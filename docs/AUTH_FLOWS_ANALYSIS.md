# Authentication Flows — End-to-End Analysis

This document analyzes the sign-up confirmation, email verification, forgot password, and Google authentication flows in the Habra Mobile App. It identifies what works, what is missing, and what is required for full end-to-end functionality.

---

## Executive Summary

| Flow | Status | Gaps |
|------|--------|------|
| **Sign-up confirmation** | ✅ Partially working | Deep link config missing; post-confirm UX unclear |
| **Email verification** | ✅ Working (in-app) | Deep link handling not configured; no "I've verified" flow |
| **Forgot password** | ❌ Not implemented | No Supabase integration; wrong UX flow |
| **Google authentication** | ⚠️ Code ready | Requires Supabase + Google Cloud config |

---

## 1. Sign-Up Confirmation Flow

### Current Implementation

**Data flow:**
1. User fills `EmailSignUpPage` (name, email, password, role).
2. `AuthCubit.register()` → `RegisterUseCase` → `AuthSupabaseRemoteDataSource.register()`.
3. `_client.auth.signUp()` is called with `data: {'full_name': name, 'role': roleString}`.
4. When Supabase has **"Confirm email"** enabled:
   - `response.session == null` and `response.user != null`.
   - App throws `EmailVerificationRequiredException(email)`.
5. `AuthRepositoryImpl` maps this to `EmailVerificationPendingFailure(email)`.
6. `AuthCubit` emits `AuthEmailVerificationPending(email)`.
7. `EmailSignUpPage` navigates to `EmailVerificationPage(email)`.

**Files involved:**
- `lib/features/auth/data/datasources/auth_supabase_remote_datasource.dart` (lines 79–103)
- `lib/features/auth/presentation/pages/email_sign_up_page.dart` (lines 89–95)
- `lib/features/auth/presentation/pages/email_verification_page.dart`

### What Works

- Sign-up with email/password.
- Detection of "email confirmation required" when Supabase sends the confirmation email.
- Redirect to `EmailVerificationPage` with instructions and resend button.
- Resend verification via `supabase.auth.resend(type: OtpType.signup, email: email)`.

### Gaps

1. **Deep link not configured**

   Supabase sends the confirmation email with a link. When the user taps it:
   - Supabase expects the link to redirect to a URL in the **Redirect URLs** list (e.g. `habra://auth/callback`).
   - The app must be able to receive that URL (deep link).

   **Current state:** Android `AndroidManifest.xml` and iOS `Info.plist` do **not** declare a custom URL scheme or intent-filter for `habra://` (or similar). The app cannot receive the confirmation link.

2. **Post-confirmation UX**

   After the user taps the link:
   - Supabase confirms the user and redirects to the URL (with tokens in the hash).
   - `supabase_flutter` v2+ uses PKCE by default and can restore the session from the URL.
   - If the app is opened via deep link, Supabase should restore the session.

   The app does not explicitly listen for `auth.onAuthStateChange` or handle deep links. Supabase Flutter may auto-handle this if the platform config is correct, but the platform config is missing.

3. **"I've verified" flow**

   `EmailVerificationPage` has "Back to sign in" but no "I've verified" flow. The user must manually sign in after tapping the link. That is acceptable, but the app should ensure:
   - The deep link is received and the session is restored (or the user is prompted to sign in).
   - If the app was cold-started by the link, the splash should detect the session and navigate to the home screen.

---

## 2. Email Verification Flow

### Current Implementation

- Same flow as sign-up confirmation: Supabase sends the email, user taps the link.
- `EmailVerificationPage` shows:
  - "Check your email" message.
  - "Check my inbox" button (opens mail app via `open_mail_launcher`).
  - "Resend email" button with 60s cooldown.
  - "Back to sign in" link.

### What Works

- Resend flow.
- Opening mail app.
- Copy email fallback.
- Clear instructions.

### Gaps

- Same as sign-up: **no deep link configuration** for Android/iOS.
- No explicit handling of the confirmation link in the app.
- No "Verify email" flow for users who signed in before verifying (e.g. business owners).

---

## 3. Forgot Password Flow

### Current Implementation

**Data flow:**
1. User taps "Forgot password?" on `SignInPage` → navigates to `ForgotPasswordPage`.
2. User enters email and taps "Reset".
3. `_onReset()` navigates directly to `ResetPasswordPage(emailOrPhone)` with no backend call.

**`ResetPasswordPage`:**
- `_onConfirm()` has `// TODO: Implement password reset with backend`.
- Shows a fake success message and navigates back to sign-in.

