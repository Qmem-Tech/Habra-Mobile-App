/// Entity representing splash screen status
/// Pure Dart class with no dependencies
class SplashStatus {
  final bool isInitialized;
  final bool hasCompletedOnboarding;
  final bool isAuthenticated;

  const SplashStatus({
    required this.isInitialized,
    required this.hasCompletedOnboarding,
    required this.isAuthenticated,
  });

  SplashStatus copyWith({
    bool? isInitialized,
    bool? hasCompletedOnboarding,
    bool? isAuthenticated,
  }) {
    return SplashStatus(
      isInitialized: isInitialized ?? this.isInitialized,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}
