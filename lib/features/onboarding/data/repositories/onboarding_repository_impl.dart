import '../../domain/repositories/onboarding_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';

/// Implementation of OnboardingRepository
class OnboardingRepositoryImpl implements OnboardingRepository {
  final LocalStorage localStorage;

  OnboardingRepositoryImpl({
    required this.localStorage,
  });

  @override
  Future<void> completeOnboarding() async {
    await localStorage.setBool(StorageKeys.hasCompletedOnboarding, true);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final value = await localStorage.getBool(StorageKeys.hasCompletedOnboarding);
    return value ?? false;
  }
}
