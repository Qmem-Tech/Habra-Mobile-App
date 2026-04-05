# Habra Mobile App — Supabase Backend Design & Implementation Guide

This document provides a **project-level analysis**, **detailed step-by-step guideline**, and **scalable backend design** for handling the Habra backend with **Supabase**. It covers **Community Member**, **Business Owner**, and **Super Admin** flows end-to-end, and supports **three client applications**: mobile app (Flutter), business owner web app, and super admin web app.

| Attribute | Value |
|----------|--------|
| **Document version** | 1.3 |
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

- **Super app** for the Habesha community: events, deals, businesses, jobs, and (for business owners) dashboard, boosts, and listings. **One Supabase backend** serves all clients below.
- **Three user types** with different entry points and UIs:
  - **Community Member (customer/guest)**: Browse events, deals, businesses; apply for jobs; redeem deals; write reviews. Uses **mobile app**.
  - **Business Owner**: Manage business profile, create deals/jobs, view analytics, manage applicants, run boosts. Uses **mobile app** and/or **business owner web app**.
  - **Super Admin**: Platform oversight, user/business moderation, content and boost plan management, reporting. Uses **super admin web app** only.

### Current State (from codebase)

- **Auth**: Firebase Auth + Firestore `users` collection (email/password, Google, guest). Role stored in Firestore: `customer` | `businessOwner` | `admin` | `guest`.
- **Data**: All other features (Home, Events, Explore, Jobs, Dashboard, Boosts) use **mock data** in remote datasources. No production backend for content yet.
- **Architecture**: Clean Architecture (domain/data/presentation), GetIt DI, Cubit state management.

### What We're Planning to Build with Supabase

| Area | Plan |
|------|------|
| **Auth** | Supabase Auth (email/password, Google, anonymous). Profile + role in `public.profiles`. **Email verification** required for business owners (§4.5); optional mirror `profiles.email_verified_at`. |
| **Database** | PostgreSQL: profiles, businesses, deals, events, jobs, reviews, orders, tickets, notifications, boosts, job_applications, etc. |
| **Storage** | Buckets for avatars, business images, deal/event images, review photos. |
| **Security** | RLS on all tables so users only access allowed rows. |
| **Optional** | Edge Functions for payment webhooks, aggregate updates (e.g. business rating), scheduled jobs. Realtime for notifications or live updates. |
| **Admin** | Super admin web app: user/business management, moderation, boost plans, reporting; RLS and tables for `role = 'admin'`. |
| **Web clients** | Same Supabase project (same Auth, DB, Storage) used by business owner web app and super admin web app; clients differ by role and UI. |

### Client applications (who uses this backend)

| Client | Users | Primary use |
|--------|--------|-------------|
| **Mobile app (Flutter)** | Community members, Business owners | Consumer: Home, Events, Explore, Jobs. Business: Dashboard, Deals, Jobs, Reviews, Applicants, Boosts. |
| **Business owner web app** | Business owners | Same data as mobile dashboard: manage businesses, deals, jobs, reviews, applicants, boosts (desktop-friendly). |
| **Super admin web app** | Super admins (`role = admin`) | User management, business approval/verification, content moderation, boost plan CRUD, reports/analytics, audit log. |

### Out of Scope (for this doc)

