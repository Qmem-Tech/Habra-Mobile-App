-- Add the `bio` column to the `profiles` table.
-- Run this in your Supabase SQL Editor (Dashboard → SQL Editor → New query).

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS bio text;

COMMENT ON COLUMN public.profiles.bio IS 'Short user bio shown on their profile.';
