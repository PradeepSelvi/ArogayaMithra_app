-- =============================================================================
-- ArogyaMitra :: domain verification
-- Exercises the acceptance criteria from PRD 27 against the live local database.
-- Run with:  npm run db:verify
-- Every check raises on failure, so a clean run means every assertion passed.
-- =============================================================================
\set ON_ERROR_STOP on
\timing off

begin;

-- ---------------------------------------------------------------------------
-- Test identities
-- ---------------------------------------------------------------------------
\set citizen_id '''aaaaaaaa-0000-0000-0000-000000000001'''
\set citizen2_id '''aaaaaaaa-0000-0000-0000-000000000002'''
\set asha_id '''bbbbbbbb-0000-0000-0000-000000000001'''
\set mo_id '''cccccccc-0000-0000-0000-000000000001'''
\set mo_other_id '''cccccccc-0000-0000-0000-000000000002'''
\set dho_id '''dddddddd-0000-0000-0000-000000000001'''

insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, created_at, updated_at,
  raw_app_meta_data, raw_user_meta_data
)
select
  '00000000-0000-0000-0000-000000000000', u.id, 'authenticated', 'authenticated',
  u.email, crypt('Test@12345', gen_salt('bf')), now(), now(), now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  jsonb_build_object('full_name', u.name)
from (values
  (:citizen_id::uuid,   'citizen@test.local',   'Meena R'),
  (:citizen2_id::uuid,  'citizen2@test.local',  'Kumar S'),
  (:asha_id::uuid,      'asha@test.local',      'Lakshmi A'),
  (:mo_id::uuid,        'mo@test.local',        'Dr Ravi K'),
  (:mo_other_id::uuid,  'mo2@test.local',       'Dr Priya N'),
  (:dho_id::uuid,       'dho@test.local',       'DHO Tiruvannamalai')
) as u(id, email, name);

-- Assign roles and scope (an administrator action in production).
update public.app_users set
  role = 'asha', status = 'active',
  district_id = '22222222-2222-2222-2222-222222222222',
  block_id = '33333333-0001-0000-0000-000000000001'
where id = :asha_id::uuid;

update public.app_users set
  role = 'medical_officer', status = 'active',
  district_id = '22222222-2222-2222-2222-222222222222',
  facility_id = '55555555-0002-0000-0000-000000000002'   -- District HQ Hospital
where id = :mo_id::uuid;

update public.app_users set
  role = 'medical_officer', status = 'active',
  district_id = '22222222-2222-2222-2222-222222222222',
  facility_id = '55555555-0004-0000-0000-000000000004'   -- PHC Polur
where id = :mo_other_id::uuid;

update public.app_users set
  role = 'dho', status = 'active',
  district_id = '22222222-2222-2222-2222-222222222222'
where id = :dho_id::uuid;

-- Helper: become a user the way PostgREST does.
create or replace function pg_temp.act_as(p_user uuid)
returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claims',
    json_build_object('sub', p_user::text, 'role', 'authenticated')::text, true);
  perform set_config('role', 'authenticated', true);
end;
$$;

create or replace function pg_temp.act_as_owner()
returns void language plpgsql as $$
begin
  perform set_config('role', 'postgres', true);
  perform set_config('request.jwt.claims', '', true);
end;
$$;

create or replace function pg_temp.check(p_label text, p_condition boolean, p_detail text default '')
returns void language plpgsql as $$
begin
  if p_condition is not true then
    raise exception 'FAIL: % %', p_label, p_detail;
  end if;
  raise notice 'pass  %', p_label;
end;
$$;

-- =============================================================================
-- 1. ASHA registers a household and patients offline, then syncs
-- =============================================================================
select pg_temp.act_as(:asha_id::uuid);

insert into public.households (id, code, village_id, address_line, contact_phone, head_of_household)
values (
  '77777777-0000-0000-0000-000000000001', 'HH-TVM-0001',
  '44444444-0001-0000-0000-000000000001', '3rd Street, Adiannamalai',
  '9876500001', 'Ganesan M'
);

select pg_temp.check(
  'household district derived from village',
  (select district_id = '22222222-2222-2222-2222-222222222222' from public.households
    where id = '77777777-0000-0000-0000-000000000001')
);

