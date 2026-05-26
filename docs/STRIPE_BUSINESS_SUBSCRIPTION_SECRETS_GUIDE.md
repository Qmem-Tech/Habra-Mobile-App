# Stripe Business Subscription Secrets Guide (Deprecated)

Business-owner subscriptions are now RevenueCat-first. This guide is retained
only for historical reference and should not be used for new owner-subscription
setups.

Use this guide when you are setting up business-owner subscriptions in Stripe
sandbox and do not yet have Pro/Premium prices created.

This is dashboard/browser-first (no terminal required).

## 1) Create Pro and Premium products + prices in Stripe (Test mode)

1. Open [Stripe Dashboard](https://dashboard.stripe.com/).
2. Enable **Test mode** (top-right toggle).
3. Go to **Product catalog**.
4. Click **Create product** for **Pro**:
   - Name: `Pro`
   - Pricing model: **Recurring**
   - Billing period: **Monthly**
   - Price: `14.99` (or your desired sandbox value)
   - Save product.
5. Open the newly created price and copy its **Price ID** (`price_...`).
6. Repeat for **Premium**:
   - Name: `Premium`
   - Recurring monthly
   - Price: `29.99` (or your desired sandbox value)
   - Save and copy **Price ID** (`price_...`).

Map them as:

- `STRIPE_BUSINESS_PRO_PRICE_ID` = Pro monthly `price_...`
- `STRIPE_BUSINESS_PREMIUM_PRICE_ID` = Premium monthly `price_...`

## 2) Get all required secret values

### A) `STRIPE_SECRET_KEY`

- Stripe Dashboard -> **Developers** -> **API keys**
- Copy **Secret key** in **Test mode** (`sk_test_...`)

### B) `STRIPE_WEBHOOK_SECRET`

- Stripe Dashboard -> **Developers** -> **Webhooks**
- Open webhook endpoint that points to:
  - `https://<YOUR_SUPABASE_PROJECT_REF>.functions.supabase.co/stripe-event-webhook`
- Click **Reveal** on **Signing secret**
- Copy value (`whsec_...`)

### C) `STRIPE_BUSINESS_PRO_PRICE_ID`

- Stripe Dashboard -> **Product catalog** -> **Pro** product -> monthly price
- Copy **Price ID** (`price_...`)

### D) `STRIPE_BUSINESS_PREMIUM_PRICE_ID`

- Stripe Dashboard -> **Product catalog** -> **Premium** product -> monthly price
- Copy **Price ID** (`price_...`)

### E) `SUPABASE_SERVICE_ROLE_KEY`

- Supabase Dashboard -> **Project Settings** -> **API**
- Copy **service_role** key

### F) `SUPABASE_URL`

- Supabase Dashboard -> **Project Settings** -> **API**
- Copy **Project URL** (`https://<project>.supabase.co`)

### G) `SUPABASE_ANON_KEY`

- Supabase Dashboard -> **Project Settings** -> **API**
- Copy **anon/public** key

## 3) Add/update secrets in Supabase (browser)

1. Open Supabase Dashboard -> your project.
2. Go to **Project Settings** -> **Edge Functions** -> **Secrets**.
3. Add or update:
   - `STRIPE_SECRET_KEY`
   - `STRIPE_WEBHOOK_SECRET`
   - `STRIPE_BUSINESS_PRO_PRICE_ID`
   - `STRIPE_BUSINESS_PREMIUM_PRICE_ID`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SUPABASE_URL` (if missing)
   - `SUPABASE_ANON_KEY` (if missing)
4. Save changes.

## 4) Configure webhook events in Stripe endpoint

For your `stripe-event-webhook` endpoint, enable:

- `checkout.session.completed`
- `checkout.session.expired`
- `customer.subscription.created`
- `customer.subscription.updated`
- `customer.subscription.deleted`
- `invoice.payment_succeeded`
- `invoice.payment_failed`
- `payment_intent.succeeded`
- `payment_intent.payment_failed`
- `charge.refunded`

## 5) Common mistakes to avoid

- **Using live keys in test mode** (or test keys in live mode).
- Swapping Pro and Premium price IDs.
- Copying **Product ID** (`prod_...`) instead of **Price ID** (`price_...`).
- Forgetting to update `STRIPE_WEBHOOK_SECRET` after recreating webhook endpoint.
- Leaving `BUSINESS_OWNER_SUBSCRIPTION_MODE` as non-`profile` in sandbox app config.

## 6) Quick verification

After setup:

1. Open business-owner subscription page in app.
2. Choose Pro/Premium.
3. Complete Stripe Checkout.
4. Tap **Refresh subscription status**.
5. Confirm profile fields and billing ledger update as described in:
   - `docs/STRIPE_SUBSCRIPTION_SANDBOX_RUNBOOK.md`
