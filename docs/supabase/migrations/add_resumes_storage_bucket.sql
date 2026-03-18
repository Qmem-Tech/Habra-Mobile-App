-- Create the resumes storage bucket and policies for job application uploads.
-- Run in Supabase Dashboard → SQL Editor if resume upload fails with "bucket not found".
--
-- Path structure: {user_id}/{job_id}/{timestamp}.{ext}
-- Users can only upload to their own folder (first path segment = auth.uid()).

-- 1. Create the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES (
  'resumes',
  'resumes',
  true,   -- public so resume URLs work when viewing applications
  5242880 -- 5MB per file
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  public = EXCLUDED.public;

-- 2. Allow authenticated users to INSERT their own resumes (path: user_id/job_id/file.ext)
DROP POLICY IF EXISTS "resumes_insert_own" ON storage.objects;
CREATE POLICY "resumes_insert_own"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'resumes'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Allow SELECT (read) resumes - authenticated users can view
DROP POLICY IF EXISTS "resumes_select" ON storage.objects;
CREATE POLICY "resumes_select"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'resumes');
