# Habra Mobile App — Production Testing Checklist

**Purpose:** Use this document to verify the app is production-ready before deployment. When all sections are satisfied, the app can be released to customers and business owners with confidence.

**How to use:** Copy this entire document into Notion (or your wiki). Check off items as you complete them. Re-run the checklist for each release (e.g. before submitting to stores or deploying a web build).

---

## Part 1 — Recommended Testing Mechanisms (Strategy)

Before implementing checks, adopt a clear testing strategy. Below is a professional, scalable approach tailored to a Flutter super app (Clean Architecture, Dio, Supabase, Firebase).

### 1.1 Testing Pyramid

| Layer | What to test | Tools / Approach | Priority |
|-------|--------------|------------------|----------|
| **Unit** | Domain: entities, use cases, mappers. Data: repositories (mocked datasources), serialization. | `flutter_test`, mocks (`mocktail` or `mockito`) | High — fast, many tests |
| **Widget** | Reusable UI: buttons, cards, form fields, list items. Screens in isolation with mocked Bloc/Cubit. | `flutter_test`, `flutter_test` + `bloc_test` | High — catch layout/overflow |
| **Integration** | Full flows: login → home, explore → business detail, job apply. Real or fake API. | `integration_test/`, `patrol` or `flutter_driver` | Medium — before each release |
| **E2E / Manual** | Critical user journeys on real devices (iOS + Android), different screen sizes. | Manual + test plan (this checklist) | High — pre-launch |

### 1.2 What to Automate First

1. **Unit:** All use cases and repository implementations (mock remote/cache).
2. **Unit:** Failure mapping (e.g. Supabase/Firebase errors → app failures).
3. **Widget:** Core widgets (`AppButton`, `AppCard`, forms) with long text and RTL (overflow, alignment).
4. **Widget:** One representative screen per feature (e.g. `EventsPage`, `JobsPage`) with mock data.
5. **Integration:** Auth flow, one “happy path” per main feature (events, jobs, explore, dashboard).

### 1.3 API and Backend Testing

- **Contract tests:** Document expected request/response shapes; optionally use Postman/OpenAPI and run against staging.
- **Mock server:** Use `dio` interceptors or a local mock (e.g. Mockoon, json-server) for integration tests so CI doesn’t depend on real backend.
- **Staging environment:** All pre-production testing against staging API/Supabase, never production.

### 1.4 CI/CD Gates

- Run on every PR: `flutter analyze`, `flutter test` (unit + widget), and optionally integration tests.
- Block merge if: analyze fails, or test count/coverage drops below agreed thresholds.
- Before release: full manual checklist (this document) + smoke tests on real devices.

### 1.5 Scalability

- **Feature-based test folders:** Mirror `lib/features/<feature>/` with `test/features/<feature>/` (unit, widget, integration).
- **Shared test helpers:** Factories for entities, fake repositories, and custom `pumpWidget` wrappers (theme, localization, BlocProvider).
- **Golden tests (optional):** For design-critical widgets to catch unintended UI changes.

---

## Part 2 — Production Readiness Checklist

### 2.1 Code Quality & Static Analysis

- [ ] **`flutter analyze`** runs with zero errors and zero warnings (or only explicitly accepted exceptions, documented).
- [ ] **No `// ignore`** comments for critical rules (e.g. `use_build_context_synchronously`) without a short justification comment.
- [ ] **Unused code:** No unused imports, unused variables, or dead code (remove or refactor).
- [ ] **Deprecated APIs:** No use of deprecated Flutter/Dart APIs (e.g. `withOpacity` → `withValues(alpha:)`); track and fix deprecation warnings.
- [ ] **Lint rules:** Project uses a consistent rule set (e.g. `flutter_lints` or custom `analysis_options.yaml`); all rules are satisfied.
- [ ] **Final fields:** All fields that are assigned only once are `final` where possible.
- [ ] **String composition:** Prefer interpolation (`'$a - $b'`) over concatenation for strings.

