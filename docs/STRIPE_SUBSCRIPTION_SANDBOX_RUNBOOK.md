# RevenueCat Owner Subscription Sandbox Runbook

This runbook validates end-to-end business-owner subscriptions with RevenueCat
as source of truth and verifies super-admin reporting data.

## Prerequisites

- Apply migrations:
  - `docs/supabase/migrations/add_business_subscription_profile_columns.sql`
  - `docs/supabase/migrations/add_billing_ledger_and_admin_reporting.sql`
  - `docs/supabase/migrations/revenuecat_owner_subscription_authority.sql`
- Deploy functions:
  - `revenuecat-subscription-webhook`
  - `stripe-event-webhook`
- Configure RevenueCat webhook:
  - Endpoint -> `revenuecat-subscription-webhook`
  - Authorization header secret -> `REVENUECAT_WEBHOOK_AUTH`
  - Forward subscription lifecycle events for owner offerings.

## App Config (Sandbox)

- `BUSINESS_OWNER_SUBSCRIPTION_MODE=revenuecat`
- `REVENUECAT_ANDROID_API_KEY=<public_sdk_key>`
- `REVENUECAT_IOS_API_KEY=<public_sdk_key>`
- `REVENUECAT_BUSINESS_ENTITLEMENT_ID=business_owner_tools` (or your custom id)
- `REVENUECAT_BUSINESS_OFFERING_ID=<offering_id>` (optional but recommended)

## Test Matrix

### 1) New Subscription Checkout

- Open business-owner subscription page.
- Choose Pro or Premium plan.
- Complete in-app store purchase with sandbox tester.
- In app, tap refresh subscription.
- Verify:
  - `profiles.owner_tools_subscription_active = true`
  - `profiles.owner_tools_subscription_tier` equals selected tier
  - `profiles.owner_tools_subscription_source = revenuecat`
  - subscription rows in `billing_subscription_events`
  - row provider is `revenuecat` in `billing_subscription_events`

### 2) Renewal

- Trigger sandbox renewal from store test account flow.
- Verify RevenueCat webhook ingested and profile remains active.
- Confirm a new lifecycle row appears in subscription ledger.

### 3) Cancellation

- Cancel from store subscriptions settings (App Store / Play Store test account).
- Verify cancellation/expiration handling:
  - profile set to inactive/basic (or canceled status)
  - ledger contains cancellation or expiration lifecycle row.

### 4) Payment Failure

- Trigger billing issue in sandbox where supported by platform tooling.
- Verify profile status transitions to `past_due` (or equivalent inactive state).
- Confirm webhook event appears in subscription ledger.

### 5) Refund Visibility

- Trigger refund in store sandbox if supported for your platform account.
- Verify RevenueCat event reaches webhook and profile/ledger remains consistent.

## Super-Admin Verification

- Sign in as `admin`.
- Query:
  - `admin_subscription_current_v1`
  - `admin_list_billing_transactions_guarded_v2(...)`
- Confirm filters for date range, tier, status, provider, and user work.

## Webhook Replay Checklist

- Replay a recent RevenueCat event from webhook logs/test tooling.
- Confirm idempotency: same `provider + provider_event_id` does not duplicate rows.
- Confirm profile state remains consistent after replay.