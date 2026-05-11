# Open issues — fix checklists (one per ticket)

**Source snapshot:** `docs/# Habra Mobile Apps — Open Issues.txt` (same folder as this file).

Use one ticket at a time: complete **Reproduce → Diagnose → Fix → Verify → Regression**. Check boxes are for your tracker or local QA.

**Suggested order** (same theme as the source doc): Auth blockers → BO publish/counts → Search/filter → Edit/delete affordances → Gallery permissions → Profile/business → Polish.

---

## Shared root causes (do once, close multiple tickets)

| Do this work once | Closes or advances |
|-------------------|--------------------|
| Google Sign-In + user-facing errors | **HAB-25**, **TES-8** |
| Email resend / verification | **HAB-11** (CM), **TES-7** |
| Community search query path | **HAB-57**, **HAB-76**, **TES-13** |
| Gallery / image picker + Android 13+ | **HAB-10**, **HAB-11** (BO deals) |
| List row actions pattern (edit/delete) | **HAB-17**, **HAB-18** |

---

# 1. Business Owner mobile app

### HAB-25 — Google authentication failure + debug text (`m4.b: 10:`)

- [ ] Reproduce on **Android** and **iOS** (debug + release) from business sign-in / sign-up and community flows if shared code.
- [ ] Capture **full logs** (Logcat / Xcode) at failure; note whether failure is before or after `signInWithIdToken`.
- [ ] Verify **Supabase** Google provider: Web client ID, iOS client ID, Android SHA-1 / package name.
- [ ] Verify **`GOOGLE_WEB_CLIENT_ID`** / **`GOOGLE_IOS_CLIENT_ID`** in `dart_defines.json` and iOS `GoogleSignIn` config (see `app_config.dart`, `INTEGRATIONS` docs).
- [ ] Inspect `lib/features/auth/data/datasources/auth_supabase_remote_datasource.dart` (and Google use case) for **raw exception** passed to UI; replace with safe message + `debugPrint`/`Crashlytics` only.
- [ ] Retest sign-in and sign-up; confirm **no internal class codes** (e.g. `*.b: 10:`) shown to users.
- [ ] If fixed, run same tests for **TES-8** (duplicate).

**Likely code:** `auth_supabase_remote_datasource.dart`, `auth_cubit.dart`, `business_sign_in_page.dart`, `business_sign_up_page.dart`, `sign_up_options_page.dart`.

---

### HAB-27 — Job posting fails to publish

- [ ] Reproduce: fill required fields → Publish → capture **exact** snackbar/dialog text.
- [ ] Log **Supabase/Postgrest** error body (code, message, hint) in datasource or temporarily in UI (dev only).
- [ ] Confirm **RLS** on `jobs` for `businessOwner` insert/update (Supabase migrations vs `jobs_supabase_datasource.dart`).
- [ ] Confirm **required columns** and FKs (`business_id`, `owner`, etc.) match schema; fix mapping if null/wrong enum.
- [ ] Fix validation vs backend (e.g. salary range, category) so user sees **actionable** errors.
- [ ] Verify: draft → publish; job appears in “Your Job Posts” and in community list if applicable.

**Likely code:** `lib/features/dashboard/...` (create job UI), `lib/features/jobs/data/datasources/jobs_supabase_datasource.dart`, dashboard cubit/repository.

---

### HAB-17 — Missing Edit/Delete for “Your Job Posts”

- [ ] Locate list UI for owner jobs (dashboard / home section).
- [ ] Confirm **job id** and **edit route** exist (reuse create-job flow with `jobId`).
- [ ] Add **Edit** → navigate to pre-filled form; **Delete** → confirm dialog → soft delete or hard delete per product/RLS.
- [ ] After action, **refresh** list (cubit `load` / optimistic update).
- [ ] Verify on device: create → edit → delete.

**Likely code:** dashboard home widgets, `jobs_repository`, create/edit job pages under `lib/features/dashboard/`.

---

### HAB-26 — Deal counts wrong until tab selected

- [ ] Reproduce: open deals area with existing active + draft; note **zero** counts before tab tap.
- [ ] Find where **counts** are computed (tab controller listener? separate `setState`?).
- [ ] Ensure **initial load** fetches both segments (or aggregated counts) and emits state **before** first paint.
- [ ] Add widget test or manual script: data present → counts non-zero on first frame.
- [ ] Verify switching tabs still updates correctly.

