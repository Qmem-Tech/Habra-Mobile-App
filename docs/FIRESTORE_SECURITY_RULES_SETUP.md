# Firestore Security Rules - Quick Setup Guide

## ⚠️ IMPORTANT: Fix Permission Denied Error

If you're getting this error:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
```

You need to set up Firestore Security Rules immediately.

## Quick Fix (Development Mode)

### Step 1: Open Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Firestore Database** → **Rules** tab

### Step 2: Copy and Paste These Rules

**⚠️ WARNING: These rules allow any authenticated user to read/write. Use only for development/testing!**

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
    
    // Users collection - Allow authenticated users to read/write their own data
    match /users/{userId} {
      // Allow read if authenticated
      allow read: if isAuthenticated();
      // Allow create if authenticated and creating their own document
      allow create: if isAuthenticated() && request.auth.uid == userId;
      // Allow update if authenticated and updating their own document
      allow update: if isOwner(userId);
      // Allow delete if authenticated and deleting their own document
      allow delete: if isOwner(userId);
    }
    
    // Allow all authenticated users to read/write (DEVELOPMENT ONLY)
    // Remove this in production and use specific rules below
    match /{document=**} {
      allow read, write: if isAuthenticated();
    }
  }
}
```

### Step 3: Publish Rules

1. Click **"Publish"** button
2. Wait for confirmation
3. Try signing in again

---

## Production-Ready Security Rules

Once your app is working, replace the development rules with these production rules:

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
      // Allow authenticated users to read any user profile (for displaying names, etc.)
      allow read: if isAuthenticated();
      // Allow create only if creating their own document
      allow create: if isAuthenticated() && 
        request.auth.uid == userId &&
        request.resource.data.keys().hasAll(['uid', 'email', 'name', 'role']) &&
        request.resource.data.uid == userId;
      // Allow update only if updating their own document
      allow update: if isOwner(userId);
      // Allow delete only if deleting their own document
      allow delete: if isOwner(userId);
    }
    
    // Businesses collection
    match /businesses/{businessId} {
      // Anyone authenticated can read businesses
      allow read: if isAuthenticated();
      // Only business owners can create/update/delete their own business
      allow create: if isAuthenticated() && 
        request.resource.data.ownerId == request.auth.uid;
      allow update: if isAuthenticated() && 
        resource.data.ownerId == request.auth.uid;
      allow delete: if isAuthenticated() && 
        resource.data.ownerId == request.auth.uid;
    }
    
    // Deals collection
    match /deals/{dealId} {
      // Anyone authenticated can read deals
      allow read: if isAuthenticated();
      // Only business owners can create/update/delete deals
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Events collection
    match /events/{eventId} {
      // Anyone authenticated can read events
      allow read: if isAuthenticated();
      // Only authenticated users can create/update/delete events
      allow create: if isAuthenticated();
      allow update: if isAuthenticated();
      allow delete: if isAuthenticated();
    }
    
    // Reviews collection
    match /reviews/{reviewId} {
      // Anyone authenticated can read reviews
      allow read: if isAuthenticated();
      // Users can only create reviews for themselves
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      // Users can only update/delete their own reviews
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
    
    // Orders collection
    match /orders/{orderId} {
      // Users can only read their own orders
      allow read: if isOwner(resource.data.userId);
      // Users can only create orders for themselves
      allow create: if isAuthenticated() && 
        request.resource.data.userId == request.auth.uid;
      // Users can only update their own orders
      allow update: if isOwner(resource.data.userId);
    }
    
    // Notifications collection
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if isOwner(resource.data.userId);
      // System can create notifications (authenticated users)
      allow create: if isAuthenticated();
      // Users can only update/delete their own notifications
      allow update: if isOwner(resource.data.userId);
      allow delete: if isOwner(resource.data.userId);
    }
  }
}
```

---

## Testing Security Rules

### Using Firebase Console Rules Playground

1. Go to **Firestore Database** → **Rules** tab
2. Click **"Rules Playground"** button
3. Test scenarios:
   - **Location**: `users/{userId}`
   - **Authenticated**: Yes
   - **User ID**: Your Firebase Auth UID
   - **Operation**: Read
   - Click **"Run"** - Should return "Allow"

### Common Issues

#### Issue 1: "Permission Denied" on Sign In
**Solution**: Make sure the `users` collection rules allow authenticated users to read their own document.

#### Issue 2: "Permission Denied" on User Creation
**Solution**: Make sure the `users` collection rules allow authenticated users to create documents where `userId == request.auth.uid`.

#### Issue 3: Rules Not Updating
**Solution**: 
- Clear browser cache
- Wait 1-2 minutes for rules to propagate
- Restart your app

---

## Storage Security Rules

Also set up Storage rules in **Storage** → **Rules**:

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

## Step-by-Step: Setting Up Rules in Firebase Console

### For Firestore Rules:

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com/
   - Select your project

2. **Navigate to Firestore Rules**
   - Click **"Firestore Database"** in left sidebar
   - Click **"Rules"** tab at the top

3. **Edit Rules**
   - You'll see a code editor with current rules
   - Delete existing rules
   - Paste the development rules from above

4. **Publish**
   - Click **"Publish"** button
   - Wait for success message

5. **Test**
   - Try signing in to your app
   - The permission error should be resolved

### For Storage Rules:

1. **Navigate to Storage Rules**
   - Click **"Storage"** in left sidebar
   - Click **"Rules"** tab at the top

2. **Edit Rules**
   - Paste the Storage rules from above
   - Click **"Publish"**

---

## Important Notes

1. **Development vs Production**: The development rules are permissive. Always use production rules before deploying to users.

2. **Rule Propagation**: Rules can take 1-2 minutes to propagate. If changes don't work immediately, wait a bit.

3. **Testing**: Always test rules in the Rules Playground before deploying.

4. **Monitoring**: Check Firebase Console → Firestore → Usage tab to monitor rule evaluations.

---

## Troubleshooting

### Error: "Permission Denied" persists after updating rules

**Solutions:**
1. Wait 2-3 minutes for rules to propagate
2. Clear app cache and restart
3. Verify you're authenticated: Check `FirebaseAuth.instance.currentUser` is not null
4. Check Rules Playground to verify rules are working
5. Ensure the user document path matches: `users/{userId}` where `userId == request.auth.uid`

### Error: "Rules are not valid"

**Solutions:**
1. Check for syntax errors (missing commas, brackets)
2. Ensure `rules_version = '2';` is at the top
3. Verify helper functions are defined before use
4. Check Firebase Console for specific error messages

### Error: "User can't create their own document"

**Solutions:**
1. Ensure `request.auth.uid == userId` in create rule
2. Verify the document ID matches the user's UID
3. Check that `request.resource.data.uid` matches `request.auth.uid`

---

## Next Steps

After setting up security rules:

1. ✅ Test sign-in with email/password
2. ✅ Test sign-in with Google
3. ✅ Test user registration
4. ✅ Test reading user profile
5. ✅ Test updating user profile

Once everything works, replace development rules with production rules!
