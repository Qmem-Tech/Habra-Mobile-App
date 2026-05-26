-- Business legal documents: 2 required documents per business, super admin approval.
-- Run in Supabase Dashboard → SQL Editor.
--
-- Flow: Business owner uploads 2 docs → status 'pending' → super admin approves → status 'approved'.

-- 1. Table for legal document metadata
CREATE TABLE IF NOT EXISTS public.business_legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,  -- e.g. 'business_license', 'tax_id', 'doc_1', 'doc_2'
  file_url TEXT NOT NULL,
  storage_bucket TEXT NOT NULL DEFAULT 'legal_documents',
  storage_path TEXT,
  mime_type TEXT,
  file_size_bytes BIGINT,
  file_name TEXT,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  uploaded_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id),
  rejection_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_legal_docs_business ON public.business_legal_documents(business_id);
CREATE INDEX IF NOT EXISTS idx_business_legal_docs_status ON public.business_legal_documents(status);

-- RLS: owners can insert/select their own; admin can update (approve/reject)
ALTER TABLE public.business_legal_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_legal_docs_select_owner" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_select_owner"
ON public.business_legal_documents FOR SELECT
USING (
  EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Super admin approval UI must read all rows (owners already matched above).
DROP POLICY IF EXISTS "business_legal_docs_select_admin" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_select_admin"
ON public.business_legal_documents FOR SELECT
USING (public.is_admin());

DROP POLICY IF EXISTS "business_legal_docs_insert_owner" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_insert_owner"
ON public.business_legal_documents FOR INSERT
WITH CHECK (
  EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Admin can update (approve/reject); owners can update their own rows if needed
DROP POLICY IF EXISTS "business_legal_docs_update_admin" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_update_admin"
ON public.business_legal_documents FOR UPDATE
USING (
  public.is_admin()
  OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
)
WITH CHECK (true);

-- 2. Storage bucket for legal documents
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES (
  'legal_documents',
  'legal_documents',
  true,   -- public for simplicity; RLS on table controls who can upload
  10485760  -- 10MB per file
)
ON CONFLICT (id) DO UPDATE SET
  file_size_limit = EXCLUDED.file_size_limit;

-- Storage policy: authenticated users can upload (app controls business_id path)
DROP POLICY IF EXISTS "legal_docs_insert" ON storage.objects;
CREATE POLICY "legal_docs_insert"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'legal_documents');

DROP POLICY IF EXISTS "legal_docs_select" ON storage.objects;
CREATE POLICY "legal_docs_select"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'legal_documents');
