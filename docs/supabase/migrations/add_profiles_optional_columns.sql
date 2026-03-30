-- Add optional profile columns used by the mobile app.
-- Run this in your Supabase SQL Editor (Dashboard > SQL Editor > New query).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bio text,
  ADD COLUMN IF NOT EXISTS city text;

COMMENT ON COLUMN public.profiles.bio IS 'Short user bio shown on their profile.';
COMMENT ON COLUMN public.profiles.city IS 'User location / city for display.';
