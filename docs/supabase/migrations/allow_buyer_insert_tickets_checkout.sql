-- =============================================================================
-- Checkout: allow community members to INSERT rows into `tickets` for their own orders
-- =============================================================================
-- Without this, RLS blocks inserts during event checkout after `orders` is created,
-- and the app shows: "You don't have permission for this action." (PGRST301 / 42501)
--
-- Run in Supabase Dashboard → SQL Editor (safe to re-run).
-- =============================================================================

ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

-- Buyers create ticket line items linked to orders they own (mobile checkout flow).
DROP POLICY IF EXISTS "Users insert tickets for own orders" ON public.tickets;
CREATE POLICY "Users insert tickets for own orders" ON public.tickets
  FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM public.orders o
      WHERE o.id = order_id
        AND o.user_id = auth.uid()
    )
  );

-- Let buyers update their own orders when the RPC fallback runs (mark processing).
DROP POLICY IF EXISTS "Users update own orders" ON public.orders;
CREATE POLICY "Users update own orders" ON public.orders
  FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
