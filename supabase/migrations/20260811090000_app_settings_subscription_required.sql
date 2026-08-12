-- Global subscription gate: when false, all business owners bypass paid subscription.
INSERT INTO public.app_settings (key, value, updated_at)
VALUES ('subscription_required', 'true'::jsonb, now())
ON CONFLICT (key) DO NOTHING;

COMMENT ON TABLE public.app_settings IS
  'Platform key/value settings. subscription_required (bool): when false, mobile unlocks owner tools for everyone.';
