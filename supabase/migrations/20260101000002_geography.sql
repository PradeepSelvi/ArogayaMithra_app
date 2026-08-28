-- =============================================================================
-- ArogyaMitra :: 0002 Administrative geography
-- State > District > Block > Village. Drives scope-based authorization
-- (PRD 6 FR-002) and DHO/State drill-down (PRD 5.4).
-- =============================================================================

create table public.states (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,               -- LGD / census code
  name_en text not null,
  name_local text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.districts (
  id uuid primary key default gen_random_uuid(),
  state_id uuid not null references public.states (id) on delete restrict,
  code text not null unique,
  name_en text not null,
  name_local text,
  centroid extensions.geography(point, 4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.blocks (
  id uuid primary key default gen_random_uuid(),
  district_id uuid not null references public.districts (id) on delete restrict,
  code text not null unique,
  name_en text not null,
  name_local text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.villages (
  id uuid primary key default gen_random_uuid(),
  block_id uuid not null references public.blocks (id) on delete restrict,
  code text not null unique,
  name_en text not null,
  name_local text,
  centroid extensions.geography(point, 4326),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index districts_state_id_idx on public.districts (state_id);
create index blocks_district_id_idx on public.blocks (district_id);
create index villages_block_id_idx on public.villages (block_id);
create index districts_centroid_idx on public.districts using gist (centroid);
create index villages_centroid_idx on public.villages using gist (centroid);

create trigger states_touch before update on public.states
  for each row execute function app.touch_updated_at();
create trigger districts_touch before update on public.districts
  for each row execute function app.touch_updated_at();
create trigger blocks_touch before update on public.blocks
  for each row execute function app.touch_updated_at();
create trigger villages_touch before update on public.villages
  for each row execute function app.touch_updated_at();

comment on table public.districts is
  'District master. Scope boundary for DHO role (PRD 4).';
