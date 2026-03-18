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

---

## Image Upload Troubleshooting

If business images (logo, cover/background) are not uploading, check:

### 1. Supabase Storage – Bucket & Policies
The `businesses` bucket must exist and have correct policies. Run the migration:
- **File**: `docs/supabase/migrations/add_businesses_storage_bucket.sql`
- **How**: Supabase Dashboard → SQL Editor → paste and run

This creates the bucket (5MB file limit) and policies so authenticated users can upload.

### 2. Image Size
- **Limit**: 5MB per file (StorageService default)
- **Formats**: JPG, JPEG, PNG, WebP, GIF only
- **Error**: "Image must be under 5MB" → compress or resize before upload

### 3. Permissions
- User must be **authenticated** (signed in)
- For existing business: user must be the **owner** (owner_id = auth.uid())
- For new business: path is `{user_id}/new/{timestamp}/...` – user can upload to own path

### 4. Loader not dismissing on error
- The loader overlay is now dismissed **before** the error card is shown.
- `LoaderHelper.hide()` is `async` – flows that show an error after the loader must `await LoaderHelper.hide(ctx)` before calling `ErrorDisplayHelper.show()`.
- If the loader stays visible, ensure the upload/save flow is wrapped in `try/catch` and `LoaderHelper.hide` is called in the `catch` block (e.g. `edit_business_page`, `business_images_upload_dialog`).

### 5. Debugging
- Check the error message in the error card (or console)
- In Supabase Dashboard → Storage → `businesses` bucket: verify bucket exists and is public
- In Storage → Policies: verify `businesses_insert` and `businesses_select` exist

---

## QA Validation Checklist

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

### Central Error Display
- [ ] Trigger an error (e.g. upload with no internet) → error card appears above dialogs/loaders
- [ ] Error card shows user-friendly message, Dismiss button works
- [ ] Try Again (when provided) works correctly

### New Location
- [ ] Add New Presence → New Location → brand list shows existing businesses
- [ ] Select brand → Add Location → fill address → Complete Registration
- [ ] Verify new business created in Supabase
- [ ] Verify logo/background inherited from parent
- [ ] Same hours as main → verify hours copied from parent
- [ ] Listing Status page shows new location