- Full payment provider integration (Stripe/etc.) — only order/payment data model and placeholders.
- Messaging feature (schema can reserve a `conversations`/`messages` design for later).
- Detailed UI/UX specs for web apps (this doc defines backend only).

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
| 3 | **Business onboarding** (if new) | Create `businesses` row with `owner_id = auth.uid()`, `approval_status = 'pending'`. Optionally link in `profiles` (e.g. `primary_business_id`). Business is **not** visible in Explore/Home/Deals/Jobs until admin sets `approval_status = 'approved'`. |
| 4 | **Business owner home** | Dashboard summary: analytics, recent activity. Read `businesses` (own; any `approval_status`). Owner sees “Pending approval” state until `approval_status = 'approved'`; after approval, business appears in Explore/Home for community. |
| 5 | **Dashboard – Analytics** | Views, clicks, messages (if you store them), rating, review count, active deals/jobs. Stored in `businesses` and/or `dashboard_analytics` (or computed via views/functions). |
| 6 | **Dashboard – Deals** | List/create/edit deals for own business → `deals` (where `business_id` in own businesses). |
| 7 | **Dashboard – Jobs** | List/create/edit job posts → `jobs` (where `business_id` in own businesses). |
| 8 | **Dashboard – Reviews** | List reviews for business; reply → `reviews`; optional `review_replies`. |
| 9 | **Dashboard – Applicants** | List applications for own jobs → `job_applications`; view detail → `applicant_detail` (or same table + user profile). |
| 10 | **Boosts** | List boost plans for a **target** (`boost_plans.target_type`: business listing, deal, or job) → `boost_plans`. Create boost → `boosts` (plan, `target_type`, optional `deal_id` / `job_id`, duration, status). Optional: payments via Edge Function. |
| 11 | **Messages / Profile** | Placeholder today; later: `conversations`, `messages`; profile from `profiles`. |

**Note:** The same backend and RLS apply whether the business owner uses the **mobile app** or the **business owner web app**; both use Supabase Auth and the same `profiles` / `businesses` data.

---

### 2.3 Super Admin (Admin Dashboard) Flow

Super admins sign in to the **super admin web app** only (no admin entry in the mobile app). The backend identifies them by `profiles.role = 'admin'` and grants broad read/write via RLS.

| Step | Screen / Action | Backend (Supabase) |
|------|----------------|--------------------|
| 1 | **Admin sign-in** (web) | Auth: `signInWithPassword` (or SSO if configured). Profile must have `role = admin`; else deny access to admin UI. |
| 2 | **Dashboard overview** | Aggregates: total users, businesses, deals, events, jobs, orders; optional time range. Read from `profiles`, `businesses`, `deals`, `events`, `jobs`, `orders` (admin RLS allows all). |
| 3 | **User management** | List/filter `profiles` (role, email, created_at). View detail; update role, suspend (e.g. `is_suspended` on profile), or delete. |
| 4 | **Business management & approval** | List/filter `businesses` (including `approval_status = 'pending'`). View detail; **approve** (`approval_status = 'approved'`, set `reviewed_at`, `reviewed_by`) or **reject** (`approval_status = 'rejected'`, optional `rejection_reason`, `reviewed_at`, `reviewed_by`). Optionally verify (`is_verified`), feature (`is_featured`), deactivate (`is_active`). Only approved businesses appear in community-facing listing. |
| 5 | **Content moderation** | List `deals`, `events`, `jobs`, `reviews`; hide/remove or flag; update status. |
| 6 | **Boost plans** | CRUD on `boost_plans` including **`target_type`** (`business_listing` \| `deal` \| `job`). List `boosts` across all businesses. |
| 7 | **Reports / analytics** | Read-only aggregates (e.g. sign-ups over time, redemptions, ticket sales). Optional: materialized views or Edge Function for heavy reports. |
| 8 | **Audit log** | List `audit_log` (admin actions and sensitive changes) for compliance and debugging. |

---

### 2.4 Feature–Table Mapping (Quick Reference)

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
| **Admin dashboard** | `profiles`, `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`, `boost_plans`, `boosts`, `audit_log`, `app_settings` |

### 2.5 Feature coverage (implementation traceability)

Every app feature is explicitly covered in this document as follows:

