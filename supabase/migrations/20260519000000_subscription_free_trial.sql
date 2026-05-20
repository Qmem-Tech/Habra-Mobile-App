-- Free-trial support for business-owner subscriptions.
-- Admin toggles it on/off and configures duration from the super-admin site;
-- the mobile app checks these settings when loading the paywall.

----------------------------------------------------------------------
-- 1. Track trial on profiles (one trial per user).
----------------------------------------------------------------------
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS subscription_trial_starts_at timestamptz,
  ADD COLUMN IF NOT EXISTS subscription_trial_ends_at   timestamptz;

----------------------------------------------------------------------
-- 2. Allow authenticated (mobile) users to read app_settings so the
--    app can fetch subscription_trial_enabled / subscription_trial_months.
----------------------------------------------------------------------
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'app_settings'
      AND policyname = 'app_settings_select_authenticated'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY app_settings_select_authenticated
        ON public.app_settings
        FOR SELECT
        USING (auth.uid() IS NOT NULL)
    $policy$;
  END IF;
END;
$$;

----------------------------------------------------------------------
-- 3. Seed default trial settings (no-op if keys already exist).
----------------------------------------------------------------------
INSERT INTO public.app_settings (key, value, updated_at) VALUES
  ('subscription_trial_enabled', 'false', now()),
  ('subscription_trial_months',  '2',     now())
ON CONFLICT (key) DO NOTHING;
