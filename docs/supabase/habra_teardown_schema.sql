-- =============================================================================
-- HABRA — Teardown / Reset Schema (drop all Habra tables, functions, enums)
-- =============================================================================
-- Use this if you ran habra_full_schema.sql more than once and got errors,
-- or if you want to wipe the Habra schema and run habra_full_schema.sql again
-- on a clean slate.
--
-- WARNING: This deletes ALL data in Habra tables. Run only on staging/dev
-- or when you intend to recreate everything. For production, prefer migrations
-- instead of full teardown.
--
-- Steps: Run this script in Supabase SQL Editor, then run habra_full_schema.sql
-- once.
-- =============================================================================

-- 1. Drop trigger on auth.users (references public.handle_new_user)
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- 2. Drop all Habra tables (reverse dependency order; CASCADE drops policies)
DROP TABLE IF EXISTS public.app_settings CASCADE;
DROP TABLE IF EXISTS public.audit_log CASCADE;
DROP TABLE IF EXISTS public.boosts CASCADE;
DROP TABLE IF EXISTS public.boost_plans CASCADE;
DROP TABLE IF EXISTS public.notifications CASCADE;
DROP TABLE IF EXISTS public.job_bookmarks CASCADE;
DROP TABLE IF EXISTS public.saved_items CASCADE;
DROP TABLE IF EXISTS public.job_applications CASCADE;
DROP TABLE IF EXISTS public.tickets CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.deal_redemptions CASCADE;
DROP TABLE IF EXISTS public.review_replies CASCADE;
DROP TABLE IF EXISTS public.reviews CASCADE;
DROP TABLE IF EXISTS public.jobs CASCADE;
DROP TABLE IF EXISTS public.event_tickets CASCADE;
DROP TABLE IF EXISTS public.events CASCADE;
DROP TABLE IF EXISTS public.deals CASCADE;
DROP TABLE IF EXISTS public.business_categories CASCADE;
DROP TABLE IF EXISTS public.categories CASCADE;
DROP TABLE IF EXISTS public.businesses CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;

-- 3. Drop functions
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.update_business_rating() CASCADE;
DROP FUNCTION IF EXISTS public.set_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.is_admin() CASCADE;

-- 4. Drop enums (order does not matter; no enum references another)
DROP TYPE IF EXISTS public.business_approval_status CASCADE;
DROP TYPE IF EXISTS public.boost_status CASCADE;
DROP TYPE IF EXISTS public.job_application_status CASCADE;
DROP TYPE IF EXISTS public.deal_status CASCADE;
DROP TYPE IF EXISTS public.ticket_status CASCADE;
DROP TYPE IF EXISTS public.order_status CASCADE;
DROP TYPE IF EXISTS public.app_role CASCADE;

-- =============================================================================
-- Done. You can now run habra_full_schema.sql once.
-- =============================================================================
