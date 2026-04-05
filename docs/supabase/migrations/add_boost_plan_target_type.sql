-- =============================================================================
-- boost_plans.target_type + boosts.target_type
-- =============================================================================
-- Run in Supabase SQL Editor on existing projects (after boost_plans / boosts exist).
-- Values must match the mobile app [BoostPlanTarget] / optionType strings:
--   business_listing | deal | job
-- =============================================================================

DO $$ BEGIN
  CREATE TYPE public.boost_plan_target AS ENUM ('business_listing', 'deal', 'job');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS target_type public.boost_plan_target NOT NULL DEFAULT 'business_listing';

ALTER TABLE public.boosts
  ADD COLUMN IF NOT EXISTS target_type public.boost_plan_target;

UPDATE public.boosts
SET target_type = CASE
  WHEN deal_id IS NOT NULL THEN 'deal'::public.boost_plan_target
  WHEN job_id IS NOT NULL THEN 'job'::public.boost_plan_target
  ELSE 'business_listing'::public.boost_plan_target
END
WHERE target_type IS NULL;

ALTER TABLE public.boosts
  ALTER COLUMN target_type SET NOT NULL,
  ALTER COLUMN target_type SET DEFAULT 'business_listing';

CREATE INDEX IF NOT EXISTS idx_boost_plans_target_active
  ON public.boost_plans (target_type)
  WHERE is_active = true;
