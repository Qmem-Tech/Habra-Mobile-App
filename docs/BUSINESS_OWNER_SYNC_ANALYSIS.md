# Business Owner Implementation vs MOBILE_APP_SYNC_PACKAGE.md

This document compares the **business owner journey** in the Habra Mobile App to the types, tables, and enums defined in `MOBILE_APP_SYNC_PACKAGE.md`, and assesses **dynamic content** and **error handling**.

---

## 1. Types & Tables (Doc Reference)

| Doc type / table | Doc location | Mobile app usage |
|------------------|--------------|------------------|
| **Profile** | `profiles` | ✅ Used in profile feature (`profiles` table). **Gap:** Doc has `business_verified`, `verified_at`, `verified_by`; app `UserProfile` has no business-verification fields. |
| **Business** | `businesses` | ✅ Explore uses `businesses` (list, detail, filters). **Business owner:** No API to *fetch owner’s businesses*; home/drawer use empty/mock data. |
| **Deal** | `deals` | ✅ Explore: list, detail, redeem. **Business owner:** Dashboard/Boosts use **mock** datasources (return `[]`). Create Deal UI exists but **does not persist** to Supabase. |
| **Job** | `jobs` | ✅ Community: browse, apply. **Business owner:** Dashboard jobs tab and Create Job UI exist; **datasource is mock**, Create Job **does not persist**. |
| **Review** | `reviews` | ✅ Explore: list, write, getMyReviews, update/delete. **Business owner:** Dashboard Reviews tab + Reply to Review UI; **dashboard datasource is mock**; Reply **does not persist**. |
| **JobApplication** | `job_applications` | ✅ Community: apply, my applications. **Business owner:** Job Applicants page uses **mock** dashboard datasource. **Enum:** Doc uses `hired`, app uses `accepted` (mismatch if backend uses `hired`). |
| **BoostPlan / Boost** | `boost_plans`, `boosts` | ⚠️ **Boosts feature** (UI, flow, filters) exists. **Datasource is mock** (empty options, locations, active/past boosts; submit/cancel/setAutoRenew no-ops). No Supabase `boost_plans` / `boosts` integration. |

**Table name constants:** The doc suggests central constants (e.g. `tables.profiles`, `tables.businesses`). The app uses **string literals** (`'profiles'`, `'businesses'`, `'deals'`, etc.) in datasources; there is **no shared `endpoints` / `tables` file** in the mobile app.

---

## 2. Implemented vs Not Implemented (Business Owner)

### ✅ Implemented (structure / UI)

- **Auth & entry:** Business sign-in, role-based routing to `BusinessOwnerWrapperPage`.
- **Navigation:** Bottom nav (Home, Dash, Boosts, Profile) + drawer (Home, Dashboard, Edit Business, Update Hours, Boost Listing, Settings, Sign out).
- **Home tab:** UI for single-business view, “All Businesses” view, setup-incomplete state, snapshot cards, quick actions, recent activity, active deals list, job posts list. **Data:** All from `BusinessOwnerHomeCubit`, which **never calls backend**; it emits empty presences, empty deals, empty jobs, empty activity.
- **Dashboard tab:** Tabs (Analytics, Deals, Jobs, Reviews), FAB for Create Deal / Create Job, Deals filter (active/expired/draft), “View Applicants”, “Reply to Review”. **Data:** `DashboardCubit` uses `DashboardRepository` → `DashboardRemoteDataSourceImpl`, which **returns null/empty for everything** (no Supabase).
- **Boosts tab:** Filters, active/past boosts list, “Boost Now”, empty state. **Data:** `BoostsCubit` → `BoostsRepository` → `BoostsRemoteDataSourceImpl` (all methods return empty or no-op).
- **Profile tab:** Same `ProfilePage` as community (loads `UserProfile` from `profiles`), Edit Profile, avatar upload, location.
- **Screens (UI only, no real persistence):** Create Deal, Create Job Post, Reply to Review, Job Applicants, Business Locations, Add New Presence, Boost flow (options, select deal/job/location, order confirmation, cancel boost). Business Locations and Add New Presence use **empty** `_presences` (no API).

### ❌ Not implemented (backend / data)

- **Owner’s businesses (presences):** No API to load businesses by `owner_id`. Home, drawer, dashboard, boosts, and business selector assume a “presence” but never fetch it; lists are always empty.
- **Dashboard data:** No Supabase (or other) implementation for:
  - Analytics
  - Deals by business (with status filter)
  - Jobs by business
  - Reviews overview + reviews list
  - Job applicants (by job) + applicant detail
  - Boost plans
- **Create Deal / Create Job:** Forms only; no repository/datasource calls to `deals` / `jobs` tables.
- **Reply to Review:** No update to `reviews` (e.g. `reply_text`, `replied_at`).
- **Boosts:** No Supabase (or other) implementation for boost options, locations, active/past boosts, submit order, cancel, setAutoRenew.
- **Edit Business / Update Hours:** Only “coming soon” snackbars; no edit-business or hours API.
- **Profile (business owner):** No use of doc’s `business_verified` / `verified_at` / `verified_by` (optional for later).

