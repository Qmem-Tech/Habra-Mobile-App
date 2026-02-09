# Habra — Staging and Production Environment Setup

This guide explains how to **set up, use, and work with** separate **staging** and **production** environments for the Habra backend (Supabase) and for the mobile and web apps. Staging is for testing and QA; production is for real users.

| Attribute | Value |
|-----------|--------|
| **Document version** | 1.0 |
| **Last updated** | 2025-02 |
| **Companion docs** | SUPABASE_BACKEND_DESIGN.md, SUPABASE_BACKEND_BUILD_GUIDE.md, SUPABASE_CLIENT_INTEGRATION_GUIDE.md |

---

## Table of Contents

1. [Overview: staging vs production](#1-overview-staging-vs-production)
2. [Supabase: two projects](#2-supabase-two-projects)
3. [Flutter app: staging vs prod config](#3-flutter-app-staging-vs-prod-config)
4. [Web apps: staging vs prod config](#4-web-apps-staging-vs-prod-config)
5. [Day-to-day workflow](#5-day-to-day-workflow)
6. [Testing strategy](#6-testing-strategy)
7. [Checklists](#7-checklists)

---

## 1. Overview: staging vs production

| Environment | Purpose | Supabase | Apps |
|-------------|--------|----------|------|
| **Staging** | Development, QA, integration tests, trying schema changes | Separate Supabase project (e.g. `habra-app-staging`) | App builds that use staging URL + anon key |
| **Production** | Live users only | Separate Supabase project (e.g. `habra-app`) | App builds that use production URL + anon key |

**Rules:**

- **Never** point production app builds at staging Supabase.
- **Never** run destructive or flaky tests against production.
- Apply **schema and config changes to staging first**, validate, then apply to production.
- Keep **production credentials** (URL, anon key, DB password, service_role) in a secure place (secrets manager, CI variables); restrict who can access them.

---

## 2. Supabase: two projects

### Step 2.1: Create both projects in the Dashboard

1. Go to [Supabase Dashboard](https://supabase.com/dashboard).
2. **Staging project**
   - **New project** → Name: `habra-app-staging` (or `habra-staging`).
   - Region: same as production or a region convenient for your team.
   - Set a strong database password; store it (e.g. in a password manager or CI secret). Note the **Project URL** and **anon** key (Settings → API).
3. **Production project**
   - **New project** → Name: `habra-app` (or `habra-prod`).
   - Region: choose the one closest to your users.
   - Set a strong database password and store it securely. Note the **Project URL** and **anon** key.

### Step 2.2: What to configure in each project

Apply the **same** backend setup to both projects (schema, RLS, Auth providers, Storage buckets), but with environment-specific details where needed:

| Item | Staging | Production |
|------|---------|------------|
| **Database schema** | Same as production (run same migrations or SQL) | Same as staging |
| **RLS policies** | Same | Same |
| **Auth → Email** | Confirm email: can disable for faster testing, or keep on | Confirm email: **on** |
| **Auth → Redirect URLs** | Add staging app URLs (e.g. `https://staging.habra.app/auth/callback`, `habra://auth/callback` for mobile, `http://localhost:5173/auth/callback`) | Add **only** production app URLs (e.g. `https://habra.app/auth/callback`, `habra://auth/callback`) |
| **Auth → Site URL** | Staging web URL or `http://localhost:5173` | Production web URL (e.g. `https://habra.app`) |
| **Storage buckets** | Same bucket names and policies | Same |
| **Seed data** | Optional: seed test users, categories, sample businesses | No seed (or minimal reference data only) |
| **Admin user** | Create a test admin (e.g. `admin@staging.habra.app`) | Create real admin(s); restrict who knows the password |

### Step 2.3: Record credentials (do not commit)

Keep a secure list per environment:

**Staging**

- Project URL: `https://<staging-ref>.supabase.co`
- anon key: `eyJ...`
- service_role key: (for scripts/Edge Functions only; store in secrets)
- Database password: (for direct DB access if needed)

**Production**

- Project URL: `https://<prod-ref>.supabase.co`
- anon key: `eyJ...`
- service_role key: (store in secrets only)
- Database password: (store in secrets only)

Use these in app config (see §3 and §4) and in CI/CD as environment variables or secrets.

---

## 3. Flutter app: staging vs prod config

Use one of the approaches below so the app connects to **staging** or **production** Supabase depending on how you build or run it.

### Option A: Flavors (recommended)

Flavors let you have **staging** and **prod** builds with different IDs and config.

1. **Define flavors** in `flutter run` / build and a config class that reads `--dart-define` values.

2. **Config class** (e.g. `lib/core/config/app_config.dart`):

```dart
class AppConfig {
  static const String _env = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isProduction => _env == 'production';
  static bool get isStaging => _env == 'staging';
}
```

3. **Initialize Supabase in `main.dart`**:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await di.init();
  runApp(const MyApp());
}
```

4. **Run or build with the right defines**:

**Staging (local run):**

```bash
flutter run --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL=https://<staging-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<staging-anon-key>
```

**Production (local run):**

```bash
flutter run --dart-define=APP_ENV=production --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

**Build for release (production):**

```bash
flutter build apk --dart-define=APP_ENV=production --dart-define=SUPABASE_URL=https://<prod-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<prod-anon-key>
```

**Build for release (staging, for QA):**

```bash
flutter build apk --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL=https://<staging-ref>.supabase.co --dart-define=SUPABASE_ANON_KEY=<staging-anon-key>
```

Store the actual URL and keys in a **local script** or **CI environment variables**; do not commit them. Example script (gitignored) `scripts/env_staging.sh`:

```bash
export SUPABASE_URL="https://xxxx.supabase.co"
export SUPABASE_ANON_KEY="eyJ..."
# Then: flutter run --dart-define=APP_ENV=staging --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```


### Option B: Environment-specific config files (runtime)

1. Add a config file per environment, e.g. under `assets/config/` (and **gitignore** the files that contain real keys):
   - `assets/config/staging.json`
   - `assets/config/production.json`

2. Example `staging.json`:

```json
{
  "supabase_url": "https://<staging-ref>.supabase.co",
  "supabase_anon_key": "eyJ..."
}
```

3. At startup, decide which file to load (e.g. from a single build-time constant like `kReleaseMode` or a flavor, or from a remote flag). Load the JSON, then call `Supabase.initialize(url: ..., anonKey: ...)`.

4. **Important:** Do not commit production keys. Either use different repos, or only commit placeholder files and fill real values in CI or locally from secrets.

### Option C: Single .env file (development only)

For local dev only, you can use a single `.env` or `config.json` (gitignored) and read it at runtime. Prefer **Option A** for clear staging vs prod builds and for CI.

---

## 4. Web apps: staging vs prod config

Use **separate env files** per environment so the same codebase can point to staging or production Supabase.

### 4.1: Env files (do not commit secrets)

Create (and gitignore if they contain real keys):

- **`.env.staging`** — used when building/running the staging web app
- **`.env.production`** — used when building/running the production web app

**`.env.staging`** (example):

```env
VITE_SUPABASE_URL=https://<staging-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_APP_ENV=staging
```

**`.env.production`** (example):

```env
VITE_SUPABASE_URL=https://<prod-ref>.supabase.co
VITE_SUPABASE_ANON_KEY=eyJ...
VITE_APP_ENV=production
```

Add to **`.gitignore`** (if they contain real keys):

```
.env.staging
.env.production
.env.local
```

Alternatively, commit **templates** (e.g. `.env.staging.example` with placeholder values) and document that developers copy them and fill in keys from a secrets manager.

### 4.2: Build commands

**Vite / Vue / React (Vite):**

- Staging: `cp .env.staging .env` then `npm run build`, or use `vite --mode staging` if you define `mode: 'staging'` and put vars in `.env.staging`.
- Production: `cp .env.production .env` then `npm run build`, or `vite --mode production` with `.env.production`.

**Next.js:**

- Staging: set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` in `.env.staging` or CI for staging builds.
- Production: same variables from `.env.production` or CI for production builds.

**Create Supabase client** (same as in the integration guide):

```ts
const url = import.meta.env.VITE_SUPABASE_URL;
const anonKey = import.meta.env.VITE_SUPABASE_ANON_KEY;
export const supabase = createClient(url, anonKey);
```

### 4.3: Deploy staging and production separately

- **Staging:** Deploy the web app to a staging host (e.g. `staging.habra.app`, Vercel/Netlify preview, or a staging subdomain). Use staging env so the app talks to the **staging** Supabase project.
- **Production:** Deploy to production host (e.g. `habra.app`) with production env so the app talks to the **production** Supabase project.

---

## 5. Day-to-day workflow

### 5.1: Schema or backend changes

1. **Apply to staging first:** Run the new migration (or SQL) in the **staging** Supabase project (Dashboard SQL Editor or `supabase db push` to staging).
2. **Test:** Use the staging app (Flutter build with staging config, or staging web URL) to verify the change (Auth, RLS, new tables, etc.).
3. **Apply to production:** Once validated, run the **same** migration/SQL in the **production** Supabase project. Prefer a short maintenance window if the change is breaking.

### 5.2: App (Flutter or web) changes

1. **Develop** against **staging** (point your local or dev build at staging Supabase).
2. **Test** on staging (manual QA or automated tests hitting staging).
3. **Release to production:** Build the app with **production** config and deploy. Production build must use **production** Supabase URL and anon key only.

### 5.3: Auth redirect URLs

- **Staging Supabase project:** Add redirect URLs for your **staging** web app and for mobile (e.g. `habra://auth/callback`). You can also add `http://localhost:*` for local dev.
- **Production Supabase project:** Add **only** production web URL and production mobile deep link. Do not add staging or localhost URLs in production.

### 5.4: Who uses which environment

| Who | Environment | Supabase project |
|-----|-------------|------------------|
| Developers (local) | Staging | Staging |
| QA / testers | Staging | Staging |
| CI (integration tests) | Staging | Staging |
| Real users | Production | Production |

---

## 6. Testing strategy

- **Unit tests:** No Supabase needed; mock the client or repository. No env distinction.
- **Integration / E2E tests:** Use the **staging** Supabase project only. Point the test app (or test runner) at staging URL + anon key. Seed staging with test data if needed; avoid touching production.
- **Production:** No automated tests that write or delete data. Use production only for live traffic and for read-only monitoring/analytics.

**Summary:** Staging = safe to break and reset; production = real data, change with care.

---

## 7. Checklists

### 7.1: Initial setup (once)

**Supabase**

- [ ] Staging project created; URL and anon key saved securely.
- [ ] Production project created; URL and anon key saved securely.
- [ ] Same schema and RLS applied to both (staging first, then production).
- [ ] Auth (Email, Google, etc.) and Storage configured in both; redirect URLs set per environment.
- [ ] Staging: optional seed data and test admin user. Production: real admin user only; no test seed.

**Flutter**

- [ ] Config class (flavor or env) reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` per environment.
- [ ] Staging and production build/run commands documented (or in scripts) with the correct `--dart-define` values.
- [ ] Keys and URL not committed; use scripts or CI secrets.

**Web (business owner + super admin)**

- [ ] `.env.staging` and `.env.production` (or CI vars) with the correct Supabase URL and anon key for each.
- [ ] Staging deploy uses staging env; production deploy uses production env.
- [ ] Secrets not committed (or only example files committed).

### 7.2: Before releasing to production

- [ ] All changes applied and tested on **staging** (schema, RLS, Auth, app code).
- [ ] Production app build uses **production** Supabase URL and anon key only.
- [ ] Production Supabase redirect URLs contain only production app URLs.
- [ ] Production credentials stored in a secure place; only production deploy pipeline or authorized people have access.

### 7.3: Optional CI/CD

- **On push to main (or release branch):** Run unit tests; run integration tests against **staging** Supabase (inject staging URL and anon key as env vars).
- **Staging deploy:** Build app with staging config; deploy to staging host; app talks to staging Supabase.
- **Production deploy:** Manual or approval-based; build app with **production** config; deploy to production host; app talks to production Supabase. Never use staging keys in production deploy.

---

## Summary

| Item | Staging | Production |
|------|--------|------------|
| **Supabase** | Separate project; same schema/RLS; test data OK | Separate project; same schema/RLS; real data only |
| **Flutter** | Build/run with staging URL + anon key (`--dart-define`) | Build/run with production URL + anon key |
| **Web** | `.env.staging` or staging mode; deploy to staging host | `.env.production` or production mode; deploy to prod host |
| **Tests** | Integration/E2E run against staging | No destructive tests; monitoring only |
| **Workflow** | Change and test on staging first → then apply same change to production |

Keeping staging and production clearly separated lets you test safely and roll out backend and app changes in a controlled way.
