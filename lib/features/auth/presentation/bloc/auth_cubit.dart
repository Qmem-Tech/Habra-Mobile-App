import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/login_as_guest_usecase.dart';
import '../../domain/entities/user.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final RegisterUseCase registerUseCase;
  final LoginAsGuestUseCase loginAsGuestUseCase;

  AuthCubit({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.registerUseCase,
    required this.loginAsGuestUseCase,
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
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
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

  Future<void> logout() async {
    final result = await logoutUseCase();
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(AuthUnauthenticated()),
    );
  }
}
