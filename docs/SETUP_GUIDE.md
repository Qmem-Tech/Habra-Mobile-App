# Detailed Setup Guide

This guide will walk you through setting up the Habra Mobile App step by step.

## Table of Contents

1. [Initial Setup](#initial-setup)
2. [Firebase Configuration](#firebase-configuration)
3. [Running the App](#running-the-app)
4. [Code Generation](#code-generation)
5. [Common Issues](#common-issues)

## Initial Setup

### 1. Install Flutter

If you haven't already, install Flutter:

```bash
# Check Flutter installation
flutter doctor

# Install Flutter dependencies
flutter doctor --android-licenses  # For Android
```

### 2. Clone and Install Dependencies

```bash
# Navigate to project directory
cd Habra-Mobile-App

# Get dependencies
flutter pub get
```

### 3. Verify Installation

```bash
# Check Flutter version (should be >=3.0.0)
flutter --version

# List available devices
flutter devices
```

## Firebase Configuration

### Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"**
3. Enter project name: `habra-mobile-app` (or your preferred name)
4. Disable Google Analytics (optional) or enable it
5. Click **"Create project"**

### Step 2: Enable Authentication

1. In Firebase Console, go to **Authentication**
2. Click **"Get started"**
3. Go to **"Sign-in method"** tab
4. Enable **"Email/Password"** provider
5. Click **"Save"**

### Step 3: Enable Firestore

1. Go to **Firestore Database**
2. Click **"Create database"**
3. Start in **test mode** (for development)
4. Choose a location (closest to your users)
5. Click **"Enable"**

### Step 4: Android Configuration

1. In Firebase Console, click the **Android icon** (or "Add app")
2. Register app:
   - **Android package name**: `com.habra.habra_mobile_app`
   - **App nickname**: Habra Mobile App (optional)
   - **Debug signing certificate SHA-1**: (optional for now)
3. Click **"Register app"**
4. Download `google-services.json`
5. Place the file in: `android/app/google-services.json`

#### Update Android Build Files

**android/build.gradle.kts** (project level):
```kotlin
buildscript {
    dependencies {
        // Add this line
        classpath("com.google.gms:google-services:4.4.0")
    }
}
```

**android/app/build.gradle.kts** (app level):
```kotlin
plugins {
    // Add this line at the top
    id("com.google.gms.google-services")
}
```

### Step 5: iOS Configuration

1. In Firebase Console, click the **iOS icon** (or "Add app")
2. Register app:
   - **iOS bundle ID**: `com.habra.habraMobileApp`
   - **App nickname**: Habra Mobile App (optional)
3. Click **"Register app"**
4. Download `GoogleService-Info.plist`
5. Open `ios/Runner.xcworkspace` in Xcode
6. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode
7. Make sure "Copy items if needed" is checked

#### Update iOS Podfile

**ios/Podfile**:
```ruby
platform :ios, '12.0'  # Ensure minimum iOS version
```

Then run:
```bash
cd ios
pod install
cd ..
```

## Running the App

### First Time Setup

```bash
# Clean build
flutter clean

# Get dependencies
flutter pub get

# Generate localization files
flutter gen-l10n

# Generate code (for JSON serialization)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run on Android

```bash
# Start an Android emulator or connect a device
flutter run
```

### Run on iOS

```bash
# Start an iOS simulator or connect a device
flutter run
```

### Run on Specific Device

```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Code Generation

### When to Run Code Generation

Run code generation when:
- You modify models with `@JsonSerializable()`
- You add new JSON serializable classes
- You see errors about missing `.g.dart` files

### Commands

```bash
# Clean and rebuild
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

# Watch mode (auto-regenerate on file changes)
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Common Issues

### Issue 1: Firebase Not Initialized

**Error**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`

**Solution**:
1. Ensure `google-services.json` is in `android/app/`
2. Ensure `GoogleService-Info.plist` is added to iOS project
3. Run `flutter clean` and rebuild

### Issue 2: Localization Not Working

**Error**: `AppLocalizations.of(context)!` returns null

**Solution**:
```bash
# Regenerate localization files
flutter gen-l10n

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

### Issue 3: Build Runner Errors

**Error**: `Conflicting outputs were detected`

**Solution**:
```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Issue 4: Missing Dependencies

**Error**: `Package not found`

**Solution**:
```bash
flutter pub get
flutter pub upgrade
```

### Issue 5: Android Build Errors

**Error**: Gradle build failures

**Solution**:
1. Update `android/gradle/wrapper/gradle-wrapper.properties`:
   ```properties
   distributionUrl=https\://services.gradle.org/distributions/gradle-8.0-all.zip
   ```
2. Update Android SDK tools
3. Run `flutter clean` and rebuild

### Issue 6: iOS Build Errors

**Error**: CocoaPods issues

**Solution**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## Testing the Setup

### Test Authentication

1. Run the app
2. Try to login with a test account
3. If account doesn't exist, create one in Firebase Console → Authentication → Users

### Test Theme Switching

1. Go to Settings (gear icon in app bar)
2. Change theme between Light/Dark/System
3. Verify theme changes immediately

### Test Localization

1. Go to Settings
2. Change language
3. Verify UI text changes to selected language

## Next Steps

After setup is complete:

1. **Customize Theme**: Edit `lib/core/theme/app_colors.dart`
2. **Add Features**: Follow the feature structure in `lib/features/`
3. **Configure API**: Update `lib/core/constants/api_constants.dart`
4. **Add More Languages**: Add ARB files in `l10n/` and update `localization_cubit.dart`

## Getting Help

- Check the main [README.md](README.md)
- Review Flutter documentation: https://flutter.dev/docs
- Review Firebase documentation: https://firebase.google.com/docs
- Open an issue in the repository

---

**Setup complete! Happy coding! 🎉**
