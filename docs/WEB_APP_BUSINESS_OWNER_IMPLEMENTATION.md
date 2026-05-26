# Habra — Business Owner Web App Implementation Guide

This document is a **detailed implementation guide** for building the **Habra Business Owner Web App**. It aligns **theme and UI** with the Habra Flutter mobile app and describes **end-to-end Supabase backend integration** (Auth, Database, Storage, RLS).

| Attribute | Value |
|-----------|--------|
| **Audience** | Developers building the business owner web app |
| **Prerequisites** | [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md), [SUPABASE_CLIENT_INTEGRATION_GUIDE.md](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md), backend schema deployed |
| **Related** | [WEB_APP_ADMIN_IMPLEMENTATION.md](./WEB_APP_ADMIN_IMPLEMENTATION.md) (admin app), [SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md) |

---

## Table of Contents

1. [Overview & Scope](#1-overview--scope)
2. [Design System (Match Mobile App)](#2-design-system-match-mobile-app)
3. [Tech Stack & Project Setup](#3-tech-stack--project-setup)
4. [Environment & Supabase Client](#4-environment--supabase-client)
5. [Authentication & Role Guard](#5-authentication--role-guard)
6. [App Shell & Navigation](#6-app-shell--navigation)
7. [Pages & Backend Integration](#7-pages--backend-integration)
8. [Storage (Images)](#8-storage-images)
9. [Error Handling & Loading](#9-error-handling--loading)
10. [Testing & Deployment](#10-testing--deployment)

---

## 1. Overview & Scope

### 1.1 Purpose

The **Business Owner Web App** lets business owners manage their businesses, deals, jobs, reviews, applicants, and boosts from a **desktop browser**. It uses the **same Supabase project** as the mobile app; RLS ensures each owner sees only their own data.

### 1.2 User Flow (from backend design)

| Step | Action | Backend |
|------|--------|---------|
| 1 | Sign in (email/password or Google) | Supabase Auth |
| 2 | App fetches profile; must have `role === 'businessOwner'` | `profiles` |
| 3 | If new: create business (pending approval) | `businesses` |
| 4 | Dashboard: analytics, deals, jobs, reviews, applicants, boosts | `businesses`, `deals`, `jobs`, `reviews`, `job_applications`, `boosts`, `boost_plans` |
| 5 | CRUD deals, jobs; reply to reviews; manage applicants; create boosts | Same tables + Storage for images |

### 1.3 Out of Scope

- Community-facing browsing (that’s the mobile app).
- Admin actions (user/business approval, boost plans CRUD) — those live in the [Admin Web App](./WEB_APP_ADMIN_IMPLEMENTATION.md).

---

## 2. Design System (Match Mobile App)

Use these tokens so the web app **visually matches** the Habra mobile app (see `lib/core/theme/` and `lib/core/resources/app_resources.dart` in the repo).

### 2.1 Colors

| Token | Hex | Usage |
|-------|-----|--------|
| **Primary (brand)** | `#1F563F` | Primary buttons, active states, links, key CTAs |
| **Primary light** | `#2D6B4F` | Hover states, subtle backgrounds |
| **Primary dark** | `#16402F` | Pressed/active emphasis |
| **Secondary (accent)** | `#C1A25F` | Secondary buttons, badges, accents |
| **Secondary light** | `#D4B87A` | Hover for secondary |
| **Secondary dark** | `#A88A4F` | Pressed secondary |
| **Text primary** | `#000000` | Headings, body |
| **Text secondary** | `#757575` | Descriptions, captions |
| **Text tertiary** | `#9E9E9E` | Placeholders, disabled |
| **Text on primary** | `#FFFFFF` | Button text on primary background |
| **Background** | `#FFFFFF` | Page/surface |
| **Background light** | `#F5F5F5` | Cards, alternate rows |
| **Background grey** | `#E0E0E0` | Borders, dividers |
| **Success** | `#4CAF50` | Success messages, approved |
| **Warning** | `#FF9800` | Warnings, pending |
| **Error** | `#B00020` | Errors, validation, rejected |

### 2.2 Typography

- **Font**: Use system font stack or the same font as mobile if you ship custom fonts (e.g. `Inter`, `Roboto`). Mobile uses `fontFamily: null` (system).
- **Sizes / weights** (match mobile):

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| Large title | 28px | Bold (700) | Page titles |
| Medium title | 22px | Semi-bold (600) | Section headers |
| Headline 1 | 32px | Bold | Hero/onboarding |
| Headline 2 | 24px | Bold | Card titles |
| Body | 16px | Normal | Body text |
| Body small | 14px | Normal | Secondary text |
| Button | 16px | Semi-bold (600) | Buttons |
| Caption | 12px | Normal | Labels, meta |

- **Line height**: Body 1.5; body small 1.4.

### 2.3 Spacing & Layout

- **Spacing scale**: 4, 8, 16, 24, 32, 48 (px) — use for padding/margins.
- **Border radius**: 4, 8, 12, 16, 24 (px). Buttons and cards: **8px**.
- **Button height**: 48px primary; 40px secondary.
- **Elevation**: Prefer flat (0) for primary buttons; use light shadow (2–4px) for cards if needed.

### 2.4 Components (Web Equivalents)

- **Primary button**: Background `#1F563F`, text white, height 48px, radius 8px, no shadow.
- **Secondary button**: Outline or background `#C1A25F` (or outline primary); same radius.
- **Cards**: White background, optional light grey border or 2px shadow, radius 8–12px, padding 16–24px.
- **Inputs**: Border `#E0E0E0`, focus border primary; radius 8px; height ~40–48px.
- **Badges**: Pending = warning color; Approved = success; Rejected = error; Active = primary.

---

## 3. Tech Stack & Project Setup

### 3.1 Recommended Stack

- **Framework**: React 18+ (or Vue 3 / Svelte) with TypeScript.
- **Build**: Vite.
- **Routing**: React Router v6 (or equivalent).
- **Backend client**: `@supabase/supabase-js`.
- **Styling**: CSS variables (for design tokens) + CSS Modules, Tailwind, or styled-components. Use the tokens from §2.

### 3.2 Create Project (Example: React + Vite)

```bash
npm create vite@latest habra-business-web -- --template react-ts
cd habra-business-web
npm install @supabase/supabase-js react-router-dom
```

### 3.3 Folder Structure (Suggested)

```
src/
  components/     # Shared: Button, Card, Input, Layout, Sidebar
  pages/          # SignIn, Dashboard, Businesses, Deals, Jobs, Reviews, Applicants, Boosts
  hooks/          # useAuth, useProfile, useBusinesses
  lib/            # supabase.ts, constants (colors, spacing)
  types/           # Profile, Business, Deal, Job, etc.
  routes/         # Route config + guard
```

---

## 4. Environment & Supabase Client

### 4.1 Environment Variables

Create `.env` (and `.env.staging`, `.env.production` for staging/prod):

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
```

Use **anon key only**; RLS enforces access. Never use `service_role` in the web app.

### 4.2 Supabase Client

Single instance, used for Auth and all table access:

```ts
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
if (!url || !anonKey) throw new Error('Missing Supabase env');

export const supabase = createClient(url, anonKey);
```

---

## 5. Authentication & Role Guard

### 5.1 Sign In

- **Email/password**: `supabase.auth.signInWithPassword({ email, password })`.
- **Google** (if enabled): `supabase.auth.signInWithOAuth({ provider: 'google' })`; configure redirect URL in Supabase Dashboard (e.g. `https://business.habra.app/auth/callback`).

After sign-in, redirect to dashboard or onboarding.

### 5.2 Session & Profile

- **Session**: `supabase.auth.getSession()` and `supabase.auth.onAuthStateChange()`.
- **Profile**: Fetch once after auth:  
  `supabase.from('profiles').select('*').eq('id', user.id).single()`.
- **Role check**: Require `profile.role === 'businessOwner'`. If not, show “Wrong account” or redirect to community app / sign-out.

### 5.3 Sign Out

`supabase.auth.signOut()` then redirect to sign-in.

### 5.4 Route Guard

- Protect all app routes: if no session → redirect to sign-in.
- If session but profile is not `businessOwner` → show access denied or sign-out.
- Example (React): a wrapper that checks `session` and `profile.role` before rendering children; else redirect.

### 5.5 Email Verification

- Check `session.user.email_confirmed_at` (or `profiles.email_verified_at` if you mirror it).
- If not verified, show a banner or block sensitive actions until verified; offer “Resend verification email” (Supabase: resend via Auth API or custom Edge Function).

---

## 6. App Shell & Navigation

- **Layout**: Sidebar (or top nav) with: Dashboard, My Businesses, Deals, Jobs, Reviews, Applicants, Boosts; user menu (profile + sign out).
- **Pending approval**: If the owner has only businesses with `approval_status === 'pending'`, show a clear “Pending approval” state on dashboard and optionally in the sidebar until at least one business is approved.

Use design tokens from §2 for nav background, active state (primary color), text (primary/secondary).

---

## 7. Pages & Backend Integration

Below, “Supabase” means `supabase.from(...)` with the **anon** client. RLS ensures the signed-in user only sees their own businesses and related rows.

### 7.1 Dashboard (Overview)

- **Purpose**: Summary for the owner (counts, recent activity).
- **Data**:
  - Businesses: `supabase.from('businesses').select('*').eq('owner_id', user.id)`.
  - Counts: active deals, active jobs, unread reviews (or total reviews), pending applicants. You can do separate count queries or one query with filters.
- **UI**: Cards for “Businesses”, “Active Deals”, “Jobs”, “Reviews”, “Applicants”; list of recent deals/jobs/applications (optional). Use primary/secondary colors and card styling from §2.

### 7.2 My Businesses

- **List**: `supabase.from('businesses').select('*').eq('owner_id', user.id).order('created_at', { ascending: false })`.
- **Display**: Name, address_city, approval_status, is_active, rating, review_count. Badge for pending/approved/rejected.
- **Create**: Navigate to “Add business” form. Insert:
  - `supabase.from('businesses').insert({ owner_id: user.id, name, address_city, ... })` — default `approval_status: 'pending'`. Redirect to list or detail.
- **Edit**: Load by id (ensure `owner_id === user.id` via RLS), then `supabase.from('businesses').update({ ... }).eq('id', id)`.
- **Detail page**: Same table; show full business + list of deals/jobs for this business (see below).

### 7.3 Deals

- **List**: For one business or all owner’s businesses:
  - Get business ids: `businesses.map(b => b.id)`.
  - `supabase.from('deals').select('*').in('business_id', businessIds).order('valid_until', { ascending: false })`.
- **Create**: `supabase.from('deals').insert({ business_id, title, description, original_price, discounted_price, discount_percentage, valid_from, valid_until, image_url, category, status: 'active' })`. Use Storage for image (see §8) and set `image_url` to the public or signed URL.
- **Edit**: `supabase.from('deals').update({ ... }).eq('id', id)`. RLS allows only if deal’s business is owned by user.
- **Status**: Update `status` to `draft` | `active` | `expired` | `inactive` as needed.

### 7.4 Jobs

- **List**: `supabase.from('jobs').select('*').in('business_id', businessIds).order('posted_at', { ascending: false })`.
- **Create**: `supabase.from('jobs').insert({ business_id, title, description, location, employment_type, salary_min, salary_max, posted_at: new Date().toISOString(), ... })`.
- **Edit**: `supabase.from('jobs').update({ ... }).eq('id', id)`.
- **Close/reopen**: Update a `status` or `is_active`-style column if present in your schema; otherwise use a convention (e.g. `closed_at`).

### 7.5 Reviews

- **List**: Get reviews for owner’s businesses:  
  `supabase.from('reviews').select('*, profiles!reviews_user_id_fkey(full_name, avatar_url)').in('business_id', businessIds).order('created_at', { ascending: false })`.  
  (Adjust join name if your FK name differs; otherwise two queries: reviews by business_ids, then profiles by user_ids.)
- **Reply**: If you have `review_replies` table: insert reply linked to review. If replies are stored on `reviews` (e.g. `reply_text`, `replied_at`), update that row.

### 7.6 Applicants (Job Applications)

- **List**: For owner’s jobs: get job ids from `jobs` where `business_id` in owner’s businesses, then  
  `supabase.from('job_applications').select('*, profiles!job_applications_user_id_fkey(full_name, email, phone), jobs(title)').in('job_id', jobIds).order('created_at', { ascending: false })`.
- **Detail**: One application by id; show resume link (Storage), cover letter, status. Update status:  
  `supabase.from('job_applications').update({ status: 'reviewed' | 'shortlisted' | 'rejected' | 'hired' }).eq('id', id)`.

### 7.7 Boosts

- **Plans**: `supabase.from('boost_plans').select('*').eq('is_active', true)` — read-only for owner.
- **My boosts**: `supabase.from('boosts').select('*, boost_plans(*), deals(title), jobs(title)').eq('business_id', businessId)` (or for all owner’s businesses: `.in('business_id', businessIds)`).
- **Create boost**: Choose deal or job, choose plan, then  
  `supabase.from('boosts').insert({ business_id, boost_plan_id, deal_id or job_id, starts_at, ends_at (from plan duration), status: 'active' })`.  
  Payment (if any) via Edge Function or external; this doc assumes you only create the `boosts` row.

---

## 8. Storage (Images)

- **Buckets**: Use the same as mobile: `businesses` (logos, gallery), `deals` (deal images). See [HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md).
- **Upload**: `supabase.storage.from('businesses').upload(path, file, { upsert: true })` — path e.g. `{businessId}/{filename}`. Then get URL: `supabase.storage.from('businesses').getPublicUrl(path).data.publicUrl` or create signed URL if bucket is private.
- **RLS**: Storage policies should allow authenticated upload for the business owner (e.g. path contains their business_id and they own that business). Enforce in app by only allowing upload when the user is the owner of the business.

---

## 9. Error Handling & Loading

- **Loading**: Show skeletons or spinners (use primary color) while fetching.
- **Errors**: On Supabase error (e.g. 403 from RLS), show a friendly message (“You don’t have access” or “Something went wrong”). Log details in dev.
- **Empty states**: When lists are empty, show clear CTAs (e.g. “Create your first deal”) with primary button styling.

---

## 10. Testing & Deployment

- **Unit tests**: Mock `supabase` (e.g. viagra or jest) in hooks and page logic.
- **Integration**: Point to a **staging** Supabase project; sign in as a test business owner; run through: create business, create deal, create job, view applicants, create boost. Ensure no RLS errors.
- **Deployment**: Build with `VITE_SUPABASE_*` for the target env (staging vs production). Add the deployed app URL to Supabase Auth → Redirect URLs. See [SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md).

---

## Summary Checklist

- [ ] Design tokens (colors, typography, spacing) match mobile app (§2).
- [ ] Supabase client created with anon key from env (§4).
- [ ] Auth: sign in, session, profile fetch, role === businessOwner guard (§5).
- [ ] App shell and navigation (§6).
- [ ] Dashboard: businesses + counts (§7.1).
- [ ] Businesses: list, create, edit (§7.2).
- [ ] Deals: list, create, edit, status (§7.3).
- [ ] Jobs: list, create, edit (§7.4).
- [ ] Reviews: list, reply (§7.5).
- [ ] Applicants: list, detail, update status (§7.6).
- [ ] Boosts: list plans, list my boosts, create boost (§7.7).
- [ ] Storage: upload business/deal images, set URLs in DB (§8).
- [ ] Errors and empty states (§9).
- [ ] Staging/prod env and redirect URLs (§10).

For backend schema and RLS details, see [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) and [supabase/habra_full_schema.sql](./supabase/habra_full_schema.sql).