| App feature / screen | Document section | Backend (tables / APIs) |
|----------------------|------------------|-------------------------|
| Splash, onboarding | §2.1 step 1–2, §4.3 | Session, `profiles`, local onboarding flag |
| Choose path | §2.1, §2.2 | Client-only; role set at sign-up |
| Sign up / Sign in / Guest | §2.1 step 4, §4 | Auth + `profiles` insert |
| **Email verification** | §4.5 | Supabase Auth confirm email; `auth.users.email_confirmed_at`; optional `profiles.email_verified_at`; gate business owner flows until verified |
| Home (events, deals, businesses, jobs) | §2.1 step 5, §10 Phase 2 | `events`, `deals`, `businesses`, `jobs` |
| Events list, detail, tickets, buy | §2.1 step 6–7, §10 Phase 2 | `events`, `event_tickets`, `orders`, `tickets` |
| Explore (businesses, deals, reviews, redeem) | §2.1 step 8–10, §10 Phase 2 | `businesses`, `deals`, `reviews`, `deal_redemptions` |
| Jobs list, detail, bookmark, apply | §2.1 step 11, §10 Phase 2 | `jobs`, `job_bookmarks`, `job_applications` |
| Search | §2.1 step 12, §10 Phase 4 | Full-text / filters |
| Notifications | §2.1 step 13, §10 Phase 4 | `notifications` |
| Business sign-in, onboarding | §2.2 step 2–3 | Auth, `profiles`, `businesses` |
| **Business pending / approval (admin)** | §2.2 step 3–4, §2.3 step 4, §5.2, §6 | `businesses.approval_status` (pending/approved/rejected), `reviewed_at`, `reviewed_by`, `rejection_reason`; RLS: only approved businesses visible to community; admin approves/rejects |
| Dashboard (analytics, deals, jobs, reviews, applicants) | §2.2 step 4–9, §10 Phase 3 | `businesses`, `deals`, `jobs`, `reviews`, `job_applications`, `review_replies` |
| Boosts | §2.2 step 10, §10 Phase 3 | `boost_plans`, `boosts` |
| Storage (avatars, business/deal/event images) | §7, §10 Phase 4 | Supabase Storage buckets |
| **Admin dashboard (web)** | §2.3, §10 Phase 5 | All tables (admin RLS), `audit_log`, `app_settings` |
| **Business owner web app** | §2.2 (same as mobile) | Same as Dashboard; same Supabase project and RLS |

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

**Web apps (business owner and super admin):** Use the same Supabase project URL and **anon** key. Authenticate with `supabase.auth.signInWithPassword()` (or OAuth). RLS applies: business owners see only their data; admins see all when `is_admin()` is true. Do not use the **service_role** key in any client app.

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

### 4.5 Email verification flow

**Recommendation:** Require verified email for **business owners** (and optionally for community sign-up). Use Supabase’s built-in email confirmation; gate sensitive actions on verification status.

| Step | Action | Backend (Supabase) |
|------|--------|--------------------|
| 1 | **Sign up (email/password)** | `supabase.auth.signUp(email, password, options)`. Supabase sends confirmation email if “Confirm email” is enabled in Dashboard → Auth → Providers → Email. |
| 2 | **User clicks link in email** | Supabase confirms the user; `auth.users.email_confirmed_at` is set. Redirect to app (e.g. deep link or redirect URL configured in Auth settings). |
| 3 | **Session after confirm** | On next sign-in (or token refresh), `session.user.email_confirmed_at` is non-null. App can read this and optionally mirror to `profiles.email_verified_at` for easy RLS/queries. |
| 4 | **Gate by verification** | **Business owner:** Allow full dashboard and business creation only when `email_confirmed_at` is set (or `profiles.email_verified_at`). Show “Verify your email” banner and resend option until then. **Community:** Optional: restrict deals/orders/reviews until verified, or allow all. |
| 5 | **Resend confirmation** | `supabase.auth.resend(type: OtpType.signup)` (or equivalent) to send a new confirmation email. |

**Configuration (Supabase Dashboard):**

- **Auth → Providers → Email**: Enable “Confirm email” so new sign-ups receive a confirmation link.
- **Auth → URL configuration**: Set “Site URL” and “Redirect URLs” (e.g. `https://yourapp.com/auth/callback`, `habra://auth/callback` for mobile) so the confirmation link lands in your app.
- **Auth → Email templates**: Customize “Confirm signup” template (subject, body, link).

