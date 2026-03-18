# QA Checklist — Business Owner Flow

Use this checklist to test the **Business Owner** experience in the Habra mobile app. Many features use **mock data** (no Supabase persistence yet); see [BUSINESS_OWNER_SYNC_ANALYSIS.md](BUSINESS_OWNER_SYNC_ANALYSIS.md) for implementation status.

---

## 1. Pre-requisites

| # | Check | Pass |
|---|-------|------|
| 1.1 | App built with correct Supabase URL and anon key | ☐ |
| 1.2 | Test business owner account exists with `profiles.role = 'businessOwner'` | ☐ |
| 1.3 | (Optional) Business row in `businesses` with `owner_id` = test user | ☐ |
| 1.4 | Note: Dashboard, Boosts, Create Deal/Job use **mock** data—no real persistence | ☐ |

---

## 2. Entry & Authentication

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 2.1 | Choose Path screen | Tap "Business Owner" | ☐ |
| 2.2 | Sign In (business owner credentials) | Success → Business Owner Home | ☐ |
| 2.3 | Wrong path (customer account) | Appropriate error or redirect | ☐ |
| 2.4 | Invalid credentials | Clear error message | ☐ |

---

## 3. Business Owner Navigation

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 3.1 | Bottom nav | Home, Dashboard, Boosts, Profile | ☐ |
| 3.2 | Open hamburger menu | Business Owner drawer | ☐ |
| 3.3 | Drawer header | Business name/placeholder, location | ☐ |
| 3.4 | Drawer items | Home, Dashboard, Edit Business, Update Hours, Boost Listing, Settings, Sign Out | ☐ |

---

## 4. Home Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 4.1 | Home tab loads | Business overview UI | ☐ |
| 4.2 | Single business view | Snapshot cards, quick actions | ☐ |
| 4.3 | All Businesses view (if multiple) | Business selector | ☐ |
| 4.4 | Setup incomplete | Prompt to complete setup | ☐ |
| 4.5 | Active deals list | (Mock: often empty) | ☐ |
| 4.6 | Job posts list | (Mock: often empty) | ☐ |
| 4.7 | Recent activity | (Mock: often empty) | ☐ |
| 4.8 | No crash with empty data | Graceful empty states | ☐ |

---

## 5. Dashboard Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 5.1 | Open Dashboard | Tabs: Analytics, Deals, Jobs, Reviews | ☐ |
| 5.2 | Analytics tab | Overview stats or empty state | ☐ |
| 5.3 | Deals tab | Deals list or empty state | ☐ |
| 5.4 | Jobs tab | Jobs list or empty state | ☐ |
| 5.5 | Reviews tab | Reviews list or empty state | ☐ |
| 5.6 | Empty state illustrations | Correct per section (no deals, no jobs, no reviews, no analytics) | ☐ |
| 5.7 | FAB (Create Deal / Create Job) | FAB visible; opens create flow | ☐ |
| 5.8 | Deals filter | Active / Expired / Draft | ☐ |
| 5.9 | View Applicants (Jobs) | Applicants list (mock) | ☐ |
| 5.10 | Reply to Review | Reply form opens (mock; does not persist) | ☐ |

---

## 6. Create Deal (UI Only — Mock)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 6.1 | Dashboard Deals → Create | Create Deal form | ☐ |
| 6.2 | Fill form fields | All fields accept input | ☐ |
| 6.3 | Submit | Success or "coming soon" (no Supabase insert yet) | ☐ |
| 6.4 | Cancel | Return to Dashboard | ☐ |
| 6.5 | Validation | Required fields enforced | ☐ |

---

## 7. Create Job Post (UI Only — Mock)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 7.1 | Dashboard Jobs → Create | Create Job form | ☐ |
| 7.2 | Fill form (title, description, etc.) | All fields accept input | ☐ |
| 7.3 | Submit | Success or "coming soon" (no Supabase insert yet) | ☐ |
| 7.4 | Cancel | Return to Dashboard | ☐ |
| 7.5 | Validation | Required fields enforced | ☐ |

---

## 8. Job Applicants (Mock)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 8.1 | Dashboard Jobs → View Applicants | Applicants list (mock; often empty) | ☐ |
| 8.2 | Tap applicant | Applicant detail | ☐ |
| 8.3 | Applicant detail | Name, cover letter, resume link (if any) | ☐ |
| 8.4 | Update status (if UI exists) | (Mock; no persistence) | ☐ |

---

## 9. Boosts Tab (Mock)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 9.1 | Open Boosts tab | Boosts list or empty state | ☐ |
| 9.2 | Empty state | Correct illustration | ☐ |
| 9.3 | Boost Now | Start boost flow | ☐ |
| 9.4 | Select job to boost | Job picker (mock) | ☐ |
| 9.5 | Select deal to boost | Deal picker (mock) | ☐ |
| 9.6 | Select location | Location selection (mock) | ☐ |
| 9.7 | Boost options | Options and pricing (mock) | ☐ |
| 9.8 | Order confirmation | Confirmation screen (no real payment) | ☐ |
| 9.9 | Active boost → Cancel | Cancel sheet (mock) | ☐ |

---

## 10. Drawer Actions

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 10.1 | Edit Business | "Coming soon" or edit form | ☐ |
| 10.2 | Update Hours | "Coming soon" or hours form | ☐ |
| 10.3 | Boost Listing | Navigate to Boosts | ☐ |
| 10.4 | Settings | Settings page (shared with community) | ☐ |
| 10.5 | Sign Out | Return to Choose Path | ☐ |

---

## 11. Profile Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 11.1 | Profile tab | Same ProfilePage as community | ☐ |
| 11.2 | Edit Profile | Works (uses `profiles` from Supabase) | ☐ |
| 11.3 | Avatar upload | Works (Supabase storage) | ☐ |

---

## 12. Error Handling

| # | Scenario | Expected Result | Pass |
|---|----------|-----------------|------|
| 12.1 | Mock empty data | No crash; empty states | ☐ |
| 12.2 | Network error on auth | Clear error message | ☐ |
| 12.3 | Session expired | Redirect to sign in | ☐ |

---

## 13. Implementation Notes

- **Dashboard data:** Analytics, Deals, Jobs, Reviews come from `DashboardRemoteDataSourceImpl` which returns **null/empty**.
- **Create Deal / Create Job:** Forms only; no repository/datasource calls to Supabase.
- **Reply to Review:** UI only; no update to `reviews` table.
- **Boosts:** All methods return empty lists or no‑ops.
- **Owner's businesses:** No API to load businesses by `owner_id`; home/drawer use empty/mock data.

When backend is wired, re-run this checklist and verify data persistence.

---

## 14. Sign-Off

- [ ] All screens reachable without crash
- [ ] Empty states display correctly
- [ ] Auth and profile (Supabase) work
- [ ] Mock flows complete without error

**Tester:** _________________ **Date:** __________

---

*Document version: 1.0 | Project: Habra Mobile App*
