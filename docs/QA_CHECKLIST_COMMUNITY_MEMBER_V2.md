# QA Checklist v2 — Community Member Flow

Use this checklist to test the **Community Member** (customer) experience in the Habra mobile app (Version 2). Check off each item as you verify it.

---

## 1. Pre-requisites

| # | Check | Pass |
|---|-------|------|
| 1.1 | App built with correct Supabase URL and anon key (staging or production) | ☐ |
| 1.2 | Supabase project has schema applied | ☐ |
| 1.3 | Storage buckets exist (avatars, businesses, deals, events, reviews, resumes) | ☐ |
| 1.4 | Auth providers enabled (Email, optionally Google) | ☐ |
| 1.5 | Test accounts exist (or can sign up) | ☐ |
| 1.6 | At least one approved business with deals, events, jobs | ☐ |

---

## 2. Entry & Onboarding

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 2.1 | Cold start app | Splash screen shows Habra logo | ☐ |
| 2.2 | First launch (onboarding not completed) | Onboarding flow shows 3 screens | ☐ |
| 2.3 | Onboarding page 1 | "Discover Your Community" + illustration | ☐ |
| 2.4 | Tap Next | Page 2: "Support Local Businesses" | ☐ |
| 2.5 | Tap Next | Page 3: "Grow Together" | ☐ |
| 2.6 | Tap Get Started | Navigate to Choose Path | ☐ |
| 2.7 | Second launch | Splash → Choose Path (no onboarding) | ☐ |

---

## 3. Choose Path & Authentication

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 3.1 | Choose Path screen | "Community Member" and "Business Owner" visible | ☐ |
| 3.2 | Tap Community Member | Navigate to Sign In / Sign Up | ☐ |
| 3.3 | Sign In with email + password | Success → Customer Home | ☐ |
| 3.4 | Sign In with Google (if enabled) | Success → Customer Home | ☐ |
| 3.5 | Sign Up with email | Create account; verification if enabled | ☐ |
| 3.6 | Forgot Password | Email sent; reset flow works | ☐ |
| 3.7 | Invalid credentials | Clear error message | ☐ |

---

## 4. Home & Navigation

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 4.1 | Customer Home loads | Bottom nav: Home, Events, Explore, Jobs | ☐ |
| 4.2 | **Recommended for you** | Section visible when data exists | ☐ |
| 4.3 | **Recommended chips** | All, Businesses, Events, Deals filter correctly | ☐ |
| 4.4 | **Tap recommended card** | Business/Event/Deal detail opens | ☐ |
| 4.5 | Home tab sections | Happening This Week, Hot Deals, Popular Businesses, Latest Jobs | ☐ |
| 4.6 | Tap event card | Event detail opens | ☐ |
| 4.7 | Tap deal card | Deal detail opens | ☐ |
| 4.8 | Tap business card | Business detail opens | ☐ |
| 4.9 | Tap job card | Job detail opens | ☐ |
| 4.10 | Empty sections | Placeholder images | ☐ |
| 4.11 | Open hamburger menu | Navigation drawer opens | ☐ |

---

## 5. Events Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 5.1 | Open Events tab | Events list (or empty state) | ☐ |
| 5.2 | Tap Filters | Filter bottom sheet opens | ☐ |
| 5.3 | Apply filters | List updates | ☐ |
| 5.4 | Tap event card | Event detail with hero image, date, location | ☐ |
| 5.5 | Event detail | Correct images; no overflow | ☐ |
| 5.6 | Select tickets | Ticket selection screen | ☐ |
| 5.7 | **Checkout flow** | Contact info → Pay → Order created | ☐ |
| 5.8 | **Payment (RevenueCat)** | Sandbox purchase or simulated fallback | ☐ |
| 5.9 | Order confirmation | Success page after payment | ☐ |
| 5.10 | No events | Empty state with illustration | ☐ |

---

## 6. Explore Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 6.1 | Open Explore tab | Featured Businesses, Businesses, Deals sections | ☐ |
| 6.2 | **Pull to refresh** | Businesses and deals reload | ☐ |
| 6.3 | Business cards | Images load (or placeholder); no overflow | ☐ |
| 6.4 | Tap business | Business detail page | ☐ |
| 6.5 | Business detail | Name, description, deals, reviews | ☐ |
| 6.6 | Tap deal | Deal detail | ☐ |
| 6.7 | Redeem deal | Redemption flow or confirmation | ☐ |
| 6.8 | Write review | Review form; submit works | ☐ |
| 6.9 | No businesses/deals | Empty state | ☐ |

