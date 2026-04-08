# Habra — Integration Document

Single reference for **third-party services**: how keys reach the app, what to configure outside the repo, and where to go for deep dives.

---

## Table of contents

1. [Purpose & scope](#1-purpose--scope)
2. [Configuration model](#2-configuration-model)
3. [Compile-time keys (reference)](#3-compile-time-keys-reference)
4. [Supabase (baseline)](#4-supabase-baseline)
5. [Google Sign-In](#5-google-sign-in)
6. [RevenueCat](#6-revenuecat)
7. [Stripe (event checkout)](#7-stripe-event-checkout)
8. [Push notifications (FCM)](#8-push-notifications-fcm)
9. [Master checklist](#9-master-checklist)
10. [Verify & build](#10-verify--build)
11. [Related documentation](#11-related-documentation)

---

## 1. Purpose & scope

| Integration | Role in Habra |
|-------------|----------------|
| **Supabase** | Auth, database, Edge Functions — required for a normal run |
| **Google Sign-In** | Optional OAuth via Supabase |
| **RevenueCat** | IAP (boosts, tickets, optional business-owner gate) |
| **Stripe** | PaymentSheet for event checkout (client + server function) |
| **Firebase / FCM** | Optional; push is stubbed until you wire FCM |

---

## 2. Configuration model

- Values are **not** loaded from `.env` at runtime in this project.
- Flutter embeds them at **compile time** via:
  - `--dart-define=KEY=value`, or
  - **`--dart-define-from-file=dart_defines.json`** (recommended).

**Setup once**

1. Copy **`dart_defines.example.json`** → **`dart_defines.json`** (gitignored).
2. Fill real values.
3. Run and build with the same file:

```bash
flutter run --dart-define-from-file=dart_defines.json
flutter build apk --release --dart-define-from-file=dart_defines.json
```

**Supabase Auth URLs:** whatever you set as `SUPABASE_AUTH_REDIRECT_URL` (default `habra://auth/callback`) must be listed under Supabase → Authentication → URL Configuration → Redirect URLs. Deep links on Android/iOS must open that scheme.

---

## 3. Compile-time keys (reference)

| Key | Required? | Purpose | Code location |
|-----|-----------|---------|----------------|
| `SUPABASE_URL` | **Yes** (to run) | Project URL | `lib/core/supabase/supabase_config.dart` |
| `SUPABASE_ANON_KEY` | **Yes** | Public anon key | same |
| `SUPABASE_AUTH_REDIRECT_URL` | No | Email / callback scheme | same (default `habra://auth/callback`) |
| `GOOGLE_WEB_CLIENT_ID` | No (recommended Android) | Web OAuth client → `GoogleSignIn(serverClientId: …)` | `lib/features/auth/data/datasources/auth_supabase_remote_datasource.dart` |
| `REVENUECAT_ANDROID_API_KEY` | For IAP on Android | RevenueCat SDK | `lib/main.dart` → `RevenueCatService` |
| `REVENUECAT_IOS_API_KEY` | For IAP on iOS | RevenueCat SDK | same |
| `BUSINESS_OWNER_SUBSCRIPTION_MODE` | No | `off` (default), `revenuecat`, `profile`, `stub_locked` | `lib/core/config/business_subscription_config.dart` |
| `REVENUECAT_BUSINESS_ENTITLEMENT_ID` | If mode = `revenuecat` | Entitlement id | same (default `business_owner_tools`) |
| `STRIPE_PUBLISHABLE_KEY` | For Stripe UI | `pk_test_…` / `pk_live_…` | `lib/main.dart` → `StripePaymentService` |
| `STRIPE_MERCHANT_ID` | Apple Pay on iOS | Merchant identifier | same |
| `STRIPE_PAYMENT_INTENT_FUNCTION` | No | Edge Function name | default `create-event-payment-intent` — `lib/core/services/stripe_payment_service.dart` |

---

## 4. Supabase (baseline)

**Purpose:** Auth, data, and serverless functions the app already calls.

**You configure (dashboard)**

- Project URL + anon key → `dart_defines.json`.
- Authentication → URL Configuration → redirect URLs for your app scheme / web callbacks.
- SQL schema and RLS from `docs/supabase/` as applicable.

**If misconfigured:** App shows **Supabase not configured** and does not reach the main UI (`lib/main.dart`).

---

## 5. Google Sign-In

| | |
|--|--|
| **Purpose** | Sign in / sign up with Google via Supabase |
| **In the app** | Implemented: `google_sign_in` → `signInWithIdToken` |
| **Keys** | Optional: `GOOGLE_WEB_CLIENT_ID` (Web client ID, same as in Supabase) |

**Configure (external)**

1. **Google Cloud Console** — OAuth consent screen; create clients:
   - **Web** — Redirect: `https://<PROJECT-REF>.supabase.co/auth/v1/callback`
   - **Android** — Package `com.habra.habra`, SHA-1 (`cd android && ./gradlew signingReport`)
   - **iOS** — Bundle `com.habra.habra` (if you ship iOS)
2. **Supabase** — Authentication → Providers → Google: enable; Web Client ID + Secret; add Android/iOS client IDs in “Client IDs”; iOS: enable **Skip nonce check**.
3. **App** — Add `GOOGLE_WEB_CLIENT_ID` to `dart_defines.json` to avoid common Android token issues.
4. **Database** — Trigger (e.g. `handle_new_user`) must create `profiles` for new users.

**Verify:** Tap “Sign in with Google”; session + profile load.

**Deep dive:** [GOOGLE_SIGNIN_SETUP.md](./GOOGLE_SIGNIN_SETUP.md) (iOS URL scheme, troubleshooting table).

---

## 6. RevenueCat

| | |
|--|--|
| **Purpose** | In-app purchases (boosts, tickets; optional business-owner subscription gate) |
| **In the app** | `purchases_flutter` + `RevenueCatService` |
| **Keys** | `REVENUECAT_ANDROID_API_KEY`, `REVENUECAT_IOS_API_KEY`; optional `BUSINESS_OWNER_SUBSCRIPTION_MODE`, `REVENUECAT_BUSINESS_ENTITLEMENT_ID` |

**Configure (external)**

1. [RevenueCat](https://www.revenuecat.com/) project; add Android/iOS apps.
2. Store products in Play Console / App Store Connect; map in RevenueCat; offerings + entitlements.
3. Put public SDK keys in `dart_defines.json`.

**Behavior if keys missing:** RevenueCat does not initialize; app otherwise runs.

**Verify:** Offerings load; sandbox purchase; entitlement after relaunch.

**Deep dive:** [REVENUECAT_SETUP.md](./REVENUECAT_SETUP.md).

---

## 7. Stripe (event checkout)

| | |
|--|--|
| **Purpose** | Card (and optionally Apple Pay) checkout via PaymentSheet |
| **In the app** | `flutter_stripe` + `StripePaymentService` |
| **Keys** | `STRIPE_PUBLISHABLE_KEY`; `STRIPE_MERCHANT_ID` (iOS Apple Pay); `STRIPE_PAYMENT_INTENT_FUNCTION` if your function name differs |

**Configure (external)**

1. Stripe Dashboard → publishable key → `dart_defines.json`.
2. Deploy Supabase Edge Functions:
   - `create-event-payment-intent` (creates/reuses PaymentIntent, returns PaymentSheet session)
   - `stripe-event-webhook` (Stripe webhook: finalizes order states)
   - `refund-event-order` (support/admin initiated refunds)
3. **Never** ship secret keys or webhook secrets in the mobile app.

**Behavior if publishable key empty:** Stripe uninitialized; checkout fails until configured.

**Verify:** Create order → PaymentSheet opens → Stripe webhook marks order `completed` → app transitions from processing to success.

---

## 8. Push notifications (FCM)

| | |
|--|--|
| **Purpose** | Device push when notifications are created (e.g. new job) |
| **In the app today** | **`PushNotificationService`** initializes FCM, syncs `profiles.fcm_token`, foreground local notifications, deep links via `NotificationDeepLinkRouter`; degrades if Firebase/native config is missing |
| **Keys** | No `dart-define` for FCM; use `lib/firebase_options.dart` (run `flutterfire configure`), `google-services.json` when present, and iOS `GoogleService-Info.plist` |

**Project setup (still required for production)**

1. **SQL** (Supabase, in order):  
   `docs/supabase/migrations/add_notifications_fcm_token.sql`  
   `docs/supabase/migrations/add_notify_on_new_job_trigger.sql`
2. **Dependencies:** `firebase_core`, `firebase_messaging`, `flutter_local_notifications` in `pubspec.yaml` (already added).
3. **Android:** add `android/app/google-services.json`; the Google Services Gradle plugin applies only when that file exists.
4. **iOS:** `GoogleService-Info.plist`, Push capability, Background **Remote notifications**, APNs key in Firebase; `Runner.entitlements` includes `aps-environment`.
5. **Delivery:** webhook or Edge Function to send FCM HTTP v1 on `notifications` insert (`data` keys documented in [PUSH_NOTIFICATIONS_SETUP.md](./PUSH_NOTIFICATIONS_SETUP.md)).

**Deep dive:** [PUSH_NOTIFICATIONS_SETUP.md](./PUSH_NOTIFICATIONS_SETUP.md).

---

## 9. Master checklist

Use this before testing each area end-to-end.

- [ ] **Supabase:** `SUPABASE_URL`, `SUPABASE_ANON_KEY`; redirect URLs; schema/RLS as needed  
- [ ] **Google:** OAuth clients; Supabase Google provider; `GOOGLE_WEB_CLIENT_ID` (recommended)  
- [ ] **RevenueCat:** keys in `dart_defines.json`; products, offerings, entitlements; sandbox testers  
- [ ] **Stripe:** publishable key; Edge Function deployed; merchant ID if Apple Pay  
- [ ] **Push:** `flutterfire configure` / real `firebase_options` + native Firebase files; Supabase SQL; Edge Function or webhook FCM sender; test token in `profiles.fcm_token`  

---

## 10. Verify & build

```bash
flutter pub get
flutter analyze
flutter run --dart-define-from-file=dart_defines.json
```

Release builds must use the **same** defines as debug so Supabase and payments point at the right environment.

---

## 11. Related documentation

| Topic | Document |
|--------|-----------|
| Google Sign-In detail | [GOOGLE_SIGNIN_SETUP.md](./GOOGLE_SIGNIN_SETUP.md) |
| RevenueCat sandbox & troubleshooting | [REVENUECAT_SETUP.md](./REVENUECAT_SETUP.md) |
| FCM, SQL, payloads | [PUSH_NOTIFICATIONS_SETUP.md](./PUSH_NOTIFICATIONS_SETUP.md) |
| QA / release defines | [QA_V2_RELEASE_NOTES.md](./QA_V2_RELEASE_NOTES.md) |
| APK distribution & defines | [ANDROID_APK_DISTRIBUTION.md](./ANDROID_APK_DISTRIBUTION.md) |
| Key template (copy to `dart_defines.json`) | [`../dart_defines.example.json`](../dart_defines.example.json) |
| Legal docs: bucket + `storage_path` contract (Flutter) | [`lib/core/constants/legal_document_storage.dart`](../lib/core/constants/legal_document_storage.dart) |
| Legal docs: DB columns migration (existing projects) | [`supabase/migrations/add_business_legal_documents_storage_columns.sql`](./supabase/migrations/add_business_legal_documents_storage_columns.sql) |
