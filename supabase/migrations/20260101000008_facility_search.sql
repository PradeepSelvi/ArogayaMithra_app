-- =============================================================================
-- ArogyaMitra :: 0008 Facility discovery and configurable scoring
-- PRD refs: 6 FR-007/FR-008, 12.1, 13 (GET /facilities)
--
-- score = w1 * inverse travel time
--       + w2 * inverse expected wait
--       + w3 * service match
--       + w4 * capacity confidence
-- All weights come from config_versions('facility_score_weights') so they can
-- be tuned per district without a deployment (PRD 12.1).
-- =============================================================================

-- Fraction of the required services a facility can actually deliver right now.
create or replace function app.service_match_score(
  p_facility_id uuid,
  p_required_services text[]
)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_required int := coalesce(array_length(p_required_services, 1), 0);
  v_total numeric := 0;
begin
  if v_required = 0 then
    return 1.0;
  end if;

  select coalesce(sum(app.availability_weight(fs.status)), 0)
  into v_total
  from public.facility_services fs
  where fs.facility_id = p_facility_id
    and fs.service_code = any (p_required_services);

  return least(v_total / v_required, 1.0);
end;
$$;

-- Expected wait proxy from bed occupancy. Replaced by a real queue signal once
-- facility HMIS integration exists; kept behind one function so the swap is local.
create or replace function app.expected_wait_score(p_facility_id uuid)
returns numeric
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_capacity numeric;
  v_occupied numeric;
begin
  select sum(r.capacity), sum(r.capacity - coalesce(r.quantity, 0))
  into v_capacity, v_occupied
  from public.facility_resources r
  where r.facility_id = p_facility_id
    and r.kind in ('bed', 'icu_bed')
    and r.capacity is not null;

  if v_capacity is null or v_capacity = 0 then
    return 0.5; -- unknown: neutral, never optimistic
  end if;

  -- 1.0 means empty, 0.0 means full.
  return greatest(0, least(1, 1 - (v_occupied / v_capacity)));
end;
$$;

-- ---------------------------------------------------------------------------
-- public.search_facilities : ranked candidate list for referral
-- ---------------------------------------------------------------------------
create or replace function public.search_facilities(
  p_lat double precision,
  p_lon double precision,
  p_required_services text[] default '{}',
  p_min_tier smallint default 1,
  p_radius_m integer default null,
  p_emergency_only boolean default false,
  p_limit integer default 10
)
returns table (
  facility_id uuid,
  name_en text,
  name_local text,
  type public.facility_type,
  tier smallint,
  district_id uuid,
  address text,
  contact_phone text,
  emergency_phone text,
  is_24x7 boolean,
  has_emergency_department boolean,
  latitude double precision,
  longitude double precision,
  distance_m double precision,
  travel_time_min numeric,
  readiness_score numeric,
  readiness_confidence numeric,
  doctor_status public.availability_status,
  medicines_status public.availability_status,
  diagnostics_status public.availability_status,
  beds_status public.availability_status,
  is_stale boolean,
  service_match numeric,
  wait_score numeric,
  facility_score numeric,
  score_components jsonb,
  score_config_version integer
)
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_cfg jsonb := coalesce(
    app.active_config('facility_score_weights'),
    '{"travel_time":0.35,"wait":0.15,"service_match":0.30,"capacity_confidence":0.20,
      "max_radius_m":30000,"avg_speed_kmph":30}'::jsonb
  );
  v_cfg_version integer := app.active_config_version('facility_score_weights');
  v_w_travel numeric := coalesce((v_cfg ->> 'travel_time')::numeric, 0.35);
  v_w_wait numeric := coalesce((v_cfg ->> 'wait')::numeric, 0.15);
  v_w_service numeric := coalesce((v_cfg ->> 'service_match')::numeric, 0.30);
  v_w_capacity numeric := coalesce((v_cfg ->> 'capacity_confidence')::numeric, 0.20);
  v_radius integer := coalesce(p_radius_m, (v_cfg ->> 'max_radius_m')::integer, 30000);
  v_speed numeric := coalesce((v_cfg ->> 'avg_speed_kmph')::numeric, 30);
  v_weight_total numeric;
  v_origin extensions.geography(point, 4326);
