# iOS TestFlight & App Store builds

## Why you see “Supabase not configured”

Supabase URL and anon key are **compile-time** values (`String.fromEnvironment` in `AppConfig`). They are **not** read from a file at runtime on the device.

If you archive from Xcode **without** passing `--dart-define-from-file` (or individual `--dart-define` flags), those values are **empty** in the shipped app. TestFlight and the App Store will show the “Supabase not configured” screen.

Local `flutter run` works because VS Code / your launch config uses `dart_defines.json`. The store build you uploaded did not.

## Fix: ship a new build with dart defines

From `Habra-Mobile-App/` (with `dart_defines.json` present and pointing at **production** Supabase):

```bash
chmod +x scripts/build_ios_store.sh
./scripts/build_ios_store.sh
```

Or manually:

```bash
flutter build ipa --release --dart-define-from-file=dart_defines.json
```

Then upload the IPA from `build/ios/ipa/` via **Transporter** or **Xcode → Organizer → Distribute App**.

Increment the build number in Xcode / `pubspec.yaml` before uploading so TestFlight accepts the new binary.

## If you prefer Xcode Archive

You must run a Flutter release build **first** so `ios/Flutter/Generated.xcconfig` contains `DART_DEFINES`:

```bash
flutter build ios --release --dart-define-from-file=dart_defines.json
open ios/Runner.xcworkspace
```

Then in Xcode: **Product → Archive**. Do **not** archive after a clean checkout without that Flutter command.

## Android (same rule)

Play Store / internal testing AABs need the same flags:

```bash
flutter build appbundle --release --dart-define-from-file=dart_defines.json
```

## CI

In Codemagic, GitHub Actions, etc., pass secrets as `--dart-define=SUPABASE_URL=...` or generate `dart_defines.json` from secrets, then always use `--dart-define-from-file` on `flutter build ipa` / `flutter build appbundle`. Never upload a release binary built with plain `flutter build` only.

## Security note

`dart_defines.json` is gitignored. Supabase **anon** and Stripe **publishable** keys are intended to ship inside the client app; protect data with RLS and server-side rules, not by hiding the anon key.
