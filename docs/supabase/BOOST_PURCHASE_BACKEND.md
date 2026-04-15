# Boost purchases: server verification (recommended)

The mobile app can charge via RevenueCat **before** calling Supabase, but a determined user can still call `boosts.insert` with a REST client if RLS allows owner inserts. For production:

## 1. RevenueCat webhooks

- In [RevenueCat Dashboard](https://app.revenuecat.com/) → **Project settings → Webhooks**, point to your backend or Supabase Edge Function URL.
- On `INITIAL_PURCHASE`, `NON_RENEWING_PURCHASE`, or `RENEWAL` (per your product type), verify the payload signature and extract `app_user_id`, product id, and transaction id.

## 2. Create the boost row server-side

- Map the store product id to your `boost_plans.id` (same mapping as `billing_product_id` in Postgres).
- Insert into `public.boosts` using the **service role** key (never embed service role in the app).
- Optionally store `revenuecat_transaction_id` / `original_transaction_id` on `boosts` for support and idempotency.
- Keep `REVENUECAT_BOOST_OFFERING_ID` aligned with the offering that contains those mapped products (or leave it empty to search all offerings).

## 3. Lock down client INSERT (optional)

- Run `migrations/restrict_boosts_client_insert_optional.sql` (uncomment the `DROP POLICY`) **after** the Edge Function is deployed.
- Change the app from `BoostsRepository.submitBoostOrder` (direct insert) to `supabase.functions.invoke('finalize-boost', …)` with a short-lived session proof or JWT the function validates.

## 4. Idempotency

- Use the store transaction id as a unique key or check for an existing boost before insert to avoid double rows on webhook retries.

This repo’s mobile flow intentionally completes IAP first, then inserts while you migrate toward webhook-only creation.
