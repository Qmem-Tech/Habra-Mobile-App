# RevenueCat Setup Guide

Habra uses RevenueCat for in-app purchases (boost listings, event tickets). RevenueCat is **free** for apps under $2.5M annual revenue.

## 1. Create RevenueCat Account

1. Sign up at [revenuecat.com](https://www.revenuecat.com)
2. Create a new project
3. Add your app (iOS and/or Android)
4. Get your API keys from Project Settings → API Keys

## 2. Configure Products

### For Boost Listings
- In App Store Connect / Google Play Console, create in-app products
- Map product IDs to your boost plans (e.g. `boost_1week`, `boost_4weeks`)
- Add products in RevenueCat dashboard under Products

### For Event Tickets
- Option A: Use consumable products per ticket tier
- Option B: Use a generic "ticket_credit" product
- Configure in RevenueCat and link to your app

## 3. Add API Keys to App

Set environment variables or use a config file (do not commit keys):

```dart
// In main.dart or config
await sl<RevenueCatService>().initialize(
  androidApiKey: const String.fromEnvironment('REVENUECAT_ANDROID_KEY'),
  iosApiKey: const String.fromEnvironment('REVENUECAT_IOS_KEY'),
);
```

Or pass keys at runtime from a secure config service.

## 4. Platform Setup

### iOS
- Enable In-App Purchase capability in Xcode
- Add StoreKit configuration for testing

### Android
- Add `com.android.vending.BILLING` permission (handled by purchases_flutter)
- Set up in-app products in Google Play Console

## 5. Testing

- Use sandbox accounts for testing
- RevenueCat provides test entitlements
- See [RevenueCat testing docs](https://docs.revenuecat.com/docs/test-and-launch)
