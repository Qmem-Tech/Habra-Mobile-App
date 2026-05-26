-- Add auto_renew column to boosts if not exists (for subscription-style boosts)
ALTER TABLE public.boosts ADD COLUMN IF NOT EXISTS auto_renew BOOLEAN DEFAULT false;
