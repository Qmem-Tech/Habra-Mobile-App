# RevenueCat Setup Guide

> **Integration overview:** [INTEGRATION_DOCUMENT.md](./INTEGRATION_DOCUMENT.md).

Habra uses RevenueCat for in-app purchases (boost listings, event tickets, and
business-owner Pro/Premium subscriptions). **Public SDK keys are set in source:**
`lib/core/config/revenue_cat_sdk_keys.dart` (not `dart_defines.json`).

## 1) RevenueCat project and products

1. Create project in [RevenueCat](https://www.revenuecat.com/).
2. Add Android/iOS apps.
3. Create products in Play Console/App Store Connect.
4. Map those products in RevenueCat.
5. Create at least one entitlement and attach products.

## 2) Which API key to use (critical)

In the RevenueCat dashboard, open **Project settings → API keys**.

- **Use in the mobile app:** the **public** “App specific” / SDK keys (one per Android app, one per iOS app). These are safe to embed in `revenue_cat_sdk_keys.dart`.
- **Never use in the app:** the **Secret** API key. It is for your server only. If you paste it into the app, the SDK will fail with a backend error similar to: **Code 7243 – Secret API keys should not be used in your app.**

## 3) App configuration (required)

1. Open `lib/core/config/revenue_cat_sdk_keys.dart` and set `android` / `ios` to your
   public SDK keys from the RevenueCat dashboard.
2. Run the app with your usual defines (Supabase, etc.), for example:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

Notes:

- Do not commit real keys to a public repo (or keep a private fork for production keys).
- If RevenueCat keys are missing, `RevenueCatService` remains uninitialized.
- Auth flow now identifies/logs out RevenueCat users using app user id.

## 4) Sandbox test flow (end-to-end)

1. Install app in debug/profile build.
2. Sign in with a real account in the app.
3. Open purchase flow (Boosts/Tickets).
4. Complete purchase with sandbox tester:
   - iOS: StoreKit sandbox tester.
   - Android: license test account in Play Console.
5. Verify:
   - Purchase completes in app.
   - RevenueCat dashboard shows customer + transaction.
   - `entitlements.active` contains expected entitlement.
6. Logout/login and verify entitlement state is restored.

## 5) RevenueCat webhook authority for owner subscriptions

Owner subscription state is backend-authoritative via:

- `supabase/functions/revenuecat-subscription-webhook/index.ts`

Configure RevenueCat webhook to call that function URL and set:

- `REVENUECAT_WEBHOOK_AUTH` secret in Supabase
- Same value as Bearer token in RevenueCat webhook Authorization header

Webhook updates profile snapshot fields:

- `owner_tools_subscription_active`
- `owner_tools_subscription_tier`
- `owner_tools_subscription_status`
- `owner_tools_subscription_updated_at`
- `owner_tools_subscription_source = revenuecat`
- `owner_tools_subscription_origin_id`

It also writes timeline rows to `billing_subscription_events` using provider
idempotency (`provider + provider_event_id`).

## 6) Validation checklist

- Offerings load successfully.
- Purchase success path works.
- Cancelled purchase path is handled.
- Failed purchase path is handled.
- Entitlements are correct after relaunch.
- RevenueCat customer identity matches app user id.
- Webhook updates profile fields after purchase/cancel/renew.

## 7) Troubleshooting

- **7243 / “Secret API keys should not be used in your app”:** You configured the **secret** key. Replace with the **public** Android/iOS SDK key from the same API keys page.
- No offerings: check product IDs and offerings in RevenueCat.
- Purchase fails: verify sandbox tester setup on store.
- Wrong entitlement: check entitlement-product mapping.
- Missing identity link: confirm user login completed and `identifyUser` ran.
