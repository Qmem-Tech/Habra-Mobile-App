# Google Sign-In Setup for Habra Mobile App

The app **already has Google Sign-In implemented** in code. You only need to configure **Google Cloud Console** and **Supabase Dashboard**. No app code changes are required.

---

## What's Already in the App

- **Sign In page**: "Sign In with Google" button
- **Sign Up options**: "Continue with Google" button
- **Flow**: Uses `google_sign_in` → gets ID token → `Supabase.auth.signInWithIdToken()`
- **Profile creation**: `handle_new_user` trigger creates a row in `profiles` (ensure your schema has this)

---

## Step 1: Google Cloud Console

### 1.1 Create or select a project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one

### 1.2 Configure OAuth consent screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** (for public users)
3. Fill in:
   - App name: **Habra**
   - User support email: your email
   - Developer contact: your email
4. Add scopes (if not already present):
   - `openid` (add manually)
   - `.../auth/userinfo.email` (default)
   - `.../auth/userinfo.profile` (default)
5. Save

### 1.3 Create OAuth 2.0 credentials

You need **three** client IDs:

#### A. Web application (for Supabase)

1. Go to **APIs & Services** → **Credentials** → **Create Credentials** → **OAuth client ID**
2. Application type: **Web application**
3. Name: e.g. `Habra Web`
4. **Authorized redirect URIs** → Add:
   ```
   https://<YOUR-PROJECT-REF>.supabase.co/auth/v1/callback
   ```
   Replace `<YOUR-PROJECT-REF>` with your Supabase project reference (e.g. `abcdefghij` from `https://abcdefghij.supabase.co`)
5. Click **Create**
6. **Save the Client ID and Client Secret** — you'll add these to Supabase

#### B. Android (for the mobile app)

1. **Create Credentials** → **OAuth client ID**
2. Application type: **Android**
3. Name: e.g. `Habra Android`
4. Package name: `com.habra.habra`
5. SHA-1 certificate fingerprint:
   - **Debug**: Run in project root:
     ```bash
     cd android && ./gradlew signingReport
     ```
     Look for `SHA1` under `Variant: debug`. Or use:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - **Release**: Use your release keystore's SHA-1
6. Click **Create**
7. **Save the Android Client ID**

#### C. iOS (if you build for iOS)

1. **Create Credentials** → **OAuth client ID**
2. Application type: **iOS**
3. Name: e.g. `Habra iOS`
4. Bundle ID: `com.habra.habra`
5. Click **Create**
6. **Save the iOS Client ID**

---

## Step 2: Supabase Dashboard

1. Go to your Supabase project → **Authentication** → **Providers**
2. Open the **Google** provider
3. Enable it
4. Fill in:
   - **Client ID**: Paste the **Web application** Client ID from Step 1.3.A
   - **Client Secret**: Paste the **Web application** Client Secret from Step 1.3.A
5. **Client IDs** (optional but recommended for native apps):
   - Add the **Android Client ID** from Step 1.3.B
   - Add the **iOS Client ID** from Step 1.3.C (if you use iOS)
   - Format: comma-separated, e.g. `123-android.apps.googleusercontent.com,456-ios.apps.googleusercontent.com`
6. For **iOS**: Enable **Skip nonce check** (recommended for Flutter)
7. Save

---

## Step 3: Optional — Android server client ID

For more reliable token validation, you can pass the Web Client ID to `google_sign_in` on Android. This is optional; the default config often works.

If you see errors like "idpConfig is invalid" or token validation fails, add:

```dart
// In auth_supabase_remote_datasource.dart
GoogleSignIn get _googleSignIn => GoogleSignIn(
  serverClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
);
```

Use the **Web application** Client ID (the same one you put in Supabase).

---

## Step 4: iOS — URL scheme (if needed)

If Google Sign-In fails on iOS, you may need to add the reversed client ID as a URL scheme. After creating the iOS OAuth client, Google provides a `REVERSED_CLIENT_ID` (e.g. `com.googleusercontent.apps.123456789-xxxx`).

Add to `ios/Runner/Info.plist` (you already have `CFBundleURLTypes` for `habra`; add another dict for Google):

```xml
<key>CFBundleURLTypes</key>
<array>
  <!-- Existing habra scheme -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>habra</string>
    </array>
    <key>CFBundleURLName</key>
    <string>auth</string>
  </dict>
  <!-- Google Sign-In (replace with your REVERSED_CLIENT_ID) -->
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
    </array>
    <key>CFBundleURLName</key>
    <string>Google Sign-In</string>
  </dict>
</array>
```

You get `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` if you use Firebase, or from the iOS OAuth client in Google Cloud Console.

---

## Checklist

- [ ] Google Cloud: OAuth consent screen configured
- [ ] Google Cloud: Web application client created (redirect URI = Supabase callback)
- [ ] Google Cloud: Android client created (package `com.habra.habra`, SHA-1)
- [ ] Google Cloud: iOS client created (bundle `com.habra.habra`) — if building for iOS
- [ ] Supabase: Google provider enabled
- [ ] Supabase: Web Client ID and Secret added
- [ ] Supabase: Android (and iOS) Client IDs added under "Client IDs"
- [ ] Supabase: "Skip nonce check" enabled for iOS
- [ ] Database: `handle_new_user` trigger creates `profiles` row on sign-up (including Google)

---

## Testing

1. Run the app: `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
2. Tap "Sign In with Google" or "Continue with Google"
3. Select a Google account
4. You should be signed in and see the home screen

---

## Troubleshooting

| Error | Fix |
|------|-----|
| "idpConfig is invalid" | Add Web Client ID to `GoogleSignIn(serverClientId: '...')` on Android |
| "Developer Error" on Android | Check package name (`com.habra.habra`) and SHA-1 in Google Cloud |
| "Profile not found" | Ensure `handle_new_user` trigger exists and creates `profiles` row |
| iOS sign-in fails | Add reversed client ID to `Info.plist`; enable "Skip nonce check" in Supabase |
