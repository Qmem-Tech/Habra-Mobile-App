-- Nearby feed helpers (haversine, km). Run in Supabase SQL Editor after habra_full_schema.sql.
-- Grants: anon + authenticated can execute (read-only public listings).

DROP FUNCTION IF EXISTS public.habra_feed_nearby_event_ids(double precision, double precision, double precision, integer);
DROP FUNCTION IF EXISTS public.habra_feed_nearby_business_ids(double precision, double precision, double precision, integer);
DROP FUNCTION IF EXISTS public.habra_distance_km(double precision, double precision, double precision, double precision);

CREATE OR REPLACE FUNCTION public.habra_distance_km(
  lat1 double precision,
  lon1 double precision,
  lat2 double precision,
  lon2 double precision
) RETURNS double precision
LANGUAGE sql
IMMUTABLE
STRICT
AS $$
  SELECT (
    6371.0 * acos(
      LEAST(1.0::double precision, GREATEST(-1.0::double precision,
        cos(radians(lat1)) * cos(radians(lat2)) *
        cos(radians(lon2) - radians(lon1)) +
        sin(radians(lat1)) * sin(radians(lat2))
      ))
    )
  )::double precision;
$$;

-- Approved, active businesses with coordinates within radius (km), nearest first.
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
  SELECT b.id AS business_id,
    public.habra_distance_km(
      p_lat, p_lng,
      b.latitude::double precision,
      b.longitude::double precision
    ) AS dist_km
  FROM public.businesses b
  WHERE b.approval_status = 'approved'::business_approval_status
    AND b.is_active = true
    AND b.latitude IS NOT NULL
    AND b.longitude IS NOT NULL
    AND public.habra_distance_km(
      p_lat, p_lng,
      b.latitude::double precision,
      b.longitude::double precision
    ) <= p_radius_km
  ORDER BY dist_km ASC
  LIMIT p_limit;
$$;

-- Events in the next 7 days: distance from venue_lat/lng or linked business coordinates.
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
  SELECT ranked.id AS event_id, ranked.dist_km
  FROM (
    SELECT
      e.id,
      e.start_at,
      CASE
        WHEN e.venue_lat IS NOT NULL AND e.venue_lng IS NOT NULL THEN
          public.habra_distance_km(
            p_lat, p_lng,
            e.venue_lat::double precision,
            e.venue_lng::double precision
          )
        WHEN e.business_id IS NOT NULL THEN (
          SELECT public.habra_distance_km(
            p_lat, p_lng,
            b.latitude::double precision,
            b.longitude::double precision
          )
          FROM public.businesses b
          WHERE b.id = e.business_id
            AND b.approval_status = 'approved'::business_approval_status
            AND b.is_active = true
            AND b.latitude IS NOT NULL
            AND b.longitude IS NOT NULL
        )
        ELSE NULL::double precision
      END AS dist_km
    FROM public.events e
    WHERE e.is_active = true
      AND e.start_at >= now()
      AND e.start_at <= now() + interval '7 days'
  ) ranked
  WHERE ranked.dist_km IS NOT NULL
    AND ranked.dist_km <= p_radius_km
  ORDER BY ranked.dist_km ASC, ranked.start_at ASC
  LIMIT p_limit;
$$;

GRANT EXECUTE ON FUNCTION public.habra_distance_km(double precision, double precision, double precision, double precision) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.habra_feed_nearby_business_ids(double precision, double precision, double precision, integer) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.habra_feed_nearby_event_ids(double precision, double precision, double precision, integer) TO anon, authenticated;
