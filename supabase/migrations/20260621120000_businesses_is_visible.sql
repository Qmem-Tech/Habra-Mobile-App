-- Admin-controlled flag: when false, business is hidden from the mobile app (owners still see their listing).
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS is_visible boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.businesses.is_visible IS
  'When false, listing is hidden from public app feeds while remaining approved for the owner.';

UPDATE public.businesses SET is_visible = true WHERE is_visible IS DISTINCT FROM true;

-- Public read: approved + active + visible (owners and admins retain full access via other policies).
DROP POLICY IF EXISTS businesses_select ON public.businesses;
CREATE POLICY businesses_select ON public.businesses
  FOR SELECT
  USING (
    (
      approval_status = 'approved'::public.business_approval_status
      AND is_active = true
      AND is_visible = true
    )
    OR owner_id = auth.uid()
  );

DROP POLICY IF EXISTS deals_select ON public.deals;
CREATE POLICY deals_select ON public.deals
  FOR SELECT
  USING (
    (
      status = 'active'::public.deal_status
      AND EXISTS (
        SELECT 1
        FROM public.businesses b
        WHERE b.id = deals.business_id
          AND b.approval_status = 'approved'::public.business_approval_status
          AND b.is_active = true
          AND b.is_visible = true
      )
    )
    OR EXISTS (
      SELECT 1
      FROM public.businesses b
      WHERE b.id = deals.business_id
        AND b.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS jobs_select ON public.jobs;
CREATE POLICY jobs_select ON public.jobs
  FOR SELECT
  USING (
    (
      is_active = true
      AND EXISTS (
        SELECT 1
        FROM public.businesses b
        WHERE b.id = jobs.business_id
          AND b.approval_status = 'approved'::public.business_approval_status
          AND b.is_active = true
          AND b.is_visible = true
      )
    )
    OR EXISTS (
      SELECT 1
      FROM public.businesses b
      WHERE b.id = jobs.business_id
        AND b.owner_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS business_listing_views_insert ON public.business_listing_views;
CREATE POLICY business_listing_views_insert ON public.business_listing_views
  FOR INSERT
  TO authenticated, anon
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.businesses b
      WHERE b.id = business_listing_views.business_id
        AND b.approval_status = 'approved'::public.business_approval_status
        AND b.is_active = true
        AND b.is_visible = true
    )
  );

-- Nearby business feed (PostGIS locations join — matches production schema).
CREATE OR REPLACE FUNCTION public.habra_feed_nearby_business_ids(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision DEFAULT 80,
  p_limit integer DEFAULT 400
)
RETURNS TABLE (business_id uuid, dist_km double precision)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    b.id AS business_id,
    (ST_Distance(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) / 1000.0)::double precision AS dist_km
  FROM public.businesses b
  JOIN public.locations l ON l.id = b.location_id
  WHERE b.approval_status = 'approved'::business_approval_status
    AND b.is_active = true
    AND b.is_visible = true
    AND l.location IS NOT NULL
    AND ST_DWithin(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_km * 1000.0
    )
  ORDER BY dist_km ASC
  LIMIT p_limit;
$$;
