# QA Update Files – Fixes and Features

This document lists fixes and features implemented for validation. Use it as a QA checklist.

---

## 1. Hours Functionality

### Fixes
- **Load existing hours**: `UpdateHoursPage` now loads current opening/closing times from Supabase when opened.
- **BlocProvider for navigation**: `UpdateHoursPage` is wrapped with `BlocProvider<DashboardCubit>.value` when navigating from drawer or quick actions (Home, Dashboard, Boosts) so it has access to `DashboardCubit`.

### Features
- **Preset time chips**: Quick-select chips for common times (6:00 AM, 8:00 AM, 9:00 AM, 10:00 AM, 12:00 PM, 5:00 PM, 6:00 PM, 9:00 PM).
- **Time picker**: Tap the field to open the system time picker for custom times.
- **Save flow**: Try/finally around loader and error handling.

### Files Changed
- `lib/features/dashboard/presentation/pages/update_hours_page.dart`
- `lib/features/dashboard/data/datasources/dashboard_supabase_datasource.dart` – added `getBusinessHours`, `_normalizeTime`
- `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart` – added `getBusinessHours`
- `lib/features/dashboard/domain/repositories/dashboard_repository.dart` – added `getBusinessHours`
- `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart` – added `getBusinessHours`
- `lib/features/dashboard/presentation/bloc/dashboard_cubit.dart` – added `getBusinessHours`
- `lib/features/home/presentation/pages/business_owner_home_page.dart` – wrap `UpdateHoursPage` with `BlocProvider`
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` – wrap `UpdateHoursPage` with `BlocProvider`
- `lib/features/boosts/presentation/pages/boosts_page.dart` – wrap `UpdateHoursPage` with `BlocProvider`

### Supabase
- No migration needed. `businesses` already has `opening_time` and `closing_time` (TIME).

---

## 2. Job Applications – photoUrl Parameter

### Fix
- **Missing parameter**: `JobApplicationsRemoteDataSourceImpl.submitApplication` was missing the `photoUrl` parameter, causing a compile error.

### Files Changed
- `lib/features/jobs/data/datasources/job_applications_remote_datasource.dart` – added `photoUrl` to `submitApplication` signature

---

## 3. Business Images Upload Dialog – Import Path & Context

### Fix
- **Wrong import path**: `business_images_upload_dialog.dart` used `../../bloc/dashboard_cubit.dart`, which resolved to `lib/features/dashboard/bloc/` (non-existent). The bloc lives at `presentation/bloc/`.
- **Solution**: Use `import '../bloc/dashboard_cubit.dart';` (from `widgets/`, one level up to `presentation/`, then `bloc/`).
- **Error**: `'DashboardCubit' isn't a type` – caused by the failed import.
- **use_build_context_synchronously**: Capture `cubit` before any `await` in `_save()`, then use it after.

### Files Changed
- `lib/features/dashboard/presentation/widgets/business_images_upload_dialog.dart` – fixed import path, capture cubit before async

---

## 3b. Add Photos Step 4 – StorageService Import

### Fix
- **Missing import**: `add_photos_step4_page.dart` uses `di.sl<StorageService>()` but did not import `StorageService`, causing `'StorageService' isn't a type`.
- **Solution**: Add `import 'package:habra_mobile_app/core/services/storage_service.dart';`

### Files Changed
- `lib/features/home/presentation/pages/add_photos_step4_page.dart` – added `StorageService` import

---

## 3c. Dashboard Supabase Datasource – Type Arguments

### Fix
- **Expected 0 type arguments**: Supabase Flutter's `.single()` and `.maybeSingle()` do not accept type arguments (e.g. `.single<Map<String, dynamic>>()` causes error).
- **Solution**: Use `.single()` and `.maybeSingle()` without generics, then cast: `res as Map<String, dynamic>`. The `unnecessary_cast` analyzer warning may appear but is acceptable.

### Files Changed
- `lib/features/dashboard/data/datasources/dashboard_supabase_datasource.dart` – use `.single()` / `.maybeSingle()` without type args

---

## 3d. Edit Business Page – use_build_context_synchronously

### Fix
- **BuildContext across async gaps**: `ctx.read<DashboardCubit>()` was called after `await` (uploadImage), which can use a disposed context.
- **Solution**: Capture `cubit` before any `await`, then use it after.

### Files Changed
- `lib/features/dashboard/presentation/pages/edit_business_page.dart` – capture cubit before async

