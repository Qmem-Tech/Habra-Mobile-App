-- Super-admin can grant per-user subscription bypass (skip RevenueCat / paywall gating).
-- Mobile app reads `profiles.subscription_bypass`; only admins may change it.

ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_bypass boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.profiles.subscription_bypass IS
  'When true, business-owner subscription limits and RevenueCat paywall are bypassed for this user. Super-admin only.';

CREATE OR REPLACE FUNCTION public.protect_profile_subscription_bypass()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.subscription_bypass IS DISTINCT FROM OLD.subscription_bypass THEN
    IF NOT public.is_admin() THEN
      NEW.subscription_bypass := OLD.subscription_bypass;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_protect_profile_subscription_bypass ON public.profiles;
CREATE TRIGGER trg_protect_profile_subscription_bypass
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_profile_subscription_bypass();
