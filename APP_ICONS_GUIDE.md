# App Icons Configuration Guide

This guide explains how to update the app icons for Android and iOS.

## 📱 Android App Icons

### Location
Android app icons are located in:
```
android/app/src/main/res/
├── mipmap-mdpi/ic_launcher.png      (48x48px)
├── mipmap-hdpi/ic_launcher.png      (72x72px)
├── mipmap-xhdpi/ic_launcher.png     (96x96px)
├── mipmap-xxhdpi/ic_launcher.png    (144x144px)
└── mipmap-xxxhdpi/ic_launcher.png   (192x192px)
```

### Required Sizes
- **mdpi**: 48x48px
- **hdpi**: 72x72px
- **xhdpi**: 96x96px
- **xxhdpi**: 144x144px
- **xxxhdpi**: 192x192px

### Steps to Update
1. Export your app logo from Figma at the required sizes
2. Replace the existing `ic_launcher.png` files in each mipmap folder
3. Ensure the file name is exactly `ic_launcher.png` (case-sensitive)
4. Rebuild the app: `flutter clean && flutter build apk`

### Alternative: Using Adaptive Icons (Recommended)
For better Android support, you can use adaptive icons:

1. Create `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@mipmap/ic_launcher_foreground"/>
</adaptive-icon>
```

2. Create foreground and background resources
3. Update `AndroidManifest.xml` if needed

## 🍎 iOS App Icons

### Location
iOS app icons are located in:
```
ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

### Required Sizes
iOS requires multiple icon sizes. Check `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` for the exact sizes needed.

Common sizes include:
- 20x20pt (@2x, @3x)
- 29x29pt (@2x, @3x)
- 40x40pt (@2x, @3x)
- 60x60pt (@2x, @3x)
- 1024x1024pt (App Store)

### Steps to Update
1. Export your app logo from Figma at all required sizes
2. Open Xcode: `open ios/Runner.xcworkspace`
3. Navigate to `Runner/Assets.xcassets/AppIcon`
4. Drag and drop your icons into the appropriate slots
5. Or manually replace files in `AppIcon.appiconset/` folder

### Using Xcode (Recommended)
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select `Runner` in the project navigator
3. Go to the `Assets.xcassets` folder
4. Click on `AppIcon`
5. Drag your icons into the appropriate slots

## 🛠️ Automated Tools

### Option 1: Using flutter_launcher_icons Package
Add to `pubspec.yaml`:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/logos/app_logo.png"
  adaptive_icon_background: "#1B5E20"  # Your brand color
  adaptive_icon_foreground: "assets/logos/app_logo.png"
```

Then run:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### Option 2: Using Online Tools
- [AppIcon.co](https://www.appicon.co/) - Upload one icon, get all sizes
- [IconKitchen](https://icon.kitchen/) - Generate adaptive icons

## 📋 Checklist

Before submitting to app stores:

- [ ] Android icons updated in all mipmap folders
- [ ] iOS icons updated in AppIcon.appiconset
- [ ] Icons tested on physical devices
- [ ] Icons look good on different screen densities
- [ ] No transparency issues (Android adaptive icons)
- [ ] Icons match brand guidelines
- [ ] App name in AndroidManifest.xml is correct
- [ ] App bundle ID/package name is correct

## 🎨 Design Guidelines

### Best Practices
- **Use PNG format** with transparency (if needed)
- **Square format** - icons will be automatically rounded/masked by the OS
- **No text** - keep it simple and recognizable
- **High contrast** - ensure visibility on light and dark backgrounds
- **Consistent branding** - match your app logo design

### Android Adaptive Icons
- **Foreground**: Your logo/icon (should be centered, 66% of canvas)
- **Background**: Solid color or gradient (matches brand)
- **Safe zone**: Keep important elements in center 66% of canvas

### iOS Icons
- **No transparency** - iOS will add rounded corners automatically
- **Full canvas** - icon should fill the entire canvas
- **Consistent design** - should match your app's visual identity

## 🔍 Verification

After updating icons:

1. **Android**:
   ```bash
   flutter clean
   flutter build apk
   # Install on device and check icon
   ```

2. **iOS**:
   ```bash
   flutter clean
   flutter build ios
   # Run on simulator/device and check icon
   ```

## 📚 Additional Resources

- [Flutter Launcher Icons Package](https://pub.dev/packages/flutter_launcher_icons)
- [Android Adaptive Icons Guide](https://developer.android.com/guide/practices/ui_guidelines/icon_design_adaptive)
- [iOS App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

---

**Note**: After updating icons, you may need to uninstall and reinstall the app to see the changes, as the OS caches app icons.
