# Push Notifications Setup

This guide explains how to enable push notifications for the Habra app. When a new job is posted (or other events occur), users receive push notifications on their devices.

**Note:** The app builds and runs without Firebase. Push notifications are disabled by default. To enable them, add the Firebase packages and configuration below.

## Overview

- **In-app notifications**: Stored in Supabase `notifications` table, displayed in the Notifications screen.
- **Push delivery**: Uses Firebase Cloud Messaging (FCM). When a job is created, a database trigger inserts notifications; an Edge Function sends the actual push via FCM.

## 1. Supabase Migrations

Run these in Supabase Dashboard → SQL Editor (in order):

1. **`add_notifications_fcm_token.sql`** – Adds `fcm_token` to `profiles`, `image_url` to `notifications`.
2. **`add_notify_on_new_job_trigger.sql`** – Creates trigger: when a job is inserted, notifications are created for all users with FCM tokens (except the job poster).

## 2. Add Firebase Packages

Add to `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.8.1
  firebase_messaging: ^15.1.5
```

Then run `flutter pub get`. You will also need to restore the full `PushNotificationService` implementation (see git history or re-add Firebase code).

## 3. Firebase Setup

### Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a project (or use existing)
3. Add an **Android** app:
   - Package name: `com.habra.habra` (from `android/app/build.gradle.kts`)
   - Download `google-services.json` → place in `android/app/`

   **Or** use FlutterFire CLI: `dart pub global activate flutterfire_cli` then `flutterfire configure` to auto-generate config files.
4. Add an **iOS** app (if needed):
   - Bundle ID from `ios/Runner/Info.plist`
   - Download `GoogleService-Info.plist` → place in `ios/Runner/`
   - Enable Push Notifications in Xcode capabilities

### Android Configuration

1. Ensure `google-services.json` is in `android/app/`
2. Add the Google services plugin to `android/settings.gradle.kts` and `android/app/build.gradle.kts` (see FlutterFire docs)

### iOS Configuration

1. Add `GoogleService-Info.plist` to `ios/Runner/`
2. In Xcode: Signing & Capabilities → add **Push Notifications**
3. Upload APNs key/certificate to Firebase Console → Project Settings → Cloud Messaging

## 4. App Behavior

- **On login**: The app requests notification permission, gets the FCM token, and stores it in `profiles.fcm_token`.
- **On new job**: The trigger inserts rows into `notifications`. Users see them in the Notifications screen.
- **Push delivery**: Requires a Supabase Edge Function or external webhook that sends FCM messages when notifications are inserted. See below.

## 5. Sending Push via FCM (Optional)

The trigger only inserts into `notifications`. To send actual push notifications when the app is in background:

### Option A: Supabase Edge Function + FCM

1. Create a Supabase Edge Function that:
   - Is triggered by a Database Webhook on `notifications` INSERT
   - Reads the new notification and target `user_id`
   - Fetches `fcm_token` from `profiles` for that user
   - Sends via FCM HTTP v1 API (requires Firebase service account JSON)

2. Store Firebase service account key in Supabase secrets.

### Option B: External Webhook

1. Create a Database Webhook in Supabase: on `notifications` INSERT, POST to your backend URL.
2. Your backend (e.g. Node.js, Vercel) uses Firebase Admin SDK to send FCM.

### FCM Payload Example

```json
{
  "message": {
    "token": "<fcm_token from profiles>",
    "notification": {
      "title": "New Job Posted",
      "body": "A business posted: Server Position"
    },
    "data": {
      "type": "job",
      "action_id": "<job_id>"
    }
  }
}
```

## 6. Notification UI

- **Header**: Habra logo + "Notifications" title
- **Empty state**: Habra logo in a circular badge, "All caught up!" message
- **Cards**: Clean white cards with subtle shadow, type-specific icons

## 7. Troubleshooting

- **Android build fails (missing google-services.json)**: Add the file from Firebase Console, or run `flutterfire configure`. To disable push temporarily, remove the `com.google.gms.google-services` plugin from `android/app/build.gradle.kts` and `android/settings.gradle.kts`.
- **No push when app closed**: Ensure FCM is configured and the Edge Function/webhook is sending.
- **Token not saved**: Check `profiles` has `fcm_token` column; user must be signed in.
- **Firebase init error**: Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). The app will skip push init if Firebase isn't configured.
