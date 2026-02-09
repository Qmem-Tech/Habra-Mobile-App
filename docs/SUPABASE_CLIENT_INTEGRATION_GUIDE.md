# Habra — Supabase Client Integration Guide (Mobile & Web)

This guide explains how to **integrate the Habra Supabase backend** with the **Flutter mobile app** and with the **business owner** and **super admin web apps**. It assumes the backend is built and tested per [SUPABASE_BACKEND_BUILD_GUIDE.md](./SUPABASE_BACKEND_BUILD_GUIDE.md); design details are in [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md).

| Attribute | Value |
|-----------|--------|
| **Document version** | 1.0 |
| **Last updated** | 2025-02 |
| **Companion docs** | SUPABASE_BACKEND_DESIGN.md, SUPABASE_BACKEND_BUILD_GUIDE.md |

---

## Table of Contents

1. [Overview: one backend, three clients](#1-overview-one-backend-three-clients)
2. [Environment and configuration](#2-environment-and-configuration)
3. [Flutter (mobile app) integration](#3-flutter-mobile-app-integration)
4. [Business owner web app integration](#4-business-owner-web-app-integration)
5. [Super admin web app integration](#5-super-admin-web-app-integration)
6. [Testing client integration](#6-testing-client-integration)
7. [Security reminders](#7-security-reminders)

---

## 1. Overview: one backend, three clients

| Client | Stack | Users | Backend usage |
|--------|--------|--------|----------------|
| **Flutter mobile app** | Dart, supabase_flutter | Community members, Business owners | Same Supabase project: Auth, PostgREST (profiles, businesses, deals, events, jobs, etc.), Storage, optional Realtime |
| **Business owner web app** | React/Vue/Next/vanilla JS + @supabase/supabase-js | Business owners | Same Auth + DB + Storage; RLS limits data to own business |
| **Super admin web app** | React/Vue/Next + @supabase/supabase-js | Admins (`role = admin`) | Same Auth + DB; RLS allows admin to read/update all via `is_admin()` |

All three use the **same Project URL** and **anon key**. No client should ever use the **service_role** key.

---

## 2. Environment and configuration

### 2.1: Keep secrets out of code

- **Do not** commit the anon key or URL in source. Use environment variables or a config file that is gitignored.
- Use different Supabase projects (or at least different keys) for **development**, **staging**, and **production** if you have separate projects.

### 2.2: Flutter — env and flavors

**Option A — compile-time (recommended)**

1. Create a config class that reads from `--dart-define` or a generated file:

```dart
// lib/core/config/supabase_config.dart
class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project-ref.supabase.co',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
}
```

2. Run with defines (store real values in a local script or CI secrets):

```bash
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
```

**Option B — runtime (e.g. from file or remote)**

- Load URL and anon key from a JSON file in assets (e.g. `config.json` in .gitignore) or from a remote config endpoint at startup, then call `Supabase.initialize(url: url, anonKey: anonKey)`.

### 2.3: Web apps — env

Use `.env` (and `.env.local` in .gitignore) with Vite/Next/CRA:

```env
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
```

Create the client once (e.g. in a `lib/supabase.ts` or `src/supabase.js`):

```ts
import { createClient } from '@supabase/supabase-js';

const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
export const supabase = createClient(url, anonKey);
```

---

## 3. Flutter (mobile app) integration

### Step 3.1: Add dependency and initialize

1. **pubspec.yaml**

```yaml
dependencies:
  supabase_flutter: ^2.8.0   # use latest stable
```

2. **Initialize before runApp** (e.g. in `main.dart`)

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,      // or from env
    anonKey: SupabaseConfig.anonKey,
  );

  await di.init();   // your dependency injection
  runApp(const MyApp());
}
```

Reference: [Supabase Flutter docs](https://supabase.com/docs/reference/dart/introduction).

### Step 3.2: Auth — replace Firebase in AuthRemoteDataSource

Keep your existing **AuthRepository** and **use cases**; only the **implementation** of `AuthRemoteDataSource` should switch to Supabase.

**Login (email/password)**

```dart
final response = await Supabase.instance.client.auth.signInWithPassword(
  email: email,
  password: password,
);
if (response.user == null) throw ServerException('Login failed');
final profile = await _fetchProfile(response.user!.id);
return UserModel.fromSupabase(response.user!, profile);
```

**Register (email/password)**

```dart
final response = await Supabase.instance.client.auth.signUp(
  email: email,
  password: password,
  data: {
    'full_name': name,
    'role': role.name,   // 'customer' | 'businessOwner' | 'guest'
  },
);
if (response.user == null) throw ServerException('Registration failed');
// Profile may be created by DB trigger; fetch it
final profile = await _fetchProfile(response.user!.id);
return UserModel.fromSupabase(response.user!, profile);
```

**Google Sign-In**

- Use `google_sign_in` to get id token, then:

```dart
final credential = await GoogleSignIn().signIn();
// ... obtain idToken from credential
final response = await Supabase.instance.client.auth.signInWithIdToken(
  provider: IdProvider.google,
  idToken: idToken,
);
// Then fetch profile as above
```

**Guest (anonymous)**

```dart
final response = await Supabase.instance.client.auth.signInAnonymously();
// Fetch or create profile (role = guest)
```

**Logout**

```dart
await Supabase.instance.client.auth.signOut();
```

**Fetch profile**

```dart
Future<Map<String, dynamic>?> _fetchProfile(String uid) async {
  final res = await Supabase.instance.client
      .from('profiles')
      .select()
      .eq('id', uid)
      .maybeSingle();
  return res;
}
```

Map the profile map to your existing `UserModel` (id, email, name, role). Your domain entity `User` and repository contract stay the same; only the data source implementation changes.

### Step 3.3: Session and splash routing

- **Session:** `Supabase.instance.client.auth.currentSession` (or listen to `auth.onAuthStateChange`).
- **User id:** `Supabase.instance.client.auth.currentUser?.id`.
- After sign-in, fetch `profiles` by that id and read `role`. Route to **Customer** shell (MainNavigationWrapper) or **Business Owner** shell (BusinessOwnerNavigationWrapper) based on `role == 'businessOwner'`. Remove any hardcoded `User` in splash; use the fetched profile to build `User` and pass to the shell.

### Step 3.4: Email verification (business owners)

- Check `Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null` (or your `profiles.email_verified_at` if you mirror it).
- If not verified, show a “Verify your email” banner and a “Resend” button that calls `Supabase.instance.client.auth.resend(type: OtpType.signup)` (or the equivalent resend API).
- Gate access to dashboard or business creation until verified.

### Step 3.5: Data — replace mock remote datasources with Supabase

Use the same **repository interfaces** and **use cases**; implement each remote datasource with Supabase client calls.

**Example: fetch approved businesses (Explore)**

```dart
final res = await Supabase.instance.client
    .from('businesses')
    .select('*')
    .eq('is_active', true)
    .eq('approval_status', 'approved')
    .order('rating', ascending: false);
// RLS already filters; you can add .eq('approval_status', 'approved') for clarity
// Map rows to your domain entities
```

**Example: fetch deals for a business**

```dart
final res = await Supabase.instance.client
    .from('deals')
    .select('*')
    .eq('business_id', businessId)
    .eq('status', 'active');
```

**Example: insert review**

```dart
await Supabase.instance.client.from('reviews').insert({
  'business_id': businessId,
  'user_id': Supabase.instance.client.auth.currentUser!.id,
  'rating': rating,
  'comment': comment,
});
```

**Example: business owner creates deal**

```dart
await Supabase.instance.client.from('deals').insert({
  'business_id': businessId,
  'title': title,
  'description': description,
  'valid_from': validFrom.toIso8601String(),
  'valid_until': validUntil.toIso8601String(),
  'status': 'active',
  // ... other fields
});
```

Use your existing **models** to convert between JSON and domain entities; keep the same repository method signatures so Cubits/Blocs do not change.

### Step 3.6: Storage (avatars, business images, etc.)

**Upload**

```dart
final file = File(localPath);
await Supabase.instance.client.storage
    .from('avatars')
    .upload('${userId}/${filename}', file);
final url = Supabase.instance.client.storage
    .from('avatars')
    .getPublicUrl('${userId}/${filename}');
// Save url to profiles.avatar_url or businesses.logo_url via .from('profiles').update(...)
```

**Download / display**

- Use the public URL from `getPublicUrl`, or use signed URLs for private buckets with `.createSignedUrl()`.

### Step 3.7: Error handling

- Supabase client throws on network or API errors. Catch and map to your app’s `ServerException` or `Failure` (e.g. from `AuthException`, `PostgrestException`).
- Check `response.error` on auth responses when the API returns 200 but with an error payload.
- For RLS violations, you typically get a 403 or a Postgrest error; show a user-friendly message and log the cause.

### Step 3.8: Realtime (optional)

- Subscribe to table changes for live updates (e.g. notifications). Use the Realtime API from `supabase_flutter` (e.g. `Supabase.instance.client.channel(...).onPostgresChanges(...).subscribe()` or the higher-level API documented in [Supabase Realtime docs](https://supabase.com/docs/guides/realtime)).
- Enable Realtime for the table in Supabase Dashboard → Database → Replication.

---

## 4. Business owner web app integration

### Step 4.1: Create Supabase client

Same as §2.3: create a single client with project URL and anon key from env.

### Step 4.2: Auth

- **Sign in:** `supabase.auth.signInWithPassword({ email, password })`.
- **Session:** `supabase.auth.getSession()` and `supabase.auth.onAuthStateChange()`.
- After sign-in, fetch `profiles` by `supabase.auth.getUser().id` and ensure `role === 'businessOwner'`. If not, redirect to a “wrong account” or community page.
- **Sign out:** `supabase.auth.signOut()`.

### Step 4.3: Data (dashboard)

- Same tables as mobile: `businesses`, `deals`, `jobs`, `reviews`, `job_applications`, `boosts`, `boost_plans`.
- RLS ensures the business owner sees only their own businesses and related data. Use the same filters as in Flutter (e.g. list deals where `business_id` is in the owner’s businesses). Example:

```ts
const { data: businesses } = await supabase
  .from('businesses')
  .select('*')
  .eq('owner_id', user.id);

const { data: deals } = await supabase
  .from('deals')
  .select('*')
  .in('business_id', businesses.map(b => b.id));
```

### Step 4.4: Email verification

- Same as Flutter: check `session.user.email_confirmed_at` (or `profiles.email_verified_at`); show “Verify your email” and resend until verified; gate sensitive actions.

---

## 5. Super admin web app integration

### Step 5.1: Auth and role check

- Sign in with `supabase.auth.signInWithPassword({ email, password })`.
- Fetch `profiles` for the current user; if `role !== 'admin'`, redirect away or show “Access denied”. Only allow access to admin routes when `role === 'admin'`.

### Step 5.2: Data (admin)

- **Users:** `supabase.from('profiles').select('*')` — RLS with `is_admin()` allows read/update.
- **Businesses:** List all; filter by `approval_status = 'pending'` for the approval queue. Update with `approval_status`, `reviewed_at`, `reviewed_by`, `rejection_reason`.
- **Deals, events, jobs, reviews:** Read/update as needed; admin policies allow full access.
- **Boost plans:** CRUD on `boost_plans`; read `boosts` for reporting.
- **Audit log:** `supabase.from('audit_log').select('*')` (read-only for admin).
- **App settings:** `supabase.from('app_settings').select('*')` and update as needed.

Use the same anon key; RLS grants access based on `is_admin()`.

---

## 6. Testing client integration

### 6.1: Unit tests — mock Supabase

- In Flutter (or web), inject a **Supabase client mock** (or an abstract interface that wraps the client) into your data sources. In tests, provide a fake that returns fixed data or throws. This keeps repository and use case tests fast and offline.
- Do not use the real anon key in unit tests; use mocks or a test-specific Supabase project.

### 6.2: Integration tests — real backend

- Point the app to a **test/staging** Supabase project (separate from production). Use test users (customer, business owner, admin) and seed data.
- Run flows: sign in → load home → load explore → create review; sign in as business owner → load dashboard → create deal; sign in as admin → approve business. Assert on visible data and absence of RLS errors.
- Flutter: integration tests with `integration_test` package; Web: Cypress/Playwright or similar calling the same Supabase backend.

### 6.3: E2E and manual

- Full E2E: run backend (local or staging) + app and drive UI; verify email and business approval flows with real or test emails and admin actions.

---

## 7. Security reminders

- **Anon key only** in mobile and web clients. It is safe to be public; RLS enforces access.
- **Never** put the **service_role** key in Flutter or web. Use it only in Edge Functions or secure backend scripts.
- **Redirect URLs**: Restrict Auth redirect URLs in Supabase to your real app origins (and localhost for dev) to avoid token theft.
- **HTTPS**: Use HTTPS in production for all clients that talk to Supabase.
- **Role checks**: Always enforce `role === 'businessOwner'` or `role === 'admin'` in the client for route protection; the real enforcement is RLS, but client checks improve UX and avoid unnecessary errors.

---

## Summary

| Step | Mobile (Flutter) | Web (business / admin) |
|------|-------------------|-------------------------|
| Config | Env / dart-define for URL + anon key | .env (VITE_*) for URL + anon key |
| Init | `Supabase.initialize()` in main | `createClient(url, anonKey)` once |
| Auth | Replace Firebase in AuthRemoteDataSource with Supabase Auth; same repository contract | signInWithPassword, getSession, fetch profile, check role |
| Data | Replace mock datasources with supabase.from(...).select/insert/update; same entities | Same .from().select/insert/update; RLS applies |
| Storage | .storage.from(bucket).upload + getPublicUrl / createSignedUrl | Same |
| Routing | Splash: session + profile → route by role | Router guard: profile.role === 'businessOwner' or 'admin' |
| Testing | Mock Supabase in unit tests; real Supabase (staging) in integration tests | Same |

For backend build and RLS details, use [SUPABASE_BACKEND_BUILD_GUIDE.md](./SUPABASE_BACKEND_BUILD_GUIDE.md). For schema and flows, use [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md).