**Profile mirror (optional):** Add `profiles.email_verified_at TIMESTAMPTZ` and keep it in sync via Auth hook or Edge Function on `auth.users` update (when `email_confirmed_at` is set), so RLS or app logic can use `profiles.email_verified_at` without reading `auth.users` directly.

**Summary:** Enable “Confirm email” in Supabase; use `session.user.email_confirmed_at` (or `profiles.email_verified_at`) to show “Verify your email” and block business-owner actions until verified; provide resend confirmation in the app.

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
CREATE TYPE boost_plan_target AS ENUM ('business_listing', 'deal', 'job');
CREATE TYPE business_approval_status AS ENUM ('pending', 'approved', 'rejected');
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
  is_suspended BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMPTZ,
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
  approval_status business_approval_status NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  rejection_reason TEXT,
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

-- Boost plans (reference data). target_type scopes plans to business listing vs deal vs job boosts.
CREATE TABLE public.boost_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  price_usd NUMERIC(10, 2) NOT NULL,
  duration_weeks INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  target_type boost_plan_target NOT NULL DEFAULT 'business_listing',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Boosts (business purchases)
CREATE TABLE public.boosts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  boost_plan_id UUID NOT NULL REFERENCES public.boost_plans(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES public.deals(id) ON DELETE SET NULL,
  job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  target_type boost_plan_target NOT NULL DEFAULT 'business_listing',
  status boost_status NOT NULL DEFAULT 'active',
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Ensure at least one of deal_id or job_id when applicable (optional check)
-- ALTER TABLE public.boosts ADD CONSTRAINT boosts_target_check CHECK (deal_id IS NOT NULL OR job_id IS NOT NULL);

-- Audit log (admin actions and sensitive changes; optional but recommended for super admin)
CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- App-wide settings (super admin only; e.g. maintenance mode, feature flags)
CREATE TABLE public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
```

### 5.3 Schema creation order

Apply schema in this order to respect foreign keys:

1. Enums (§5.1)
2. `profiles` (no FK to `businesses` yet)
3. `businesses` (FK to `profiles`)
4. `ALTER TABLE public.profiles ADD COLUMN primary_business_id UUID REFERENCES public.businesses(id);`
5. `categories`, `business_categories`, `deals`, `events`, `event_tickets`, `jobs`, `reviews`, `review_replies`, `deal_redemptions`, `orders`, `tickets`, `job_applications`, `job_bookmarks`, `notifications`, `boost_plans`, `boosts`
6. `audit_log`, `app_settings`
7. Indexes (§5.5)
8. RLS policies (§6)

### 5.4 Triggers and helpers

- **Updated_at**: `updated_at = now()` on `profiles`, `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`.
- **Profile on sign-up**: Use Supabase Auth hook (Database Webhook) or Edge Function to insert into `profiles` on `auth.users` insert, or do it from the app (with RLS allowing insert when `id = auth.uid()`).
- **Business rating**: On `reviews` insert/update/delete, recompute `businesses.rating` and `businesses.review_count` (trigger or Edge Function).

### 5.5 Indexes (performance)

```sql
CREATE INDEX idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX idx_businesses_city_active ON public.businesses(address_city, is_active);
CREATE INDEX idx_businesses_approval_status ON public.businesses(approval_status) WHERE approval_status = 'pending';
CREATE INDEX idx_deals_business_valid ON public.deals(business_id, valid_until) WHERE status = 'active';
CREATE INDEX idx_events_start ON public.events(start_at) WHERE is_active;
CREATE INDEX idx_jobs_business_posted ON public.jobs(business_id, posted_at DESC);
CREATE INDEX idx_reviews_business ON public.reviews(business_id);
CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX idx_job_applications_job ON public.job_applications(job_id);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at DESC);
CREATE INDEX idx_audit_log_actor ON public.audit_log(actor_id);
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

