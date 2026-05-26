# QA Checklist v2 — Business Owner Flow

Use this checklist to test the **Business Owner** experience in the Habra mobile app (Version 2). All features use **Supabase** for persistence unless noted.

---

## 1. Pre-requisites

| # | Check | Pass |
|---|-------|------|
| 1.1 | App built with correct Supabase URL and anon key | ☐ |
| 1.2 | Test business owner account exists with `profiles.role = 'businessOwner'` | ☐ |
| 1.3 | Business row(s) in `businesses` with `owner_id` = test user | ☐ |
| 1.4 | Storage buckets exist: `businesses`, `events`, `legal_documents` | ☐ |
| 1.5 | Migrations applied (see `QA_Update_files.md` for list) | ☐ |

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
| 4.5 | Active deals list | Loads from Supabase | ☐ |
| 4.6 | Job posts list | Loads from Supabase | ☐ |
| 4.7 | **Pull to refresh** | Data reloads | ☐ |
| 4.8 | **Refresh button** (app bar) | Data reloads | ☐ |
| 4.9 | **Add New Presence → complete** | Return to home → list shows new business | ☐ |
| 4.10 | No crash with empty data | Graceful empty states | ☐ |

---

## 5. Dashboard Tab (v2 UI)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 5.1 | Open Dashboard | Summary header + tabs: Analytics, Deals, Jobs, Reviews | ☐ |
| 5.2 | **Summary header** | Gradient card with Active Deals, Open Jobs, Rating/Reviews counts | ☐ |
| 5.3 | **Tap summary card** | Switches to corresponding tab | ☐ |
| 5.4 | **Tab bar** | Icons + labels, pill-style selection | ☐ |
| 5.5 | **Refresh button** (app bar) | Data reloads | ☐ |
| 5.6 | **Pull to refresh** (Analytics tab) | Data reloads | ☐ |
| 5.7 | Analytics tab | Overview stats or empty state | ☐ |
| 5.8 | Deals tab | Deals list or empty state | ☐ |
| 5.9 | Jobs tab | Jobs list or empty state | ☐ |
| 5.10 | Reviews tab | Reviews list or empty state | ☐ |
| 5.11 | Empty state illustrations | Correct per section | ☐ |
| 5.12 | FAB (Create Deal / Create Job) | FAB visible; opens create flow | ☐ |
| 5.13 | Deals filter | Active / Expired / Draft | ☐ |
| 5.14 | View Applicants (Jobs) | Applicants list from Supabase | ☐ |
| 5.15 | Reply to Review | Reply form; persists to Supabase | ☐ |

---

## 6. Create Deal (Supabase)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 6.1 | Dashboard Deals → Create | Create Deal form | ☐ |
| 6.2 | Fill form fields | All fields accept input | ☐ |
| 6.3 | **Date picker** (Start/End Date) | Calendar opens; value displays (YYYY-MM-DD) | ☐ |
| 6.4 | **Time picker** (Start/End Time) | Clock opens; value displays (e.g. 9:00 AM) | ☐ |
| 6.5 | Publish without dates/times | Uses defaults; deal creates | ☐ |
| 6.6 | Submit | Deal created in Supabase; success | ☐ |
| 6.7 | Cancel | Return to Dashboard | ☐ |
| 6.8 | Validation | Required fields enforced | ☐ |

---

## 7. Create Job Post (Supabase)

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 7.1 | Dashboard Jobs → Create | Create Job form | ☐ |
| 7.2 | Fill form (title, description, etc.) | All fields accept input | ☐ |
| 7.3 | Submit | Job created in Supabase; success | ☐ |
| 7.4 | Cancel | Return to Dashboard | ☐ |
| 7.5 | Validation | Required fields enforced | ☐ |

---

