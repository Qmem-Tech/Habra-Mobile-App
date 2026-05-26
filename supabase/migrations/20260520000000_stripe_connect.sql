-- Stripe Connect for event-ticket payouts.
-- Business owners onboard to Stripe Express; ticket charges use destination splits.

ALTER TABLE public.businesses
  ADD COLUMN IF NOT EXISTS stripe_account_id       text,
  ADD COLUMN IF NOT EXISTS stripe_connect_status   text
    CHECK (stripe_connect_status IN ('pending','restricted','complete'))
    DEFAULT 'pending',
  ADD COLUMN IF NOT EXISTS stripe_connect_onboarded_at timestamptz;

COMMENT ON COLUMN public.businesses.stripe_account_id IS
  'Stripe Express connected account id (acct_...). NULL = not yet onboarded.';
COMMENT ON COLUMN public.businesses.stripe_connect_status IS
  'pending = link not yet visited; restricted = partially onboarded; complete = payouts enabled.';

-- Index so admin queries (e.g. "show unpaid businesses") are fast.
CREATE INDEX IF NOT EXISTS idx_businesses_stripe_connect_status
  ON public.businesses (stripe_connect_status);

-- RLS: owners can read their own connect status; admins can read/write all.
DROP POLICY IF EXISTS "Owners can read own stripe connect status" ON public.businesses;
CREATE POLICY "Owners can read own stripe connect status"
  ON public.businesses
  FOR SELECT
  USING (owner_id = auth.uid());

DROP POLICY IF EXISTS "Owners can update own stripe connect columns" ON public.businesses;
CREATE POLICY "Owners can update own stripe connect columns"
  ON public.businesses
  FOR UPDATE
  USING (owner_id = auth.uid())
  WITH CHECK (owner_id = auth.uid());
