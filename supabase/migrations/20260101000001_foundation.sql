-- =============================================================================
-- ArogyaMitra :: 0001 Foundation
-- Extensions, schemas, enumerations and shared utilities.
-- PRD refs: 8.1 (architecture principles), 11 (data model), 16 (security)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Extensions
-- ---------------------------------------------------------------------------
create extension if not exists "pgcrypto" with schema extensions;
create extension if not exists "postgis" with schema extensions;
create extension if not exists "pg_trgm" with schema extensions;

-- ---------------------------------------------------------------------------
-- Schemas
--   public : tables + RPC exposed through PostgREST
--   app    : internal helpers, triggers, security predicates (never exposed)
-- ---------------------------------------------------------------------------
create schema if not exists app;

revoke all on schema app from anon, authenticated;
grant usage on schema app to authenticated;

-- ---------------------------------------------------------------------------
-- Enumerations
-- ---------------------------------------------------------------------------

-- PRD 4 - Target users and roles
create type public.user_role as enum (
  'citizen',
  'asha',
  'anm',
  'medical_officer',
  'facility_admin',
  'dho',
  'state_admin',
  'system_admin'
);

create type public.account_status as enum ('pending', 'active', 'suspended', 'disabled');

create type public.sex as enum ('male', 'female', 'other', 'undisclosed');

-- PRD 5.3 / 12.3 - facility taxonomy for the Indian public health system
create type public.facility_type as enum (
  'health_sub_centre',
  'hwc',                 -- Health & Wellness Centre
  'phc',                 -- Primary Health Centre
  'chc',                 -- Community Health Centre
  'sub_district_hospital',
  'district_hospital',
  'medical_college',
  'private_hospital',
  'diagnostic_centre'
);

-- PRD 12.3 - readiness components
create type public.resource_kind as enum (
  'doctor',
  'nurse',
  'specialist',
  'essential_medicine',
  'diagnostic',
  'bed',
  'icu_bed',
  'oxygen',
  'ambulance',
  'equipment'
);

create type public.availability_status as enum (
  'available',
  'limited',
  'unavailable',
  'unknown'
);

-- PRD 12.2 - referral state machine
create type public.referral_status as enum (
  'CREATED',
  'TRIAGED',
  'RECOMMENDED',
  'REFERRAL_SENT',
  'ACCEPTED',
  'PATIENT_TRAVELLING',
  'ARRIVED',
  'CONSULTATION',
  'COMPLETED',
  -- alternate terminal / exception states
  'REJECTED',
  'CANCELLED',
  'EXPIRED',
  'NO_SHOW',
  'EMERGENCY_ESCALATED'
);

create type public.referral_priority as enum ('routine', 'urgent', 'emergency');

-- PRD 6 FR-005 - triage outcome
create type public.risk_level as enum ('low', 'medium', 'high', 'emergency');

create type public.next_action as enum (
  'self_care',
  'visit_facility',
  'teleconsult',
  'refer',
  'emergency_response'
);

create type public.followup_status as enum ('scheduled', 'due', 'completed', 'missed', 'cancelled');

create type public.notification_channel as enum ('push', 'sms', 'ivr', 'in_app', 'whatsapp');

create type public.delivery_status as enum ('queued', 'sent', 'delivered', 'failed', 'suppressed');

create type public.consent_status as enum ('requested', 'granted', 'denied', 'revoked', 'expired');

create type public.external_system as enum (
  'abdm',
  'bhashini',
  'esanjeevani',
  'ambulance',
  'sms_gateway',
  'maps'
);

create type public.integration_status as enum ('pending', 'success', 'failed', 'timeout', 'mocked');

create type public.language_code as enum ('ta', 'en', 'hi');

-- ---------------------------------------------------------------------------
-- Shared utilities
-- ---------------------------------------------------------------------------

-- Keeps updated_at honest without trusting the client.
create or replace function app.touch_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

comment on function app.touch_updated_at is
  'BEFORE UPDATE trigger: server-authoritative updated_at timestamp.';

-- Correlation id for a request chain. Read from the request header when the
-- client supplies one, otherwise generated. PRD 13 (correlation IDs).
create or replace function app.trace_id()
returns text
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_headers json;
  v_trace text;
begin
  begin
    v_headers := current_setting('request.headers', true)::json;
  exception when others then
    v_headers := null;
  end;

  if v_headers is not null then
    v_trace := v_headers ->> 'x-trace-id';
  end if;

  return coalesce(nullif(v_trace, ''), gen_random_uuid()::text);
end;
$$;

comment on function app.trace_id is
  'Correlation id for the current request, from x-trace-id header or generated.';

-- Purpose of access, used by consent-aware reads and audit records.
-- PRD 16 (purpose-aware access to health information).
create or replace function app.access_purpose()
returns text
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_headers json;
  v_purpose text;
begin
  begin
    v_headers := current_setting('request.headers', true)::json;
  exception when others then
    v_headers := null;
  end;

  if v_headers is not null then
    v_purpose := v_headers ->> 'x-access-purpose';
  end if;

  return coalesce(nullif(v_purpose, ''), 'care_delivery');
end;
$$;
