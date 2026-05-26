# Stripe Event Payment Test Matrix

## Scope
- Community-member event checkout only.
- Webhook-first finalization.
- Saved payment methods in PaymentSheet.
- Refund propagation from backend to app state.

## Preconditions
- Migration applied: `docs/supabase/migrations/add_event_payment_hardening.sql`
- Deployed functions:
  - `create-event-payment-intent`
  - `stripe-event-webhook`
  - `refund-event-order`
- Stripe env configured in Supabase:
  - `STRIPE_SECRET_KEY`
  - `STRIPE_WEBHOOK_SECRET`
  - `STRIPE_PAYMENT_CURRENCY` (optional, defaults to `usd`)
- Flutter defines configured:
  - `STRIPE_PUBLISHABLE_KEY`
  - `STRIPE_PAYMENT_INTENT_FUNCTION` (if non-default)

## Functional Matrix

| ID | Scenario | Expected Result |
|---|---|---|
| P1 | Happy path card payment | `orders.status` moves `pending` -> `processing` -> `completed`; app navigates to confirmation page |
| P2 | Saved card shown for returning user | PaymentSheet displays saved method(s) and allows quick pay |
| P3 | Payment canceled in sheet | App shows `PaymentFailedPage`; order remains `pending` or `processing` then eventually `failed/cancelled` |
| P4 | Card decline | Webhook marks order `failed`; app surfaces failure message |
| P5 | Double tap pay button | No duplicate PaymentIntent/duplicate tickets; one logical purchase only |
| P6 | App kill after PaymentSheet success | Re-open app and check tickets; completed order is visible once webhook arrives |
| P7 | Webhook delayed (>20s) | App keeps processing until timeout message; eventual completion visible in My Tickets |
| P8 | Refund requested | `refund-event-order` updates refund fields; webhook/DB status reaches `refunded`; UI no longer treats as completed purchase |
| P9 | Retry checkout on failed order | Creates new PaymentIntent path safely without duplicate finalization |
| P10 | Unauthorized order access attempt | `create-event-payment-intent` returns 404/401; no payment session created |

## Error Handling Verification
- Network timeout during `fetchPaymentSheetSession` returns actionable error.
- Missing `clientSecret` response is handled as non-retriable config/backend issue.
- Stripe exception from PaymentSheet maps to cancellation/failure state safely.
- Poll timeout after sheet success shows delayed-confirmation guidance (not false success).
- Refunded status is mapped distinctly from generic failure.

## Observability Checklist
- Log every Stripe event type handled in webhook (`payment_intent.succeeded`, `payment_intent.payment_failed`, `charge.refunded`).
- Log order id and payment intent id for each state transition.
- Alert on repeated webhook failures and signature validation failures.

## Regression Checks
- Existing event browsing, ticket selection, and checkout UI flow remains unchanged.
- Totals shown in checkout match server-computed amount (subtotal + 5% service fee).
- Organizer ticket-sale notifications fire once per unique `order_id` + `event_ticket_id`.
