-- =============================================================================
-- ArogyaMitra :: 0007 Deterministic, versioned triage engine
-- PRD refs: 6 FR-004/FR-005/FR-006, 11 (TriageAssessment), 16, 20
--
-- Design notes
--   * Rules are data, not code: clinically owned, versioned and approved.
--   * Red-flag rules are always evaluated before everything else.
--   * When no rule matches, the engine fails safe to medium risk and a facility
--     visit. It never falls back to self-care.
--   * Every assessment stores the rule set version and matched rule code, so a
--     past decision can always be explained (PRD 20).
-- =============================================================================

create table public.symptom_catalog (
  code text primary key,
  name_en text not null,
  name_ta text not null,
  body_system text not null,
  -- Shown in the citizen "quick pick" grid (PRD 5.1 low-literacy flows).
  is_common boolean not null default false,
  icon_key text,
  display_order smallint not null default 100,
  created_at timestamptz not null default now()
);

comment on table public.symptom_catalog is
  'Structured symptom vocabulary. Localised labels only, no free text.';

-- ---------------------------------------------------------------------------
-- Clinically governed rule sets (PRD 16: documented owner, version, approval)
-- ---------------------------------------------------------------------------
create table public.triage_rule_sets (
  id uuid primary key default gen_random_uuid(),
  version integer not null unique,
  name text not null,
  status text not null default 'draft' check (status in ('draft', 'active', 'retired')),
  clinical_owner text not null,
  approved_by uuid references public.app_users (id) on delete set null,
  approved_at timestamptz,
  effective_from timestamptz,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  -- An active rule set must have been signed off.
  constraint triage_rule_sets_active_requires_approval check (
    status <> 'active' or approved_at is not null
  )
);

create unique index triage_rule_sets_one_active_idx
  on public.triage_rule_sets (status)
  where status = 'active';

create trigger triage_rule_sets_touch before update on public.triage_rule_sets
  for each row execute function app.touch_updated_at();

create trigger triage_rule_sets_audit
  after insert or update or delete on public.triage_rule_sets
  for each row execute function app.audit_row('triage_rule_set');

-- ---------------------------------------------------------------------------
-- Individual rules.
-- `match` is a JSON predicate evaluated by app.triage_rule_matches:
--   any_symptoms        text[]  - at least one must be present
--   all_symptoms        text[]  - every one must be present
--   none_symptoms       text[]  - none may be present
--   min_age / max_age   int     - inclusive age bounds in years
--   min_severity        int     - 1..5 self-reported severity
--   max_severity        int     - 1..5 self-reported severity
--   min_duration_hours  int
--   max_duration_hours  int
--   pregnant            bool    - patient pregnancy flag must equal this
--   chronic_any         text[]  - at least one chronic condition must match
-- Omitted keys are simply not constrained.
-- ---------------------------------------------------------------------------
create table public.triage_rules (
  id uuid primary key default gen_random_uuid(),
  rule_set_id uuid not null references public.triage_rule_sets (id) on delete cascade,
  code text not null,
  description text not null,
  -- Red flags win over everything else regardless of priority.
  is_red_flag boolean not null default false,
  priority smallint not null default 100,
  match jsonb not null,
  risk_level public.risk_level not null,
  next_action public.next_action not null,
  -- Services the destination facility must offer (feeds facility scoring).
  required_services text[] not null default '{}',
  -- Minimum facility tier the patient should be routed to.
  min_facility_tier smallint not null default 1 check (min_facility_tier between 1 and 4),
  advice_key text not null,
  created_at timestamptz not null default now(),
  unique (rule_set_id, code),

  -- Guardrail: an emergency outcome must trigger the emergency pathway.
  constraint triage_rules_emergency_consistency check (
    (risk_level = 'emergency') = (next_action = 'emergency_response')
  ),
  -- Guardrail: self-care is only ever allowed for low risk.
  constraint triage_rules_self_care_low_risk_only check (
    next_action <> 'self_care' or risk_level = 'low'
  )
);

create index triage_rules_set_idx on public.triage_rules (rule_set_id, is_red_flag desc, priority desc);

create trigger triage_rules_audit
  after insert or update or delete on public.triage_rules
  for each row execute function app.audit_row('triage_rule');

-- ---------------------------------------------------------------------------
-- TriageAssessment (PRD 11)
-- ---------------------------------------------------------------------------
create table public.triage_assessments (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  assessed_by uuid references public.app_users (id) on delete set null,
  channel text not null default 'citizen_app'
    check (channel in ('citizen_app', 'asha_app', 'facility', 'ussd', 'ivr')),
  input_language public.language_code not null default 'ta',
  symptoms text[] not null,
  severity smallint check (severity between 1 and 5),
  duration_hours integer check (duration_hours >= 0),
  answers jsonb not null default '{}'::jsonb,
  -- Outcome
  risk_level public.risk_level not null,
  next_action public.next_action not null,
  red_flags text[] not null default '{}',
  required_services text[] not null default '{}',
  min_facility_tier smallint not null default 1,
  advice_key text not null,
  -- Explainability (PRD 20)
  rule_set_version integer not null,
  matched_rule_code text,
  used_default_fallback boolean not null default false,
  -- AI is advisory only and always labelled as such (PRD 20)
  ai_assisted boolean not null default false,
  ai_suggestion jsonb,
  created_at timestamptz not null default now()
);

