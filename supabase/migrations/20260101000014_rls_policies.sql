-- =============================================================================
-- ArogyaMitra :: 0014 Row Level Security
-- PRD refs: 6 FR-002, 16 (least privilege, purpose-aware access), 27
--
-- Posture
--   * RLS is enabled on every table in public. Nothing is readable by default.
--   * anon has no data access at all; every policy targets `authenticated`.
--   * DHO/State roles deliberately get NO row access to patients or households.
--     They monitor through the aggregate views in migration 0015, which is what
--     PRD 5.4 actually asks for. This keeps identifiable health data inside the
--     care team (PRD 16 least privilege).
--
-- Why the access predicates below are SECURITY DEFINER
--   Patient visibility depends on households, and household visibility depends
--   on patients. Expressing that directly in two policies makes Postgres
--   recurse. Encapsulating each rule in one SECURITY DEFINER function evaluates
--   the relationship once, with RLS bypassed inside the function only, so the
--   policies stay acyclic and the rule lives in exactly one place.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Enable RLS everywhere
-- ---------------------------------------------------------------------------
alter table public.states enable row level security;
alter table public.districts enable row level security;
alter table public.blocks enable row level security;
alter table public.villages enable row level security;
alter table public.app_users enable row level security;
alter table public.audit_logs enable row level security;
alter table public.facilities enable row level security;
alter table public.service_catalog enable row level security;
alter table public.facility_services enable row level security;
alter table public.facility_resources enable row level security;
alter table public.config_versions enable row level security;
alter table public.readiness_checks enable row level security;
alter table public.idempotency_keys enable row level security;
alter table public.households enable row level security;
alter table public.patients enable row level security;
alter table public.symptom_catalog enable row level security;
alter table public.triage_rule_sets enable row level security;
alter table public.triage_rules enable row level security;
alter table public.triage_assessments enable row level security;
alter table public.domain_events enable row level security;
alter table public.notification_templates enable row level security;
alter table public.notifications enable row level security;
alter table public.referral_transitions enable row level security;
alter table public.referrals enable row level security;
alter table public.referral_events enable row level security;
alter table public.followups enable row level security;
alter table public.feedback enable row level security;
alter table public.consent_records enable row level security;
alter table public.integration_transactions enable row level security;
alter table public.ambulance_requests enable row level security;
alter table public.teleconsult_sessions enable row level security;

-- anon is used only for the pre-login shell; it reads nothing.
revoke all on all tables in schema public from anon;

-- ===========================================================================
-- Access predicates
-- ===========================================================================

-- The caller is the citizen this patient record belongs to.
create or replace function app.is_own_patient(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.patients p
    where p.id = p_patient_id and p.app_user_id = auth.uid()
  );
$$;

-- The caller is the field worker responsible for this patient's household,
-- either by direct assignment or by working the same block.
create or replace function app.field_worker_owns_patient(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.patients p
    join public.households h on h.id = p.household_id
    where p.id = p_patient_id
      and (
        h.assigned_worker_id = auth.uid()
        or (app.is_field_worker() and h.block_id = app.current_block_id())
      )
  );
$$;

-- The caller's facility has an active care relationship with this patient.
create or replace function app.facility_treats_patient(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.is_facility_staff() and exists (
    select 1 from public.referrals r
    where r.patient_id = p_patient_id
      and (
        r.destination_facility_id = app.current_facility_id()
        or r.source_facility_id = app.current_facility_id()
      )
  );
$$;

-- Full patient visibility rule. Note the absence of DHO and State: oversight
-- roles read aggregates, not people.
create or replace function app.can_access_patient(p_patient_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    app.is_own_patient(p_patient_id)
    or app.field_worker_owns_patient(p_patient_id)
    or app.facility_treats_patient(p_patient_id)
    or exists (
      select 1 from public.patients p
      where p.id = p_patient_id and p.created_by = auth.uid()
    )
    or app.has_role(array['system_admin']::public.user_role[]);
$$;

-- The caller has a patient record inside this household.
create or replace function app.is_household_member(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.patients p
    where p.household_id = p_household_id and p.app_user_id = auth.uid()
  );
$$;

-- The caller is the field worker for this household.
create or replace function app.field_worker_owns_household(p_household_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.households h
    where h.id = p_household_id
      and (
        h.assigned_worker_id = auth.uid()
        or h.created_by = auth.uid()
        or (app.is_field_worker() and h.block_id = app.current_block_id())
      )
  );
$$;

-- ---------------------------------------------------------------------------
-- Reference geography: readable by any signed-in user, writable by admins.
-- ---------------------------------------------------------------------------
create policy states_read on public.states
  for select to authenticated using (true);
create policy districts_read on public.districts
  for select to authenticated using (true);
create policy blocks_read on public.blocks
  for select to authenticated using (true);
create policy villages_read on public.villages
  for select to authenticated using (true);

create policy states_admin_write on public.states
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());
create policy districts_admin_write on public.districts
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());
create policy blocks_admin_write on public.blocks
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());
create policy villages_admin_write on public.villages
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

