# Habra — Supabase Dashboard Configuration (After Running Schema)

After you run **`habra_full_schema.sql`** in Supabase Dashboard → SQL Editor, complete these steps in the **Dashboard**. The SQL file creates all tables, RLS, and triggers; the steps below configure Auth, URLs, and Storage.

---

## If you ran the schema twice (or got errors)

The schema script is **not idempotent**: running it a second time causes errors (e.g. “type already exists”, “relation already exists”) because it tries to create the same objects again.

**What happened:** The **first** run usually succeeds. The **second** run fails on enums/tables that already exist. Your database is almost certainly in the correct state after the first run; the errors from the second run can be ignored.

**What to do:**

1. **If you only ran it twice and got errors**  
   - You can **do nothing**. The DB should already have the full schema from the first run. Confirm in **Table Editor** that tables like `profiles`, `businesses`, `deals` exist. If they do, continue with the configuration steps below.

2. **If you want a clean slate and to run the schema again (e.g. staging reset)**  
   - Run **`habra_teardown_schema.sql`** in the SQL Editor first. It drops all Habra tables, functions, and enums.  
   - Then run **`habra_full_schema.sql`** **once**.  
   - **Warning:** Teardown deletes all data in those tables. Use only on staging/dev or when you intend to recreate everything.

**Going forward:** Run **`habra_full_schema.sql`** only **once** per project. If you need to change the schema later, add a new migration (e.g. `ALTER TABLE ... ADD COLUMN ...`) instead of re-running the full script.

---

## 1. Authentication — where to find settings

In the Supabase Dashboard, open your **project**, then use the left sidebar:

- Click **Authentication** (or **Auth**). You’ll see sub-pages such as **Providers**, **URL Configuration**, **Email Templates**, **Sessions**, etc. (labels may vary; e.g. “Sign In” or “Sign In / Providers” for providers.)

If your Dashboard looks different, use **Project Settings** (gear icon) → **Auth** or the **Authentication** section and look for **Providers**, **URL Configuration**, and **Email Templates**.

---

## 2. Providers (Email, Google, Anonymous)

1. Go to **Authentication** → **Providers** (or **Sign In** / **Sign In & Providers**).
2. **Email**
   - Open the **Email** provider card.
   - Turn **Email** on (enable the provider).
   - **Confirm email**: Turn **on** for production so new users get a verification link before they can sign in. For staging you can leave it **off** for faster testing. (When off, Supabase treats the email as confirmed automatically.)
   - Save.
