-- =============================================================================
-- ArogyaMitra :: 0012 Follow-up tasks and citizen feedback
-- PRD refs: 5.2, 6 FR-011/FR-012, 11 (FollowUp, Feedback), 18, 19
-- =============================================================================

create table public.followups (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid not null references public.patients (id) on delete cascade,
  referral_id uuid references public.referrals (id) on delete set null,
  district_id uuid not null references public.districts (id) on delete restrict,
  assignee_id uuid references public.app_users (id) on delete set null,
  task_type text not null default 'post_referral_check'
    check (task_type in (
      'post_referral_check', 'medication_adherence', 'anc_visit',
      'immunisation', 'chronic_review', 'custom'
    )),
  instructions_key text not null default 'followup.default',
  notes text,
  due_date date not null,
  status public.followup_status not null default 'scheduled',
  completed_at timestamptz,
  outcome text,
  -- Offline provenance (PRD 15)
  created_by uuid references public.app_users (id) on delete set null,
  client_created_at timestamptz,
  synced_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint followups_completion_requires_outcome check (
    status <> 'completed' or coalesce(length(trim(outcome)), 0) > 0
  )
);

create index followups_assignee_due_idx on public.followups (assignee_id, due_date)
  where status in ('scheduled', 'due');
create index followups_patient_idx on public.followups (patient_id, due_date desc);
create index followups_referral_idx on public.followups (referral_id);
create index followups_district_idx on public.followups (district_id, due_date);

create trigger followups_touch before update on public.followups
  for each row execute function app.touch_updated_at();

create trigger followups_audit
  after insert or update or delete on public.followups
  for each row execute function app.audit_row('followup');

comment on table public.followups is
  'Follow-up task queue for ASHA/ANM workers (PRD 5.2, FR-011).';

create or replace function app.normalise_followup()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.district_id is null then
    select p.district_id into new.district_id
    from public.patients p where p.id = new.patient_id;
  end if;

  -- Default the assignee to the worker who owns the patient's household.
  if new.assignee_id is null then
    select h.assigned_worker_id into new.assignee_id
    from public.patients p
    join public.households h on h.id = p.household_id
    where p.id = new.patient_id;
  end if;

  if tg_op = 'INSERT' then
    new.created_by := coalesce(new.created_by, auth.uid());
    new.synced_at := now();
  end if;

  if new.status = 'completed' then
    new.completed_at := coalesce(new.completed_at, now());
  end if;

  return new;
end;
$$;

create trigger followups_normalise
  before insert or update on public.followups
  for each row execute function app.normalise_followup();

-- Auto-schedule a check after a referral completes (PRD 7.14).
create or replace function app.schedule_followup_on_completion()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_cfg jsonb := coalesce(
    app.active_config('followup_policy'),
    '{"post_referral_days":3}'::jsonb
  );
begin
  if new.status <> 'COMPLETED' then
    return null;
  end if;

  if exists (
    select 1 from public.followups f
    where f.referral_id = new.id and f.task_type = 'post_referral_check'
  ) then
    return null;
  end if;

  insert into public.followups (
    patient_id, referral_id, district_id, task_type,
    instructions_key, due_date, status, created_by
  )
  values (
    new.patient_id, new.id, new.district_id, 'post_referral_check',
    'followup.post_referral',
    (now() + make_interval(days => coalesce((v_cfg ->> 'post_referral_days')::int, 3)))::date,
    'scheduled', new.created_by
  );

  return null;
end;
$$;

create trigger referrals_schedule_followup
  after update of status on public.referrals
  for each row execute function app.schedule_followup_on_completion();

-- Scheduled sweep: move due tasks, mark misses, notify assignees (PRD 18).
create or replace function public.refresh_followup_states()
returns table (marked_due integer, marked_missed integer)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_due integer := 0;
  v_missed integer := 0;
  v_cfg jsonb := coalesce(app.active_config('followup_policy'), '{"grace_days":7}'::jsonb);
  v_grace integer := coalesce((v_cfg ->> 'grace_days')::int, 7);
  v_row record;
