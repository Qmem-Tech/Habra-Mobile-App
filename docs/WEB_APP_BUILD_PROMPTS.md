# Habra Web Apps — Copy-Paste Build Prompts

Use these prompts in **separate project folders** (e.g. `habra-business-web` and `habra-admin-web`) when building each web app. Paste the full prompt into Cursor (or another AI assistant) in that folder so it can implement the **UI** and **Supabase backend integration** end-to-end.

**Before using:** Ensure you have:
- A Supabase project with the Habra schema deployed (run `docs/supabase/habra_full_schema.sql` in the main Habra-Mobile-App repo).
- For the **admin app**: at least one user with `profiles.role = 'admin'` (set in Supabase Table Editor or via SQL).
- Project URL and **anon** key from Supabase Dashboard → Project Settings → API.

---

## Prompt 1: Business Owner Web App

Copy everything below the line into the **root of your business owner web app project** (e.g. a new React + Vite + TypeScript repo). Then ask the AI to implement the system using this spec.

---

**Build the Habra Business Owner Web App with UI and full Supabase backend integration.**

**Context:** This is a web app for **business owners** of the Habra platform (community app for events, deals, businesses, jobs). They sign in and manage their businesses, deals, jobs, reviews, applicants, and boosts. The backend is **Supabase** (PostgreSQL + Auth + Storage). Use the **anon key only**; RLS restricts data to the signed-in owner.

**Design system (match Habra mobile app):**
- **Colors:** Primary `#1F563F`, primary light `#2D6B4F`, secondary `#C1A25F`, secondary light `#D4B87A`. Text: primary `#000000`, secondary `#757575`, tertiary `#9E9E9E`. On primary (e.g. button text): `#FFFFFF`. Background: `#FFFFFF`, light `#F5F5F5`, grey `#E0E0E0`. Success `#4CAF50`, warning `#FF9800`, error `#B00020`.
- **Typography:** System font; large title 28px bold, section 22px semi-bold, body 16px, body small 14px, button 16px semi-bold, caption 12px. Line height body 1.5.
- **Layout:** Spacing 4/8/16/24/32/48px; border radius 8px for buttons and cards; primary button height 48px, no shadow.

**Tech stack:** React 18+ with TypeScript, Vite, React Router v6, `@supabase/supabase-js`. Styling: CSS variables for the design tokens above, plus your choice (Tailwind, CSS Modules, or styled-components).

**Environment:** `.env` with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Create one Supabase client with `createClient(url, anonKey)` and use it for Auth and all table access.

**Auth and access control:**
- Sign in: email/password via `supabase.auth.signInWithPassword({ email, password })`; optional Google via `signInWithOAuth({ provider: 'google' })`.
- After sign-in, fetch profile: `supabase.from('profiles').select('*').eq('id', user.id).single()`. Require `profile.role === 'businessOwner'`; otherwise show "Wrong account" or redirect. Sign out with `supabase.auth.signOut()`.
- Protect all app routes: no session → redirect to sign-in; session but not businessOwner → access denied.

**App shell:** Sidebar or top nav with: Dashboard, My Businesses, Deals, Jobs, Reviews, Applicants, Boosts; user menu (sign out). Use primary color for active item.

**Pages and backend (Supabase tables; RLS gives owner-only access):**

1. **Dashboard:** Load businesses with `supabase.from('businesses').select('*').eq('owner_id', user.id)`. Show counts (e.g. active deals, jobs, reviews, pending applicants) and optional recent activity. Use cards with the design tokens.

2. **My Businesses:** List: same `businesses` query, order by `created_at` desc. Show name, city, `approval_status` (badge: pending=warning, approved=success, rejected=error). Create: form then `supabase.from('businesses').insert({ owner_id: user.id, name, address_city, ... })` with `approval_status: 'pending'`. Edit: load by id, then `update({ ... }).eq('id', id)`.

3. **Deals:** List: get owner's business ids, then `supabase.from('deals').select('*').in('business_id', businessIds).order('valid_until', { ascending: false })`. Create: `insert({ business_id, title, description, original_price, discounted_price, discount_percentage, valid_from, valid_until, image_url, category, status: 'active' })`. Edit: `update({ ... }).eq('id', id)`. For images use Storage bucket `deals`: upload file, get public URL, set `image_url`.

