-- =============================================================================
-- ArogyaMitra :: 0013 Consent, integration ledger, ambulance and teleconsult
-- PRD refs: 6 FR-017..FR-021, 11 (ConsentRecord, IntegrationTransaction), 14, 16
--
-- Every external system is reached through an adapter. This migration owns the
-- ArogyaMitra-side records only: correlation ids, status and the minimum
-- operational metadata (PRD 14.1). No external clinical payload is copied here.
-- =============================================================================

create type public.ambulance_status as enum (
  'requested',
  'dispatched',
  'en_route_pickup',
  'at_pickup',
  'en_route_destination',
  'completed',
  'cancelled',
  'failed'
);

create type public.teleconsult_status as enum (
  'requested',
  'scheduled',
  'in_progress',
  'completed',
  'cancelled',
  'failed'
);

-- ---------------------------------------------------------------------------
-- ConsentRecord (PRD 11, 14.1, 16)
-- ---------------------------------------------------------------------------
create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  subject_patient_id uuid not null references public.patients (id) on delete cascade,
  requester_id uuid references public.app_users (id) on delete set null,
  requester_facility_id uuid references public.facilities (id) on delete set null,
  purpose text not null,
  -- What the consent covers: hi_types, date range, recipients.
  scope jsonb not null default '{}'::jsonb,
  status public.consent_status not null default 'requested',
  -- ABDM consent artefact / transaction reference (PRD 11, 14.1)
  external_system public.external_system not null default 'abdm',
  external_transaction_id text,
  artefact_reference text,
  requested_at timestamptz not null default now(),
  granted_at timestamptz,
  denied_at timestamptz,
  revoked_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index consent_records_subject_idx on public.consent_records (subject_patient_id, created_at desc);
create index consent_records_active_idx on public.consent_records (subject_patient_id)
  where status = 'granted';
create index consent_records_external_idx on public.consent_records (external_transaction_id);

create trigger consent_records_touch before update on public.consent_records
  for each row execute function app.touch_updated_at();

create trigger consent_records_audit
  after insert or update or delete on public.consent_records
  for each row execute function app.audit_row('consent_record');

comment on table public.consent_records is
  'Consent artefact references for health-information exchange. Purpose-bound '
  'and auditable (PRD 16).';

-- Is there a live consent covering this purpose right now?
create or replace function app.has_active_consent(p_patient_id uuid, p_purpose text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.consent_records c
    where c.subject_patient_id = p_patient_id
      and c.status = 'granted'
      and c.purpose = p_purpose
      and c.revoked_at is null
      and (c.expires_at is null or c.expires_at > now())
  );
$$;

-- ---------------------------------------------------------------------------
-- IntegrationTransaction (PRD 11, 14)
-- One row per adapter call. Request/response bodies are deliberately not
-- stored, only metadata needed to troubleshoot (PRD 14.1, 16).
-- ---------------------------------------------------------------------------
create table public.integration_transactions (
  id uuid primary key default gen_random_uuid(),
  system public.external_system not null,
  operation text not null,
  correlation_id text not null,
  status public.integration_status not null default 'pending',
  -- Optional links back into the workflow
  referral_id uuid references public.referrals (id) on delete set null,
  patient_id uuid references public.patients (id) on delete set null,
  facility_id uuid references public.facilities (id) on delete set null,
  consent_record_id uuid references public.consent_records (id) on delete set null,
  request_metadata jsonb not null default '{}'::jsonb,
  response_metadata jsonb not null default '{}'::jsonb,
  http_status integer,
  latency_ms integer,
  attempts smallint not null default 1,
  error_code text,
  error_message text,
  -- True while running against a mock adapter (PRD 14.4, 23)
  is_mock boolean not null default true,
  adapter_version text,
  started_at timestamptz not null default now(),
  completed_at timestamptz
);

create index integration_transactions_system_idx
  on public.integration_transactions (system, started_at desc);
create index integration_transactions_correlation_idx
  on public.integration_transactions (correlation_id);
create index integration_transactions_failed_idx
  on public.integration_transactions (system, started_at desc)
  where status in ('failed', 'timeout');

comment on table public.integration_transactions is
  'Adapter call ledger for ABDM, Bhashini, eSanjeevani, ambulance, SMS and maps.';

