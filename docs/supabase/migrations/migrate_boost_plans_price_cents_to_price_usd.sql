-- =============================================================================
-- boost_plans: store price in USD dollars (NUMERIC) instead of integer cents
-- =============================================================================
-- Run after boost_plans exists. Safe to run once; drops legacy price_cents.
-- =============================================================================

ALTER TABLE public.boost_plans ADD COLUMN IF NOT EXISTS price_usd NUMERIC(10, 2);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'boost_plans' AND column_name = 'price_cents'
  ) THEN
    UPDATE public.boost_plans
    SET price_usd = ROUND((price_cents::numeric / 100.0), 2)
    WHERE price_usd IS NULL;
  END IF;
END $$;

ALTER TABLE public.boost_plans ALTER COLUMN price_usd SET NOT NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'boost_plans' AND column_name = 'price_cents'
  ) THEN
    ALTER TABLE public.boost_plans DROP COLUMN price_cents;
  END IF;
END $$;
