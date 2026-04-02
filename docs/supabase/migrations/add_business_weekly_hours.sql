-- Per-day opening hours (e.g. short Sunday). Mobile Update Hours + optional API consumers.
-- Keys are weekday strings "1".."7" (Monday=1 .. Sunday=7, same as Dart DateTime.weekday).
-- Each value: { "closed": true } or { "closed": false, "open": "09:00", "close": "17:00" }
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS weekly_hours JSONB;

COMMENT ON COLUMN public.businesses.weekly_hours IS
  'Weekly schedule: {"1":{"closed":false,"open":"09:00","close":"17:00"},...,"7":{"closed":true}}';