-- ---------------------------------------------------------------------------
-- app_users
-- ---------------------------------------------------------------------------
create policy app_users_read_self on public.app_users
  for select to authenticated using (id = auth.uid());

create policy app_users_read_colleagues on public.app_users
  for select to authenticated using (
    app.is_facility_staff() and facility_id = app.current_facility_id()
  );

create policy app_users_read_in_scope on public.app_users
  for select to authenticated using (
    app.has_role(array['system_admin', 'state_admin']::public.user_role[])
    or (app.has_role(array['dho']::public.user_role[]) and app.can_see_district(district_id))
  );

-- Self-service profile edit. Role/status/scope changes are blocked by the
-- guard trigger below, which RLS alone cannot express (no column-level check).
create policy app_users_update_self on public.app_users
  for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

create policy app_users_admin_write on public.app_users
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

create or replace function app.guard_privilege_escalation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  -- auth.uid() is null only for the service role or a direct database session,
  -- both of which are already privileged. `anon` cannot reach this trigger
  -- because every app_users policy targets `authenticated` and anon has no
  -- table privileges.
  if auth.uid() is null or app.is_administrator() then
    return new;
  end if;

  if new.role is distinct from old.role
     or new.status is distinct from old.status
     or new.facility_id is distinct from old.facility_id
     or new.district_id is distinct from old.district_id
     or new.block_id is distinct from old.block_id
     or new.state_id is distinct from old.state_id
     or new.employee_code is distinct from old.employee_code then
    raise exception 'Role, status and scope can only be changed by an administrator'
      using errcode = 'insufficient_privilege';
  end if;

  return new;
end;
$$;

create trigger app_users_guard_privileges
  before update on public.app_users
  for each row execute function app.guard_privilege_escalation();

-- ---------------------------------------------------------------------------
-- Facilities, services, resources, readiness: shared operational picture.
-- ---------------------------------------------------------------------------
create policy facilities_read on public.facilities
  for select to authenticated using (true);
create policy service_catalog_read on public.service_catalog
  for select to authenticated using (true);
create policy facility_services_read on public.facility_services
  for select to authenticated using (true);
create policy facility_resources_read on public.facility_resources
  for select to authenticated using (true);
create policy readiness_checks_read on public.readiness_checks
  for select to authenticated using (true);

-- Only the facility's own staff (or an admin) may publish its readiness.
create policy facility_services_write on public.facility_services
  for all to authenticated
  using (
    app.is_administrator()
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
  )
  with check (
    app.is_administrator()
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
  );

create policy facility_resources_write on public.facility_resources
  for all to authenticated
  using (
    app.is_administrator()
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
  )
  with check (
    app.is_administrator()
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
  );

create policy facilities_admin_write on public.facilities
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());
create policy service_catalog_admin_write on public.service_catalog
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

-- ---------------------------------------------------------------------------
-- Clinical governance and configuration: administrators only.
-- Domain functions read these with SECURITY DEFINER, so clients never need to.
-- ---------------------------------------------------------------------------
create policy config_versions_admin on public.config_versions
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

create policy symptom_catalog_read on public.symptom_catalog
  for select to authenticated using (true);
create policy symptom_catalog_admin_write on public.symptom_catalog
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

create policy triage_rule_sets_read on public.triage_rule_sets
  for select to authenticated using (app.is_health_worker());
create policy triage_rule_sets_admin on public.triage_rule_sets
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

create policy triage_rules_read on public.triage_rules
  for select to authenticated using (app.is_health_worker());
create policy triage_rules_admin on public.triage_rules
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

create policy referral_transitions_read on public.referral_transitions
  for select to authenticated using (true);
create policy referral_transitions_admin on public.referral_transitions
  for all to authenticated using (app.has_role(array['system_admin']::public.user_role[]))
  with check (app.has_role(array['system_admin']::public.user_role[]));

create policy notification_templates_read on public.notification_templates
  for select to authenticated using (app.is_administrator());
create policy notification_templates_admin on public.notification_templates
  for all to authenticated using (app.is_administrator()) with check (app.is_administrator());

