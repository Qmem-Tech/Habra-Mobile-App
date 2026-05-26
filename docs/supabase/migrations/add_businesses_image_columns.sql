-- Ensure businesses table has logo_url, background_url, and image_urls.
-- Run this if "Images uploaded but we couldn't save the update" appears.
-- Supabase Dashboard → SQL Editor → paste and run.

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS logo_url TEXT;

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS background_url TEXT;

-- image_urls as TEXT[] for gallery URLs (optional)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'businesses' AND column_name = 'image_urls'
  ) THEN
    ALTER TABLE public.businesses ADD COLUMN image_urls TEXT[] DEFAULT '{}';
  END IF;
END $$;
