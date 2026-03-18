# Sharing Android APK Build — Habra (Supabase App)

This guide explains how to **build and share** the Habra Android APK for testing, considering that the app uses **Supabase** as its backend.

---

## 1. Supabase App Considerations

The Habra app connects to Supabase at runtime. The **Supabase URL** and **anon key** are **compiled into the APK** via `--dart-define`. This means:

- Each APK build is tied to **one Supabase project** (staging or production).
- Testers **cannot** switch environments without a new build.
- Testers must use **accounts that exist in that Supabase project**.
- Auth, Storage, and Database must be configured in that project.

---

## 2. Build the APK

### 2.1 Staging (for QA / internal testing)

```bash
flutter build apk --dart-define=SUPABASE_URL=https://YOUR_STAGING_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_staging_anon_key
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### 2.2 Production (for external testers / release)

```bash
flutter build apk --dart-define=SUPABASE_URL=https://YOUR_PROD_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_production_anon_key
```

### 2.3 Split APKs by ABI (smaller downloads)

```bash
flutter build apk --split-per-abi --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

Output: `app-armeabi-v7a-release.apk`, `app-arm64-v8a-release.apk`, `app-x86_64-release.apk`

---

## 3. Before Sharing — Supabase Checklist

Ensure the **target Supabase project** is ready:

| # | Check | Notes |
|---|-------|-------|
| 1 | Schema applied | Run `habra_full_schema.sql` in SQL Editor |
| 2 | Storage buckets | Create `avatars`, `businesses`, `deals`, `events`, `reviews`, `resumes` (see `HABRA_SUPABASE_CONFIG.md`) |
| 3 | Auth providers | Enable Email (and Google if needed) |
| 4 | Redirect URLs | Add mobile deep link if using OAuth (e.g. `habra://auth/callback`) |
| 5 | Test data | Seed categories, sample businesses, jobs, deals, events |
| 6 | Test accounts | Create or allow sign-up for testers |

---

## 4. Distribution Options

### Option A: Direct APK Download

1. Upload the APK to a file host (Google Drive, Dropbox, your server).
2. Share the link with testers.
3. Testers enable **Install from unknown sources** (or **Install unknown apps**) for the browser/file manager.
4. Download and install.

**Pros:** Simple, no setup.  
**Cons:** No analytics, manual updates, some users may be wary of unknown sources.

---

### Option B: Firebase App Distribution

1. Add Firebase to the project (optional; can use only App Distribution).
2. Install Firebase CLI: `npm install -g firebase-tools`
3. Login: `firebase login`
4. Add App Distribution: `firebase init` → App Distribution
5. Upload APK:

   ```bash
   firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app YOUR_FIREBASE_APP_ID --groups "testers"
   ```

6. Invite testers via email; they get a link to download and install.

**Pros:** Managed tester list, release notes, easy updates.  
**Cons:** Requires Firebase project setup.

---

### Option C: Google Play Internal Testing

1. Create a Google Play Developer account (one-time fee).
2. Create an app in Play Console.
3. Upload the APK to **Internal testing** track.
4. Add testers by email.
5. Testers install via Play Store link.

**Pros:** Trusted install flow, automatic updates.  
**Cons:** Requires Play Console, review for first release.

---

### Option D: Internal Link (Slack, Email, etc.)

1. Host APK on internal server or cloud storage.
2. Share link in Slack, email, or internal wiki.
3. Include brief instructions (see Section 5).

---

## 5. Tester Instructions (Template)

Provide this to testers when sharing the APK:

---

**Habra Mobile App — Test Build**

1. **Download** the APK from the link below.
2. **Enable installation** from unknown sources:
   - Android: Settings → Security → Unknown sources (or per-app in Android 8+)
   - Or: When prompted, allow your browser/file manager to install apps
3. **Install** the APK.
4. **Sign in** with a test account (we will provide credentials) or sign up if allowed.
5. **Note:** This build connects to our [staging/production] server. Data you create will be stored there.
6. **Report issues** to [your contact/channel].

---

## 6. Security Notes

- **Anon key** is public by design; it is safe to embed in the app. Row Level Security (RLS) protects data.
- **Never** embed the `service_role` key in the app.
- Use **staging** Supabase for QA builds; use **production** only for release builds.
- Restrict **Redirect URLs** in Supabase Auth to your app’s scheme and domains.

---

## 7. Versioning

- Use `version` and `versionCode` in `pubspec.yaml` for each release.
- Include version in release notes so testers know which build they have.

---

## 8. Quick Reference

| Task | Command |
|------|---------|
| Build staging APK | `flutter build apk --dart-define=SUPABASE_URL=<staging-url> --dart-define=SUPABASE_ANON_KEY=<staging-key>` |
| Build prod APK | `flutter build apk --dart-define=SUPABASE_URL=<prod-url> --dart-define=SUPABASE_ANON_KEY=<prod-key>` |
| Split by ABI | Add `--split-per-abi` |
| Output path | `build/app/outputs/flutter-apk/app-release.apk` |

---

*Document version: 1.0 | Project: Habra Mobile App*
