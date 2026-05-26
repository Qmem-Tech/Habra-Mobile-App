-- =============================================================================
-- Normalize reusable physical locations and nearby search.
-- =============================================================================
-- Safe to run after habra_full_schema.sql. Existing address columns remain in
-- place during rollout so old app versions and legacy rows keep working.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE IF NOT EXISTS public.locations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT,
  address_line1 TEXT,
  address_line2 TEXT,
  city TEXT,
  state TEXT,
  country TEXT DEFAULT 'US',
  postal_code TEXT,
  latitude NUMERIC,
  longitude NUMERIC,
  place_id TEXT,
  timezone TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  google_maps_url TEXT,
  location GEOGRAPHY(Point, 4326)
    GENERATED ALWAYS AS (
      CASE
        WHEN latitude IS NOT NULL AND longitude IS NOT NULL
        THEN ST_SetSRID(ST_MakePoint(longitude::double precision, latitude::double precision), 4326)::geography
        ELSE NULL
      END
    ) STORED,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_locations_place_id ON public.locations(place_id)
  WHERE place_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_locations_city_state ON public.locations(city, state);
CREATE INDEX IF NOT EXISTS idx_locations_location_gist ON public.locations USING GIST(location);
CREATE UNIQUE INDEX IF NOT EXISTS idx_locations_unique_place_id ON public.locations(place_id)
  WHERE place_id IS NOT NULL;

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL;

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS location_id UUID REFERENCES public.locations(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS is_online BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS online_url TEXT;

CREATE INDEX IF NOT EXISTS idx_businesses_location_id ON public.businesses(location_id);
CREATE INDEX IF NOT EXISTS idx_events_location_id ON public.events(location_id);
CREATE INDEX IF NOT EXISTS idx_events_online ON public.events(is_online);

ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "locations_select" ON public.locations;
CREATE POLICY "locations_select" ON public.locations
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "locations_insert_authenticated" ON public.locations;
CREATE POLICY "locations_insert_authenticated" ON public.locations
  FOR INSERT TO authenticated
  WITH CHECK (true);

DROP POLICY IF EXISTS "locations_update_business_owner" ON public.locations;
CREATE POLICY "locations_update_business_owner" ON public.locations
  FOR UPDATE TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.location_id = locations.id
        AND b.owner_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.location_id = locations.id
        AND e.organizer_id = auth.uid()
    )
  )
  WITH CHECK (true);

DROP POLICY IF EXISTS "admin_locations" ON public.locations;
CREATE POLICY "admin_locations" ON public.locations
  FOR ALL USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Backfill businesses. We intentionally create one location per business row
-- unless a Google place_id is present in future data, because existing rows do
-- not have a stable dedupe key.
INSERT INTO public.locations (
  name,
  address_line1,
  city,
  state,
  country,
  postal_code,
  latitude,
  longitude,
  is_verified,
  created_at,
  updated_at
)
SELECT
  b.name,
  b.address_street,
  b.address_city,
  b.address_state,
  COALESCE(b.address_country, 'US'),
  b.address_zip,
  b.latitude,
  b.longitude,
  b.is_verified,
  COALESCE(b.created_at, now()),
  COALESCE(b.updated_at, now())
FROM public.businesses b
WHERE b.location_id IS NULL
  AND (
    b.address_street IS NOT NULL
    OR b.address_city IS NOT NULL
    OR (b.latitude IS NOT NULL AND b.longitude IS NOT NULL)
  );

WITH ranked AS (
  SELECT
    b.id AS business_id,
    l.id AS location_id,
    row_number() OVER (
      PARTITION BY b.id
      ORDER BY l.created_at DESC, l.id
    ) AS rn
  FROM public.businesses b
  JOIN public.locations l
    ON COALESCE(l.name, '') = COALESCE(b.name, '')
   AND COALESCE(l.address_line1, '') = COALESCE(b.address_street, '')
   AND COALESCE(l.city, '') = COALESCE(b.address_city, '')
   AND COALESCE(l.state, '') = COALESCE(b.address_state, '')
   AND COALESCE(l.postal_code, '') = COALESCE(b.address_zip, '')
   AND COALESCE(l.latitude::text, '') = COALESCE(b.latitude::text, '')
   AND COALESCE(l.longitude::text, '') = COALESCE(b.longitude::text, '')
  WHERE b.location_id IS NULL
)
UPDATE public.businesses b
SET location_id = ranked.location_id
FROM ranked
WHERE ranked.business_id = b.id
  AND ranked.rn = 1;

-- Backfill events from venue columns.
INSERT INTO public.locations (
  name,
  address_line1,
  latitude,
  longitude,
  created_at,
  updated_at
)
SELECT
  e.venue_name,
  e.venue_address,
  e.venue_lat,
  e.venue_lng,
  COALESCE(e.created_at, now()),
  COALESCE(e.updated_at, now())
FROM public.events e
WHERE e.location_id IS NULL
  AND COALESCE(e.is_online, false) = false
  AND (
    e.venue_name IS NOT NULL
    OR e.venue_address IS NOT NULL
    OR (e.venue_lat IS NOT NULL AND e.venue_lng IS NOT NULL)
  );

WITH ranked AS (
  SELECT
    e.id AS event_id,
    l.id AS location_id,
    row_number() OVER (
      PARTITION BY e.id
      ORDER BY l.created_at DESC, l.id
    ) AS rn
  FROM public.events e
  JOIN public.locations l
    ON COALESCE(l.name, '') = COALESCE(e.venue_name, '')
   AND COALESCE(l.address_line1, '') = COALESCE(e.venue_address, '')
   AND COALESCE(l.latitude::text, '') = COALESCE(e.venue_lat::text, '')
   AND COALESCE(l.longitude::text, '') = COALESCE(e.venue_lng::text, '')
  WHERE e.location_id IS NULL
    AND COALESCE(e.is_online, false) = false
)
UPDATE public.events e
SET location_id = ranked.location_id
FROM ranked
WHERE ranked.event_id = e.id
  AND ranked.rn = 1;

DROP FUNCTION IF EXISTS public.habra_feed_nearby_event_ids(double precision, double precision, double precision, integer);
DROP FUNCTION IF EXISTS public.habra_feed_nearby_business_ids(double precision, double precision, double precision, integer);

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
    AND l.location IS NOT NULL
    AND ST_DWithin(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_km * 1000.0
    )
  ORDER BY dist_km ASC
  LIMIT p_limit;
$$;

CREATE OR REPLACE FUNCTION public.habra_feed_nearby_event_ids(
  p_lat double precision,
  p_lng double precision,
  p_radius_km double precision DEFAULT 80,
  p_limit integer DEFAULT 200
)
RETURNS TABLE (event_id uuid, dist_km double precision)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    e.id AS event_id,
    (ST_Distance(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) / 1000.0)::double precision AS dist_km
  FROM public.events e
  JOIN public.locations l ON l.id = e.location_id
  WHERE e.is_active = true
    AND COALESCE(e.is_online, false) = false
    AND e.start_at >= now()
    AND e.start_at <= now() + interval '7 days'
    AND l.location IS NOT NULL
    AND ST_DWithin(
      l.location,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
      p_radius_km * 1000.0
    )
  ORDER BY dist_km ASC, e.start_at ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.habra_feed_nearby_business_ids(double precision, double precision, double precision, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.habra_feed_nearby_event_ids(double precision, double precision, double precision, integer) TO anon, authenticated;
