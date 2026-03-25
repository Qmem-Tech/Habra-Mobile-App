# Auth And Business Gating Test Flow

This checklist verifies strict behavior for:

- email verification enforcement,
- unverified login blocking,
- business dashboard access gating by docs + approval.

## Preconditions

- Supabase email provider is enabled and working.
- Deep link callback URL is configured (`habra://auth/callback`).
- Test business user is created through app signup.

## A) Email verification flow

1. Sign up a new user with email/password.
2. Confirm app lands on `EmailVerificationPage`.
3. Confirm resend button starts disabled with 60s timer.
4. Trigger resend after timer.
5. Open email link and return to app.
6. Confirm app resumes correctly and no stuck loading.

Expected:

- User cannot access authenticated flow before verification.
- Verified user can continue after callback.

## B) Unverified login block

1. Use an unverified account and attempt sign-in.
2. Confirm app routes to `EmailVerificationPage`.
3. Confirm previous routes are cleared (cannot back into protected flow).

Expected:

- No dashboard/home access while unverified.
- Session is not persisted as authenticated for unverified account.

## C) Business dashboard gating

1. Sign in as business owner with verified email.
2. Ensure at least one business is pending and/or legal docs not approved.
3. Try opening Dashboard and Boost tabs.

Expected:

- Access is blocked with an explanatory message.
- Home/profile remains accessible.

4. Upload required legal docs.
5. Keep approval pending; retry tabs.

Expected:

- Still blocked until admin approval is completed.

6. Mark legal docs approved and business approval status approved.
7. Retry tabs.

Expected:

- Dashboard and Boosts are accessible.

## D) Regression checks

- Forgot password flow still works.
- Deep link password recovery still opens reset screen.
- Sign out clears authenticated and purchase-linked state.
