# QA Checklist — Community Member Flow

Use this checklist to test the **Community Member** (customer) experience in the Habra mobile app. Check off each item as you verify it.

---

## 1. Pre-requisites

| # | Check | Pass |
|---|-------|------|
| 1.1 | App is built with correct Supabase URL and anon key (staging or production) | ☐ |
| 1.2 | Supabase project has schema applied (`habra_full_schema.sql`) | ☐ |
| 1.3 | Storage buckets exist (avatars, businesses, deals, events, reviews, resumes) | ☐ |
| 1.4 | Auth providers enabled (Email, optionally Google) | ☐ |
| 1.5 | Test accounts exist in Supabase (or can sign up) | ☐ |
| 1.6 | At least one approved business with deals, events, and jobs for testing | ☐ |

---

## 2. Entry & Onboarding

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 2.1 | Cold start app | Splash screen shows Habra logo | ☐ |
| 2.2 | First launch (onboarding not completed) | Onboarding flow shows 3 screens | ☐ |
| 2.3 | Onboarding page 1 | "Discover Your Community" + correct illustration | ☐ |
| 2.4 | Tap Next | Page 2: "Support Local Businesses" | ☐ |
| 2.5 | Tap Next | Page 3: "Grow Together" | ☐ |
| 2.6 | Tap Get Started | Navigate to Choose Path | ☐ |
| 2.7 | Tap Skip/Close (if available) | Skip to Choose Path | ☐ |
| 2.8 | Second launch (onboarding completed) | Splash → Choose Path (no onboarding) | ☐ |

---

## 3. Choose Path & Authentication

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 3.1 | Choose Path screen | "Community Member" and "Business Owner" options visible | ☐ |
| 3.2 | Tap Community Member | Navigate to Sign In / Sign Up | ☐ |
| 3.3 | Sign In with email + password | Success → Customer Home with bottom nav | ☐ |
| 3.4 | Sign In with Google (if enabled) | Success → Customer Home | ☐ |
| 3.5 | Sign Up with email | Create account; email verification if enabled | ☐ |
| 3.6 | Forgot Password | Email sent; reset flow works | ☐ |
| 3.7 | Continue as Guest (if enabled) | Anonymous sign-in → Customer Home | ☐ |
| 3.8 | Invalid credentials | Clear error message | ☐ |

---

## 4. Home & Navigation

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 4.1 | Customer Home loads | Bottom nav: Home, Events, Explore, Jobs | ☐ |
| 4.2 | Home tab | Sections: Happening This Week, Hot Deals, Popular Businesses, Latest Jobs | ☐ |
| 4.3 | Tap event card | Event detail opens | ☐ |
| 4.4 | Tap deal card | Deal detail opens | ☐ |
| 4.5 | Tap business card | Business detail opens | ☐ |
| 4.6 | Tap job card | Job detail opens | ☐ |
| 4.7 | Empty sections | Placeholder images (event, deal, business, job) | ☐ |
| 4.8 | Open hamburger menu | Navigation drawer opens | ☐ |

---

## 5. Events Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 5.1 | Open Events tab | Events list (or empty state) | ☐ |
| 5.2 | Tap Filters | Filter bottom sheet opens | ☐ |
| 5.3 | Apply filters | List updates | ☐ |
| 5.4 | Tap event card | Event detail with hero image, date, location | ☐ |
| 5.5 | Event detail | Correct images; no overflow or layout issues | ☐ |
| 5.6 | Select tickets (if available) | Ticket selection screen | ☐ |
| 5.7 | No events | Empty state with correct illustration | ☐ |

---

## 6. Explore Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 6.1 | Open Explore tab | Featured Businesses, Businesses, Deals sections | ☐ |
| 6.2 | Business cards | Images load (or placeholder); no overflow | ☐ |
| 6.3 | Tap business | Business detail page | ☐ |
| 6.4 | Business detail | Name, description, deals, reviews | ☐ |
| 6.5 | Tap deal | Deal detail | ☐ |
| 6.6 | Redeem deal | Redemption flow or confirmation | ☐ |
| 6.7 | Write review | Review form opens; submit works | ☐ |
| 6.8 | No businesses/deals | Empty state | ☐ |

