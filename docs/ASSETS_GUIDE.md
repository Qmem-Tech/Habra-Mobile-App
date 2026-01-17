# Assets Management Guide

This guide explains how to manage assets in the Habra Mobile App and where to place them.

## 📁 Asset Directory Structure

All assets should be organized in the following structure:

```
assets/
├── images/
│   └── onboarding/
│       ├── onboarding_1_music_festival.png
│       ├── onboarding_2_coffee_shop.png
│       └── onboarding_3_grow_together.png
├── icons/
│   └── ic_close.png
└── logos/
    ├── app_logo.png
    ├── app_logo.svg (optional - if you have vector format)
    └── splash_logo.png
```

## 📋 Required Assets

### 1. App Logo
- **Path**: `assets/logos/app_logo.png`
- **Description**: Main app logo - Hexagonal logo with interconnected figures
- **Format**: PNG (recommended) or SVG
- **Usage**: Used throughout the app for branding
- **Recommended Size**: 512x512px (for high quality)

### 2. Splash Screen Logo
- **Path**: `assets/logos/splash_logo.png`
- **Description**: Logo displayed on splash screen
- **Format**: PNG
- **Usage**: Shown during app launch
- **Recommended Size**: 512x512px (for high quality)

### 3. Onboarding Illustrations

#### Onboarding Screen 1 - Music Festival
- **Path**: `assets/images/onboarding/onboarding_1_music_festival.png`
- **Description**: Illustration for "Discover Your Community" screen
- **Format**: PNG
- **Content**: Music festival scene with speakers, people, and musical notes
- **Recommended Size**: 1080x1080px or higher (for high quality)

#### Onboarding Screen 2 - Coffee Shop
- **Path**: `assets/images/onboarding/onboarding_2_coffee_shop.png`
- **Description**: Illustration for "Support Local Businesses" screen
- **Format**: PNG
- **Content**: Isometric coffee shop interior scene
- **Recommended Size**: 1080x1080px or higher (for high quality)

#### Onboarding Screen 3 - Grow Together
- **Path**: `assets/images/onboarding/onboarding_3_grow_together.png`
- **Description**: Illustration for "Grow Together" screen
- **Format**: PNG
- **Content**: Globe with connectivity network and people with devices
- **Recommended Size**: 1080x1080px or higher (for high quality)

### 4. Icons

#### Close/Skip Icon
- **Path**: `assets/icons/ic_close.png`
- **Description**: Close/Skip icon for onboarding screens
- **Format**: PNG
- **Usage**: Top-right corner of onboarding screens
- **Recommended Size**: 24x24px (1x), 48x48px (2x), 72x72px (3x)

## 🎨 Asset Specifications

### Image Formats
- **PNG**: Recommended for logos and illustrations with transparency
- **SVG**: Optional for logos (vector format, scalable)
- **JPG**: Not recommended (no transparency support)

### Resolution Guidelines
- **Logos**: Minimum 512x512px, recommended 1024x1024px
- **Onboarding Illustrations**: Minimum 1080x1080px, recommended 1440x1440px
- **Icons**: Provide @1x, @2x, and @3x versions for different screen densities

### Color Profile
- Use **sRGB** color profile for consistency across devices
- Ensure assets match the brand colors:
  - Primary: Dark Green (#1B5E20)
  - Secondary: Golden Brown/Tan (#D4A574)

## 📝 How to Add Assets

### Step 1: Download Assets from Figma
1. Export assets from Figma in the required formats
2. Ensure proper naming (use the exact file names specified above)
3. Export at recommended resolutions

### Step 2: Create Directory Structure
If the directories don't exist, create them:
```bash
mkdir -p assets/images/onboarding
mkdir -p assets/icons
mkdir -p assets/logos
```

### Step 3: Place Assets
Copy your downloaded assets to the corresponding directories:
- Logos → `assets/logos/`
- Onboarding illustrations → `assets/images/onboarding/`
- Icons → `assets/icons/`

### Step 4: Verify Asset Paths
The asset paths are already configured in:
- `lib/core/resources/app_assets.dart` - Central asset management
- `pubspec.yaml` - Asset registration

## 🔧 Using Assets in Code

### Accessing Assets
All assets are accessed through the centralized `AppAssets` class:

```dart
import 'package:habra_mobile_app/core/resources/app_assets.dart';

// Use in Image.asset()
Image.asset(AppAssets.appLogo)
Image.asset(AppAssets.splashLogo)
Image.asset(AppAssets.onboardingMusicFestival)
```

### Example Usage
```dart
// In a widget
Image.asset(
  AppAssets.appLogo,
  width: 100,
  height: 100,
  errorBuilder: (context, error, stackTrace) {
    // Fallback widget if asset not found
    return Icon(Icons.image);
  },
)
```

## 🔄 Updating Assets

### When Assets Change
1. **Replace the asset file** in the corresponding directory
2. **Keep the same file name** (or update `AppAssets` class if renaming)
3. **Run** `flutter clean` and `flutter pub get` to refresh
4. **Hot restart** the app (not just hot reload) to see changes

### Updating Asset Paths
If you need to change asset paths or add new assets:

1. Update `lib/core/resources/app_assets.dart`:
```dart
static const String newAsset = '$_imagesPath/new_asset.png';
```

2. Update `pubspec.yaml` if adding new directories:
```yaml
assets:
  - assets/images/
  - assets/images/new_folder/
```

3. Run `flutter pub get`

## ✅ Asset Checklist

Before committing assets, ensure:

- [ ] All required assets are present
- [ ] Assets are in the correct directories
- [ ] File names match exactly (case-sensitive)
- [ ] Assets are optimized (not too large, but high quality)
- [ ] Assets use sRGB color profile
- [ ] `pubspec.yaml` includes all asset directories
- [ ] App runs without asset errors

## 🐛 Troubleshooting

### Asset Not Found Error
- **Check file path**: Ensure the path in `AppAssets` matches the actual file location
- **Check pubspec.yaml**: Verify the asset directory is listed
- **Run flutter clean**: Sometimes Flutter caches old asset configurations
- **Check file name**: File names are case-sensitive

### Asset Not Updating
- **Hot restart** instead of hot reload
- Run `flutter clean` and rebuild
- Check if the asset file was actually replaced

### Large App Size
- Optimize images using tools like:
  - [TinyPNG](https://tinypng.com/) for PNG compression
  - [ImageOptim](https://imageoptim.com/) for general optimization
- Consider using WebP format (requires additional setup)

## 📚 Additional Resources

- [Flutter Asset Documentation](https://docs.flutter.dev/development/ui/assets-and-images)
- [Image Optimization Guide](https://docs.flutter.dev/development/ui/assets-and-images#resolution-aware)

---

**Note**: All asset paths are centralized in `lib/core/resources/app_assets.dart`. When adding or updating assets, always update this file to maintain consistency across the app.