---

## 4. Add Presence – Supabase Integration

### Overview
When adding a new business or location, all steps (including cover photo, logo, and contact details) are now saved to Supabase.

---

### 4.1 New Business Flow (4 Steps → Supabase)

**Data flow between steps:**
- **Step 1** (Business Details): name, category → passed to Step 2
- **Step 2** (Location): street, suite, city, state, zip → passed to Step 3
- **Step 3** (Contact): phone, email, website, hours → passed to Step 4
- **Step 4** (Photos): cover photo, logo

**On “Complete Registration” in Step 4:**
1. Upload cover photo to Supabase Storage (`businesses` bucket)
2. Upload logo to Supabase Storage
3. Create business in Supabase with:
   - name, description (category), phone, email, website
   - address_street, address_city, address_state, address_zip
   - opening_time, closing_time
   - logo_url, background_url
   - approval_status: `pending`
4. Navigate to `ListingStatusPage` with the new business

### Files Changed
- `lib/features/home/presentation/pages/business_details_step1_page.dart` – pass `step1Data` to Step 2
- `lib/features/home/presentation/pages/business_location_step2_page.dart` – accept `step1Data`, pass `step2Data` to Step 3
- `lib/features/home/presentation/pages/contact_details_step3_page.dart` – accept `step2Data`, pass `step3Data` to Step 4
- `lib/features/home/presentation/pages/add_photos_step4_page.dart` – accept `step3Data`, upload photos, create business in Supabase
- `lib/features/home/presentation/pages/listing_status_page.dart` – added optional `businessId`, `businessName`, `imageUrl`, `locationText`

---

### 4.2 New Location Flow (2 Steps → Supabase)

**ChooseBusinessBrandPage:**
- Receives owner’s presences from `AddNewPresencePage`
- Shows them as selectable brands (no more empty list)
- Passes selected brand and parent presence to `AddLocationPage`

**AddLocationPage:**
- On “Complete Registration”:
  1. Creates a new business in Supabase
  2. Inherits logo and background from parent
  3. Uses parent’s hours when “Same hours as main” is on
  4. Saves address fields
  5. Navigates to `ListingStatusPage`

### Files Changed
- `lib/features/home/presentation/pages/add_new_presence_page.dart` – accept `presences`, pass to `ChooseBusinessBrandPage`
- `lib/features/home/presentation/pages/choose_business_brand_page.dart` – accept `presences`, convert to brands, pass `parentPresence` to `AddLocationPage`
- `lib/features/home/presentation/pages/add_location_page.dart` – accept `parentPresence`, create business in Supabase on complete
- `lib/features/home/presentation/pages/business_locations_page.dart` – pass `presences` to `AddNewPresencePage`
- `lib/features/home/presentation/pages/business_owner_home_page.dart` – pass `presences` when opening `AddNewPresencePage`

---

### 4.3 createBusiness API

### Files Changed
- `lib/features/dashboard/data/datasources/dashboard_remote_datasource.dart` – added `createBusiness`
- `lib/features/dashboard/data/datasources/dashboard_supabase_datasource.dart` – added `createBusiness` implementation
- `lib/features/dashboard/domain/repositories/dashboard_repository.dart` – added `createBusiness`
- `lib/features/dashboard/data/repositories/dashboard_repository_impl.dart` – added `createBusiness`
- `lib/features/dashboard/presentation/bloc/dashboard_cubit.dart` – added `createBusiness`

### Supabase
- No new migrations. Uses existing `businesses` table and `background_url` column.
- Storage bucket: `businesses` (for logo and cover uploads).

---

## Central Error Display (AppErrorCard)

### Overview
Errors that appear behind dialogs, loaders, or other overlays are hard to see. Instead of SnackBars (which render at the bottom and can be hidden), the app uses a **central, dismissible error card** that appears as an overlay above all UI.

### Components

| File | Purpose |
|------|---------|
| `lib/core/widgets/app_error_card.dart` | Beautiful card widget with icon, title, message, Dismiss button, optional Try Again |
| `lib/core/widgets/error_display_helper.dart` | `ErrorDisplayHelper.show(context, ...)` – shows the card as a dialog overlay |

### Usage

