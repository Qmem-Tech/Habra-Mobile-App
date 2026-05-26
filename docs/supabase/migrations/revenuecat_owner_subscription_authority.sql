-- RevenueCat-first authority and provider-agnostic billing ledger.
-- Safe to run multiple times.

-- 1) Provider-agnostic source precedence (latest update wins; supports RevenueCat canonical flow).
CREATE OR REPLACE FUNCTION public.enforce_owner_tools_subscription_source_priority()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;

  IF COALESCE(NEW.owner_tools_subscription_updated_at, timezone('utc', now()))
     < COALESCE(OLD.owner_tools_subscription_updated_at, '-infinity'::timestamptz) THEN
    NEW.owner_tools_subscription_active := OLD.owner_tools_subscription_active;
    NEW.owner_tools_subscription_tier := OLD.owner_tools_subscription_tier;
    NEW.owner_tools_subscription_status := OLD.owner_tools_subscription_status;
    NEW.owner_tools_subscription_source := OLD.owner_tools_subscription_source;
    NEW.owner_tools_subscription_origin_id := OLD.owner_tools_subscription_origin_id;
    NEW.owner_tools_subscription_updated_at := OLD.owner_tools_subscription_updated_at;
  END IF;

  RETURN NEW;
END;
$$;

-- 2) Provider-agnostic ledger columns.
ALTER TABLE public.billing_subscription_events
  ADD COLUMN IF NOT EXISTS provider text DEFAULT 'stripe',
  ADD COLUMN IF NOT EXISTS provider_event_id text,
  ADD COLUMN IF NOT EXISTS provider_customer_id text,
  ADD COLUMN IF NOT EXISTS provider_subscription_id text;

ALTER TABLE public.billing_invoice_events
  ADD COLUMN IF NOT EXISTS provider text DEFAULT 'stripe',
  ADD COLUMN IF NOT EXISTS provider_event_id text,
  ADD COLUMN IF NOT EXISTS provider_customer_id text,
  ADD COLUMN IF NOT EXISTS provider_subscription_id text,
  ADD COLUMN IF NOT EXISTS provider_invoice_id text;

UPDATE public.billing_subscription_events
SET
  provider = COALESCE(provider, source, 'stripe'),
  provider_event_id = COALESCE(provider_event_id, stripe_event_id),
  provider_customer_id = COALESCE(provider_customer_id, stripe_customer_id),
  provider_subscription_id = COALESCE(provider_subscription_id, stripe_subscription_id)
WHERE provider_event_id IS NULL
   OR provider_customer_id IS NULL
   OR provider_subscription_id IS NULL;

UPDATE public.billing_invoice_events
SET
  provider = COALESCE(provider, 'stripe'),
  provider_event_id = COALESCE(provider_event_id, stripe_event_id),
  provider_customer_id = COALESCE(provider_customer_id, stripe_customer_id),
  provider_subscription_id = COALESCE(provider_subscription_id, stripe_subscription_id),
  provider_invoice_id = COALESCE(provider_invoice_id, stripe_invoice_id)
WHERE provider_event_id IS NULL
   OR provider_customer_id IS NULL
   OR provider_subscription_id IS NULL
   OR provider_invoice_id IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_subscription_events_provider_event_unique
  ON public.billing_subscription_events (provider, provider_event_id)
  WHERE provider_event_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_billing_invoice_events_provider_event_unique
  ON public.billing_invoice_events (provider, provider_event_id)
  WHERE provider_event_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_billing_subscription_events_provider_subscription
  ON public.billing_subscription_events (provider, provider_subscription_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_billing_invoice_events_provider_subscription
  ON public.billing_invoice_events (provider, provider_subscription_id, created_at DESC);

-- 3) New provider-aware reporting surface (v2) while keeping v1 compatibility.
CREATE OR REPLACE VIEW public.admin_billing_transactions_v2 AS
SELECT
  e.id::text AS ledger_id,
  e.created_at,
  e.user_id,
  p.email,
  p.full_name,
  e.provider,
  e.provider_customer_id,
  e.provider_subscription_id,
  null::text AS provider_invoice_id,
  'subscription'::text AS ledger_type,
  e.event_type,
  e.status,
  e.tier,
  null::bigint AS amount_cents,
  null::text AS currency,
  e.payload_json
