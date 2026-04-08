-- =============================================================================
-- EVENT PAYMENTS HARDENING (Stripe webhook-first)
-- =============================================================================
-- Adds order status transitions, Stripe reference columns, idempotency constraints,
-- and helper functions for secure server-side finalization.
-- =============================================================================

-- 1) Expand order_status enum for asynchronous processing and explicit failures.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.typname = 'order_status'
      AND e.enumlabel = 'processing'
  ) THEN
    ALTER TYPE public.order_status ADD VALUE 'processing';
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_type t
    JOIN pg_enum e ON e.enumtypid = t.oid
    WHERE t.typname = 'order_status'
      AND e.enumlabel = 'failed'
  ) THEN
    ALTER TYPE public.order_status ADD VALUE 'failed';
  END IF;
END $$;

-- 2) Add Stripe/payment columns to orders.
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS subtotal_amount NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS service_fee_amount NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS payment_provider TEXT,
  ADD COLUMN IF NOT EXISTS stripe_payment_intent_id TEXT,
  ADD COLUMN IF NOT EXISTS stripe_customer_id TEXT,
  ADD COLUMN IF NOT EXISTS refund_status TEXT,
  ADD COLUMN IF NOT EXISTS refunded_amount NUMERIC(10,2),
  ADD COLUMN IF NOT EXISTS payment_failure_reason TEXT,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS payment_started_at TIMESTAMPTZ;

-- Backfill existing rows.
UPDATE public.orders
SET
  subtotal_amount = COALESCE(subtotal_amount, total_amount),
  service_fee_amount = COALESCE(service_fee_amount, GREATEST(total_amount - COALESCE(subtotal_amount, total_amount), 0)),
  payment_provider = COALESCE(payment_provider, CASE WHEN payment_method IS NULL OR payment_method = '' THEN NULL ELSE 'legacy' END)
WHERE subtotal_amount IS NULL
   OR service_fee_amount IS NULL
   OR payment_provider IS NULL;

-- 3) Idempotency and query performance.
CREATE UNIQUE INDEX IF NOT EXISTS idx_orders_stripe_payment_intent_unique
  ON public.orders (stripe_payment_intent_id)
  WHERE stripe_payment_intent_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_user_status_created
  ON public.orders (user_id, status, created_at DESC);

ALTER TABLE public.event_ticket_purchases
  ADD COLUMN IF NOT EXISTS order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE;

-- Ensure a ticket type is only finalized once per order for event_ticket_purchases.
CREATE UNIQUE INDEX IF NOT EXISTS idx_event_ticket_purchases_order_ticket_unique
  ON public.event_ticket_purchases (order_id, event_ticket_id);

-- 4) Helper: set order in processing state (webhook-first flow).
CREATE OR REPLACE FUNCTION public.mark_event_order_processing(
  p_order_id UUID,
  p_payment_provider TEXT,
  p_stripe_payment_intent_id TEXT,
  p_payment_method TEXT,
  p_payment_id TEXT,
  p_stripe_customer_id TEXT DEFAULT NULL
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders;
BEGIN
  UPDATE public.orders
  SET
    status = 'processing',
    payment_provider = COALESCE(p_payment_provider, payment_provider),
    stripe_payment_intent_id = COALESCE(p_stripe_payment_intent_id, stripe_payment_intent_id),
    payment_method = COALESCE(p_payment_method, payment_method),
    payment_id = COALESCE(p_payment_id, payment_id),
    stripe_customer_id = COALESCE(p_stripe_customer_id, stripe_customer_id),
    payment_started_at = now(),
    updated_at = now()
  WHERE id = p_order_id
    AND user_id = auth.uid()
  RETURNING * INTO v_order;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found or unauthorized';
  END IF;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.mark_event_order_processing(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.mark_event_order_processing(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) TO authenticated;

-- 5) Helper: idempotent payment finalization for Stripe webhook handlers.
CREATE OR REPLACE FUNCTION public.finalize_event_order_payment(
  p_order_id UUID,
  p_stripe_payment_intent_id TEXT,
  p_payment_method TEXT,
  p_payment_id TEXT,
  p_status TEXT,
  p_failure_reason TEXT DEFAULT NULL
)
RETURNS public.orders
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_order public.orders;
BEGIN
  SELECT *
  INTO v_order
  FROM public.orders
  WHERE id = p_order_id
  FOR UPDATE;

  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order not found';
  END IF;

  IF v_order.status = 'completed' THEN
    RETURN v_order;
  END IF;

  IF p_status = 'completed' THEN
    UPDATE public.orders
    SET
      status = 'completed',
      payment_provider = 'stripe',
      stripe_payment_intent_id = COALESCE(p_stripe_payment_intent_id, stripe_payment_intent_id),
      payment_method = COALESCE(p_payment_method, payment_method),
      payment_id = COALESCE(p_payment_id, payment_id),
      payment_failure_reason = NULL,
      completed_at = now(),
      updated_at = now()
    WHERE id = p_order_id
    RETURNING * INTO v_order;
  ELSIF p_status = 'failed' THEN
    UPDATE public.orders
    SET
      status = 'failed',
      payment_provider = 'stripe',
      stripe_payment_intent_id = COALESCE(p_stripe_payment_intent_id, stripe_payment_intent_id),
      payment_method = COALESCE(p_payment_method, payment_method),
      payment_id = COALESCE(p_payment_id, payment_id),
      payment_failure_reason = p_failure_reason,
      updated_at = now()
    WHERE id = p_order_id
    RETURNING * INTO v_order;
  ELSIF p_status = 'cancelled' THEN
    UPDATE public.orders
    SET
      status = 'cancelled',
      payment_provider = 'stripe',
      stripe_payment_intent_id = COALESCE(p_stripe_payment_intent_id, stripe_payment_intent_id),
      payment_method = COALESCE(p_payment_method, payment_method),
      payment_id = COALESCE(p_payment_id, payment_id),
      payment_failure_reason = p_failure_reason,
      updated_at = now()
    WHERE id = p_order_id
    RETURNING * INTO v_order;
  ELSE
    RAISE EXCEPTION 'Unsupported payment status: %', p_status;
  END IF;

  RETURN v_order;
END;
$$;

REVOKE ALL ON FUNCTION public.finalize_event_order_payment(UUID, TEXT, TEXT, TEXT, TEXT, TEXT) FROM PUBLIC;