4. **Jobs:** List: `supabase.from('jobs').select('*').in('business_id', businessIds).order('posted_at', { ascending: false })`. Create: `insert({ business_id, title, description, location, employment_type, salary_min, salary_max, posted_at: new Date().toISOString(), ... })`. Edit: `update({ ... }).eq('id', id)`.

5. **Reviews:** List: `supabase.from('reviews').select('*').in('business_id', businessIds).order('created_at', { ascending: false })`. Optionally join or fetch user profiles for reviewer name. Reply: if you have `review_replies` table, insert reply; else update review with reply fields if schema supports it.

6. **Applicants:** Get job ids for owner's businesses, then `supabase.from('job_applications').select('*, profiles(...), jobs(title)').in('job_id', jobIds).order('created_at', { ascending: false })`. Detail page: show application; update status with `supabase.from('job_applications').update({ status: 'reviewed'|'shortlisted'|'rejected'|'hired' }).eq('id', id)`.

7. **Boosts:** List plans: `supabase.from('boost_plans').select('*').eq('is_active', true)`. List my boosts: `supabase.from('boosts').select('*, boost_plans(*), deals(title), jobs(title)').in('business_id', businessIds)`. Create: user picks deal or job and plan; then `supabase.from('boosts').insert({ business_id, boost_plan_id, deal_id or job_id, starts_at, ends_at, status: 'active' })`.

**Storage:** Buckets `businesses` and `deals`. Upload with `supabase.storage.from('bucket').upload(path, file)`; path e.g. `{businessId}/{filename}`. Use `getPublicUrl(path)` for public URLs and set that URL on the row (`logo_url`, `image_url`, etc.).

**UX:** Loading states (spinner/skeleton with primary color); error messages on Supabase errors; empty states with clear CTAs (e.g. "Create your first deal"). Use the design system consistently for buttons, cards, inputs, and badges.

Implement the app structure (routes, guards, layout), all pages above, and Supabase integration. Do not use the service_role key; only the anon key.

---

## Prompt 2: Super Admin Web App

Copy everything below the line into the **root of your admin web app project** (e.g. a new React + Vite + TypeScript repo). Then ask the AI to implement the system using this spec.

---

**Build the Habra Super Admin Web App with UI and full Supabase backend integration.**

**Context:** This is a **platform admin** web app for Habra. Only users with **`profiles.role = 'admin'`** may use it. They manage users, approve/reject businesses, moderate content (deals, events, jobs, reviews), manage boost plans, view audit log, and edit app settings. Backend is **Supabase**; use the **anon key only**. RLS uses `is_admin()` so admins can read/update the relevant tables.

**Design system (match Habra mobile app):**
- **Colors:** Primary `#1F563F`, primary light `#2D6B4F`, secondary `#C1A25F`. Text: primary `#000000`, secondary `#757575`. Background: `#FFFFFF`, light `#F5F5F5`, grey `#E0E0E0`. Success `#4CAF50`, warning `#FF9800`, error `#B00020`.
- **Typography:** System font; large title 28px bold, section 22px semi-bold, body 16px, body small 14px, button 16px semi-bold. Spacing 4/8/16/24/32/48px; radius 8px for buttons and cards; button height 48px.
- **Admin UI:** Use tables for lists; approval badges: pending=warning, approved=success, rejected=error. Danger actions (reject, delete) in error color with confirmation.

**Tech stack:** React 18+ with TypeScript, Vite, React Router v6, `@supabase/supabase-js`. Styling: CSS variables for the design tokens above, plus Tailwind/CSS Modules/styled-components.

**Environment:** `.env` with `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY`. Single client: `createClient(url, anonKey)`.

**Auth and access control:**
- Sign in: `supabase.auth.signInWithPassword({ email, password })`.
- Fetch profile: `supabase.from('profiles').select('*').eq('id', user.id).single()`. Require `profile.role === 'admin'`; otherwise show "Access denied" and do not render admin UI. Sign out: `supabase.auth.signOut()`.
- Guard all admin routes: no session → sign-in page; session but not admin → access denied.