begin
  for v_row in
    update public.followups f
    set status = 'due'
    where f.status = 'scheduled' and f.due_date <= current_date
    returning f.id, f.assignee_id, f.patient_id, f.district_id
  loop
    v_due := v_due + 1;

    if v_row.assignee_id is not null then
      perform app.queue_notifications(
        app.emit_event('followup.due', 'followup', v_row.id::text,
          jsonb_build_object('patient_id', v_row.patient_id), v_row.district_id),
        'followup.due',
        (select jsonb_build_array(jsonb_build_object(
           'user_id', u.id, 'role', u.role, 'language', u.preferred_language))
         from public.app_users u where u.id = v_row.assignee_id and u.status = 'active'),
        jsonb_build_object(
          'patient_name', (select p.full_name from public.patients p where p.id = v_row.patient_id),
          'action', jsonb_build_object('route', '/followups', 'id', v_row.id)
        )
      );
    end if;
  end loop;

  with missed as (
    update public.followups f
    set status = 'missed'
    where f.status = 'due' and f.due_date < current_date - v_grace
    returning f.id
  )
  select count(*) into v_missed from missed;

  return query select v_due, v_missed;
end;
$$;

-- ---------------------------------------------------------------------------
-- Feedback (PRD 11, FR-012, 19 citizen satisfaction)
-- ---------------------------------------------------------------------------
create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  patient_id uuid references public.patients (id) on delete set null,
  submitted_by uuid references public.app_users (id) on delete set null,
  facility_id uuid references public.facilities (id) on delete set null,
  referral_id uuid references public.referrals (id) on delete set null,
  district_id uuid references public.districts (id) on delete restrict,
  rating smallint not null check (rating between 1 and 5),
  -- Would-recommend answer, used for the NPS-like measure in PRD 19.
  would_recommend boolean,
  category text not null default 'general'
    check (category in (
      'general', 'waiting_time', 'staff_behaviour', 'medicine_unavailable',
      'diagnostic_unavailable', 'cleanliness', 'cost', 'referral_process',
      'ambulance', 'teleconsult', 'other'
    )),
  comment text,
  language public.language_code not null default 'ta',
  status text not null default 'new' check (status in ('new', 'triaged', 'actioned', 'closed')),
  resolution_note text,
  resolved_by uuid references public.app_users (id) on delete set null,
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index feedback_facility_idx on public.feedback (facility_id, created_at desc);
create index feedback_district_idx on public.feedback (district_id, created_at desc);
create index feedback_open_idx on public.feedback (status) where status in ('new', 'triaged');

create trigger feedback_touch before update on public.feedback
  for each row execute function app.touch_updated_at();

create or replace function app.normalise_feedback()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    new.submitted_by := coalesce(new.submitted_by, auth.uid());
  end if;

  if new.district_id is null then
    if new.facility_id is not null then
      select f.district_id into new.district_id
      from public.facilities f where f.id = new.facility_id;
    elsif new.patient_id is not null then
      select p.district_id into new.district_id
      from public.patients p where p.id = new.patient_id;
    end if;
  end if;

  if new.status in ('actioned', 'closed') and new.resolved_at is null then
    new.resolved_at := now();
    new.resolved_by := coalesce(new.resolved_by, auth.uid());
  end if;

  return new;
end;
$$;

create trigger feedback_normalise
  before insert or update on public.feedback
  for each row execute function app.normalise_feedback();

-- Low ratings and supply-side complaints are raised to the facility and DHO.
create or replace function app.on_feedback_created()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_event_id bigint;
begin
  v_event_id := app.emit_event(
    'feedback.created', 'feedback', new.id::text,
    jsonb_build_object(
      'rating', new.rating, 'category', new.category, 'facility_id', new.facility_id
    ),
    new.district_id
  );

  if new.rating <= 2 or new.category in ('medicine_unavailable', 'diagnostic_unavailable', 'ambulance') then
    perform app.emit_event(
      'feedback.issue', 'feedback', new.id::text,
      jsonb_build_object(
        'rating', new.rating, 'category', new.category, 'facility_id', new.facility_id
      ),
      new.district_id
    );
  end if;

  return null;
end;
$$;

create trigger feedback_emit_event
  after insert on public.feedback
  for each row execute function app.on_feedback_created();
