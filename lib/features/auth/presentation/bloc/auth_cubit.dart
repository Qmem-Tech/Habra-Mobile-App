import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_as_guest_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/resend_verification_email_usecase.dart';
import '../../domain/usecases/reset_password_for_email_usecase.dart';
import '../../domain/usecases/update_password_usecase.dart';
import '../../domain/entities/user.dart';
import '../../../../core/error/failures.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final LoginAsGuestUseCase loginAsGuestUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final ResendVerificationEmailUseCase resendVerificationEmailUseCase;
  final ResetPasswordForEmailUseCase resetPasswordForEmailUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.loginAsGuestUseCase,
    required this.signInWithGoogleUseCase,
    required this.resendVerificationEmailUseCase,
    required this.resetPasswordForEmailUseCase,
    required this.updatePasswordUseCase,
  }) : super(AuthInitial());

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    final result = await loginUseCase(email, password);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
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
      (user) => emit(AuthAuthenticated(user)),
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
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    final result = await signInWithGoogleUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  Future<void> logout() async {
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
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
    emit(AuthLoading());
    final result = await updatePasswordUseCase(newPassword);
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) async {
        emit(const AuthPasswordUpdated());
        await logoutUseCase();
        emit(AuthUnauthenticated());
      },
    );
  }

  /// Restores auth state from a cached/session user (e.g. after app cold start).
  /// Keeps the app in sync so the user stays signed in without being asked again.
  void restoreUser(User user) {
    emit(AuthAuthenticated(user));
  }

  /// Resets to initial state (e.g. when leaving forgot-password success screen).
  void resetToInitial() {
    emit(AuthInitial());
  }
}
