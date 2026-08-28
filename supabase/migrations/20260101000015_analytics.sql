-- =============================================================================
-- ArogyaMitra :: 0015 Operational analytics for DHO / State dashboards
-- PRD refs: 5.4, 6 FR-022, 19 (KPIs)
--
-- These views are owned by the database owner and therefore see past the RLS
-- policies on the underlying tables. That is deliberate: a DHO needs district
-- level numbers without being granted row access to patient records
-- (PRD 16 least privilege). Every view enforces scope itself through
-- app.can_see_district(), and every output is an aggregate.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Referral funnel and turnaround (PRD 19)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_referral_daily as
select
  r.district_id,
  d.name_en as district_name,
  date_trunc('day', r.created_at)::date as day,
  count(*) as referrals_created,
  count(*) filter (where r.sent_at is not null) as referrals_sent,
  count(*) filter (where r.accepted_at is not null) as referrals_accepted,
  count(*) filter (where r.status = 'REJECTED') as referrals_rejected,
  count(*) filter (where r.status = 'COMPLETED') as referrals_completed,
  count(*) filter (where r.status = 'EXPIRED') as referrals_expired,
  count(*) filter (where r.status = 'NO_SHOW') as referrals_no_show,
  count(*) filter (where r.status = 'EMERGENCY_ESCALATED') as emergency_escalations,
  count(*) filter (where r.sla_breached) as sla_breaches,
  -- Acceptance rate = accepted / sent (PRD 19)
  round(
    count(*) filter (where r.accepted_at is not null)::numeric
    / nullif(count(*) filter (where r.sent_at is not null), 0), 4
  ) as acceptance_rate,
  -- Completion rate = completed / created (PRD 19)
  round(
    count(*) filter (where r.status = 'COMPLETED')::numeric / nullif(count(*), 0), 4
  ) as completion_rate,
  -- Median minutes from creation to acceptance
  round(
    percentile_cont(0.5) within group (
      order by extract(epoch from (r.accepted_at - r.created_at)) / 60
    )::numeric, 1
  ) as median_accept_minutes,
  -- Median minutes from creation to a closed referral
  round(
    percentile_cont(0.5) within group (
      order by extract(epoch from (r.closed_at - r.created_at)) / 60
    )::numeric, 1
  ) as median_turnaround_minutes
from public.referrals r
join public.districts d on d.id = r.district_id
where app.can_see_district(r.district_id)
group by r.district_id, d.name_en, date_trunc('day', r.created_at);

comment on view public.kpi_referral_daily is
  'Referral volume, acceptance, completion and turnaround by district and day.';

-- ---------------------------------------------------------------------------
-- Readiness heatmap (PRD 5.4)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_facility_readiness as
select
  f.id as facility_id,
  f.name_en,
  f.name_local,
  f.type,
  f.tier,
  f.district_id,
  d.name_en as district_name,
  f.block_id,
  extensions.st_y(f.location::extensions.geometry)::double precision as latitude,
  extensions.st_x(f.location::extensions.geometry)::double precision as longitude,
  rc.readiness_score,
  rc.readiness_confidence,
  rc.doctor_status,
  rc.medicines_status,
  rc.diagnostics_status,
  rc.beds_status,
  rc.checked_at,
  rc.is_stale,
  -- Bands drive the heatmap colour; thresholds are UI-agnostic.
  case
    when rc.is_stale then 'stale'
    when rc.readiness_score >= 0.75 then 'good'
    when rc.readiness_score >= 0.45 then 'partial'
    else 'critical'
  end as readiness_band,
  (select count(*) from public.referrals r
    where r.destination_facility_id = f.id
      and r.status in ('REFERRAL_SENT', 'ACCEPTED', 'PATIENT_TRAVELLING')
  ) as open_incoming_referrals
from public.facilities f
join public.districts d on d.id = f.district_id
join public.facility_readiness_current rc on rc.facility_id = f.id
where f.is_operational
  and app.can_see_district(f.district_id);

