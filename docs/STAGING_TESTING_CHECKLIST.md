# Habra Mobile App — Staging Environment Testing Checklist

**Purpose:** Use this checklist on the **staging** build (staging API/Supabase, debug or release build pointed at staging) to catch bugs early, verify illustrations match flows, confirm all screens are present, and document scenarios and test cases. Copy to Notion and check off as you complete each item.

---

## 1. Staging Environment Setup

Before running any tests, ensure the staging environment is correct.

| # | Check | Expected | Pass |
|---|--------|-----------|------|
| 1.1 | App is built with **staging** base URL / Supabase URL (not production) | Config or env shows staging endpoint | ☐ |
| 1.2 | Staging API is reachable (e.g. health check or login works) | No "connection refused" or timeouts | ☐ |
| 1.3 | Staging Firebase project is used (if applicable) | Correct `google-services.json` / `GoogleService-Info.plist` for staging | ☐ |
| 1.4 | Staging Supabase project is used | Correct Supabase URL in config | ☐ |
| 1.5 | Test accounts exist on staging (customer + business owner) | Can sign in and perform flows | ☐ |
| 1.6 | Build variant: debug or release build used for testing is documented | e.g. "Staging Debug" or "Staging Release" | ☐ |

---

## 2. Illustration & Asset Cross-Check (Flow vs Screen)

Verify that **each illustration/image** used in a flow matches the **flow and the screen** it appears on (correct asset, correct context, no wrong or placeholder where final art is expected).

### 2.1 Splash & App Identity

| Screen | Asset (from `AppAssets`) | Expected meaning | Verify on screen |
|--------|---------------------------|------------------|-------------------|
| Splash | `splashLogo` / `appLogo` | Habra logo, centered | Logo visible, no missing image icon | ☐ |
| Splash | — | App name "Habra" (text) | Text present and correct | ☐ |

### 2.2 Onboarding Flow (3 screens)

| Page # | Screen purpose | Asset | Expected illustration meaning | Check |
|--------|-----------------|-------|-------------------------------|-------|
| 1 | Discover Your Community | `onboardingMusicFestival` (`onboarding_screen_1.png`) | Music festival / events / community | Image shows events/community theme; matches "Discover Your Community" | ☐ |
| 2 | Support Local Businesses | `onboardingCoffeeShop` (`onboarding_screen_2.png`) | Coffee shop / local business | Image shows local business theme; matches "Support Local Businesses" | ☐ |
| 3 | Grow Together | `onboardingGrowTogether` (`onboarding_screen_3.png`) | Growth / connectivity / together | Image shows growth/connection theme; matches "Grow Together" | ☐ |

**Cross-check:**

- [ ] Progress indicators (dots) match current page (1, 2, or 3).
- [ ] "Next" on page 1 & 2; "Get Started" on page 3.
- [ ] Close/Skip goes to Choose Path; Get Started goes to Choose Path.
- [ ] No broken image placeholders; aspect ratio looks correct on small and large devices.

### 2.3 Choose Path Screen

| Element | Asset / design | Verify |
|---------|----------------|--------|
| Screen purpose | Choose Customer vs Business Owner | Both options visible and tappable | ☐ |
| Any illustration | If present | Matches "choice" or "path" concept; not a wrong flow image | ☐ |

### 2.4 Auth Flow (Sign In / Sign Up)

| Screen / element | Asset / copy | Verify |
|-------------------|--------------|--------|
| Sign In | Google icon (`google_icon.png`) | Google button shows correct branding; no broken icon | ☐ |
| Email verification | Any success/email illustration | Matches "verify email" flow | ☐ |
| Forgot / Reset password | — | No wrong illustration on these screens | ☐ |
| Business sign-up steps | Any step illustrations | Each step shows correct illustration for "business basics", "contact", "location", "photos" | ☐ |

### 2.5 Customer Home & Tabs

| Screen / state | Asset | Expected | Verify |
|----------------|-------|----------|--------|
| Home – events | `eventPlaceholder` | Event placeholder when no image | Correct placeholder; no wrong category image | ☐ |
| Home – deals | `dealPlaceholder` | Deal placeholder | Correct for deals | ☐ |
| Home – businesses | `businessPlaceholder` | Business placeholder | Correct for businesses | ☐ |
| Home – jobs | `jobPlaceholder` | Job placeholder | Correct for jobs | ☐ |
| Notifications empty | `notificationEmpty` | Empty notifications state | Illustration matches "no notifications" | ☐ |
| Search no results | `noResults` | No results state | Illustration matches "no results" | ☐ |

