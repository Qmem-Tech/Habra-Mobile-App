import '../entities/splash_status.dart';

/// Repository interface for splash screen operations
/// Domain layer - no dependencies on data layer
abstract class SplashRepository {
  /// Check if user has completed onboarding
  Future<bool> hasCompletedOnboarding();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Get splash status
  Future<SplashStatus> getSplashStatus();
}
