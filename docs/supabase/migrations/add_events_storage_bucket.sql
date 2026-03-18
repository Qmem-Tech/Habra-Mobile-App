-- Create the events storage bucket and policies for event image uploads.
-- Run in Supabase Dashboard → SQL Editor if event image upload fails with RLS/permission errors.
--
-- Path structure: {user_id}/{timestamp}.{ext}
-- Create event page uploads with organizer's user id as first path segment.

-- 1. Create the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES (
  'events',
  'events',
  true,   -- public so event images work in listings
  5242880 -- 5MB per file
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  public = EXCLUDED.public;

-- 2. Allow authenticated users to INSERT when path starts with their user id
DROP POLICY IF EXISTS "events_insert" ON storage.objects;
CREATE POLICY "events_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'events'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

-- 3. Allow public SELECT (bucket is public)
DROP POLICY IF EXISTS "events_select" ON storage.objects;
CREATE POLICY "events_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'events');