### 2.6 Events Flow

| Screen / state | Asset / context | Verify |
|----------------|-----------------|--------|
| Event list cards | Event images or placeholder | Correct per event or placeholder | ☐ |
| Event detail | Hero image | Matches event; no wrong event image | ☐ |
| Empty / sold out | Any empty state image | Matches "no events" or "sold out" | ☐ |
| Order / payment success | `successIcon` or similar | Success confirmation matches flow | ☐ |

### 2.7 Jobs Flow

| Screen / state | Asset (from `AppAssets`) | Expected | Verify |
|----------------|--------------------------|----------|--------|
| Job cards / featured | `jobsCulturalNightHero`, `jobsCulturalNight`, `jobsTeddyAfroConcert` | Job-related imagery | Right image for context (hero vs list vs alternate) | ☐ |
| No jobs found | `noJobsFound` | Empty state for no jobs | Illustration fits "no jobs" message | ☐ |
| No applications | `noApplications` | Empty state for applications | Fits "no applications" | ☐ |
| Application submitted | `applicationSubmitted` | Success state | Fits "application submitted" | ☐ |

### 2.8 Explore (Businesses & Deals)

| Screen / state | Asset / context | Verify |
|----------------|-----------------|--------|
| Business list/detail | Business images or default | `default.png` or first image; no wrong business image | ☐ |
| Deal cards | Deal images or placeholder | Correct per deal | ☐ |
| Empty / no results | Relevant empty asset | Matches "no businesses" or "no deals" | ☐ |
| Write review / redeem | Any illustration | Matches review or redemption flow | ☐ |

### 2.9 Business Owner (Dashboard & Home)

| Screen / state | Asset | Expected | Verify |
|----------------|-------|----------|--------|
| Dashboard – no deals | `dashboardNoDeals` | Empty state for deals | Matches "no deals yet" | ☐ |
| Dashboard – no jobs | `dashboardNoJobs` | Empty state for job posts | Matches "no jobs yet" | ☐ |
| Dashboard – no analytics | `dashboardNoAnalytics` | Empty state for analytics | Matches "no analytics yet" | ☐ |
| Dashboard – no reviews | `dashboardNoReviews` | Empty state for reviews | Matches "no reviews yet" | ☐ |
| Add new presence / business | `businessOwnerNewBusiness`, `businessOwnerNewLocation`, `businessOwnerUploadPhoto` | Onboarding / add flow | Each step shows correct illustration for "new business", "new location", "upload" | ☐ |
| Pending review | `businessOwnerPendingReview` | Pending state | Matches "pending review" | ☐ |

### 2.10 Boosts Flow

| Screen / state | Asset | Expected | Verify |
|----------------|-------|----------|--------|
| Boosts list empty | `boostsEmptyState` | No boosts used | Matches "no boosts" | ☐ |
| Boost order success | `boostsOrderSuccess` | Payment/order success | Success icon/illustration | ☐ |
| Cancel boost modal | `boostsCancelListingPlaceholder` | Listing placeholder | Appropriate for cancel context | ☐ |

### 2.11 Global / Shared

| Asset | Used in | Verify |
|-------|---------|--------|
| `successIcon` | Payment, order, application submitted, etc. | Same success treatment across flows; no wrong icon | ☐ |
| `icClose` | Onboarding, modals | Close icon consistent | ☐ |

---

## 3. Screen Presence Checklist (All Screens Present)

Confirm that every expected screen exists, is reachable, and renders without crash. Mark **Present** or **N/A** (e.g. feature disabled on staging).

### 3.1 Entry & Onboarding

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Splash | Cold start | ☐ | |
| Onboarding (page 1) | First launch after install / reset | ☐ | |
| Onboarding (page 2) | Swipe or Next from page 1 | ☐ | |
| Onboarding (page 3) | Swipe or Next from page 2 | ☐ | |
| Choose Path | After onboarding or equivalent | ☐ | |