-- ---------------------------------------------------------------------------
-- Triage funnel (PRD 19 triage completion, risk mix)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_triage_daily as
select
  p.district_id,
  date_trunc('day', t.created_at)::date as day,
  t.channel,
  count(*) as assessments,
  count(*) filter (where t.risk_level = 'low') as low_risk,
  count(*) filter (where t.risk_level = 'medium') as medium_risk,
  count(*) filter (where t.risk_level = 'high') as high_risk,
  count(*) filter (where t.risk_level = 'emergency') as emergency_risk,
  count(*) filter (where cardinality(t.red_flags) > 0) as red_flag_hits,
  count(*) filter (where t.used_default_fallback) as unmatched_fallbacks,
  -- Share of assessments that produced a referral (PRD 19)
  round(
    (select count(*) from public.referrals r where r.triage_assessment_id = any (
       array_agg(t.id)
     ))::numeric / nullif(count(*), 0), 4
  ) as referral_conversion_rate
from public.triage_assessments t
join public.patients p on p.id = t.patient_id
where app.can_see_district(p.district_id)
group by p.district_id, date_trunc('day', t.created_at), t.channel;

-- ---------------------------------------------------------------------------
-- Follow-up compliance (PRD 19)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_followup_compliance as
select
  f.district_id,
  date_trunc('week', f.due_date)::date as week,
  count(*) as total_followups,
  count(*) filter (where f.status = 'completed') as completed,
  count(*) filter (where f.status = 'missed') as missed,
  count(*) filter (where f.status in ('scheduled', 'due')) as pending,
  round(
    count(*) filter (where f.status = 'completed')::numeric
    / nullif(count(*) filter (where f.status in ('completed', 'missed')), 0), 4
  ) as completion_rate
from public.followups f
where app.can_see_district(f.district_id)
group by f.district_id, date_trunc('week', f.due_date);

-- ---------------------------------------------------------------------------
-- Citizen satisfaction (PRD 19)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_feedback_summary as
select
  fb.district_id,
  fb.facility_id,
  f.name_en as facility_name,
  date_trunc('month', fb.created_at)::date as month,
  count(*) as responses,
  round(avg(fb.rating)::numeric, 2) as average_rating,
  count(*) filter (where fb.rating <= 2) as detractors,
  count(*) filter (where fb.rating >= 4) as promoters,
  -- NPS-like measure on a 1..5 scale
  round(
    (count(*) filter (where fb.rating >= 4)::numeric
     - count(*) filter (where fb.rating <= 2)::numeric)
    / nullif(count(*), 0) * 100, 1
  ) as nps_like,
  count(*) filter (where fb.status in ('new', 'triaged')) as open_issues,
  mode() within group (order by fb.category) as top_category
from public.feedback fb
left join public.facilities f on f.id = fb.facility_id
where app.can_see_district(fb.district_id)
group by fb.district_id, fb.facility_id, f.name_en, date_trunc('month', fb.created_at);

-- ---------------------------------------------------------------------------
-- Ambulance response (PRD 19)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_ambulance_response as
select
  a.district_id,
  date_trunc('day', a.requested_at)::date as day,
  count(*) as requests,
  count(*) filter (where a.status = 'completed') as completed,
  count(*) filter (where a.status in ('cancelled', 'failed')) as unfulfilled,
  round(
    percentile_cont(0.5) within group (
      order by extract(epoch from (a.dispatched_at - a.requested_at)) / 60
    )::numeric, 1
  ) as median_dispatch_minutes,
  round(
    percentile_cont(0.5) within group (
      order by extract(epoch from (a.at_pickup_at - a.requested_at)) / 60
    )::numeric, 1
  ) as median_arrival_minutes,
  count(*) filter (where a.is_mock) as mock_requests
from public.ambulance_requests a
where app.can_see_district(a.district_id)
group by a.district_id, date_trunc('day', a.requested_at);