**Files:**
- `lib/features/auth/presentation/pages/forgot_password_page.dart` (lines 25–34)
- `lib/features/auth/presentation/pages/reset_password_page.dart` (lines 31–45)

### What Works

- UI only.
- Navigation between sign-in → forgot → reset.

### Gaps (Critical)

1. **No Supabase integration**

   `AuthRemoteDataSource` and `AuthSupabaseRemoteDataSource` have no:
   - `resetPasswordForEmail(String email)`
   - `updatePassword(String newPassword)` (for recovery session)

2. **Wrong UX flow**

   Supabase’s forgot-password flow:

   | Step | Action |
   |------|--------|
   | 1 | User enters email on Forgot page. |
   | 2 | App calls `supabase.auth.resetPasswordForEmail(email, redirectTo: 'habra://auth/callback')`. |
   | 3 | Supabase sends email with magic link. |
   | 4 | User taps link → opens app via deep link (with tokens in URL). |
   | 5 | App detects recovery session (session restored by Supabase). |
   | 6 | App shows "Set new password" screen. |
   | 7 | User enters new password. |
   | 8 | App calls `supabase.auth.updateUser(UserAttributes(password: newPassword))`. |

   Current flow skips steps 2–5 and goes straight to step 6–7 without a valid recovery session.

3. **Deep link required**

   Same as email confirmation: the app must be configured to receive `habra://auth/callback` (or equivalent) so the recovery link can open the app.

4. **Repository / use case**

   No `resetPasswordForEmail` or `updatePassword` in the auth domain layer.

---

## 4. Google Authentication Flow

### Current Implementation

**Data flow:**
1. User taps "Continue with Google" on sign-in or sign-up options.
2. `AuthCubit.signInWithGoogle()` → `SignInWithGoogleUseCase` → `AuthSupabaseRemoteDataSource.signInWithGoogle()`.
3. `GoogleSignIn().signIn()` → native Google sign-in.
4. `googleUser.authentication` → `idToken`.
5. `_client.auth.signInWithIdToken(provider: OAuthProvider.google, idToken: idToken)`.
6. `_sessionToUser()` fetches profile from `profiles` table.

**Files:**
- `lib/features/auth/data/datasources/auth_supabase_remote_datasource.dart` (lines 57–76)
- `lib/features/auth/presentation/bloc/auth_cubit.dart` (lines 77–84)

### What Works

- Code path is correct.
- Uses `signInWithIdToken` (no OAuth redirect needed).

### Gaps

1. **Supabase Dashboard**

   - Google provider must be enabled in Supabase Auth → Providers.
   - Client ID and Client Secret from Google Cloud Console must be configured.

2. **Google Cloud Console**

   - OAuth 2.0 Client ID (Web application) for Supabase callback.
   - Android OAuth client (if using Android) with correct SHA-1 fingerprint.
   - iOS OAuth client with correct bundle ID.

3. **Platform config**

   - `google_sign_in` uses default config; for production you may need custom `GoogleSignIn` with `serverClientId` for Android.
   - Docs: [HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md) §2.

4. **Profile creation**

   - `handle_new_user` trigger must create a row in `profiles` (with `role` from `user_metadata` if provided).
   - Google sign-in may not pass `role`; the trigger may need to default to `customer`.

---

## 5. Deep Link Configuration (Required for All Flows)

### Why It’s Needed

- **Email confirmation:** User taps link in email → app must open and receive the URL.
- **Password reset:** User taps link in email → app must open and receive the URL.
- **OAuth (if using signInWithOAuth):** Redirects back to app (not used for Google sign-in with id token).

### Recommended URL Scheme

- **Scheme:** `habra`
- **Host:** `auth`
- **Full URL:** `habra://auth/callback`

### Android Configuration

Add to `android/app/src/main/AndroidManifest.xml` inside the `<activity>` that has `LAUNCHER`:

```xml
<!-- Deep Links for auth (email confirm, password reset) -->
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="habra"
        android:host="auth"
        android:pathPrefix="/callback" />
</intent-filter>
```

### iOS Configuration

Add to `ios/Runner/Info.plist` (inside `<dict>`):

```xml
<key>CFBundleURLTypes</key>
<array>
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
</array>
```

### Supabase Dashboard

In **Authentication → URL Configuration → Redirect URLs**, add:

- `habra://auth/callback`
- `habra://**` (if you want to allow any path)

### Supabase Flutter