### 3.2 Authentication (Customer & Business)

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Sign In | Choose Path → Customer / then sign in | ☐ | |
| Sign Up Options | Choose Path → Sign up path | ☐ | |
| Email Sign Up | Sign up → Email | ☐ | |
| Phone Sign Up | Sign up → Phone | ☐ | |
| Email Verification | After email sign up | ☐ | |
| Authentication Code | After phone sign up | ☐ | |
| Forgot Password | From sign in | ☐ | |
| Reset Password | From forgot password email link / flow | ☐ | |
| Business Sign In | Choose Path → Business owner | ☐ | |
| Business Basics | Business sign-up step | ☐ | |
| Business Contact | Business sign-up step | ☐ | |
| Business Location | Business sign-up step | ☐ | |
| Business Photos | Business sign-up step | ☐ | |
| City Selection | When required by flow | ☐ | |
| Interests Selection | When required by flow | ☐ | |
| Welcome | After successful sign up (if used) | ☐ | |

### 3.3 Customer Home & Navigation

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Customer Home | After customer sign in | ☐ | |
| Guest Home | If guest mode exists | ☐ | |
| Navigation drawer / menu | Open drawer from home | ☐ | |
| Search | Home or drawer → Search | ☐ | |
| Search Results | After search query | ☐ | |
| Notifications | Drawer or icon → Notifications | ☐ | |

### 3.4 Events

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Events list | Tab or menu → Events | ☐ | |
| Event filters | Events → Filter | ☐ | |
| Event search | Events → Search | ☐ | |
| Event detail | Events list → Event card | ☐ | |
| Select tickets | Event detail → Select tickets | ☐ | |
| Checkout | Select tickets → Checkout | ☐ | |
| Order confirmation | After successful payment | ☐ | |
| Payment failed | After failed payment | ☐ | |
| Event sold out | When event is sold out | ☐ | |
| My tickets | Menu → My tickets | ☐ | |
| Ticket detail | My tickets → Ticket | ☐ | |

### 3.5 Jobs

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Jobs list | Tab or menu → Jobs | ☐ | |
| Job filters | Jobs → Filter | ☐ | |
| Job detail | Jobs list → Job card | ☐ | |
| Apply for job | Job detail → Apply | ☐ | |
| Application submitted | After submit application | ☐ | |
| No jobs found | When no jobs match filters | ☐ | |

### 3.6 Explore (Businesses & Deals)

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Explore / Directory | Tab or menu → Explore | ☐ | |
| Deals list | Explore → Deals | ☐ | |
| Deal detail | Deals → Deal card | ☐ | |
| Redeem deal | Deal detail → Redeem | ☐ | |
| Business detail | Directory / list → Business | ☐ | |
| Write review | Business detail → Write review | ☐ | |
| Map | Explore → Map (if present) | ☐ | |

### 3.7 Business Owner

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Business owner home | After business owner sign in | ☐ | |
| Dashboard | Business owner home / main | ☐ | |
| Dashboard – Jobs tab | Dashboard → Jobs | ☐ | |
| Dashboard – Deals tab | Dashboard → Deals | ☐ | |
| Dashboard – Reviews tab | Dashboard → Reviews | ☐ | |
| Dashboard – Analytics tab | Dashboard → Analytics | ☐ | |
| Create job post | Dashboard Jobs → Create | ☐ | |
| Job applicants | Dashboard Jobs → Applicants | ☐ | |
| Applicant details | Applicants → Applicant | ☐ | |
| Create deal | Dashboard Deals → Create | ☐ | |
| Reply to review | Dashboard Reviews → Reply | ☐ | |
| Add new presence | Dashboard / home → Add | ☐ | |
| Add location | Add presence or locations list | ☐ | |
| Business locations | Dashboard / menu → Locations | ☐ | |
| Choose business brand | When multiple brands | ☐ | |
| Listing status | When listing is pending | ☐ | |
| Business pending | When business is under review | ☐ | |
| Boost listing | Dashboard / menu → Boosts | ☐ | |

### 3.8 Boosts (Business Owner)

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Boosts list | Menu / dashboard → Boosts | ☐ | |
| Select job to boost | Boosts → Boost → Job | ☐ | |
| Select deal to boost | Boosts → Boost → Deal | ☐ | |
| Select location | Boost flow → Location | ☐ | |
| Boost options | After selection → Options | ☐ | |
| Order confirmation | After selecting option | ☐ | |
| Active boost details | Boosts list → Active boost | ☐ | |
| Cancel boost sheet | Active boost → Cancel | ☐ | |

