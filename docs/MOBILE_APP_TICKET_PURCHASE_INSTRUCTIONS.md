# Mobile App — Event Ticket Purchase Implementation

This document describes how to implement event ticket purchases in the Habra mobile app so that:

1. **Business owners** see sales in the web app (EventDetail: sold/left counts, progress bar)
2. **Notifications** are created when a customer buys a ticket
3. **Realtime** updates the web app when purchases occur

---

## 1. Database Table: `event_ticket_purchases`

Ensure the table exists (from `add_notifications_and_ticket_purchases.sql`):


| Column            | Type        | Description                                                  |
| ----------------- | ----------- | ------------------------------------------------------------ |
| `id`              | uuid        | PK, auto-generated                                           |
| `event_id`        | uuid        | FK to `events` — **required**                                |
| `event_ticket_id` | uuid        | FK to `event_tickets` — **recommended** for per-ticket stats |
| `buyer_id`        | uuid        | FK to `auth.users` — current signed-in user                  |
| `quantity`        | integer     | Number of tickets purchased                                  |
| `total_cents`     | integer     | Optional: total paid in cents                                |
| `status`          | text        | `'completed'` (default), `'pending'`, `'refunded'`           |
| `created_at`      | timestamptz | Auto-set                                                     |


---

## 2. Insert a Purchase (Supabase)

For Stripe-backed event checkout, purchases must be inserted by the backend webhook handler, not directly by the mobile app.

When a customer completes a ticket purchase:

1. App creates order + tickets.
2. App starts Stripe PaymentSheet.
3. `stripe-event-webhook` receives `payment_intent.succeeded`.
4. Webhook upserts `event_ticket_purchases` rows idempotently (`order_id`, `event_ticket_id`).

```kotlin
// Kotlin / Android example
supabase.from("event_ticket_purchases").insert(
    mapOf(
        "event_id" to eventId,
        "event_ticket_id" to ticketId,
        "buyer_id" to supabase.auth.currentUser?.id,
        "quantity" to quantity,
        "total_cents" to totalCents,
        "status" to "completed"
    )
)
```

```swift
// Swift / iOS example
try await supabase
    .from("event_ticket_purchases")
    .insert([
        "event_id": eventId,
        "event_ticket_id": ticketId,
        "buyer_id": supabase.auth.currentUser?.id,
        "quantity": quantity,
        "total_cents": totalCents,
        "status": "completed"
    ])
    .execute()
```

---

## 3. Important: `event_ticket_id`

- **Include `event_ticket_id`** when the customer selects a specific ticket type (e.g. "General", "VIP").
- The web app uses this to show **per-ticket** sold/left counts.
- If you omit it, the purchase still counts toward **total event sales**, but not per-ticket breakdown.

**Flow:** Customer selects ticket type → you have `event_ticket.id` → pass it as `event_ticket_id`.

---

## 4. RLS (Row Level Security)

The migration creates:

- **SELECT:** Event organizers can read purchases for their events.
- **INSERT:** Authenticated users can insert (customers buying tickets).

Ensure the mobile app user is **signed in** when inserting. Anonymous purchases would need a different RLS policy.

---

## 5. What Happens After Insert

1. **DB trigger** `notify_on_ticket_purchase` runs.
2. A row is inserted into `notifications` for the event organizer.
3. The web app shows a notification: "A customer purchased 2 ticket(s) for [Event Name]".
4. If Realtime is enabled for `event_ticket_purchases`, the web app refreshes sold/left counts.

---

## 6. Suggested Mobile Flow

1. User browses events → selects event → sees ticket types from `event_tickets`.
2. User selects ticket type and quantity.
3. (Optional) Payment flow.
4. Insert into `event_ticket_purchases` with:
  - `event_id`
  - `event_ticket_id` (from selected ticket)
  - `buyer_id` (current user)
  - `quantity`
  - `status: 'completed'`
5. Show success and optionally navigate to "My Tickets" or event details.

---

## 7. Fetching Ticket Types (for purchase UI)

```sql
-- Get tickets for an event
SELECT id, name, price, quantity_available
FROM event_tickets
WHERE event_id = :eventId
ORDER BY created_at;
```

The mobile app can use this to show ticket options and pass `id` as `event_ticket_id` when inserting a purchase.

---

## 8. Checking Availability (optional)

Before inserting, you can verify capacity:

```sql
-- Sold so far for a ticket
SELECT COALESCE(SUM(quantity), 0) as sold
FROM event_ticket_purchases
WHERE event_ticket_id = :ticketId
  AND status = 'completed';

-- Left = quantity_available - sold
```

Implement this in your mobile app if you want to block over-selling.

---

## 9. Summary Checklist


| Step | Action                                                                     |
| ---- | -------------------------------------------------------------------------- |
| 1    | Run `add_notifications_and_ticket_purchases.sql` in Supabase (if not done) |
| 2    | On purchase completion, insert into `event_ticket_purchases`               |
| 3    | Include `event_ticket_id` when the user selects a specific ticket type     |
| 4    | Use `buyer_id` = current authenticated user                                |
| 5    | Set `status` = `'completed'`                                               |
| 6    | Ensure user is signed in (RLS requires auth for INSERT)                    |


---

## 10. Mobile App Implementation (Current)

The mobile app no longer finalizes orders or inserts `event_ticket_purchases` directly.

- **Where:** `lib/features/events/presentation/bloc/tickets_cubit.dart` and `lib/features/events/data/datasources/events_supabase_datasource.dart` 
- **When:** after PaymentSheet success, app marks the order as `processing` and polls for webhook-confirmed status
- **Source of truth:** `stripe-event-webhook` Edge Function + DB function `finalize_event_order_payment` 
- **Migration:** run `docs/supabase/migrations/add_event_payment_hardening.sql`

---

*Document version: 1.1 | Project: Habra | Mar 2025*