create index triage_assessments_patient_idx on public.triage_assessments (patient_id, created_at desc);
create index triage_assessments_risk_idx on public.triage_assessments (risk_level, created_at desc);

comment on table public.triage_assessments is
  'Immutable triage outcome with the rule set version that produced it.';

-- ---------------------------------------------------------------------------
-- Predicate evaluation
-- ---------------------------------------------------------------------------
create or replace function app.triage_rule_matches(
  p_match jsonb,
  p_symptoms text[],
  p_age_years integer,
  p_severity integer,
  p_duration_hours integer,
  p_is_pregnant boolean,
  p_chronic text[]
)
returns boolean
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  v_any text[];
  v_all text[];
  v_none text[];
  v_chronic_any text[];
begin
  -- any_symptoms: at least one present
  if p_match ? 'any_symptoms' then
    select array_agg(value) into v_any
    from jsonb_array_elements_text(p_match -> 'any_symptoms');
    if v_any is not null and not (p_symptoms && v_any) then
      return false;
    end if;
  end if;

  -- all_symptoms: every one present
  if p_match ? 'all_symptoms' then
    select array_agg(value) into v_all
    from jsonb_array_elements_text(p_match -> 'all_symptoms');
    if v_all is not null and not (p_symptoms @> v_all) then
      return false;
    end if;
  end if;

  -- none_symptoms: none present
  if p_match ? 'none_symptoms' then
    select array_agg(value) into v_none
    from jsonb_array_elements_text(p_match -> 'none_symptoms');
    if v_none is not null and (p_symptoms && v_none) then
      return false;
    end if;
  end if;

  if p_match ? 'min_age' then
    if p_age_years is null or p_age_years < (p_match ->> 'min_age')::int then
      return false;
    end if;
  end if;

  if p_match ? 'max_age' then
    if p_age_years is null or p_age_years > (p_match ->> 'max_age')::int then
      return false;
    end if;
  end if;

  if p_match ? 'min_severity' then
    if p_severity is null or p_severity < (p_match ->> 'min_severity')::int then
      return false;
    end if;
  end if;

  -- max_severity is what makes a self-care rule specific enough to be safe:
  -- a mild symptom stops matching as soon as the citizen reports it worsening.
  if p_match ? 'max_severity' then
    if p_severity is null or p_severity > (p_match ->> 'max_severity')::int then
      return false;
    end if;
  end if;

  if p_match ? 'min_duration_hours' then
    if p_duration_hours is null or p_duration_hours < (p_match ->> 'min_duration_hours')::int then
      return false;
    end if;
  end if;

  if p_match ? 'max_duration_hours' then
    if p_duration_hours is null or p_duration_hours > (p_match ->> 'max_duration_hours')::int then
      return false;
    end if;
  end if;

  if p_match ? 'pregnant' then
    if coalesce(p_is_pregnant, false) <> (p_match ->> 'pregnant')::boolean then
      return false;
    end if;
  end if;

  if p_match ? 'chronic_any' then
    select array_agg(value) into v_chronic_any
    from jsonb_array_elements_text(p_match -> 'chronic_any');
    if v_chronic_any is not null and not (coalesce(p_chronic, '{}'::text[]) && v_chronic_any) then
      return false;
    end if;
  end if;

  return true;
end;
$$;

-- ---------------------------------------------------------------------------
-- Rule lookup helpers.
--
-- The rule tables are readable only by health workers, because a published rule
-- set is clinical governance material rather than citizen-facing content. But
-- run_triage must work for a citizen too, and it stays SECURITY INVOKER so that
-- reading the patient and writing the assessment are still checked by RLS.
--
-- These helpers are the narrow exception: they expose the *outcome* of matching
-- to any caller without exposing the rule set itself.
-- ---------------------------------------------------------------------------
create or replace function app.active_rule_set()
returns public.triage_rule_sets
language sql
stable
security definer
set search_path = ''
as $$
  select rs.* from public.triage_rule_sets rs where rs.status = 'active' limit 1;
$$;

create or replace function app.match_triage_rule(
  p_rule_set_id uuid,
  p_symptoms text[],
  p_age_years integer,
  p_severity integer,
  p_duration_hours integer,
  p_is_pregnant boolean,
  p_chronic text[]
)
returns public.triage_rules
language sql
stable
security definer
set search_path = ''
as $$
  select r.*
  from public.triage_rules r
  where r.rule_set_id = p_rule_set_id
    and app.triage_rule_matches(
      r.match, p_symptoms, p_age_years, p_severity,
      p_duration_hours, p_is_pregnant, p_chronic
    )
  -- Red flags outrank everything, then priority. First match wins.
  order by r.is_red_flag desc, r.priority desc, r.code asc
  limit 1;
