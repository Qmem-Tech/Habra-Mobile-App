-- =============================================================================
-- HABRA — Seed Data (SQL)
-- =============================================================================
-- Run this in Supabase Dashboard → SQL Editor after habra_full_schema.sql.
-- Safe to run more than once: uses ON CONFLICT where applicable.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. CATEGORIES (business types: Restaurant, Retail, etc.)
-- -----------------------------------------------------------------------------
INSERT INTO public.categories (name, slug) VALUES
  ('Restaurant', 'restaurant'),
  ('Cafe', 'cafe'),
  ('Retail', 'retail'),
  ('Events & Entertainment', 'events-entertainment'),
  ('Health & Beauty', 'health-beauty'),
  ('Professional Services', 'professional-services'),
  ('Food & Grocery', 'food-grocery'),
  ('Arts & Culture', 'arts-culture')
ON CONFLICT (name) DO NOTHING;

-- -----------------------------------------------------------------------------
-- 2. BOOST PLANS (per target: business listing, deal, job — matches mobile BoostPlanTarget)
-- -----------------------------------------------------------------------------
-- Run once, or truncate boost_plans before re-running to avoid duplicate rows.
INSERT INTO public.boost_plans (
  title, description, price_usd, original_price_usd, duration_weeks, is_active, target_type, billing_product_id
) VALUES
  ('Starter', 'Get your business profile in front of more people for 1 week.', 9.99, NULL, 1, true, 'business_listing', 'com.habra.habra.boost.business_listing.1wk'),
  ('Growth', '2 weeks of boosted visibility for your listing.', 19.99, NULL, 2, true, 'business_listing', 'com.habra.habra.boost.business_listing.2wk'),
  ('Pro', '1 month of prime placement for your business profile.', 69.99, 87.96, 4, true, 'business_listing', 'com.habra.habra.boost.business_listing.4wk'),
  ('Starter', 'Promote your deal to more customers — 1 week.', 8.99, NULL, 1, true, 'deal', 'com.habra.habra.boost.deal.1wk'),
  ('Growth', '2 weeks of boosted reach for your deal.', 17.99, NULL, 2, true, 'deal', 'com.habra.habra.boost.deal.2wk'),
  ('Pro', '1 month of prime placement for your deal.', 64.99, 79.96, 4, true, 'deal', 'com.habra.habra.boost.deal.4wk'),
  ('Starter', 'Reach more applicants — 1 week boost.', 10.99, NULL, 1, true, 'job', 'com.habra.habra.boost.job.1wk'),
  ('Growth', '2 weeks of visibility for your job post.', 21.99, NULL, 2, true, 'job', 'com.habra.habra.boost.job.2wk'),
  ('Pro', '1 month of prime placement for hiring.', 69.99, 87.96, 4, true, 'job', 'com.habra.habra.boost.job.4wk');

-- -----------------------------------------------------------------------------
-- 3. APP SETTINGS (feature flags, maintenance, etc.)
-- -----------------------------------------------------------------------------
INSERT INTO public.app_settings (key, value, updated_at) VALUES
  ('maintenance_mode', 'false'::jsonb, now()),
  ('min_app_version_android', '"1.0.0"'::jsonb, now()),
  ('min_app_version_ios', '"1.0.0"'::jsonb, now()),
  ('feature_boosts_enabled', 'true'::jsonb, now()),
  ('feature_messages_enabled', 'false'::jsonb, now())
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  updated_at = EXCLUDED.updated_at;

-- =============================================================================
-- Optional: sample data for staging/dev (uncomment to use)
-- =============================================================================
-- These require at least one profile (user) and optionally one business.
-- Create a user via your app or Auth → Users first, then replace the UUIDs below.

/*
-- Example: one approved business (replace <owner_id> with a real profiles.id)
INSERT INTO public.businesses (
  owner_id, name, slug, address_city, address_state, address_country,
  approval_status, is_active, is_verified
) VALUES (
  '<owner_id>'::uuid,
  'Sample Restaurant',
  'sample-restaurant',
  'Washington',
  'DC',
  'US',
  'approved',
  true,
  false
) ON CONFLICT (slug) DO NOTHING;
*/

-- =============================================================================
-- Done. Check Table Editor: categories, boost_plans, app_settings.
-- =============================================================================
