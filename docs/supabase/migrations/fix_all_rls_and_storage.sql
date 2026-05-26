-- =============================================================================
-- FIX ALL RLS AND STORAGE ISSUES
-- =============================================================================
-- Run this in Supabase Dashboard → SQL Editor to fix common RLS and storage
-- permission errors (e.g. "new row violates row-level security policy",
-- "permission denied", "bucket not found").
--
-- This script:
-- 1. Creates all required storage buckets (if missing)
-- 2. Applies permissive storage policies so authenticated users can upload
-- 3. Ensures SELECT policies allow reads where needed
--
-- Safe to run multiple times (uses DROP IF EXISTS, ON CONFLICT, etc.).
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CREATE STORAGE BUCKETS
-- -----------------------------------------------------------------------------

-- businesses: logos, cover images, gallery
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('businesses', 'businesses', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- events: event images
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('events', 'events', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- resumes: job application resumes
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('resumes', 'resumes', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- legal_documents: business legal docs (2 per business)
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('legal_documents', 'legal_documents', true, 10485760)  -- 10MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- avatars: profile photos
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('avatars', 'avatars', true, 2097152)  -- 2MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- deals: deal images
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('deals', 'deals', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- reviews: review photos
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('reviews', 'reviews', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;

-- applicant_photos: optional job application photos
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES ('applicant_photos', 'applicant_photos', true, 5242880)  -- 5MB
ON CONFLICT (id) DO UPDATE SET file_size_limit = EXCLUDED.file_size_limit, public = EXCLUDED.public;


-- -----------------------------------------------------------------------------
-- 2. PERMISSIVE STORAGE POLICIES (allows any authenticated user to upload)
-- -----------------------------------------------------------------------------

-- businesses
DROP POLICY IF EXISTS "businesses_insert" ON storage.objects;
DROP POLICY IF EXISTS "businesses_update" ON storage.objects;
DROP POLICY IF EXISTS "businesses_select" ON storage.objects;
CREATE POLICY "businesses_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'businesses');
CREATE POLICY "businesses_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'businesses') WITH CHECK (bucket_id = 'businesses');
CREATE POLICY "businesses_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'businesses');

-- events
DROP POLICY IF EXISTS "events_insert" ON storage.objects;
DROP POLICY IF EXISTS "events_select" ON storage.objects;
CREATE POLICY "events_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'events');
CREATE POLICY "events_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'events');

-- resumes
DROP POLICY IF EXISTS "resumes_insert_own" ON storage.objects;
DROP POLICY IF EXISTS "resumes_select" ON storage.objects;
CREATE POLICY "resumes_insert_own" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'resumes');
CREATE POLICY "resumes_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'resumes');

-- legal_documents
DROP POLICY IF EXISTS "legal_docs_insert" ON storage.objects;
DROP POLICY IF EXISTS "legal_docs_select" ON storage.objects;
CREATE POLICY "legal_docs_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'legal_documents');
CREATE POLICY "legal_docs_select" ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'legal_documents');

-- avatars
DROP POLICY IF EXISTS "avatars_insert" ON storage.objects;
DROP POLICY IF EXISTS "avatars_update" ON storage.objects;
DROP POLICY IF EXISTS "avatars_select" ON storage.objects;
CREATE POLICY "avatars_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars');
CREATE POLICY "avatars_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'avatars') WITH CHECK (bucket_id = 'avatars');
CREATE POLICY "avatars_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'avatars');

-- deals
DROP POLICY IF EXISTS "deals_insert" ON storage.objects;
DROP POLICY IF EXISTS "deals_update" ON storage.objects;
DROP POLICY IF EXISTS "deals_select" ON storage.objects;
CREATE POLICY "deals_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'deals');
CREATE POLICY "deals_update" ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'deals') WITH CHECK (bucket_id = 'deals');
CREATE POLICY "deals_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'deals');

-- reviews
DROP POLICY IF EXISTS "reviews_insert" ON storage.objects;
DROP POLICY IF EXISTS "reviews_select" ON storage.objects;
CREATE POLICY "reviews_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'reviews');
CREATE POLICY "reviews_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'reviews');

-- applicant_photos
DROP POLICY IF EXISTS "applicant_photos_insert" ON storage.objects;
DROP POLICY IF EXISTS "applicant_photos_select" ON storage.objects;
CREATE POLICY "applicant_photos_insert" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'applicant_photos');
CREATE POLICY "applicant_photos_select" ON storage.objects FOR SELECT TO public
  USING (bucket_id = 'applicant_photos');


-- -----------------------------------------------------------------------------
-- 3. ENSURE business_legal_documents TABLE EXISTS (if legal docs flow used)
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.business_legal_documents (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
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

-- RLS for business_legal_documents
ALTER TABLE public.business_legal_documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_legal_docs_select_owner" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_select_owner" ON public.business_legal_documents FOR SELECT
  USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "business_legal_docs_select_admin" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_select_admin" ON public.business_legal_documents FOR SELECT
  USING (public.is_admin());

DROP POLICY IF EXISTS "business_legal_docs_insert_owner" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_insert_owner" ON public.business_legal_documents FOR INSERT
  WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

DROP POLICY IF EXISTS "business_legal_docs_update_admin" ON public.business_legal_documents;
CREATE POLICY "business_legal_docs_update_admin" ON public.business_legal_documents FOR UPDATE
  USING (
    public.is_admin()
    OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
  )
  WITH CHECK (true);


-- -----------------------------------------------------------------------------
-- 4. ENSURE businesses TABLE HAS IMAGE COLUMNS
-- -----------------------------------------------------------------------------
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS logo_url TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS background_url TEXT;
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS image_urls TEXT[] DEFAULT '{}';


-- -----------------------------------------------------------------------------
-- DONE
-- -----------------------------------------------------------------------------
-- After running, test:
-- - Business owner: Edit business → upload logo/cover
-- - Business owner: Create event → upload event image
-- - Community: Apply for job → upload resume
-- - Community: Write review → upload photo
-- - Business owner: Legal documents → upload 2 docs
