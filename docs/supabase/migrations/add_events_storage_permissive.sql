-- Permissive storage policy for events bucket.
-- Run if uploads still fail with permission errors AFTER add_events_storage_bucket.sql.

DROP POLICY IF EXISTS "events_insert" ON storage.objects;
DROP POLICY IF EXISTS "events_select" ON storage.objects;

CREATE POLICY "events_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'events');

CREATE POLICY "events_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'events');
