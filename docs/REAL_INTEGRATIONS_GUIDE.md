# Real Integrations Guide — Maps, Photos, Location & Auth Completion

This guide outlines the **recommended libraries and tools** for real (non-mocked) integrations in Habra Mobile App.

---

## 1. Authentication — Finish & Harden

### Current State
- **Supabase** (when configured via `--dart-define`) or **Firebase** fallback
- Email/password, Google Sign-In, Guest (anonymous)
- Registration with role selection (customer / business owner)

### To Finish Auth
1. **Choose one backend**: Supabase (recommended per your docs) or Firebase
2. **Supabase Dashboard**: Enable Google OAuth provider; add Google Client ID & Secret
3. **Run with Supabase**:
   ```bash
   flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
   ```
4. **Profile creation**: Ensure the `handle_new_user` trigger creates rows in `profiles` on sign-up

### Recommended Packages (Already in Use)
| Package | Purpose |
|---------|---------|
| `supabase_flutter` ^2.8.0 | Auth, DB, Storage when using Supabase |
| `firebase_auth` ^6.1.4 | Auth when using Firebase |
| `google_sign_in` ^6.1.6 | Google OAuth for both backends |

### Optional (Session Security)
| Package | Purpose |
|---------|---------|
| `flutter_secure_storage` | Store refresh tokens more securely than SharedPreferences |

---

## 2. Maps — Real Map Display

### Current State
- `MapPage` uses a gray placeholder with "Lat: x, Lng: y" text
- No real map tiles, no markers, no directions

### Recommended Packages
| Package | Purpose | Notes |
|---------|---------|------|
| **`google_maps_flutter`** ^2.5 | Native Google Maps | Best quality, requires API key, free tier (Google Cloud) |
| **`geolocator`** ^11.0 | Get user's GPS location | Permissions, accuracy |
| **`url_launcher`** ^6.2 | Open Maps/Google Maps/Waze for directions | No key needed for launch |

### Alternative (No API Key)
| Package | Purpose |
|---------|---------|
| **`flutter_map`** ^6.0 + **`latlong2`** | OpenStreetMap tiles, free, no key |

### Setup for Google Maps
1. Add to `pubspec.yaml`: `google_maps_flutter: ^2.5.0`
2. **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_API_KEY"/>
   ```
3. **iOS** (`ios/Runner/AppDelegate.swift` or `AppDelegate.m`):
   - Add `GMSServices.provideAPIKey("YOUR_API_KEY")` in `application didFinishLaunching`
4. Create API key in [Google Cloud Console](https://console.cloud.google.com/) → enable **Maps SDK for Android** and **Maps SDK for iOS**

### What to Implement
- Replace `MapPage` placeholder with `GoogleMap` widget
- Add marker for business lat/lng
- "My Location" FAB → `Geolocator.getCurrentPosition()` + animate camera
- "Directions" → `UrlLauncher.launchUrl` with `google.navigation:?q=lat,lng` or `https://maps.google.com/maps?daddr=lat,lng`

---

## 3. Photos — Real Image Picker & Upload

### Current State
- `BusinessPhotosPage`: "Image picker coming soon" — no real picker
- `WriteReviewPage`: Simulates photos with `_photos.add('photo_${_photos.length + 1}')`
- `AddPhotosStep4Page`: Boolean flags only, no actual files

### Recommended Packages
| Package | Purpose |
|---------|---------|
| **`image_picker`** ^1.0 | Camera + gallery (iOS/Android) — official plugin |
| **`image_cropper`** ^5.0 | Crop before upload (optional but recommended) |

### Storage (Already Available)
- **Supabase Storage**: `supabase.storage.from('businesses')`, `reviews`, `avatars`, etc.
- **Firebase Storage**: `firebase_storage` already in `pubspec.yaml`

### What to Implement
1. Add `image_picker: ^1.0.7` to `pubspec.yaml`
2. **Permissions**:
   - Android: `android/app/src/main/AndroidManifest.xml` — `READ_EXTERNAL_STORAGE`, `READ_MEDIA_IMAGES`, `CAMERA`
   - iOS: `ios/Runner/Info.plist` — `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`, `NSMicrophoneUsageDescription` (for video if needed)
3. Use `ImagePicker().pickImage(source: ImageSource.gallery)` or `pickImage(source: ImageSource.camera)`
4. Upload via Supabase:
   ```dart
   await Supabase.instance.client.storage
     .from('businesses')
     .upload('$businessId/cover.jpg', file, fileOptions: FileOptions(upsert: true));
   ```

---

## 4. Location — Real Geolocation & Place Search

### Current State
- `LocationSelectionPage`: Hardcoded list (Washington, Dallas, Atlanta, etc.)
- "Use Current Location" uses fake `_currentLocation = LocationEntity(id: '2', city: 'Dallas', ...)`
- No GPS, no reverse geocoding, no place search

