# Super Admin Billing API Contract (Sandbox)

This contract is for the separate super-admin web app to read Stripe-first
subscription and transaction data from Supabase after applying
`docs/supabase/migrations/add_billing_ledger_and_admin_reporting.sql`.

## Source Of Truth

- Billing source: Stripe webhooks.
- Current subscription snapshot: `profiles` subscription fields.
- Audit timeline: `billing_subscription_events`, `billing_invoice_events`.

## Required Auth

- Caller must be authenticated and `profiles.role = 'admin'`.
- Use Supabase JWT from an admin account.

## Read Surfaces

- `public.admin_subscription_current_v1`
  - One row per profile, with latest subscription status/snapshot fields.
- `public.admin_billing_transactions_v1`
  - Unified timeline view (subscription + invoice ledger rows).
- `public.admin_list_billing_transactions_guarded(...)`
  - Filterable RPC for server-driven pagination in super-admin UI.

## RPC Signature

`admin_list_billing_transactions_guarded(`
- `p_from timestamptz DEFAULT NULL`
- `p_to timestamptz DEFAULT NULL`
- `p_tier text DEFAULT NULL`
- `p_status text DEFAULT NULL`
- `p_user_id uuid DEFAULT NULL`
- `p_limit int DEFAULT 100`
- `p_offset int DEFAULT 0`
`)`

## Response Shape

Each row includes:

- `ledger_id`
- `created_at`
- `user_id`
- `email`
- `full_name`
- `stripe_customer_id`
- `stripe_subscription_id`
- `stripe_invoice_id`
- `ledger_type` (`subscription` | `invoice`)
- `event_type` (Stripe webhook event type)
- `status`
- `tier`
- `amount_cents`
- `currency`

## Example Usage

```ts
const { data, error } = await supabase.rpc(
  "admin_list_billing_transactions_guarded",
  {
    p_from: "2026-01-01T00:00:00Z",
    p_to: "2026-12-31T23:59:59Z",
    p_tier: null,
    p_status: null,
    p_user_id: null,
    p_limit: 50,
    p_offset: 0,
  },
);
```

## Recommended Super-Admin Pages

- Subscriptions list (from `admin_subscription_current_v1`)
- Subscription detail timeline (filter by `p_user_id`)
- Transactions list (from guarded RPC)
- Transaction detail (by `ledger_id` + raw payload from ledger tables)

## Refresh Strategy

- Default polling every 30-60 seconds for list pages.
- Force refresh after any operator action (refund/cancel handled outside this app).
- Optional webhook fan-out can be added later; RPC contract stays unchanged.