FROM public.billing_subscription_events e
LEFT JOIN public.profiles p ON p.id = e.user_id
UNION ALL
SELECT
  i.id::text AS ledger_id,
  i.created_at,
  i.user_id,
  p.email,
  p.full_name,
  i.provider,
  i.provider_customer_id,
  i.provider_subscription_id,
  i.provider_invoice_id,
  'invoice'::text AS ledger_type,
  i.event_type,
  COALESCE(i.status, 'unknown') AS status,
  COALESCE(p.owner_tools_subscription_tier, 'basic') AS tier,
  i.amount_cents,
  i.currency,
  i.payload_json
FROM public.billing_invoice_events i
LEFT JOIN public.profiles p ON p.id = i.user_id;

ALTER VIEW public.admin_billing_transactions_v2 SET (security_invoker = true);

CREATE OR REPLACE FUNCTION public.admin_list_billing_transactions_v2(
  p_from timestamptz DEFAULT NULL,
  p_to timestamptz DEFAULT NULL,
  p_tier text DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_user_id uuid DEFAULT NULL,
  p_provider text DEFAULT NULL,
  p_limit int DEFAULT 100,
  p_offset int DEFAULT 0
)
RETURNS TABLE (
  ledger_id text,
  created_at timestamptz,
  user_id uuid,
  email text,
  full_name text,
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  provider_invoice_id text,
  ledger_type text,
  event_type text,
  status text,
  tier text,
  amount_cents bigint,
  currency text,
  payload_json jsonb
)
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    t.ledger_id,
    t.created_at,
    t.user_id,
    t.email,
    t.full_name,
    t.provider,
    t.provider_customer_id,
    t.provider_subscription_id,
    t.provider_invoice_id,
    t.ledger_type,
    t.event_type,
    t.status,
    t.tier,
    t.amount_cents,
    t.currency,
    t.payload_json
  FROM public.admin_billing_transactions_v2 t
  WHERE
    (p_from IS NULL OR t.created_at >= p_from)
    AND (p_to IS NULL OR t.created_at <= p_to)
    AND (p_tier IS NULL OR lower(t.tier) = lower(p_tier))
    AND (p_status IS NULL OR lower(t.status) = lower(p_status))
    AND (p_user_id IS NULL OR t.user_id = p_user_id)
    AND (p_provider IS NULL OR lower(t.provider) = lower(p_provider))
  ORDER BY t.created_at DESC
  LIMIT GREATEST(COALESCE(p_limit, 100), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$$;

REVOKE ALL ON FUNCTION public.admin_list_billing_transactions_v2(
  timestamptz,
  timestamptz,
  text,
  text,
  uuid,
  text,
  int,
  int
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_list_billing_transactions_v2(
  timestamptz,
  timestamptz,
  text,
  text,
  uuid,
  text,
  int,
  int
) TO authenticated;

CREATE OR REPLACE FUNCTION public.admin_list_billing_transactions_guarded_v2(
  p_from timestamptz DEFAULT NULL,
  p_to timestamptz DEFAULT NULL,
  p_tier text DEFAULT NULL,
  p_status text DEFAULT NULL,
  p_user_id uuid DEFAULT NULL,
  p_provider text DEFAULT NULL,
  p_limit int DEFAULT 100,
  p_offset int DEFAULT 0
)
RETURNS TABLE (
  ledger_id text,
  created_at timestamptz,
  user_id uuid,
  email text,
  full_name text,
  provider text,
  provider_customer_id text,
  provider_subscription_id text,
  provider_invoice_id text,
  ledger_type text,
  event_type text,
  status text,
  tier text,
  amount_cents bigint,
  currency text,
  payload_json jsonb
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Forbidden';
  END IF;

  RETURN QUERY
  SELECT * FROM public.admin_list_billing_transactions_v2(
    p_from, p_to, p_tier, p_status, p_user_id, p_provider, p_limit, p_offset
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_list_billing_transactions_guarded_v2(
  timestamptz,
  timestamptz,
  text,
  text,
  uuid,
  text,
  int,
  int
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.admin_list_billing_transactions_guarded_v2(
  timestamptz,
  timestamptz,
  text,
  text,
  uuid,
  text,
  int,
  int
) TO authenticated;
