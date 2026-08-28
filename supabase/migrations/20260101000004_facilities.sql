-- =============================================================================
-- ArogyaMitra :: 0004 Facility registry and service catalogue
-- PRD refs: 5.3, 6 FR-007, 11 (Facility, FacilityResource), 12.3
-- =============================================================================

create table public.facilities (
  id uuid primary key default gen_random_uuid(),
  -- Health Facility Registry id where the facility is registered (PRD 11).
  hfr_id text unique,
  name_en text not null,
  name_local text,
  type public.facility_type not null,
  state_id uuid not null references public.states (id) on delete restrict,
  district_id uuid not null references public.districts (id) on delete restrict,
  block_id uuid references public.blocks (id) on delete set null,
  village_id uuid references public.villages (id) on delete set null,
  location extensions.geography(point, 4326) not null,
  address text,
  contact_phone text,
  emergency_phone text,
  is_24x7 boolean not null default false,
  has_emergency_department boolean not null default false,
  is_operational boolean not null default true,
  parent_facility_id uuid references public.facilities (id) on delete set null,
  -- Referral tier used as a tie-breaker when scoring (PRD 12.1).
  tier smallint not null default 1 check (tier between 1 and 4),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index facilities_location_idx on public.facilities using gist (location);
create index facilities_district_idx on public.facilities (district_id);
create index facilities_block_idx on public.facilities (block_id);
create index facilities_type_idx on public.facilities (type);
create index facilities_name_trgm_idx on public.facilities using gin (name_en extensions.gin_trgm_ops);

create trigger facilities_touch before update on public.facilities
  for each row execute function app.touch_updated_at();

create trigger facilities_audit
  after insert or update or delete on public.facilities
  for each row execute function app.audit_row('facility');

-- Close the loop on the user scope FK deferred from migration 0003.
alter table public.app_users
  add constraint app_users_facility_id_fkey
  foreign key (facility_id) references public.facilities (id) on delete restrict;

-- ---------------------------------------------------------------------------
-- Service catalogue: the vocabulary triage and referral speak in.
-- ---------------------------------------------------------------------------
create table public.service_catalog (
  code text primary key,
  name_en text not null,
  name_ta text not null,
  category text not null,          -- 'clinical' | 'diagnostic' | 'pharmacy' | 'emergency'
  -- Lowest facility tier that is normally expected to offer this service.
  min_tier smallint not null default 1 check (min_tier between 1 and 4),
  is_emergency_service boolean not null default false,
  created_at timestamptz not null default now()
);

comment on table public.service_catalog is
  'Configurable service vocabulary shared by triage rules and facility search.';

create table public.facility_services (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities (id) on delete cascade,
  service_code text not null references public.service_catalog (code) on delete restrict,
  status public.availability_status not null default 'unknown',
  notes text,
  updated_by uuid references public.app_users (id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (facility_id, service_code)
);

create index facility_services_facility_idx on public.facility_services (facility_id);
create index facility_services_code_idx on public.facility_services (service_code);

create trigger facility_services_touch before update on public.facility_services
  for each row execute function app.touch_updated_at();

-- ---------------------------------------------------------------------------
-- FacilityResource (PRD 11): doctors, medicines, diagnostics, beds, oxygen.
-- ---------------------------------------------------------------------------
create table public.facility_resources (
  id uuid primary key default gen_random_uuid(),
  facility_id uuid not null references public.facilities (id) on delete cascade,
  kind public.resource_kind not null,
  item_code text not null,              -- e.g. 'ORS', 'XRAY', 'GENERAL_BED'
  label_en text not null,
  label_ta text,
  status public.availability_status not null default 'unknown',
  quantity integer check (quantity >= 0),
  capacity integer check (capacity >= 0),
  -- PRD 12.3: manual override only with authorized role and reason.
  is_manual_override boolean not null default false,
  override_reason text,
  updated_by uuid references public.app_users (id) on delete set null,
  updated_at timestamptz not null default now(),
  unique (facility_id, kind, item_code),

  constraint facility_resources_override_reason_required check (
    not is_manual_override or coalesce(length(trim(override_reason)), 0) > 0
  ),
  constraint facility_resources_quantity_within_capacity check (
    capacity is null or quantity is null or quantity <= capacity
  )
);

create index facility_resources_facility_idx on public.facility_resources (facility_id);
create index facility_resources_kind_idx on public.facility_resources (facility_id, kind);
create index facility_resources_updated_idx on public.facility_resources (updated_at desc);

create trigger facility_resources_touch before update on public.facility_resources
  for each row execute function app.touch_updated_at();

create trigger facility_resources_audit
  after insert or update or delete on public.facility_resources
  for each row execute function app.audit_row('facility_resource');

-- Stamp the acting user so readiness updates are always attributable.
create or replace function app.stamp_updated_by()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  new.updated_by := coalesce(auth.uid(), new.updated_by);
  return new;
end;
$$;

create trigger facility_resources_stamp_actor
  before insert or update on public.facility_resources
  for each row execute function app.stamp_updated_by();

create trigger facility_services_stamp_actor
  before insert or update on public.facility_services
  for each row execute function app.stamp_updated_by();