-- ---------------------------------------------------------------------------
-- Households
-- ---------------------------------------------------------------------------
create policy households_read on public.households
  for select to authenticated using (
    assigned_worker_id = auth.uid()
    or created_by = auth.uid()
    or (app.is_field_worker() and block_id = app.current_block_id())
    or app.is_household_member(id)
    or app.has_role(array['system_admin']::public.user_role[])
  );

create policy households_insert on public.households
  for insert to authenticated with check (app.is_field_worker() or app.is_administrator());

create policy households_update on public.households
  for update to authenticated
  using (
    app.field_worker_owns_household(id)
    or app.has_role(array['system_admin']::public.user_role[])
  )
  with check (
    app.field_worker_owns_household(id)
    or app.has_role(array['system_admin']::public.user_role[])
  );

-- ---------------------------------------------------------------------------
-- Patients. Identifiable health data stays with the care team.
-- ---------------------------------------------------------------------------
create policy patients_read on public.patients
  for select to authenticated using (app.can_access_patient(id));

create policy patients_insert on public.patients
  for insert to authenticated with check (
    app.is_field_worker()
    or app.is_facility_staff()
    or app.has_role(array['system_admin']::public.user_role[])
    -- A citizen may register only themselves
    or app_user_id = auth.uid()
  );

create policy patients_update on public.patients
  for update to authenticated
  using (app.can_access_patient(id)) with check (true);

-- ---------------------------------------------------------------------------
-- Triage assessments
-- ---------------------------------------------------------------------------
create policy triage_assessments_read on public.triage_assessments
  for select to authenticated using (
    assessed_by = auth.uid()
    or app.can_access_patient(patient_id)
  );

-- Inserts go through public.run_triage, which validates and audits.
create policy triage_assessments_insert on public.triage_assessments
  for insert to authenticated with check (assessed_by = auth.uid());

-- ---------------------------------------------------------------------------
-- Referrals
-- ---------------------------------------------------------------------------
create policy referrals_read on public.referrals
  for select to authenticated using (
    created_by = auth.uid()
    or assigned_worker_id = auth.uid()
    or app.is_own_patient(patient_id)
    or app.field_worker_owns_patient(patient_id)
    or (
      app.is_facility_staff()
      and (destination_facility_id = app.current_facility_id()
           or source_facility_id = app.current_facility_id())
    )
    -- Operational oversight for SLA monitoring (PRD 5.4)
    or (app.is_administrator() and app.can_see_district(district_id))
    or app.has_role(array['system_admin', 'state_admin']::public.user_role[])
  );

create policy referrals_insert on public.referrals
  for insert to authenticated with check (
    app.is_health_worker() or app.is_own_patient(patient_id)
  );

-- The state machine trigger decides what a transition may be; RLS decides who
-- is allowed to touch the row at all.
create policy referrals_update on public.referrals
  for update to authenticated
  using (
    created_by = auth.uid()
    or assigned_worker_id = auth.uid()
    or app.is_own_patient(patient_id)
    or (
      app.is_facility_staff()
      and (destination_facility_id = app.current_facility_id()
           or source_facility_id = app.current_facility_id())
    )
    or app.has_role(array['dho', 'state_admin', 'system_admin']::public.user_role[])
  )
  with check (true);

create policy referral_events_read on public.referral_events
  for select to authenticated using (
    exists (select 1 from public.referrals r where r.id = referral_events.referral_id)
  );

-- ---------------------------------------------------------------------------
-- Follow-ups
-- ---------------------------------------------------------------------------
create policy followups_read on public.followups
  for select to authenticated using (
    assignee_id = auth.uid()
    or created_by = auth.uid()
    or app.is_own_patient(patient_id)
    or app.field_worker_owns_patient(patient_id)
    or (app.is_administrator() and app.can_see_district(district_id))
    or app.has_role(array['system_admin', 'state_admin']::public.user_role[])
  );

create policy followups_write on public.followups
  for all to authenticated
  using (
    assignee_id = auth.uid()
    or created_by = auth.uid()
    or app.is_facility_staff()
    or app.is_administrator()
  )
  with check (app.is_health_worker());

-- ---------------------------------------------------------------------------
-- Feedback
-- ---------------------------------------------------------------------------
create policy feedback_read on public.feedback
  for select to authenticated using (
    submitted_by = auth.uid()
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
    or (app.is_administrator() and app.can_see_district(district_id))
    or app.has_role(array['system_admin', 'state_admin']::public.user_role[])
  );

create policy feedback_insert on public.feedback
  for insert to authenticated with check (
    submitted_by = auth.uid() or submitted_by is null
  );