---

### 2.2 Unit & Widget Tests (Automated)

- [ ] **Unit tests** exist for all domain use cases (e.g. `GetEventsUseCase`, `SubmitApplicationUseCase`) with success and failure cases.
- [ ] **Repository tests** cover success, network error, and (where applicable) cache hit/miss using mocked datasources.
- [ ] **Failure mappers** (e.g. Supabase/Firebase → app failures) are unit-tested for each error type.
- [ ] **Widget tests** exist for core shared widgets (`AppButton`, `AppCard`, `AppText`, loaders) including loading/disabled states.
- [ ] **Widget tests** for at least one key screen per feature (e.g. Events, Jobs, Explore, Dashboard) with mocked Cubit/Bloc and sample data.
- [ ] **No flaky tests:** All tests pass consistently (run multiple times or in CI); fix or remove flaky tests.
- [ ] **CI:** `flutter test` is run in CI (e.g. GitHub Actions) and must pass before merge/release.

---

### 2.3 UI/UX — Layout & Overflow

- [ ] **Scroll:** Every screen with content that can exceed viewport uses a scrollable widget (`SingleChildScrollView`, `ListView`, `CustomScrollView`, etc.) and never causes overflow.
- [ ] **Long text:** Titles, descriptions, and user-generated text are constrained (e.g. `Expanded`/`Flexible`, `maxLines`, `overflow: TextOverflow.ellipsis`) and tested with long strings (e.g. 500+ characters).
- [ ] **Small screens:** All main screens tested on smallest supported device (e.g. 4" or 320pt width); no overflow or unusable layout.
- [ ] **Large screens / Tablets:** Layouts scale or use responsive breakpoints (e.g. `ResponsiveScaffold`, `ScreenUtils`); no huge empty spaces or cramped content.
- [ ] **Orientation:** Portrait and landscape tested for critical screens (at least home, detail, and forms).
- [ ] **Safe areas:** Notches, status bar, and home indicator respected; no content hidden behind system UI.
- [ ] **Dynamic font sizes:** Test with system font size set to “Large” or “Largest”; no overflow or clipped text.

---

### 2.4 UI/UX — Design Consistency & Improvement

- [ ] **Design match:** Screens match approved designs (Figma/Adobe XD) for layout, spacing, typography, and key components; document any intentional deviations.
- [ ] **Theme:** Light and dark themes applied correctly; no hardcoded colors that break in one theme.
- [ ] **Brand colors:** Primary/secondary colors (e.g. dark green, golden brown) used consistently via `AppColors`/theme.
- [ ] **Typography:** Headings, body, and captions use `AppTextStyles`/theme; no arbitrary font sizes or weights.
- [ ] **Spacing:** Consistent use of spacing constants (XS, S, M, L, XL); no magic numbers (e.g. `padding: 17`).
- [ ] **Loading states:** Every async operation shows a clear loading indicator (e.g. loader, skeleton) and no “blank” screens.
- [ ] **Empty states:** Lists and detail views show a clear empty state (message + optional CTA), not a blank area.
- [ ] **Error states:** User-facing error messages are clear and actionable; retry or alternative action where appropriate.
- [ ] **Improvement backlog:** Known UI/UX improvements are documented (e.g. in `UI_UX_STATUS.md` or Notion); critical items fixed before release.

---

### 2.5 API Integration & Network

- [ ] **Base URL:** Production API base URL is correct and not pointing to dev/staging (use env/flavor or build config).
- [ ] **API version:** Correct API version path (e.g. `/v1`) and headers; no mixing of versions.
- [ ] **Timeouts:** Connect and receive timeouts set (e.g. 30s); no infinite waits.
- [ ] **Retries:** Critical requests (e.g. payment, submit application) have a defined retry or “try again” strategy; no silent failure.
- [ ] **All endpoints:** Every feature that calls the backend has been tested against staging (or production-like) API at least once.
- [ ] **Request shape:** Request body/query params match backend contract; content-type and accept headers correct (e.g. `application/json`).
- [ ] **Response handling:** Success responses parsed correctly; status 2xx mapped to success.
- [ ] **Error handling:** 4xx/5xx mapped to user-friendly messages; no raw stack traces or technical errors shown to users.
- [ ] **Offline / poor network:** App handles no connectivity (e.g. connectivity_plus); shows clear message and optional retry; no crash.
- [ ] **Logging:** In production build, no logging of full request/response bodies or tokens; use debug-only interceptors (e.g. `kDebugMode`).

---

### 2.6 Security

- [ ] **Secrets:** No API keys, Supabase anon keys, or other secrets hardcoded in source; use environment variables or secure config (e.g. Dart Define, CI secrets).
- [ ] **Token storage:** Access/refresh tokens stored in secure storage (e.g. Flutter Secure Storage for sensitive tokens); if using SharedPreferences, document risk and consider migration.
- [ ] **Token usage:** Auth token sent only over HTTPS; Bearer token in `Authorization` header (e.g. via `AuthInterceptor`); no token in URL or logs.
- [ ] **Token expiry:** App handles 401/403 (e.g. refresh token or re-login); user is not left in a broken state.
- [ ] **Input validation:** All user inputs (forms, search, reviews) validated and sanitized; no raw input sent to backend without validation.
- [ ] **Deep links / URLs:** Any in-app links or WebViews validate URLs; no open redirect or injection.
- [ ] **ProGuard / R8 (Android):** Release build uses minification; no sensitive strings in plain text in APK where avoidable.
- [ ] **Certificate pinning (if required):** If your security policy requires it, certificate pinning is implemented and tested.

---

### 2.7 Authentication & Authorization

- [ ] **Login flows:** Email, Google (and any other providers) work on both Android and iOS; errors (wrong password, disabled account) show clear messages.
- [ ] **Sign up:** Registration completes and (if applicable) email verification works; no duplicate accounts for same identity.
- [ ] **Password reset:** Forgot password flow works; user receives email and can set new password.
- [ ] **Session persistence:** After app restart, logged-in user remains logged in until token expiry or logout.
- [ ] **Logout:** Logout clears tokens and in-memory state; next launch shows login/onboarding as expected.
- [ ] **Role / path:** Customer vs business owner path (e.g. `ChoosePathPage`, dashboard) correct; no access to wrong role’s data.
- [ ] **Protected routes:** All authenticated-only screens redirect to login when session is invalid.

---

### 2.8 Localization (i18n)

- [ ] **All supported locales** (e.g. EN, AR, FR) have complete `arb` files; no missing keys.
- [ ] **RTL:** Arabic (and any other RTL locale) layout and navigation are correct; no mirrored icons or broken alignment.
- [ ] **No hardcoded strings:** User-facing strings use `AppLocalizations` (or equivalent); no raw English in UI.
- [ ] **Numbers & dates:** Formatted with locale-aware formatters (e.g. `intl`); currency and dates correct for each locale.
- [ ] **Plurals & gender:** Plural and gender-sensitive strings use correct ICU/plural forms where needed.

---

### 2.9 Performance & Stability

- [ ] **Startup:** App launches without long blank screen; splash then navigates to correct screen.
- [ ] **No jank:** Scrolling lists (events, jobs, explore) are smooth (e.g. 60fps); use `ListView.builder` or equivalent for long lists.
- [ ] **Images:** Images are sized appropriately (e.g. cached, resized) to avoid OOM on low-end devices.
- [ ] **Memory:** No obvious memory leaks (e.g. navigate in/out of heavy screens multiple times; use DevTools if needed).
- [ ] **Crashlytics:** Firebase Crashlytics (or equivalent) integrated in release build; no critical crashes in last test cycle.
- [ ] **Analytics:** Key events (e.g. sign up, purchase, job application) tracked for business owners; no PII in event names or params.

---

### 2.10 Platform-Specific (Android)

- [ ] **Min SDK:** Min SDK version is set and supported devices are documented (e.g. minSdk 21).
- [ ] **Permissions:** Only required permissions declared; runtime permissions requested at appropriate time with rationale.
- [ ] **Back button:** Back button behavior is correct (e.g. doesn’t exit app unexpectedly on root screens).
- [ ] **Release build:** Release APK/AAB builds successfully; signing configured (upload key for Play Store).
- [ ] **No debug:** Debug flags, dev overlay, and mock API URLs disabled in release.

---

### 2.11 Platform-Specific (iOS)

- [ ] **Deployment target:** iOS deployment target set (e.g. 12+); consistent with Podfile and Xcode.
- [ ] **Permissions:** Usage descriptions (camera, location, etc.) in `Info.plist` and accurate; permissions requested when needed.
- [ ] **Release build:** Archive and build for release succeed; signing and provisioning correct.
- [ ] **No debug:** Debug-only code and mock APIs disabled in release.
- [ ] **App Store:** Screenshots, description, and privacy notes prepared; no placeholder content in store listing.

---

### 2.12 Third-Party Services

- [ ] **Firebase:** All used services (Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, Remote Config) configured for production project; correct `google-services.json` and `GoogleService-Info.plist` in repo or CI.
- [ ] **Supabase:** Production project and URL; RLS and auth policies reviewed; no dev keys in production build.
- [ ] **Google Sign-In:** OAuth client IDs for Android and iOS configured; correct package name and bundle ID.
- [ ] **Push notifications:** FCM/APNs configured; tokens sent to backend; notifications received on physical device in release build (if feature is live).

---

### 2.13 Data & Privacy

- [ ] **Privacy policy:** Accessible in app (e.g. Settings or sign-up); URL or content is final and correct.
- [ ] **Terms of service:** Same as above if applicable.
- [ ] **Data collection:** Only necessary data collected; no unnecessary tracking or PII in logs/analytics.
- [ ] **User data handling:** Delete account or export data flow implemented if required by policy or law.
- [ ] **Compliance:** Any required compliance (e.g. GDPR, CCPA) documented and implemented (consent, deletion, etc.).

---

### 2.14 Deployment & Release

- [ ] **Version:** `pubspec.yaml` version and build number incremented (e.g. `1.0.0+1` → `1.0.1+2`).
- [ ] **Changelog:** Release notes or changelog updated for store and/or internal release.
- [ ] **Store assets:** Icons, screenshots, and feature graphic ready for Play Store and App Store.
- [ ] **Staged rollout (optional):** Plan for phased rollout (e.g. 10% → 50% → 100%) and rollback if needed.
- [ ] **Monitoring:** Post-release monitoring plan (Crashlytics, analytics, support channel) and owner defined.

---

### 2.15 Final Smoke Test (Manual)

Run once on a physical device (or emulator) for each platform before release:

- [ ] Cold start → Splash → Onboarding or Home.
- [ ] Sign in (email and Google) → Home.
- [ ] Navigate: Home → Explore → Business detail → Back.
- [ ] Navigate: Events → Event detail → Select tickets → Checkout (or as far as possible without payment).
- [ ] Navigate: Jobs → Job detail → Apply (submit or cancel).
- [ ] Business owner: Sign in as business → Dashboard → at least one tab (e.g. Jobs, Deals, Reviews).
- [ ] Settings: Change language; change theme (if available); open privacy/terms links.
- [ ] Sign out → confirm landing on login/onboarding.
- [ ] No crash, no obvious layout break, no missing text or images.

---

## Summary: Ready for Production?

- **All sections above** should be checked (or explicitly marked “N/A” with reason) before production deployment.
- **No known critical or high-severity bugs** open for the release scope.
- **Rollback plan** and **owner** for post-release issues are agreed.

Once these are met, the app is ready for production and can be deployed for customers and business owners.

---

*Document version: 1.0 | Last updated: Feb 2025 | Project: Habra Mobile App*