```dart
import 'package:habra_mobile_app/core/widgets/error_display_helper.dart';

// After a catch or on failure:
try {
  await someOperation();
} catch (e) {
  if (context.mounted) {
    ErrorDisplayHelper.show(context, error: e, title: 'Upload failed');
  }
}

// With custom message:
ErrorDisplayHelper.show(context, message: 'File must be under 5MB', title: 'File too large');

// With retry callback:
ErrorDisplayHelper.show(
  context,
  error: e,
  title: 'Upload failed',
  onRetry: () => _retryUpload(),
);
```

### User-Friendly Message Mapping
`ErrorDisplayHelper` converts raw exceptions into readable messages:

| Pattern | User message |
|---------|--------------|
| connection, network, timeout | "Check your internet connection and try again." |
| unauthorized, session | "Please sign in again." |
| upload, storage, bucket | "We couldn't upload your file. Check that the file is under 5MB and try again." |
| 5mb, size, too large | "File must be under 5MB. Try a smaller image." |
| jpg, png, format | "Please use JPG, PNG, WebP, or GIF format." |
| exception, error, failed | "Something went wrong. Please try again." |

Short messages (≤120 chars) are shown as-is after stripping `Exception:` / `Error:` prefixes.

### Where It's Used
- `add_photos_step4_page.dart` – photo upload errors
- `business_images_upload_dialog.dart` – logo/background upload errors
- `add_location_page.dart` – location creation errors
- `edit_business_page.dart` – business update errors
- `create_deal_page.dart` – deal creation errors
- `create_job_post_page.dart` – job post errors
- `update_hours_page.dart` – hours save errors
- `create_event_page.dart` – event creation errors
- `write_review_page.dart` – photo upload, review submit errors
- `apply_for_job_page.dart` – resume/photo upload, application errors

### When to Use
- **Use `ErrorDisplayHelper.show()`** for errors that may appear behind dialogs, loaders, or sheets (e.g. upload failures, API errors).
- **SnackBar is fine** for quick validation hints (e.g. "Please fill in required field") or success messages that don't need to compete with overlays.

### Debug Mode
- In **debug builds** (`kDebugMode`), the error card shows the raw error text at the bottom for easier diagnosis (e.g. Supabase Storage API errors).

---

## Image Upload Troubleshooting

If business images (logo, cover/background) are not uploading, check:

### 1. Supabase Storage – Bucket & Policies
The `businesses` bucket must exist and have correct policies. Run the migration:
- **File**: `docs/supabase/migrations/add_businesses_storage_bucket.sql`
- **How**: Supabase Dashboard → SQL Editor → paste and run

This creates the bucket (5MB file limit) and policies so authenticated users can upload.

### 2. "Images uploaded but we couldn't save the update"
- Upload to Storage succeeds, but the database update fails.
- **Fix**: Run `docs/supabase/migrations/add_businesses_image_columns.sql` to ensure `logo_url`, `background_url`, and `image_urls` columns exist.
- In debug builds, the error card shows the raw Supabase error at the bottom for diagnosis.

### 3. Upload still failing (file size is fine)
If the file is under 5 MB but upload still fails:

1. **Run the permissive migration** – The strict policy may reject uploads if `businesses.owner_id` doesn't match or the schema differs. Run:
   - **File**: `docs/supabase/migrations/add_businesses_storage_permissive.sql`
   - **How**: Supabase Dashboard → SQL Editor → paste and run
   - This allows any authenticated user to upload to the `businesses` bucket.

2. **Check the raw error** – In debug builds, the error card shows the raw Supabase error at the bottom. Use it to diagnose (e.g. "bucket not found", "new row violates row-level security policy").

3. **Verify bucket exists** – Run `add_businesses_storage_bucket.sql` first if you haven't. The permissive migration only changes policies; it assumes the bucket exists.

### 4. Image Size
- **Limit**: 5MB per file (StorageService default)
- **Formats**: JPG, JPEG, PNG, WebP, GIF only
- **Error**: "Image must be under 5MB" → compress or resize before upload

### 5. Permissions
- User must be **authenticated** (signed in)
- For existing business: user must be the **owner** (owner_id = auth.uid())
- For new business: path is `{user_id}/new/{timestamp}/...` – user can upload to own path

### 6. "Please sign in again" when already signed in
- Supabase Storage RLS failures often return errors containing "unauthorized" even when the user is signed in.
- **Fix**: `ErrorDisplayHelper` now checks for storage/upload/permission errors **before** auth errors, so you'll see the upload message instead.
- If uploads still fail, run `docs/supabase/migrations/add_businesses_storage_bucket.sql` and ensure `businesses.owner_id` matches the signed-in user for existing businesses.

