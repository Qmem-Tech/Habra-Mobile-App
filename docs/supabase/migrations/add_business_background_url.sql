-- Add background image URL to businesses (mandatory with logo).
ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS background_url TEXT;
