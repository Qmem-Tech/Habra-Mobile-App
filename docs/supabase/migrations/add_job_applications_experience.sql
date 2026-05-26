-- Structured work history on applications (JSON array). Shown on owner Applicant Details.
ALTER TABLE public.job_applications
  ADD COLUMN IF NOT EXISTS experience JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN public.job_applications.experience IS
  'Array of objects: title, company, employment_type, start_year, start_month, end_year, end_month, is_current';