### 7. Loader not dismissing on error
- The loader overlay is now dismissed **before** the error card is shown.
- `LoaderHelper.hide()` is `async` – flows that show an error after the loader must `await LoaderHelper.hide(ctx)` before calling `ErrorDisplayHelper.show()`.
- If the loader stays visible, ensure the upload/save flow is wrapped in `try/catch` and `LoaderHelper.hide` is called in the `catch` block (e.g. `edit_business_page`, `business_images_upload_dialog`).

### 8. File size in UI
- **Display**: Selected images show file size (e.g. "2.3 MB / 5 MB") in a badge overlay.
- **Over-limit warning**: Size turns red when file exceeds 5 MB.
- **Pre-upload check**: Save/Complete is blocked with an error card if any file is over 5 MB.
- **Utility**: `lib/core/utils/file_utils.dart` – `FileUtils.formatFileSize(bytes)`, `FileUtils.maxImageBytes`.
- **Where**: `business_images_upload_dialog`, `add_photos_step4_page`, `edit_business_page`.

### 9. Event image upload RLS error
- **Error**: "new row violates row-level security policy" when creating event with image.
- **Fix**: Run `docs/supabase/migrations/add_events_storage_bucket.sql` in Supabase Dashboard → SQL Editor.
- If uploads still fail, run `docs/supabase/migrations/add_events_storage_permissive.sql`.

### 10. Resumes bucket not found
- **Error**: "bucket not found" when uploading resume for job application.
- **Fix**: Run `docs/supabase/migrations/add_resumes_storage_bucket.sql` in Supabase Dashboard → SQL Editor.
- If uploads still fail with permission errors, run `docs/supabase/migrations/add_resumes_storage_permissive.sql`.

### 11. Debugging
- Check the error message in the error card (or console)
- In Supabase Dashboard → Storage → `businesses` bucket: verify bucket exists and is public
- In Storage → Policies: verify `businesses_insert` and `businesses_select` exist

---

## Create Deal Page – Provider & Date/Time Pickers

### Fix: Provider&lt;BusinessOwnerHomeCubit&gt; not found

**Error**: `Could not find the correct Provider<BusinessOwnerHomeCubit> above this CreateDealPage Widget`

**Cause**: `CreateDealPage` and `CreateEventPage` use `context.read<BusinessOwnerHomeCubit>()` to get the selected business, but they were navigated to without the cubit in the widget tree (providers are scoped to routes).

**Solution**: Wrap both pages with `MultiBlocProvider` when navigating, passing `DashboardCubit` and `BusinessOwnerHomeCubit` via `.value`.

### Navigation points updated

| Location | Page | Wrapped with |
|----------|------|--------------|
| `business_owner_home_page.dart` – Setup task "Post First Deal" | `CreateDealPage` | `MultiBlocProvider` (DashboardCubit, BusinessOwnerHomeCubit) |
| `business_owner_home_page.dart` – Quick action "Create Event" | `CreateEventPage` | `MultiBlocProvider` (DashboardCubit, BusinessOwnerHomeCubit) |
| `business_owner_home_page.dart` – Quick action "Post Deal" | `CreateDealPage` | `MultiBlocProvider` (DashboardCubit, BusinessOwnerHomeCubit) |
| `dashboard_page.dart` – `_navigateToCreateDeal()` | `CreateDealPage` | `MultiBlocProvider` (DashboardCubit, BusinessOwnerHomeCubit) |

### Feature: Date and time pickers

**Before**: Start Date, End Date, Start Time, and End Time were plain `TextField`s with no way to select values.

**After**: Each field is tappable and opens the system picker:

| Field | Picker | Display format |
|-------|-------|----------------|
| Start Date | `showDatePicker` (calendar) | `YYYY-MM-DD` (e.g. 2025-03-18) |
| End Date | `showDatePicker` (calendar) | `YYYY-MM-DD` |
| Start Time | `showTimePicker` (clock) | 12h format (e.g. 9:00 AM) |
| End Time | `showTimePicker` (clock) | 12h format |

- **Placeholder**: "Tap to select" when no value is chosen.
- **Icons**: Calendar icon for dates, clock icon for times.
- **Defaults**: If dates/times are not set when publishing, payload uses: start = now, end = 7 days from now.
- **Date range**: First date = 1 year ago; last date = 2 years ahead.