### 3.9 Settings & Other

| Screen | How to reach | Present | Notes |
|--------|----------------|---------|--------|
| Settings | Drawer / profile → Settings | ☐ | |
| (Add any other global screens) | — | ☐ | |

---

## 4. Scenarios & Steps to Reproduce (Flows)

Use these as **scenarios** to run on staging. For each scenario, follow the steps and note **Pass** or **Fail** and any bug (with steps to reproduce for the bug).

### 4.1 Customer: First-time user (onboarding → home)

| Step | Action | Expected result | Pass | Notes / bug (steps to reproduce) |
|------|--------|------------------|------|-----------------------------------|
| 1 | Install app, open (cold start) | Splash shows; then onboarding or choose path | ☐ | |
| 2 | View onboarding page 1 | Illustration = "Discover Your Community"; title and description correct | ☐ | |
| 3 | Tap Next | Page 2 with "Support Local Businesses" and coffee shop illustration | ☐ | |
| 4 | Tap Next | Page 3 with "Grow Together" and grow-together illustration | ☐ | |
| 5 | Tap Get Started | Navigate to Choose Path | ☐ | |
| 6 | Tap Customer (or equivalent) | Navigate to Sign In or Home (if guest) | ☐ | |
| 7 | Sign in (email or Google) | Reach Customer Home with bottom nav / tabs | ☐ | |
| 8 | Open each tab (Home, Events, Jobs, Explore) | Each tab loads; no crash; correct content or empty state | ☐ | |

### 4.2 Customer: Browse events and view detail

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | From Customer Home, open Events | Events list (or empty state) | ☐ | |
| 2 | Tap Filters | Filter screen opens | ☐ | |
| 3 | Apply filters, apply | List updates (or empty) | ☐ | |
| 4 | Tap an event card | Event detail screen opens | ☐ | |
| 5 | Check hero image and copy | Image matches event; no wrong asset | ☐ | |
| 6 | Tap Select tickets (if available) | Select tickets screen | ☐ | |
| 7 | Select quantity, continue | Checkout or next step | ☐ | |
| 8 | Back to list | No crash; list still correct | ☐ | |

### 4.3 Customer: Browse jobs and apply

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | Open Jobs tab | Jobs list (or empty state) | ☐ | |
| 2 | Tap a job card | Job detail opens | ☐ | |
| 3 | Tap Apply | Apply for job screen (form) | ☐ | |
| 4 | Fill required fields, submit | Success screen (e.g. Application submitted) with correct illustration | ☐ | |
| 5 | Verify illustration | Success asset matches "application submitted" | ☐ | |
| 6 | Go back to Jobs | List or detail; no crash | ☐ | |

### 4.4 Customer: Explore businesses and deal

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | Open Explore / Directory | List or map; categories work | ☐ | |
| 2 | Tap a business | Business detail with correct images/info | ☐ | |
| 3 | Tap a deal (if any) | Deal detail | ☐ | |
| 4 | Tap Redeem | Redeem flow; confirmation or error handled | ☐ | |
| 5 | From business detail, tap Write review | Write review screen | ☐ | |
| 6 | Submit review (or cancel) | Success or back; no crash | ☐ | |

### 4.5 Business owner: Sign in and dashboard

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | Choose Path → Business owner; sign in | Business owner home / dashboard | ☐ | |
| 2 | Open Dashboard (if separate) | Dashboard with tabs (e.g. Jobs, Deals, Reviews, Analytics) | ☐ | |
| 3 | Open each tab | Each tab loads; empty states show correct illustration | ☐ | |
| 4 | Verify empty state assets | No jobs / no deals / no reviews / no analytics use correct images | ☐ | |
| 5 | Create job post (if available) | Create job screen; required steps present | ☐ | |
| 6 | Create deal (if available) | Create deal screen; flow completes or fails gracefully | ☐ | |

