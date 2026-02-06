# Habra Mobile App — Supabase Backend Design & Implementation Guide

This document provides a **project-level analysis**, **detailed step-by-step guideline**, and **scalable backend design** for handling the Habra app backend with **Supabase**. It covers both **Business Owner** and **Community Member** flows end-to-end, with features, schema, security, and recommendations.

| Attribute | Value |
|----------|--------|
| **Document version** | 1.1 |
| **Last updated** | 2025-02 |
| **Status** | Approved for implementation |
| **Audience** | Development team, product/tech leads |

---

## Table of Contents

1. [Executive Summary & Scope](#1-executive-summary--scope)
2. [User Flows End-to-End](#2-user-flows-end-to-end)
3. [Supabase Project Setup](#3-supabase-project-setup)
4. [Authentication Design](#4-authentication-design)
5. [Database Schema (PostgreSQL)](#5-database-schema-postgresql)
6. [Row Level Security (RLS)](#6-row-level-security-rls)
7. [Storage Design](#7-storage-design)
8. [Edge Functions & Realtime](#8-edge-functions--realtime)
9. [Migration from Firebase](#9-migration-from-firebase)
10. [Implementation Phases](#10-implementation-phases)
11. [Recommendations](#11-recommendations)

---

## 1. Executive Summary & Scope

### What Habra Is

- **Super app** for the Habesha community: events, deals, businesses, jobs, and (for business owners) dashboard, boosts, and listings.
- **Two main user types** with different entry points and UIs:
  - **Community Member (customer/guest)**: Browse events, deals, businesses; apply for jobs; redeem deals; write reviews.
  - **Business Owner**: Manage business profile, create deals/jobs, view analytics, manage applicants, run boosts.

### Current State (from codebase)

- **Auth**: Firebase Auth + Firestore `users` collection (email/password, Google, guest). Role stored in Firestore: `customer` | `businessOwner` | `admin` | `guest`.
- **Data**: All other features (Home, Events, Explore, Jobs, Dashboard, Boosts) use **mock data** in remote datasources. No production backend for content yet.
- **Architecture**: Clean Architecture (domain/data/presentation), GetIt DI, Cubit state management.

### What We're Planning to Build with Supabase

| Area | Plan |
|------|------|
| **Auth** | Supabase Auth (email/password, Google, anonymous). Profile + role in `public.profiles`. |
| **Database** | PostgreSQL: profiles, businesses, deals, events, jobs, reviews, orders, tickets, notifications, boosts, job_applications, etc. |
| **Storage** | Buckets for avatars, business images, deal/event images, review photos. |
| **Security** | RLS on all tables so users only access allowed rows. |
| **Optional** | Edge Functions for payment webhooks, aggregate updates (e.g. business rating), scheduled jobs. Realtime for notifications or live updates. |

### Out of Scope (for this doc)

- Full payment provider integration (Stripe/etc.) — only order/payment data model and placeholders.
- Admin dashboard or admin-only APIs (schema can support `role = 'admin'` later).
- Messaging feature (schema can reserve a `conversations`/`messages` design for later).

---

### Why Supabase (recommendation)

**Recommendation: Use Supabase as the primary backend.** It fits Habra’s needs and addresses Firebase cost and flexibility.

| Factor | Firebase (current) | Supabase |
|--------|--------------------|----------|
| **Cost** | Firestore/Storage/Auth can scale in cost with reads/writes and storage; Blaze plan required for production scale. | Predictable: free tier (500MB DB, 1GB storage), then Pro by seat + usage; often lower total cost for read-heavy apps. |
| **Data model** | NoSQL (denormalization, limited querying). | PostgreSQL: normalized schema, SQL, joins, full-text search, triggers. |
| **Security** | Firestore/Storage rules (expression language). | Row Level Security (SQL); same “who can see what” mindset, often easier to reason about. |
| **Backend logic** | Cloud Functions (Node). | Edge Functions (Deno) + DB triggers; no vendor lock-in for Postgres. |
| **Realtime** | Firestore listeners. | Postgres Realtime (broadcast/presence or table changes). |
| **Migration** | N/A. | One-time migration from Firebase; then single stack. |

**Practical takeaway:** For a super app with businesses, deals, events, jobs, and two distinct user types, a relational model and RLS in Postgres will be easier to maintain and scale. Moving to Supabase is a sound decision from both cost and architecture perspectives.

---

## 2. User Flows End-to-End

### 2.1 Community Member (Customer / Guest) Flow

| Step | Screen / Action | Backend (Supabase) |
|------|----------------|--------------------|
| 1 | **Splash** → Check onboarding + auth | Local: `has_completed_onboarding`. Supabase: `getSession()`; if session, fetch `profiles` by `id`. |
| 2 | **Onboarding** (if first time) | Local: set `has_completed_onboarding`. |
| 3 | **Choose path** → “Community Member” | No backend. |
| 4 | **Sign up** (email/phone) or **Sign in** (email, Google) or **Continue as guest** | Auth: `signUp`, `signInWithPassword`, `signInWithIdToken` (Google), `signInAnonymously`. On first sign-up: insert `profiles` (role = `customer` or `guest`). |
| 5 | **Home** (customer) | **Home**: Events this week, hot deals, popular businesses, latest jobs → read `events`, `deals`, `businesses`, `jobs` (with RLS). Optional: search/notifications. |
| 6 | **Events** tab | List/filter events → `events`. Event detail → `events` + `event_tickets`. User tickets → `orders` + `tickets` (by user id). |
| 7 | **Event: buy tickets** | Create order → `orders` (type=event). Create `tickets`. Optional: Edge Function for payment. |
| 8 | **Explore** tab | Businesses list/filter → `businesses`. Business detail → `businesses` + `deals` + `reviews`. Deals list → `deals`. Deal detail / redeem → `deals`, `deal_redemptions`. |
| 9 | **Write review** | Insert `reviews` (user_id, business_id, rating, comment, images). Trigger/function to update `businesses.rating` and `review_count`. |
| 10 | **Redeem deal** | Insert `deal_redemptions`; optionally decrement/increment redemption count on `deals`. |
| 11 | **Jobs** tab | List/filter jobs → `jobs`. Job detail → `jobs`. Bookmark → `job_bookmarks`. Apply → `job_applications`. |
| 12 | **Search** | Full-text or filters on `events`, `deals`, `businesses`, `jobs`. |
| 13 | **Notifications** | List `notifications` for user; mark read. |

**Guest**: Same flows but with `auth.uid()` from anonymous session; role `guest`. You may restrict (e.g. no reviews, or prompt to convert to full account).

---

### 2.2 Business Owner Flow

| Step | Screen / Action | Backend (Supabase) |
|------|----------------|--------------------|
| 1 | **Choose path** → “Business Owner” | No backend. |
| 2 | **Business sign in** (email/password) | Auth: `signInWithPassword`. Profile must have `role = businessOwner` (or redirect to “wrong path” / upgrade flow). |
| 3 | **Business onboarding** (if new) | Create `businesses` row with `owner_id = auth.uid()`. Optionally link in `profiles` (e.g. `primary_business_id`). |
| 4 | **Business owner home** | Dashboard summary: analytics, recent activity. Read `businesses` (own), `deals`, `jobs`, `reviews` for that business. |
| 5 | **Dashboard – Analytics** | Views, clicks, messages (if you store them), rating, review count, active deals/jobs. Stored in `businesses` and/or `dashboard_analytics` (or computed via views/functions). |
| 6 | **Dashboard – Deals** | List/create/edit deals for own business → `deals` (where `business_id` in own businesses). |
| 7 | **Dashboard – Jobs** | List/create/edit job posts → `jobs` (where `business_id` in own businesses). |
| 8 | **Dashboard – Reviews** | List reviews for business; reply → `reviews`; optional `review_replies`. |
| 9 | **Dashboard – Applicants** | List applications for own jobs → `job_applications`; view detail → `applicant_detail` (or same table + user profile). |
| 10 | **Boosts** | List boost plans → `boost_plans`. Create boost for deal/job → `boosts` (references deal or job, business, plan, duration, status). Optional: payments via Edge Function. |
| 11 | **Messages / Profile** | Placeholder today; later: `conversations`, `messages`; profile from `profiles`. |

---

### 2.3 Feature–Table Mapping (Quick Reference)

| Feature | Main tables |
|---------|-------------|
| Auth & user profile | `auth.users` (Supabase managed), `public.profiles` |
| Businesses | `businesses`, `business_categories` (M:N) |
| Deals | `deals` (FK business_id) |
| Events | `events`, `event_tickets`, `orders`, `tickets` |
| Jobs | `jobs` (FK business_id), `job_applications`, `job_bookmarks` |
| Reviews | `reviews` (user_id, business_id), optional `review_replies` |
| Deal redemption | `deal_redemptions` |
| Orders / tickets | `orders`, `tickets` |
| Notifications | `notifications` |
| Boosts | `boost_plans`, `boosts` (FK business, deal or job) |
| Search | Full-text / filters on `businesses`, `deals`, `events`, `jobs` |

### 2.4 Feature coverage (implementation traceability)

Every app feature is explicitly covered in this document as follows:

| App feature / screen | Document section | Backend (tables / APIs) |
|----------------------|------------------|-------------------------|
| Splash, onboarding | §2.1 step 1–2, §4.3 | Session, `profiles`, local onboarding flag |
| Choose path | §2.1, §2.2 | Client-only; role set at sign-up |
| Sign up / Sign in / Guest | §2.1 step 4, §4 | Auth + `profiles` insert |
| Home (events, deals, businesses, jobs) | §2.1 step 5, §10 Phase 2 | `events`, `deals`, `businesses`, `jobs` |
| Events list, detail, tickets, buy | §2.1 step 6–7, §10 Phase 2 | `events`, `event_tickets`, `orders`, `tickets` |
| Explore (businesses, deals, reviews, redeem) | §2.1 step 8–10, §10 Phase 2 | `businesses`, `deals`, `reviews`, `deal_redemptions` |
| Jobs list, detail, bookmark, apply | §2.1 step 11, §10 Phase 2 | `jobs`, `job_bookmarks`, `job_applications` |
| Search | §2.1 step 12, §10 Phase 4 | Full-text / filters |
| Notifications | §2.1 step 13, §10 Phase 4 | `notifications` |
| Business sign-in, onboarding | §2.2 step 2–3 | Auth, `profiles`, `businesses` |
| Dashboard (analytics, deals, jobs, reviews, applicants) | §2.2 step 4–9, §10 Phase 3 | `businesses`, `deals`, `jobs`, `reviews`, `job_applications`, `review_replies` |
| Boosts | §2.2 step 10, §10 Phase 3 | `boost_plans`, `boosts` |
| Storage (avatars, business/deal/event images) | §7, §10 Phase 4 | Supabase Storage buckets |

---

## 3. Supabase Project Setup

### Step 1: Create project

1. Go to [Supabase Dashboard](https://supabase.com/dashboard).
2. **New project**: name (e.g. `habra-app`), database password, region (closest to users).
3. Wait for provisioning.

### Step 2: Get credentials

- **Project URL**: `https://<project-ref>.supabase.co`
- **anon key**: for client-side (Flutter); respects RLS.
- **service_role key**: server-only (Edge Functions, admin scripts); bypasses RLS. Never ship in the app.

### Step 3: Flutter SDK

Add to `pubspec.yaml`:

```yaml
dependencies:
  supabase_flutter: ^2.8.0  # or latest stable
```

Initialize in `main.dart` (after WidgetsBinding, before runApp):

```dart
await Supabase.initialize(
  url: 'https://<project-ref>.supabase.co',
  anonKey: '<anon-key>',
);
```

Use env or flavor for URL/keys so you can switch staging/production.

---

## 4. Authentication Design

### 4.1 Providers

- **Email/password**: Supabase Auth built-in.
- **Google**: Supabase “Sign in with Google” (configure in Dashboard → Auth → Providers). Flutter: get id_token from Google Sign-In, then `supabase.auth.signInWithIdToken(provider: 'google', idToken: idToken)`.
- **Anonymous (guest)**: `supabase.auth.signInAnonymously()`. Optionally later link to email/Google with `linkIdentity`.

### 4.2 Profile and role

- **Table**: `public.profiles` (see schema below), keyed by `id` = `auth.uid()`.
- **On first sign-up or first anonymous sign-in**: Insert row in `profiles` (trigger or app logic) with `role`: `customer` | `businessOwner` | `admin` | `guest`.
- **Choose path**: For “Business Owner” you either register with role `businessOwner` or have a separate “business sign up” that sets `role = businessOwner`. Do not allow switching role after creation (as per your in-app warning).

### 4.3 Session and splash

- **Splash**: Call `Supabase.instance.client.auth.getSession()`. If session exists, fetch `profiles` where `id = session.user.id` to get `role` and display name.
- **Navigation**: If `role == 'businessOwner'` → Business Owner shell; else → Community (customer/guest) shell. Redirect business sign-in to owner shell; if someone with `customer` hits business sign-in, show error or redirect to community.

### 4.4 Logout

- `supabase.auth.signOut()`. Clear any local caches (e.g. stored user profile).

---

## 5. Database Schema (PostgreSQL)

Below is a **normalized, scalable** schema that matches your app’s domain and the Firebase guide’s intent, adapted for Postgres and RLS.

### 5.1 Enums (optional but clear)

```sql
CREATE TYPE app_role AS ENUM ('customer', 'businessOwner', 'admin', 'guest');
CREATE TYPE order_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE ticket_status AS ENUM ('valid', 'used', 'cancelled');
CREATE TYPE deal_status AS ENUM ('draft', 'active', 'expired', 'inactive');
CREATE TYPE job_application_status AS ENUM ('pending', 'reviewed', 'shortlisted', 'rejected', 'hired');
CREATE TYPE boost_status AS ENUM ('active', 'paused', 'completed', 'cancelled');
```

### 5.2 Core tables

```sql
-- Profiles (extends auth.users). Create first; add primary_business_id after businesses exists (see 5.5).
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  role app_role NOT NULL DEFAULT 'customer',
  phone TEXT,
  locale TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
-- After creating businesses: ALTER TABLE public.profiles ADD COLUMN primary_business_id UUID REFERENCES public.businesses(id);

-- Businesses (owner = business owner user)
CREATE TABLE public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  description TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  address_street TEXT,
  address_city TEXT NOT NULL,
  address_state TEXT,
  address_zip TEXT,
  address_country TEXT DEFAULT 'US',
  latitude NUMERIC,
  longitude NUMERIC,
  logo_url TEXT,
  image_urls TEXT[] DEFAULT '{}',
  rating NUMERIC(3,2) DEFAULT 0,
  review_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  opening_time TIME,
  closing_time TIME,
  price_range TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Categories (e.g. Restaurant, Retail) — normalize or keep as tags
CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT UNIQUE
);

-- M:N business <-> categories
CREATE TABLE public.business_categories (
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  PRIMARY KEY (business_id, category_id)
);

-- Deals
CREATE TABLE public.deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  original_price NUMERIC(10,2),
  discounted_price NUMERIC(10,2),
  discount_percentage INT,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  category TEXT,
  status deal_status DEFAULT 'active',
  redemption_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Events
CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  venue_name TEXT,
  venue_address TEXT,
  venue_lat NUMERIC,
  venue_lng NUMERIC,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Event ticket types (e.g. General, VIP)
CREATE TABLE public.event_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  quantity_available INT NOT NULL,
  quantity_sold INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Jobs
CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  job_type TEXT NOT NULL,
  location TEXT,
  salary_min NUMERIC,
  salary_max NUMERIC,
  salary_display TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  posted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Reviews
CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(business_id, user_id)
);

-- Optional: reply from business
CREATE TABLE public.review_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Deal redemptions
CREATE TABLE public.deal_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id UUID NOT NULL REFERENCES public.deals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Orders (events or other types later)
CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'event',
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  status order_status NOT NULL DEFAULT 'pending',
  total_amount NUMERIC(10,2) NOT NULL,
  payment_method TEXT,
  payment_id TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Tickets (per order)
CREATE TABLE public.tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  event_ticket_id UUID NOT NULL REFERENCES public.event_tickets(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  status ticket_status DEFAULT 'valid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Job applications
CREATE TABLE public.job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cover_message TEXT,
  resume_url TEXT,
  status job_application_status DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(job_id, user_id)
);

-- Job bookmarks (community members)
CREATE TABLE public.job_bookmarks (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, job_id)
);

-- Notifications
CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Boost plans (reference data)
CREATE TABLE public.boost_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  price_cents INT NOT NULL,
  duration_weeks INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Boosts (business purchases)
CREATE TABLE public.boosts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  boost_plan_id UUID NOT NULL REFERENCES public.boost_plans(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES public.deals(id) ON DELETE SET NULL,
  job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  status boost_status NOT NULL DEFAULT 'active',
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure at least one of deal_id or job_id when applicable (optional check)
-- ALTER TABLE public.boosts ADD CONSTRAINT boosts_target_check CHECK (deal_id IS NOT NULL OR job_id IS NOT NULL);
```

### 5.3 Schema creation order

Apply schema in this order to respect foreign keys:

1. Enums (§5.1)
2. `profiles` (no FK to `businesses` yet)
3. `businesses` (FK to `profiles`)
4. `ALTER TABLE public.profiles ADD COLUMN primary_business_id UUID REFERENCES public.businesses(id);`
5. `categories`, `business_categories`, `deals`, `events`, `event_tickets`, `jobs`, `reviews`, `review_replies`, `deal_redemptions`, `orders`, `tickets`, `job_applications`, `job_bookmarks`, `notifications`, `boost_plans`, `boosts`
6. Indexes (§5.4)
7. RLS policies (§6)

### 5.4 Triggers and helpers

- **Updated_at**: `updated_at = now()` on `profiles`, `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`.
- **Profile on sign-up**: Use Supabase Auth hook (Database Webhook) or Edge Function to insert into `profiles` on `auth.users` insert, or do it from the app (with RLS allowing insert when `id = auth.uid()`).
- **Business rating**: On `reviews` insert/update/delete, recompute `businesses.rating` and `businesses.review_count` (trigger or Edge Function).

### 5.5 Indexes (performance)

```sql
CREATE INDEX idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX idx_businesses_city_active ON public.businesses(address_city, is_active);
CREATE INDEX idx_deals_business_valid ON public.deals(business_id, valid_until) WHERE status = 'active';
CREATE INDEX idx_events_start ON public.events(start_at) WHERE is_active;
CREATE INDEX idx_jobs_business_posted ON public.jobs(business_id, posted_at DESC);
CREATE INDEX idx_reviews_business ON public.reviews(business_id);
CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX idx_job_applications_job ON public.job_applications(job_id);
```

Full-text (optional):

```sql
ALTER TABLE public.businesses ADD COLUMN search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('english', name || ' ' || COALESCE(description, ''))) STORED;
CREATE INDEX idx_businesses_search ON public.businesses USING GIN(search_vector);
```

---

## 6. Row Level Security (RLS)

Enable RLS on all public tables; then add policies so the **anon** key (used by the app) only sees allowed rows.

### 6.1 Principles

- **profiles**: Users read any profile (for display names); insert/update/delete only own row (`id = auth.uid()`).
- **businesses**: Everyone can read active businesses; insert only when `auth.uid() = owner_id` and profile has role businessOwner; update/delete only owner.
- **deals, events, jobs**: Read for active/visible rows; create/update/delete only for the owning business/organizer.
- **reviews**: Read all; insert with `user_id = auth.uid()`; update/delete own.
- **orders, tickets**: User sees only own orders.
- **notifications**: User sees only own.
- **job_applications**: Applicant sees own; business owner sees for their jobs.
- **boosts**: Business owner sees own.

### 6.2 Example policies (copy and adapt)

```sql
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

-- Businesses
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Active businesses are viewable by everyone"
  ON public.businesses FOR SELECT USING (is_active = true OR owner_id = auth.uid());

CREATE POLICY "Business owners can insert own business"
  ON public.businesses FOR INSERT
  WITH CHECK (
    auth.uid() = owner_id
    AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'businessOwner')
  );

CREATE POLICY "Business owners can update own business"
  ON public.businesses FOR UPDATE USING (owner_id = auth.uid());

CREATE POLICY "Business owners can delete own business"
  ON public.businesses FOR DELETE USING (owner_id = auth.uid());

-- Deals: read active; write by business owner
ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Deals readable by all when active"
  ON public.deals FOR SELECT USING (status = 'active' OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Deals insert by business owner"
  ON public.deals FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Deals update/delete by business owner"
  ON public.deals FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- Reviews: read all; insert/update/delete own
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Reviews readable by all" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "Users insert own review" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update/delete own review" ON public.reviews FOR ALL USING (auth.uid() = user_id);

-- Orders: user sees only own
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own orders" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own orders" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Notifications: user sees only own
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own notifications" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- Job applications: applicant sees own; business sees for their jobs
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Applicant sees own" ON public.job_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Business sees for own jobs" ON public.job_applications FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.jobs j JOIN public.businesses b ON j.business_id = b.id WHERE j.id = job_id AND b.owner_id = auth.uid())
);
CREATE POLICY "User can insert own application" ON public.job_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Business can update status" ON public.job_applications FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.jobs j JOIN public.businesses b ON j.business_id = b.id WHERE j.id = job_id AND b.owner_id = auth.uid())
);

-- Events: read active; create/update/delete by organizer (or business owner if linked)
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Events readable when active" ON public.events FOR SELECT USING (is_active = true OR organizer_id = auth.uid());
CREATE POLICY "Organizer can manage events" ON public.events FOR ALL USING (organizer_id = auth.uid());

-- Event tickets: read with event; manage with event organizer
ALTER TABLE public.event_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Event tickets readable with event" ON public.event_tickets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND (e.is_active = true OR e.organizer_id = auth.uid()))
);
CREATE POLICY "Organizer can manage event tickets" ON public.event_tickets FOR ALL USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND e.organizer_id = auth.uid())
);

-- Jobs: read active; write by business owner
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Jobs readable when active" ON public.jobs FOR SELECT USING (is_active = true OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Business owner can manage jobs" ON public.jobs FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- Tickets: read/update with order ownership
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users see own tickets" ON public.tickets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.user_id = auth.uid())
);

-- Job bookmarks: user owns own bookmarks
ALTER TABLE public.job_bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own bookmarks" ON public.job_bookmarks FOR ALL USING (auth.uid() = user_id);

-- Boosts: business owner sees/manages own
ALTER TABLE public.boosts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Business owner sees own boosts" ON public.boosts FOR SELECT USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Business owner can insert boosts" ON public.boosts FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Business owner can update own boosts" ON public.boosts FOR UPDATE USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "Business owner can delete own boosts" ON public.boosts FOR DELETE USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- boost_plans: read-only for all
ALTER TABLE public.boost_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Boost plans readable by all" ON public.boost_plans FOR SELECT USING (true);
```

Use helper functions if you prefer:

```sql
CREATE OR REPLACE FUNCTION public.is_business_owner(bid UUID)
RETURNS BOOLEAN AS $$
  SELECT EXISTS (SELECT 1 FROM public.businesses WHERE id = bid AND owner_id = auth.uid());
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

---

## 7. Storage Design

### 7.1 Buckets

| Bucket | Purpose | Who uploads |
|--------|---------|-------------|
| `avatars` | User profile photos | Authenticated user (own only) |
| `businesses` | Logos, gallery | Business owner (own business) |
| `deals` | Deal images | Business owner |
| `events` | Event images | Event organizer |
| `reviews` | Review photos | Authenticated user |
| `resumes` | Job application attachments | Authenticated user (own only) |

### 7.2 Policies

- **avatars**: Path `{user_id}/*`. Read: authenticated. Insert/Update: `auth.uid() = user_id`.
- **businesses**: Path `{business_id}/*`. Read: public or authenticated. Insert/Update: user is owner of `business_id` (check via `businesses.owner_id` or RLS).
- **deals**, **events**: Same idea: only the owner/organizer can upload.
- **reviews**: Path e.g. `{business_id}/{review_id}/*`. User can upload if they created the review.
- **resumes**: Path `{user_id}/*`. Only that user can upload/read.

Use Storage RLS (policies on `storage.objects`) with `bucket_id` and `name` (path) checks, and optionally a small Edge Function or DB check for “is owner of business” when path contains `business_id`.

---

## 8. Edge Functions & Realtime

### 8.1 When to use Edge Functions

- **Payment webhooks**: Stripe (or other) webhook handler to update `orders` and `tickets`.
- **Business rating aggregation**: On review create/update/delete, recompute `businesses.rating` and `review_count` (if you prefer not to use DB triggers).
- **Sending emails**: e.g. “Confirm your email”, “Application received”.
- **Scheduled jobs**: e.g. expire deals, send “event tomorrow” reminders (via cron trigger).

### 8.2 Realtime

- **Notifications**: Subscribe to `notifications` where `user_id = auth.uid()` for live badge updates.
- **Dashboard**: Business owner can subscribe to new `job_applications` or `reviews` for their business.

Enable Realtime on the tables you need in Dashboard → Database → Replication.

---

## 9. Migration from Firebase

### 9.1 Auth

- **New users**: All new sign-ups go through Supabase Auth; no Firebase Auth for new users once you switch.
- **Existing users**: One-time migration script (backend/script):
  - Export Firebase Auth users (or use Firebase Admin to list users).
  - For each user, create in Supabase Auth (Admin API) with same UID if possible, or new UID and store mapping; then insert `profiles` with role from Firestore `users` document.
- **Passwords**: Supabase does not support importing Firebase password hashes; users will need to reset password or use “Sign in with Google” after migration.

### 9.2 Firestore → Postgres

- Export Firestore collections (e.g. `users` → `profiles`, `businesses`, `deals`, etc.) to JSON/CSV.
- Map field names to new schema (e.g. `createdAt` → `created_at`), resolve references (e.g. `ownerId` → `owner_id` UUID).
- Import via SQL or Supabase API (batch inserts). Keep old document IDs in a column if you need to preserve external links, or map to new UUIDs.

### 9.3 App switchover

- **Phased**: Keep Firebase Auth + Firestore for existing users during transition; new users use Supabase. Or do a single cutover after migration weekend.
- **Flutter**: Replace `AuthRemoteDataSource` implementation with one that uses `Supabase.instance.client.auth` and `supabase.from('profiles')`. Keep the same repository/use-case interface so presentation layer stays unchanged. Same for other features: point remote datasources to Supabase (Postgres + Storage) instead of mock/Firestore.

---

## 10. Implementation Phases

Phases are ordered by dependency. Each phase has **deliverables** (what to produce) and **acceptance criteria** (done when).

---

### Phase 1: Foundation (1–2 weeks)

**Objective:** Supabase is the source of auth and profile; splash routes correctly by role; no hardcoded user.

| # | Deliverable | Acceptance criteria |
|---|-------------|---------------------|
| 1.1 | Supabase project created | Project URL and anon key available; env/flavor used for config. |
| 1.2 | `supabase_flutter` added and initialized in app | App starts with `Supabase.initialize()`; no runtime errors. |
| 1.3 | `profiles` table + RLS created (§5.2, §6) | Table exists; RLS allows insert when `id = auth.uid()`, select for all, update/delete own. |
| 1.4 | Profile on sign-up | New user (email or Google or anonymous) gets a row in `profiles` with correct `role` (trigger or app logic). |
| 1.5 | **AuthRemoteDataSource** uses Supabase Auth | Email/password, Google, anonymous sign-in/sign-up work; same `AuthRepository` contract; Firebase auth code removed or behind feature flag. |
| 1.6 | Splash uses session + profile | `getSession()` and fetch `profiles` by `id`; route to Customer shell vs Business Owner shell by `role`; remove hardcoded `User`. |
| 1.7 | (Optional) Firebase user migration | If production users exist: script and run one-time migration; document password reset expectation. |

**Phase 1 done when:** User can sign up/in as customer or business owner, and splash navigates to the correct shell; profile and role persist across restarts.

---

### Phase 2: Community content (2–3 weeks)

**Objective:** Home, Explore, Events, and Jobs use real data from Supabase; community flows are end-to-end.

| # | Deliverable | Acceptance criteria |
|---|-------------|---------------------|
| 2.1 | Core tables created (§5.2, §5.3 order) | `businesses`, `categories`, `business_categories`, `deals`, `events`, `event_tickets`, `jobs`, `reviews`, `review_replies`, `deal_redemptions`, `orders`, `tickets`, `job_applications`, `job_bookmarks` exist with FKs and indexes (§5.5). |
| 2.2 | RLS for Phase 2 tables (§6) | All policies applied; customer/guest cannot see other users’ orders or write to others’ data; business owner can manage only own business data. |
| 2.3 | **Explore**: BusinessesRemoteDataSource → Supabase | List businesses (filter/category), business detail, deals list/detail, reviews list; write review; redeem deal. |
| 2.4 | **Home**: HomeRemoteDataSource → Supabase | “Happening this week”, hot deals, popular businesses, latest jobs from DB (or seeded data). |
| 2.5 | **Events**: EventsRemoteDataSource → Supabase | List events (filters), event detail, event tickets; create order + tickets; user can see own tickets. |
| 2.6 | **Jobs**: JobsRemoteDataSource → Supabase | List jobs (filters), job detail; bookmark; submit application. |

**Phase 2 done when:** Community member can browse and use Explore, Home, Events, and Jobs with real data; reviews and deal redemptions and job applications persist; event orders and tickets are stored and visible.

---

### Phase 3: Business owner (2–3 weeks)

**Objective:** Dashboard and Boosts use real data; business owner can create/edit deals and jobs and manage applicants/reviews.

| # | Deliverable | Acceptance criteria |
|---|-------------|---------------------|
| 3.1 | **Dashboard**: DashboardRemoteDataSource → Supabase | Analytics (or derived from DB), deals list (own business), jobs list (own), reviews list, applicants list; create/edit deal and job. |
| 3.2 | Review replies | `review_replies` table and RLS; business owner can reply to reviews; reply shown in app. |
| 3.3 | `boost_plans` and `boosts` tables + RLS | Tables created and secured; business owner can list plans and create a boost for a deal or job (status, dates). |
| 3.4 | Boosts UI → Supabase | List active/past boosts; create boost flow writes to `boosts`; payment is placeholder if needed. |

**Phase 3 done when:** Business owner sees real dashboard data, can create/edit deals and jobs, reply to reviews, and create and view boosts.

---

### Phase 4: Polish and scale (1–2 weeks)

**Objective:** Storage, notifications, search, and optional server-side logic are production-ready.

| # | Deliverable | Acceptance criteria |
|---|-------------|---------------------|
| 4.1 | **Storage**: Buckets + policies (§7) | Buckets for avatars, businesses, deals, events, reviews, resumes; policies restrict upload/read by ownership. |
| 4.2 | App uploads use Supabase Storage | Business/deal/event/review images and avatar uploads go to Storage; URLs stored in DB where needed. |
| 4.3 | **Notifications** | List notifications for user; mark read; optional Realtime subscription for live updates. |
| 4.4 | **Search** | Full-text or filter-based search on businesses, deals, events, jobs (indexes and queries in place). |
| 4.5 | **Edge Functions** (optional) | Rating aggregation on review change; optional email or payment webhook. |
| 4.6 | **Realtime** (optional) | Notifications or dashboard subscriptions enabled where needed; connection usage documented. |

**Phase 4 done when:** Images flow through Storage; notifications and search work; any agreed Edge/Realtime features are implemented and tested.

---

### Phase summary (checklist)

| Phase | Focus | Key tables/areas |
|-------|--------|-------------------|
| 1 | Auth + profile + routing | `profiles`, Supabase Auth, splash |
| 2 | Community content | `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`, `tickets`, `job_applications`, `job_bookmarks`, `deal_redemptions` |
| 3 | Business owner | Dashboard, `review_replies`, `boost_plans`, `boosts` |
| 4 | Storage, notifications, search, optional backend | Storage buckets, `notifications`, search indexes, Edge Functions, Realtime |

---

## 11. Recommendations

### Scope and priorities

- **Start with Auth + profiles + one vertical**: e.g. Auth + Explore (businesses + deals + reviews). That gives you a full slice and validates RLS and app flow. Then Home, Events, Jobs, then Dashboard and Boosts.
- **Keep Clean Architecture**: Keep domain entities and repository interfaces; only swap data layer (Supabase client instead of Firebase/mock). This keeps the app testable and future-proof.
- **Single source of truth**: Prefer one backend (Supabase). Avoid long-term dual Firebase + Supabase for the same data.

### Scalability and maintainability

- **Normalized schema**: Use FKs and enums; avoid huge JSONB blobs for core data. Use JSONB for flexible payloads (e.g. notification `data`).
- **RLS first**: Design RLS with “who can see what” and “who can write what” from the start; avoid opening tables to anon with no RLS.
- **Indexes**: Add indexes for filters and sorts you use in the app (city, dates, status, user_id).
- **Naming**: Consistent `snake_case` and `_at` for timestamps; same in Flutter models when mapping.

### Security

- Never ship **service_role** in the app. Use it only in Edge Functions or secure backend scripts.
- Use **anon** key in the app; rely on RLS and Auth for access control.
- Validate file types and size in Storage policies and optionally in Edge Functions for uploads.

### Cost and limits

- Supabase free tier: 500MB DB, 1GB file storage, 2GB egress. Monitor usage as you add data and users.
- Realtime: count concurrent connections; disable on tables that don’t need live updates if you hit limits.

### Testing

- Use a **staging** Supabase project (e.g. `habra-app-staging`) with same schema; point dev/debug builds to it.
- Test RLS with different roles (customer, businessOwner, guest) and ensure no cross-tenant data leak.

---

## Summary

- **Backend**: Supabase (Auth, Postgres, Storage, optional Edge Functions and Realtime) as the single backend for Habra.
- **Flows**: Community members use Home, Events, Explore, Jobs, Search, Notifications; business owners use Dashboard, Deals, Jobs, Reviews, Applicants, Boosts. Both are covered by the same schema and RLS.
- **Schema**: Normalized, with clear ownership (profiles, businesses, deals, events, jobs, reviews, orders, tickets, notifications, boosts). Creation order is documented (§5.3); RLS and indexes keep it secure and performant.
- **Migration**: Replace Firebase Auth/Firestore in the app stepwise; migrate existing users if needed; keep your Clean Architecture and swap only the data layer.
- **Implementation**: Four phases with explicit deliverables and acceptance criteria (§10); every app feature is traceable via the feature coverage table (§2.4).

Following the phases above will give you a **detailed, scalable, and maintainable** backend on Supabase aligned with your current app structure and user flows.

---

## Document standards (how to use this doc)

- **Traceability**: Every app feature maps to a user-flow step (§2.1, §2.2), a feature–table mapping (§2.3), and a feature-coverage row (§2.4), and to implementation phases (§10).
- **Implementability**: Schema is executable SQL in order (§5.2, §5.3); RLS is copy-pasteable with policies for all main tables (§6); phases list deliverables and “done when” criteria.
- **Maintainability**: Version and last-updated are at the top; scope and out-of-scope are stated; recommendations and cost notes are in §11 and “Why Supabase”.
- **Consistency**: Naming is `snake_case` and `_at` for timestamps; roles and enums are defined once and referenced throughout.
