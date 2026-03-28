-- Fix: Super admin cannot see legal document rows in approval UI.
--
-- Symptom: Owners upload to business_legal_documents (and storage) successfully, but
-- admin dashboard shows empty / errors because RLS only allowed SELECT for owners.
--
-- Run in Supabase Dashboard → SQL Editor (safe to re-run).
-- Requires public.is_admin() from habra_full_schema (profiles.role = 'admin').

DROP POLICY IF EXISTS "business_legal_docs_select_admin" ON public.business_legal_documents;

CREATE POLICY "business_legal_docs_select_admin"
ON public.business_legal_documents
FOR SELECT
USING (public.is_admin());