---

## 7. Directory (Search)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 7.1 | Open Directory | Search page | ☐ |
| 7.2 | **Search debounced** | Type query → results update after ~400 ms | ☐ |
| 7.3 | **Refresh button** | List reloads | ☐ |
| 7.4 | No results | Empty state; "New businesses may need admin approval" | ☐ |
| 7.5 | Tap result | Navigate to detail | ☐ |

---

## 8. Jobs Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 8.1 | Open Jobs tab | Jobs list (or empty state) | ☐ |
| 8.2 | Search bar | Type query; results update | ☐ |
| 8.3 | Tap Filters | Filter bottom sheet | ☐ |
| 8.4 | Apply filters | List updates | ☐ |
| 8.5 | Tap "My Applications" | My Applications page opens | ☐ |
| 8.6 | Tap job card | Job detail with logo, title, description | ☐ |
| 8.7 | Tap Apply Now | Apply for Job form | ☐ |
| 8.8 | Fill form | All fields accept input | ☐ |
| 8.9 | Attach resume (PDF/DOC/DOCX) | File picker; file selected | ☐ |
| 8.10 | Submit application | Success; application stored | ☐ |
| 8.11 | No jobs found | No Jobs Found page with illustration | ☐ |

---

## 9. My Applications

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 9.1 | Drawer or Jobs → My Applications | My Applications page | ☐ |
| 9.2 | With applications | List shows job title, company, status, date | ☐ |
| 9.3 | Status labels | Application Sent, Under Review, Interview, Hired, Closed | ☐ |
| 9.4 | No applications | Empty state with Retry button | ☐ |

---

## 10. Search

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 10.1 | Open Search (drawer or icon) | Search page | ☐ |
| 10.2 | Search for business/event/deal/job | Results grouped by type | ☐ |
| 10.3 | No results | No results illustration and message | ☐ |
| 10.4 | Tap result | Navigate to detail | ☐ |

---

## 11. Notifications

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 11.1 | Tap notification icon | Notifications page | ☐ |
| 11.2 | With notifications | List shows items | ☐ |
| 11.3 | No notifications | Empty state illustration | ☐ |
| 11.4 | Mark as read | State updates | ☐ |

---

## 12. Drawer & Profile

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 12.1 | Drawer header | User name, email, avatar | ☐ |
| 12.2 | View Profile | Profile page | ☐ |
| 12.3 | **Profile: tap avatar** | Edit Profile opens | ☐ |
| 12.4 | **Profile: long name/email** | No overflow (ellipsis) | ☐ |
| 12.5 | Saved Items | Saved businesses, events, jobs | ☐ |
| 12.6 | My Review | My reviews list | ☐ |
| 12.7 | My Applications | My Applications page | ☐ |
| 12.8 | Settings | Settings page | ☐ |
| 12.9 | Sign Out | Return to Choose Path | ☐ |

---

## 13. Profile & Settings

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 13.1 | Profile page | Name, email, avatar, location | ☐ |
| 13.2 | Edit Profile | Edit form; save updates profile | ☐ |
| 13.3 | Avatar upload | Image picker; upload to Supabase | ☐ |
| 13.4 | Settings | Language, notifications, etc. | ☐ |

---

## 14. Layout & UX

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 14.1 | Bottom nav | Reduced padding; no excessive space | ☐ |
| 14.2 | Checkout pay button | Reasonable padding | ☐ |
| 14.3 | Event location map | Map displays correctly | ☐ |

---

## 15. Error Handling & Edge Cases

| # | Scenario | Expected Result | Pass |
|---|----------|-----------------|------|
| 15.1 | No network | Graceful error; retry option | ☐ |
| 15.2 | Session expired | Redirect to sign in | ☐ |
| 15.3 | Invalid/expired deep link | Handled without crash | ☐ |
| 15.4 | Large images | No crash; reasonable load time | ☐ |
| 15.5 | Rotate device | Layout adapts | ☐ |
| 15.6 | Back from detail | No duplicate navigation | ☐ |

---

## 16. Sign-Off

- [ ] All critical paths (auth, home, events, checkout, jobs, apply) tested
- [ ] Recommendations section works
- [ ] Explore refresh and Directory search work
- [ ] Profile avatar tap and overflow handling work
- [ ] Event checkout and payment complete
- [ ] No crashes on main flows

**Tester:** _________________ **Date:** __________

---

*Document version: 2.0 | Project: Habra Mobile App | Updated: Mar 2025*
