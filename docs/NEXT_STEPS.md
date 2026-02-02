# Next Steps – Get the App Running and Fix Issues

Follow these in order. Commands are for a terminal in the project root (`Habra-Mobile-App`).

---

## 1. Environment

- [ ] **Flutter**
  - Run: `flutter doctor`
  - Fix any reported issues (e.g. `flutter doctor --android-licenses` for Android).
- [ ] **Dart**
  - Ensure Dart SDK is in range: `>=3.0.0 <4.0.0` (check with `dart --version`).

---

## 2. Dependencies and Build Runner

- [ ] **Clean**
  - `flutter clean`
- [ ] **Remove build cache** (if problems persist)
  - Delete the `.dart_tool` folder (e.g. `rm -rf .dart_tool` or on Windows: `rmdir /s /q .dart_tool`).
- [ ] **Repair pub cache** (optional but recommended after errors)
  - `flutter pub cache repair`
- [ ] **Get packages**
  - `flutter pub get`
- [ ] **Run code generation**
  - `dart run build_runner build --delete-conflicting-outputs`
  - Or: `flutter pub run build_runner build --delete-conflicting-outputs`

If you still see `build_runner_core` or similar errors, run steps 2 again (clean → delete `.dart_tool` → `pub cache repair` → `pub get` → build_runner).

---

## 3. Localization

- [ ] **Generate l10n**
  - `flutter gen-l10n`
  - Ensures `lib/l10n/` is up to date from `l10n/*.arb`.

---

## 4. Firebase (required for auth and backend features)

- [ ] **Create/use a Firebase project** and enable:
  - Authentication (Email/Password; Google if you use it)
  - Firestore
  - Any other services the app uses (e.g. Storage, Messaging, Analytics, Crashlytics).
- [ ] **Android**
  - Download `google-services.json` from Firebase Console.
  - Put it in `android/app/`.
  - Confirm `android/build.gradle.kts` and `android/app/build.gradle.kts` use the Google Services plugin (see [SETUP_GUIDE.md](SETUP_GUIDE.md)).
- [ ] **iOS** (if you build for iOS)
  - Download `GoogleService-Info.plist`, add it to the Xcode project.
  - Run: `cd ios && pod install && cd ..`

Without Firebase config files, the app may crash on startup when it initializes Firebase.

---

## 5. Run the App

- [ ] **Get dependencies again** (if you added Firebase files or changed config)
  - `flutter pub get`
- [ ] **Run**
  - `flutter run`
  - Or choose a device/emulator in your IDE and run from there.

---

## 6. Verify and Fix Issues

- [ ] **Analyze**
  - `flutter analyze`
  - Fix any reported errors and, if you want, warnings.
- [ ] **Build**
  - Android: `flutter build apk` (or `flutter build appbundle` for Play Store).
  - iOS: `flutter build ios` (then open Xcode if needed).
- [ ] **Manual checks**
  - Splash → Onboarding (if first launch) → Auth (sign in/up) → Home and other tabs.
  - Change language in Settings and confirm UI updates.
  - Confirm no crashes or missing screens.

---

## 7. Optional Cleanups

- **Theme**
  - The app now uses a single light theme (no theme cubit). If you see docs or checklists that still mention “Light/Dark/System” or “Theme Management”, update them (e.g. [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) “Theme Management” section).
- **Assets**
  - `pubspec.yaml` references `assets/icons/habra_app_lcon.png`. If the real file has a different name (e.g. `habra_app_icon.png`), fix the path or rename the file.
- **Git**
  - Commit your changes (e.g. `pubspec.yaml` and any fixes) and push when ready.

---

## Quick Command Summary

```bash
flutter doctor
flutter clean
# Optional: remove .dart_tool, then:
# flutter pub cache repair
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
flutter run
flutter analyze
```

Use this list as a checklist: run each step, fix any errors, then move to the next. After 2–5 and a successful run, you’re in a good state to work on the app and fix remaining issues.
