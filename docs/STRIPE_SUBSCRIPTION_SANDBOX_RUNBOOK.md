# Stripe Subscription Sandbox Runbook

This runbook validates end-to-end business-owner subscriptions with Stripe as
source of truth and verifies super-admin reporting data.

## Prerequisites

- Apply migrations:
  - `docs/supabase/migrations/add_business_subscription_profile_columns.sql`
  - `docs/supabase/migrations/add_billing_ledger_and_admin_reporting.sql`
- Deploy functions:
  - `create-business-subscription-checkout`
  - `create-business-subscription-portal`
  - `stripe-event-webhook`
- Configure Stripe sandbox:
  - Price IDs in function secrets (`STRIPE_BUSINESS_PRO_PRICE_ID`, `STRIPE_BUSINESS_PREMIUM_PRICE_ID`)
  - Webhook endpoint -> `stripe-event-webhook`
  - Events enabled:
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

## App Config (Sandbox)

- `BUSINESS_OWNER_SUBSCRIPTION_MODE=profile`
- `STRIPE_BUSINESS_SUBSCRIPTION_CHECKOUT_FUNCTION=create-business-subscription-checkout`
- `STRIPE_BUSINESS_SUBSCRIPTION_PORTAL_FUNCTION=create-business-subscription-portal`
- Valid hosted URLs:
  - `STRIPE_BUSINESS_SUBSCRIPTION_SUCCESS_URL`
  - `STRIPE_BUSINESS_SUBSCRIPTION_CANCEL_URL`

## Test Matrix

### 1) New Subscription Checkout

- Open business-owner subscription page.
- Choose Pro or Premium plan.
- Complete Stripe Checkout with sandbox card.
- In app, tap refresh subscription.
- Verify:
  - `profiles.owner_tools_subscription_active = true`
  - `profiles.owner_tools_subscription_tier` equals selected tier
  - subscription rows in `billing_subscription_events`
  - invoice rows in `billing_invoice_events`

### 2) Renewal

- Trigger renewal in Stripe test clock/sandbox controls.
- Verify webhook event ingested and latest profile status remains active.
- Confirm new invoice event appears in ledger.

### 3) Cancellation

- From app active screen, open Manage plan -> Stripe portal.
- Cancel subscription in portal.
- Verify `customer.subscription.deleted` handling:
  - profile set to inactive/basic (or canceled status)
  - ledger contains cancel lifecycle row.

### 4) Payment Failure

- Force failed renewal/payment in sandbox.
- Verify profile status transitions to `past_due` and active becomes false.
- Confirm invoice failure event is visible in ledger.

### 5) Refund Visibility

- Trigger refund from Stripe dashboard for a related payment.
- Verify `charge.refunded` row appears in invoice ledger and status reflects refund.

## Super-Admin Verification

- Sign in as `admin`.
- Query:
  - `admin_subscription_current_v1`
  - `admin_list_billing_transactions_guarded(...)`
- Confirm list filters for date range, tier, status, and business owner (`user_id`) work.

## Webhook Replay Checklist

- Replay a recent event from Stripe dashboard.
- Confirm idempotency: same `stripe_event_id` does not duplicate rows.
- Confirm profile state remains consistent after replay.
