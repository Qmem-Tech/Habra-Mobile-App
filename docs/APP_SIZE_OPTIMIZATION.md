# App Size Optimization Guide

This document outlines best practices to keep your Flutter app size small for Android and iOS.

## 📊 Understanding App Size

### Android App Size Components
- **APK**: Full package (all architectures)
- **AAB (App Bundle)**: Google Play optimized (recommended)
- **Split APKs**: Architecture-specific (arm64-v8a, armeabi-v7a, x86_64)

### iOS App Size Components
- **IPA**: Full package
- **App Thinning**: Automatic by App Store

## 🎯 Best Practices for App Size Optimization

### 1. **Use App Bundles (AAB) for Android**

**Always build AAB instead of APK for production:**

```bash
# Build AAB (recommended)
flutter build appbundle --release

# Instead of APK
# flutter build apk --release
```

**Benefits:**
- Google Play automatically generates optimized APKs per device
- Reduces download size by ~30-50%
- Only includes necessary native libraries

### 2. **Enable Code Shrinking (ProGuard/R8)**

**Android (`android/app/build.gradle.kts`):**

```kotlin
buildTypes {
    release {
        // Enable code shrinking
        isMinifyEnabled = true
        isShrinkResources = true

        // ProGuard rules
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

**Create `android/app/proguard-rules.pro`:**
```proguard
# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }

# Keep Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Keep your models
-keep class com.habra.habra_mobile_app.features.** { *; }
```

### 3. **Optimize Images and Assets**

**Best Practices:**
- Use **WebP** format for images (30-50% smaller than PNG)
- Use **vector graphics** (SVG) when possible
- Compress images before adding to assets
- Use appropriate image sizes (don't use 2x images on 1x screens)

**Tools:**
```bash
# Convert PNG to WebP
cwebp input.png -q 80 -o output.webp

# Compress images
# Use tools like TinyPNG, ImageOptim, or Squoosh
```

**In `pubspec.yaml`:**
```yaml
flutter:
  assets:
    - assets/images/  # Only include necessary images
```

### 4. **Remove Unused Dependencies**

**Regular audit:**
```bash
# Check unused dependencies
flutter pub outdated
flutter pub deps

# Remove unused packages from pubspec.yaml
```

**Common heavy packages to avoid if not needed:**
- `video_player` (if not using videos)
- `camera` (if not using camera)
- `image_picker` (if not picking images)
- `webview_flutter` (if not using webviews)

### 5. **Use Tree Shaking**

Flutter automatically tree-shakes unused code, but ensure:
- Don't import entire packages when you only need specific classes
- Use `show` keyword for selective imports:

```dart
// ❌ Bad - imports entire package
import 'package:firebase_auth/firebase_auth.dart';

// ✅ Good - only imports what you need
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth, User;
```

### 6. **Optimize Native Dependencies**

**Check native library sizes:**
```bash
# Android
flutter build apk --release --split-per-abi
# Check sizes in build/app/outputs/apk/

# iOS
flutter build ios --release
# Check size in Xcode
```

**Remove unused native code:**
- Review `android/app/build.gradle.kts` for unnecessary dependencies
- Review iOS Podfile for unused pods

### 7. **Enable Split APKs (Android)**

Build separate APKs per architecture:

```bash
flutter build apk --release --split-per-abi
```

This creates:
- `app-arm64-v8a-release.apk` (~15-20 MB)
- `app-armeabi-v7a-release.apk` (~15-20 MB)
- `app-x86_64-release.apk` (~15-20 MB)

Instead of one large APK (~40-50 MB)

### 8. **Optimize Firebase**

**Only include Firebase services you use:**

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  # Only add what you need:
  # firebase_storage: ^11.5.6  # Only if using storage
  # firebase_messaging: ^14.7.10  # Only if using push notifications
  # firebase_analytics: ^10.7.4  # Only if using analytics
```

**Firebase App Check (optional):**
- Consider using Firebase App Check to reduce bot traffic
- Doesn't affect size but improves security

### 9. **Optimize Localization**

**Only include languages you support:**

```dart
// lib/core/localization/localization_cubit.dart
List<Locale> get supportedLocales => const [
  Locale('en'),
  Locale('ar'),
  Locale('fr'),
  // Don't add languages you don't use
];
```

**Remove unused ARB files:**
- Only keep `app_en.arb`, `app_ar.arb`, `app_fr.arb` if you use all three
- Remove others from `l10n/` folder

