# QA v2 Release Notes & APK Build

## Supabase Configuration (Required)

The app uses Supabase for auth and backend. **Run** and **build** commands must include the Supabase URL and anon key via `--dart-define`) or the app will throw at startup.

### Run command (development)
```bash
flutter run --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```

Or set in your IDE run configuration (VS Code / Android Studio).

---

## Building the APK for Team Distribution

**Build commands must include the same `--dart-define` flags** so the APK has the correct Supabase configuration baked in.

### Debug APK (for internal testing)
```bash
flutter build apk --debug --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```
Output: `build/app/outputs/flutter-apk/app-debug.apk`

### Release APK (for distribution)
```bash
flutter build apk --release --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Split APKs by ABI (smaller file size per device)
```bash
flutter build apk --release --split-per-abi --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co --dart-define=SUPABASE_ANON_KEY=your_anon_key
```
Output (in `build/app/outputs/flutter-apk/`):
- `app-armeabi-v7a-release.apk` (32-bit ARM)
- `app-arm64-v8a-release.apk` (64-bit ARM, most common)
- `app-x86_64-release.apk` (emulators/x86)

**Recommendation:** Use `--split-per-abi` for smaller downloads. Most phones use `arm64-v8a`. For universal distribution, use `flutter build apk --release` (single APK, larger).

### Using environment variables (optional)
```bash
# Set once
export SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
export SUPABASE_ANON_KEY="eyJ..."

# Then build
flutter build apk --release --dart-define=SUPABASE_URL=$SUPABASE_URL --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY
```

### Before building
1. Update version in `pubspec.yaml` if needed (`version: 1.0.0+1` → `version: 2.0.0+2`)
2. Run `flutter pub get`
3. Run `flutter analyze` (fix any errors)
4. Ensure signing is configured for release (see `android/app/build.gradle`)
5. Replace `YOUR_PROJECT` and `your_anon_key` with your Supabase project URL and anon key

---

## Fix RLS & Storage Issues (One-Time)

If you see errors like "new row violates row-level security policy", "permission denied", or "bucket not found", run this in **Supabase Dashboard → SQL Editor**:

**File:** `docs/supabase/migrations/fix_all_rls_and_storage.sql`

This single script:
- Creates all storage buckets (businesses, events, resumes, legal_documents, avatars, deals, reviews, applicant_photos)
- Applies permissive storage policies so authenticated users can upload
- Ensures `business_legal_documents` table and RLS exist
- Adds `logo_url`, `background_url`, `image_urls` to `businesses` if missing

**Prerequisite:** Main schema (businesses, profiles, etc.) must already be deployed.

---

## QA v2 Document Index

| Document | Purpose |
|---------|---------|
| [QA_CHECKLIST_BUSINESS_OWNER_V2.md](QA_CHECKLIST_BUSINESS_OWNER_V2.md) | Business owner flow – full checklist |
| [QA_CHECKLIST_COMMUNITY_MEMBER_V2.md](QA_CHECKLIST_COMMUNITY_MEMBER_V2.md) | Community member flow – full checklist |
| [QA_Update_files.md](QA_Update_files.md) | Implementation details, migrations, fixes |
| [WEB_APP_BUSINESS_OWNER_IMPLEMENTATION_COPYPASTE.md](WEB_APP_BUSINESS_OWNER_IMPLEMENTATION_COPYPASTE.md) | Copy-paste implementation for Business Owner Web app |

---

## v2 Highlights

### Business Owner
- Dashboard: Summary header (deals, jobs, reviews), tab bar with icons, refresh
- Pull-to-refresh and refresh button on Home
- Add New Presence → new business/location → list updates
- Create Deal/Job/Event with Supabase persistence
- Edit Business, Update Hours, Legal documents
- Event creation with image upload

### Community Member
- Recommendations: "Recommended for you" with All/Businesses/Events/Deals chips
- Explore: Pull-to-refresh
- Directory: Debounced search, refresh button
- Profile: Avatar tap → Edit Profile, overflow handling
- Event checkout: RevenueCat payment (sandbox)
- Layout: Reduced bottom nav and checkout padding

---

*Version: 2.0 | Mar 2025*
