-- Optional coordinates for job posts (nearby search, maps).
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS location_lat DOUBLE PRECISION;
ALTER TABLE public.jobs ADD COLUMN IF NOT EXISTS location_lng DOUBLE PRECISION;