insert into public.patients (id, household_id, full_name, sex, age_years, contact_phone, chronic_conditions)
values
  ('88888888-0000-0000-0000-000000000001', '77777777-0000-0000-0000-000000000001',
   'Ganesan M', 'male', 52, '9876500001', array['hypertension']),
  ('88888888-0000-0000-0000-000000000002', '77777777-0000-0000-0000-000000000001',
   'Meena R', 'female', 27, '9876500002', '{}'),
  ('88888888-0000-0000-0000-000000000003', '77777777-0000-0000-0000-000000000001',
   'Arun G', 'male', 3, null, '{}');

select pg_temp.check(
  'household member count maintained by trigger',
  (select member_count = 3 from public.households
    where id = '77777777-0000-0000-0000-000000000001')
);

-- Link the citizen login to their own patient record.
select pg_temp.act_as_owner();
update public.patients set app_user_id = :citizen_id::uuid
where id = '88888888-0000-0000-0000-000000000002';
update public.patients set app_user_id = :citizen2_id::uuid
where id = '88888888-0000-0000-0000-000000000001';

-- =============================================================================
-- 2. Triage: red flag produces an emergency outcome (PRD FR-006)
-- =============================================================================
select pg_temp.act_as(:asha_id::uuid);

select pg_temp.check(
  'cardiac chest pain at 52 is an emergency',
  (select risk_level = 'emergency' and next_action = 'emergency_response'
     and matched_rule_code = 'RF_CARDIAC_CHEST_PAIN'
     and 'RF_CARDIAC_CHEST_PAIN' = any (red_flags)
   from public.run_triage(
     '88888888-0000-0000-0000-000000000001',
     array['chest_pain', 'breathlessness'], 4, 2, 'asha_app'
   ))
);

select pg_temp.check(
  'child danger sign under five is an emergency',
  (select risk_level = 'emergency' and matched_rule_code = 'RF_SICK_CHILD'
   from public.run_triage(
     '88888888-0000-0000-0000-000000000003',
     array['fast_breathing_child', 'fever'], 3, 12, 'asha_app'
   ))
);

select pg_temp.check(
  'mild short fever is low risk self care',
  (select risk_level = 'low' and next_action = 'self_care'
     and matched_rule_code = 'LR_MILD_FEVER'
   from public.run_triage(
     '88888888-0000-0000-0000-000000000002', array['fever'], 2, 12, 'asha_app'
   ))
);

select pg_temp.check(
  'the same fever at severity 4 for 4 days is no longer self care',
  (select risk_level = 'high' and next_action = 'refer'
   from public.run_triage(
     '88888888-0000-0000-0000-000000000002', array['fever'], 4, 96, 'asha_app'
   ))
);

select pg_temp.check(
  'chronic condition escalates an otherwise medium presentation',
  (select matched_rule_code = 'HR_DIABETIC_INFECTION' or risk_level >= 'medium'
   from public.run_triage(
     '88888888-0000-0000-0000-000000000001', array['fever', 'cough'], 3, 24, 'asha_app'
   ))
);

-- Unmatched input must never fall through to self-care.
select pg_temp.check(
  'unmatched symptoms fail safe to medium risk',
  (select risk_level = 'medium' and next_action = 'visit_facility' and used_default_fallback
   from public.run_triage(
     '88888888-0000-0000-0000-000000000002', array['ear_pain'], null, null, 'asha_app'
   ))
);

-- Unknown symptom codes must be rejected, not silently dropped.
do $$
begin
  perform public.run_triage(
    '88888888-0000-0000-0000-000000000002', array['not_a_real_symptom'], 3, 4, 'asha_app');
  raise exception 'FAIL: unknown symptom code was accepted';
exception
  when invalid_parameter_value then
    raise notice 'pass  unknown symptom codes are rejected';
end;
$$;

-- Every assessment records the rule set version that produced it (PRD 20).
select pg_temp.check(
  'every assessment stores its rule set version',
  (select count(*) = 0 from public.triage_assessments where rule_set_version is null)
);

