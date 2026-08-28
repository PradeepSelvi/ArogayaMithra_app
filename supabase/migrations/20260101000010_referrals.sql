-- =============================================================================
-- ArogyaMitra :: 0010 Referral engine and state machine
-- PRD refs: 6 FR-009/FR-010, 11 (Referral, ReferralEvent), 12.2, 27
--
-- The legal transitions are rows in referral_transitions, not branches in code.
-- A BEFORE UPDATE trigger rejects anything not in that table, so an invalid
-- transition is impossible from any client, any role, any connection.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Transition table (PRD 12.2)
-- ---------------------------------------------------------------------------
create table public.referral_transitions (
  from_status public.referral_status not null,
  to_status public.referral_status not null,
  -- Empty array means "any authenticated role in scope".
  allowed_roles public.user_role[] not null default '{}',
  requires_reason boolean not null default false,
  description text,
  primary key (from_status, to_status)
);

comment on table public.referral_transitions is
  'The referral state machine as data. Editing this table changes the legal '
  'workflow; the enforcement trigger reads it on every update.';

insert into public.referral_transitions (from_status, to_status, allowed_roles, requires_reason, description) values
  -- Happy path
  ('CREATED', 'TRIAGED', '{}', false, 'Triage outcome attached'),
  ('TRIAGED', 'RECOMMENDED', '{}', false, 'Facility ranking produced a recommendation'),
  -- A clinician who has already examined the patient may refer without running
  -- app triage. Deliberately closed to citizens: a citizen-initiated referral
  -- must pass through TRIAGED so red flags are always evaluated.
  ('CREATED', 'RECOMMENDED',
   array['asha','anm','medical_officer','facility_admin','system_admin']::public.user_role[],
   false, 'Clinician-initiated referral with no app triage'),
  ('RECOMMENDED', 'REFERRAL_SENT', '{}', false, 'Citizen accepted the recommendation'),
  ('REFERRAL_SENT', 'ACCEPTED', array['medical_officer','facility_admin','system_admin']::public.user_role[], false, 'Destination facility accepted'),
  ('ACCEPTED', 'PATIENT_TRAVELLING', array['citizen','asha','anm','medical_officer','facility_admin','system_admin']::public.user_role[], false, 'Patient started travelling'),
  ('PATIENT_TRAVELLING', 'ARRIVED', array['medical_officer','facility_admin','asha','anm','system_admin']::public.user_role[], false, 'Patient arrived at destination'),
  ('ARRIVED', 'CONSULTATION', array['medical_officer','facility_admin','system_admin']::public.user_role[], false, 'Consultation started'),
  ('CONSULTATION', 'COMPLETED', array['medical_officer','facility_admin','system_admin']::public.user_role[], false, 'Consultation completed'),

  -- Rejection and re-routing
  ('REFERRAL_SENT', 'REJECTED', array['medical_officer','facility_admin','system_admin']::public.user_role[], true, 'Destination facility rejected'),
  ('REJECTED', 'RECOMMENDED', '{}', false, 'Re-ranked to an alternative facility'),

  -- Expiry
  ('RECOMMENDED', 'EXPIRED', array['system_admin']::public.user_role[], false, 'Recommendation expired'),
  ('REFERRAL_SENT', 'EXPIRED', array['system_admin']::public.user_role[], false, 'Acceptance SLA expired'),

  -- No-show
  ('ACCEPTED', 'NO_SHOW', array['medical_officer','facility_admin','system_admin']::public.user_role[], true, 'Patient did not arrive'),
  ('PATIENT_TRAVELLING', 'NO_SHOW', array['medical_officer','facility_admin','system_admin']::public.user_role[], true, 'Patient did not arrive'),
  ('ARRIVED', 'NO_SHOW', array['medical_officer','facility_admin','system_admin']::public.user_role[], true, 'Patient left before consultation'),

  -- Cancellation
  ('CREATED', 'CANCELLED', '{}', true, 'Cancelled before triage'),
  ('TRIAGED', 'CANCELLED', '{}', true, 'Cancelled after triage'),
  ('RECOMMENDED', 'CANCELLED', '{}', true, 'Citizen declined all recommendations'),
  ('REFERRAL_SENT', 'CANCELLED', array['citizen','asha','anm','dho','state_admin','system_admin']::public.user_role[], true, 'Cancelled before acceptance'),
  ('ACCEPTED', 'CANCELLED', array['citizen','asha','anm','dho','state_admin','system_admin']::public.user_role[], true, 'Cancelled after acceptance'),

  -- Emergency escalation is reachable from every pre-arrival state.
  -- It is an exception state (PRD 12.2) but not a dead end: the patient still
  -- needs to be tracked to arrival and completion.
  ('CREATED', 'EMERGENCY_ESCALATED', '{}', false, 'Red flag detected'),
  ('TRIAGED', 'EMERGENCY_ESCALATED', '{}', false, 'Red flag detected'),
  ('RECOMMENDED', 'EMERGENCY_ESCALATED', '{}', false, 'Condition deteriorated'),
  ('REFERRAL_SENT', 'EMERGENCY_ESCALATED', '{}', false, 'Condition deteriorated'),
  ('ACCEPTED', 'EMERGENCY_ESCALATED', '{}', false, 'Condition deteriorated'),
  ('PATIENT_TRAVELLING', 'EMERGENCY_ESCALATED', '{}', false, 'Condition deteriorated'),
  ('EMERGENCY_ESCALATED', 'ARRIVED', array['medical_officer','facility_admin','asha','anm','system_admin']::public.user_role[], false, 'Patient arrived by emergency transport'),
  ('EMERGENCY_ESCALATED', 'CONSULTATION', array['medical_officer','facility_admin','system_admin']::public.user_role[], false, 'Emergency treatment started'),
  ('EMERGENCY_ESCALATED', 'NO_SHOW', array['medical_officer','facility_admin','system_admin']::public.user_role[], true, 'Patient not reachable'),
  ('EMERGENCY_ESCALATED', 'CANCELLED', array['dho','state_admin','system_admin']::public.user_role[], true, 'Escalation withdrawn');

