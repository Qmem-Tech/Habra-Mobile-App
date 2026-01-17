# Architecture Overview

## Clean Architecture Principles

This project follows **Clean Architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (UI, Widgets, Pages, Cubit/Bloc for State Management)  │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                     Domain Layer                         │
│  (Entities, Use Cases, Repository Interfaces)           │
│  - Pure Dart, No Dependencies                           │
└──────────────────────┬──────────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────────┐
│                      Data Layer                          │
│  (Data Sources, Models, Repository Implementations)     │
│  - External Dependencies (Firebase, API, Storage)       │
└─────────────────────────────────────────────────────────┘
```

## Layer Responsibilities

### 1. Presentation Layer
- **Location**: `lib/features/{feature}/presentation/`
- **Responsibilities**:
  - UI components (Pages, Widgets)
  - State management (Cubit/Bloc)
  - User interactions
  - Displaying data from domain layer

### 2. Domain Layer
- **Location**: `lib/features/{feature}/domain/`
- **Responsibilities**:
  - Business logic
  - Entities (pure Dart classes)
  - Use cases (business operations)
  - Repository interfaces (contracts)
- **Rules**:
  - No dependencies on other layers
  - Pure Dart code
  - Framework-independent

### 3. Data Layer
- **Location**: `lib/features/{feature}/data/`
- **Responsibilities**:
  - Data sources (Remote & Local)
  - Models (JSON serializable)
  - Repository implementations
  - Data transformation (Model → Entity)

## Feature Structure

Each feature is self-contained:

```
features/
  auth/
    ├── data/
    │   ├── datasources/
    │   │   ├── auth_remote_datasource.dart    # Firebase/API calls
    │   │   └── auth_local_datasource.dart      # Local storage
    │   ├── models/
    │   │   └── user_model.dart                 # JSON serializable
    │   └── repositories/
    │       └── auth_repository_impl.dart       # Implements domain interface
    │
    ├── domain/
    │   ├── entities/
    │   │   └── user.dart                       # Pure Dart class
    │   ├── repositories/
    │   │   └── auth_repository.dart            # Interface/Contract
    │   └── usecases/
    │       ├── login_usecase.dart              # Business logic
    │       └── logout_usecase.dart
    │
    └── presentation/
        ├── bloc/
        │   ├── auth_cubit.dart                 # State management
        │   └── auth_state.dart                 # State classes
        └── pages/
            └── login_page.dart                 # UI
```

## Data Flow

### Example: Login Flow

```
1. User taps "Login" button
   ↓
2. LoginPage calls AuthCubit.login()
   ↓
3. AuthCubit calls LoginUseCase
   ↓
4. LoginUseCase calls AuthRepository.login()
   ↓
5. AuthRepositoryImpl calls AuthRemoteDataSource
   ↓
6. AuthRemoteDataSource calls Firebase Auth
   ↓
7. Response flows back up:
   Firebase → DataSource → Repository → UseCase → Cubit → UI
```

## State Management (Cubit)

### Cubit Pattern

```dart
// State
abstract class AuthState extends Equatable {}

class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
}
class AuthError extends AuthState {
  final String message;
}

// Cubit
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }
}
```

## Dependency Injection

Using **GetIt** service locator:

```dart
// Registration
sl.registerLazySingleton<AuthRepository>(
  () => AuthRepositoryImpl(...),
);

// Usage
final authRepo = sl<AuthRepository>();
```

## Error Handling

### Either Pattern (Dartz)

```dart
// Success or Failure
Future<Either<Failure, User>> login(...) async {
  try {
    final user = await dataSource.login(...);
    return Right(user);  // Success
  } catch (e) {
    return Left(ServerFailure(e.message));  // Failure
  }
}

// Usage
result.fold(
  (failure) => handleError(failure),
  (user) => handleSuccess(user),
);
```

## Core Modules

### Network Layer
- **ApiClient**: Dio-based HTTP client
- **Interceptors**: Logging, Authentication
- **Firebase Services**: Firebase SDK wrappers

### Storage Layer
- **LocalStorage**: SharedPreferences abstraction
- **Secure Storage**: (Can be added for sensitive data)

### Theme Management
- **ThemeCubit**: Manages theme state
- **AppTheme**: Theme definitions
- **AppColors**: Color constants

### Localization
- **LocalizationCubit**: Manages language state
- **ARB Files**: Translation files
- **Generated Files**: Auto-generated from ARB

## Best Practices

### 1. Feature Independence
- Each feature should be independent
- Features communicate through domain layer
- No direct dependencies between features

### 2. Dependency Rule
- Inner layers don't know about outer layers
- Dependencies point inward
- Domain has no dependencies

### 3. Use Cases
- One use case = one business operation
- Use cases are testable in isolation
- Use cases orchestrate repository calls

### 4. Repository Pattern
- Single source of truth
- Abstracts data sources
- Returns domain entities (not models)

### 5. Error Handling
- Use Either pattern for operations that can fail
- Convert exceptions to failures
- Handle errors at presentation layer

## Testing Strategy

### Unit Tests
- Test use cases in isolation
- Mock repositories
- Test business logic

### Widget Tests
- Test UI components
- Mock Cubit/Bloc
- Test user interactions

### Integration Tests
- Test feature flows
- Test repository implementations
- Test with real data sources (optional)

## Adding a New Feature

1. **Create Feature Folder**
   ```
   lib/features/new_feature/
   ```

2. **Domain Layer First**
   - Define entities
   - Define repository interface
   - Create use cases

3. **Data Layer**
   - Create models
   - Implement data sources
   - Implement repository

4. **Presentation Layer**
   - Create Cubit/Bloc
   - Create pages/widgets
   - Connect to use cases

5. **Register Dependencies**
   - Add to `injection_container.dart`

6. **Add Routes** (if needed)
   - Update router configuration

## Code Organization Rules

1. **One file = One class** (when possible)
2. **Feature-based structure** (not layer-based)
3. **Core modules** are shared across features
4. **No circular dependencies**
5. **Follow naming conventions**:
   - Entities: `user.dart`
   - Models: `user_model.dart`
   - Repositories: `auth_repository.dart`
   - Use Cases: `login_usecase.dart`
   - Cubits: `auth_cubit.dart`
   - States: `auth_state.dart`

## Benefits of This Architecture

✅ **Testability**: Each layer can be tested independently
✅ **Maintainability**: Clear separation of concerns
✅ **Scalability**: Easy to add new features
✅ **Flexibility**: Easy to swap implementations
✅ **Team Collaboration**: Clear boundaries for team members

---

For more details, see the main [README.md](README.md)
