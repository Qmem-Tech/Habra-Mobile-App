/// Repository interface for onboarding operations
/// Domain layer - no dependencies on data layer
abstract class OnboardingRepository {
  /// Mark onboarding as completed
  Future<void> completeOnboarding();

  /// Check if onboarding is completed
  Future<bool> isOnboardingCompleted();
}
