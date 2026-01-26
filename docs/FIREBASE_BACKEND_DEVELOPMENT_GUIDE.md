# Firebase Backend Development Guide for Habra Mobile App

This comprehensive guide will walk you through setting up and developing the backend infrastructure for the Habra Mobile App using Firebase ecosystem.

## Table of Contents

1. [Overview](#overview)
2. [Firebase Project Setup](#firebase-project-setup)
3. [Authentication Setup](#authentication-setup)
4. [Cloud Firestore Database Design](#cloud-firestore-database-design)
5. [Firebase Storage Setup](#firebase-storage-setup)
6. [Cloud Functions (Backend Logic)](#cloud-functions-backend-logic)
7. [Security Rules](#security-rules)
8. [Firebase Remote Config](#firebase-remote-config)
9. [Firebase Cloud Messaging (Push Notifications)](#firebase-cloud-messaging-push-notifications)
10. [Analytics & Monitoring](#analytics--monitoring)
11. [Best Practices](#best-practices)
12. [Testing & Deployment](#testing--deployment)

---

## Overview

The Habra Mobile App uses Firebase as its complete backend solution. This includes:

- **Firebase Authentication**: Email/Password and Google Sign-In
- **Cloud Firestore**: NoSQL database for storing app data
- **Firebase Storage**: File storage for images and media
- **Cloud Functions**: Serverless backend logic
- **Firebase Remote Config**: Feature flags and configuration
- **Cloud Messaging**: Push notifications
- **Analytics**: User behavior tracking
- **Crashlytics**: Error monitoring

---

## Firebase Project Setup

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or **"Create a project"**
3. Enter project name: `habra-mobile-app` (or your preferred name)
4. Enable Google Analytics (recommended)
5. Select or create an Analytics account
6. Click **"Create project"**

### Step 2: Add Apps to Firebase Project

#### Android App Setup

1. In Firebase Console, click **"Add app"** → Select **Android**
2. Register your app:
   - **Package name**: `com.habra.habra` (check your `android/app/build.gradle`)
   - **App nickname**: `Habra Android` (optional)
   - **Debug signing certificate SHA-1**: (optional, for Google Sign-In)
3. Download `google-services.json`
4. Place it in `android/app/` directory
5. Update `android/build.gradle`:
   ```gradle
   dependencies {
       classpath 'com.google.gms:google-services:4.4.0'
   }
   ```
6. Update `android/app/build.gradle`:
   ```gradle
   apply plugin: 'com.google.gms.google-services'
   ```

#### iOS App Setup

1. In Firebase Console, click **"Add app"** → Select **iOS**
2. Register your app:
   - **Bundle ID**: `com.habra.habra` (check your `ios/Runner.xcodeproj`)
   - **App nickname**: `Habra iOS` (optional)
3. Download `GoogleService-Info.plist`
4. Open `ios/Runner.xcworkspace` in Xcode
5. Drag `GoogleService-Info.plist` into the `Runner` folder
6. Ensure it's added to the target

---

## Authentication Setup

### Step 1: Enable Authentication Providers

1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable the following providers:

#### Email/Password Authentication

1. Click on **Email/Password**
2. Toggle **Enable** to ON
3. Click **Save**

#### Google Sign-In

1. Click on **Google**
2. Toggle **Enable** to ON
3. Set **Project support email** (your email)
4. Click **Save**

#### Additional Setup for Google Sign-In

**Android:**
- The SHA-1 certificate fingerprint is needed
- Get it using:
  ```bash
  cd android
  ./gradlew signingReport
  ```
- Copy the SHA-1 from the output
- Go to Firebase Console → Project Settings → Your Android App
- Add the SHA-1 fingerprint

**iOS:**
- No additional setup needed for Google Sign-In

### Step 2: Configure OAuth Consent Screen (Google Sign-In)

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Go to **APIs & Services** → **OAuth consent screen**
4. Configure:
   - **User Type**: External (for public apps)
   - **App name**: Habra
   - **User support email**: Your email
   - **Developer contact information**: Your email
5. Add scopes:
   - `email`
   - `profile`
   - `openid`
6. Add test users (for development)
7. Save and continue

### Step 3: Authentication Flow in App

The app already implements:
- Email/Password sign-up and sign-in
- Google Sign-In
- Guest authentication
- User profile creation in Firestore

**User Data Structure:**
```javascript
{
  uid: "user_id_from_firebase_auth",
  email: "user@example.com",
  name: "User Name",
  role: "customer" | "businessOwner" | "admin" | "guest",
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

---

## Cloud Firestore Database Design

### Step 1: Create Firestore Database

1. In Firebase Console, go to **Firestore Database**
2. Click **"Create database"**
3. Choose **"Start in production mode"** (we'll add security rules later)
4. Select a location (choose closest to your users)
5. Click **"Enable"**

### Step 2: Database Schema Design

#### Collections Structure

```
firestore/
├── users/
│   └── {userId}/
│       ├── uid: string
│       ├── email: string
│       ├── name: string
│       ├── role: string
│       ├── phoneNumber?: string
│       ├── profileImageUrl?: string
│       ├── createdAt: Timestamp
│       ├── updatedAt: Timestamp
│       └── preferences?: {
│           ├── notifications: boolean
│           ├── language: string
│           └── theme: string
│       }
│
├── businesses/
│   └── {businessId}/
│       ├── id: string
│       ├── name: string
│       ├── description: string
│       ├── category: string
│       ├── ownerId: string (reference to users)
│       ├── address: {
│       │   ├── street: string
│       │   ├── city: string
│       │   ├── state: string
│       │   ├── zipCode: string
│       │   └── coordinates: GeoPoint
│       ├── phoneNumber: string
│       ├── email: string
│       ├── website?: string
│       ├── images: string[] (Storage URLs)
│       ├── rating: number
│       ├── reviewCount: number
│       ├── isActive: boolean
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── deals/
│   └── {dealId}/
│       ├── id: string
│       ├── businessId: string (reference to businesses)
│       ├── title: string
│       ├── description: string
│       ├── originalPrice: number
│       ├── discountedPrice: number
│       ├── discountPercentage: number
│       ├── validFrom: Timestamp
│       ├── validUntil: Timestamp
│       ├── imageUrl: string
│       ├── category: string
│       ├── isActive: boolean
│       ├── redemptionCount: number
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── events/
│   └── {eventId}/
│       ├── id: string
│       ├── title: string
│       ├── description: string
│       ├── organizerId: string (reference to users/businesses)
│       ├── venue: {
│       │   ├── name: string
│       │   ├── address: string
│       │   └── coordinates: GeoPoint
│       ├── startDate: Timestamp
│       ├── endDate: Timestamp
│       ├── ticketPrice: number
│       ├── availableTickets: number
│       ├── imageUrl: string
│       ├── category: string
│       ├── isActive: boolean
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── reviews/
│   └── {reviewId}/
│       ├── id: string
│       ├── businessId: string (reference to businesses)
│       ├── userId: string (reference to users)
│       ├── rating: number (1-5)
│       ├── comment: string
│       ├── images?: string[]
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
├── orders/
│   └── {orderId}/
│       ├── id: string
│       ├── userId: string (reference to users)
│       ├── type: "event" | "deal"
│       ├── itemId: string (reference to events or deals)
│       ├── quantity: number
│       ├── totalAmount: number
│       ├── status: "pending" | "completed" | "cancelled"
│       ├── paymentMethod: string
│       ├── createdAt: Timestamp
│       └── updatedAt: Timestamp
│
└── notifications/
    └── {notificationId}/
        ├── id: string
        ├── userId: string (reference to users)
        ├── title: string
        ├── body: string
        ├── type: string
        ├── data?: object
        ├── isRead: boolean
        ├── createdAt: Timestamp
        └── updatedAt: Timestamp
```

### Step 3: Create Indexes

Firestore requires composite indexes for complex queries. Create them as needed:

1. Go to **Firestore Database** → **Indexes**
2. Click **"Create Index"**
3. Common indexes needed:
   - `businesses`: `category` + `isActive` + `rating` (descending)
   - `deals`: `businessId` + `isActive` + `validUntil` (ascending)
   - `events`: `startDate` (ascending) + `isActive`
   - `reviews`: `businessId` + `createdAt` (descending)

---

## Firebase Storage Setup

### Step 1: Enable Storage

1. In Firebase Console, go to **Storage**
2. Click **"Get started"**
3. Choose **"Start in production mode"** (we'll add security rules)
4. Select a location (same as Firestore)
5. Click **"Done"**

### Step 2: Storage Structure

Organize files in the following structure:

```
storage/
├── users/
│   └── {userId}/
│       └── profile_image.jpg
│
├── businesses/
│   └── {businessId}/
│       ├── logo.jpg
│       ├── images/
│       │   ├── image1.jpg
│       │   └── image2.jpg
│
├── deals/
│   └── {dealId}/
│       └── deal_image.jpg
│
├── events/
│   └── {eventId}/
│       └── event_image.jpg
│
└── reviews/
    └── {reviewId}/
        └── review_images/
            └── image1.jpg
```

### Step 3: File Upload Best Practices

- **Image Compression**: Compress images before upload
- **File Size Limits**:
  - Profile images: Max 2MB
  - Business images: Max 5MB per image
  - Event/Deal images: Max 3MB
- **Supported Formats**: JPG, PNG, WebP
- **Naming Convention**: Use UUIDs or timestamps for unique filenames

---

## Cloud Functions (Backend Logic)

### Step 1: Install Firebase CLI

```bash
npm install -g firebase-tools
firebase login
```

### Step 2: Initialize Functions

```bash
cd your-project-root
firebase init functions
```

Choose:
- TypeScript or JavaScript (TypeScript recommended)
- ESLint: Yes
- Install dependencies: Yes

### Step 3: Common Cloud Functions

Create functions in `functions/src/index.ts`:

#### Example: User Profile Creation Trigger

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Automatically create user profile in Firestore when user signs up
export const onCreateUser = functions.auth.user().onCreate(async (user) => {
  const userData = {
    uid: user.uid,
    email: user.email || '',
    name: user.displayName || '',
    role: 'customer',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore().collection('users').doc(user.uid).set(userData);

  return null;
});
```

#### Example: Update Business Rating

```typescript
export const updateBusinessRating = functions.firestore
  .document('reviews/{reviewId}')
  .onWrite(async (change, context) => {
    const reviewData = change.after.data();
    const businessId = reviewData?.businessId;

    if (!businessId) return null;

    // Get all reviews for this business
    const reviewsSnapshot = await admin.firestore()
      .collection('reviews')
      .where('businessId', '==', businessId)
      .get();

    let totalRating = 0;
    let count = 0;

    reviewsSnapshot.forEach((doc) => {
      const data = doc.data();
      totalRating += data.rating || 0;
      count++;
    });

    const averageRating = count > 0 ? totalRating / count : 0;

    // Update business document
    await admin.firestore()
      .collection('businesses')
      .doc(businessId)
      .update({
        rating: averageRating,
        reviewCount: count,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    return null;
  });
```

#### Example: Send Notification on New Deal

```typescript
export const notifyNewDeal = functions.firestore
  .document('deals/{dealId}')
  .onCreate(async (snap, context) => {
    const dealData = snap.data();

    // Get all users who have enabled notifications
    const usersSnapshot = await admin.firestore()
      .collection('users')
      .where('preferences.notifications', '==', true)
      .get();

    const messages = usersSnapshot.docs.map((doc) => {
      const userData = doc.data();
      return {
        token: userData.fcmToken, // Store FCM token in user document
        notification: {
          title: 'New Deal Available!',
          body: `${dealData.title} - ${dealData.discountPercentage}% off`,
        },
        data: {
          type: 'deal',
          dealId: context.params.dealId,
        },
      };
    });

    // Send notifications in batches
    const batchSize = 500;
    for (let i = 0; i < messages.length; i += batchSize) {
      const batch = messages.slice(i, i + batchSize);
      await admin.messaging().sendAll(batch);
    }

    return null;
  });
```

### Step 4: Deploy Functions

```bash
firebase deploy --only functions
```

---

## Security Rules

### ⚠️ CRITICAL: Set Up Security Rules First!

**If you're getting "Permission Denied" errors, you MUST set up Firestore Security Rules immediately!**

See **[FIRESTORE_SECURITY_RULES_SETUP.md](./FIRESTORE_SECURITY_RULES_SETUP.md)** for a quick setup guide.

### Firestore Security Rules

Go to **Firestore Database** → **Rules** and update:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && request.auth.uid == userId;
      allow update: if isOwner(userId);
      allow delete: if isOwner(userId);
    }

    // Businesses collection
    match /businesses/{businessId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.ownerId == request.auth.uid;
      allow update: if isAuthenticated() &&
        resource.data.ownerId == request.auth.uid;
      allow delete: if isAuthenticated() &&
        resource.data.ownerId == request.auth.uid;
    }

    // Deals collection
    match /deals/{dealId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }

    // Events collection
    match /events/{eventId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }

    // Reviews collection
    match /reviews/{reviewId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() &&
        request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }

    // Orders collection
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated() &&
        request.resource.data.userId == request.auth.uid;
      allow update: if isOwner(resource.data.userId);
    }

    // Notifications collection
    match /notifications/{notificationId} {
      allow read: if isOwner(resource.data.userId);
      allow create: if isAuthenticated();
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
  }
}
```

### Storage Security Rules

Go to **Storage** → **Rules** and update:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Helper function
    function isAuthenticated() {
      return request.auth != null;
    }

    // User profile images
    match /users/{userId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated() && request.auth.uid == userId;
    }

    // Business images
    match /businesses/{businessId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Deal images
    match /deals/{dealId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Event images
    match /events/{eventId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }

    // Review images
    match /reviews/{reviewId}/{allPaths=**} {
      allow read: if isAuthenticated();
      allow write: if isAuthenticated();
    }
  }
}
```

---

## Firebase Remote Config

### Step 1: Enable Remote Config

1. Go to **Remote Config** in Firebase Console
2. Click **"Get started"**

### Step 2: Add Parameters

Common parameters to add:

- `app_version`: Current app version
- `min_supported_version`: Minimum supported version
- `feature_flags`: Feature toggles
- `api_endpoints`: API configuration
- `maintenance_mode`: Boolean for maintenance mode

### Step 3: Use in App

The app already has `FirebaseRemoteConfig` initialized. Use it like:

```dart
final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.fetchAndActivate();

final minVersion = remoteConfig.getString('min_supported_version');
final isFeatureEnabled = remoteConfig.getBool('feature_flag_name');
```

---

## Firebase Cloud Messaging (Push Notifications)

### Step 1: Setup FCM

1. Go to **Cloud Messaging** in Firebase Console
2. For Android: Upload server key (if using legacy API)
3. For iOS: Upload APNs certificate or key

### Step 2: Request Permissions (in App)

The app already includes `firebase_messaging`. Add permission requests:

**Android**: Already configured in `AndroidManifest.xml`

**iOS**: Add to `ios/Runner/Info.plist`:
```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

### Step 3: Store FCM Token

When user logs in, store their FCM token in Firestore:

```dart
final token = await FirebaseMessaging.instance.getToken();
await FirebaseFirestore.instance
  .collection('users')
  .doc(userId)
  .update({'fcmToken': token});
```

### Step 4: Send Notifications

Use Cloud Functions (see example above) or Firebase Console → Cloud Messaging → Send test message

---

## Analytics & Monitoring

### Step 1: Enable Analytics

Analytics is automatically enabled when you create a Firebase project with Google Analytics.

### Step 2: Track Events

The app already includes `firebase_analytics`. Track custom events:

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'view_item',
  parameters: {
    'item_id': 'business_123',
    'item_name': 'Business Name',
    'item_category': 'Restaurant',
  },
);
```

### Step 3: Crashlytics

Crashlytics is already configured in the app. It automatically reports crashes.

---

## Best Practices

### 1. Data Modeling

- **Denormalize for reads**: Store frequently accessed data together
- **Normalize for writes**: Keep single source of truth
- **Use subcollections**: For one-to-many relationships
- **Index properly**: Create indexes for all query combinations

### 2. Performance

- **Pagination**: Always use `limit()` and pagination
- **Caching**: Use local caching for frequently accessed data
- **Batch operations**: Use batch writes for multiple operations
- **Offline support**: Enable offline persistence

### 3. Security

- **Validate on client and server**: Never trust client-side validation alone
- **Use security rules**: Always implement proper security rules
- **Least privilege**: Give minimum required permissions
- **Regular audits**: Review security rules regularly

### 4. Cost Optimization

- **Read optimization**: Minimize document reads
- **Write optimization**: Batch writes when possible
- **Storage optimization**: Compress images before upload
- **Function optimization**: Keep Cloud Functions lightweight

### 5. Error Handling

- **Retry logic**: Implement retry for network failures
- **Offline handling**: Handle offline scenarios gracefully
- **User feedback**: Show clear error messages
- **Logging**: Log errors for debugging

---

## Testing & Deployment

### Step 1: Testing

1. **Unit Tests**: Test business logic
2. **Integration Tests**: Test Firebase integration
3. **Security Rules Testing**: Use Rules Playground in Firebase Console
4. **Performance Testing**: Monitor Firestore usage

### Step 2: Staging Environment

Create a separate Firebase project for staging:

1. Create new Firebase project: `habra-mobile-app-staging`
2. Configure same structure as production
3. Use different package name/bundle ID for staging app
4. Test all features in staging before production

### Step 3: Deployment Checklist

- [ ] All security rules tested
- [ ] Cloud Functions tested
- [ ] FCM tokens working
- [ ] Analytics tracking events
- [ ] Crashlytics reporting
- [ ] Storage rules configured
- [ ] Firestore indexes created
- [ ] Remote Config parameters set
- [ ] Backup strategy in place

### Step 4: Monitoring

Set up monitoring:

1. **Firebase Console**: Monitor usage, errors, performance
2. **Cloud Functions Logs**: Check function execution logs
3. **Analytics Dashboard**: Track user behavior
4. **Crashlytics Dashboard**: Monitor crashes

---

## Additional Resources

- [Firebase Documentation](https://firebase.google.com/docs)
- [Firestore Best Practices](https://firebase.google.com/docs/firestore/best-practices)
- [Cloud Functions Documentation](https://firebase.google.com/docs/functions)
- [Firebase Security Rules](https://firebase.google.com/docs/rules)
- [FlutterFire Documentation](https://firebase.flutter.dev/)

---

## Support & Troubleshooting

### Common Issues

1. **Authentication not working**: Check SHA-1 fingerprint (Android) or bundle ID (iOS)
2. **Security rules blocking**: Use Rules Playground to test
3. **Queries failing**: Check if indexes are created
4. **Storage upload failing**: Check file size and security rules
5. **Cloud Functions not triggering**: Check function logs and triggers

### Getting Help

- Firebase Support: [Firebase Support](https://firebase.google.com/support)
- Stack Overflow: Tag questions with `firebase` and `flutter`
- GitHub Issues: Report bugs in your repository

---

## Conclusion

This guide provides a comprehensive foundation for developing the Habra Mobile App backend using Firebase. Follow each section step-by-step, test thoroughly, and iterate based on your app's specific needs.

Remember to:
- Start with development/staging environment
- Test security rules thoroughly
- Monitor usage and costs
- Keep documentation updated
- Follow Firebase best practices

Good luck with your backend development! 🚀