### 4.6 Business owner: Boosts flow

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | From dashboard/menu, open Boosts | Boosts list (or empty state with correct illustration) | ☐ | |
| 2 | Start new boost (if available) | Select job or deal to boost | ☐ | |
| 3 | Select location | Location selection screen | ☐ | |
| 4 | Select boost option | Options and pricing clear | ☐ | |
| 5 | Confirm order | Order confirmation or payment; success asset if success | ☐ | |
| 6 | Open active boost → Cancel | Cancel sheet with correct placeholder/illustration | ☐ | |

### 4.7 Auth: Forgot password and reset

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | Sign In → Forgot password | Forgot password screen | ☐ | |
| 2 | Enter email, submit | Success message or error handled | ☐ | |
| 3 | Use link from email (staging inbox) | Reset password screen | ☐ | |
| 4 | Set new password, submit | Redirect to sign in or success | ☐ | |
| 5 | Sign in with new password | Sign in succeeds | ☐ | |

### 4.8 Settings and localization

| Step | Action | Expected result | Pass | Notes / bug |
|------|--------|------------------|------|-------------|
| 1 | Open Settings | Settings screen with options | ☐ | |
| 2 | Change language (e.g. to AR) | App language switches; RTL if applicable | ☐ | |
| 3 | Navigate to 2–3 screens | No overflow; labels in selected language | ☐ | |
| 4 | Change back to EN (or default) | Language reverts | ☐ | |

---

## 5. Test Cases (Structured)

Use these as **test cases** to log in a test run. Fill **Actual result** and **Pass/Fail** during staging testing. **Steps to reproduce** should be enough for a developer to reproduce any failure.

### TC-01: Splash → Onboarding → Choose Path

| Field | Content |
|-------|--------|
| **ID** | TC-01 |
| **Scenario** | App cold start shows splash, then onboarding (if first time), then choose path. |
| **Preconditions** | Fresh install or onboarding not completed. |
| **Steps to reproduce** | 1. Install staging build. 2. Open app. 3. Wait for splash. 4. View onboarding pages 1–3. 5. Tap Get Started. |
| **Expected result** | Splash → onboarding (3 screens with correct illustrations and copy) → Choose Path. No crash; correct assets. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |
| **Notes** | _e.g. Illustration 2 wrong; Steps to reproduce for bug: …_ |

### TC-02: Onboarding illustration match (all 3 screens)

| Field | Content |
|-------|--------|
| **ID** | TC-02 |
| **Scenario** | Each onboarding screen shows the illustration that matches its title and flow. |
| **Preconditions** | On onboarding flow. |
| **Steps to reproduce** | 1. Reach onboarding. 2. Page 1: verify "Discover Your Community" + music festival image. 3. Page 2: verify "Support Local Businesses" + coffee shop image. 4. Page 3: verify "Grow Together" + grow-together image. |
| **Expected result** | Title, description, and image are semantically aligned on each page; no swapped or wrong assets. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-03: Customer sign in (email) → Home

| Field | Content |
|-------|--------|
| **ID** | TC-03 |
| **Scenario** | Customer can sign in with email and reach home. |
| **Preconditions** | Staging account exists; app on Choose Path or Sign In. |
| **Steps to reproduce** | 1. Tap Customer. 2. Enter email + password. 3. Tap Sign In. 4. Wait for navigation. |
| **Expected result** | Sign in succeeds; user lands on Customer Home; tabs visible. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-04: Customer sign in (Google) → Home

| Field | Content |
|-------|--------|
| **ID** | TC-04 |
| **Scenario** | Customer can sign in with Google and reach home. |
| **Preconditions** | Google configured for staging; app on Sign In. |
| **Steps to reproduce** | 1. Tap Sign in with Google. 2. Complete Google consent. 3. Return to app. |
| **Expected result** | Sign in succeeds; user lands on Customer Home. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-05: Events list → Event detail → Back

| Field | Content |
|-------|--------|
| **ID** | TC-05 |
| **Scenario** | Events list loads; tapping an event opens detail; back returns to list. |
| **Preconditions** | Customer signed in; events available on staging (or empty state). |
| **Steps to reproduce** | 1. Open Events tab. 2. Tap first event (or confirm empty state). 3. On detail, verify hero image matches event. 4. Tap back. |
| **Expected result** | List → detail with correct content and asset; back works; no crash. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-06: Jobs list → Job detail → Apply → Success screen

