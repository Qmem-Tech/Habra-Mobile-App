# Habra Business Update Two

**Date:** March 2025  
**Scope:** Mobile app feature additions + Web app migration guide

This document summarizes all changes made in **Habra Business Update Two** and provides a migration checklist for the **Business Owner Web App** and **Admin Web App** so they stay in sync with the mobile app and Supabase backend.

---

## Table of Contents

1. [Summary of Changes](#1-summary-of-changes)
2. [Backend Schema — Expected / Created Columns](#2-backend-schema--expected--created-columns)
3. [Web App Migration Checklist](#3-web-app-migration-checklist)
4. [API & Table Reference](#4-api--table-reference)
5. [Storage Buckets](#5-storage-buckets)

---

## 1. Summary of Changes

### 1.1 Event Creation (Business Owner)

| Item | Description |
|------|-------------|
| **Feature** | Business owners can create events with ticket types |
| **Tables** | `events`, `event_tickets` (existing) |
| **Storage** | `events` bucket for event images |
| **Mobile** | Create Event page, quick action on Business Owner Home |

**Web app migration:** Add a **Create Event** page with form (title, description, venue, address, date/time, category, image upload, ticket types). Use same Supabase `events` and `event_tickets` tables.

---

### 1.2 Boost / Advertisement

| Item | Description |
|------|-------------|
| **Fix** | Boost plans now load from `boost_plans` (`price_usd` in dollars, `duration_weeks`) |
| **Fix** | Submit boost order persists to `boosts` table |
| **Schema** | `boosts.auto_renew` (BOOLEAN, default false) |

**Web app migration:** Ensure boost plans are fetched from `boost_plans` (not hardcoded). Use **`price_usd`** (dollar amount, e.g. `9.99`) and `duration_weeks`. Submit boost orders to `boosts` table. Support `auto_renew` if your UI exposes it.

---

### 1.3 Payment (RevenueCat)

| Item | Description |
|------|-------------|
| **Mobile** | RevenueCat SDK for in-app purchases (boosts, tickets) |
| **Web** | N/A — RevenueCat is mobile-only. Web app typically uses Stripe or similar. |

**Web app migration:** No direct migration. If the web app handles boost payments, use Stripe (or your existing web payment provider). The `boosts` table does not store payment provider; it only stores boost metadata.

---

### 1.4 Review Photo Upload

| Item | Description |
|------|-------------|
| **Feature** | Users can upload photos when writing reviews |
| **Storage** | `reviews` bucket |
| **Schema** | `reviews.image_urls` (TEXT[] array) |

**Web app migration:** If the web app has a community-facing review form, add image upload to `reviews` bucket and pass `image_urls` array when inserting into `reviews`. If the web app is business-owner-only, this may not apply (owners reply to reviews, not write them).

---

### 1.5 Deal Image Upload

| Item | Description |
|------|-------------|
| **Feature** | Business owners can upload an image when creating deals |
| **Storage** | `deals` bucket |
| **Schema** | `deals.image_url` (TEXT) |

**Web app migration:** Add image upload to Create Deal form. Upload to `deals` bucket, get public URL, pass `image_url` when inserting into `deals`. Ensure `valid_from` and `valid_until` are set (NOT NULL in schema); default to now and now+7 days if user leaves empty.

---

### 1.6 Ticket Reselling

| Item | Description |
|------|-------------|
| **Feature** | Users can list tickets for resale |
| **Table** | `ticket_listings` (new) |
| **Mobile** | "Sell" button on My Tickets; ListTicketSheet for asking price |

**Web app migration:** If the web app has a community member flow (My Tickets), add "Sell" action that inserts into `ticket_listings`. If web app is business-owner-only, this does not apply. Admin web app may want to view/manage `ticket_listings` for moderation.

---

## 2. Backend Schema — Expected / Created Columns

### 2.1 New Table: ticket_listings

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| ticket_id | UUID | FK → tickets |
| seller_id | UUID | FK → profiles |
| asking_price | NUMERIC(10,2) | NOT NULL |
| status | TEXT | 'available', 'sold', 'cancelled' |
| created_at | TIMESTAMPTZ | |
| updated_at | TIMESTAMPTZ | |

### 2.2 New Column: boosts.auto_renew

| Column | Type | Notes |
|--------|------|-------|
| auto_renew | BOOLEAN | Default false |

### 2.3 Storage Buckets

| Bucket | Purpose |
|--------|---------|
| `events` | Event cover images |
| `reviews` | Review photos |
| `deals` | Deal images |

---

## 3. Web App Migration Checklist

### Business Owner Web App

| # | Task | Priority |
|---|------|----------|
| 1 | **Create Event** page: form + image upload + ticket types → `events`, `event_tickets` | High |
| 2 | **Create Deal** page: add image upload → `deals` bucket, pass `image_url` | High |
| 3 | **Create Deal** page: ensure `valid_from`, `valid_until` are set (default if empty) | High |
| 4 | **Boost plans**: fetch from `boost_plans`; use `price_usd`, `duration_weeks` | High |
| 5 | **Boost submit**: persist to `boosts` table; support `auto_renew` if UI has it | High |
| 6 | Add "Create Event" to navigation / dashboard | Medium |

### Admin Web App

| # | Task | Priority |
|---|------|----------|
| 1 | (Optional) View/manage `ticket_listings` for moderation | Low |
| 2 | (Optional) Manage `boost_plans` — ensure `duration_weeks` and `price_usd` are used | Medium |

### Community Web App (if exists)

| # | Task | Priority |
|---|------|----------|
| 1 | **Write Review**: add photo upload → `reviews` bucket, pass `image_urls` | High |
| 2 | **My Tickets**: add "Sell" action → insert into `ticket_listings` | Medium |

---

## 4. API & Table Reference

### boost_plans

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | PK |
| title | TEXT | |
| description | TEXT | |
| price_usd | NUMERIC(10,2) | Dollar amount (e.g. 9.99), not cents |
| duration_weeks | INT | Use this, not `duration_days` |
| is_active | BOOLEAN | |

### events (reference for Create Event)

| Column | Type | Notes |
|--------|------|-------|
| organizer_id | UUID | auth.uid() |
| business_id | UUID | Optional |
| title | TEXT | |
| description | TEXT | |
| venue_name | TEXT | |
| venue_address | TEXT | |
| venue_lat | NUMERIC | Optional |
| venue_lng | NUMERIC | Optional |
| start_at | TIMESTAMPTZ | |
| end_at | TIMESTAMPTZ | |
| image_url | TEXT | From storage upload |
| category | TEXT | e.g. 'community', 'concerts' |
| is_active | BOOLEAN | Default true |

### event_tickets (reference)

| Column | Type | Notes |
|--------|------|-------|
| event_id | UUID | FK → events |
| name | TEXT | Ticket type name |
| price | NUMERIC(10,2) | |
| quantity_available | INT | |
| quantity_sold | INT | Default 0 |

---

## 5. Storage Buckets

| Bucket | Path pattern | Use |
|--------|--------------|-----|
| events | `{userId}/{timestamp}.{ext}` | Event cover image |
| reviews | `{userId}/{businessId}/{timestamp}_{index}.{ext}` | Review photos (multiple) |
| deals | `{userId}/{timestamp}.{ext}` | Deal image |

---

## Related Documents

- [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) — Mobile app changes
- [WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md](./WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md) — Business owner web app guide
- [WEB_APP_ADMIN_IMPLEMENTATION.md](./WEB_APP_ADMIN_IMPLEMENTATION.md) — Admin web app guide
- [REVENUECAT_SETUP.md](./REVENUECAT_SETUP.md) — RevenueCat (mobile only)