### Files changed

- `lib/features/home/presentation/pages/business_owner_home_page.dart` – wrap `CreateDealPage` and `CreateEventPage` with `MultiBlocProvider` on all navigation paths
- `lib/features/dashboard/presentation/pages/dashboard_page.dart` – wrap `CreateDealPage` with `MultiBlocProvider` in `_navigateToCreateDeal()`
- `lib/features/dashboard/presentation/pages/create_deal_page.dart` – replace text controllers with `DateTime?` / `TimeOfDay?`, add `_buildDateField`, `_buildTimeField`, `_pickDate`, `_pickTime`

---

## QA Validation Checklist

### Supabase Migrations (run before testing upload flows)
Run these in Supabase Dashboard → SQL Editor if the corresponding feature fails:

| Migration | When to run |
|-----------|-------------|
| `add_notifications_and_ticket_purchases.sql` | Event ticket purchases (sold/left counts, organizer notifications) |
| `add_businesses_storage_bucket.sql` | Business images (logo, cover) upload fails |
| `add_businesses_storage_permissive.sql` | Business images still fail after bucket |
| `add_businesses_image_columns.sql` | "Images uploaded but we couldn't save the update" |
| `add_events_storage_bucket.sql` | Create Event image upload fails (RLS error) |
| `add_events_storage_permissive.sql` | Event image still fails after bucket |
| `add_resumes_storage_bucket.sql` | Resume upload fails (bucket not found) |
| `add_resumes_storage_permissive.sql` | Resume upload still fails |
| `add_business_legal_documents.sql` | Legal documents flow |
| `add_legal_documents_storage_permissive.sql` | Legal docs upload fails |
| `add_notifications_fcm_token.sql` | Push notifications |
| `add_notify_on_new_job_trigger.sql` | New job → create notifications |

### Flutter Analyze
- [ ] Run `flutter analyze` – no errors, no warnings
- [ ] No `uri_does_not_exist` (import path)
- [ ] No `non_type_as_type_argument` (DashboardCubit, StorageService)
- [ ] No `unnecessary_cast` warnings
- [ ] No `use_build_context_synchronously` info

### Hours
- [ ] Open Update Hours from drawer → existing hours load
- [ ] Change opening time via time picker → saves correctly
- [ ] Change closing time via preset chip → saves correctly
- [ ] Save hours → success message, navigates back
- [ ] Verify hours in Supabase `businesses` table

### Job Applications
- [ ] Apply for job with optional photo → no compile/runtime error
- [ ] Submit application → `photo_url` stored in `job_applications`

### Job Application – Resume Upload
- [ ] Apply for job → attach resume (PDF/DOC/DOCX, max 5MB) → upload succeeds
- [ ] No "bucket not found" error (run `add_resumes_storage_bucket.sql` if needed)
- [ ] No RLS error on resume upload (run `add_resumes_storage_permissive.sql` if needed)
- [ ] Business owner: view applicant → resume link opens/downloads

### Business Images Upload Dialog
- [ ] Open business with missing logo/background → mandatory upload dialog appears
- [ ] Upload logo and background → saves to Supabase, dialog dismisses
- [ ] No "DashboardCubit isn't a type" or import path errors

### Add Photos Step 4 (New Business)
- [ ] No "StorageService isn't a type" error when completing registration
- [ ] Cover photo and logo upload successfully to Supabase Storage

### New Business
- [ ] Add New Presence → New Business → complete all 4 steps
- [ ] Step 4: upload cover + logo → Complete Registration
- [ ] Verify business created in Supabase `businesses`
- [ ] Verify `logo_url` and `background_url` populated
- [ ] Verify address, phone, email, hours stored
- [ ] Listing Status page shows new business

### Legal Documents (2 required per business)
- **Flow**: After sign up / first login, business owners must upload 2 legal documents per business.
- **Order**: Images dialog runs first (if needed); legal documents dialog runs second (if needed). Dialogs are sequential.
- **Step 1**: Choose business from list (only those needing docs).
- **Step 2**: Upload 2 documents (PDF, JPG, PNG; max 10MB each). Status: pending.
- **Approval**: Super admin reviews and approves via Supabase Dashboard or admin panel.
- **Migrations**: Run `docs/supabase/migrations/add_business_legal_documents.sql`. If uploads fail with permission errors, run `docs/supabase/migrations/add_legal_documents_storage_permissive.sql`. If **super admin cannot see uploaded legal docs** (empty list / RLS), run `docs/supabase/migrations/fix_business_legal_documents_admin_select_rls.sql` (adds `SELECT` for `public.is_admin()`).
- **Table**: `business_legal_documents` (business_id, document_type, file_url, status, etc.).
- **Storage**: `legal_documents` bucket.

