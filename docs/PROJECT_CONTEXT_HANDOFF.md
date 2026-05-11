# Habra Mobile App — Project context (handoff)

**Purpose:** One document to onboard developers or to paste into another repo (planning, contractor brief, or parallel work). It summarizes stack, configuration, architecture, and where to look in code.

**Repository:** Flutter mobile app (Android & iOS). Backend is **Supabase** (Postgres, Auth, Storage, Edge Functions). Payments: **RevenueCat** (IAP / subscriptions), **Stripe** (event tickets via PaymentSheet).

---

## 1. What this app is

- **Community member app:** Browse events, explore businesses/deals, jobs, profile, saved items, ticket purchases (Stripe).
- **Business owner app:** Same codebase; role-driven UI (`UserRole.businessOwner`) — dashboard (analytics, deals, jobs, events, reviews), boosts, subscriptions (RevenueCat), business onboarding.

There is **no super-admin UI in this repo**; admin is a separate web app (see `docs/WEB_APP_ADMIN_IMPLEMENTATION.md`).

---

## 2. Tech stack

| Layer | Choice |
|--------|--------|
| Framework | Flutter (Dart 3+) |
| State | Cubit / BLoC (`flutter_bloc`) |
| DI | GetIt (`injection_container.dart`) |
| Backend client | `supabase_flutter` |
| IAP | `purchases_flutter` (RevenueCat) |
| Card payments | `flutter_stripe` (PaymentSheet) |
| Auth | Supabase Auth + Google Sign-In + Apple (business flows) |

**Unsupported targets:** Web / desktop are not first-class (project may not compile for them).

---

## 3. Configuration (how the app gets secrets)

### Supabase (required to launch)

- **`dart_defines.json`** at repo root (copy from `dart_defines.example.json`).
- Used via `--dart-define-from-file=dart_defines.json` or IDE run config.
- Keys: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, optional `SUPABASE_AUTH_REDIRECT_URL` (default `habra://auth/callback`).
- Read in code through `AppConfig` / `SupabaseConfig`. If missing, `main.dart` shows a missing-config screen.

### RevenueCat (public SDK keys — in source, not defines)

- **File:** `lib/core/config/revenue_cat_sdk_keys.dart`
- Set **`android`** (`goog_…`) and **`ios`** (`appl_…`) from RevenueCat dashboard → **Public / app-specific** keys.
- **Do not** put the RevenueCat **secret** API key in the app.
- Entitlement / offering IDs can still use compile defines: `REVENUECAT_BUSINESS_ENTITLEMENT_ID`, `REVENUECAT_BUSINESS_OFFERING_ID`, `REVENUECAT_BOOST_OFFERING_ID` (see `lib/core/config/app_config.dart`).

### Google Sign-In

- **`GOOGLE_WEB_CLIENT_ID`** in `dart_defines.json` (Android token flow).
- **`GOOGLE_IOS_CLIENT_ID`** for iOS; `pod install` syncs to iOS config (see `docs/INTEGRATIONS_SETUP.md` / `app_config.dart` comments).
- Android **SHA-1** must match the OAuth client in Google Cloud; misconfiguration surfaces as Google Sign-In **code 10** / obfuscated traces (`m4.b: 10`, etc.). User-facing messages are mapped in `lib/core/supabase/supabase_failure_mapper.dart`.

### Stripe

- `STRIPE_PUBLISHABLE_KEY`, optional `STRIPE_MERCHANT_ID` (Apple Pay), Edge Function name for payment intents — see `stripe_payment_service.dart` and `dart_defines.example.json`.

### Maps

- `GOOGLE_MAPS_API_KEY` — also wired for Android/iOS native builds per project docs.

---

## 4. Architecture (where code lives)

```
lib/
├── core/           # Config, theme, services (Stripe, RevenueCat, permissions), Supabase helpers
├── features/       # Feature-first: auth, home, dashboard, jobs, events, explore, profile, ...
├── injection/      # GetIt registration (injection_container.dart)
└── main.dart       # Supabase init, DI, RevenueCat, Stripe, runApp
```

- **Clean-ish layering:** `domain` (entities, repositories interfaces, use cases) → `data` (datasources, models) → `presentation` (pages, cubits).
- **Errors:** Remote failures often go through `SupabaseFailureMapper` into app `ServerException` / `AuthException` / etc. (`lib/core/error/exceptions.dart`).

