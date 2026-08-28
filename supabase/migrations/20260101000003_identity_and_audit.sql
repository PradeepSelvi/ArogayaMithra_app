-- =============================================================================
-- ArogyaMitra :: 0003 Identity, authorization scope and audit
-- PRD refs: 6 FR-001/FR-002/FR-023, 11 (User, AuditLog), 16 (security)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- app_users : ArogyaMitra profile attached 1:1 to a Supabase auth identity.
-- Role and scope live here, never on the client.
-- ---------------------------------------------------------------------------
create table public.app_users (
  id uuid primary key references auth.users (id) on delete cascade,
  role public.user_role not null default 'citizen',
  status public.account_status not null default 'pending',
  phone text unique,
  full_name text,
  employee_code text unique,
  preferred_language public.language_code not null default 'ta',
  -- Authorization scope. Narrowest non-null value wins.
  state_id uuid references public.states (id) on delete restrict,
  district_id uuid references public.districts (id) on delete restrict,
  block_id uuid references public.blocks (id) on delete restrict,
  facility_id uuid, -- FK added in the facilities migration
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_active_at timestamptz,

  -- Field staff and facility roles are meaningless without a scope.
  constraint app_users_scope_required check (
    role = 'citizen'
    or role = 'system_admin'
    or state_id is not null
    or district_id is not null
    or block_id is not null
    or facility_id is not null
  )
);

create index app_users_role_idx on public.app_users (role);
create index app_users_district_idx on public.app_users (district_id);
create index app_users_facility_idx on public.app_users (facility_id);
create index app_users_block_idx on public.app_users (block_id);

create trigger app_users_touch before update on public.app_users
  for each row execute function app.touch_updated_at();

comment on table public.app_users is
  'ArogyaMitra user profile: role, account status and authorization scope.';