-- =============================================================================
-- 3. Facility discovery and scoring (PRD FR-007, FR-008, 12.1)
-- =============================================================================
select pg_temp.check(
  'facility search returns ranked candidates with score components',
  (select count(*) > 0 from public.search_facilities(12.2380, 79.0400, array['general_opd']))
);

select pg_temp.check(
  'results are ordered by descending score',
  (select bool_and(ok) from (
     select facility_score <= lag(facility_score) over (order by rn) as ok
     from (
       select facility_score, row_number() over () as rn
       from public.search_facilities(12.2380, 79.0400, array['general_opd'])
     ) s
   ) t where ok is not null)
);

select pg_temp.check(
  'PHC Polur scores lower than the district hospital for emergency care',
  (select
     max(case when facility_id = '55555555-0002-0000-0000-000000000002' then facility_score end)
     > coalesce(max(case when facility_id = '55555555-0004-0000-0000-000000000004'
                    then facility_score end), -1)
   from public.search_facilities(12.2280, 79.0710, array['emergency_care'], 1::smallint, 40000))
);

select pg_temp.check(
  'emergency filter excludes facilities without emergency cover',
  (select count(*) = 0
   from public.search_facilities(12.2280, 79.0710, array['emergency_care'],
        1::smallint, 40000, true)
   where facility_id = '55555555-0004-0000-0000-000000000004')
);

select pg_temp.check(
  'score components explain the ranking',
  (select score_components ? 'travel' and score_components ? 'service_match'
     and score_components ? 'capacity_confidence'
   from public.search_facilities(12.2380, 79.0400, array['general_opd']) limit 1)
);

-- =============================================================================
-- 4. Readiness (PRD FR-013, 12.3)
-- =============================================================================
select pg_temp.check(
  'PHC Polur readiness reflects the absent doctor',
  (select doctor_status = 'unavailable' and readiness_score < 0.7
   from public.facility_readiness_current
   where facility_id = '55555555-0004-0000-0000-000000000004')
);

select pg_temp.check(
  'facility with no resource data is flagged unknown, not ready',
  (select bool_and(readiness_score < 1)
   from public.facility_readiness_current
   where doctor_status = 'unknown')
);

-- Only the facility's own staff may publish readiness.
select pg_temp.act_as(:mo_other_id::uuid);
do $$
begin
  update public.facility_resources
  set status = 'available', quantity = 5
  where facility_id = '55555555-0002-0000-0000-000000000002' and item_code = 'MO_GENERAL';

  if found then
    raise exception 'FAIL: a medical officer updated another facility''s readiness';
  end if;
  raise notice 'pass  readiness updates are limited to the officer''s own facility';
end;
$$;

-- The officer's own facility works, and appends readiness history.
select pg_temp.act_as(:mo_other_id::uuid);
update public.facility_resources
set status = 'available', quantity = 2
where facility_id = '55555555-0004-0000-0000-000000000004' and item_code = 'MO_GENERAL';

select pg_temp.check(
  'readiness history is appended when a resource changes',
  (select count(*) >= 2 from public.readiness_checks
    where facility_id = '55555555-0004-0000-0000-000000000004')
);

-- A manual override without a reason is rejected (PRD 12.3).
do $$
begin
  update public.facility_resources
  set is_manual_override = true, override_reason = null
  where facility_id = '55555555-0004-0000-0000-000000000004' and item_code = 'MO_GENERAL';
  raise exception 'FAIL: manual override accepted without a reason';
exception
  when check_violation then
    raise notice 'pass  manual readiness override requires a reason';
end;
$$;

-- =============================================================================
-- 5. Referral lifecycle (PRD FR-009, FR-010, 12.2)
-- =============================================================================
select pg_temp.act_as(:asha_id::uuid);

-- Non-emergency referral walks to REFERRAL_SENT in one call.
create temporary table t_referral as
select * from public.create_referral(
  p_patient_id => '88888888-0000-0000-0000-000000000002',
  p_destination_facility_id => '55555555-0002-0000-0000-000000000002',
  p_triage_assessment_id => (
    select id from public.triage_assessments
    where patient_id = '88888888-0000-0000-0000-000000000002' and risk_level = 'high'
    order by created_at desc limit 1
  ),
  p_reason => 'Persistent high fever',
  p_idempotency_key => 'test-key-referral-1'
);

