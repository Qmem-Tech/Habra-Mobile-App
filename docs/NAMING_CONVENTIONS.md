# Naming Conventions

This document outlines the naming conventions used in the Habra Mobile App project.

## 🎯 "Habra" Naming Convention

We use the **"habra"** prefix for Flutter/Firebase-related getters and methods to distinguish them from other code and make the codebase more maintainable.

### Firebase Services

All Firebase-related getters and methods use the `habra` prefix:

```dart
class FirebaseServices {
  // ✅ Use "habra" prefix for Flutter/Firebase getters
  FirebaseAuth get habraAuth => FirebaseAuth.instance;
  FirebaseFirestore get habraFirestore => FirebaseFirestore.instance;
  FirebaseStorage get habraStorage => FirebaseStorage.instance;
  FirebaseMessaging get habraMessaging => FirebaseMessaging.instance;
  FirebaseRemoteConfig get habraRemoteConfig => FirebaseRemoteConfig.instance;

  Future<void> initializeHabraRemoteConfig() async { ... }
}
```

### Usage Example

```dart
// ✅ Correct - Using "habra" prefix
final auth = firebaseServices.habraAuth;
final firestore = firebaseServices.habraFirestore;
await firebaseServices.habraAuth.signInWithEmailAndPassword(...);

// ❌ Incorrect - Old naming (deprecated)
final auth = firebaseServices.auth; // Deprecated
```

## 📝 General Naming Conventions

### Files and Folders
- **Files**: `snake_case.dart` (e.g., `user_model.dart`, `auth_cubit.dart`)
- **Folders**: `snake_case` (e.g., `data_sources/`, `presentation/`)

### Classes
- **Classes**: `PascalCase` (e.g., `UserModel`, `AuthCubit`, `LoginPage`)
- **Abstract Classes**: `PascalCase` (e.g., `AuthRepository`, `NetworkInfo`)

### Variables and Functions
- **Variables**: `camelCase` (e.g., `userName`, `isLoading`)
- **Functions/Methods**: `camelCase` (e.g., `login()`, `getUserData()`)
- **Private**: `_camelCase` (e.g., `_userName`, `_handleLogin()`)

### Constants
- **Constants**: `lowerCamelCase` for final variables (e.g., `const apiKey = '...'`)
- **Enums**: `PascalCase` (e.g., `UserRole`, `AppThemeMode`)
- **Enum Values**: `camelCase` (e.g., `UserRole.customer`, `AppThemeMode.light`)

### Widgets
- **Widget Classes**: `PascalCase` (e.g., `LoginPage`, `CustomerHomePage`)
- **Widget Files**: `snake_case.dart` (e.g., `login_page.dart`)

## 🏗️ Architecture-Specific Naming

### Domain Layer
- **Entities**: `PascalCase` (e.g., `User`, `Product`)
- **Repositories**: `PascalCase` + `Repository` (e.g., `AuthRepository`)
- **Use Cases**: `PascalCase` + `UseCase` (e.g., `LoginUseCase`)

### Data Layer
- **Models**: `PascalCase` + `Model` (e.g., `UserModel`)
- **Data Sources**: `PascalCase` + `DataSource` (e.g., `AuthRemoteDataSource`)
- **Repository Implementations**: `PascalCase` + `RepositoryImpl` (e.g., `AuthRepositoryImpl`)

### Presentation Layer
- **Cubits/Blocs**: `PascalCase` + `Cubit`/`Bloc` (e.g., `AuthCubit`)
- **States**: `PascalCase` + `State` (e.g., `AuthState`)
- **Pages**: `PascalCase` + `Page` (e.g., `LoginPage`)

## 🔑 Key Rules

1. **Flutter/Firebase Getters**: Always use `habra` prefix
   - `habraAuth`, `habraFirestore`, `habraStorage`, etc.

2. **Private Members**: Always start with `_`
   - `_userName`, `_handleLogin()`, `_usersCollection`

3. **Constants**: Use `const` or `final` with `lowerCamelCase`
   - `const apiBaseUrl = '...'`
   - `final maxRetries = 3`

4. **Boolean Variables**: Use `is`, `has`, `should`, `can` prefix
   - `isLoading`, `hasError`, `shouldShowDialog`, `canEdit`

5. **Collections**: Use plural nouns
   - `users`, `products`, `orders`

## 📚 Examples

### Good Examples ✅

```dart
// Firebase Services
class FirebaseServices {
  FirebaseAuth get habraAuth => FirebaseAuth.instance;
  FirebaseFirestore get habraFirestore => FirebaseFirestore.instance;
}

// Use Cases
class LoginUseCase {
  Future<Either<Failure, User>> call(String email, String password) { ... }
}

// Models
class UserModel extends User {
  factory UserModel.fromJson(Map<String, dynamic> json) { ... }
  Map<String, dynamic> toJson() { ... }
}

// Cubits
class AuthCubit extends Cubit<AuthState> {
  Future<void> login(String email, String password) async { ... }
}

// Pages
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
}
```

### Bad Examples ❌

```dart
// ❌ Don't use generic names for Firebase getters
FirebaseAuth get auth => FirebaseAuth.instance;

// ❌ Don't use abbreviations
class UsrMdl extends User { ... }

// ❌ Don't use Hungarian notation
String strUserName;
int intCount;

// ❌ Don't use unclear names
class Thing { ... }
void doStuff() { ... }
```

## 🎨 Special Cases

### Firebase Collections
```dart
// Use descriptive names
CollectionReference<Map<String, dynamic>> get _usersCollection =>
    firebaseServices.habraFirestore.collection('users');
```

### Error Handling
```dart
// Use descriptive error names
class ServerException implements Exception { ... }
class NetworkFailure extends Failure { ... }
```

### State Management
```dart
// States should be descriptive
class AuthLoading extends AuthState { ... }
class AuthAuthenticated extends AuthState { ... }
class AuthError extends AuthState { ... }
```

## 📖 Summary

- **Flutter/Firebase**: Use `habra` prefix (e.g., `habraAuth`, `habraFirestore`)
- **Files**: `snake_case.dart`
- **Classes**: `PascalCase`
- **Variables/Functions**: `camelCase`
- **Private**: `_camelCase`
- **Constants**: `lowerCamelCase` with `const`/`final`
- **Booleans**: `is`/`has`/`should`/`can` prefix

---

**Remember**: Consistency is key! Follow these conventions throughout the project.