## 8. Job Applicants

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 8.1 | Dashboard Jobs → View Applicants | Applicants list from Supabase | ☐ |
| 8.2 | Tap applicant | Applicant detail | ☐ |
| 8.3 | Applicant detail | Name, cover letter, resume link | ☐ |
| 8.4 | Update status (if UI exists) | Persists to Supabase | ☐ |

---

## 9. Boosts Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 9.1 | Open Boosts tab | Boosts list or empty state | ☐ |
| 9.2 | Empty state | Correct illustration | ☐ |
| 9.3 | Boost Now | Start boost flow | ☐ |
| 9.4 | Select job/deal to boost | Pickers work | ☐ |
| 9.5 | Order confirmation | Confirmation screen | ☐ |
| 9.6 | Active boost → Cancel | Cancel sheet | ☐ |

---

## 10. Drawer Actions

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 10.1 | Edit Business | Edit form; saves to Supabase | ☐ |
| 10.2 | **Edit Business – logo/cover** | Upload dialog; images save to Storage | ☐ |
| 10.3 | Update Hours | Hours form; loads existing; saves | ☐ |
| 10.4 | Boost Listing | Navigate to Boosts | ☐ |
| 10.5 | Settings | Settings page | ☐ |
| 10.6 | Sign Out | Return to Choose Path | ☐ |

---

## 11. Add New Presence

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 11.1 | Add New Presence → New Business | 4-step flow (Details, Location, Contact, Photos) | ☐ |
| 11.2 | Step 4: upload cover + logo | Upload to Storage; Complete Registration | ☐ |
| 11.3 | Business created | In Supabase `businesses`; Listing Status page | ☐ |
| 11.4 | Add New Presence → New Location | Brand list shows existing businesses | ☐ |
| 11.5 | Select brand → Add Location | Address form; inherits logo/background | ☐ |
| 11.6 | Same hours as main | Hours copied from parent | ☐ |

---

## 12. Legal Documents

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 12.1 | First login (business needs docs) | Images dialog (if needed) → Legal docs dialog | ☐ |
| 12.2 | Choose business | List of businesses needing docs | ☐ |
| 12.3 | Upload 2 documents | PDF/JPG/PNG; max 10MB each | ☐ |
| 12.4 | Submit | Saved to `business_legal_documents`; status pending | ☐ |

---

## 13. Create Event

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 13.1 | Home → Quick Actions → Create Event | Create Event page opens | ☐ |
| 13.2 | Fill title, description, venue, dates | All fields work | ☐ |
| 13.3 | Add ticket types | At least one required | ☐ |
| 13.4 | Add event image | Uploads to Storage | ☐ |
| 13.5 | Submit | Event created in Supabase | ☐ |
| 13.6 | Community user | New event appears in Events tab | ☐ |

---

## 14. Profile Tab

| # | Action | Expected Result | Pass |
|---|--------|-----------------|------|
| 14.1 | Profile tab | Same ProfilePage as community | ☐ |
| 14.2 | Edit Profile | Works; uses `profiles` from Supabase | ☐ |
| 14.3 | Avatar upload | Works; Supabase storage | ☐ |

---

## 15. Error Handling

| # | Scenario | Expected Result | Pass |
|---|----------|-----------------|------|
| 15.1 | Empty data | No crash; empty states | ☐ |
| 15.2 | Network error on auth | Clear error message | ☐ |
| 15.3 | Upload error (e.g. file too large) | Error card overlay; user-friendly message | ☐ |
| 15.4 | Session expired | Redirect to sign in | ☐ |

---

## 16. Sign-Off

- [ ] All screens reachable without crash
- [ ] Dashboard summary header and tabs work
- [ ] Pull-to-refresh and refresh button work
- [ ] Create Deal/Job/Event persist to Supabase
- [ ] Edit Business, Update Hours, Legal docs work
- [ ] Add New Presence (business + location) works

**Tester:** _________________ **Date:** __________

---

*Document version: 2.0 | Project: Habra Mobile App | Updated: Mar 2025*
