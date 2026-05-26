# Habra — Supabase Backend Build Guide (Step-by-Step)

This guide walks you through **building the Habra backend on Supabase** from scratch: project setup, database schema, RLS, Auth, Storage, optional Edge Functions, and **testing**. It is backend-focused; client integration is covered in [SUPABASE_CLIENT_INTEGRATION_GUIDE.md](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md).

**Prerequisites:** [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) — use it for schema details, RLS principles, and user flows.

| Attribute | Value |
|-----------|--------|
| **Document version** | 1.1 |
| **Last updated** | 2025-02 |
| **Companion docs** | SUPABASE_BACKEND_DESIGN.md (design), SUPABASE_CLIENT_INTEGRATION_GUIDE.md (clients) |

---

## Online-only vs local: do I need to run Supabase on my machine?

**No. You can use Supabase 100% online (cloud only).**

| Approach | What you need | When to use it |
|----------|----------------|----------------|
| **Online only (recommended to start)** | A Supabase account and a browser. No local files, no Docker, no CLI. | You create a project in the [Supabase Dashboard](https://supabase.com/dashboard), run SQL in the **SQL Editor**, and configure Auth/Storage in the Dashboard. Your Flutter and web apps connect to the **cloud project URL** and **anon key**. This is enough to build and run the full backend. |
| **Local (optional)** | Supabase CLI, Docker, and a `supabase/` folder with migrations. | Useful if you want to test schema changes offline, run migrations in CI, or develop without touching the cloud project. Not required for using Supabase. |

**Summary:** You do **not** need any Supabase files or local run. Create a project online, paste or run SQL in the Dashboard, and point your apps at the project URL and anon key. Use local only if you choose to.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Create Supabase project (cloud)](#2-create-supabase-project-cloud)
3. [Local development (optional)](#3-local-development-optional)
4. [Database: migrations and schema](#4-database-migrations-and-schema)
5. [Row Level Security (RLS)](#5-row-level-security-rls)
6. [Authentication configuration](#6-authentication-configuration)
7. [Storage: buckets and policies](#7-storage-buckets-and-policies)
8. [Edge Functions (optional)](#8-edge-functions-optional)
9. [Testing the backend](#9-testing-the-backend)
10. [Deployment and checklist](#10-deployment-and-checklist)

---

## 1. Prerequisites

**For online-only (minimum):**

- **Supabase account**: [supabase.com](https://supabase.com) — sign up if needed.
- **Browser**: to use the Dashboard (SQL Editor, Auth, Storage, etc.).

**Optional (only if you use local Supabase or CLI):**

- **Node.js** (v18+): for Supabase CLI and optional Edge Functions.
- **Supabase CLI**: `npm install -g supabase` — for local `supabase start` and migration files.
- **Docker**: required for `supabase start` (local run only).
- **Git**: for versioning migration files (if you use the CLI).

---

## 2. Create Supabase project (cloud)

Everything in this section uses only the **Supabase Dashboard** in the browser. No local install needed.

### Step 2.1: New project in Dashboard

1. Go to [Supabase Dashboard](https://supabase.com/dashboard) → **New project**.
2. **Organization**: Create or select one.
3. **Name**: e.g. `habra-app` (production) or `habra-app-staging` (staging).
4. **Database password**: Generate a strong password and store it securely (e.g. in a secrets manager). You need it for direct DB access and migrations.
5. **Region**: Choose the region closest to your users.
6. Click **Create new project** and wait for provisioning (1–2 minutes).

### Step 2.2: Get API keys and URL

1. In the project, go to **Project Settings** (gear) → **API**.
2. Note:
   - **Project URL**: `https://<project-ref>.supabase.co`
   - **anon public**: use this in **all client apps** (mobile and web). It respects RLS.
   - **service_role**: use only in **backend/scripts/Edge Functions**. Never expose it in clients.

### Step 2.3: (Optional) Link CLI to project

Only if you use the Supabase CLI (e.g. for migration files or `supabase db push`):

```bash
supabase login
supabase link --project-ref <project-ref>
```

`<project-ref>` is in the project URL (e.g. `abcdefghijklmnop`). You can skip this and apply SQL directly in the Dashboard (see §4).

---

## 3. Local development (optional)

**You can skip this section entirely and work only with the cloud project.** Running Supabase locally is optional and useful mainly for offline migration testing or CI.

### Step 3.1: Initialize Supabase in repo (if not already)

From your repo root (e.g. Habra-Mobile-App or a separate `habra-backend` repo):

```bash
supabase init
```

This creates `supabase/` with `config.toml` and `migrations/` folder.

### Step 3.2: Start local Supabase

Requires Docker.

```bash
supabase start
```

Note the output: **API URL**, **anon key**, **service_role key**, and **DB URL**. Use these for local client and DB access.

### Step 3.3: Run migrations locally

After adding migration files (see §4):

```bash
supabase db reset
```

This applies all migrations in `supabase/migrations/` and resets the local DB. Use it to verify migration order and RLS.

### Step 3.4: Stop local

```bash
supabase stop
```

---

## 4. Database: migrations and schema

You can apply the schema in either of two ways:

- **Online only:** Open your project in the Dashboard → **SQL Editor**, and run each SQL block below (or from the design doc) **in order**. No local files or CLI needed.
- **With CLI (optional):** Create migration files under `supabase/migrations/` with the same SQL, then run `supabase db push` (or `supabase db reset` locally). Migration filenames must be ordered (e.g. numeric prefix) so they run in the correct order.

The full schema is defined in [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) §5; here we give an **ordered, step-by-step** plan. Run the blocks in the order shown.

### Step 4.1: Migration / script order

Apply SQL in this order (whether in Dashboard or as migration files):

1. Enums  
2. `profiles`  
3. `businesses` + add `primary_business_id` to `profiles`  
4. Remaining tables (categories, deals, events, jobs, reviews, etc.)  
5. Indexes  
6. RLS policies (after all tables exist)

### Step 4.2: SQL to run (migration files or Dashboard)

Either create each block as a file under `supabase/migrations/` (if using CLI) or paste and run in Dashboard → **SQL Editor** (online-only). Run in the order listed.

**Migration 1 — Enums**

File: `supabase/migrations/20250207000001_create_enums.sql`

```sql
CREATE TYPE app_role AS ENUM ('customer', 'businessOwner', 'admin', 'guest');
CREATE TYPE order_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE ticket_status AS ENUM ('valid', 'used', 'cancelled');
CREATE TYPE deal_status AS ENUM ('draft', 'active', 'expired', 'inactive');
CREATE TYPE job_application_status AS ENUM ('pending', 'reviewed', 'shortlisted', 'rejected', 'hired');
CREATE TYPE boost_status AS ENUM ('active', 'paused', 'completed', 'cancelled');
CREATE TYPE business_approval_status AS ENUM ('pending', 'approved', 'rejected');
```

**Migration 2 — Profiles**

File: `supabase/migrations/20250207000002_create_profiles.sql`

```sql
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

CREATE INDEX idx_profiles_role ON public.profiles(role);
```

**Migration 3 — Businesses**

File: `supabase/migrations/20250207000003_create_businesses.sql`

```sql
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

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS primary_business_id UUID REFERENCES public.businesses(id);

CREATE INDEX idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX idx_businesses_city_active ON public.businesses(address_city, is_active);
CREATE INDEX idx_businesses_approval_status ON public.businesses(approval_status) WHERE approval_status = 'pending';
```

**Migration 4 — Categories, business_categories, deals, events, event_tickets, jobs**

Add one or more migration files for the remaining tables from the design doc (§5.2): `categories`, `business_categories`, `deals`, `events`, `event_tickets`, `jobs`, `reviews`, `review_replies`, `deal_redemptions`, `orders`, `tickets`, `job_applications`, `job_bookmarks`, `notifications`, `boost_plans`, `boosts`, `audit_log`, `app_settings`. Keep the **creation order** from the design doc to satisfy foreign keys.

**Migration N — Indexes and full-text (optional)**

Add indexes from design doc §5.5 (e.g. `idx_deals_business_valid`, `idx_events_start`, `idx_jobs_business_posted`, etc.). Optional: full-text search on `businesses` (search_vector, GIN index).

### Step 4.3: Apply the schema

**Online only (no CLI):** In Supabase Dashboard → **SQL Editor**, paste and run each SQL block from §4.2 (and the design doc for the rest of the tables) **in order**. Check for errors after each run.

**With CLI — local:** Run `supabase db reset` to apply all migrations in `supabase/migrations/` to your local Supabase.

**With CLI — cloud:** Run `supabase db push` to apply migrations to your linked cloud project.

You do **not** need the CLI; the Dashboard SQL Editor is enough to build the full backend.

### Step 4.4: Seed data (optional)

Create `supabase/seed.sql` (or a migration that runs only in dev) to insert:

- A few `categories`.
- Optional: one admin user (set `profiles.role = 'admin'` for a test user after sign-up).
- Optional: `boost_plans` rows.

Run seed locally: `supabase db reset` runs `seed.sql` if configured in `config.toml` under `[db] seed = "seed.sql"`.

---

## 5. Row Level Security (RLS)

Every table that clients access must have RLS enabled and policies that match the design doc (§6). Below is a concise checklist; exact policy SQL is in [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) §6.

### Step 5.1: Helper for admin

Create a migration that defines:

```sql
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$;
```

### Step 5.2: Enable RLS and add policies per table

For each table in the design:

1. `ALTER TABLE public.<table> ENABLE ROW LEVEL SECURITY;`
2. Add **SELECT** (read) policies: who can see which rows.
3. Add **INSERT** / **UPDATE** / **DELETE** where needed.

**Order of operations:** Create policies in a migration **after** the table exists. You can put all RLS in one migration (e.g. `20250207000020_rls_policies.sql`) that runs after all table migrations, or add policies in the same migration as the table.

**Key rules (from design doc):**

- **profiles**: Everyone can SELECT; insert/update/delete only own row (`id = auth.uid()`). Admin can update any (for suspend, role).
- **businesses**: Public SELECT only for `approval_status = 'approved' AND is_active = true`; owner always sees own; admin sees all. Insert only by businessOwner; update/delete only owner (or admin).
- **deals, jobs**: Public SELECT only when business is approved and active; owner sees own business’s deals/jobs. Insert/update/delete by business owner (or admin).
- **reviews**: Everyone SELECT; insert with `user_id = auth.uid()`; update/delete own (or admin).
- **orders, tickets**: User sees only own orders/tickets; admin read-only.
- **notifications**: User sees only own.
- **job_applications**: Applicant sees own; business owner sees for their jobs; admin sees all; business/admin can update status.
- **boosts**: Business owner sees own; admin sees all.
- **boost_plans**: Everyone SELECT; only admin INSERT/UPDATE/DELETE.
- **audit_log**: Admin SELECT only; inserts via trigger or Edge Function (service_role).
- **app_settings**: Admin only (SELECT + write).

Copy the full policy SQL from the design doc §6.2, §6.4 into your RLS migration(s).

### Step 5.3: Verify RLS

After applying migrations, test as different roles (see §9).

---

## 6. Authentication configuration

### Step 6.1: Auth providers (Dashboard)

1. **Authentication** → **Providers**.
2. **Email**: Enable; turn on **“Confirm email”** if you want email verification (recommended for business owners). Set **“Secure email change”** as needed.
3. **Google**: Enable; add Client ID and Secret from Google Cloud Console (OAuth 2.0 credentials). Use the same setup as in the design doc for Google Sign-In.
4. **Anonymous**: Enable if you support guest sign-in.

### Step 6.2: URL configuration

1. **Authentication** → **URL configuration**.
2. **Site URL**: Your production app URL (e.g. `https://habra.app` or, for testing, `http://localhost:3000`).
3. **Redirect URLs**: Add every URL where users can land after auth (e.g. email confirm, OAuth callback):
   - Web: `https://yourapp.com/auth/callback`, `http://localhost:5173/auth/callback`
   - Mobile: `habra://auth/callback`, `com.habra.habra://auth/callback`

### Step 6.3: Email templates

Under **Authentication** → **Email templates**, customize:

- **Confirm signup**: Subject and body; `{{ .ConfirmationURL }}` is the link. Ensure the link uses a redirect URL that your app handles.

### Step 6.4: Profile on sign-up

When a user signs up (email or Google or anonymous), they must get a row in `public.profiles`. Two options:

**Option A — Database trigger (recommended)**

Use a trigger on `auth.users` that inserts into `public.profiles`:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE((NEW.raw_user_meta_data->>'role')::app_role, 'customer')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

Note: Role cannot be set from `raw_user_meta_data` unless the client sends it at sign-up. For business owner sign-up, the app can send `role: 'businessOwner'` in `options.data` and read it in the trigger from `NEW.raw_user_meta_data->>'role'`, or create the profile with default `customer` and have a separate “claim business owner” flow that updates `profiles.role` (e.g. after admin approval or a specific sign-up path).

**Option B — Edge Function**

On `auth.users` insert, call an Edge Function that inserts into `profiles` using the service_role client. Prefer the trigger for simplicity.

---

## 7. Storage: buckets and policies

### Step 7.1: Create buckets

In **Storage** in the Dashboard (or via SQL), create:

| Bucket | Public? | Purpose |
|--------|--------|--------|
| `avatars` | No | User profile photos |
| `businesses` | Yes (or No + signed URLs) | Business logos and gallery |
| `deals` | Yes | Deal images |
| `events` | Yes | Event images |
| `reviews` | No | Review photos |
| `resumes` | No | Job application attachments |

### Step 7.2: Storage policies

Define policies so that:

- **avatars**: Read for authenticated; insert/update only for `auth.uid()` matching the path (e.g. `{user_id}/*`).
- **businesses**: Read for all (or authenticated); insert/update only for the business owner (you may need to check `businesses.owner_id` in a policy or via an Edge Function).
- **deals**, **events**: Similar to businesses (only owner/organizer can upload).
- **reviews**: User can upload to their own review path.
- **resumes**: User can read/upload only their own path (`{user_id}/*`).

Example for avatars (path pattern `{user_id}/*`):

```sql
-- Storage policy: avatars
-- Allow read for authenticated
CREATE POLICY "Avatar read"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'avatars');

-- Allow insert/update for own path
CREATE POLICY "Avatar insert/update"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'avatars' AND (storage.foldername(name))[1] = auth.uid()::text);
```

Adjust `storage.foldername(name)` and path structure to match your naming (e.g. `user_id/filename`).

---

## 8. Edge Functions (optional)

Use Edge Functions for:

- Syncing `profiles.email_verified_at` when `auth.users.email_confirmed_at` is set (if using Auth hook).
- Business rating aggregation when a review is created/updated/deleted.
- Sending emails (e.g. “Application received”).
- Payment webhooks (Stripe).

### Step 8.1: Create a function

```bash
supabase functions new sync-profile-email-verified
```

Implement in `supabase/functions/sync-profile-email-verified/index.ts`: use the Supabase client with **service_role** to update `profiles.email_verified_at` when the Auth hook payload indicates email confirmation.

### Step 8.2: Auth hook (example)

In Dashboard → **Authentication** → **Hooks**, you can add a “Send Email” or “Customize User” hook that calls your Edge Function. Alternatively, use a Database webhook on `auth.users` (e.g. on update) to call the function.

### Step 8.3: Deploy functions

```bash
supabase functions deploy sync-profile-email-verified
```

---

## 9. Testing the backend

You can test entirely against your **cloud project**; local Supabase is optional.

### Step 9.1: Use your cloud project (or local)

- **Online only:** Use the **Project URL** and **anon key** from Dashboard → Project Settings → API. Your Flutter and web apps connect to this URL; run your tests (manual or automated) against this project. Use a **staging** project for tests so you don’t touch production.
- **Optional — local:** Run `supabase start` and apply migrations with `supabase db reset`; use the local API URL and anon key from the `supabase start` output for client tests.

### Step 9.2: Test Auth and profile

1. **Sign up** (email/password) via API or a test client. Check:
   - Row in `auth.users`.
   - Row in `public.profiles` with same `id` (trigger or function).
2. **Sign in** and use the returned access token for subsequent requests.
3. **Confirm email** (if enabled): use the link from the email or Supabase Inbucket (local) and confirm that `email_confirmed_at` is set and, if implemented, `profiles.email_verified_at` is updated.

### Step 9.3: Test RLS

Use the **anon** key and different users (tokens) to ensure:

- **Customer** can read approved businesses, deals, jobs; can create own reviews and orders; cannot read other users’ orders or update other users’ profiles.
- **Business owner** can read/update only their own businesses, deals, jobs; can see own boosts and job_applications for their jobs.
- **Admin** can read/update profiles, businesses (approval_status, etc.), and other tables as per design.

**Ways to test:**

1. **Dashboard → SQL Editor**: Run queries as a specific user by setting `request.jwt.claim.sub` (not always available in Dashboard). Prefer option 2 or 3.
2. **REST/Postman**: Use the anon key and `Authorization: Bearer <access_token>`. Sign in as different test users, then call PostgREST endpoints (e.g. `GET /rest/v1/profiles`, `GET /rest/v1/businesses`). Verify visible rows match expectations.
3. **Integration tests**: Write a small script (Node/TS or Dart) that uses `@supabase/supabase-js` or `supabase_flutter` to sign in as customer, business owner, and admin and assert on list/detail responses.

### Step 9.4: Test business approval flow

1. Create a business owner user and a business row with `approval_status = 'pending'`.
2. As a **customer**, list businesses: the pending business should **not** appear.
3. As **admin**, set `approval_status = 'approved'` (via Dashboard or API with admin token).
4. As **customer**, list businesses again: the business **should** appear (and deals/jobs for that business in their lists).

### Step 9.5: Seed and smoke tests

- Add seed data for categories, one approved business, a few deals/jobs.
- Run a smoke test: open the app (or Postman), sign in as customer, load Home and Explore; sign in as business owner, load Dashboard; sign in as admin, load admin panel (if built). Verify no RLS errors and data appears as designed.

---

## 10. Deployment and checklist

### Step 10.1: Staging vs production

- Use a **staging** Supabase project for QA and integration tests.
- Use **production** only for live traffic. Apply the same migrations to both (staging first, then production).

### Step 10.2: Backend deployment checklist

- [ ] Supabase project(s) created in Dashboard (staging + production). No local install required.
- [ ] Schema and RLS applied in order (via Dashboard SQL Editor or CLI migrations); no failed runs.
- [ ] RLS enabled on all relevant tables; policies match design doc.
- [ ] Auth: Email (with confirm), Google, Anonymous configured; redirect URLs and email templates set.
- [ ] Profile-on-sign-up: trigger or Edge Function creates `profiles` row.
- [ ] Storage buckets and policies created.
- [ ] First admin user created securely (e.g. set `profiles.role = 'admin'` for a known user via Dashboard or one-off script; never allow self-sign-up as admin).
- [ ] Email verification and business approval flows tested (§9).
- [ ] (Optional) Edge Functions deployed and tested.
- [ ] API URL and **anon** key documented for client teams; **service_role** stored in secrets only.

### Step 10.3: Ongoing

- **Migrations**: Add new changes as new migration files; test locally with `supabase db reset`, then push to staging, then production.
- **Backups**: Rely on Supabase managed backups; configure point-in-time recovery if required.
- **Monitoring**: Use Dashboard for DB and Auth metrics; set up alerts for errors and usage.

---

## Summary

1. Create Supabase project(s) and get URL + anon key.
2. Use migrations for schema and RLS (order matters; reference design doc).
3. Configure Auth (providers, confirm email, redirect URLs) and profile-on-sign-up.
4. Add Storage buckets and policies.
5. Test Auth, RLS, and business approval locally or on staging.
6. Deploy Edge Functions if needed; then connect clients using the [Client Integration Guide](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md).
