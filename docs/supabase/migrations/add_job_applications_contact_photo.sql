-- Add contact info and optional photo to job applications.
-- Enables email/phone display and optional applicant photo.
ALTER TABLE public.job_applications
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT;

-- Create applicant_photos storage bucket for optional applicant photos.
-- Run in Supabase Dashboard: Storage → New bucket → applicant_photos (public).
