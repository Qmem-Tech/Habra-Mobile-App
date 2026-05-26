-- Add contact info, optional photo, and screening answers to job_applications.
-- Required for the mobile apply flow (inserts full_name, email, phone, screening_answers).
-- Run this on projects created from an older habra_full_schema.sql that omitted these columns.
ALTER TABLE public.job_applications
  ADD COLUMN IF NOT EXISTS full_name TEXT,
  ADD COLUMN IF NOT EXISTS email TEXT,
  ADD COLUMN IF NOT EXISTS phone TEXT,
  ADD COLUMN IF NOT EXISTS photo_url TEXT,
  ADD COLUMN IF NOT EXISTS screening_answers JSONB NOT NULL DEFAULT '{}'::jsonb;

-- Create applicant_photos storage bucket for optional applicant photos.
-- Run in Supabase Dashboard: Storage → New bucket → applicant_photos (public).