-- Terminal states never transition again.
create or replace function app.is_terminal_referral_status(p_status public.referral_status)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select not exists (
    select 1 from public.referral_transitions t where t.from_status = p_status
  );
$$;

-- ---------------------------------------------------------------------------
-- Referral (PRD 11)
-- ---------------------------------------------------------------------------
create table public.referrals (
  id uuid primary key default gen_random_uuid(),
  reference_code text not null unique,
  patient_id uuid not null references public.patients (id) on delete restrict,
  triage_assessment_id uuid references public.triage_assessments (id) on delete set null,
  source_facility_id uuid references public.facilities (id) on delete set null,
  destination_facility_id uuid references public.facilities (id) on delete restrict,
  district_id uuid not null references public.districts (id) on delete restrict,
  priority public.referral_priority not null default 'routine',
  status public.referral_status not null default 'CREATED',
  risk_level public.risk_level,
  required_services text[] not null default '{}',
  reason text,
  clinical_notes text,
  -- Why this facility won, captured at decision time (PRD 12.1, explainability)
  score_snapshot jsonb,
  score_config_version integer,
  rule_set_version integer,
  -- SLA (PRD 5.4, 19)
  sla_due_at timestamptz,
  expires_at timestamptz,
  sla_breached boolean not null default false,
  -- Lifecycle timestamps for turnaround KPIs (PRD 19)
  sent_at timestamptz,
  accepted_at timestamptz,
  arrived_at timestamptz,
  consultation_at timestamptz,
  closed_at timestamptz,
  rejection_reason text,
  cancellation_reason text,
  outcome text,
  created_by uuid references public.app_users (id) on delete set null,
  assigned_worker_id uuid references public.app_users (id) on delete set null,
  client_created_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- A referral past RECOMMENDED must name a destination.
  constraint referrals_destination_required check (
    status in ('CREATED', 'TRIAGED', 'CANCELLED', 'EXPIRED')
    or destination_facility_id is not null
  )
);