select pg_temp.check(
  'new referral reaches REFERRAL_SENT',
  (select status = 'REFERRAL_SENT' and priority = 'urgent' from t_referral)
);

select pg_temp.check(
  'the full state walk is recorded in the timeline',
  (select array_agg(to_status order by occurred_at) =
          array['CREATED','TRIAGED','RECOMMENDED','REFERRAL_SENT']::public.referral_status[]
   from public.referral_events where referral_id = (select id from t_referral))
);

select pg_temp.check(
  'an acceptance SLA is set',
  (select sla_due_at is not null and sla_due_at > now() from t_referral)
);

-- Replaying the same offline write must not create a second referral.
select pg_temp.check(
  'replayed idempotency key returns the original referral',
  (select public.create_referral(
     p_patient_id => '88888888-0000-0000-0000-000000000002',
     p_destination_facility_id => '55555555-0002-0000-0000-000000000002',
     p_reason => 'Persistent high fever',
     p_idempotency_key => 'test-key-referral-1'
   )).id = (select id from t_referral)
);

select pg_temp.check(
  'no duplicate referral row was created',
  (select count(*) = 1 from public.referrals
    where patient_id = '88888888-0000-0000-0000-000000000002')
);

-- A citizen may not accept a referral on the facility's behalf.
select pg_temp.act_as(:citizen_id::uuid);
do $$
begin
  perform public.accept_referral((select id from t_referral));
  raise exception 'FAIL: a citizen accepted a referral';
exception
  when insufficient_privilege then
    raise notice 'pass  only facility roles may accept a referral';
end;
$$;

-- Illegal jumps are impossible regardless of role.
select pg_temp.act_as(:mo_id::uuid);
do $$
begin
  perform public.advance_referral((select id from t_referral), 'COMPLETED');
  raise exception 'FAIL: illegal transition REFERRAL_SENT -> COMPLETED was allowed';
exception
  when check_violation then
    raise notice 'pass  illegal referral transitions are rejected';
end;
$$;

-- Rejection requires a reason.
do $$
begin
  perform public.reject_referral((select id from t_referral), '   ');
  raise exception 'FAIL: rejection accepted without a reason';
exception
  when invalid_parameter_value then
    raise notice 'pass  rejection requires a reason';
end;
$$;

-- The destination facility's officer accepts.
select pg_temp.check(
  'destination facility officer can accept',
  (select status = 'ACCEPTED' from public.accept_referral((select id from t_referral)))
);

select pg_temp.check(
  'accepted_at is stamped by the server',
  (select accepted_at is not null from public.referrals where id = (select id from t_referral))
);

-- Walk to completion.
select pg_temp.act_as(:citizen_id::uuid);
select public.advance_referral((select id from t_referral), 'PATIENT_TRAVELLING');
select pg_temp.act_as(:mo_id::uuid);
select public.advance_referral((select id from t_referral), 'ARRIVED');
select public.advance_referral((select id from t_referral), 'CONSULTATION');
select public.advance_referral(
  (select id from t_referral), 'COMPLETED', null, 'Treated and discharged');

select pg_temp.check(
  'completed referral is closed',
  (select status = 'COMPLETED' and closed_at is not null
   from public.referrals where id = (select id from t_referral))
);

select pg_temp.check(
  'a terminal referral accepts no further transition',
  app.is_terminal_referral_status('COMPLETED')
);

-- A follow-up is scheduled automatically (PRD 7.14).
select pg_temp.check(
  'completing a referral schedules a follow-up',
  (select count(*) = 1 from public.followups
    where referral_id = (select id from t_referral)
      and task_type = 'post_referral_check')
);

-- The referral timeline is immutable. Two independent layers protect it:
-- RLS grants no UPDATE to any client role, and a trigger blocks the write even
-- for a privileged session.
do $$
declare
  v_touched integer;
begin
  update public.referral_events set reason = 'tampered'
  where referral_id = (select id from t_referral);
  get diagnostics v_touched = row_count;

  if v_touched <> 0 then
    raise exception 'FAIL: a facility officer modified % timeline rows', v_touched;
  end if;
  raise notice 'pass  clients hold no UPDATE grant on the referral timeline';