### Recommended Packages
| Package | Purpose |
|---------|---------|
| **`geolocator`** ^11.0 | Get current position, request permissions |
| **`geocoding`** ^2.1 | Reverse (lat/lng → address) and forward (address → lat/lng) |
| **`geolocator_platform_interface`** | Used by geolocator (transitive) |

### Optional: Place Autocomplete
| Package | Purpose |
|---------|---------|
| **`google_places_flutter`** or **`flutter_google_places`** | Search cities/addresses with Google Places API |
| Or use **Geocoding API** (`geocoding` package) with a search API of your choice |

### What to Implement
1. Add `geolocator: ^11.0.0` and `geocoding: ^2.1.1` to `pubspec.yaml`
2. **Permissions**:
   - Android: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`
   - iOS: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysUsageDescription`
3. Current location:
   ```dart
   final pos = await Geolocator.getCurrentPosition(/* options */);
   final placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
   ```
4. Build `LocationEntity` from `Placemark` (city, state, country, coordinates)
5. For place search: either integrate Google Places Autocomplete or use a simpler geocoding-based search

---

## 5. Phone & Country Code

### Current State
- `PhoneSignUpPage`: Hardcoded dropdown (+1, +65, +44, +91) with plain `TextFormField`
- `ApplyForJobPage`, `ContactDetailsStep3Page`, `BusinessContactPage`, `CheckoutPage`: Plain phone `TextFormField` with no country code

### Recommended Package
| Package | Purpose |
|---------|---------|
| **`intl_phone_field`** ^3.1 | Country picker with flags + formatted phone input; outputs E.164 (e.g. `+1234567890`) |

### What to Implement
1. Replace manual country dropdown + phone field with `IntlPhoneField`:
   ```dart
   IntlPhoneField(
     decoration: InputDecoration(
       labelText: 'Phone Number',
       border: OutlineInputBorder(),
     ),
     initialCountryCode: 'US',
     onChanged: (phone) {
       // phone.completeNumber yields E.164: +12025551234
     },
   )
   ```
2. Use `phone.completeNumber` when submitting (E.164 format for storage/Supabase/Firebase Auth)
3. Pages to update: `PhoneSignUpPage`, `ApplyForJobPage`, `ContactDetailsStep3Page`, `BusinessContactPage`, `CheckoutPage`

### Optional: Validation
| Package | Purpose |
|---------|---------|
| `phonenumbers` | Validate and parse phone numbers (e.g. check if valid for country) |

---

## 6. Summary: Add to `pubspec.yaml`

```yaml
dependencies:
  # Maps
  google_maps_flutter: ^2.5.0   # or flutter_map + latlong2 for free maps
  geolocator: ^11.0.0
  url_launcher: ^6.2.0

  # Photos
  image_picker: ^1.0.7

  # Location (geocoding)
  geocoding: ^2.1.1

  # Phone & Country Code
  intl_phone_field: ^3.1.0
```

---

## 7. Implementation Order

1. **Auth** — Ensure Supabase (or Firebase) is configured; verify Google sign-in in Dashboard; test full flow.
2. **Photos** — Add `image_picker` and wire it to `BusinessPhotosPage`, `WriteReviewPage`, `AddPhotosStep4Page`; upload to Supabase Storage.
3. **Location** — Add `geolocator` + `geocoding`; implement real "Use Current Location" and optional place search.
4. **Maps** — Add `google_maps_flutter`; replace `MapPage` placeholder; add "Directions" via `url_launcher`.
5. **Phone** — Replace manual country + phone fields with `IntlPhoneField` in auth, apply, contact, checkout flows.

---

## 8. Permissions Reference

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Habra needs your location to show nearby businesses and events</string>
<key>NSCameraUsageDescription</key>
<string>Habra needs camera access to take photos for reviews and business profiles</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Habra needs photo library access to add photos to reviews and business profiles</string>
```

---

## 9. APIs & Keys Required

| Service | Where to Get | Used For |
|---------|--------------|----------|
| **Supabase URL + Anon Key** | Supabase Dashboard → Settings → API | Auth, DB, Storage |
| **Google OAuth Client ID** | Google Cloud Console → APIs & Services → Credentials | Google Sign-In |
| **Google Maps API Key** | Google Cloud Console → APIs & Services → Credentials | Maps (if using `google_maps_flutter`) |
| **Google Places API** (optional) | Same as Maps | Place autocomplete |

---

## 10. Post-Integration Setup (Required for Maps)

After integrating, complete these steps for maps to work:

1. **Google Maps API Key**
   - Create a key at [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → Credentials
   - Enable **Maps SDK for Android** and **Maps SDK for iOS**
   - **Android**: Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml`
   - **iOS**: Replace `YOUR_GOOGLE_MAPS_API_KEY` in `ios/Runner/AppDelegate.swift`
   - Run `cd ios && pod install && cd ..` after any iOS dependency changes

2. **Run the app**
   ```bash
   flutter pub get
   flutter run
   ```

---

*Document version: 1.0 | Created for Habra Mobile App*