3. **Google** (optional)
   - Open the **Google** provider and enable it.
   - Enter **Client ID** and **Client secret** from [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials → create or use an OAuth 2.0 Client ID (Web application). In the client’s **Authorized redirect URIs**, add the callback Supabase shows (e.g. `https://<project-ref>.supabase.co/auth/v1/callback`).
   - Save.
4. **Anonymous** (optional, for guest sign-in)
   - Open the **Anonymous** provider and enable **Allow anonymous sign-ins** if your app has “Continue as guest”.
   - Save.

**Note:** If you see a project-level option **“Allow new users to sign up”**, leave it **on** so sign-ups work. Disable it only if you want to block new sign-ups and allow only existing users to sign in.

---

## 3. URL Configuration (Site URL and Redirect URLs)

1. Go to **Authentication** → **URL Configuration** (a separate page from Providers).
2. **Site URL**
   - This is the default redirect when your app doesn’t pass a specific `redirectTo`. It’s used for email confirmation links and password reset when no `redirectTo` is provided.
   - **Production:** set to your app URL (e.g. `https://habra.app`).
   - **Staging / local:** e.g. `https://staging.habra.app` or `http://localhost:5173`.
3. **Redirect URLs** (allow list)
   - Add every URL (or pattern) where users can land after sign-in, email confirmation, or OAuth. The `redirectTo` value in your app must match an entry in this list. Add one URL per line (or as the UI allows).
   - **Web production:** `https://habra.app/auth/callback` (or your real callback path).
   - **Web staging / local:** `https://staging.habra.app/auth/callback`, `http://localhost:5173/auth/callback`, or `http://localhost:5173/**` for local dev.
   - **Mobile (deep link):** e.g. `habra://auth/callback`, `com.habra.habra://auth/callback` (use your app’s scheme and bundle ID). See [Supabase: Mobile deep linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking).
   - You can use wildcards (e.g. `http://localhost:3000/**`) for preview or local URLs; for production, exact paths are recommended.
4. Save.

---

## 4. Email Templates (optional)

1. Go to **Authentication** → **Email Templates** (or **Templates**).
2. Open the **Confirm signup** template (used when “Confirm email” is on).
   - Edit **Subject** and **Body** if you want custom copy.
   - In the body, use `{{ .ConfirmationURL }}` for the confirmation link. Alternatives: `{{ .SiteURL }}` (your Site URL) or `{{ .RedirectTo }}` (the redirect passed from your app). For email confirmation, `{{ .ConfirmationURL }}` is usually best.
3. Save.

Reference: [Supabase Email Templates](https://supabase.com/docs/guides/auth/auth-email-templates).

**Supabase docs (if the Dashboard layout changes):** [Redirect URLs](https://supabase.com/docs/guides/auth/redirect-urls), [General configuration](https://supabase.com/docs/guides/auth/general-configuration).

---

## 5. Storage — Create buckets and policies

The SQL file does **not** create Storage buckets; do this in the Dashboard.

1. Go to **Storage**.
2. Create these buckets (click **New bucket**):

| Bucket name   | Public bucket | Purpose                |
|---------------|---------------|------------------------|
| `avatars`     | No            | User profile photos    |
| `businesses`  | Yes (or No)   | Business logos/gallery |
| `deals`       | Yes           | Deal images            |
| `events`      | Yes           | Event images           |
| `reviews`     | No            | Review photos          |
| `resumes`     | No            | Job application files  |

3. For each bucket, open it → **Policies** → **New policy** (or use “For full customization” and add policies below).

**Suggested policies (Storage RLS):**

- **avatars**
  - **SELECT**: `bucket_id = 'avatars'` and `auth.role() = 'authenticated'`.
  - **INSERT/UPDATE**: `bucket_id = 'avatars'` and `auth.uid()::text = (storage.foldername(name))[1]` (path like `{user_id}/file.jpg`).

- **businesses**
  - **SELECT**: `bucket_id = 'businesses'` (and optionally restrict to authenticated).
  - **INSERT/UPDATE**: `bucket_id = 'businesses'` and authenticated; for strict ownership you’d need a custom check (e.g. first folder = business_id and user is owner in DB). For simplicity you can allow authenticated users to insert/update and enforce ownership in the app.

- **deals**, **events**: Same idea — allow read; restrict write to authenticated (and ideally to owner/organizer in app or via a small Edge Function).

- **reviews**: **SELECT** for authenticated; **INSERT/UPDATE** for authenticated with path matching the user’s review.

- **resumes**
  - **SELECT/INSERT/UPDATE**: `bucket_id = 'resumes'` and `auth.uid()::text = (storage.foldername(name))[1]`.

You can start with “Allow all for authenticated” and tighten later with custom policies.

---

## 6. Create the first admin user

The schema does **not** create any user. Admins are normal users with `profiles.role = 'admin'`.

1. **Option A — From the app**
   - Sign up a user (e.g. your email) via your app, or in the Dashboard go to **Authentication** → **Users** → **Add user** (or **Invite**).
   - In **Table Editor** → `public.profiles`, find the row with that user’s `id` and set **role** to `admin`.
2. **Option B — SQL**
   - After signing up once, run in SQL Editor (replace with the real user id from `auth.users`):
   ```sql
   UPDATE public.profiles SET role = 'admin' WHERE id = '<your-user-uuid>';
   ```

Do **not** allow self-sign-up as admin from the app; keep admin creation manual or via a one-off script.

---

## 7. (Optional) Seed data

You can seed **categories**, **boost_plans**, and **app_settings** in two ways.

### Option A — SQL file (recommended)

1. Open **`docs/supabase/habra_seed.sql`** in this repo.
2. Copy its contents and run them in **Supabase Dashboard → SQL Editor** (after you’ve run `habra_full_schema.sql`).
3. The script inserts:
   - **Categories:** Restaurant, Cafe, Retail, Events & Entertainment, Health & Beauty, Professional Services, Food & Grocery, Arts & Culture.
   - **Boost plans:** Starter, Growth, Pro, Scale (with price and duration).
   - **App settings:** `maintenance_mode`, min app versions, feature flags for boosts and messages.
4. **Re-running:** Categories and app_settings use `ON CONFLICT`, so safe to run again. Boost_plans has no unique constraint — run once, or truncate `boost_plans` before re-running if you need to re-seed.

### Option B — JSON file (reference or scripts)

- **`docs/supabase/habra_seed_data.json`** contains the same data in JSON form.
- Use it as reference, or in a small script (e.g. Node/Deno) that reads the JSON and calls the Supabase client to insert rows. The SQL file is the canonical way to seed via the Dashboard.

---

## 8. Get API keys for your app

1. Go to **Project Settings** (gear icon in the left sidebar or top) → **API** (under **Project API** or **Configuration**).
2. Copy:
   - **Project URL** (e.g. `https://xxxx.supabase.co`).
   - **anon** / **anon public** key — use this in Flutter and web apps (never commit; use env or dart-define).
3. **service_role** key: use only in Edge Functions or secure backend scripts; never in mobile or web clients.

---

## Checklist (after schema + config)

- [ ] `habra_full_schema.sql` run in SQL Editor with no errors.
- [ ] Auth: Email (and optionally Google, Anonymous) enabled; Confirm email set as needed.
- [ ] Auth: Site URL and Redirect URLs set for your app and mobile scheme.
- [ ] Storage: Buckets created (avatars, businesses, deals, events, reviews, resumes); policies added.
- [ ] First admin: one user’s `profiles.role` set to `admin`.
- [ ] (Optional) Seed: run `habra_seed.sql` in SQL Editor, or use `habra_seed_data.json` in a script.
- [ ] Project URL and anon key saved for Flutter and web app config (staging vs production).

For full backend and client flow, see **SUPABASE_BACKEND_DESIGN.md**, **SUPABASE_BACKEND_BUILD_GUIDE.md**, and **SUPABASE_CLIENT_INTEGRATION_GUIDE.md** in the `docs/` folder.
