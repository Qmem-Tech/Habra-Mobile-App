-- Deal redemptions: verifiable codes, one per user per deal, analytics count via trigger.
-- Run in Supabase SQL editor (or migrate) after reviewing.

-- 1) Human-readable code shown to customer & staff (QR / manual lookup).
ALTER TABLE public.deal_redemptions
  ADD COLUMN IF NOT EXISTS redemption_code TEXT;

-- Backfill any legacy rows (if column was null)
UPDATE public.deal_redemptions
SET redemption_code = 'LEGACY-' || replace(id::text, '-', '')
WHERE redemption_code IS NULL OR redemption_code = '';

ALTER TABLE public.deal_redemptions
  ALTER COLUMN redemption_code SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS deal_redemptions_code_key
  ON public.deal_redemptions (redemption_code);

-- 2) One active redemption per user per deal (prevents duplicate "redeem" abuse).
CREATE UNIQUE INDEX IF NOT EXISTS deal_redemptions_one_per_user_deal
  ON public.deal_redemptions (deal_id, user_id);

-- 3) Increment deals.redemption_count in the database (RLS blocks customers from UPDATE deals).
CREATE OR REPLACE FUNCTION public.bump_deal_redemption_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.deals
  SET redemption_count = COALESCE(redemption_count, 0) + 1,
      updated_at = now()
  WHERE id = NEW.deal_id;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_deal_redemptions_bump_count ON public.deal_redemptions;
CREATE TRIGGER tr_deal_redemptions_bump_count
  AFTER INSERT ON public.deal_redemptions
  FOR EACH ROW
  EXECUTE FUNCTION public.bump_deal_redemption_count();

-- Verification for businesses:
--   SELECT * FROM public.deal_redemptions dr
--   JOIN public.deals d ON d.id = dr.deal_id
--   WHERE dr.redemption_code = 'HAB-XXXXXXXX'
--     AND d.business_id = '<their business id>';
-- Or list recent redemptions for analytics:
--   SELECT dr.redemption_code, dr.redeemed_at, profiles.email
--   FROM deal_redemptions dr
--   JOIN profiles ON profiles.id = dr.user_id
--   WHERE dr.deal_id IN (SELECT id FROM deals WHERE business_id = '<id>');
