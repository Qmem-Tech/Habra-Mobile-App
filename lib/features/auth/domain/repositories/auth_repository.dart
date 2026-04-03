import '../entities/user.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class AuthRepository {
  Future<Either<Failure, User>> login(String email, String password);
  Future<Either<Failure, User>> loginAsGuest();
  Future<Either<Failure, User>> signInWithGoogle();
  Future<Either<Failure, User>> signInWithApple();
  Future<Either<Failure, void>> logout();
  Future<Either<Failure, User>> register(
    String email,
    String password,
    String name,
    UserRole role,
  );
  /// Current user from local cache (after login or splash refresh).
  Future<Either<Failure, User?>> getCurrentUser();

  /// Resends the signup confirmation email to [email].
  Future<Either<Failure, void>> resendVerificationEmail(String email);

  /// Sends a password reset email to [email].
  Future<Either<Failure, void>> resetPasswordForEmail(String email);

  /// Updates the current user's password (requires recovery session from reset link).
  Future<Either<Failure, void>> updatePassword(String newPassword);

  /// Updates local auth cache (name, avatar, etc.) after profile edits; no remote call.
  Future<Either<Failure, void>> cacheUserProfile(User user);
}