---

## 7. Jobs Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 7.1 | Open Jobs tab | Jobs list (or empty state) | ☐ |
| 7.2 | Search bar | Type query; results update | ☐ |
| 7.3 | Tap Filters | Filter bottom sheet | ☐ |
| 7.4 | Apply filters | List updates | ☐ |
| 7.5 | Tap "My Applications" (header) | My Applications page opens | ☐ |
| 7.6 | Tap job card | Job detail with company logo, title, description | ☐ |
| 7.7 | Tap Apply Now | Apply for Job form | ☐ |
| 7.8 | Fill form (name, email, phone, cover letter) | All fields accept input | ☐ |
| 7.9 | Attach resume (PDF/DOC/DOCX) | File picker opens; file selected | ☐ |
| 7.10 | Submit application | Success message; redirect or confirmation | ☐ |
| 7.11 | Resume upload error | Clear error message (e.g. bucket missing) | ☐ |
| 7.12 | No jobs found | No Jobs Found page with illustration | ☐ |

---

## 8. My Applications

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 8.1 | Drawer → My Applications | My Applications page | ☐ |
| 8.2 | Jobs tab → My Applications | Same page | ☐ |
| 8.3 | With applications | List shows job title, company, status, date | ☐ |
| 8.4 | Status labels | Application Sent, Under Review, Interview Scheduled, Hired, Closed | ☐ |
| 8.5 | No applications | Empty state with Retry button | ☐ |
| 8.6 | Retry on error | Reloads applications | ☐ |
| 8.7 | Tap application card | (View detail if implemented) | ☐ |

---

## 9. Search

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 9.1 | Open Search (drawer or icon) | Search page | ☐ |
| 9.2 | Search for business/event/deal/job | Results grouped by type | ☐ |
| 9.3 | No results | No results illustration and message | ☐ |
| 9.4 | Tap result | Navigate to detail | ☐ |

---

## 10. Notifications

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 10.1 | Tap notification icon | Notifications page | ☐ |
| 10.2 | With notifications | List shows items | ☐ |
| 10.3 | No notifications | Empty state illustration | ☐ |
| 10.4 | Mark as read (if supported) | State updates | ☐ |

---

## 11. Drawer & Profile

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 11.1 | Drawer header | User name, email, avatar | ☐ |
| 11.2 | View Profile | Profile page | ☐ |
| 11.3 | Saved Items | Saved businesses, events, jobs | ☐ |
| 11.4 | My Review | My reviews list | ☐ |
| 11.5 | My Applications | My Applications page | ☐ |
| 11.6 | Settings | Settings page | ☐ |
| 11.7 | Sign Out | Return to Choose Path / Sign In | ☐ |

---

## 12. Profile & Settings

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 12.1 | Profile page | Name, email, avatar, location | ☐ |
| 12.2 | Edit Profile | Edit form; save updates profile | ☐ |
| 12.3 | Avatar upload | Image picker; upload to Supabase | ☐ |
| 12.4 | Settings | Language, notifications, etc. | ☐ |

---

## 13. Error Handling & Edge Cases

| # | Scenario | Expected Result | Pass |
|---|----------|-----------------|------|
| 13.1 | No network | Graceful error; retry option | ☐ |
| 13.2 | Session expired | Redirect to sign in | ☐ |
| 13.3 | Invalid/expired deep link | Handled without crash | ☐ |
| 13.4 | Large images | No crash; reasonable load time | ☐ |
| 13.5 | Rotate device | Layout adapts | ☐ |
| 13.6 | Back from detail | No duplicate navigation | ☐ |

---

## 14. Sign-Off

- [ ] All critical paths (auth, home, jobs, apply, my applications) tested
- [ ] No crashes on main flows
- [ ] Supabase data loads correctly
- [ ] Error states show user-friendly messages

**Tester:** _________________ **Date:** __________

---

*Document version: 1.0 | Project: Habra Mobile App*
