-- Multi-location: optional parent listing, branch display label, monthly view counter (denormalized).
-- Apply in Supabase SQL editor or CLI. PostgREST embed hint: businesses!businesses_parent_business_id_fkey

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS parent_business_id UUID REFERENCES public.businesses (id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_businesses_parent_business_id
  ON public.businesses (parent_business_id)
  WHERE parent_business_id IS NOT NULL;

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS location_label TEXT;

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS monthly_profile_views INTEGER NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.businesses.parent_business_id IS
  'Root listing id for satellite locations; must belong to the same owner.';
COMMENT ON COLUMN public.businesses.location_label IS
  'Short label for this branch in owner UI (e.g. neighborhood or city).';
COMMENT ON COLUMN public.businesses.monthly_profile_views IS
  'Optional denormalized counter for owner dashboard; update via job or trigger as needed.';

CREATE OR REPLACE FUNCTION public.businesses_enforce_parent_same_owner()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.parent_business_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1
      FROM public.businesses p
      WHERE p.id = NEW.parent_business_id
        AND p.owner_id IS NOT DISTINCT FROM NEW.owner_id
    ) THEN
      RAISE EXCEPTION 'parent_business_id must reference a business with the same owner_id';
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_businesses_parent_same_owner ON public.businesses;
CREATE TRIGGER tr_businesses_parent_same_owner
  BEFORE INSERT OR UPDATE OF parent_business_id, owner_id ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.businesses_enforce_parent_same_owner();