-- ---------------------------------------------------------------------------
-- Provision a profile whenever an auth identity is created, so there is never
-- an authenticated session without a resolvable role.
-- ---------------------------------------------------------------------------
create or replace function app.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.app_users (id, phone, role, status, full_name)
  values (
    new.id,
    new.phone,
    'citizen',
    'active',
    nullif(new.raw_user_meta_data ->> 'full_name', '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function app.handle_new_auth_user();

comment on function app.handle_new_auth_user is
  'Creates a citizen-scoped app_users row for every new auth identity. '
  'Elevated roles are granted only by an administrator.';

-- ---------------------------------------------------------------------------
-- Authorization predicates.
-- SECURITY DEFINER so RLS policies on app_users do not recurse.
-- STABLE so the planner evaluates them once per statement.
-- ---------------------------------------------------------------------------

create or replace function app.current_role()
returns public.user_role
language sql
stable
security definer
set search_path = ''
as $$
  select u.role
  from public.app_users u
  where u.id = auth.uid()
    and u.status = 'active';
$$;

create or replace function app.current_facility_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.facility_id
  from public.app_users u
  where u.id = auth.uid() and u.status = 'active';
$$;

create or replace function app.current_district_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.district_id
  from public.app_users u
  where u.id = auth.uid() and u.status = 'active';
$$;

create or replace function app.current_block_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.block_id
  from public.app_users u
  where u.id = auth.uid() and u.status = 'active';
$$;

create or replace function app.current_state_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select u.state_id
  from public.app_users u
  where u.id = auth.uid() and u.status = 'active';
$$;

create or replace function app.has_role(p_roles public.user_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(app.current_role() = any (p_roles), false);
$$;

-- Any role that works inside the health system (i.e. not a citizen).
create or replace function app.is_health_worker()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.has_role(array[
    'asha', 'anm', 'medical_officer', 'facility_admin',
    'dho', 'state_admin', 'system_admin'
  ]::public.user_role[]);
$$;

create or replace function app.is_field_worker()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.has_role(array['asha', 'anm']::public.user_role[]);
$$;

create or replace function app.is_facility_staff()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.has_role(array['medical_officer', 'facility_admin']::public.user_role[]);
$$;

create or replace function app.is_administrator()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select app.has_role(array['dho', 'state_admin', 'system_admin']::public.user_role[]);
$$;

-- True when the caller's scope contains the given district.
-- PRD 27: "Role-based users cannot access data outside their scope."
create or replace function app.can_see_district(p_district_id uuid)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_role public.user_role := app.current_role();
begin
  if v_role is null or p_district_id is null then
    return false;
  end if;

  if v_role in ('system_admin', 'state_admin') then
    return true;
  end if;

  return exists (
    select 1
    from public.app_users u
    where u.id = auth.uid()
      and u.status = 'active'
      and (
        u.district_id = p_district_id
        or exists (
          select 1 from public.blocks b
          where b.id = u.block_id and b.district_id = p_district_id
        )
      )
  );
end;
$$;

-- ---------------------------------------------------------------------------
-- audit_logs : append-only record of sensitive actions.
-- PRD 6 FR-023, PRD 16, PRD 17 (auditability).
-- ---------------------------------------------------------------------------
create table public.audit_logs (
  id bigint generated always as identity primary key,
  occurred_at timestamptz not null default now(),
  actor_id uuid,                                  -- no FK: actor may be deleted, record must survive
  actor_role public.user_role,
  action text not null,                           -- e.g. 'referral.accept'
  resource_type text not null,
  resource_id text,
  purpose text not null default 'care_delivery',
  trace_id text,
  before_state jsonb,
  after_state jsonb,
  metadata jsonb not null default '{}'::jsonb
);

create index audit_logs_resource_idx on public.audit_logs (resource_type, resource_id);
create index audit_logs_actor_idx on public.audit_logs (actor_id, occurred_at desc);
create index audit_logs_occurred_idx on public.audit_logs (occurred_at desc);

comment on table public.audit_logs is
  'Append-only audit trail. UPDATE and DELETE are blocked at the database level.';

-- Enforce append-only regardless of role or connection.
create or replace function app.reject_audit_mutation()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  raise exception 'audit_logs is append-only (attempted %)', tg_op
    using errcode = 'insufficient_privilege';
end;
$$;

create trigger audit_logs_no_update
  before update on public.audit_logs
  for each row execute function app.reject_audit_mutation();

create trigger audit_logs_no_delete
  before delete on public.audit_logs
  for each row execute function app.reject_audit_mutation();

-- Convenience writer used by domain triggers and RPCs.
create or replace function app.write_audit(
  p_action text,
  p_resource_type text,
  p_resource_id text,
  p_before jsonb default null,
  p_after jsonb default null,
  p_metadata jsonb default '{}'::jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.audit_logs (
    actor_id, actor_role, action, resource_type, resource_id,
    purpose, trace_id, before_state, after_state, metadata
  )
  values (
    auth.uid(), app.current_role(), p_action, p_resource_type, p_resource_id,
    app.access_purpose(), app.trace_id(), p_before, p_after, coalesce(p_metadata, '{}'::jsonb)
  );
end;
$$;

-- Generic row-level audit trigger. Attach with:
--   create trigger x_audit after insert or update or delete on t
--     for each row execute function app.audit_row('resource_name');
create or replace function app.audit_row()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resource text := coalesce(tg_argv[0], tg_table_name);
  v_id text;
begin
  if tg_op = 'DELETE' then
    v_id := (to_jsonb(old) ->> 'id');
    perform app.write_audit(
      v_resource || '.delete', v_resource, v_id, to_jsonb(old), null
    );
    return old;
  elsif tg_op = 'UPDATE' then
    v_id := (to_jsonb(new) ->> 'id');
    perform app.write_audit(
      v_resource || '.update', v_resource, v_id, to_jsonb(old), to_jsonb(new)
    );
    return new;
  else
    v_id := (to_jsonb(new) ->> 'id');
    perform app.write_audit(
      v_resource || '.create', v_resource, v_id, null, to_jsonb(new)
    );
    return new;
  end if;
end;
$$;

create trigger app_users_audit
  after insert or update or delete on public.app_users
  for each row execute function app.audit_row('user');
