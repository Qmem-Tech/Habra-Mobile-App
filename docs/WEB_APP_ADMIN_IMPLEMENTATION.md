# Habra — Super Admin Web App Implementation Guide

This document is a **detailed implementation guide** for building the **Habra Super Admin Web App**. It aligns **theme and UI** with the Habra Flutter mobile app and describes **end-to-end Supabase backend integration** (Auth, Database, RLS) for platform oversight: user management, business approval, content moderation, boost plans, reports, audit log, and app settings.

| Attribute | Value |
|-----------|--------|
| **Audience** | Developers building the super admin web app |
| **Prerequisites** | [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md), [SUPABASE_CLIENT_INTEGRATION_GUIDE.md](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md), backend schema deployed, at least one user with `profiles.role = 'admin'` |
| **Related** | [WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md](./WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md) (business app), [SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md) |

---

## Table of Contents

1. [Overview & Scope](#1-overview--scope)
2. [Design System (Match Mobile App)](#2-design-system-match-mobile-app)
3. [Tech Stack & Project Setup](#3-tech-stack--project-setup)
4. [Environment & Supabase Client](#4-environment--supabase-client)
5. [Authentication & Admin Role Guard](#5-authentication--admin-role-guard)
6. [App Shell & Navigation](#6-app-shell--navigation)
7. [Pages & Backend Integration](#7-pages--backend-integration)
8. [Audit Logging (Optional)](#8-audit-logging-optional)
9. [Error Handling & Loading](#9-error-handling--loading)
10. [Testing & Deployment](#10-testing--deployment)

---

## 1. Overview & Scope

### 1.1 Purpose

The **Super Admin Web App** is used only by users with **`profiles.role = 'admin'`**. It provides:

- **Dashboard**: Platform-wide counts and overview.
- **User management**: List/filter profiles; view detail; update role, suspend, or delete.
- **Business management & approval**: List businesses (including `approval_status = 'pending'`); approve or reject; set verified, featured, active.
- **Content moderation**: List and update deals, events, jobs, reviews (e.g. hide, change status).
- **Boost plans**: Full CRUD on `boost_plans`; list all `boosts`.
- **Reports / analytics**: Read-only aggregates (sign-ups, redemptions, ticket sales, etc.).
- **Audit log**: Read-only list of admin actions and sensitive changes.
- **App settings**: Read/update feature flags and config (e.g. maintenance_mode, min app version).

RLS uses the `is_admin()` function: when the signed-in user has `role = 'admin'`, they can read/update (and where stated, insert/delete) across the relevant tables.

### 1.2 User Flow

| Step | Action | Backend |
|------|--------|---------|
| 1 | Sign in (email/password or SSO) | Supabase Auth |
| 2 | Fetch profile; require `role === 'admin'` | `profiles` |
| 3 | Dashboard: counts (users, businesses, deals, events, jobs, orders) | Multiple tables (admin RLS) |
| 4 | Users: list, filter, update role/suspend | `profiles` |
| 5 | Businesses: list, filter by pending; approve/reject; verify, feature | `businesses` |
| 6 | Content: deals, events, jobs, reviews — list, update status | `deals`, `events`, `jobs`, `reviews` |
| 7 | Boost plans: CRUD; list boosts | `boost_plans`, `boosts` |
| 8 | Audit log: list (read-only) | `audit_log` |
| 9 | App settings: list, update | `app_settings` |

### 1.3 Out of Scope

- Business owner dashboard (use [Business Owner Web App](./WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md)).
- Community mobile flows (mobile app).
- Writing to `audit_log` from the web client: typically done by triggers or Edge Functions with service_role; this doc describes reading the audit log only. If you add client-side audit writes, use an Edge Function that uses service_role and inserts to `audit_log`.

---

## 2. Design System (Match Mobile App)

Use the **same design tokens** as the Business Owner Web App so both web apps and the mobile app feel consistent. Summary below; see [WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md §2](./WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md#2-design-system-match-mobile-app) for full detail.

### 2.1 Colors

| Token | Hex | Usage |
|-------|-----|--------|
| **Primary** | `#1F563F` | Primary buttons, active nav, links |
| **Primary light** | `#2D6B4F` | Hover |
| **Secondary** | `#C1A25F` | Secondary buttons, badges |
| **Text primary** | `#000000` | Headings, body |
| **Text secondary** | `#757575` | Descriptions |
| **Background** | `#FFFFFF` | Page/surface |
| **Background light** | `#F5F5F5` | Cards, tables |
| **Success** | `#4CAF50` | Approved, success |
| **Warning** | `#FF9800` | Pending, warning |
| **Error** | `#B00020` | Rejected, errors |

### 2.2 Typography & Layout

- **Font**: System stack or same as mobile (e.g. Inter, Roboto).
- **Sizes**: Large title 28px bold; section headers 22px semi-bold; body 16px; body small 14px; button 16px semi-bold; caption 12px.
- **Spacing**: 4, 8, 16, 24, 32, 48 px.
- **Radius**: Buttons and cards 8px.

### 2.3 Admin-Specific UI

- **Approval badges**: Pending = warning; Approved = success; Rejected = error.
- **Tables**: Use clear headers and alternating row background (#F5F5F5) for lists (users, businesses, deals, etc.).
- **Danger actions**: Delete or reject in error color; confirm with a modal or confirmation step.

---

## 3. Tech Stack & Project Setup

### 3.1 Recommended Stack

- **Framework**: React 18+ (or Vue 3 / Svelte) with TypeScript.
- **Build**: Vite.
- **Routing**: React Router v6 (or equivalent).
- **Backend client**: `@supabase/supabase-js` (anon key only; RLS + `is_admin()` grant access).

### 3.2 Create Project

```bash
npm create vite@latest habra-admin-web -- --template react-ts
cd habra-admin-web
npm install @supabase/supabase-js react-router-dom
```

### 3.3 Folder Structure (Suggested)

```
src/
  components/   # Button, Card, Table, Layout, Sidebar, Badge, Modal
  pages/        # SignIn, Dashboard, Users, Businesses, Deals, Events, Jobs, Reviews, BoostPlans, Boosts, AuditLog, AppSettings
  hooks/        # useAuth, useProfile, useAdminGuard
  lib/          # supabase.ts, design tokens
  types/        # Profile, Business, Deal, etc.
  routes/       # Route config + admin guard
```

---

## 4. Environment & Supabase Client

### 4.1 Environment Variables

```env
VITE_SUPABASE_URL=https://<project-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=<anon-key>
```

Use the **anon key** only. Admin access is enforced by RLS via `is_admin()`; do not use `service_role` in the client.

### 4.2 Supabase Client

```ts
// src/lib/supabase.ts
import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
if (!url || !anonKey) throw new Error('Missing Supabase env');

export const supabase = createClient(url, anonKey);
```

---

## 5. Authentication & Admin Role Guard

### 5.1 Sign In

- **Email/password**: `supabase.auth.signInWithPassword({ email, password })`.
- **SSO** (if configured): Use Supabase OAuth; add admin app redirect URL in Dashboard.

After sign-in, fetch profile and enforce admin role before showing any admin UI.

### 5.2 Profile & Role Check

- **Profile**: `supabase.from('profiles').select('*').eq('id', user.id).single()`.
- **Require**: `profile.role === 'admin'`. If not, show “Access denied” and sign out or redirect away. Do not render admin routes for non-admins.

### 5.3 Sign Out

`supabase.auth.signOut()` then redirect to sign-in.

### 5.4 Route Guard

- All admin routes: if no session → redirect to sign-in. If session but `profile.role !== 'admin'` → access denied. Only then render the admin app.

---

## 6. App Shell & Navigation

- **Layout**: Sidebar (or top nav) with: Dashboard, Users, Businesses, Deals, Events, Jobs, Reviews, Boost Plans, Boosts, Audit Log, App Settings; user menu (sign out).
- **Active item**: Use primary color (#1F563F). Keep labels clear (e.g. “Business approval” for pending queue).

---

## 7. Pages & Backend Integration

All queries use the same Supabase client with the **anon** key. RLS policies that call `is_admin()` allow the signed-in admin to read/update (and where applicable insert/delete) the tables below.

### 7.1 Dashboard (Overview)

- **Purpose**: High-level counts and optional recent activity.
- **Data** (all via admin RLS):
  - Users: `supabase.from('profiles').select('id', { count: 'exact', head: true })`.
  - Businesses: `supabase.from('businesses').select('id', { count: 'exact', head: true })`.
  - Pending businesses: `.select('id', { count: 'exact', head: true }).eq('approval_status', 'pending')`.
  - Deals: `supabase.from('deals').select('id', { count: 'exact', head: true })`.
  - Events: `supabase.from('events').select('id', { count: 'exact', head: true })`.
  - Jobs: `supabase.from('jobs').select('id', { count: 'exact', head: true })`.
  - Orders: `supabase.from('orders').select('id', { count: 'exact', head: true })`.
- **UI**: Cards or tiles for each count; highlight “Pending businesses” (e.g. link to Businesses filtered by pending). Optional: recent users, recent businesses, recent orders.

### 7.2 User Management

- **List**: `supabase.from('profiles').select('*').order('created_at', { ascending: false })`. Support pagination (range) and optional filters (role, email search, is_suspended).
- **Detail**: Select by id: `.select('*').eq('id', id).single()`.
- **Update**:
  - Role: `.update({ role: 'customer' | 'businessOwner' | 'admin' | 'guest' }).eq('id', id)`.
  - Suspend: `.update({ is_suspended: true | false }).eq('id', id)`.
- **Delete**: If your RLS allows admin to delete profiles: `.delete().eq('id', id)`. Schema may only allow delete own profile; if so, “deletion” may be done via suspend or via a backend/Edge Function. Check RLS: `profiles_delete_own` and `profiles_admin_update` — admin has update, not necessarily delete. If you need admin delete, add an RLS policy `profiles_admin_delete` with `USING (public.is_admin())` and `FOR DELETE`.

### 7.3 Business Management & Approval

- **List**: `supabase.from('businesses').select('*').order('created_at', { ascending: false })`. Filter by `approval_status`: `pending`, `approved`, `rejected`.
- **Pending queue**: `.eq('approval_status', 'pending')` — primary view for “Business approval”.
- **Detail**: `.select('*').eq('id', id).single()`. Show owner (join or fetch `profiles` by `owner_id`), categories, and related counts (deals, jobs).
- **Approve**:  
  `supabase.from('businesses').update({ approval_status: 'approved', reviewed_at: new Date().toISOString(), reviewed_by: currentUser.id }).eq('id', id)`.
- **Reject**:  
  `.update({ approval_status: 'rejected', rejection_reason: reason, reviewed_at: new Date().toISOString(), reviewed_by: currentUser.id }).eq('id', id)`.
- **Other flags**:  
  `.update({ is_verified: true|false, is_featured: true|false, is_active: true|false }).eq('id', id)`.

### 7.4 Content Moderation (Deals, Events, Jobs, Reviews)

- **Deals**: List `supabase.from('deals').select('*, businesses(name)').order('updated_at', { ascending: false })`. Filter by status: draft, active, expired, inactive. Update: `.update({ status: 'inactive' }).eq('id', id)` to hide or deactivate.
- **Events**: List `supabase.from('events').select('*').order('start_at', { ascending: false })`. Update: `.update({ is_active: false }).eq('id', id)` to hide.
- **Jobs**: List `supabase.from('jobs').select('*, businesses(name)').order('posted_at', { ascending: false })`. Update: `.update({ is_active: false }).eq('id', id)` (if column exists) or equivalent.
- **Reviews**: List `supabase.from('reviews').select('*, businesses(name), profiles!user_id(full_name)').order('created_at', { ascending: false })`. Admin can update or delete if RLS allows; schema has `reviews_update_delete_own` for user, and `admin_reviews` for admin FOR ALL — so admin can update/delete. To “hide” a review you might add a `is_hidden` column and filter in app, or delete.

Use design tokens for status badges (active = primary, inactive = grey, etc.).

### 7.5 Boost Plans

- **List**: `supabase.from('boost_plans').select('*').order('created_at', { ascending: false })`.
- **Create**: `supabase.from('boost_plans').insert({ title, description, price_cents, duration_weeks, is_active: true })`.
- **Edit**: `supabase.from('boost_plans').update({ title, description, price_cents, duration_weeks, is_active }).eq('id', id)`.
- **Delete**: `supabase.from('boost_plans').delete().eq('id', id)` (if you want hard delete; otherwise set `is_active: false`).

### 7.6 Boosts (All Businesses)

- **List**: `supabase.from('boosts').select('*, businesses(name), boost_plans(title, duration_weeks), deals(title), jobs(title)').order('starts_at', { ascending: false })`. Admin RLS allows SELECT on `boosts` via `admin_boosts`.

### 7.7 Reports / Analytics

- **Read-only** aggregates. Examples:
  - Sign-ups over time: count `profiles` by `created_at` (group by day/week).
  - Redemptions: `supabase.from('deal_redemptions').select('id', { count: 'exact', head: true })` and optionally by date range.
  - Ticket sales: count `orders` where `type` = event (if applicable) or count `tickets`.
- Implement with multiple queries or a single aggregation query; for heavy reports consider a materialized view or Edge Function and call from admin app.

### 7.8 Audit Log

- **List**: `supabase.from('audit_log').select('*').order('created_at', { ascending: false })`. Support pagination and optional filter by `actor_id`, `resource_type`, date range.
- **Read-only**: RLS only allows SELECT for admin. Inserts to `audit_log` are typically done by database triggers or Edge Functions (service_role), not by the web client. If you need to log admin actions from the client, create an Edge Function that accepts action/resource and inserts into `audit_log` with the service_role client.

### 7.9 App Settings

- **List**: `supabase.from('app_settings').select('*')`.
- **Update**: `supabase.from('app_settings').update({ value: newJsonValue, updated_at: new Date().toISOString() }).eq('key', key)`. Values are JSONB (e.g. `true`, `"1.0.0"`).
- **Common keys**: `maintenance_mode`, `min_app_version_android`, `min_app_version_ios`, `feature_boosts_enabled`, `feature_messages_enabled` (see seed data in [habra_seed_data.json](./supabase/habra_seed_data.json)).

---

## 8. Audit Logging (Optional)

If you want the admin app to record actions (e.g. “Business approved”, “User suspended”):

- **Option A**: Add database triggers that fire on `businesses.approval_status` change, `profiles.role` / `profiles.is_suspended` change, etc., and insert into `audit_log` (using a SECURITY DEFINER function that sets `actor_id` from `auth.uid()`).
- **Option B**: Call an Edge Function from the admin app with action and resource details; the function uses the service_role client to insert into `audit_log` with `actor_id` from the JWT.

Do not insert into `audit_log` directly from the client with the anon key unless you add an RLS policy that allows INSERT for `is_admin()` and you set `actor_id = auth.uid()`. The current schema only has SELECT for admin; add an INSERT policy if you prefer client-side audit writes.

---

## 9. Error Handling & Loading

- **Loading**: Use skeletons or spinners (primary color) for tables and detail views.
- **Errors**: On Supabase error (e.g. 403), show a clear message; log details in dev. If the user is no longer admin (e.g. role changed elsewhere), redirect to access denied and sign out.
- **Empty states**: When lists are empty, show a short message and optional CTA where relevant.

---

## 10. Testing & Deployment

- **Unit tests**: Mock `supabase` in hooks and page logic.
- **Integration**: Use a **staging** Supabase project and a test user with `role = 'admin'`. Run through: sign in → dashboard → approve business → update user role → edit boost plan → view audit log → update app setting. Ensure no RLS errors.
- **Deployment**: Build with the correct `VITE_SUPABASE_*` for staging or production. Add the admin app URL to Supabase Auth → Redirect URLs. Restrict admin app URL to internal or VPN if possible; keep admin credentials strict. See [SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md).

---

## Summary Checklist

- [ ] Design tokens match mobile app (§2).
- [ ] Supabase client with anon key (§4).
- [ ] Auth: sign in, profile fetch, role === admin guard (§5).
- [ ] App shell and navigation (§6).
- [ ] Dashboard: counts and pending businesses (§7.1).
- [ ] Users: list, filter, update role/suspend (§7.2).
- [ ] Businesses: list, filter, approve/reject, verify, feature (§7.3).
- [ ] Content: deals, events, jobs, reviews — list and update status/hide (§7.4).
- [ ] Boost plans: CRUD (§7.5); Boosts: list (§7.6).
- [ ] Reports: read-only aggregates (§7.7).
- [ ] Audit log: list (§7.8).
- [ ] App settings: list, update (§7.9).
- [ ] Optional: audit logging for admin actions (§8).
- [ ] Errors and loading states (§9).
- [ ] Staging/prod env and redirect URLs (§10).

For schema and RLS details, see [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) and [supabase/habra_full_schema.sql](./supabase/habra_full_schema.sql).