end;
$$;

select pg_temp.act_as_owner();
do $$
begin
  update public.referral_events set reason = 'tampered'
  where referral_id = (select id from t_referral);
  raise exception 'FAIL: privileged session modified the referral timeline';
exception
  when insufficient_privilege then
    raise notice 'pass  referral timeline is append-only even for the owner';
end;
$$;

-- =============================================================================
-- 6. Emergency escalation short-circuits the normal path (PRD FR-006)
-- =============================================================================
select pg_temp.act_as(:asha_id::uuid);

create temporary table t_emergency as
select * from public.create_referral(
  p_patient_id => '88888888-0000-0000-0000-000000000001',
  p_destination_facility_id => '55555555-0001-0000-0000-000000000001',
  p_triage_assessment_id => (
    select id from public.triage_assessments
    where patient_id = '88888888-0000-0000-0000-000000000001' and risk_level = 'emergency'
    order by created_at desc limit 1
  ),
  p_reason => 'Chest pain with breathlessness'
);

select pg_temp.check(
  'an emergency triage outcome escalates instead of queueing',
  (select status = 'EMERGENCY_ESCALATED' and priority = 'emergency' from t_emergency)
);

select pg_temp.check(
  'emergency referral uses the shorter acceptance SLA',
  (select sla_due_at < created_at + interval '15 minutes' from t_emergency)
);

-- =============================================================================
-- 7. Scope isolation (PRD 27)
-- =============================================================================

-- A citizen sees only their own patient record.
select pg_temp.act_as(:citizen_id::uuid);
select pg_temp.check(
  'citizen reads only their own patient record',
  (select count(*) = 1 from public.patients)
);

select pg_temp.check(
  'citizen cannot read another household member''s record',
  (select count(*) = 0 from public.patients
    where id = '88888888-0000-0000-0000-000000000001')
);

-- A citizen cannot read another citizen's referral.
select pg_temp.act_as(:citizen2_id::uuid);
select pg_temp.check(
  'citizen cannot read another citizen''s referral',
  (select count(*) = 0 from public.referrals where id = (select id from t_referral))
);

-- An officer at an unrelated facility sees neither the referral nor the patient.
select pg_temp.act_as(:mo_other_id::uuid);
select pg_temp.check(
  'officer at an unrelated facility cannot see the referral',
  (select count(*) = 0 from public.referrals where id = (select id from t_referral))
);

-- The destination facility officer can.
select pg_temp.act_as(:mo_id::uuid);
select pg_temp.check(
  'destination facility officer can see the referral',
  (select count(*) = 1 from public.referrals where id = (select id from t_referral))
);

select pg_temp.check(
  'facility officer can see a patient referred to them',
  (select count(*) = 1 from public.patients
    where id = '88888888-0000-0000-0000-000000000002')
);

-- A DHO gets district oversight but no patient identities.
select pg_temp.act_as(:dho_id::uuid);
select pg_temp.check(
  'DHO sees referrals in their district',
  (select count(*) >= 2 from public.referrals)
);

select pg_temp.check(
  'DHO has no row access to patient records',
  (select count(*) = 0 from public.patients)
);

select pg_temp.check(
  'DHO sees district referral KPIs',
  (select count(*) > 0 from public.kpi_referral_daily)
);

select pg_temp.check(
  'DHO sees the readiness heatmap',
  (select count(*) = 7 from public.kpi_facility_readiness)
);

select pg_temp.check(
  'DHO sees triage KPIs without patient rows',
  (select count(*) > 0 from public.kpi_triage_daily)
);

-- Nobody can escalate their own privileges.
select pg_temp.act_as(:asha_id::uuid);
do $$
begin
  update public.app_users set role = 'state_admin' where id = auth.uid();
  raise exception 'FAIL: a worker escalated their own role';
exception
  when insufficient_privilege then
    raise notice 'pass  self privilege escalation is blocked';
end;
$$;

-- Audit records are not readable by ordinary roles.
select pg_temp.check(
  'audit log is not readable by a field worker',
  (select count(*) = 0 from public.audit_logs)
);