begin
  if p_lat is null or p_lon is null then
    raise exception 'Origin coordinates are required' using errcode = 'invalid_parameter_value';
  end if;

  v_origin := extensions.st_setsrid(extensions.st_makepoint(p_lon, p_lat), 4326)::extensions.geography;
  v_weight_total := nullif(v_w_travel + v_w_wait + v_w_service + v_w_capacity, 0);
  if v_weight_total is null then
    v_weight_total := 1;
  end if;

  return query
  with candidates as (
    select
      r.facility_id,
      r.name_en,
      r.name_local,
      r.type,
      r.tier,
      r.district_id,
      f.address,
      f.contact_phone,
      f.emergency_phone,
      r.is_24x7,
      r.has_emergency_department,
      extensions.st_y(f.location::extensions.geometry)::double precision as latitude,
      extensions.st_x(f.location::extensions.geometry)::double precision as longitude,
      extensions.st_distance(f.location, v_origin)::double precision as distance_m,
      r.readiness_score,
      r.readiness_confidence,
      r.doctor_status,
      r.medicines_status,
      r.diagnostics_status,
      r.beds_status,
      r.is_stale,
      app.service_match_score(r.facility_id, p_required_services) as service_match,
      app.expected_wait_score(r.facility_id) as wait_score
    from public.facility_readiness_current r
    join public.facilities f on f.id = r.facility_id
    where r.is_operational
      and r.tier >= p_min_tier
      and extensions.st_dwithin(f.location, v_origin, v_radius)
      and (not p_emergency_only or r.has_emergency_department or r.is_24x7)
  ),
  scored as (
    select
      c.*,
      -- Normalised inverse travel time: 1.0 at the origin, 0.0 at the radius.
      -- PostGIS returns double precision, so everything is pinned to numeric
      -- before it reaches the weighted sum.
      greatest(0::numeric, least(
        1::numeric,
        1 - (c.distance_m::numeric / nullif(v_radius, 0)::numeric)
      )) as travel_norm,
      round(
        (c.distance_m::numeric / 1000.0) / nullif(v_speed, 0) * 60, 1
      ) as travel_time_min
    from candidates c
  )
  select
    s.facility_id,
    s.name_en,
    s.name_local,
    s.type,
    s.tier,
    s.district_id,
    s.address,
    s.contact_phone,
    s.emergency_phone,
    s.is_24x7,
    s.has_emergency_department,
    s.latitude,
    s.longitude,
    s.distance_m,
    s.travel_time_min,
    s.readiness_score,
    s.readiness_confidence,
    s.doctor_status,
    s.medicines_status,
    s.diagnostics_status,
    s.beds_status,
    s.is_stale,
    s.service_match,
    s.wait_score,
    round((
        v_w_travel * s.travel_norm
      + v_w_wait * s.wait_score
      + v_w_service * s.service_match
      + v_w_capacity * s.readiness_confidence
    ) / v_weight_total, 4) as facility_score,
    jsonb_build_object(
      'travel', jsonb_build_object('weight', v_w_travel, 'value', round(s.travel_norm, 4)),
      'wait', jsonb_build_object('weight', v_w_wait, 'value', round(s.wait_score, 4)),
      'service_match', jsonb_build_object('weight', v_w_service, 'value', round(s.service_match, 4)),
      'capacity_confidence', jsonb_build_object('weight', v_w_capacity, 'value', round(s.readiness_confidence, 4)),
      'readiness_score', s.readiness_score,
      'is_stale', s.is_stale,
      'radius_m', v_radius,
      'avg_speed_kmph', v_speed
    ) as score_components,
    v_cfg_version as score_config_version
  from scored s
  order by facility_score desc, s.distance_m asc
  limit greatest(1, least(coalesce(p_limit, 10), 50));
end;
$$;

comment on function public.search_facilities is
  'Ranked facility discovery. Returns per-factor score components so the '
  'recommendation is explainable to the citizen and auditable (PRD 12.1).';
