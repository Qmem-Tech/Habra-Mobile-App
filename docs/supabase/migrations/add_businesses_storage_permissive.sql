-- PERMISSIVE storage policy for businesses bucket.
-- Use this if uploads fail with "permission denied" or "unauthorized" even when signed in.
--
-- This allows any authenticated user to upload to the businesses bucket.
-- The app controls which paths are used (business_id/logo, user_id/new/..., etc.).
-- Run this AFTER add_businesses_storage_bucket.sql if the strict policy fails.
--
-- To apply: Supabase Dashboard → SQL Editor → paste and run.

-- Drop the strict policies (they may have different names if already customized)
DROP POLICY IF EXISTS "businesses_insert" ON storage.objects;
DROP POLICY IF EXISTS "businesses_update" ON storage.objects;

-- Allow any authenticated user to INSERT into businesses bucket
CREATE POLICY "businesses_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'businesses');

-- Allow any authenticated user to UPDATE in businesses bucket
CREATE POLICY "businesses_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (bucket_id = 'businesses')
WITH CHECK (bucket_id = 'businesses');
