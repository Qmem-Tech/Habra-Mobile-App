# Android SDK Versioning Guide

## 📱 Current Configuration

- **minSdk**: 23 (Android 6.0 Marshmallow)
- **targetSdk**: Latest (managed by Flutter)
- **compileSdk**: Latest (managed by Flutter)

## 🎯 Why minSdk 23?

### Firebase Requirements
Firebase Firestore (and other Firebase services) require **minimum SDK 23** because they use APIs that are only available in Android 6.0+.

### Device Coverage
- **API 23 (Android 6.0)** covers **99%+** of active Android devices as of 2024
- Android 6.0 was released in 2015, so devices older than 9 years are excluded
- This is a reasonable trade-off for modern app development

### Benefits
1. ✅ **Access to modern APIs**: Runtime permissions, Doze mode, App Standby
2. ✅ **Better security**: Runtime permission model
3. ✅ **Firebase compatibility**: All Firebase services work properly
4. ✅ **Future-proof**: Aligns with industry standards

## 📊 Android Version Distribution (2024)

| Android Version | API Level | Market Share |
|----------------|-----------|--------------|
| Android 14 | 34 | ~5% |
| Android 13 | 33 | ~15% |
| Android 12 | 31-32 | ~20% |
| Android 11 | 30 | ~18% |
| Android 10 | 29 | ~15% |
| Android 9 | 28 | ~10% |
| Android 8 | 26-27 | ~8% |
| Android 7 | 24-25 | ~5% |
| **Android 6** | **23** | **~2%** |
| Android 5 and below | 21-22 | <1% |

**Total coverage with minSdk 23: ~99%+**

## 🔄 When to Update minSdk

### Consider increasing minSdk when:
1. **New Firebase features require it** - Check Firebase release notes
2. **You need newer Android APIs** - For specific features
3. **Market share drops** - When API 23 devices drop below 1%
4. **Security requirements** - For enterprise apps requiring latest security features

### Recommended Progression:
- **2024**: minSdk 23 (current)
- **2025-2026**: Consider minSdk 24 (Android 7.0)
- **2027+**: Consider minSdk 26 (Android 8.0)

## ⚠️ What NOT to Do

### ❌ Don't use `tools:overrideLibrary`
```xml
<!-- BAD: Forces incompatible library usage -->
<uses-sdk tools:overrideLibrary="com.google.firebase.firestore" />
```
**Why**: This can lead to runtime crashes when Firebase tries to use APIs not available in older Android versions.

### ❌ Don't use minSdk < 23 with Firebase
**Why**: Firebase Firestore and other services will fail at runtime or during build.

## ✅ Best Practices

### 1. Explicit minSdk Declaration
Always explicitly set minSdk in `build.gradle.kts`:
```kotlin
defaultConfig {
    minSdk = 23  // Explicit, not flutter.minSdkVersion
}
```

### 2. Document the Reason
Add comments explaining why:
```kotlin
// Firebase Firestore requires minSdk 23 (Android 6.0)
// API 23 covers 99%+ of active Android devices (as of 2024)
minSdk = 23
```

### 3. Test on Minimum SDK
Always test your app on an emulator/device running the minimum SDK version.

### 4. Monitor Device Coverage
Check Android distribution stats annually:
- [Android Developer Dashboard](https://developer.android.com/about/dashboards)

## 🔍 Checking Current SDK Versions

### In build.gradle.kts:
```kotlin
android {
    compileSdk = flutter.compileSdkVersion  // Usually 34+
    defaultConfig {
        minSdk = 23
        targetSdk = flutter.targetSdkVersion  // Usually 34+
    }
}
```

### Check Flutter's defaults:
```bash
flutter doctor -v
```

## 📝 Summary

**Current Setup:**
- ✅ minSdk: **23** (required by Firebase)
- ✅ Covers: **99%+** of devices
- ✅ Future-proof: Aligns with industry standards

**Long-term Strategy:**
- Monitor device distribution annually
- Update minSdk when:
  - New dependencies require it
  - Market share drops below acceptable threshold
  - Security/compliance requirements change

---

**Remember**: It's better to set a reasonable minSdk (23) than to force incompatible libraries, which leads to runtime failures and poor user experience.
