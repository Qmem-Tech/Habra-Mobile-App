# Backend integration: what’s done and step-by-step TODOs

This doc tracks the “remove mock data and use Supabase backend” work: what’s done and a test-and-fix TODO list you can run through step by step.

**Firebase has been removed.** The app uses **Supabase only** for auth and backend. You must run with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` or the app will throw at startup.

---

## 1. What’s done

### 1.1 Core

- **`lib/core/supabase/supabase_mappers.dart`**  
  Helpers for parsing Supabase row data (timestamps, strings, numbers, lists).

### 1.2 Explore (businesses, deals, reviews)

- **`lib/features/explore/data/datasources/businesses_supabase_datasource.dart`**  
  Supabase implementation of `BusinessesRemoteDataSource`:
  - `getBusinesses` (filters: location, category, search, featured)
  - `getBusinessDetail` (with deals and reviews)
  - `getDeals` / `getDealDetail`
  - `getBusinessReviews` / `writeReview` / `redeemDeal`

### 1.3 Home feed

- **`lib/features/home/data/datasources/home_supabase_datasource.dart`**  
  Supabase implementation of `HomeRemoteDataSource`:
  - `getHappeningThisWeek`, `getHotDealsNearYou`, `getPopularBusinesses`, `getLatestJobs`

### 1.4 Events

- **`lib/features/events/data/datasources/events_supabase_datasource.dart`**  
  Supabase implementation of `EventsRemoteDataSource`:
  - `getEvents`, `getEventDetail`, `getSimilarEvents`
  - `getUserTickets`, `getTicketDetail`
  - `createOrder`, `processPayment`

### 1.5 Jobs

- **`lib/features/jobs/data/datasources/jobs_supabase_datasource.dart`**  
  Supabase implementation of `JobsRemoteDataSource`:
  - `getJobs`, `getJobDetail`, `getJobCategories`, `getJobTypes`
  - `getBookmarkedJobIds`, `toggleBookmark` (Supabase `job_bookmarks`)

- **`lib/features/jobs/data/datasources/job_applications_supabase_datasource.dart`**  
  Supabase implementation of `JobApplicationsRemoteDataSource`:
  - `submitApplication`, `getApplications`, `getApplicationForJob`

- **Jobs repository**  
  Uses `remoteDataSource.getBookmarkedJobIds()` and `remoteDataSource.toggleBookmark()` so bookmarks go to Supabase when the remote is Supabase.

### 1.6 Jobs remote interface

- **`getBookmarkedJobIds()` and `toggleBookmark()`** added to `JobsRemoteDataSource`; mock impl returns empty / no-op; Supabase impl uses `job_bookmarks` table.

---

## 2. What’s not done yet

- **DI wiring**  
  `injection_container.dart` still registers only **mock** implementations for:
  - Home, Search, Notifications
  - Dashboard, Boosts
  - Events, Explore, Jobs, JobApplications  

  No `SupabaseConfig.isConfigured` switch to use the new Supabase datasources yet.

- **Dashboard**  
  No `DashboardSupabaseDataSource` (analytics, deals, jobs, reviews, applicants, boost plans from Supabase).

- **Boosts**  
  No `BoostsSupabaseDataSource` (boost plans, locations, active/past boosts, submit/cancel/setAutoRenew).

- **Search**  
  No `SearchSupabaseDataSource` (search across events, businesses, jobs; trending).

- **Notifications**  
  No `NotificationSupabaseDataSource` (list, mark read, unread count from `notifications` table).

---

## 3. Step-by-step TODO list (test and fix iteratively)

Use this list in order. For each step: run the app with Supabase configured, do the action, then fix any errors or missing behavior before moving on.

### Phase A: Wire Supabase and verify basics

- [ ] **A1. Wire Explore to Supabase**  
  - In `injection_container.dart`, register `BusinessesRemoteDataSource` so that when `SupabaseConfig.isConfigured` is true you use `BusinessesSupabaseDataSource()`, else `BusinessesRemoteDataSourceImpl()`.
  - Run app with `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`.
  - Open **Explore** tab → confirm business list loads (or empty state if DB is empty). Fix any RLS/query/parsing errors.

- [ ] **A2. Test Explore: business detail, deals, reviews**  
  - Tap a business → detail page with deals and reviews.
  - If possible: write a review, redeem a deal; fix errors (e.g. RLS, `profiles` relation name, `deal_redemptions`).

- [ ] **A3. Wire Home to Supabase**  
  - Register `HomeRemoteDataSource` with Supabase vs mock (same pattern as A1).
  - Open **Home** tab → confirm “Happening this week”, “Hot deals”, “Popular businesses”, “Latest jobs” (or empty). Fix any errors.

- [ ] **A4. Wire Events to Supabase**  
  - Register `EventsRemoteDataSource` with Supabase vs mock.
  - Open **Events** tab → list and event detail. Optionally: create order / process payment; fix errors (e.g. `orders`/`tickets` inserts, relation names).

- [ ] **A5. Wire Jobs to Supabase**  
  - Register `JobsRemoteDataSource` and `JobApplicationsRemoteDataSource` with Supabase vs mock.
  - Open **Jobs** tab → list, filters, job detail. Toggle bookmark; apply for a job. Fix errors (e.g. `job_bookmarks` upsert/delete, `job_applications` insert).

### Phase B: Remaining datasources and DI

- [ ] **B1. Implement SearchSupabaseDataSource**  
  - Implement `SearchRemoteDataSource` with Supabase (search `events`, `businesses`, `jobs` by query/location; optional trending).
  - Register in DI (Supabase when configured).
  - Test **Search**: run a query, check results and empty state.

- [ ] **B2. Implement NotificationSupabaseDataSource**  
  - Implement `NotificationRemoteDataSource` with Supabase (`notifications` table: list by user, mark read, unread count).
  - Register in DI.
  - Test **Notifications** screen.

- [ ] **B3. Implement DashboardSupabaseDataSource**  
  - Implement `DashboardRemoteDataSource` with Supabase: businesses (by owner), deals, jobs, reviews, job_applicants, boost_plans; map to existing dashboard entities (analytics can use counts/placeholders if no views table).
  - Register in DI.
  - Sign in as **business owner** → open Dashboard → test each tab (analytics, deals, jobs, reviews, applicants). Fix RLS and mapping.

- [ ] **B4. Implement BoostsSupabaseDataSource**  
  - Implement `BoostsRemoteDataSource` with Supabase: `boost_plans`, `boosts`, locations (e.g. owner’s businesses), active/past boosts, submit order, cancel, setAutoRenew.
  - Register in DI.
  - As business owner: open **Boosts** → test list, select option/location, submit; test cancel/auto-renew if applicable.

### Phase C: Cleanup and edge cases

- [ ] **C1. Remove or guard mock-only paths**  
  - Once all features work with Supabase, decide: require Supabase (e.g. show “Configure backend” if not configured) or keep mock as fallback and document it.
  - Remove any dead code or duplicate logic.

- [ ] **C2. Error handling and empty states**  
  - Ensure network/auth/RLS errors show a clear message (no raw exceptions).
  - Ensure empty lists (no businesses, no events, etc.) show the correct empty-state UI.

- [ ] **C3. Auth and RLS**  
  - Test as **guest** vs **signed-in user** vs **business owner**: list/detail, bookmarks, applications, reviews, dashboard, boosts.
  - Fix any RLS policies or missing `auth.uid()` usage.

- [ ] **C4. Optional: run `flutter analyze`**  
  - Fix any new analyzer hints or errors introduced by the new code.

---

## 4. Quick reference: DI registration pattern

For each feature, use the same pattern as Auth/Splash:

```dart
// Example: Explore
sl.registerLazySingleton<BusinessesRemoteDataSource>(
  () => SupabaseConfig.isConfigured
      ? BusinessesSupabaseDataSource()
      : BusinessesRemoteDataSourceImpl(),
);
```

Repeat for: `HomeRemoteDataSource`, `SearchRemoteDataSource`, `NotificationRemoteDataSource`, `EventsRemoteDataSource`, `JobsRemoteDataSource`, `JobApplicationsRemoteDataSource`, `DashboardRemoteDataSource`, `BoostsRemoteDataSource`.

---

## 5. Running the app with Supabase

```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Ensure the project has run the schema (e.g. `docs/supabase/habra_full_schema.sql`) and that RLS and seed data (if any) are in place.