**Likely code:** `lib/features/dashboard/presentation/pages/dashboard_deals_tab.dart`, related dashboard cubit.

---

### HAB-14 — No draft vs published distinction in Active Deals list

- [ ] Inspect deal model/API for **status** field (`draft` / `active` / etc.).
- [ ] Ensure list query **includes** status and UI shows **badge** or subtitle.
- [ ] Align naming with product (“Draft” vs “Published”) and filters if any.
- [ ] Verify: save draft → appears with draft badge; publish → published badge.

**Likely code:** `create_deal_page.dart`, `dashboard_deals_tab.dart`, `dashboard_deal` entity, Supabase `deals.status`.

---

### HAB-18 — Missing Edit/Delete for “Your Active Deals”

- [ ] Same pattern as **HAB-17**: list row actions, routes to `create_deal_page` with id, delete + refresh.
- [ ] Respect **HAB-14** so user knows which rows are draft vs published before delete.
- [ ] Verify end-to-end.

**Likely code:** `dashboard_deals_tab.dart`, `create_deal_page.dart`, deals datasource/repository.

---

### HAB-11 (Business Owner) — Gallery permission on Create Deal

- [ ] Reproduce on **Android 12/13/14** and iOS: gallery path after “Allow”.
- [ ] Centralize **image pick** in one helper (camera + gallery); use **Photo Picker** where no broad storage permission needed.
- [ ] Fix **activity lifecycle** / `onActivityResult` / permission callback so flow does not **pop** without result.
- [ ] Wire **create event** (**HAB-10**) through the same helper.
- [ ] Document required **AndroidManifest** / iOS **Info.plist** keys.
- [ ] Verify deal + event image attach.

**Likely code:** `create_deal_page.dart`, event create pages under `lib/features/dashboard/` or `events/`, any `image_picker` / `permission_handler` usage.

---

### HAB-10 — Gallery permission: returns without selecting image (Create Event)

- [ ] Complete **same checklist as HAB-11 (BO)** after shared helper exists; validate event screen only if different wrapper.
- [ ] Mark duplicate work in tracker.

---

### HAB-12 — Inconsistent date/time UI (Create Event vs Create Deal)

- [ ] Audit both screens: widgets used for **start/end** datetime.
- [ ] Extract **shared** `DateTimeField` / bottom sheet / `showDatePicker`+`showTimePicker` pair.
- [ ] Match **labels**, **format**, and **validation** (end after start).
- [ ] Verify both flows on light/dark theme.

**Likely code:** `create_deal_page.dart`, event creation under dashboard/events.

---

### HAB-23 — Profile photo not updating after change

- [ ] Reproduce: change avatar → profile still shows old image.
- [ ] Confirm **upload** returns new `avatar_url`; `profiles` row updates in Supabase.
- [ ] Fix **cache**: `CachedNetworkImage` cache key, query param bust, or `evictFromCache`; refresh **profile** state in cubit after update.
- [ ] Verify drawer + profile page show new photo without restart.

**Likely code:** `profile_supabase_datasource.dart`, profile page / cubit, image widget.

---

### HAB-22 — Cannot remove interests on Edit Profile

- [ ] Locate interests UI (chips / list).
- [ ] Add **remove** (tap X or long-press) and persist via same `updateProfile` payload as add.
- [ ] Handle empty list if all removed.
- [ ] Verify reload shows correct interests.

**Likely code:** edit profile page, `profile_supabase_datasource.dart` (`interests` column).

---

### HAB-15 — Manage button shows “pending approval” incorrectly

- [ ] Reproduce: approved business vs pending; note **`businesses.approval_status`** (or equivalent) in DB.
- [ ] Trace **Manage** `onTap`: which condition blocks navigation?
- [ ] Fix logic: only block when truly `pending`; optional “limited manage” per product spec.
- [ ] Verify approved owner reaches **management** UI; pending sees correct copy.

**Likely code:** business owner home / dashboard entry, `businesses` fetch, approval fields.

---

### HAB-24 — Business hours: one time applies to all days

- [ ] Reproduce: change Monday → all days change.
- [ ] Inspect model: **per-day** list vs single `TimeOfDay`.
- [ ] Refactor state to **Map<Weekday, Hours>** or list of day rows; optional **“Copy to all days”** button.
- [ ] Save/load round-trip to Supabase.
- [ ] Verify mixed schedules (e.g. Sat closed).

