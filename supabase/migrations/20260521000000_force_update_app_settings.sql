-- Force-update: public read for version keys (splash runs before login).
-- Seeds store URLs and optional message for the update dialog.

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename  = 'app_settings'
      AND policyname = 'app_settings_select_public'
  ) THEN
    EXECUTE $policy$
      CREATE POLICY app_settings_select_public
        ON public.app_settings
        FOR SELECT
        USING (true)
    $policy$;
  END IF;
END;
$$;

INSERT INTO public.app_settings (key, value, updated_at) VALUES
  (
    'force_update_message',
    '"A newer version of Habra is required to continue. Please update from the app store."'::jsonb,
    now()
  ),
  (
    'store_url_android',
    '"https://play.google.com/store/apps/details?id=com.habra.habra"'::jsonb,
    now()
  ),
  (
    'store_url_ios',
    '"https://apps.apple.com/app/habra/id000000000"'::jsonb,
    now()
  )
ON CONFLICT (key) DO NOTHING;