---

## 5. Important runtime flows

### Auth

- Email/password, Google, Apple (where enabled), guest.
- After login, **RevenueCat** `identifyUser` links `profiles.id` to the customer (`auth_supabase_remote_datasource.dart` / `RevenueCatService`).

### Business owner gating

- **Subscription / listing tier:** `BusinessSubscriptionPolicy`, `BusinessOwnerSubscriptionCubit`, paywall pages under `features/home/`.
- **Navigation gate:** `BusinessOwnerNavigationWrapper` computes whether Dashboard / Boosts are allowed from **business approval**, legal docs, and subscription snapshot (`_computeToolsSnapshot`).

### Dashboard (owner)

- **`DashboardCubit`** loads analytics, deals, jobs, reviews, events for the selected `business_id`.
- **Deals:** Full deal list for counts across Active / Expired / Drafts tabs should stay **one full fetch**; tab switching filters **client-side** only (avoid replacing the list with a single-status fetch so chip counts stay correct).

### Jobs & explore (community)

- Jobs list: `JobsCubit` + `jobs_supabase_datasource.dart` (approved businesses, `is_active`, optional search/filters).
- Explore / directory: `BusinessesCubit` + `businesses_supabase_datasource.dart`.
- **Location:** Session/device location and profile city sync — see `SessionDeviceLocationCubit`, `profile_home_city_sync.dart`. Default location labels like “Choose your location” are UX placeholders when nothing is set (not a fake Washington DC for queries).

---

## 6. Backend & SQL

- Schema reference: `docs/supabase/habra_full_schema.sql` and migrations under `docs/supabase/migrations/`.
- **RLS:** Admin operations in a future admin web app use `public.is_admin()` (`profiles.role = 'admin'`).
- Edge Functions live under `supabase/functions/` (e.g. Stripe intents, RevenueCat webhook).

---

## 7. Related documentation (in this repo)

| Doc | Use |
|-----|-----|
| `docs/INTEGRATION_DOCUMENT.md` | Integrations overview |
| `docs/SUPABASE_CLIENT_INTEGRATION_GUIDE.md` | Mobile + web clients vs Supabase |
| `docs/REVENUECAT_SETUP.md` | RevenueCat dashboard + keys |
| `docs/WEB_APP_ADMIN_IMPLEMENTATION.md` | Super admin web app (users, businesses, events CRUD, etc.) |
| `docs/OPEN_ISSUES_FIX_CHECKLISTS.md` | Ticket-style checklists for known open bugs |
| `docs/# Habra Mobile Apps — Open Issues.txt` | Snapshot of open issue IDs |

---

## 8. Build & run

```bash
flutter pub get
flutter run --dart-define-from-file=dart_defines.json
```

Release Android:

```bash
flutter build apk --release --dart-define-from-file=dart_defines.json
# or appbundle for Play Store
```

Ensure **`lib/core/config/revenue_cat_sdk_keys.dart`** is filled for IAP builds.

---

## 9. Conventions for parallel / external development

1. **Single source for RevenueCat SDK keys:** `revenue_cat_sdk_keys.dart` (not `dart_defines` for those keys).
2. **Avoid `AuthException` name clashes:** If a file imports both `supabase_flutter` and `core/error/exceptions.dart`, use a **prefix** on app exceptions (e.g. `import '.../exceptions.dart' as app_err;`).
3. **Dashboard mutations:** Creating/updating jobs or deals should **propagate repository exceptions** to the UI (or map them); swallowing errors only as `DashboardError` can break nested flows and lose messages.
4. **Google Sign-In errors:** Map obfuscated Android messages in `SupabaseFailureMapper._fallbackMessage`, not raw `PlatformException` strings in SnackBars.

---

## 10. Copying this doc to another repo

- Paste **this entire file** as e.g. `HABRA_MOBILE_CONTEXT.md` in the other repository.
- Add links to **this** repo URL if they need the actual code.
- Attach **`dart_defines.example.json`** (redacted) if the other team configures CI without real secrets.

---

*Generated for cross-repo context sharing. Update Supabase URLs, store IDs, and feature flags as your environments diverge.*