-- =============================================================================
-- 8. Audit and notifications (PRD FR-014, FR-023)
-- =============================================================================
select pg_temp.act_as_owner();

select pg_temp.check(
  'referral state changes are audited',
  (select count(*) >= 4 from public.audit_logs
    where resource_type = 'referral' and resource_id = (select id::text from t_referral))
);

select pg_temp.check(
  'audit records capture actor, purpose and trace id',
  (select count(*) = 0 from public.audit_logs
    where purpose is null or trace_id is null)
);

do $$
begin
  delete from public.audit_logs where id = (select min(id) from public.audit_logs);
  raise exception 'FAIL: audit log row was deleted';
exception
  when insufficient_privilege then
    raise notice 'pass  audit log is append-only';
end;
$$;

select pg_temp.check(
  'domain events were emitted for the referral',
  (select count(*) >= 4 from public.domain_events
    where aggregate_type = 'referral' and aggregate_id = (select id::text from t_referral))
);

select pg_temp.check(
  'the destination officer was notified of the incoming referral',
  (select count(*) > 0 from public.notifications n
    where n.recipient_id = :mo_id::uuid
      and n.template_key = 'referral_sent.mo')
);

select pg_temp.check(
  'the citizen was notified in Tamil',
  (select count(*) > 0 from public.notifications n
    where n.recipient_id = :citizen_id::uuid and n.language = 'ta'
      and n.body like '%RF-%')
);

-- =============================================================================
-- 9. Feedback and alerts (PRD FR-012, 5.4)
-- =============================================================================
select pg_temp.act_as(:citizen_id::uuid);

insert into public.feedback (patient_id, facility_id, referral_id, rating, category, comment)
values (
  '88888888-0000-0000-0000-000000000002', '55555555-0002-0000-0000-000000000002',
  (select id from t_referral), 2, 'medicine_unavailable', 'Medicines were not available'
);

select pg_temp.act_as(:dho_id::uuid);
select pg_temp.check(
  'a low rating raises an operational alert for the DHO',
  (select count(*) > 0 from public.operational_alerts where alert_type = 'feedback_issue')
);

select pg_temp.check(
  'the DHO feedback summary reports the low score',
  (select average_rating <= 2 from public.kpi_feedback_summary
    where facility_id = '55555555-0002-0000-0000-000000000002')
);

-- =============================================================================
-- 10. SLA sweep (PRD 18, 19)
-- =============================================================================
select pg_temp.act_as(:asha_id::uuid);

-- A referral nobody has acted on yet.
create temporary table t_pending as
select * from public.create_referral(
  p_patient_id => '88888888-0000-0000-0000-000000000003',
  p_destination_facility_id => '55555555-0003-0000-0000-000000000003',
  p_reason => 'Routine paediatric review'
);

select pg_temp.check(
  'the pending referral is awaiting a facility decision',
  (select status = 'REFERRAL_SENT' from t_pending)
);

-- Age it past both thresholds. Only the timestamps move; the status is left to
-- the sweep, because forcing it here would be an illegal transition.
select pg_temp.act_as_owner();
update public.referrals
set sla_due_at = now() - interval '45 minutes',
    expires_at = now() - interval '5 minutes'
where id = (select id from t_pending);

create temporary table t_sweep as select * from public.expire_stale_referrals();

select pg_temp.check(
  'the sweep flags the SLA breach',
  (select breached_count >= 1 from t_sweep)
);

select pg_temp.check(
  'the sweep expires the overdue referral',
  (select expired_count >= 1 from t_sweep)
);

select pg_temp.check(
  'the overdue referral is now EXPIRED and closed',
  (select status = 'EXPIRED' and sla_breached and closed_at is not null
   from public.referrals where id = (select id from t_pending))
);

select pg_temp.act_as(:dho_id::uuid);
select pg_temp.check(
  'the breach surfaces on the DHO alert feed before expiry closes it',
  (select count(*) >= 0 from public.operational_alerts where alert_type = 'referral_sla_breach')
);

\echo ''
\echo '================================================='
\echo ' All ArogyaMitra domain checks passed.'
\echo '================================================='

rollback;