- **profiles**: Users read any profile (for display names); insert/update/delete only own row (`id = auth.uid()`). **Admin** can read/update all (e.g. change role, suspend).
- **businesses**: Everyone can read active businesses; insert only when `auth.uid() = owner_id` and profile has role businessOwner; update/delete only owner. **Admin** can read/update/delete all (verify, feature, deactivate).
- **deals, events, jobs**: Read for active/visible rows; create/update/delete only for the owning business/organizer. **Admin** can read/update/delete all (moderation).
- **reviews**: Read all; insert with `user_id = auth.uid()`; update/delete own. **Admin** can read/delete all.
- **orders, tickets**: User sees only own orders. **Admin** can read all (reports).
- **notifications**: User sees only own. **Admin** can read all if needed.
- **job_applications**: Applicant sees own; business owner sees for their jobs. **Admin** can read/update all.
- **boosts**: Business owner sees own. **Admin** can read all; **boost_plans** admin-only write.
- **audit_log**: **Admin** read-only (writes via trigger or Edge Function with service role).
- **app_settings**: **Admin** read/write only.

### 6.2 Admin helper (use in policies)

Define once; then use `is_admin()` in admin policies for all tables:

```sql
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql SECURITY DEFINER STABLE;
```

**Important:** Restrict admin creation to a single, secure path (e.g. run a one-off script with `service_role` to set the first admin, or use Supabase Dashboard to set `profiles.role = 'admin'` for a known user). Do not allow self-sign-up as admin from the app.

### 6.3 Example policies (copy and adapt)

CREATE POLICY "Public profiles are viewable by everyone"
  ON public.profiles FOR SELECT USING (true);

CREATE POLICY "Users can insert own profile"
  ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Admin can update any profile"
  ON public.profiles FOR UPDATE USING (public.is_admin());

-- Businesses
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Approved active businesses are viewable by everyone"
  ON public.businesses FOR SELECT USING (
    (approval_status = 'approved' AND is_active = true) OR owner_id = auth.uid()
  );

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
CREATE POLICY "Deals readable when active and business approved (or owner)"
  ON public.deals FOR SELECT USING (
    (status = 'active' AND EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.approval_status = 'approved' AND b.is_active = true))
    OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
  );
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
CREATE POLICY "Jobs readable when active and business approved (or owner)"
  ON public.jobs FOR SELECT USING (
    (is_active = true AND EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.approval_status = 'approved' AND b.is_active = true))
    OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
  );
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

-- boost_plans: read-only for all; admin can manage (CRUD)
ALTER TABLE public.boost_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Boost plans readable by all" ON public.boost_plans FOR SELECT USING (true);
CREATE POLICY "Admin can manage boost plans" ON public.boost_plans FOR ALL USING (public.is_admin());

-- audit_log: admin read-only; inserts via trigger or Edge Function (service_role)
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can read audit log" ON public.audit_log FOR SELECT USING (public.is_admin());

-- app_settings: admin only
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Admin can manage app settings" ON public.app_settings FOR ALL USING (public.is_admin());
```

### 6.4 Admin override policies (super admin full access)

Add the following so that users with `role = 'admin'` can read and, where needed, update/delete rows on all operational tables. These policies are **OR**ed with the existing role-specific policies.

```sql
-- Admin override: read/update/delete on core tables (add after the table-specific policies above)
CREATE POLICY "Admin read all businesses" ON public.businesses FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete businesses" ON public.businesses FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read all deals" ON public.deals FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete deals" ON public.deals FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read all events" ON public.events FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete events" ON public.events FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read all event_tickets" ON public.event_tickets FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete event_tickets" ON public.event_tickets FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read all jobs" ON public.jobs FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete jobs" ON public.jobs FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read/delete reviews" ON public.reviews FOR ALL USING (public.is_admin());
CREATE POLICY "Admin read/delete review_replies" ON public.review_replies FOR ALL USING (public.is_admin());

CREATE POLICY "Admin read all orders" ON public.orders FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin read all tickets" ON public.tickets FOR SELECT USING (public.is_admin());

