-- Push-notification fan-out, force-update remote config, sold-out waitlist.
-- Run with: supabase db push

----------------------------------------------------------------------
-- 1. app_config: single-row table the splash screen reads on startup.
----------------------------------------------------------------------
create table if not exists public.app_config (
  id                int primary key default 1,
  min_android       text,
  min_ios           text,
  latest_android    text,
  latest_ios        text,
  store_url_android text,
  store_url_ios     text,
  message           text,
  updated_at        timestamptz not null default now(),
  constraint app_config_single_row check (id = 1)
);

insert into public.app_config (id) values (1)
  on conflict (id) do nothing;

alter table public.app_config enable row level security;

drop policy if exists "Anyone can read app_config" on public.app_config;
create policy "Anyone can read app_config"
  on public.app_config for select
  using (true);

drop policy if exists "Admins can update app_config" on public.app_config;
create policy "Admins can update app_config"
  on public.app_config for update
  using (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and lower(p.role) = 'admin'
    )
  )
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and lower(p.role) = 'admin'
    )
  );

----------------------------------------------------------------------
-- 2. event_ticket_waitlist: "Notify Me" on sold-out tickets.
----------------------------------------------------------------------
create table if not exists public.event_ticket_waitlist (
  user_id         uuid not null references auth.users(id) on delete cascade,
  event_id        uuid not null,
  ticket_type_id  uuid not null,
  created_at      timestamptz not null default now(),
  notified_at     timestamptz,
  primary key (user_id, event_id, ticket_type_id)
);

alter table public.event_ticket_waitlist enable row level security;

drop policy if exists "Users manage their own waitlist rows"
  on public.event_ticket_waitlist;
create policy "Users manage their own waitlist rows"
  on public.event_ticket_waitlist
  for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

----------------------------------------------------------------------
-- 3. platform_notifications: admin broadcasts (read by all matching users).
--    Assumes the table already exists; this only normalises columns.
----------------------------------------------------------------------
create table if not exists public.platform_notifications (
  id          uuid primary key default gen_random_uuid(),
  title       text not null,
  body        text not null,
  audience    text not null default 'all',
  created_by  uuid references auth.users(id),
  created_at  timestamptz not null default now()
);

alter table public.platform_notifications enable row level security;

drop policy if exists "Anyone can read platform notifications"
  on public.platform_notifications;
create policy "Anyone can read platform notifications"
  on public.platform_notifications for select
  using (true);

drop policy if exists "Admins can send platform notifications"
  on public.platform_notifications;
create policy "Admins can send platform notifications"
  on public.platform_notifications for insert
  with check (
    exists (
      select 1 from public.profiles p
      where p.id = auth.uid() and lower(p.role) = 'admin'
    )
  );

----------------------------------------------------------------------
-- 4. Triggers that POST to the send-push-notification Edge Function
--    using the http extension (Supabase). Requires SUPABASE_URL and a
--    SUPABASE_FUNCTIONS_INVOKE_KEY (service role) stored as DB-level
--    settings via `alter database ... set ...` (see comments below).
----------------------------------------------------------------------
create extension if not exists http with schema extensions;

create or replace function public.invoke_send_push_notification(
  p_source text,
  p_notification_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_url  text;
  v_key  text;
begin
  -- Configure these once per environment:
  --   alter database postgres set "app.settings.supabase_url" = 'https://<ref>.supabase.co';
  --   alter database postgres set "app.settings.service_role_key" = '<service role key>';
  v_url := current_setting('app.settings.supabase_url', true);
  v_key := current_setting('app.settings.service_role_key', true);
  if v_url is null or v_key is null then
    raise notice 'invoke_send_push_notification skipped: settings missing';
    return;
  end if;

  perform extensions.http_post(
    url     := v_url || '/functions/v1/send-push-notification',
    body    := json_build_object(
      'source', p_source,
      'notification_id', p_notification_id::text
    )::text,
    params  := array[]::extensions.http_header[],
    headers := array[
      extensions.http_header('Authorization', 'Bearer ' || v_key),
      extensions.http_header('Content-Type', 'application/json')
    ]
  );
end;
$$;

----------------------------------------------------------------------
-- Trigger: any new row in public.notifications -> per-user push.
----------------------------------------------------------------------
create or replace function public.tg_notifications_after_insert()
returns trigger
language plpgsql
as $$
begin
  perform public.invoke_send_push_notification('user', new.id);
  return new;
end;
$$;

drop trigger if exists notifications_after_insert on public.notifications;
create trigger notifications_after_insert
  after insert on public.notifications
  for each row
  execute function public.tg_notifications_after_insert();

----------------------------------------------------------------------
-- Trigger: any new row in public.platform_notifications -> broadcast push.
----------------------------------------------------------------------
create or replace function public.tg_platform_notifications_after_insert()
returns trigger
language plpgsql
as $$
begin
  perform public.invoke_send_push_notification('platform', new.id);
  return new;
end;
$$;

drop trigger if exists platform_notifications_after_insert
  on public.platform_notifications;
create trigger platform_notifications_after_insert
  after insert on public.platform_notifications
  for each row
  execute function public.tg_platform_notifications_after_insert();
