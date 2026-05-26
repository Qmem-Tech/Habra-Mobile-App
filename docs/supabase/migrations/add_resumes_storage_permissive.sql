-- Permissive storage policy for resumes bucket.
-- Run if uploads still fail with permission errors AFTER add_resumes_storage_bucket.sql.

DROP POLICY IF EXISTS "resumes_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "resumes_select" ON storage.objects;

CREATE POLICY "resumes_insert_own"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'resumes');

CREATE POLICY "resumes_select"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'resumes');
