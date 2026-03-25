import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/storage_keys.dart';
import '../../../../core/storage/local_storage.dart' as app_storage;
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../domain/entities/splash_status.dart';
import '../../domain/repositories/splash_repository.dart';
import '../../../auth/data/datasources/auth_local_datasource.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../auth/domain/entities/user.dart' as app_auth;

/// Splash repository using Supabase for auth state.
/// When session exists, fetches profile, caches user, and returns currentUser in status.
class SplashRepositorySupabaseImpl implements SplashRepository {
  SplashRepositorySupabaseImpl({
    required this.localStorage,
    required this.authLocalDataSource,
  });

  final app_storage.LocalStorage localStorage;
  final AuthLocalDataSource authLocalDataSource;

  @override
  Future<bool> hasCompletedOnboarding() async {
    final value = await localStorage.getBool(StorageKeys.hasCompletedOnboarding);
    return value ?? false;
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final isVerified = session?.user.emailConfirmedAt != null;
      if (session != null && !isVerified) {
        await Supabase.instance.client.auth.signOut();
        return false;
      }
      if (session != null) {
        final profile = await SupabaseFailureMapper.guard(
          () => Supabase.instance.client
              .from('profiles')
              .select('email_verified_at')
              .eq('id', session.user.id)
              .maybeSingle(),
        );
        final profileVerifiedAt =
            profile is Map<String, dynamic> ? profile['email_verified_at'] : null;
        if (profileVerifiedAt == null) {
          await Supabase.instance.client.auth.signOut();
          return false;
        }
      }
      return session != null;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<SplashStatus> getSplashStatus() async {
    final hasCompleted = await hasCompletedOnboarding();
    final session = Supabase.instance.client.auth.currentSession;
    final isVerified = session?.user.emailConfirmedAt != null;
    if (session != null && !isVerified) {
      await Supabase.instance.client.auth.signOut();
      return SplashStatus(
        isInitialized: true,
        hasCompletedOnboarding: hasCompleted,
        isAuthenticated: false,
        currentUser: null,
      );
    }
    if (session != null) {
      final profile = await SupabaseFailureMapper.guard(
        () => Supabase.instance.client
            .from('profiles')
            .select('email_verified_at')
            .eq('id', session.user.id)
            .maybeSingle(),
      );
      final profileVerifiedAt =
          profile is Map<String, dynamic> ? profile['email_verified_at'] : null;
      if (profileVerifiedAt == null) {
        await Supabase.instance.client.auth.signOut();
        return SplashStatus(
          isInitialized: true,
          hasCompletedOnboarding: hasCompleted,
          isAuthenticated: false,
          currentUser: null,
        );
      }
    }
    final isAuth = session != null;

    app_auth.User? currentUser;
    if (session != null) {
      try {
        final userId = session.user.id;
        final res = await SupabaseFailureMapper.guard(() => Supabase
            .instance.client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle());
        if (res != null) {
          final profile = Map<String, dynamic>.from(res as Map);
          final userModel = UserModel.fromSupabaseProfile(profile);
          await authLocalDataSource.cacheUser(userModel);
          currentUser = userModel;
        }
      } catch (_) {
        // Keep currentUser null; isAuthenticated is still true, UI can fallback
        final cached = await authLocalDataSource.getCachedUser();
        currentUser = cached;
      }
    }

    return SplashStatus(
      isInitialized: true,
      hasCompletedOnboarding: hasCompleted,
      isAuthenticated: isAuth,
      currentUser: currentUser,
    );
  }
}