-- ---------------------------------------------------------------------------
-- Teleconsult utilisation (PRD 19)
-- ---------------------------------------------------------------------------
create or replace view public.kpi_teleconsult_utilisation as
select
  t.district_id,
  date_trunc('day', t.created_at)::date as day,
  count(*) as sessions_initiated,
  count(*) filter (where t.status = 'completed') as sessions_completed,
  count(*) filter (where t.status in ('cancelled', 'failed')) as sessions_failed,
  round(
    count(*) filter (where t.status = 'completed')::numeric / nullif(count(*), 0), 4
  ) as utilisation_rate,
  round(avg(t.duration_seconds)::numeric / 60, 1) as average_duration_minutes
from public.teleconsult_sessions t
where app.can_see_district(t.district_id)
group by t.district_id, date_trunc('day', t.created_at);

-- ---------------------------------------------------------------------------
-- Live SLA and escalation alert feed (PRD 5.4, 18)
-- ---------------------------------------------------------------------------
create or replace view public.operational_alerts as
select
  'referral_sla_breach' as alert_type,
  case when r.priority = 'emergency' then 'critical' else 'warning' end as severity,
  r.district_id,
  r.destination_facility_id as facility_id,
  r.id::text as subject_id,
  r.reference_code as subject_label,
  r.sla_due_at as due_at,
  r.created_at as raised_at,
  jsonb_build_object(
    'status', r.status, 'priority', r.priority,
    'minutes_overdue', greatest(0, round(extract(epoch from (now() - r.sla_due_at)) / 60))
  ) as details
from public.referrals r
where r.sla_breached
  and r.status in ('RECOMMENDED', 'REFERRAL_SENT')
  and app.can_see_district(r.district_id)

union all

select
  'readiness_critical' as alert_type,
  'warning' as severity,
  h.district_id,
  h.facility_id,
  h.facility_id::text as subject_id,
  h.name_en as subject_label,
  null::timestamptz as due_at,
  coalesce(h.checked_at, now()) as raised_at,
  jsonb_build_object(
    'readiness_score', h.readiness_score,
    'band', h.readiness_band,
    'doctor', h.doctor_status,
    'medicines', h.medicines_status,
    'is_stale', h.is_stale
  ) as details
from public.kpi_facility_readiness h
where h.readiness_band in ('critical', 'stale')

union all

select
  'feedback_issue' as alert_type,
  case when fb.rating = 1 then 'critical' else 'warning' end as severity,
  fb.district_id,
  fb.facility_id,
  fb.id::text as subject_id,
  fb.category as subject_label,
  null::timestamptz as due_at,
  fb.created_at as raised_at,
  jsonb_build_object('rating', fb.rating, 'category', fb.category) as details
from public.feedback fb
where fb.status in ('new', 'triaged')
  and (fb.rating <= 2 or fb.category in ('medicine_unavailable', 'diagnostic_unavailable', 'ambulance'))
  and app.can_see_district(fb.district_id);

comment on view public.operational_alerts is
  'Unified alert feed for the DHO console: SLA breaches, critical or stale '
  'readiness and unresolved citizen issues (PRD 5.4, 18).';

-- ---------------------------------------------------------------------------
-- Grants. Analytics are for oversight roles only; the scope filter inside each
-- view still applies.
-- ---------------------------------------------------------------------------
revoke all on public.kpi_referral_daily, public.kpi_facility_readiness,
  public.kpi_triage_daily, public.kpi_followup_compliance,
  public.kpi_feedback_summary, public.kpi_ambulance_response,
  public.kpi_teleconsult_utilisation, public.operational_alerts
  from anon, authenticated;

grant select on public.kpi_referral_daily, public.kpi_facility_readiness,
  public.kpi_triage_daily, public.kpi_followup_compliance,
  public.kpi_feedback_summary, public.kpi_ambulance_response,
  public.kpi_teleconsult_utilisation, public.operational_alerts
  to authenticated;
