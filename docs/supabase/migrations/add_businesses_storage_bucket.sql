-- Create the businesses storage bucket and policies for logo, background, and gallery uploads.
-- Run this in Supabase Dashboard → SQL Editor if business image upload fails with permission errors.
--
-- Path structures:
--   - New business: {user_id}/new/{timestamp}/logo, {user_id}/new/{timestamp}/background
--   - Existing business: {business_id}/logo, {business_id}/background, {business_id}/gallery/...
--
-- Authenticated users can upload to their own user_id path (new business) or to business_id paths
-- where they own the business.

-- 1. Create the bucket (if it doesn't exist)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES (
  'businesses',
  'businesses',
  true,   -- public so logo/background URLs work in listings
  5242880 -- 5MB per file
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit,
  public = EXCLUDED.public;

-- 2. Allow authenticated users to INSERT
--    - To {user_id}/... (new business flow)
--    - To {business_id}/... where user owns the business
DROP POLICY IF EXISTS "businesses_insert" ON storage.objects;
CREATE POLICY "businesses_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'businesses'
  AND (
    -- New business: path starts with user's id
    (storage.foldername(name))[1] = auth.uid()::text
    OR
    -- Existing business: first path segment is a business_id owned by user
    EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id::text = (storage.foldername(name))[1]
      AND b.owner_id = auth.uid()
    )
  )
);

-- 3. Allow public SELECT (bucket is public, but explicit policy for RLS)
DROP POLICY IF EXISTS "businesses_select" ON storage.objects;
CREATE POLICY "businesses_select"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'businesses');

-- 4. Allow authenticated users to UPDATE their own uploads (same path rules as insert)
DROP POLICY IF EXISTS "businesses_update" ON storage.objects;
CREATE POLICY "businesses_update"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'businesses'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id::text = (storage.foldername(name))[1]
      AND b.owner_id = auth.uid()
    )
  )
)
WITH CHECK (
  bucket_id = 'businesses'
  AND (
    (storage.foldername(name))[1] = auth.uid()::text
    OR EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id::text = (storage.foldername(name))[1]
      AND b.owner_id = auth.uid()
    )
  )
);
