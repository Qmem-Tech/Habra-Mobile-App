-- Optional organizer-facing policy text shown on ticket detail (newline-separated bullets ok).
alter table public.events
  add column if not exists event_policy text;

comment on column public.events.event_policy is 'Shown to attendees on ticket detail; use newlines for multiple lines.';
