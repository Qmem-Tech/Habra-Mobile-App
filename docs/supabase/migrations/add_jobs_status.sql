-- Add status column to jobs for draft/active/closed support.
-- Draft jobs sync between mobile and web via Supabase.
ALTER TABLE public.jobs
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'open';