| Field | Content |
|-------|--------|
| **ID** | TC-06 |
| **Scenario** | User can open a job, apply, and see application-submitted screen with correct illustration. |
| **Preconditions** | Customer signed in; at least one job on staging. |
| **Steps to reproduce** | 1. Open Jobs. 2. Tap a job. 3. Tap Apply. 4. Fill form; submit. 5. Check success screen. |
| **Expected result** | Success screen shows; illustration matches "application submitted"; no wrong asset. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-07: Explore → Business detail → Write review

| Field | Content |
|-------|--------|
| **ID** | TC-07 |
| **Scenario** | User can open a business and open write review. |
| **Preconditions** | Customer signed in; businesses on staging. |
| **Steps to reproduce** | 1. Open Explore. 2. Tap a business. 3. Tap Write review. 4. Enter text (or cancel). |
| **Expected result** | Business detail and write review screen open; submit or cancel works. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-08: Business owner dashboard empty states

| Field | Content |
|-------|--------|
| **ID** | TC-08 |
| **Scenario** | Dashboard tabs show correct empty-state illustrations (no jobs, no deals, no reviews, no analytics). |
| **Preconditions** | Business owner signed in; dashboard has no data (or clear data for test). |
| **Steps to reproduce** | 1. Open Dashboard. 2. Open Jobs tab → check empty illustration. 3. Deals tab → check. 4. Reviews tab → check. 5. Analytics tab → check. |
| **Expected result** | Each empty state shows the correct illustration and copy for that section. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-09: Business owner boost flow (select job → option → confirm)

| Field | Content |
|-------|--------|
| **ID** | TC-09 |
| **Scenario** | Business owner can start a boost, select job, select option, and reach order confirmation. |
| **Preconditions** | Business owner signed in; has job(s) to boost. |
| **Steps to reproduce** | 1. Open Boosts. 2. Start boost → Select job. 3. Select a job. 4. Select location (if required). 5. Select boost option. 6. Confirm. |
| **Expected result** | Each step opens correct screen; order confirmation or payment step appears; success asset if completed. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

### TC-10: No results / empty states (customer)

| Field | Content |
|-------|--------|
| **ID** | TC-10 |
| **Scenario** | Search no results, notifications empty, and other empty states show correct illustration and message. |
| **Preconditions** | Customer signed in. |
| **Steps to reproduce** | 1. Search for nonexistent query → verify no-results asset. 2. Open Notifications with none → verify notification-empty asset. 3. Open Jobs with no results (e.g. strict filters) → verify no-jobs asset. |
| **Expected result** | Each empty state uses the correct asset from Section 2; copy matches. |
| **Actual result** | _Fill during test_ |
| **Pass / Fail** | ☐ Pass  ☐ Fail |

---

## 6. Bug Report Template (When You Find a Bug)

Use this so that staging bugs are reported with clear **steps to reproduce** and **illustration/screen** context.

| Field | Description |
|-------|-------------|
| **Title** | Short summary (e.g. "Onboarding page 2 shows wrong illustration") |
| **Environment** | Staging; build type; device/OS |
| **Flow** | e.g. Onboarding, Events, Jobs |
| **Screen** | Exact screen name / route if known |
| **Steps to reproduce** | 1. … 2. … 3. … (number steps so anyone can follow) |
| **Expected** | What should happen (including which illustration or text) |
| **Actual** | What happened (wrong image, crash, wrong screen) |
| **Assets involved** | e.g. `onboarding_screen_2.png`, or "success screen after job apply" |
| **Screenshot / recording** | Attach if possible |
| **Severity** | Critical / High / Medium / Low |

---

## 7. Staging Sign-Off

Before considering staging "done" for a release:

- [ ] All items in **Section 1** (Staging setup) are checked.
- [ ] All **Section 2** illustration cross-checks are done; mismatches logged as bugs.
- [ ] All **Section 3** screens are confirmed present (or N/A) and reachable.
- [ ] All **Section 4** scenarios run at least once; failures documented with steps to reproduce.
- [ ] All **Section 5** test cases executed and Pass/Fail recorded.
- [ ] Critical/High bugs from this run are fixed or accepted with due date.
- [ ] Sign-off: _________________ Date: __________

---

*Document version: 1.0 | Last updated: Feb 2025 | Project: Habra Mobile App*
