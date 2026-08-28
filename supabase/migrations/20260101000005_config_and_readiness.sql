-- =============================================================================
-- ArogyaMitra :: 0005 Versioned configuration + facility readiness
-- PRD refs: 6 FR-013, 11 (ReadinessCheck), 12.1, 12.3, 16 (versioned rules)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- config_versions : every tunable weight, threshold and SLA lives here, with
-- a version, an approver and an audit trail. Nothing is hard-coded (PRD 12.1).
-- ---------------------------------------------------------------------------
create table public.config_versions (
  id uuid primary key default gen_random_uuid(),
  config_key text not null,
  version integer not null,
  payload jsonb not null,
  status text not null default 'draft' check (status in ('draft', 'active', 'retired')),
  effective_from timestamptz,
  approved_by uuid references public.app_users (id) on delete set null,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (config_key, version)
);

-- Exactly one active version per config key.
create unique index config_versions_one_active_idx
  on public.config_versions (config_key)
  where status = 'active';

create trigger config_versions_touch before update on public.config_versions
  for each row execute function app.touch_updated_at();

create trigger config_versions_audit
  after insert or update or delete on public.config_versions
  for each row execute function app.audit_row('config_version');

comment on table public.config_versions is
  'Versioned, auditable configuration: readiness weights, facility scoring '
  'weights, referral SLAs, staleness thresholds.';