-- ---------------------------------------------------------------------------
-- Ambulance (PRD 5.1, 6 FR-021, 14.4)
-- ---------------------------------------------------------------------------
create table public.ambulance_requests (
  id uuid primary key default gen_random_uuid(),
  referral_id uuid references public.referrals (id) on delete set null,
  patient_id uuid not null references public.patients (id) on delete restrict,
  requested_by uuid references public.app_users (id) on delete set null,
  district_id uuid not null references public.districts (id) on delete restrict,
  destination_facility_id uuid references public.facilities (id) on delete set null,
  pickup_point extensions.geography(point, 4326) not null,
  pickup_address text,
  contact_phone text not null,
  status public.ambulance_status not null default 'requested',
  -- Adapter is provider-agnostic; there is no universal 108 API (PRD 14.4).
  provider_key text not null default 'mock',
  external_reference text,
  vehicle_number text,
  crew_contact text,
  eta_minutes integer,
  requested_at timestamptz not null default now(),
  dispatched_at timestamptz,
  at_pickup_at timestamptz,
  completed_at timestamptz,
  cancellation_reason text,
  is_mock boolean not null default true,
  updated_at timestamptz not null default now()
);

create index ambulance_requests_referral_idx on public.ambulance_requests (referral_id);
create index ambulance_requests_district_idx
  on public.ambulance_requests (district_id, requested_at desc);
create index ambulance_requests_open_idx on public.ambulance_requests (status)
  where status not in ('completed', 'cancelled', 'failed');

create trigger ambulance_requests_touch before update on public.ambulance_requests
  for each row execute function app.touch_updated_at();

create trigger ambulance_requests_audit
  after insert or update or delete on public.ambulance_requests
  for each row execute function app.audit_row('ambulance_request');

create or replace function app.on_ambulance_status_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return null;
  end if;

  if new.status = 'dispatched' then
    update public.ambulance_requests
    set dispatched_at = coalesce(dispatched_at, now())
    where id = new.id;
  end if;

  perform app.emit_event(
    'ambulance.' || new.status::text, 'ambulance_request', new.id::text,
    jsonb_build_object(
      'referral_id', new.referral_id,
      'eta_minutes', new.eta_minutes,
      'vehicle_number', new.vehicle_number
    ),
    new.district_id
  );

  return null;
end;
$$;

create trigger ambulance_requests_events
  after insert or update of status on public.ambulance_requests
  for each row execute function app.on_ambulance_status_change();

-- ---------------------------------------------------------------------------
-- Teleconsultation (PRD 5.1, 6 FR-020, 14.3)
-- ---------------------------------------------------------------------------
create table public.teleconsult_sessions (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete restrict,
  referral_id uuid references public.referrals (id) on delete set null,
  facility_id uuid references public.facilities (id) on delete set null,
  district_id uuid references public.districts (id) on delete restrict,
  requested_by uuid references public.app_users (id) on delete set null,
  consent_record_id uuid references public.consent_records (id) on delete set null,
  provider_key text not null default 'mock',
  external_session_id text,
  -- Held only for the life of the session; never treated as durable content.
  join_url text,
  status public.teleconsult_status not null default 'requested',
  scheduled_at timestamptz,
  started_at timestamptz,
  ended_at timestamptz,
  duration_seconds integer,
  failure_reason text,
  is_mock boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index teleconsult_sessions_patient_idx
  on public.teleconsult_sessions (patient_id, created_at desc);
create index teleconsult_sessions_district_idx
  on public.teleconsult_sessions (district_id, created_at desc);

create trigger teleconsult_sessions_touch before update on public.teleconsult_sessions
  for each row execute function app.touch_updated_at();

create trigger teleconsult_sessions_audit
  after insert or update or delete on public.teleconsult_sessions
  for each row execute function app.audit_row('teleconsult_session');

-- ---------------------------------------------------------------------------
-- Adapter-facing helpers. Edge Functions call these with the service role so
-- the ledger is always written, even when the external call fails.
-- ---------------------------------------------------------------------------
create or replace function public.log_integration_start(
  p_system public.external_system,
  p_operation text,
  p_request_metadata jsonb default '{}'::jsonb,
  p_referral_id uuid default null,
  p_patient_id uuid default null,
  p_is_mock boolean default true,
  p_adapter_version text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  insert into public.integration_transactions (
    system, operation, correlation_id, status, referral_id, patient_id,
    request_metadata, is_mock, adapter_version
  )
  values (
    p_system, p_operation, app.trace_id(), 'pending', p_referral_id, p_patient_id,
    coalesce(p_request_metadata, '{}'::jsonb), p_is_mock, p_adapter_version
  )
  returning id into v_id;

  return v_id;
end;
$$;

create or replace function public.log_integration_finish(
  p_transaction_id uuid,
  p_status public.integration_status,
  p_response_metadata jsonb default '{}'::jsonb,
  p_http_status integer default null,
  p_error_code text default null,
  p_error_message text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.integration_transactions t
  set status = p_status,
      response_metadata = coalesce(p_response_metadata, '{}'::jsonb),
      http_status = p_http_status,
      error_code = p_error_code,
      error_message = p_error_message,
      completed_at = now(),
      latency_ms = greatest(0, (extract(epoch from (now() - t.started_at)) * 1000)::int)
  where t.id = p_transaction_id;
end;
$$;
