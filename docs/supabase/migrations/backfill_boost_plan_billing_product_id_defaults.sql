-- Backfill billing_product_id for existing boost plans so boost purchases can map
-- to RevenueCat packages and App Store / Play products.
--
-- IMPORTANT:
-- 1) These ids must exist as product identifiers in App Store Connect / Google Play.
-- 2) The same product identifiers must be attached to RevenueCat packages.
-- 3) If your store ids use a different naming convention, edit these values accordingly.

ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS billing_product_id TEXT;

UPDATE public.boost_plans
SET billing_product_id = CONCAT(
  'com.habra.habra.boost.',
  target_type::text,
  '.',
  duration_weeks::text,
  'wk'
)
WHERE is_active = true
  AND (billing_product_id IS NULL OR btrim(billing_product_id) = '');

COMMENT ON COLUMN public.boost_plans.billing_product_id IS
  'Store product id (App Store / Play) used to map plan -> RevenueCat package.';

-- Optional audit query: find plans still missing linkage.
-- SELECT id, title, target_type, duration_weeks
-- FROM public.boost_plans
-- WHERE is_active = true
--   AND (billing_product_id IS NULL OR btrim(billing_product_id) = '');