create index referrals_patient_idx on public.referrals (patient_id, created_at desc);
create index referrals_destination_status_idx
  on public.referrals (destination_facility_id, status, created_at desc);
create index referrals_district_idx on public.referrals (district_id, created_at desc);
create index referrals_status_idx on public.referrals (status);
create index referrals_open_sla_idx
  on public.referrals (sla_due_at)
  where status in ('REFERRAL_SENT', 'RECOMMENDED');
create index referrals_worker_idx on public.referrals (assigned_worker_id);

create trigger referrals_touch before update on public.referrals
  for each row execute function app.touch_updated_at();

-- ---------------------------------------------------------------------------
-- ReferralEvent (PRD 11): append-only timeline, PRD 13 GET /referrals/{id}/events
-- ---------------------------------------------------------------------------
create table public.referral_events (
  id bigint generated always as identity primary key,
  referral_id uuid not null references public.referrals (id) on delete cascade,
  event_type text not null,
  from_status public.referral_status,
  to_status public.referral_status,
  actor_id uuid references public.app_users (id) on delete set null,
  actor_role public.user_role,
  reason text,
  metadata jsonb not null default '{}'::jsonb,
  trace_id text,
  occurred_at timestamptz not null default now()
);

create index referral_events_referral_idx on public.referral_events (referral_id, occurred_at);

create trigger referral_events_no_update
  before update on public.referral_events
  for each row execute function app.reject_audit_mutation();

create trigger referral_events_no_delete
  before delete on public.referral_events
  for each row execute function app.reject_audit_mutation();

comment on table public.referral_events is
  'Immutable referral timeline. Every state change lands here (PRD FR-010).';

-- ---------------------------------------------------------------------------
-- Human-readable reference code, e.g. RF-2026-0A3C91
-- ---------------------------------------------------------------------------
create sequence if not exists public.referral_reference_seq;

create or replace function app.next_referral_reference()
returns text
language sql
volatile
security invoker
set search_path = ''
as $$
  select 'RF-' || to_char(now(), 'YYYY') || '-'
    || lpad(upper(to_hex(nextval('public.referral_reference_seq'))), 6, '0');
$$;

-- ---------------------------------------------------------------------------
-- State machine enforcement
-- ---------------------------------------------------------------------------
create or replace function app.enforce_referral_transition()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_transition public.referral_transitions;
  v_role public.user_role := app.current_role();
  v_reason text;
begin
  if new.status = old.status then
    return new;
  end if;

  select * into v_transition
  from public.referral_transitions t
  where t.from_status = old.status and t.to_status = new.status;

  if v_transition.from_status is null then
    raise exception 'Illegal referral transition % -> %', old.status, new.status
      using errcode = 'check_violation',
            hint = 'See public.referral_transitions for the legal workflow.';
  end if;

  -- Role gate. An empty allowed_roles means any authenticated role may act.
  --
  -- Scheduled automation (the SLA sweep, adapter callbacks) runs with no JWT,
  -- so auth.uid() is null. Those sessions hold the service role and are already
  -- privileged, so the role gate is skipped for them. Transition legality and
  -- the reason requirement below are NOT skipped: automation is still unable to
  -- perform a transition that does not exist in referral_transitions.
  if auth.uid() is not null
     and array_length(v_transition.allowed_roles, 1) is not null
     and (v_role is null or not (v_role = any (v_transition.allowed_roles))) then
    raise exception 'Role % may not move a referral from % to %',
      coalesce(v_role::text, 'unassigned'), old.status, new.status
      using errcode = 'insufficient_privilege';
  end if;

  v_reason := case new.status
    when 'REJECTED' then new.rejection_reason
    when 'CANCELLED' then new.cancellation_reason
    else coalesce(new.rejection_reason, new.cancellation_reason, new.outcome)
  end;

  if v_transition.requires_reason and coalesce(length(trim(v_reason)), 0) = 0 then
    raise exception 'Transition % -> % requires a reason', old.status, new.status
      using errcode = 'check_violation';
  end if;

  -- Server-authoritative lifecycle timestamps.
  case new.status
    when 'REFERRAL_SENT' then new.sent_at := coalesce(new.sent_at, now());
    when 'ACCEPTED' then new.accepted_at := coalesce(new.accepted_at, now());
    when 'ARRIVED' then new.arrived_at := coalesce(new.arrived_at, now());
    when 'CONSULTATION' then new.consultation_at := coalesce(new.consultation_at, now());
    else null;
  end case;

  if app.is_terminal_referral_status(new.status) then
    new.closed_at := coalesce(new.closed_at, now());
  end if;

  return new;
