# Habra Mobile App

A Flutter super app built with **Clean Architecture**, **Cubit/BLoC** for state management, **Firebase** backend, **Theme Management**, and **Multi-language Localization**.

## 🏗️ Architecture

This project follows **Clean Architecture** principles with a **feature-based** folder structure:

```
lib/
├── core/                    # Core functionality shared across features
│   ├── constants/          # App-wide constants
│   ├── error/              # Error handling (exceptions, failures)
│   ├── network/            # Network layer (API client, interceptors, Firebase)
│   ├── storage/            # Local storage abstraction
│   ├── theme/              # Theme management (colors, styles, cubit)
│   ├── localization/       # Localization management (cubit)
│   └── router/             # Navigation/routing
│
├── features/                # Feature modules (each feature is self-contained)
│   ├── auth/               # Authentication feature
│   │   ├── data/          # Data layer (datasources, models, repositories)
│   │   ├── domain/        # Domain layer (entities, repositories, usecases)
│   │   └── presentation/  # Presentation layer (pages, bloc/cubit)
│   └── settings/          # Settings feature
│
├── injection/              # Dependency injection setup
└── main.dart              # App entry point
```

## ✨ Features

- ✅ **Clean Architecture** - Separation of concerns with domain, data, and presentation layers
- ✅ **Cubit/BLoC State Management** - Reactive state management using flutter_bloc
- ✅ **Firebase Integration** - Authentication, Firestore, Storage, Analytics, Crashlytics
- ✅ **Theme Management** - Light/Dark/System theme with persistent storage
- ✅ **Multi-language Support** - English, Arabic, and French with easy extension
- ✅ **Dependency Injection** - Using GetIt for service locator pattern
- ✅ **Error Handling** - Comprehensive error handling with Either pattern
- ✅ **Network Layer** - Dio-based API client with interceptors
- ✅ **Local Storage** - SharedPreferences abstraction

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

