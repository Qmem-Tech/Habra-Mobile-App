-- Adds profile fields required by business subscription checkout + webhook sync.
-- Safe to run multiple times.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS stripe_customer_id text,
  ADD COLUMN IF NOT EXISTS owner_tools_subscription_active boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS owner_tools_subscription_tier text DEFAULT 'basic',
  ADD COLUMN IF NOT EXISTS owner_tools_subscription_status text DEFAULT 'inactive',
  ADD COLUMN IF NOT EXISTS owner_tools_subscription_updated_at timestamptz;

-- Keep one Stripe customer id per profile when provided.
CREATE UNIQUE INDEX IF NOT EXISTS idx_profiles_stripe_customer_id_unique
  ON public.profiles (stripe_customer_id)
  WHERE stripe_customer_id IS NOT NULL;

-- Helpful query index for subscription lookups.
CREATE INDEX IF NOT EXISTS idx_profiles_owner_tools_subscription_tier
  ON public.profiles (owner_tools_subscription_tier);

CREATE INDEX IF NOT EXISTS idx_profiles_owner_tools_subscription_active
  ON public.profiles (owner_tools_subscription_active);

COMMENT ON COLUMN public.profiles.stripe_customer_id
  IS 'Stripe customer id used for hosted subscription checkout/portal.';
COMMENT ON COLUMN public.profiles.owner_tools_subscription_active
  IS 'Whether the business-owner tools subscription is currently active.';
COMMENT ON COLUMN public.profiles.owner_tools_subscription_tier
  IS 'Current business tier: basic | pro | premium.';
COMMENT ON COLUMN public.profiles.owner_tools_subscription_status
  IS 'Raw normalized lifecycle state: active | trialing | past_due | canceled | inactive.';
COMMENT ON COLUMN public.profiles.owner_tools_subscription_updated_at
  IS 'UTC timestamp of last webhook-driven subscription sync.';
