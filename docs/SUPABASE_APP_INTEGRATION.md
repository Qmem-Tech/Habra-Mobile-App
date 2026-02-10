# Habra Mobile App — Supabase Backend Integration

This document describes **what you must provide from Supabase**, how **error handling** and **caching** work, and how the app is wired to the backend.

**Quick: what you need to provide**

1. **From Supabase Dashboard** → Project Settings → API: **Project URL** and **anon (public) key**.
2. **In the app**: pass them at runtime via **dart-define**:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://YOUR_REF.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
   ```
   Or set the same in your IDE run configuration. When both are set, the app uses **Supabase for Auth and Splash**; otherwise it falls back to Firebase Auth and the existing splash.

---

## 1. What to Provide from Supabase

### 1.1 Required (Auth + Database)

| What | Where in Supabase | Use in app |
|------|-------------------|------------|
| **Project URL** | Dashboard → Project Settings → API → Project URL | `SupabaseConfig.supabaseUrl` |
| **Anon (public) key** | Project Settings → API → anon public | `SupabaseConfig.supabaseAnonKey` |

- Use the **anon key only** in the app. RLS enforces access; never put the **service_role** key in the client.
- For **staging vs production**: use different env / dart-define values per build (see [SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md](./SUPABASE_STAGING_AND_PRODUCTION_GUIDE.md)).

### 1.2 Auth (Dashboard)

- **Authentication → Providers**: Enable **Email** (and **Confirm email** if you want verification). Enable **Google** and/or **Anonymous** if your app uses them.
- **URL Configuration**: Set **Site URL** and **Redirect URLs** (e.g. your app deep link for OAuth: `habra://auth/callback` or as in [HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md)).

### 1.3 Storage (for images)

- Create buckets per [HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md): e.g. `avatars`, `businesses`, `deals`, `events`, `reviews`, `resumes`.
- Bucket names are used in code when uploading (e.g. `supabase.storage.from('deals')`). No extra config in the app beyond the project URL and anon key.

### 1.4 Backend schema and RLS

- Run **`docs/supabase/habra_full_schema.sql`** in the SQL Editor once.
- Optional seed: run **`docs/supabase/habra_seed.sql`** for categories, boost_plans, app_settings.
- RLS policies are defined in the schema; the app does not send any secret; access is determined by `auth.uid()` and role in `profiles`.

### 1.5 Summary: minimal checklist

- [ ] Supabase project created; **Project URL** and **anon key** copied.
- [ ] Schema applied (`habra_full_schema.sql`); optional seed run.
- [ ] Auth: Email (and optionally Google, Anonymous) enabled; Redirect URLs set.
- [ ] Storage buckets created if the app uploads images.
- [ ] In the app: provide URL and anon key via env or dart-define (see §3).

---

## 2. App-side configuration (what you set in the app)

- **Supabase URL** and **anon key** must be available at runtime. Options:
  - **Dart-define** (recommended for builds):  
    `--dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key`
  - **Environment variables**: read from `String.fromEnvironment('SUPABASE_URL', defaultValue: '')` and same for key, or from a config file that is not committed (e.g. `lib/core/supabase/supabase_config.dart` with placeholders; replace in CI or locally).
- **Initialization**: Call `Supabase.initialize(url: url, anonKey: anonKey)` in `main.dart` before `runApp` (see §5). If URL or key is missing, the app should fail fast with a clear message or show a config error screen.

---

## 3. Error handling (robust, professional)

### 3.1 Layers

- **Data source (Supabase)**: Catches Supabase/network errors and throws **exceptions** from `core/error/exceptions.dart` (e.g. `ServerException`, `AuthException`, `ForbiddenException`).
- **Repository**: Catches those exceptions and returns **failures** (`core/error/failures.dart`): `Left(ServerFailure(...))`, `Left(AuthFailure(...))`, etc.
- **UI**: Uses `Either.fold`; shows user-friendly messages and optional retry.

### 3.2 Supabase error → exception mapping

- **Auth errors** (invalid credentials, email not confirmed, user disabled): → `AuthException(message)`.
- **RLS / 403 / PGRST301**: → `ForbiddenException(message)`.
- **Network / timeout**: → `NetworkException(message)`.
- **Postgrest/Supabase server errors (5xx, 400)**: → `ServerException(message)`.
- **Unknown**: → `ServerException(safeMessage)` (do not expose raw stack to UI).

`SupabaseFailureMapper` in `lib/core/supabase/` centralizes this mapping so every Supabase call can be wrapped and converted.

### 3.3 User-facing messages

- Map failures to localized or fixed strings: e.g. `AuthFailure` → "Invalid email or password" or "Please confirm your email"; `NetworkFailure` → "No connection"; `ServerFailure` → "Something went wrong. Try again."
- Optionally log the original error (or code) for debugging; do not show raw Supabase errors to the user.

