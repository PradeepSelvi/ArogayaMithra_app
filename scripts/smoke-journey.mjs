#!/usr/bin/env node
/**
 * End-to-end smoke test of the MVP care journey from PRD 23, driven entirely
 * through the public API surface the Flutter apps use.
 *
 * Citizen signs in with a one-time code -> runs triage -> sees ranked facilities
 * -> creates a referral -> the destination medical officer accepts it -> the
 * citizen sees the new status and their notification -> the DHO sees the KPIs.
 *
 * This proves the same thing the apps rely on: that RLS, the triage engine and
 * the referral state machine behave correctly for real JWTs, not just for a
 * superuser session.
 *
 * Usage: npm run smoke
 */

const BASE = process.env.SUPABASE_URL ?? 'http://127.0.0.1:54321';
const KEY =
  process.env.SUPABASE_PUBLISHABLE_KEY ??
  'sb_publishable_ACJWlzQHlZjBrEguHvfOxg_3BJgxAaH';

const CITIZEN_PHONE = '+919876500002';
const CITIZEN_OTP = '123456';
const MO_EMAIL = 'mo.district@arogyamitra.local';
const OTHER_MO_EMAIL = 'mo.polur@arogyamitra.local';
const DHO_EMAIL = 'dho@arogyamitra.local';
const STAFF_PASSWORD = 'ArogyaMitra@2026';

const DISTRICT_HQ = '55555555-0002-0000-0000-000000000002';

let passed = 0;
const failures = [];

function check(label, condition, detail = '') {
  if (condition) {
    passed += 1;
    console.log(`  ok  ${label}`);
  } else {
    failures.push(`${label} ${detail}`.trim());
    console.error(`  XX  ${label} ${detail}`.trim());
  }
}

async function api(path, { token, method = 'GET', body, headers = {} } = {}) {
  const response = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      apikey: KEY,
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...headers,
    },
    ...(body ? { body: JSON.stringify(body) } : {}),
  });

  const text = await response.text();
  let parsed = null;
  if (text) {
    try {
      parsed = JSON.parse(text);
    } catch {
      parsed = text;
    }
  }

  return { status: response.status, ok: response.ok, body: parsed };
}

async function signInWithPassword(email) {
  const result = await api('/auth/v1/token?grant_type=password', {
    method: 'POST',
    body: { email, password: STAFF_PASSWORD },
  });
  if (!result.ok) {
    throw new Error(`Sign-in failed for ${email}: ${JSON.stringify(result.body)}`);
  }
  return result.body.access_token;
}

async function signInCitizen() {
  const requested = await api('/auth/v1/otp', {
    method: 'POST',
    body: { phone: CITIZEN_PHONE },
  });
  check('citizen can request a one-time code', requested.ok, JSON.stringify(requested.body));

  const verified = await api('/auth/v1/verify', {
    method: 'POST',
    body: { phone: CITIZEN_PHONE, token: CITIZEN_OTP, type: 'sms' },
  });
  if (!verified.ok) {
    throw new Error(`OTP verify failed: ${JSON.stringify(verified.body)}`);
  }
  check('citizen one-time code establishes a session', Boolean(verified.body.access_token));
  return verified.body.access_token;
}

