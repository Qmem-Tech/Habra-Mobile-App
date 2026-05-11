
## Pre-test checklist

### Supabase Edge Function secrets
Project → Settings → Edge Functions → Secrets:
- [x] `STRIPE_SECRET_KEY` = `sk_test_…` (or `sk_live_…`) — **must be the secret key, not pk_**
- [x] `STRIPE_WEBHOOK_SECRET` = `whsec_…`
- [x] `SUPABASE_SERVICE_ROLE_KEY` is present (usually auto)

### Edge Functions deployed
`supabase functions list` should show all four:
- [x] `create-event-payment-intent`
- [x] `sync-event-order-payment`
- [x] `stripe-event-webhook`
- [x] `refund-event-order`

### Database
- [x] `finalize_event_order_payment` SQL function exists (called by both sync fn and webhook)
- [x] `mark_event_order_processing` SQL function exists (the code falls back to direct UPDATE if missing, but the RPC is cleaner)
- [x] `orders` table has: `stripe_payment_intent_id`, `stripe_customer_id`, `payment_provider`, `payment_method`, `payment_id`, `payment_started_at`

### Stripe Dashboard
- [x] Webhook endpoint registered → `https://tygsxsulgeiyisydxlse.supabase.co/functions/v1/stripe-event-webhook`
- [x] Subscribed events: `payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`
- [x] Webhook signing secret in Stripe matches `STRIPE_WEBHOOK_SECRET` in Supabase
- [x] Test mode keys match between Stripe and Supabase (don't mix test/live)

### App build (`dart_defines.json`)
- [x] `STRIPE_PUBLISHABLE_KEY` = `pk_test_…` (matches the same Stripe account as `STRIPE_SECRET_KEY`)
- [x] `STRIPE_PAYMENT_INTENT_FUNCTION` = `create-event-payment-intent`
- [x] `STRIPE_SYNC_ORDER_PAYMENT_FUNCTION` = `sync-event-order-payment`
- [x] Android: `MainActivity` extends `FlutterFragmentActivity` and uses `Theme.MaterialComponents` (required by flutter_stripe; otherwise sheet won't present)

### Stripe test cards
- Success: `4242 4242 4242 4242` — any future expiry, any CVC, any ZIP
- 3DS required (auth passes): `4000 0027 6000 3184`
- 3DS auth fails: `4000 0084 0000 1629`
- Generic decline: `4000 0000 0000 0002`
- Insufficient funds: `4000 0000 0000 9995`

### During a real test, watch in this order
1. **App console** — phase indicator should walk: *Creating order → Securing payment → Confirming order → Success*
2. **Supabase logs** → `sync-event-order-payment` should return `200 { ok: true, orderStatus: "completed" }` within 1-2 s
3. **If sync didn't finalize** → Stripe Dashboard → Webhooks → check delivery attempts and response codes
4. **`orders` table** → `status` should go `pending` → `processing` → `completed`
5. **My Tickets** → confirmed ticket appears with `is_verified: true`

### If a ticket gets stuck "pending" after the test
That means **both paths failed silently**. Diagnose in this order:
1. Is `sync-event-order-payment` deployed? → `supabase functions list`
2. Is `STRIPE_SECRET_KEY` set in Edge Function secrets? → it's a 500 from the sync fn otherwise (visible in logs)
3. Is the webhook reaching Supabase? → Stripe Dashboard → Webhook delivery attempts, look for non-200 responses
4. Is `finalize_event_order_payment` SQL function present? → both paths call it, and if missing they fail silently

Once those four are green, payment confirmation should land in well under 1 second instead of the current 12-second wait.