$$;

create or replace function app.matched_red_flags(
  p_rule_set_id uuid,
  p_symptoms text[],
  p_age_years integer,
  p_severity integer,
  p_duration_hours integer,
  p_is_pregnant boolean,
  p_chronic text[]
)
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(array_agg(r.code order by r.priority desc), '{}')
  from public.triage_rules r
  where r.rule_set_id = p_rule_set_id
    and r.is_red_flag
    and app.triage_rule_matches(
      r.match, p_symptoms, p_age_years, p_severity,
      p_duration_hours, p_is_pregnant, p_chronic
    );
$$;

create or replace function app.unknown_symptom_codes(p_symptoms text[])
returns text[]
language sql
stable
security definer
set search_path = ''
as $$
  select array_agg(s)
  from unnest(p_symptoms) as s
  where not exists (select 1 from public.symptom_catalog c where c.code = s);
$$;

-- ---------------------------------------------------------------------------
-- public.run_triage : PRD 13 POST /api/v1/triage
-- ---------------------------------------------------------------------------
create or replace function public.run_triage(
  p_patient_id uuid,
  p_symptoms text[],
  p_severity integer default null,
  p_duration_hours integer default null,
  p_channel text default 'citizen_app',
  p_input_language public.language_code default 'ta',
  p_answers jsonb default '{}'::jsonb,
  p_idempotency_key text default null
)
returns public.triage_assessments
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_set public.triage_rule_sets;
  v_rule public.triage_rules;
  v_patient public.patients;
  v_unknown text[];
  v_red_flags text[] := '{}';
  v_assessment public.triage_assessments;
  v_cached jsonb;
begin
  if p_symptoms is null or array_length(p_symptoms, 1) is null then
    raise exception 'At least one symptom is required' using errcode = 'invalid_parameter_value';
  end if;

  -- Replay protection for offline sync (PRD 15).
  if p_idempotency_key is not null then
    v_cached := app.idempotency_lookup(p_idempotency_key, 'run_triage');

    if v_cached is not null then
      select * into v_assessment
      from public.triage_assessments t
      where t.id = (v_cached ->> 'id')::uuid;
      if v_assessment.id is not null then
        return v_assessment;
      end if;
    end if;
  end if;

  select * into v_patient from public.patients p where p.id = p_patient_id;
  if v_patient.id is null then
    raise exception 'Patient % not found', p_patient_id using errcode = 'no_data_found';
  end if;

  -- Reject unknown symptom codes rather than silently ignoring them: a dropped
  -- symptom could downgrade risk.
  v_unknown := app.unknown_symptom_codes(p_symptoms);
  if v_unknown is not null then
    raise exception 'Unknown symptom codes: %', v_unknown using errcode = 'invalid_parameter_value';
  end if;

  v_set := app.active_rule_set();
  if v_set.id is null then
    raise exception 'No active triage rule set is configured'
      using errcode = 'configuration_limit_exceeded';
  end if;

  v_rule := app.match_triage_rule(
    v_set.id, p_symptoms, v_patient.age_years, p_severity,
    p_duration_hours, v_patient.is_pregnant, v_patient.chronic_conditions
  );

  -- Every red flag that fired, for the record and for the UI.
  v_red_flags := app.matched_red_flags(
    v_set.id, p_symptoms, v_patient.age_years, p_severity,
    p_duration_hours, v_patient.is_pregnant, v_patient.chronic_conditions
  );

  insert into public.triage_assessments (
    patient_id, assessed_by, channel, input_language, symptoms, severity,
    duration_hours, answers, risk_level, next_action, red_flags,
    required_services, min_facility_tier, advice_key,
    rule_set_version, matched_rule_code, used_default_fallback
  )
  values (
    p_patient_id, auth.uid(), p_channel, p_input_language, p_symptoms, p_severity,
    p_duration_hours, coalesce(p_answers, '{}'::jsonb),
    -- Fail safe: unmatched input is never self-care.
    coalesce(v_rule.risk_level, 'medium'),
    coalesce(v_rule.next_action, 'visit_facility'),
    v_red_flags,
    coalesce(v_rule.required_services, array['general_opd']),
    coalesce(v_rule.min_facility_tier, 1),
    coalesce(v_rule.advice_key, 'advice.default_visit_facility'),
    v_set.version,
    v_rule.code,
    v_rule.id is null
  )
  returning * into v_assessment;

  if p_idempotency_key is not null then
    perform app.idempotency_remember(
      p_idempotency_key, 'run_triage', jsonb_build_object('id', v_assessment.id)
    );
  end if;

  perform app.write_audit(
    'triage.run', 'triage_assessment', v_assessment.id::text, null,
    to_jsonb(v_assessment) - 'answers'
  );

  return v_assessment;
end;
$$;

comment on function public.run_triage is
  'Deterministic triage. Returns risk level, next action and the rule set '
  'version that produced the decision (PRD FR-005, FR-006).';
