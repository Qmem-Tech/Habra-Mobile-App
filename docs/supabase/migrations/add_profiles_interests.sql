-- Add profile interests for onboarding + edit-profile personalization.
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS interests TEXT[] DEFAULT '{}'::text[];