async function main() {
  console.log('ArogyaMitra end-to-end care journey\n');

  // --- 1. Citizen signs in -------------------------------------------------
  const citizen = await signInCitizen();

  const profile = await api('/rest/v1/app_users?select=role,preferred_language', {
    token: citizen,
  });
  check(
    'citizen profile resolves with the citizen role',
    profile.body?.[0]?.role === 'citizen',
    JSON.stringify(profile.body),
  );

  const patients = await api('/rest/v1/patients?select=id,full_name,age_years', {
    token: citizen,
  });
  check(
    'citizen sees exactly their own patient record',
    Array.isArray(patients.body) && patients.body.length === 1,
    `saw ${patients.body?.length} rows`,
  );

  const patientId = patients.body[0].id;

  // --- 2. Triage -----------------------------------------------------------
  const triage = await api('/rest/v1/rpc/run_triage', {
    token: citizen,
    method: 'POST',
    body: {
      p_patient_id: patientId,
      p_symptoms: ['fever', 'cough'],
      p_severity: 4,
      p_duration_hours: 96,
      p_channel: 'citizen_app',
      p_input_language: 'ta',
    },
  });

  check('triage returns an assessment', triage.ok, JSON.stringify(triage.body));
  const assessment = triage.body;
  check(
    'triage classified a 4-day severe fever as high risk',
    assessment?.risk_level === 'high',
    `got ${assessment?.risk_level}`,
  );
  check(
    'assessment records the rule set version that produced it',
    typeof assessment?.rule_set_version === 'number',
  );
  check(
    'assessment names the matched rule',
    Boolean(assessment?.matched_rule_code),
    `got ${assessment?.matched_rule_code}`,
  );

  // --- 3. Facility discovery ----------------------------------------------
  const search = await api('/rest/v1/rpc/search_facilities', {
    token: citizen,
    method: 'POST',
    body: {
      p_lat: 12.238,
      p_lon: 79.04,
      p_required_services: assessment.required_services,
      p_min_tier: assessment.min_facility_tier,
      p_limit: 5,
    },
  });

  check('facility search returns candidates', Array.isArray(search.body) && search.body.length > 0);
  const candidates = search.body;
  check(
    'candidates are ranked by descending score',
    candidates.every(
      (c, i) => i === 0 || Number(candidates[i - 1].facility_score) >= Number(c.facility_score),
    ),
  );
  check(
    'each candidate explains its score',
    candidates.every((c) => c.score_components?.travel && c.score_components?.service_match),
  );
  check(
    'each candidate reports readiness staleness',
    candidates.every((c) => typeof c.is_stale === 'boolean'),
  );

  const chosen =
    candidates.find((c) => c.facility_id === DISTRICT_HQ) ?? candidates[0];

  // --- 4. Referral ---------------------------------------------------------
  const idempotencyKey = `smoke-${Date.now()}`;
  const created = await api('/rest/v1/rpc/create_referral', {
    token: citizen,
    method: 'POST',
    body: {
      p_patient_id: patientId,
      p_destination_facility_id: chosen.facility_id,
      p_triage_assessment_id: assessment.id,
      p_reason: 'Fever for four days',
      p_score_snapshot: { facility_score: chosen.facility_score },
      p_score_config_version: chosen.score_config_version,
      p_idempotency_key: idempotencyKey,
    },
  });

  check('citizen can create a referral', created.ok, JSON.stringify(created.body));
  const referral = created.body;
  check(
    'referral is waiting on the facility',
    referral?.status === 'REFERRAL_SENT',
    `got ${referral?.status}`,
  );
  check('referral has an acceptance SLA', Boolean(referral?.sla_due_at));
  check(
    'high risk produced an urgent referral',
    referral?.priority === 'urgent',
    `got ${referral?.priority}`,
  );

  // Replay the identical request, as an interrupted network call would.
  const replay = await api('/rest/v1/rpc/create_referral', {
    token: citizen,
    method: 'POST',
    body: {
      p_patient_id: patientId,
      p_destination_facility_id: chosen.facility_id,
      p_triage_assessment_id: assessment.id,
      p_reason: 'Fever for four days',
      p_idempotency_key: idempotencyKey,
    },
  });
  check(
    'replaying the request returns the same referral',
    Boolean(referral?.id) && replay.body?.id === referral.id,
    `got ${replay.body?.id}`,
  );

  // --- 5. Scope isolation --------------------------------------------------
  const otherMo = await signInWithPassword(OTHER_MO_EMAIL);
  const unrelated = await api(
    `/rest/v1/referrals?select=id&id=eq.${referral.id}`,
    { token: otherMo },
  );
  check(
    'an officer at another facility cannot see the referral',
    Array.isArray(unrelated.body) && unrelated.body.length === 0,
    `saw ${unrelated.body?.length} rows`,
  );

  const wrongAccept = await api('/rest/v1/rpc/accept_referral', {
    token: otherMo,
    method: 'POST',
    body: { p_referral_id: referral.id },
  });
  check(
    'an officer at another facility cannot accept it',
    !wrongAccept.ok,
    `status ${wrongAccept.status}`,
  );

  // --- 6. The destination facility accepts --------------------------------
  const mo = await signInWithPassword(MO_EMAIL);

  const queue = await api(
    '/rest/v1/referrals?select=id,reference_code,status,priority&status=eq.REFERRAL_SENT',
    { token: mo },
  );
  check(
    'the referral appears in the destination facility queue',
    queue.body?.some((r) => r.id === referral.id),
  );

  const illegal = await api('/rest/v1/rpc/advance_referral', {
    token: mo,
    method: 'POST',
    body: { p_referral_id: referral.id, p_to: 'COMPLETED' },
  });
  check(
    'the state machine refuses to skip straight to COMPLETED',
    !illegal.ok,
    `status ${illegal.status}`,
  );

  const noReason = await api('/rest/v1/rpc/reject_referral', {
    token: mo,
    method: 'POST',
    body: { p_referral_id: referral.id, p_reason: '  ' },
  });
  check('rejecting without a reason is refused', !noReason.ok, `status ${noReason.status}`);

  const accepted = await api('/rest/v1/rpc/accept_referral', {
    token: mo,
    method: 'POST',
    body: { p_referral_id: referral.id },
  });
  check('the destination officer can accept', accepted.body?.status === 'ACCEPTED',
    JSON.stringify(accepted.body));
  check('acceptance is timestamped by the server', Boolean(accepted.body?.accepted_at));

  // --- 7. The citizen sees the update -------------------------------------
  const citizenView = await api(
    `/rest/v1/referrals?select=status&id=eq.${referral.id}`,
    { token: citizen },
  );
  check(
    'the citizen sees the accepted status',
    citizenView.body?.[0]?.status === 'ACCEPTED',
    `got ${citizenView.body?.[0]?.status}`,
  );

  const timeline = await api(
    `/rest/v1/referral_timeline?select=to_status&referral_id=eq.${referral.id}&order=occurred_at`,
    { token: citizen },
  );
  const states = (timeline.body ?? []).map((e) => e.to_status);
  check(
    'the timeline records every state the referral passed through',
    ['CREATED', 'TRIAGED', 'RECOMMENDED', 'REFERRAL_SENT', 'ACCEPTED'].every((s) =>
      states.includes(s),
    ),
    states.join(' -> '),
  );

  const inbox = await api('/rest/v1/notifications?select=title,body,language', {
    token: citizen,
  });
  check(
    'the citizen was notified in Tamil',
    inbox.body?.some((n) => n.language === 'ta'),
    `${inbox.body?.length} messages`,
  );

  // --- 8. Complete the journey --------------------------------------------
  await api('/rest/v1/rpc/advance_referral', {
    token: citizen,
    method: 'POST',
    body: { p_referral_id: referral.id, p_to: 'PATIENT_TRAVELLING' },
  });
  await api('/rest/v1/rpc/advance_referral', {
    token: mo,
    method: 'POST',
    body: { p_referral_id: referral.id, p_to: 'ARRIVED' },
  });
  await api('/rest/v1/rpc/advance_referral', {
    token: mo,
    method: 'POST',
    body: { p_referral_id: referral.id, p_to: 'CONSULTATION' },
  });
  const completed = await api('/rest/v1/rpc/advance_referral', {
    token: mo,
    method: 'POST',
    body: {
      p_referral_id: referral.id,
      p_to: 'COMPLETED',
      p_outcome: 'Treated and discharged',
    },
  });
  check('the referral can be completed', completed.body?.status === 'COMPLETED',
    JSON.stringify(completed.body));

  // --- 9. Feedback ---------------------------------------------------------
  const feedback = await api('/rest/v1/feedback', {
    token: citizen,
    method: 'POST',
    headers: { Prefer: 'return=representation' },
    body: {
      patient_id: patientId,
      facility_id: chosen.facility_id,
      referral_id: referral.id,
      rating: 2,
      category: 'medicine_unavailable',
      comment: 'Medicines were not available',
      language: 'ta',
    },
  });
  check('the citizen can submit feedback', feedback.ok, JSON.stringify(feedback.body));

  // --- 10. Oversight -------------------------------------------------------
  const dho = await signInWithPassword(DHO_EMAIL);

  const patientsForDho = await api('/rest/v1/patients?select=id', { token: dho });
  check(
    'the DHO has no row access to patient records',
    Array.isArray(patientsForDho.body) && patientsForDho.body.length === 0,
    `saw ${patientsForDho.body?.length} rows`,
  );

  const kpis = await api('/rest/v1/kpi_referral_daily?select=*', { token: dho });
  check(
    'the DHO sees referral KPIs',
    Array.isArray(kpis.body) && kpis.body.length > 0,
    JSON.stringify(kpis.body).slice(0, 160),
  );
  check(
    'the completed referral is reflected in the KPIs',
    (kpis.body ?? []).some((row) => row.referrals_completed >= 1),
  );

  const heatmap = await api('/rest/v1/kpi_facility_readiness?select=facility_id,readiness_band', {
    token: dho,
  });
  check(
    'the DHO sees the readiness heatmap for all seven facilities',
    heatmap.body?.length === 7,
    `got ${heatmap.body?.length}`,
  );

  const alerts = await api('/rest/v1/operational_alerts?select=alert_type', { token: dho });
  check(
    'the low rating raised a feedback alert',
    (alerts.body ?? []).some((a) => a.alert_type === 'feedback_issue'),
    JSON.stringify(alerts.body),
  );

  console.log('');
  console.log(`${passed} checks passed, ${failures.length} failed.`);
  if (failures.length > 0) process.exit(1);
}

main().catch((error) => {
  console.error(`\nSmoke test aborted: ${error.message}`);
  process.exit(1);
});
