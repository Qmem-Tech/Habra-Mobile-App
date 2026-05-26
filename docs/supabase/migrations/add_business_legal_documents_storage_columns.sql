-- =============================================================================
-- business_legal_documents: storage_bucket + storage_path (single source of truth)
-- =============================================================================
-- Run in Supabase SQL Editor after add_business_legal_documents.sql.
--
-- Every row should carry the real bucket id and the exact Storage object key used in
-- upload(), plus mime/size for admin review. file_url remains for quick linking.
-- =============================================================================

ALTER TABLE public.business_legal_documents
  ADD COLUMN IF NOT EXISTS storage_bucket TEXT NOT NULL DEFAULT 'legal_documents',
  ADD COLUMN IF NOT EXISTS storage_path TEXT,
  ADD COLUMN IF NOT EXISTS mime_type TEXT,
  ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT;

COMMENT ON COLUMN public.business_legal_documents.storage_bucket IS
  'Supabase Storage bucket id; production rows should be legal_documents.';
COMMENT ON COLUMN public.business_legal_documents.storage_path IS
  'Object key within bucket (no leading slash), same string passed to Storage upload().';

-- Ensure default applies to any legacy NULL (if column existed without default)
UPDATE public.business_legal_documents
SET storage_bucket = 'legal_documents'
WHERE storage_bucket IS NULL OR trim(storage_bucket) = '';

-- Backfill storage_path from public URL: .../object/public/legal_documents/<path>
UPDATE public.business_legal_documents
SET storage_path = regexp_replace(
    file_url,
    '^.*\/object\/public\/legal_documents\/',
    ''
  )
WHERE (storage_path IS NULL OR storage_path = '')
  AND file_url LIKE '%/object/public/legal_documents/%';