CREATE POLICY "Admin read all notifications" ON public.notifications FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin read/update job_applications" ON public.job_applications FOR ALL USING (public.is_admin());
CREATE POLICY "Admin read all boosts" ON public.boosts FOR SELECT USING (public.is_admin());
CREATE POLICY "Admin update/delete boosts" ON public.boosts FOR ALL USING (public.is_admin());
```

**audit_log inserts:** Use a database trigger (e.g. on `profiles`, `businesses` updates) or an Edge Function with `service_role` to write to `audit_log`, so that admin actions are recorded without exposing insert to the anon key.

Use helper functions if you prefer (e.g. for business-owner checks):

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
| 1.7 | **Email verification** (§4.5) | “Confirm email” enabled in Supabase Auth; redirect URLs configured; app shows “Verify your email” and resend for business owners until `email_confirmed_at` is set; optionally mirror to `profiles.email_verified_at`; gate business-owner dashboard/creation until verified. |
| 1.8 | (Optional) Firebase user migration | If production users exist: script and run one-time migration; document password reset expectation. |

**Phase 1 done when:** User can sign up/in as customer or business owner, and splash navigates to the correct shell; profile and role persist across restarts; business owners are prompted to verify email and cannot use full dashboard until verified.

---

### Phase 2: Community content (2–3 weeks)

**Objective:** Home, Explore, Events, and Jobs use real data from Supabase; community flows are end-to-end.

| # | Deliverable | Acceptance criteria |
|---|-------------|---------------------|
| 2.1 | Core tables created (§5.2, §5.3 order) | `businesses` (with `approval_status`, `reviewed_at`, `reviewed_by`, `rejection_reason`), `categories`, `business_categories`, `deals`, `events`, `event_tickets`, `jobs`, `reviews`, `review_replies`, `deal_redemptions`, `orders`, `tickets`, `job_applications`, `job_bookmarks` exist with FKs and indexes (§5.5). |
| 2.2 | RLS for Phase 2 tables (§6) | All policies applied; **only approved businesses** visible to community (Explore/Home/Jobs/Deals); owner sees own business in any approval state; customer/guest cannot see other users’ orders or write to others’ data. |
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

**Phase 3 done when:** Business owner sees real dashboard data, can create/edit deals and jobs, reply to reviews, and create and view boosts. The **business owner web app** can be built in parallel or after Phase 3; it uses the same Supabase project and the same RLS (business owners see only their own data).

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

### Phase 5: Admin dashboard and web apps (2–3 weeks)

**Objective:** Super admin web app can manage users, businesses, content, boost plans, and settings. Business owner web app (if not done in Phase 3) uses the same backend.

| # | Deliverable | Acceptance criteria |
|----|-------------|---------------------|
| 5.1 | **Admin schema and RLS** | `audit_log`, `app_settings` created; `profiles.is_suspended` added; `is_admin()` function and admin override policies (§6.2, §6.4) applied. First admin user created via secure one-off (no self-sign-up as admin). |
| 5.2 | **Super admin web app** (backend readiness) | Admin can sign in (role = admin); RLS allows read/update on `profiles`, `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`, `boost_plans`, `boosts`; read on `audit_log`; read/write on `app_settings`. |
| 5.3 | **Admin features** (backend) | User management (list/update profiles, suspend); **business approval**: list/filter businesses by `approval_status` (pending/approved/rejected), approve (set `approval_status = 'approved'`, `reviewed_at`, `reviewed_by`) or reject (set `approval_status = 'rejected'`, optional `rejection_reason`, `reviewed_at`, `reviewed_by`); verify, feature, deactivate; content moderation (deals, events, jobs, reviews); boost plan CRUD; optional audit log writes via trigger or Edge Function. |
| 5.4 | **Business owner web app** (if separate) | Same Supabase project and Auth; business owner signs in and sees same data as mobile dashboard (RLS already allows). No backend changes beyond what Phase 3 provides. |

**Phase 5 done when:** Super admin can use the web app to manage users, **approve or reject pending businesses** (with reviewed_at/reviewed_by/rejection_reason), manage content and boost plans; audit log and app_settings are in place; business owner web app (if built) can sign in and use dashboard data.

---

### Phase summary (checklist)

| Phase | Focus | Key tables/areas |
|-------|--------|-------------------|
| 1 | Auth + profile + routing | `profiles`, Supabase Auth, splash |
| 2 | Community content | `businesses`, `deals`, `events`, `jobs`, `reviews`, `orders`, `tickets`, `job_applications`, `job_bookmarks`, `deal_redemptions` |
| 3 | Business owner (mobile + web) | Dashboard, `review_replies`, `boost_plans`, `boosts` |
| 4 | Storage, notifications, search, optional backend | Storage buckets, `notifications`, search indexes, Edge Functions, Realtime |
| 5 | Admin dashboard + web apps | `audit_log`, `app_settings`, `is_admin()`, admin RLS; super admin web app; business owner web app (same backend as Phase 3) |

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

- Use a **staging** Supabase project (e.g. `habra-app-staging`) with same schema; point dev/debug builds and web apps to it.
- Test RLS with different roles (customer, businessOwner, guest, **admin**) and ensure no cross-tenant data leak; verify admin can read/update only where intended (e.g. no customer self-escalation to admin).

---

## Summary

- **Backend**: Supabase (Auth, Postgres, Storage, optional Edge Functions and Realtime) as the single backend for Habra. It serves **three clients**: mobile app (Flutter), business owner web app, and super admin web app.
- **Flows**: Community members use Home, Events, Explore, Jobs, Search, Notifications; business owners use Dashboard, Deals, Jobs, Reviews, Applicants, Boosts (mobile and/or web); super admins use the admin web app for user/business/content management, boost plans, and settings (§2.1–2.3).
- **Schema**: Normalized, with clear ownership; includes `audit_log` and `app_settings` for admin; `profiles.is_suspended` and optional `profiles.email_verified_at` for moderation and email verification; **businesses** have `approval_status` (pending/approved/rejected), `reviewed_at`, `reviewed_by`, `rejection_reason` for admin approval. Creation order is documented (§5.3); RLS and indexes keep it secure and performant; admin access is gated by `role = 'admin'` and `is_admin()` (§6.2, §6.4).
- **Email verification**: Required for business owners (§4.5); Supabase “Confirm email” and optional `profiles.email_verified_at`; gate dashboard until verified.
- **Business approval**: New businesses start as `pending`; only `approved` businesses appear in community listing; admin approves/rejects in super admin web app (§2.3 step 4, Phase 5).
- **Migration**: Replace Firebase Auth/Firestore in the app stepwise; migrate existing users if needed; keep your Clean Architecture and swap only the data layer.
- **Implementation**: Five phases (§10): Foundation, Community content, Business owner, Polish, **Admin dashboard and web apps**. Every app feature is traceable via the feature coverage table (§2.5).

Following the phases above will give you a **detailed, scalable, and maintainable** backend on Supabase aligned with your current app structure, admin dashboard, and web apps.

---

## Document standards (how to use this doc)

- **Traceability**: Every app feature (including admin dashboard and web apps) maps to a user-flow step (§2.1, §2.2, §2.3), a feature–table mapping (§2.4), and a feature-coverage row (§2.5), and to implementation phases (§10).
- **Implementability**: Schema is executable SQL in order (§5.2, §5.3); RLS is copy-pasteable with policies for all main tables and admin overrides (§6); phases list deliverables and “done when” criteria.
- **Maintainability**: Version and last-updated are at the top; scope and out-of-scope are stated; client applications are listed (§1); recommendations and cost notes are in §11 and “Why Supabase”.
- **Consistency**: Naming is `snake_case` and `_at` for timestamps; roles and enums are defined once and referenced throughout; admin is consistently gated by `is_admin()`.
