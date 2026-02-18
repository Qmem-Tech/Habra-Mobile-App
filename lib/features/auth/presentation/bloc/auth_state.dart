import 'package:equatable/equatable.dart';
import '../../domain/entities/user.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated(this.user);

  @override
  List<Object> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

/// Sign-up succeeded; user must verify email before they can sign in.
class AuthEmailVerificationPending extends AuthState {
  final String email;

  const AuthEmailVerificationPending(this.email);

  @override
  List<Object> get props => [email];
}

/// Resend verification email succeeded (then cubit reverts to AuthEmailVerificationPending).
class AuthResendVerificationSuccess extends AuthState {
  const AuthResendVerificationSuccess();
}