### Business Images Flow (2 steps)
- **Step 1**: When businesses need images, a "Choose Business" dialog appears first. User selects from the list of their businesses.
- **Step 2**: If the selected business already has logo + background → SnackBar "already has logo and cover photo", flow ends. If not → opens the upload dialog.
- **Component**: `lib/features/dashboard/presentation/widgets/choose_business_for_images_dialog.dart`

### Legal Documents Flow (post-login)
- [ ] After first login with business(es) needing legal docs → images dialog (if needed) appears first, then legal docs dialog
- [ ] Choose business for legal docs → upload 2 documents (PDF/JPG/PNG, max 10MB each)
- [ ] Documents saved to `business_legal_documents` with status `pending`

### Create Event (Business Owner)
- [ ] Sign in as business owner → Home tab → Quick Actions → "Create Event" visible
- [ ] Tap Create Event → Create Event page opens (no provider error)
- [ ] Fill title, description, venue, dates, add at least one ticket type
- [ ] Add event image (optional) → image uploads without "row-level security policy" error
- [ ] Submit → event created successfully, navigates back
- [ ] Verify event in Supabase `events` table
- [ ] If image upload fails: run `add_events_storage_bucket.sql` in Supabase SQL Editor
- [ ] Community user: Events tab → new event appears in list

### Create Deal Page – Provider & Date/Time
- [ ] Open Create Deal from Home (setup task or quick action) → no `Provider<BusinessOwnerHomeCubit> not found` error
- [ ] Open Create Deal from Dashboard → no provider error
- [ ] Open Create Event from Home quick action → no provider error
- [ ] Create Deal: tap Start Date → date picker opens, select date → value displays (YYYY-MM-DD)
- [ ] Create Deal: tap End Date → date picker opens, select date → value displays
- [ ] Create Deal: tap Start Time → time picker opens, select time → value displays (e.g. 9:00 AM)
- [ ] Create Deal: tap End Time → time picker opens, select time → value displays
- [ ] Create Deal: publish without selecting dates/times → uses defaults (now, now+7 days), deal creates successfully
- [ ] Create Deal: publish with custom dates/times → deal created with correct valid_from/valid_until

### Central Error Display
- [ ] Trigger an error (e.g. upload with no internet) → error card appears above dialogs/loaders
- [ ] Error card shows user-friendly message, Dismiss button works
- [ ] Try Again (when provided) works correctly

### Push Notifications & Notification UI
- **In-app notifications**: Fetched from Supabase `notifications` table via `NotificationSupabaseDataSource`.
- **FCM token**: Stored in `profiles.fcm_token` when user logs in (MainNavigationWrapper, BusinessOwnerNavigationWrapper).
- **New job trigger**: Run `add_notify_on_new_job_trigger.sql` – when a job is posted, notifications are created for users with FCM tokens.
- **UI**: Habra logo in header and empty state; clean white notification cards with subtle shadow.
- **Setup**: See `docs/PUSH_NOTIFICATIONS_SETUP.md` for Firebase config and push delivery.

### New Location
- [ ] Add New Presence → New Location → brand list shows existing businesses
- [ ] Select brand → Add Location → fill address → Complete Registration
- [ ] Verify new business created in Supabase
- [ ] Verify logo/background inherited from parent
- [ ] Same hours as main → verify hours copied from parent
- [ ] Listing Status page shows new location

---

## Community Member & Business Owner Updates (Mar 2025)

### Overview
Fixes and features for community member flow, payment integration, profile, search, and business owner dashboard.

---

### 1. Explore Page Refresh
- **Fix**: `RefreshIndicator` now reloads businesses and deals on pull-to-refresh (was empty before).
- **Files**: `lib/features/explore/presentation/pages/explore_page.dart`