create or replace function app.active_config(p_key text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select c.payload
  from public.config_versions c
  where c.config_key = p_key and c.status = 'active'
  limit 1;
$$;

create or replace function app.active_config_version(p_key text)
returns integer
language sql
stable
security definer
set search_path = ''
as $$
  select c.version
  from public.config_versions c
  where c.config_key = p_key and c.status = 'active'
  limit 1;
$$;

-- ---------------------------------------------------------------------------
-- Availability -> numeric contribution.
-- 'unknown' scores zero and is separately penalised through confidence, so a
-- facility can never look ready just because nobody updated it.
-- ---------------------------------------------------------------------------
create or replace function app.availability_weight(p_status public.availability_status)
returns numeric
language sql
immutable
security invoker
set search_path = ''
as $$
  select case p_status
    when 'available' then 1.0
    when 'limited' then 0.5
    when 'unavailable' then 0.0
    else 0.0
  end::numeric;
$$;

-- Worst-case rollup of a resource group into a single status.
create or replace function app.rollup_status(p_facility_id uuid, p_kinds public.resource_kind[])
returns public.availability_status
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_total int;
  v_available int;
  v_limited int;
begin
  select
    count(*),
    count(*) filter (where r.status = 'available'),
    count(*) filter (where r.status = 'limited')
  into v_total, v_available, v_limited
  from public.facility_resources r
  where r.facility_id = p_facility_id
    and r.kind = any (p_kinds);

  if v_total = 0 then
    return 'unknown';
  elsif v_available = v_total then
    return 'available';
  elsif v_available + v_limited = 0 then
    return 'unavailable';
  else
    return 'limited';
  end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- ReadinessCheck (PRD 11): immutable snapshot with component detail.
-- ---------------------------------------------------------------------------
create table public.readiness_checks (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities (id) on delete cascade,
  doctor_status public.availability_status not null,
  medicines_status public.availability_status not null,
  diagnostics_status public.availability_status not null,
  beds_status public.availability_status not null,
  -- 0..1 weighted readiness (PRD 12.3)
  score numeric(5, 4) not null check (score between 0 and 1),
  -- 0..1 how much of the input data is fresh and explicitly set
  confidence numeric(5, 4) not null check (confidence between 0 and 1),
  components jsonb not null default '{}'::jsonb,
  config_version integer,
  oldest_input_at timestamptz,
  checked_at timestamptz not null default now(),
  checked_by uuid references public.app_users (id) on delete set null,
  source text not null default 'system' check (source in ('system', 'manual', 'integration'))
);

create index readiness_checks_facility_time_idx
  on public.readiness_checks (facility_id, checked_at desc);

comment on table public.readiness_checks is
  'Append-only readiness history. Latest row per facility is the current state.';

-- ---------------------------------------------------------------------------
-- Readiness computation. Deterministic, config-driven, versioned.
-- ---------------------------------------------------------------------------
create or replace function app.compute_readiness(p_facility_id uuid)
returns public.readiness_checks
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cfg jsonb := coalesce(
    app.active_config('readiness_weights'),
    '{"doctor":0.35,"medicines":0.2,"diagnostics":0.2,"beds":0.25,"stale_after_hours":24}'::jsonb
  );
  v_cfg_version integer := app.active_config_version('readiness_weights');
  v_doctor public.availability_status;
  v_medicines public.availability_status;
  v_diagnostics public.availability_status;
  v_beds public.availability_status;
  v_w_doctor numeric := coalesce((v_cfg ->> 'doctor')::numeric, 0.35);
  v_w_med numeric := coalesce((v_cfg ->> 'medicines')::numeric, 0.20);
  v_w_diag numeric := coalesce((v_cfg ->> 'diagnostics')::numeric, 0.20);
  v_w_beds numeric := coalesce((v_cfg ->> 'beds')::numeric, 0.25);
  v_stale_hours numeric := coalesce((v_cfg ->> 'stale_after_hours')::numeric, 24);
  v_weight_total numeric;
  v_score numeric;
  v_known int := 0;
  v_fresh int := 0;
  v_oldest timestamptz;
  v_row public.readiness_checks;
begin
  v_doctor := app.rollup_status(p_facility_id, array['doctor', 'specialist']::public.resource_kind[]);
  v_medicines := app.rollup_status(p_facility_id, array['essential_medicine']::public.resource_kind[]);
  v_diagnostics := app.rollup_status(p_facility_id, array['diagnostic']::public.resource_kind[]);
  v_beds := app.rollup_status(p_facility_id, array['bed', 'icu_bed']::public.resource_kind[]);

  v_weight_total := v_w_doctor + v_w_med + v_w_diag + v_w_beds;
  if v_weight_total <= 0 then
    v_weight_total := 1;
  end if;

  v_score := (
      v_w_doctor * app.availability_weight(v_doctor)
    + v_w_med * app.availability_weight(v_medicines)
    + v_w_diag * app.availability_weight(v_diagnostics)
    + v_w_beds * app.availability_weight(v_beds)
  ) / v_weight_total;

  -- Confidence: share of the four components that are both known and fresh.
  select
    count(*) filter (where s.st <> 'unknown'),
    count(*) filter (where s.st <> 'unknown')
  into v_known, v_fresh
  from (values (v_doctor), (v_medicines), (v_diagnostics), (v_beds)) as s(st);

  select min(r.updated_at) into v_oldest
  from public.facility_resources r
  where r.facility_id = p_facility_id;

  if v_oldest is not null and v_oldest < now() - make_interval(hours => v_stale_hours::int) then
    -- Stale inputs halve confidence; the UI flags this (PRD 12.3).
    v_fresh := greatest(v_fresh - 2, 0);
  end if;

  insert into public.readiness_checks (
    facility_id, doctor_status, medicines_status, diagnostics_status, beds_status,
    score, confidence, components, config_version, oldest_input_at, checked_by, source
  )
  values (
    p_facility_id, v_doctor, v_medicines, v_diagnostics, v_beds,
    round(v_score, 4),
    round((v_fresh::numeric / 4), 4),
    jsonb_build_object(
      'doctor', jsonb_build_object('status', v_doctor, 'weight', v_w_doctor),
      'medicines', jsonb_build_object('status', v_medicines, 'weight', v_w_med),
      'diagnostics', jsonb_build_object('status', v_diagnostics, 'weight', v_w_diag),
      'beds', jsonb_build_object('status', v_beds, 'weight', v_w_beds),
      'known_components', v_known,
      'stale_after_hours', v_stale_hours
    ),
    v_cfg_version, v_oldest, auth.uid(), 'system'
  )
  returning * into v_row;

  return v_row;
end;
$$;

comment on function app.compute_readiness is
  'Recomputes and appends a readiness snapshot for a facility using the '
  'active readiness_weights configuration version.';

-- Client-callable wrapper (PRD 13: GET/PUT /facilities/{id}/readiness).
create or replace function public.refresh_facility_readiness(p_facility_id uuid)
returns public.readiness_checks
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.readiness_checks;
begin
  if not exists (select 1 from public.facilities f where f.id = p_facility_id) then
    raise exception 'Facility % not found', p_facility_id using errcode = 'no_data_found';
  end if;

  v_row := app.compute_readiness(p_facility_id);
  perform app.write_audit(
    'readiness.refresh', 'facility', p_facility_id::text, null, to_jsonb(v_row)
  );
  return v_row;
end;
$$;

-- Keep readiness current whenever a resource changes, but only append a new
-- snapshot when something actually moved.
create or replace function app.on_resource_change()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_facility uuid := coalesce(new.facility_id, old.facility_id);
  v_prev public.readiness_checks;
  v_next public.readiness_checks;
begin
  select * into v_prev
  from public.readiness_checks r
  where r.facility_id = v_facility
  order by r.checked_at desc
  limit 1;

  v_next := app.compute_readiness(v_facility);

  if v_prev.id is not null
     and v_prev.score = v_next.score
     and v_prev.confidence = v_next.confidence
     and v_prev.doctor_status = v_next.doctor_status
     and v_prev.medicines_status = v_next.medicines_status
     and v_prev.diagnostics_status = v_next.diagnostics_status
     and v_prev.beds_status = v_next.beds_status then
    -- No material change: drop the duplicate snapshot we just wrote.
    delete from public.readiness_checks where id = v_next.id;
  end if;

  return null;
end;
$$;

create trigger facility_resources_readiness
  after insert or update or delete on public.facility_resources
  for each row execute function app.on_resource_change();

-- ---------------------------------------------------------------------------
-- Current readiness per facility, with an explicit staleness flag.
-- ---------------------------------------------------------------------------
create or replace view public.facility_readiness_current
with (security_invoker = true)
as
select
  f.id as facility_id,
  f.name_en,
  f.name_local,
  f.type,
  f.tier,
  f.district_id,
  f.block_id,
  f.is_24x7,
  f.has_emergency_department,
  f.is_operational,
  r.id as readiness_check_id,
  coalesce(r.score, 0)::numeric(5, 4) as readiness_score,
  coalesce(r.confidence, 0)::numeric(5, 4) as readiness_confidence,
  coalesce(r.doctor_status, 'unknown') as doctor_status,
  coalesce(r.medicines_status, 'unknown') as medicines_status,
  coalesce(r.diagnostics_status, 'unknown') as diagnostics_status,
  coalesce(r.beds_status, 'unknown') as beds_status,
  r.components,
  r.checked_at,
  (
    r.checked_at is null
    or r.checked_at < now() - make_interval(
      hours => coalesce((app.active_config('readiness_weights') ->> 'stale_after_hours')::int, 24)
    )
  ) as is_stale
from public.facilities f
left join lateral (
  select rc.*
  from public.readiness_checks rc
  where rc.facility_id = f.id
  order by rc.checked_at desc
  limit 1
) r on true;

comment on view public.facility_readiness_current is
  'Latest readiness snapshot per facility with is_stale flag (PRD 12.3).';
