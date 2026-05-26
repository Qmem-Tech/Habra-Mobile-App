import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/push_notification_service.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/delete_account_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_as_guest_usecase.dart';
import '../../domain/usecases/sign_in_with_apple_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/resend_verification_email_usecase.dart';
import '../../domain/usecases/reset_password_for_email_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final DeleteAccountUseCase deleteAccountUseCase;
  final RegisterUseCase registerUseCase;
  final LoginAsGuestUseCase loginAsGuestUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignInWithAppleUseCase signInWithAppleUseCase;
  final ResendVerificationEmailUseCase resendVerificationEmailUseCase;
  final ResetPasswordForEmailUseCase resetPasswordForEmailUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final RevenueCatService revenueCatService;
  final AuthRepository authRepository;
  final PushNotificationService pushNotificationService;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.deleteAccountUseCase,
    required this.registerUseCase,
    required this.loginAsGuestUseCase,
    required this.signInWithGoogleUseCase,
    required this.signInWithAppleUseCase,
    required this.resendVerificationEmailUseCase,
    required this.resetPasswordForEmailUseCase,
    required this.updatePasswordUseCase,
    required this.revenueCatService,
    required this.authRepository,
    required this.pushNotificationService,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(email, password);
    result.fold(
      (failure) {
        if (failure is EmailVerificationPendingFailure) {
          emit(AuthEmailVerificationPending(failure.email));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    emit(AuthLoading());
    final result = await registerUseCase(email, password, name, role);
    result.fold(
      (failure) {
        if (failure is EmailVerificationPendingFailure) {
          emit(AuthEmailVerificationPending(failure.email));
        } else {
          emit(AuthError(failure.message));
        }
      },
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> resendVerificationEmail(String email) async {
    final result = await resendVerificationEmailUseCase(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        emit(const AuthResendVerificationSuccess());
        emit(AuthEmailVerificationPending(email));
      },
    );
  }

  Future<void> loginAsGuest() async {
    emit(AuthLoading());
    final result = await loginAsGuestUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> signInWithGoogle({
    bool forceAccountPicker = false,
    UserRole? oauthIntendedRole,
  }) async {
    emit(AuthLoading());
    final result = await signInWithGoogleUseCase(
      forceAccountPicker: forceAccountPicker,
      oauthIntendedRole: oauthIntendedRole,
    );
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> signInWithApple({UserRole? oauthIntendedRole}) async {
    emit(AuthLoading());
    final result =
        await signInWithAppleUseCase(oauthIntendedRole: oauthIntendedRole);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }

  Future<void> logout() async {
    final uid =
        state is AuthAuthenticated ? (state as AuthAuthenticated).user.id : null;
    if (uid != null) {
      await pushNotificationService.clearTokenForUser(uid);
    }
    final result = await logoutUseCase();
    await result.fold<Future<void>>(
      (failure) async {
        emit(AuthError(failure.message));
      },
      (_) async {
        await revenueCatService.logout();
        emit(AuthUnauthenticated());
      },
    );
  }

  /// Returns `true` when the account was deleted successfully.
  Future<bool> deleteAccount() async {
    final uid =
        state is AuthAuthenticated ? (state as AuthAuthenticated).user.id : null;
    if (uid != null) {
      await pushNotificationService.clearTokenForUser(uid);
    }
    emit(AuthLoading());
    final result = await deleteAccountUseCase();
    return await result.fold<Future<bool>>(
      (failure) async {
        emit(AuthError(failure.message));
        return false;
      },
      (_) async {
        await revenueCatService.logout();
        emit(AuthUnauthenticated());
        return true;
      },
    );
  }

  Future<void> resetPasswordForEmail(String email) async {
    emit(AuthLoading());
    final result = await resetPasswordForEmailUseCase(email);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthResetEmailSent()),
    );
  }

  Future<void> updatePassword(String newPassword) async {
    final previousUid =
        state is AuthAuthenticated ? (state as AuthAuthenticated).user.id : null;
    emit(AuthLoading());
    final result = await updatePasswordUseCase(newPassword);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) async {
        emit(const AuthPasswordUpdated());
        if (previousUid != null) {
          await pushNotificationService.clearTokenForUser(previousUid);
        }
        await logoutUseCase();
        await revenueCatService.logout();
        emit(AuthUnauthenticated());
      },
    );
  }

  /// Restores auth state from a cached/session user (e.g. after app cold start).
  /// Keeps the app in sync so the user stays signed in without being asked again.
  Future<void> restoreUser(User user) async {
    await revenueCatService.identifyUser(
      user.id,
      email: user.email,
      displayName: user.name,
    );
    emit(AuthAuthenticated(user));
  }

  /// Resets to initial state (e.g. when leaving forgot-password success screen).
  void resetToInitial() {
    emit(AuthInitial());
  }

  /// After profile save: refresh session user + disk cache so drawer / shell update.
  Future<void> applyProfileEditsToSession(User updated) async {
    await authRepository.cacheUserProfile(updated);
    emit(AuthAuthenticated(updated));
  }

  /// Saves `profiles.city` (home / feed metro) and updates session + local cache.
  Future<void> saveHomeCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isEmpty) return;
    final result = await authRepository.updateHomeCity(trimmed);
    result.fold(
      (_) {},
      (user) async {
        await revenueCatService.identifyUser(
          user.id,
          email: user.email,
          displayName: user.name,
        );
        emit(AuthAuthenticated(user));
      },
    );
  }
}