### 2. Checkout & RevenueCat Payment
- **Fix**: Checkout flow creates order first, gets real order ID, then processes payment (was using fake order ID).
- **Feature**: `performCheckout` in `TicketsCubit` integrates RevenueCat for sandbox IAP; falls back to simulated success when RevenueCat has no offerings.
- **Files**: `lib/features/events/presentation/bloc/tickets_cubit.dart`, `lib/features/events/presentation/pages/checkout_page.dart`, `lib/features/events/data/datasources/events_supabase_datasource.dart`, `lib/injection/injection_container.dart`

### 3. Bottom Nav & Card Padding
- **Fix**: Reduced bottom nav padding (SafeArea + padding top: 8, bottom: 4).
- **Fix**: Reduced checkout pay button and Explore section bottom padding.
- **Files**: `lib/core/navigation/main_navigation_wrapper.dart`, `lib/features/events/presentation/pages/checkout_page.dart`, `lib/features/explore/presentation/pages/explore_page.dart`

### 4. Directory Search & Refresh
- **Fix**: Search debounced (400 ms) to avoid excessive API calls.
- **Feature**: Refresh button in app bar; empty state mentions admin approval for new businesses.
- **Files**: `lib/features/explore/presentation/pages/directory_page.dart`

### 5. Profile UX
- **Feature**: Avatar tap opens Edit Profile; camera icon overlay on avatar.
- **Fix**: `maxLines` and `overflow` on name, email, bio to prevent overflow.
- **Files**: `lib/features/home/presentation/pages/profile_page.dart`

### 6. Business Owner Dashboard Refresh
- **Feature**: Pull-to-refresh on single-business and all-businesses views.
- **Feature**: Refresh button in app bar.
- **Feature**: Returning from Add New Presence triggers reload of business list.
- **Files**: `lib/features/home/presentation/pages/business_owner_home_page.dart`

---

### QA Validation Checklist (Additions)

#### Explore & Directory
- [ ] Explore tab: pull to refresh → businesses and deals reload
- [ ] Directory: tap search bar → type query → results update after 400 ms debounce
- [ ] Directory: tap refresh icon → list reloads
- [ ] Directory: empty state shows "New businesses may need admin approval"

#### Event Checkout & Payment
- [ ] Event detail → Select tickets → Checkout → fill contact info → Pay
- [ ] Order created in Supabase with correct ID before payment
- [ ] Payment completes (RevenueCat sandbox or simulated fallback)
- [ ] Order confirmation page shows after success

#### Profile
- [ ] Profile: tap avatar → Edit Profile opens
- [ ] Profile: long name/email → no overflow (ellipsis)
- [ ] Edit Profile: Change Photo → upload works

#### Business Owner
- [ ] Home tab: pull to refresh → data reloads
- [ ] Home tab: tap refresh icon → data reloads
- [ ] Add New Presence → complete → return → home list shows new business

#### Layout
- [ ] Bottom nav: reduced padding (no excessive bottom space)
- [ ] Checkout: pay button area has reasonable padding

---

## Recommendations & Dashboard UI (Mar 2025)

### 1. Recommendations Feature (Community Member)
- **Location**: Home page, above "Happening This Week"
- **Section**: "Recommended for you" with sparkle icon
- **Selection chips**: All, Businesses, Events, Deals – filter recommended items by type
- **Content**: Horizontal scroll of businesses (compact cards), events, and deals
- **Files**: `lib/features/home/presentation/pages/home_page.dart`

### 2. Dashboard UI Update (Business Owner)
- **Summary header**: Gradient card showing Active Deals, Open Jobs, Rating/Reviews at a glance; tap to switch tab
- **Tab bar**: Icons + labels, pill-style selection, subtle shadow
- **Refresh**: Refresh button in app bar; pull-to-refresh on Analytics tab
- **Files**: `lib/features/dashboard/presentation/widgets/dashboard_summary_header.dart`, `dashboard_tab_bar.dart`, `dashboard_app_bar.dart`, `dashboard_page.dart`, `dashboard_analytics_tab.dart`

### QA Validation
- [ ] Home: "Recommended for you" section visible when data exists
- [ ] Home: Tap All/Businesses/Events/Deals chips → list filters correctly
- [ ] Home: Tap recommended business card → Business detail opens
- [ ] Dashboard: Summary header shows deals, jobs, reviews counts
- [ ] Dashboard: Tap summary card → switches to corresponding tab
- [ ] Dashboard: Tab bar shows icons; selected tab highlighted
- [ ] Dashboard: Refresh button reloads data
- [ ] Dashboard: Pull to refresh on Analytics tab works