`supabase_flutter` v2+ uses PKCE by default and can restore the session from the URL. The app does not need to explicitly call `getSessionFromUrl` if the platform handles the link and the URL is passed to Supabase. You may need to ensure Supabase is initialized with the correct auth options (default is usually fine).

### Optional: Explicit Deep Link Handling

If the app is in the background when the user taps the link, you may need to listen for incoming links:

```dart
// Use app_links or uni_links
appLinks.uriLinkStream.listen((uri) {
  if (uri != null) {
    Supabase.instance.client.auth.recoverSession(uri.toString());
  }
});
```

Supabase Flutter may already handle this; verify with testing.

---

## 6. Implementation Checklist

### Sign-Up / Email Verification

- [x] Sign-up with email confirmation detection
- [x] EmailVerificationPage with resend
- [x] **Add deep link config** (Android + iOS)
- [ ] **Add `habra://auth/callback` to Supabase Redirect URLs** (Dashboard → Auth → URL Configuration)
- [x] `emailRedirectTo` passed in signUp for confirmation emails
- [ ] **Test:** Sign up → receive email → tap link → app opens → user can sign in

### Forgot Password

- [x] **Add `resetPasswordForEmail(String email)`** to `AuthRemoteDataSource` and `AuthSupabaseRemoteDataSource`
- [x] **Add `updatePassword(String newPassword)`** for recovery session
- [x] **Add use cases** for both
- [x] **Update ForgotPasswordPage:** Call `resetPasswordForEmail` → show "Check your email"
- [x] **Update ResetPasswordPage:** Shown when app opens via recovery link; call `updatePassword` on confirm
- [x] **Add deep link config** (same as above)
- [x] **AuthDeepLinkHandler** listens for `AuthChangeEvent.passwordRecovery` and navigates to ResetPasswordPage
- [ ] **Test:** Forgot → email → tap link → app opens → set new password → sign in

### Google Authentication

- [ ] **Supabase Dashboard:** Enable Google provider, add Client ID and Secret
- [ ] **Google Cloud Console:** Create OAuth client, add Supabase callback URL
- [ ] **Android:** Add SHA-1 fingerprint for debug/release; create Android OAuth client if needed
- [ ] **Test:** Sign in with Google → profile created → navigate to home

### General

- [ ] **Confirm `handle_new_user` trigger** creates `profiles` for all sign-up methods (email, Google, anonymous)
- [ ] **Confirm `handle_new_user`** sets `role` from `user_metadata` if provided
- [ ] **Email templates:** Customize "Confirm signup" and "Reset password" in Supabase Dashboard

---

## 7. Recommended File Changes

### AuthRemoteDataSource

```dart
// Add to abstract class and implementation
Future<void> resetPasswordForEmail(String email);
Future<void> updatePassword(String newPassword);
```

### AuthSupabaseRemoteDataSource

```dart
@override
Future<void> resetPasswordForEmail(String email) async {
  await _client.auth.resetPasswordForEmail(
    email,
    redirectTo: 'habra://auth/callback',
  );
}

@override
Future<void> updatePassword(String newPassword) async {
  await _client.auth.updateUser(UserAttributes(password: newPassword));
}
```

### Supabase signUp (optional)

Pass `redirectTo` so the confirmation email uses the correct URL:

```dart
final response = await _client.auth.signUp(
  email: email,
  password: password,
  data: {'full_name': name, 'role': roleString},
  emailRedirectTo: 'habra://auth/callback',
);
```

### ForgotPasswordPage

- On "Reset": Call `resetPasswordForEmail(email)` instead of navigating to ResetPasswordPage.
- Show "Check your email" and optionally a "Check inbox" button.
- Do not navigate to ResetPasswordPage until the user has tapped the link (app opens via deep link).

### ResetPasswordPage

- Entry point: When app is opened via password-reset deep link, Supabase restores the session with `type: recovery`.
- Show ResetPasswordPage when `session != null` and `session.user.recovery_sent_at` or similar indicates recovery.
- On confirm: Call `updatePassword(newPassword)` and then sign in or redirect.

---

## 8. References

- [Supabase: Native Mobile Deep Linking](https://supabase.com/docs/guides/auth/native-mobile-deep-linking)
- [Supabase: Resetting a user's password](https://supabase.com/docs/guides/auth/passwords#resetting-a-users-password-forgot-password)
- [HABRA_SUPABASE_CONFIG.md](./supabase/HABRA_SUPABASE_CONFIG.md)
- [SUPABASE_BACKEND_DESIGN.md](./SUPABASE_BACKEND_DESIGN.md) §4.5 (Email verification flow)
