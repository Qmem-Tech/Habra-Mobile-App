import '../../domain/entities/splash_status.dart';
import '../../domain/repositories/splash_repository.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/network/firebase/firebase_services.dart';

/// Implementation of SplashRepository
class SplashRepositoryImpl implements SplashRepository {
  final LocalStorage localStorage;
  final FirebaseServices firebaseServices;

  SplashRepositoryImpl({
    required this.localStorage,
    required this.firebaseServices,
  });

  @override
  Future<bool> hasCompletedOnboarding() async {
    final value = await localStorage.getBool(StorageKeys.hasCompletedOnboarding);
    return value ?? false;
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final user = firebaseServices.habraAuth.currentUser;
      return user != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SplashStatus> getSplashStatus() async {
    final hasCompleted = await hasCompletedOnboarding();
    final isAuth = await isAuthenticated();

    return SplashStatus(
      isInitialized: true,
      hasCompletedOnboarding: hasCompleted,
      isAuthenticated: isAuth,
    );
  }
}