-- Only the facility or an administrator may resolve an issue.
create policy feedback_update on public.feedback
  for update to authenticated
  using (
    (app.is_facility_staff() and facility_id = app.current_facility_id())
    or app.is_administrator()
  )
  with check (
    (app.is_facility_staff() and facility_id = app.current_facility_id())
    or app.is_administrator()
  );

-- ---------------------------------------------------------------------------
-- Notifications: strictly the recipient's own inbox.
-- ---------------------------------------------------------------------------
create policy notifications_read on public.notifications
  for select to authenticated using (recipient_id = auth.uid());

create policy notifications_update on public.notifications
  for update to authenticated
  using (recipient_id = auth.uid()) with check (recipient_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Consent
-- ---------------------------------------------------------------------------
create policy consent_records_read on public.consent_records
  for select to authenticated using (
    requester_id = auth.uid()
    or app.is_own_patient(subject_patient_id)
    or app.has_role(array['system_admin']::public.user_role[])
  );

create policy consent_records_write on public.consent_records
  for all to authenticated
  using (
    requester_id = auth.uid()
    or app.is_own_patient(subject_patient_id)
    or app.has_role(array['system_admin']::public.user_role[])
  )
  with check (app.is_health_worker() or requester_id = auth.uid());

-- ---------------------------------------------------------------------------
-- Ambulance and teleconsult
-- ---------------------------------------------------------------------------
create policy ambulance_requests_read on public.ambulance_requests
  for select to authenticated using (
    requested_by = auth.uid()
    or app.is_own_patient(patient_id)
    or (app.is_facility_staff() and destination_facility_id = app.current_facility_id())
    or (app.is_administrator() and app.can_see_district(district_id))
    or app.has_role(array['system_admin', 'state_admin']::public.user_role[])
  );

create policy ambulance_requests_insert on public.ambulance_requests
  for insert to authenticated with check (
    app.is_health_worker() or app.is_own_patient(patient_id)
  );

create policy teleconsult_sessions_read on public.teleconsult_sessions
  for select to authenticated using (
    requested_by = auth.uid()
    or app.is_own_patient(patient_id)
    or (app.is_facility_staff() and facility_id = app.current_facility_id())
    or app.has_role(array['system_admin', 'state_admin']::public.user_role[])
  );

create policy teleconsult_sessions_insert on public.teleconsult_sessions
  for insert to authenticated with check (
    app.is_health_worker() or app.is_own_patient(patient_id)
  );

-- ---------------------------------------------------------------------------
-- Restricted internals: no policy for `authenticated` means no access at all.
-- Reached only by SECURITY DEFINER functions or the service role.
-- ---------------------------------------------------------------------------
create policy audit_logs_system_admin_read on public.audit_logs
  for select to authenticated
  using (app.has_role(array['system_admin']::public.user_role[]));

create policy domain_events_admin_read on public.domain_events
  for select to authenticated using (app.is_administrator());

create policy integration_transactions_admin_read on public.integration_transactions
  for select to authenticated
  using (app.has_role(array['system_admin']::public.user_role[]));

-- idempotency_keys: intentionally no policy. Only definer functions touch it.

-- ---------------------------------------------------------------------------
-- Execute grants for the client-callable RPC surface (PRD 13)
-- ---------------------------------------------------------------------------
revoke execute on all functions in schema public from anon;

grant execute on function public.run_triage(uuid, text[], integer, integer, text, public.language_code, jsonb, text) to authenticated;
grant execute on function public.search_facilities(double precision, double precision, text[], smallint, integer, boolean, integer) to authenticated;
grant execute on function public.refresh_facility_readiness(uuid) to authenticated;
grant execute on function public.create_referral(uuid, uuid, uuid, public.referral_priority, text, text, uuid, jsonb, integer, timestamptz, text) to authenticated;
grant execute on function public.accept_referral(uuid, text) to authenticated;
grant execute on function public.reject_referral(uuid, text) to authenticated;
grant execute on function public.advance_referral(uuid, public.referral_status, text, text) to authenticated;
grant execute on function public.cancel_referral(uuid, text) to authenticated;
grant execute on function public.escalate_referral(uuid, text) to authenticated;
grant execute on function public.reroute_referral(uuid, uuid, jsonb) to authenticated;
grant execute on function public.mark_notification_read(uuid) to authenticated;

-- Scheduled/maintenance and adapter-facing functions: service role only.
revoke execute on function public.expire_stale_referrals() from anon, authenticated;
revoke execute on function public.refresh_followup_states() from anon, authenticated;
revoke execute on function public.log_integration_start(public.external_system, text, jsonb, uuid, uuid, boolean, text) from anon, authenticated;
revoke execute on function public.log_integration_finish(uuid, public.integration_status, jsonb, integer, text, text) from anon, authenticated;
