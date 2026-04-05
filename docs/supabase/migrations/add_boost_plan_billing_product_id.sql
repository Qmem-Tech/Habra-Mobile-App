-- Maps each boost plan row to an App Store / Play product id (RevenueCat package).
-- Set values in Supabase Table Editor → boost_plans.billing_product_id
-- to match the product identifier in App Store Connect / Google Play Console.

ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS billing_product_id TEXT;

COMMENT ON COLUMN public.boost_plans.billing_product_id IS
  'Store product id (e.g. com.habra.boost.listing_4wk). Must match a product attached to a RevenueCat offering package.';