### 10. **Use Lazy Loading**

**Load heavy resources on-demand:**
- Load images from network when needed
- Use pagination for lists
- Load features only when accessed

### 11. **Optimize Fonts**

**Only include fonts you use:**
```yaml
flutter:
  fonts:
    - family: YourFont
      fonts:
        - asset: fonts/YourFont-Regular.ttf
        # Only add weights/styles you use
```

**Or use system fonts** (no font files needed):
```dart
// Use system fonts
TextStyle(fontFamily: null) // Uses system default
```

### 12. **Remove Debug Code**

**Ensure release builds exclude debug code:**

```dart
// Use kDebugMode
if (kDebugMode) {
  print('Debug info');
}

// Or use conditional imports
import 'package:flutter/foundation.dart' show kReleaseMode;
```

### 13. **Optimize Build Configuration**

**Android - `android/app/build.gradle.kts`:**

```kotlin
android {
    defaultConfig {
        // Remove unnecessary features
        resConfigs("en", "ar", "fr") // Only include used languages

        // Enable multidex only if needed (>65K methods)
        // multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
        }
    }
}
```

**iOS - `ios/Runner.xcconfig`:**

```
// Optimize for size
EXCLUDED_ARCHS[sdk=iphonesimulator*] = arm64
```

### 14. **Monitor App Size**

**Regular checks:**
```bash
# Android
flutter build appbundle --release
# Check size: build/app/outputs/bundle/release/app-release.aab

# iOS
flutter build ios --release
# Check size in Xcode: Product > Archive > Distribute App
```

**Target sizes:**
- **Android AAB**: < 30 MB (before Play Store optimization)
- **iOS IPA**: < 50 MB (before App Store optimization)
- **Download size**: < 20 MB (after store optimization)

### 15. **Use Dynamic Features (Advanced)**

**Android App Bundle Dynamic Features:**
- Split large features into dynamic modules
- Download on-demand
- Reduces initial install size

### 16. **Optimize Dependencies**

**Review heavy packages:**

| Package | Size Impact | Alternative |
|---------|------------|-------------|
| `video_player` | ~5-10 MB | Use network streaming |
| `camera` | ~3-5 MB | Use image_picker only |
| `webview_flutter` | ~2-3 MB | Use url_launcher |
| `flutter_svg` | ~1-2 MB | Use vector_math if possible |

### 17. **Code-Level Optimizations**

**Avoid:**
```dart
// ❌ Creates large widget tree
ListView.builder(
  itemBuilder: (context, index) => ComplexWidget(),
)

// ✅ Use const constructors
const Text('Hello')

// ✅ Extract widgets to reduce rebuilds
```

**Use:**
```dart
// ✅ Lazy loading
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)

// ✅ Const constructors
const SizedBox(height: 16)
```

## 📈 Size Comparison

### Before Optimization
- Android APK: ~50-70 MB
- iOS IPA: ~60-80 MB

### After Optimization
- Android AAB: ~25-35 MB (download: ~15-20 MB)
- iOS IPA: ~30-40 MB (download: ~20-25 MB)

## 🔍 Tools for Analysis

### Android
```bash
# Analyze APK size
flutter build apk --release
# Use Android Studio: Build > Analyze APK

# Check AAB size
flutter build appbundle --release
# Upload to Play Console for size analysis
```

### iOS
```bash
# Build and analyze
flutter build ios --release
# Use Xcode: Product > Archive > Distribute App > Size Report
```

## ✅ Checklist

- [ ] Build AAB instead of APK for Android
- [ ] Enable ProGuard/R8 code shrinking
- [ ] Convert images to WebP format
- [ ] Remove unused dependencies
- [ ] Use selective imports (`show` keyword)
- [ ] Only include used Firebase services
- [ ] Only include used languages
- [ ] Remove unused fonts
- [ ] Enable split APKs (if not using AAB)
- [ ] Monitor app size regularly
- [ ] Use const constructors
- [ ] Optimize images before adding to assets

## 🚀 Quick Wins

1. **Build AAB** - Immediate 30-50% reduction
2. **Enable ProGuard** - 20-30% reduction
3. **Convert images to WebP** - 30-50% reduction
4. **Remove unused dependencies** - Variable reduction
5. **Use split APKs** - 50% reduction per APK

---

**Remember:** App size optimization is an ongoing process. Regularly monitor and optimize!