**App shell:** Sidebar or top nav: Dashboard, Users, Businesses, Deals, Events, Jobs, Reviews, Boost Plans, Boosts, Audit Log, App Settings; user menu (sign out). Active item in primary color.

**Pages and backend (admin RLS allows access via is_admin()):**

1. **Dashboard:** Counts: `profiles` (count), `businesses` (count), `businesses` where `approval_status = 'pending'` (count), `deals`, `events`, `jobs`, `orders` (counts). Show as cards; link "Pending businesses" to Businesses filtered by pending.

2. **Users:** List: `supabase.from('profiles').select('*').order('created_at', { ascending: false })`. Filter by role, search email. Detail: by id. Update: `update({ role: 'customer'|'businessOwner'|'admin'|'guest', is_suspended: true|false }).eq('id', id)`.

3. **Businesses:** List: `supabase.from('businesses').select('*').order('created_at', { ascending: false })`. Filter by `approval_status`: pending, approved, rejected. Detail: by id, show owner. **Approve:** `update({ approval_status: 'approved', reviewed_at: now, reviewed_by: currentUser.id }).eq('id', id)`. **Reject:** `update({ approval_status: 'rejected', rejection_reason, reviewed_at, reviewed_by }).eq('id', id)`. Also support updating `is_verified`, `is_featured`, `is_active`.

4. **Content moderation:**  
   - **Deals:** List `deals` with business name; filter by status; update `status` (e.g. to `inactive`) to hide.  
   - **Events:** List `events`; update `is_active: false` to hide.  
   - **Jobs:** List `jobs` with business name; update `is_active` or equivalent to hide.  
   - **Reviews:** List `reviews` with business and user; admin can update/delete per RLS.

5. **Boost plans:** List: `supabase.from('boost_plans').select('*')`. Create: `insert({ title, description, price_usd, duration_weeks, is_active: true, target_type })` (`price_usd` in dollars, e.g. `9.99`). Edit: `update({ ... }).eq('id', id)`. Delete or set `is_active: false`.

6. **Boosts:** List: `supabase.from('boosts').select('*, businesses(name), boost_plans(title), deals(title), jobs(title)').order('starts_at', { ascending: false })`. Read-only for this page.

7. **Audit log:** List: `supabase.from('audit_log').select('*').order('created_at', { ascending: false })`. Read-only; pagination and optional filter by resource_type or actor.

8. **App settings:** List: `supabase.from('app_settings').select('*')`. Update: `update({ value: jsonValue, updated_at: now }).eq('key', key)`. Keys include `maintenance_mode`, `min_app_version_android`, `min_app_version_ios`, `feature_boosts_enabled`, `feature_messages_enabled`; values are JSONB (boolean or string).

**UX:** Loading states (spinner/skeleton); clear errors on Supabase failures; empty states where relevant. Use the design system for all components. Do not use the service_role key; only anon key.

Implement the app structure (routes, admin guard, layout), all pages above, and Supabase integration.

---

## How to Use

1. **Business owner app:** Create a new folder (e.g. `habra-business-web`), run `npm create vite@latest . -- --template react-ts`, add `@supabase/supabase-js` and `react-router-dom`. Create `.env` with your Supabase URL and anon key. Copy **Prompt 1** above (from "Build the Habra Business Owner Web App" through "Do not use the service_role key") into a new Cursor chat in that folder and send. Iterate with the AI to add or refine pages.

2. **Admin app:** Same idea in a separate folder (e.g. `habra-admin-web`). Ensure one user in Supabase has `profiles.role = 'admin'`. Copy **Prompt 2** (from "Build the Habra Super Admin Web App" through "Only anon key") into a new Cursor chat in that folder and send.

3. **Reference docs (in main repo):** For full table schemas, RLS, and flows, the main Habra repo has:
   - `docs/WEB_APP_BUSINESS_OWNER_IMPLEMENTATION.md` — full business owner guide
   - `docs/WEB_APP_ADMIN_IMPLEMENTATION.md` — full admin guide
   - `docs/SUPABASE_BACKEND_DESIGN.md` — backend design
   - `docs/supabase/habra_full_schema.sql` — schema and RLS

You can copy the relevant implementation guide into the web app repo as a reference file if the repo is separate from the main Habra-Mobile-App repo.
