-- =============================================================================
-- ArogyaMitra :: 0009 Domain events, outbox and notifications
-- PRD refs: 6 FR-014/FR-022, 8.1 (event-driven), 11 (Notification), 18
--
-- Domain events are written in the same transaction as the state change they
-- describe (transactional outbox). A worker drains the outbox and calls the
-- delivery adapters, so an SMS gateway outage can never roll back a referral.
-- =============================================================================

create table public.domain_events (
  id bigint generated always as identity primary key,
  event_type text not null,                 -- 'referral.accepted', 'readiness.critical'
  aggregate_type text not null,             -- 'referral', 'facility'
  aggregate_id text not null,
  payload jsonb not null default '{}'::jsonb,
  district_id uuid references public.districts (id) on delete set null,
  actor_id uuid,
  trace_id text,
  occurred_at timestamptz not null default now(),
  -- Outbox dispatch state
  processed_at timestamptz,
  attempts smallint not null default 0,
  last_error text
);

create index domain_events_unprocessed_idx
  on public.domain_events (occurred_at)
  where processed_at is null;
create index domain_events_aggregate_idx on public.domain_events (aggregate_type, aggregate_id);
create index domain_events_type_time_idx on public.domain_events (event_type, occurred_at desc);

comment on table public.domain_events is
  'Transactional outbox. Feeds notifications (PRD 18) and analytics (PRD 19).';

create or replace function app.emit_event(
  p_event_type text,
  p_aggregate_type text,
  p_aggregate_id text,
  p_payload jsonb default '{}'::jsonb,
  p_district_id uuid default null
)
returns bigint
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id bigint;
begin
  insert into public.domain_events (
    event_type, aggregate_type, aggregate_id, payload, district_id, actor_id, trace_id
  )
  values (
    p_event_type, p_aggregate_type, p_aggregate_id,
    coalesce(p_payload, '{}'::jsonb), p_district_id, auth.uid(), app.trace_id()
  )
  returning id into v_id;

  return v_id;
end;
$$;

-- ---------------------------------------------------------------------------
-- Notification templates and routing matrix (PRD 18)
-- ---------------------------------------------------------------------------
create table public.notification_templates (
  key text primary key,
  event_type text not null,
  channel public.notification_channel not null,
  audience_role public.user_role not null,
  title_en text not null,
  title_ta text not null,
  body_en text not null,
  body_ta text not null,
  is_active boolean not null default true,
  -- Optional notifications from the PRD 18 matrix default to off.
  is_optional boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index notification_templates_event_idx
  on public.notification_templates (event_type, audience_role) where is_active;

create trigger notification_templates_touch before update on public.notification_templates
  for each row execute function app.touch_updated_at();

comment on table public.notification_templates is
  'Localised notification content. No user-facing string is hard-coded (PRD 17).';

-- ---------------------------------------------------------------------------
-- Notification (PRD 11)
-- ---------------------------------------------------------------------------
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.app_users (id) on delete cascade,
  template_key text references public.notification_templates (key) on delete set null,
  channel public.notification_channel not null default 'in_app',
  language public.language_code not null default 'ta',
  title text not null,
  body text not null,
  -- Deep link target, e.g. {"route":"/referral","id":"..."}
  action jsonb not null default '{}'::jsonb,
  event_id bigint references public.domain_events (id) on delete set null,
  status public.delivery_status not null default 'queued',
  provider_reference text,
  failure_reason text,
  read_at timestamptz,
  queued_at timestamptz not null default now(),
  sent_at timestamptz,
  delivered_at timestamptz
);

create index notifications_recipient_idx
  on public.notifications (recipient_id, queued_at desc);
create index notifications_unread_idx
  on public.notifications (recipient_id) where read_at is null;
create index notifications_pending_idx
  on public.notifications (queued_at) where status = 'queued';

comment on table public.notifications is
  'Per-recipient notification inbox and delivery ledger (PRD 13 GET /notifications).';

-- Renders every template registered for an event/audience pair.
create or replace function app.queue_notifications(
  p_event_id bigint,
  p_event_type text,
  p_recipients jsonb,   -- [{"user_id":"...","role":"citizen","language":"ta"}]
  p_vars jsonb default '{}'::jsonb
)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_recipient jsonb;
  v_template public.notification_templates;
  v_title text;
  v_body text;
  v_lang public.language_code;
  v_count integer := 0;
  v_key text;
  v_val text;
begin
  for v_recipient in select * from jsonb_array_elements(coalesce(p_recipients, '[]'::jsonb)) loop
    v_lang := coalesce((v_recipient ->> 'language')::public.language_code, 'ta');

    for v_template in
      select t.*
      from public.notification_templates t
      where t.event_type = p_event_type
        and t.audience_role = (v_recipient ->> 'role')::public.user_role
        and t.is_active
        and not t.is_optional
    loop
      if v_lang = 'ta' then
        v_title := v_template.title_ta;
        v_body := v_template.body_ta;
      else
        v_title := v_template.title_en;
        v_body := v_template.body_en;
      end if;

      -- Simple {{var}} interpolation from p_vars.
      for v_key, v_val in select key, value from jsonb_each_text(coalesce(p_vars, '{}'::jsonb)) loop
        v_title := replace(v_title, '{{' || v_key || '}}', coalesce(v_val, ''));
        v_body := replace(v_body, '{{' || v_key || '}}', coalesce(v_val, ''));
      end loop;

      insert into public.notifications (
        recipient_id, template_key, channel, language, title, body, action, event_id
      )
      values (
        (v_recipient ->> 'user_id')::uuid, v_template.key, v_template.channel,
        v_lang, v_title, v_body, coalesce(p_vars -> 'action', '{}'::jsonb), p_event_id
      );

      v_count := v_count + 1;
    end loop;
  end loop;

  return v_count;
end;
$$;

-- Citizen-facing inbox action.
create or replace function public.mark_notification_read(p_notification_id uuid)
returns public.notifications
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_row public.notifications;
begin
  update public.notifications
  set read_at = coalesce(read_at, now())
  where id = p_notification_id
  returning * into v_row;

  if v_row.id is null then
    raise exception 'Notification % not found', p_notification_id using errcode = 'no_data_found';
  end if;

  return v_row;
end;
$$;
