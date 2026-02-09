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
-- 2. BOOST PLANS (for business owners to promote deals/jobs)
-- -----------------------------------------------------------------------------
-- Run once, or truncate boost_plans before re-running to avoid duplicate rows.
INSERT INTO public.boost_plans (title, description, price_cents, duration_weeks, is_active) VALUES
  ('Starter', 'Get your listing in front of more people for 1 week.', 999, 1, true),
  ('Growth', '2 weeks of boosted visibility. Best for new promotions.', 1999, 2, true),
  ('Pro', '1 month of prime placement. Save 20% vs weekly.', 6999, 4, true),
  ('Scale', '3 months. Maximum reach for serious growth.', 14999, 12, true);

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