**Likely code:** business hours editor under dashboard/onboarding.

---

# 2. Community Member — current backlog

### HAB-11 — Resend email verification not working

- [ ] Reproduce from **email verification** screen; watch network or logs.
- [ ] Trace `AuthCubit.resendVerificationEmail` → `resendVerificationEmailUseCase` → `auth_supabase_remote_datasource` / `signUp` APIs.
- [ ] Supabase Dashboard: **Auth → Providers → Email**, **SMTP** configured, rate limits.
- [ ] Confirm correct **Resend** API (`resend` type: `signup` vs `email_change`).
- [ ] Add user-visible error from server message (sanitized).
- [ ] Verify email received; retest **TES-7** as duplicate.

**Likely code:** `email_verification_page.dart`, `auth_cubit.dart`, `auth_repository_impl.dart`, remote datasource.

---

### HAB-76 — Search jobs not working

- [ ] Reproduce on jobs screen: enter query → no / wrong results.
- [ ] Trace **search** parameters** from UI → `jobs_cubit` / repository → Supabase query (ilike, RPC, filters).
- [ ] Fix empty-query vs filter combination; align with **HAB-57**, **TES-13**.
- [ ] Add minimal test or manual matrix: keyword, category, location.

**Likely code:** `jobs_page.dart`, `jobs_cubit.dart`, `jobs_supabase_datasource.dart`, `job_filters_bottom_sheet.dart`.

---

### HAB-75 — Job filter broken; hard-coded “show 24 jobs”

- [ ] Find **“24”** string or fixed `limit` in jobs UI.
- [ ] Replace with **real count** from response or pagination metadata.
- [ ] Ensure **filter** changes query and resets page.
- [ ] Verify label updates when fewer than 24 jobs exist.

**Likely code:** `jobs_page.dart`, `jobs_section_list_page.dart`, cubit/state.

---

### HAB-57 — General search doesn’t work

- [ ] Identify all **search entry points** (home, explore, global).
- [ ] Unify **debounce + query** to backend; fix broken route or empty search string.
- [ ] Cross-check with **HAB-76** / **TES-13** so one fix doesn’t regress another surface.
- [ ] Verify keyword returns results across entities (per product scope).

**Likely code:** explore/home blocs, search widgets under `lib/features/explore/`, `lib/features/home/`.

---

### HAB-50 — After sign up, prompt location + interests

- [ ] Define **UX**: modal vs dedicated onboarding screen vs settings nudge.
- [ ] Persist **location** (city/coords) + **interests** to `profiles` (and any prefs).
- [ ] Gate or skip without blocking critical path if user dismisses (product call).
- [ ] Verify new user sees flow once (`SharedPreferences` / profile flag).

**Likely code:** post-auth navigation, onboarding feature, profile columns.

---

### HAB-55 — Location hard-coded to Washington DC

- [ ] Grep codebase for **Washington**, **DC**, default coordinates.
- [ ] Replace with **onboarding value**, **profile field**, or **device** placeholder with permission UX.
- [ ] Ensure **explore/map** reads dynamic default.
- [ ] Verify with new account + different city.

**Likely code:** explore cubit, map widgets, localization/defaults.

---

### HAB-64 — Explore page UI/UX (In Progress)

- [ ] Compare **home** vs **explore** list components; align spacing, typography, cards.
- [ ] Fix overflow / clipping if any; test small devices.
- [ ] Peer review screenshots before marking done.

**Likely code:** `lib/features/explore/presentation/pages/`.

---

### HAB-34 — RevenueCat subscriptions + Stripe tickets + QR (In Progress)

- [ ] Confirm **Stripe** PaymentSheet path for tickets; **RevenueCat** for subscriptions per `business_subscription_config`.
- [ ] After successful purchase, load **ticket** record with stable id for QR payload.
- [ ] Implement **QR** on ticket detail / “My Tickets” (`qr_flutter` or equivalent).
- [ ] Test sandbox: purchase → QR scans to expected payload; **HAB-81** remains superseded.

**Likely code:** `stripe_payment_service.dart`, `my_tickets_page.dart`, `ticket_detail_page.dart`, `revenue_cat_service.dart`.

---

### HAB-99 — Excessive loading (Canceled)

- [ ] **When reopening:** profile with Performance overlay; reduce redundant `fetch` on tab change; consider `AutomaticKeepAliveClientMixin`.

---

