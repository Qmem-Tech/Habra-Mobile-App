-- Append-only events when a community user opens a business listing (mobile / web).
-- Dashboard aggregates these for "Views Over Time" and week-over-week change.
--
-- Apply in Supabase SQL editor or via CLI. Adjust policy names if they collide.

CREATE TABLE IF NOT EXISTS public.business_listing_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses (id) ON DELETE CASCADE,
  -- Optional; matches auth user id when logged in. No FK so anon + partial profiles stay valid.
  viewer_user_id UUID,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_business_listing_views_business_created
  ON public.business_listing_views (business_id, created_at DESC);

ALTER TABLE public.business_listing_views ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_listing_views_insert" ON public.business_listing_views;
CREATE POLICY "business_listing_views_insert"
  ON public.business_listing_views FOR INSERT
  TO authenticated, anon
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.businesses b
      WHERE b.id = business_id
        AND b.approval_status = 'approved'
        AND b.is_active = true
    )
  );

DROP POLICY IF EXISTS "business_listing_views_select_owner" ON public.business_listing_views;
CREATE POLICY "business_listing_views_select_owner"
  ON public.business_listing_views FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1
      FROM public.businesses b
      WHERE b.id = business_listing_views.business_id
        AND b.owner_id = auth.uid()
    )
  );

COMMENT ON TABLE public.business_listing_views IS
  'One row per business detail view; used for owner dashboard analytics.';
