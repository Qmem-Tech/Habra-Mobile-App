import '../../../auth/domain/entities/user.dart';

/// Entity representing splash screen status.
/// When [isAuthenticated] is true, [currentUser] is set (from cache after profile refresh).
class SplashStatus {
  final bool isInitialized;
  final bool hasCompletedOnboarding;
  final bool isAuthenticated;
  final User? currentUser;

  const SplashStatus({
    required this.isInitialized,
    required this.hasCompletedOnboarding,
    required this.isAuthenticated,
    this.currentUser,
  });

  SplashStatus copyWith({
    bool? isInitialized,
    bool? hasCompletedOnboarding,
    bool? isAuthenticated,
    User? currentUser,
  }) {
    return SplashStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      currentUser: currentUser ?? this.currentUser,
    );
  }
}
