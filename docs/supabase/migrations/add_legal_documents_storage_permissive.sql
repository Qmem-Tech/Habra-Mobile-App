-- Permissive storage policy for legal_documents bucket.
-- Run if uploads fail with permission errors. Run AFTER add_business_legal_documents.sql.

DROP POLICY IF EXISTS "legal_docs_insert" ON storage.objects;
DROP POLICY IF EXISTS "legal_docs_select" ON storage.objects;

CREATE POLICY "legal_docs_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'legal_documents');

CREATE POLICY "legal_docs_select"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'legal_documents');