### ⚠️ Enum / schema alignment

- **Deal status:** Doc: `draft` | `active` | `expired` | `inactive`. App: `DashboardDealStatus`: active, expired, draft (no `inactive`). Add `inactive` if backend uses it.
- **Application status:** Doc: `pending` | `reviewed` | `shortlisted` | `rejected` | **`hired`**. App: same plus **`accepted`** instead of `hired`. Align with backend (e.g. map `hired` ↔ `accepted` or rename).
- **Deal category:** Doc lists e.g. `food-drink`, `retail`, …; app uses its own category enums in explore; ensure any deal category field matches backend.

---

## 3. Dynamic Content

- **Community/Explore:** Uses **dynamic** data from Supabase (`businesses`, `deals`, `reviews`, etc.) via `BusinessesSupabaseDataSource` and related repos/cubits.
- **Business owner:**
  - **Home:** Not dynamic. `BusinessOwnerHomeCubit` returns fixed empty lists and no real presences/deals/jobs.
  - **Dashboard:** Not dynamic. `DashboardRemoteDataSourceImpl` returns null/empty; no Supabase (or other) implementation.
  - **Boosts:** Not dynamic. `BoostsRemoteDataSourceImpl` returns empty lists and no-ops for write operations.
  - **Create Deal / Job / Reply to Review:** Not dynamic; form data is not sent to any backend.

So the **business owner journey currently does not use dynamic content** from the doc’s tables; it is UI and mock-only.

---

## 4. Error Handling

- **Explore / profile / auth:** Use `SupabaseFailureMapper.guard()` and/or `Either<Failure, T>`; exceptions are converted to `ServerException`, `ForbiddenException`, `NetworkException`, etc. `ServerException.toString()` returns the message, so the UI can show a clear message instead of “Instance of 'ServerException'”.
- **Business owner:**
  - **Dashboard:** `DashboardCubit` uses `try/catch` and `emit(DashboardError(e.toString()))`. If the repository ever threw `ServerException`, the user would now see the message (after the `toString()` fix). No use of `Either` or a shared failure type; no mapping of exceptions to user-friendly strings (e.g. network vs server vs permission).
  - **Boosts:** Same pattern: `try/catch` and `emit(BoostsError(e.toString()))`. No centralized error mapping.
  - **Create Deal / Job / Reply:** No backend calls, so no real error handling.

So error handling on the business owner side is **not aligned with best practice**: no `Either`/Failure, no shared user-facing message mapping, and no distinction between network/server/permission errors.

---

## 5. Recommendations

1. **Wire business owner to real data (sync with doc):**
   - Add an API to fetch businesses by `owner_id` (e.g. from `businesses` table) and map to “presences” for home, drawer, and selectors.
   - Implement **Supabase** (or shared) implementations for:
     - Dashboard: analytics, deals, jobs, reviews overview + list, job applicants + detail, boost plans (using `tables.deals`, `tables.jobs`, `tables.reviews`, `tables.job_applications`, `tables.boost_plans`).
     - Boosts: options, locations, active/past boosts, submit order, cancel, setAutoRenew (using `tables.boosts`, `tables.boost_plans`).
   - Implement Create Deal / Create Job to insert into `deals` / `jobs` with correct status and business_id.
   - Implement Reply to Review to update `reviews` (e.g. `reply_text`, `replied_at`).

2. **Align with doc and backend:**
   - Add a shared **table/endpoint constants** file (e.g. `lib/core/constants/supabase_tables.dart`) matching the doc’s `tables` and use it in all datasources.
   - Align enums: Deal status (`inactive` if used), Application status (`hired` vs `accepted`), and any deal category with the doc/backend.

3. **Improve error handling for business owner:**
   - Use `Either<Failure, T>` (or a single Failure type) in dashboard/boosts repositories and map exceptions in datasource (e.g. via `SupabaseFailureMapper` or equivalent) so the UI never shows raw `e.toString()` for unknown errors.
   - In cubits, fold on `Either` and emit error state with a **user-facing message** (e.g. from `Failure.message` or a central “message from exception” helper).
   - Optionally add retry and offline/network-specific messaging for critical flows (e.g. create deal, submit boost).

4. **Optional (doc):** Add `business_verified`, `verified_at`, `verified_by` to app profile type and UI if the backend and product require them.

---

*Summary: The business owner flow has full UI and navigation aligned with the doc’s features, but **no dynamic data** and **no persistence** for dashboard, boosts, create deal/job, or reply to review. Table names and types are used in explore/profile; dashboard and boosts use mock datasources and ad-hoc error handling. Wiring to the doc’s tables and centralizing errors will bring the business owner journey in sync with the doc and improve robustness.*