- **Flutter SDK** (>=3.0.0) - [Install Flutter](https://flutter.dev/docs/get-started/install)
- **Dart SDK** (>=3.0.0)
- **Android Studio** or **VS Code** with Flutter extensions
- **Firebase Account** - [Firebase Console](https://console.firebase.google.com/)

## 🚀 Getting Started

### Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd Habra-Mobile-App
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

### Step 3: Firebase Setup

#### 3.1 Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add project" and follow the setup wizard
3. Enable the following services:
   - **Authentication** (Email/Password)
   - **Cloud Firestore**
   - **Storage**
   - **Analytics**
   - **Crashlytics**

#### 3.2 Android Setup

1. In Firebase Console, click "Add app" → Select Android
2. Register your app with package name: `com.habra.habra_mobile_app`
3. Download `google-services.json`
4. Place it in `android/app/` directory

#### 3.3 iOS Setup

1. In Firebase Console, click "Add app" → Select iOS
2. Register your app with bundle ID: `com.habra.habraMobileApp`
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/` directory using Xcode

#### 3.4 Enable Authentication

1. In Firebase Console → Authentication → Sign-in method
2. Enable "Email/Password" provider

### Step 4: Generate Localization Files

```bash
flutter gen-l10n
```

This generates the localization files from the ARB files in `l10n/` directory.

### Step 5: Generate Code (if needed)

If you modify models with `@JsonSerializable()`, run:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 6: Run the App

```bash
# For Android
flutter run

# For iOS
flutter run

# For a specific device
flutter devices
flutter run -d <device-id>
```

## 📱 Running on Different Platforms

### Android

1. Ensure you have an Android emulator running or a physical device connected
2. Run `flutter run`
3. Make sure `google-services.json` is in `android/app/`

### iOS

1. Open `ios/Runner.xcworkspace` in Xcode
2. Ensure `GoogleService-Info.plist` is added to the project
3. Run `flutter run` or build from Xcode

### Web

```bash
flutter run -d chrome
```

### Desktop (Windows/Mac/Linux)

```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
```

## 🧪 Testing

Run tests with:

```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage
```

## 📁 Project Structure Explained

### Core Layer

- **constants/**: App-wide constants (API endpoints, storage keys, etc.)
- **error/**: Error handling classes (exceptions and failures)
- **network/**: Network configuration (API client, interceptors, Firebase services)
- **storage/**: Local storage abstraction (SharedPreferences wrapper)
- **theme/**: Theme management (colors, styles, theme cubit)
- **localization/**: Language management (localization cubit)

### Features Layer

Each feature follows Clean Architecture:

- **domain/**: Business logic
  - `entities/`: Pure Dart classes representing business objects
  - `repositories/`: Abstract repository interfaces
  - `usecases/`: Business logic operations
- **data/**: Data sources
  - `datasources/`: Remote and local data sources
  - `models/`: Data transfer objects (JSON serializable)
  - `repositories/`: Repository implementations
- **presentation/**: UI layer
  - `bloc/`: State management (Cubit/Bloc and states)
  - `pages/`: UI screens

## 🔧 Configuration

### API Configuration

Update API endpoints in `lib/core/constants/api_constants.dart`:

```dart
class ApiConstants {
  static const String baseUrl = 'https://your-api.com';
  // ...
}
```

### Theme Customization

Modify colors in `lib/core/theme/app_colors.dart` and styles in `lib/core/theme/app_text_styles.dart`.

### Adding New Languages

1. Create a new ARB file in `l10n/` (e.g., `app_es.arb` for Spanish)
2. Add the locale to `lib/core/localization/localization_cubit.dart`:

```dart
List<Locale> get supportedLocales => const [
  Locale('en'),
  Locale('ar'),
  Locale('fr'),
  Locale('es'), // New language
];
```

3. Run `flutter gen-l10n` to generate localization files

## 🎨 Theme Management

The app supports three theme modes:
- **Light Mode**: Light color scheme
- **Dark Mode**: Dark color scheme
- **System Default**: Follows device theme

Users can change themes from the Settings page. The preference is saved locally.

## 🌍 Localization

The app currently supports:
- **English** (en)
- **Arabic** (ar)
- **French** (fr)

Users can change language from the Settings page. The preference is saved locally.

## 🔐 Authentication

The app uses Firebase Authentication with email/password. The authentication flow:

1. User enters email and password
2. Firebase authenticates the user
3. User data is cached locally
4. User is authenticated and can access the app

## 📦 Dependencies

### Main Dependencies

- **flutter_bloc**: State management
- **firebase_core, firebase_auth, cloud_firestore**: Firebase services
- **get_it**: Dependency injection
- **dio**: HTTP client
- **shared_preferences**: Local storage
- **go_router**: Navigation
- **equatable**: Value equality
- **dartz**: Functional programming (Either pattern)

See `pubspec.yaml` for the complete list.

## 🐛 Troubleshooting

### Firebase Not Initialized

- Ensure `google-services.json` (Android) or `GoogleService-Info.plist` (iOS) is in the correct location
- Run `flutter clean` and `flutter pub get`
- Rebuild the app

### Localization Not Working

- Run `flutter gen-l10n` to generate localization files
- Ensure ARB files are in `l10n/` directory
- Check that `generate: true` is in `pubspec.yaml`

### Build Errors

```bash
# Clean build
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Code Generation Issues

If you see errors related to `.g.dart` files:

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

## 📝 Adding New Features

To add a new feature:

1. Create a new folder in `lib/features/` (e.g., `lib/features/home/`)
2. Follow the Clean Architecture structure:
   ```
   features/
     home/
       data/
         datasources/
         models/
         repositories/
       domain/
         entities/
         repositories/
         usecases/
       presentation/
         bloc/
         pages/
   ```
3. Register dependencies in `lib/injection/injection_container.dart`
4. Add routes if needed

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- Clean Architecture by Robert C. Martin

## 📞 Support

For support, email your-email@example.com or open an issue in the repository.

---

**Happy Coding! 🚀**