### HAB-81 — Stripe for tickets (Canceled)

- [ ] Superseded by **HAB-34**; no separate work unless scope split again.

---

# 3. Community Member — testing backlog (TES)

### TES-8 — Continue with Google error (`j4.b: 10:`)

- [ ] Execute **HAB-25** checklist; treat as **same defect** until proven otherwise.

---

### TES-7 — Continue with email — no verification email

- [ ] Execute **HAB-11** (resend verification) checklist.

---

### TES-14 — “My Tickets” shows error

- [ ] Open **My Tickets** from `navigation_drawer.dart` → `MyTicketsPage`.
- [ ] Inspect `TicketsCubit.loadUserTickets` / repository: **Postgrest** error, **RLS**, missing `user_id`.
- [ ] Fix query or auth; replace generic `Error: ${state.message}` with actionable copy + log.
- [ ] Verify empty state vs error state; test user with zero tickets.

**Likely code:** `lib/features/events/presentation/pages/my_tickets_page.dart`, `tickets_cubit.dart`, tickets datasource.

---

### TES-13 — Search only works when filter used

- [ ] Execute **HAB-57** / **HAB-76** search path audit; ensure **default** search executes same query as post-filter.
- [ ] Retest drawer search without opening filters.

---

### TES-11 — Deals not clickable on business cards

- [ ] Locate **business card** layout (home/explore); find deal sub-row.
- [ ] Wrap with `InkWell` / `GestureDetector`; `Navigator` to `deal_detail_page` with deal id.
- [ ] Verify “Hot Deals” behavior unchanged.

**Likely code:** business card widgets under `home` / `explore`.

---

### TES-16 — Social media on About Us

- [ ] Add links (URL launcher) for agreed networks; track opens externally.
- [ ] Content from remote config vs static — product decision.

---

### TES-9 — Ticket count dropdown invisible (white on white)

- [ ] Find order-summary **dropdown** (ticket quantity).
- [ ] Set `dropdownColor`, `style` **text color**, `decoration` **fillColor** for light theme.
- [ ] Verify light + dark + accessibility contrast.

**Likely code:** event checkout / ticket purchase UI under `lib/features/events/`.

---

### TES-12 — Job category filter returns no rows

- [ ] Reproduce: category X shows jobs in “All” but **empty** when filtered.
- [ ] Compare **category id** / slug used in filter vs stored on `jobs` row.
- [ ] Fix mapping in `job_filters_bottom_sheet` / query `.eq('category', ...)`.
- [ ] Verify each category in seed data.

---

### TES-10 — Saved Events: no saved vs unsaved distinction

- [ ] In **Saved Items** events tab, add **bookmark** icon state or label.
- [ ] Sync with `SavedItemsCubit` / toggle API.
- [ ] Match jobs tab behavior for consistency.

---

### TES-15 — Arabic / French non-functional

- [ ] Audit `lib/l10n/*.arb`: missing keys vs English.
- [ ] Enable **locale** resolution in `MaterialApp`; verify `Locale('ar')` loads ARB.
- [ ] Fix **RTL** without hiding untranslated strings; fallback strategy.
- [ ] QA: switch language in settings → restart if required → spot-check main flows.

---

### TES-6 — Phone confirmation code not sent

- [ ] Supabase: **Phone** auth enabled; **SMS** hook (Twilio/MessageBird) secrets set.
- [ ] App: correct **country code**, E.164 format, rate limit handling.
- [ ] Test on real device; check Supabase Auth logs.

**Likely code:** auth flows using phone OTP (if present in `auth_supabase_remote_datasource.dart`).

---

### TES-17 — “View all” on business detail does nothing

- [ ] Find **View all** for photos/reviews on business detail page.
- [ ] Implement **routes**: gallery grid / full reviews list with `businessId`.
- [ ] Disable button only when count is zero.

**Likely code:** business detail under `explore` or `home`.

---

### TES-5 — Single back press exits app

- [ ] Wrap root `Navigator` or use `PopScope` / `WillPopScope`: first back → **SnackBar** “Press again to exit”; second within window exits.
- [ ] Test Android hardware back; iOS swipe not applicable.

**Likely code:** `main_navigation_wrapper.dart` or shell `Scaffold`.

---

## Maintenance

When a ticket is **done**, check it off here or in your issue tracker and add **PR / commit** reference in the tracker. Optionally link to this file from the Open Issues TXT.
