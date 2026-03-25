# RevenueCat Setup Guide

Habra uses RevenueCat for in-app purchases (boost listings, event tickets). This project now reads RevenueCat keys from `--dart-define` values.

## 1) RevenueCat project and products

1. Create project in [RevenueCat](https://www.revenuecat.com/).
2. Add Android/iOS apps.
3. Create products in Play Console/App Store Connect.
4. Map those products in RevenueCat.
5. Create at least one entitlement and attach products.

## 2) App configuration (required)

Run the app with:

```bash
flutter run \
  --dart-define=SUPABASE_URL=YOUR_SUPABASE_URL \
  --dart-define=SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY \
  --dart-define=REVENUECAT_ANDROID_API_KEY=YOUR_ANDROID_REVENUECAT_KEY \
  --dart-define=REVENUECAT_IOS_API_KEY=YOUR_IOS_REVENUECAT_KEY
```

Notes:

- Do not commit real keys.
- If RevenueCat keys are missing, `RevenueCatService` remains uninitialized.
- Auth flow now identifies/logs out RevenueCat users using app user id.

## 3) Sandbox test flow (end-to-end)

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

## 4) Validation checklist

- Offerings load successfully.
- Purchase success path works.
- Cancelled purchase path is handled.
- Failed purchase path is handled.
- Entitlements are correct after relaunch.
- RevenueCat customer identity matches app user id.

## 5) Troubleshooting

- No offerings: check product IDs and offerings in RevenueCat.
- Purchase fails: verify sandbox tester setup on store.
- Wrong entitlement: check entitlement-product mapping.
- Missing identity link: confirm user login completed and `identifyUser` ran.