end;
$$;

create trigger referrals_enforce_transition
  before update of status on public.referrals
  for each row execute function app.enforce_referral_transition();

-- ---------------------------------------------------------------------------
-- Timeline, audit and notification fan-out after a state change
-- ---------------------------------------------------------------------------
create or replace function app.record_referral_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_type text;
  v_event_id bigint;
  v_recipients jsonb := '[]'::jsonb;
  v_patient public.patients;
  v_facility_name text;
  v_reason text;
begin
  if tg_op = 'INSERT' then
    v_event_type := 'referral.created';
  elsif new.status is distinct from old.status then
    v_event_type := 'referral.' || lower(new.status::text);
  else
    return null;
  end if;

  v_reason := coalesce(new.rejection_reason, new.cancellation_reason);

  insert into public.referral_events (
    referral_id, event_type, from_status, to_status,
    actor_id, actor_role, reason, metadata, trace_id
  )
  values (
    new.id, v_event_type,
    case when tg_op = 'UPDATE' then old.status end,
    new.status,
    auth.uid(), app.current_role(), v_reason,
    jsonb_build_object(
      'priority', new.priority,
      'destination_facility_id', new.destination_facility_id,
      'risk_level', new.risk_level
    ),
    app.trace_id()
  );

  perform app.write_audit(
    v_event_type, 'referral', new.id::text,
    case when tg_op = 'UPDATE' then to_jsonb(old) end,
    to_jsonb(new)
  );

  v_event_id := app.emit_event(
    v_event_type, 'referral', new.id::text,
    jsonb_build_object(
      'reference_code', new.reference_code,
      'status', new.status,
      'priority', new.priority,
      'patient_id', new.patient_id,
      'destination_facility_id', new.destination_facility_id,
      'source_facility_id', new.source_facility_id
    ),
    new.district_id
  );

  -- Build the recipient list from the PRD 18 matrix.
  select * into v_patient from public.patients p where p.id = new.patient_id;
  select f.name_en into v_facility_name
  from public.facilities f where f.id = new.destination_facility_id;

  if v_patient.app_user_id is not null then
    v_recipients := v_recipients || jsonb_build_array(jsonb_build_object(
      'user_id', v_patient.app_user_id, 'role', 'citizen',
      'language', v_patient.preferred_language
    ));
  end if;

  if new.assigned_worker_id is not null then
    v_recipients := v_recipients || (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', u.id, 'role', u.role, 'language', u.preferred_language
      )), '[]'::jsonb)
      from public.app_users u
      where u.id = new.assigned_worker_id and u.status = 'active'
    );
  end if;

  if new.destination_facility_id is not null then
    v_recipients := v_recipients || (
      select coalesce(jsonb_agg(jsonb_build_object(
        'user_id', u.id, 'role', u.role, 'language', u.preferred_language
      )), '[]'::jsonb)
      from public.app_users u
      where u.facility_id = new.destination_facility_id
        and u.role in ('medical_officer', 'facility_admin')
        and u.status = 'active'
    );
  end if;

  perform app.queue_notifications(
    v_event_id, v_event_type, v_recipients,
    jsonb_build_object(
      'reference_code', new.reference_code,
      'facility_name', coalesce(v_facility_name, ''),
      'patient_name', coalesce(v_patient.full_name, ''),
      'action', jsonb_build_object('route', '/referrals', 'id', new.id)
    )
  );

  return null;
end;
$$;

create trigger referrals_record_change
  after insert or update of status on public.referrals
  for each row execute function app.record_referral_change();
