-- =============================================================================
-- ArogyaMitra :: 0011 Referral use cases (PRD 13 endpoints)
--   POST /referrals              -> public.create_referral
--   POST /referrals/{id}/accept  -> public.accept_referral
--   POST /referrals/{id}/reject  -> public.reject_referral
--   (lifecycle)                  -> public.advance_referral
--   (cancel)                     -> public.cancel_referral
--   (escalate)                   -> public.escalate_referral
--   (scheduled)                  -> public.expire_stale_referrals
-- =============================================================================

-- Walk one legal step. All status changes funnel through here so the trigger
-- always sees a single from->to pair.
create or replace function app.set_referral_status(
  p_referral_id uuid,
  p_to public.referral_status,
  p_reason text default null,
  p_outcome text default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.referrals;
begin
  update public.referrals r
  set status = p_to,
      rejection_reason = case when p_to = 'REJECTED' then p_reason else r.rejection_reason end,
      cancellation_reason = case
        when p_to in ('CANCELLED', 'NO_SHOW') then p_reason else r.cancellation_reason end,
      outcome = coalesce(p_outcome, r.outcome)
  where r.id = p_referral_id
  returning * into v_row;

  if v_row.id is null then
    raise exception 'Referral % not found', p_referral_id using errcode = 'no_data_found';
  end if;

  return v_row;
end;
$$;

-- ---------------------------------------------------------------------------
-- create_referral
-- ---------------------------------------------------------------------------
create or replace function public.create_referral(
  p_patient_id uuid,
  p_destination_facility_id uuid,
  p_triage_assessment_id uuid default null,
  p_priority public.referral_priority default null,
  p_reason text default null,
  p_clinical_notes text default null,
  p_source_facility_id uuid default null,
  p_score_snapshot jsonb default null,
  p_score_config_version integer default null,
  p_client_created_at timestamptz default null,
  p_idempotency_key text default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_patient public.patients;
  v_triage public.triage_assessments;
  v_facility public.facilities;
  v_referral public.referrals;
  v_priority public.referral_priority;
  v_sla jsonb := coalesce(
    app.active_config('referral_sla'),
    '{"accept_minutes":30,"emergency_accept_minutes":10,"recommendation_expiry_minutes":720}'::jsonb
  );
  v_accept_minutes integer;
  v_cached jsonb;
begin
  -- Offline replay protection (PRD 15, PRD 27 "duplicate synchronisation does
  -- not create duplicate referrals").
  if p_idempotency_key is not null then
    v_cached := app.idempotency_lookup(p_idempotency_key, 'create_referral');

    if v_cached is not null then
      select * into v_referral from public.referrals r where r.id = (v_cached ->> 'id')::uuid;
      if v_referral.id is not null then
        return v_referral;
      end if;
    end if;
  end if;

  select * into v_patient from public.patients p where p.id = p_patient_id;
  if v_patient.id is null then
    raise exception 'Patient % not found', p_patient_id using errcode = 'no_data_found';
  end if;

  select * into v_facility from public.facilities f where f.id = p_destination_facility_id;
  if v_facility.id is null then
    raise exception 'Facility % not found', p_destination_facility_id using errcode = 'no_data_found';
  end if;
  if not v_facility.is_operational then
    raise exception 'Facility % is not operational', v_facility.name_en
      using errcode = 'check_violation';
  end if;

  if p_triage_assessment_id is not null then
    select * into v_triage
    from public.triage_assessments t
    where t.id = p_triage_assessment_id and t.patient_id = p_patient_id;

    if v_triage.id is null then
      raise exception 'Triage assessment % does not belong to patient %',
        p_triage_assessment_id, p_patient_id using errcode = 'invalid_parameter_value';
    end if;
  end if;

  -- Priority is derived from triage unless explicitly overridden.
  v_priority := coalesce(
    p_priority,
    case v_triage.risk_level
      when 'emergency' then 'emergency'
      when 'high' then 'urgent'
      else 'routine'
    end::public.referral_priority,
    'routine'
  );

  v_accept_minutes := case
    when v_priority = 'emergency'
      then coalesce((v_sla ->> 'emergency_accept_minutes')::int, 10)
    else coalesce((v_sla ->> 'accept_minutes')::int, 30)
  end;

  -- 1. CREATED
  insert into public.referrals (
    reference_code, patient_id, triage_assessment_id, source_facility_id,
    destination_facility_id, district_id, priority, status, risk_level,
    required_services, reason, clinical_notes, score_snapshot,
    score_config_version, rule_set_version, sla_due_at, expires_at,
    created_by, assigned_worker_id, client_created_at
  )
  values (
    app.next_referral_reference(), p_patient_id, p_triage_assessment_id, p_source_facility_id,
    p_destination_facility_id,
    coalesce(v_patient.district_id, v_facility.district_id),
    v_priority, 'CREATED', v_triage.risk_level,
    coalesce(v_triage.required_services, '{}'), p_reason, p_clinical_notes, p_score_snapshot,
    coalesce(p_score_config_version, app.active_config_version('facility_score_weights')),
    v_triage.rule_set_version,
    now() + make_interval(mins => v_accept_minutes),
    now() + make_interval(
      mins => coalesce((v_sla ->> 'recommendation_expiry_minutes')::int, 720)
    ),
    auth.uid(),
    case when app.is_field_worker() then auth.uid() else null end,
    p_client_created_at
  )
  returning * into v_referral;

  -- 2. TRIAGED (only when a triage outcome is attached)
  if v_triage.id is not null then
    v_referral := app.set_referral_status(v_referral.id, 'TRIAGED');

    -- 3a. Emergency red flag short-circuits the normal path (PRD 6 FR-006, 7.5)
    if v_triage.risk_level = 'emergency' then
      v_referral := app.set_referral_status(v_referral.id, 'EMERGENCY_ESCALATED');

      if p_idempotency_key is not null then
        perform app.idempotency_remember(
          p_idempotency_key, 'create_referral', jsonb_build_object('id', v_referral.id)
        );
      end if;

      return v_referral;
    end if;
  end if;

  -- 3b. RECOMMENDED -> REFERRAL_SENT
  v_referral := app.set_referral_status(v_referral.id, 'RECOMMENDED');
  v_referral := app.set_referral_status(v_referral.id, 'REFERRAL_SENT');

  if p_idempotency_key is not null then
    perform app.idempotency_remember(
      p_idempotency_key, 'create_referral', jsonb_build_object('id', v_referral.id)
    );
  end if;

  return v_referral;
end;
$$;

comment on function public.create_referral is
  'Creates a referral and walks it through CREATED -> TRIAGED -> RECOMMENDED '
  '-> REFERRAL_SENT in one transaction, or to EMERGENCY_ESCALATED on a red flag.';

-- ---------------------------------------------------------------------------
-- Facility actions (PRD 5.3)
-- ---------------------------------------------------------------------------
create or replace function public.accept_referral(
  p_referral_id uuid,
  p_note text default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return app.set_referral_status(p_referral_id, 'ACCEPTED', null, p_note);
end;
$$;

create or replace function public.reject_referral(
  p_referral_id uuid,
  p_reason text
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if coalesce(length(trim(p_reason)), 0) = 0 then
    raise exception 'A rejection reason is required' using errcode = 'invalid_parameter_value';
  end if;

  return app.set_referral_status(p_referral_id, 'REJECTED', p_reason);
end;
$$;

create or replace function public.advance_referral(
  p_referral_id uuid,
  p_to public.referral_status,
  p_reason text default null,
  p_outcome text default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
begin
  return app.set_referral_status(p_referral_id, p_to, p_reason, p_outcome);
end;
$$;

create or replace function public.cancel_referral(
  p_referral_id uuid,
  p_reason text
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if coalesce(length(trim(p_reason)), 0) = 0 then
    raise exception 'A cancellation reason is required' using errcode = 'invalid_parameter_value';
  end if;

  return app.set_referral_status(p_referral_id, 'CANCELLED', p_reason);
end;
$$;

create or replace function public.escalate_referral(
  p_referral_id uuid,
  p_reason text default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.referrals;
begin
  update public.referrals set priority = 'emergency' where id = p_referral_id;
  v_row := app.set_referral_status(p_referral_id, 'EMERGENCY_ESCALATED', p_reason);
  return v_row;
end;
$$;

-- ---------------------------------------------------------------------------
-- Re-route after a rejection: back to RECOMMENDED with a new destination.
-- ---------------------------------------------------------------------------
create or replace function public.reroute_referral(
  p_referral_id uuid,
  p_destination_facility_id uuid,
  p_score_snapshot jsonb default null
)
returns public.referrals
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.referrals;
begin
  update public.referrals
  set destination_facility_id = p_destination_facility_id,
      score_snapshot = coalesce(p_score_snapshot, score_snapshot),
      rejection_reason = null
  where id = p_referral_id
  returning * into v_row;

  if v_row.id is null then
    raise exception 'Referral % not found', p_referral_id using errcode = 'no_data_found';
  end if;

  v_row := app.set_referral_status(p_referral_id, 'RECOMMENDED');
  return app.set_referral_status(p_referral_id, 'REFERRAL_SENT');
end;
$$;

-- ---------------------------------------------------------------------------
-- Scheduled maintenance: expire and flag SLA breaches.
-- Invoked by pg_cron or an Edge Function on a schedule.
-- ---------------------------------------------------------------------------
create or replace function public.expire_stale_referrals()
returns table (expired_count integer, breached_count integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_expired integer := 0;
  v_breached integer := 0;
  v_id uuid;
begin
  -- Mark SLA breaches without changing workflow state (PRD 18 SLA breach alert).
  with breached as (
    update public.referrals r
    set sla_breached = true
    where r.sla_breached = false
      and r.sla_due_at < now()
      and r.status in ('RECOMMENDED', 'REFERRAL_SENT')
    returning r.id, r.district_id, r.reference_code
  )
  select count(*) into v_breached from breached;

  for v_id in
    select r.id from public.referrals r
    where r.expires_at < now()
      and r.status in ('RECOMMENDED', 'REFERRAL_SENT')
  loop
    perform app.set_referral_status(v_id, 'EXPIRED');
    v_expired := v_expired + 1;
  end loop;

  return query select v_expired, v_breached;
end;
$$;

-- ---------------------------------------------------------------------------
-- Referral timeline for the UI (PRD 13 GET /referrals/{id}/events)
-- ---------------------------------------------------------------------------
create or replace view public.referral_timeline
with (security_invoker = true)
as
select
  e.id,
  e.referral_id,
  r.reference_code,
  e.event_type,
  e.from_status,
  e.to_status,
  e.reason,
  e.actor_role,
  e.occurred_at,
  e.metadata
from public.referral_events e
join public.referrals r on r.id = e.referral_id
order by e.occurred_at;
