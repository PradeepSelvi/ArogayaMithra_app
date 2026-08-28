-- =============================================================================
-- ArogyaMitra :: 0006 Households, patients and offline write safety
-- PRD refs: 5.2, 6 FR-015/FR-016, 11 (Household, Patient), 15 (offline-first)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- idempotency_keys : PRD 13 and 15 require retriable commands and guarantee
-- that a replayed offline sync never creates duplicate records.
-- ---------------------------------------------------------------------------
create table public.idempotency_keys (
  key text primary key,
  actor_id uuid references public.app_users (id) on delete cascade,
  operation text not null,
  request_fingerprint text,
  response jsonb,
  created_at timestamptz not null default now()
);

create index idempotency_keys_created_idx on public.idempotency_keys (created_at);

comment on table public.idempotency_keys is
  'Replay protection for offline sync and retried commands (PRD 15). No RLS '
  'policy is granted; the table is reachable only through the two helpers below.';

-- Domain RPCs run as SECURITY INVOKER so that RLS still applies to the business
-- tables they touch. Replay bookkeeping is infrastructure rather than user data,
-- so it goes through these definer helpers instead of a policy that would have
-- to expose the table to clients.
create or replace function app.idempotency_lookup(p_key text, p_operation text)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select k.response
  from public.idempotency_keys k
  where k.key = p_key and k.operation = p_operation;
$$;

create or replace function app.idempotency_remember(
  p_key text,
  p_operation text,
  p_response jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.idempotency_keys (key, actor_id, operation, response)
  values (p_key, auth.uid(), p_operation, p_response)
  on conflict (key) do nothing;
end;
$$;

-- ---------------------------------------------------------------------------
-- Household (PRD 11)
-- Primary key is client-supplied so an ASHA can create records offline and the
-- id survives synchronisation unchanged (PRD 15: "every write shall receive a
-- local UUID").
-- ---------------------------------------------------------------------------
create table public.households (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  village_id uuid not null references public.villages (id) on delete restrict,
  block_id uuid not null references public.blocks (id) on delete restrict,
  district_id uuid not null references public.districts (id) on delete restrict,
  address_line text,
  landmark text,
  geo_point extensions.geography(point, 4326),
  assigned_worker_id uuid references public.app_users (id) on delete set null,
  head_of_household text,
  contact_phone text,
  member_count smallint not null default 0 check (member_count >= 0),
  -- Offline provenance
  created_by uuid references public.app_users (id) on delete set null,
  client_created_at timestamptz,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index households_worker_idx on public.households (assigned_worker_id);
create index households_village_idx on public.households (village_id);
create index households_district_idx on public.households (district_id);
create index households_geo_idx on public.households using gist (geo_point);

create trigger households_touch before update on public.households
  for each row execute function app.touch_updated_at();

create trigger households_audit
  after insert or update or delete on public.households
  for each row execute function app.audit_row('household');

-- Derive block/district from the village so scope can never be spoofed and
-- stamp the creating worker. PRD 6 FR-002.
create or replace function app.normalise_household()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_block uuid;
  v_district uuid;
begin
  select v.block_id, b.district_id
  into v_block, v_district
  from public.villages v
  join public.blocks b on b.id = v.block_id
  where v.id = new.village_id;

  if v_block is null then
    raise exception 'Unknown village %', new.village_id using errcode = 'foreign_key_violation';
  end if;

  new.block_id := v_block;
  new.district_id := v_district;

  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.assigned_worker_id := coalesce(new.assigned_worker_id, auth.uid());
    new.synced_at := now();
  end if;

  return new;
end;
$$;

create trigger households_normalise
  before insert or update on public.households
  for each row execute function app.normalise_household();

-- ---------------------------------------------------------------------------
-- Patient (PRD 11)
-- ABHA identifiers are stored as references only; no clinical record is
-- duplicated here (PRD 3.2 non-goal, PRD 14.1 minimum operational metadata).
-- ---------------------------------------------------------------------------
create table public.patients (
  id uuid primary key default gen_random_uuid(),
  household_id uuid references public.households (id) on delete set null,
  -- Set when a citizen self-registers and this patient record is their own.
  app_user_id uuid unique references public.app_users (id) on delete set null,
  full_name text not null,
  sex public.sex not null default 'undisclosed',
  date_of_birth date,
  age_years smallint check (age_years between 0 and 130),
  contact_phone text,
  preferred_language public.language_code not null default 'ta',
  village_id uuid references public.villages (id) on delete set null,
  district_id uuid references public.districts (id) on delete restrict,
  -- Reference identifiers only (PRD 14.1)
  abha_address text,
  abha_number_last4 text check (abha_number_last4 is null or abha_number_last4 ~ '^[0-9]{4}$'),
  -- Risk context used by triage (PRD 6 FR-004)
  is_pregnant boolean not null default false,
  chronic_conditions text[] not null default '{}',
  allergies text[] not null default '{}',
  created_by uuid references public.app_users (id) on delete set null,
  client_created_at timestamptz,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint patients_age_or_dob check (date_of_birth is not null or age_years is not null)
);

create index patients_household_idx on public.patients (household_id);
create index patients_district_idx on public.patients (district_id);
create index patients_app_user_idx on public.patients (app_user_id);
create index patients_name_trgm_idx on public.patients using gin (full_name extensions.gin_trgm_ops);

create trigger patients_touch before update on public.patients
  for each row execute function app.touch_updated_at();

create trigger patients_audit
  after insert or update or delete on public.patients
  for each row execute function app.audit_row('patient');

create or replace function app.normalise_patient()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_village uuid;
  v_district uuid;
begin
  if new.household_id is not null then
    select h.village_id, h.district_id into v_village, v_district
    from public.households h where h.id = new.household_id;

    new.village_id := coalesce(new.village_id, v_village);
    new.district_id := coalesce(new.district_id, v_district);
  end if;

  if new.district_id is null and new.village_id is not null then
    select b.district_id into new.district_id
    from public.villages v join public.blocks b on b.id = v.block_id
    where v.id = new.village_id;
  end if;

  -- Keep a usable age even when only one of dob/age is supplied.
  if new.date_of_birth is not null then
    new.age_years := extract(year from age(new.date_of_birth))::smallint;
  end if;

  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.synced_at := now();
  end if;

  return new;
end;
$$;

create trigger patients_normalise
  before insert or update on public.patients
  for each row execute function app.normalise_patient();

-- Household member count stays accurate without client bookkeeping.
create or replace function app.sync_household_member_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_ids uuid[] := array_remove(array[
    case when tg_op <> 'INSERT' then old.household_id end,
    case when tg_op <> 'DELETE' then new.household_id end
  ], null);
  v_id uuid;
begin
  foreach v_id in array v_ids loop
    update public.households h
    set member_count = (select count(*) from public.patients p where p.household_id = h.id)
    where h.id = v_id;
  end loop;

  return null;
end;
$$;

create trigger patients_household_count
  after insert or update of household_id or delete on public.patients
  for each row execute function app.sync_household_member_count();
