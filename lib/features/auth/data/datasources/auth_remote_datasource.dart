import '../models/user_model.dart';
import '../../domain/entities/user.dart';

/// Remote data source for authentication.
/// Implemented by [AuthSupabaseRemoteDataSource] (Supabase Auth + profiles).
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginAsGuest();
  Future<UserModel> signInWithGoogle();
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  );
  Future<void> logout();

  /// Resends the signup confirmation email to [email].
  Future<void> resendVerificationEmail(String email);
}