---

## 4. Cache for static / semi-static data

### 4.1 Purpose

- Data that changes rarely (e.g. **categories**, **boost_plans**, **app_settings**) is fetched from Supabase but **cached** in the app to reduce network calls and improve offline behavior.
- Previously **mock/static** data in the app is replaced by **Supabase + cache**: first load (or after cache expiry) hits the backend; subsequent reads use cache until TTL expires.

### 4.2 What is cached

- **Categories** (e.g. business types): table `categories`; cache key `cache_categories`; TTL e.g. 24 hours.
- **Boost plans**: table `boost_plans`; cache key `cache_boost_plans`; TTL e.g. 1 hour or 24 hours.
- **App settings** (feature flags, min version): table `app_settings`; cache key `cache_app_settings`; TTL e.g. 15–60 minutes.
- **Job categories** (if you use `categories` or a dedicated list): same as categories or dedicated key; TTL as above.

### 4.3 How cache is implemented

- **`CacheClient`** in `lib/core/cache/`: abstract interface `get<T>`, `set<T>`, `remove`, optional TTL per key.
- **In-memory cache** with TTL: e.g. `MemoryCacheClient` that stores entries with expiry. Used for categories, boost_plans, app_settings so that:
  - First request: fetch from Supabase, store in cache with expiry, return data.
  - Later requests: if cache valid, return cached data; else fetch from Supabase again and refresh cache.
- Optionally: persist cache to disk (e.g. SharedPreferences or Hive) with same keys and expiry so it survives app restarts. For simplicity, the base implementation can be in-memory only; you can add a `PersistentCacheClient` later that uses the same interface.

### 4.4 Usage in data layer

- **Categories**: A repository or datasource method "get categories" first checks `CacheClient.get<List<Category>>(cache_categories)`. If null or expired, fetch from Supabase, then `CacheClient.set(cache_categories, data, ttl: Duration(hours: 24))` and return. Otherwise return cached value.
- **Boost plans / app settings**: Same pattern with their keys and TTLs.
- **User-specific or frequently changing data** (deals, jobs, reviews, current user profile) is **not** cached with long TTL; use normal Supabase calls (and optional short-lived cache for "last list" if you want).

---

## 5. Integration architecture (high level)

- **main.dart**: Initialize Supabase with URL and anon key (from dart-define or config); then `di.init()` and `runApp()`.
- **Auth**: `AuthRemoteDataSource` implemented by **Supabase** (Supabase Auth + `profiles` table). Login/register/guest/Google call Supabase; profile is fetched from `profiles` and mapped to `UserModel`; repository caches user locally and returns `Either<Failure, User>`.
- **Splash**: `SplashRepository` uses **Supabase** to check session (`Supabase.instance.client.auth.currentSession`). If session exists, optionally fetch profile and cache user, then return `SplashStatus(isAuthenticated: true, currentUser: user)`. On navigation, splash uses `status.currentUser` so the hardcoded user is removed.
- **Other features** (home, explore, jobs, events, dashboard, boosts): Replace mock remote datasources with **Supabase** implementations that call `Supabase.instance.client.from(...)`. For categories, boost_plans, app_settings use the **cache** as above.
- **Errors**: All Supabase calls go through a central mapper so exceptions and failures are consistent and user-friendly.

---

## 6. Dependency injection and feature flag

- **GetIt** registers:
  - `SupabaseConfig` (or URL/key) and optionally `CacheClient`.
  - `AuthRemoteDataSource` → **Supabase** implementation (e.g. `AuthRemoteDataSourceSupabase`).
  - `SplashRepository` → implementation that uses Supabase for `isAuthenticated()` and profile refresh.
  - Other remote datasources → Supabase (and cache where applicable).
- You can keep a **feature flag** (e.g. `useSupabaseBackend`) so that in development you can switch between mock and Supabase; for production, set it to true and remove mock implementations.

---

## 7. Checklist (you provide from Supabase)

- [ ] **Project URL** and **anon key** from Supabase Dashboard.
- [ ] Schema and optional seed applied; Auth and Storage configured.
- [ ] App config: URL and anon key set via dart-define or env.
- [ ] `Supabase.initialize()` in main; error handling and cache wired as above.
- [ ] Auth and splash use Supabase; current user comes from profile/cache.
- [ ] Static/semi-static data (categories, boost_plans, app_settings) loaded from Supabase with cache (in-memory or persistent) and TTL.

For schema and RLS details, see [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) and [supabase/habra_full_schema.sql](./supabase/habra_full_schema.sql). For client API patterns, see [SUPABASE_CLIENT_INTEGRATION_GUIDE.md](./SUPABASE_CLIENT_INTEGRATION_GUIDE.md).
