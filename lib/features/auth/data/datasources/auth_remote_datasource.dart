import '../models/user_model.dart';
import '../../domain/entities/user.dart';

/// Remote data source for authentication.
/// Implemented by [AuthSupabaseRemoteDataSource] (Supabase Auth + profiles).
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> loginAsGuest();
  /// When [forceAccountPicker] is true, clears the Google plugin's cached
  /// account first so the user sees the account chooser (e.g. business flow).
  ///
  /// [oauthIntendedRole]: when set (e.g. [UserRole.businessOwner] from the
  /// business sign-up screen), ensures `profiles.role` matches after OAuth,
  /// since Google/Apple do not send signup metadata like email/password sign-up.
  Future<UserModel> signInWithGoogle({
    bool forceAccountPicker = false,
    UserRole? oauthIntendedRole,
  });
  Future<UserModel> signInWithApple({UserRole? oauthIntendedRole});
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  );
  Future<void> logout();

  /// Permanently deletes the signed-in account via the delete-account edge function.
  Future<void> deleteAccount();

  /// Resends the signup confirmation email to [email].
  Future<void> resendVerificationEmail(String email);

  /// Sends a password reset email to [email]. User must tap the link to open the app.
  Future<void> resetPasswordForEmail(String email);

  /// Updates the current user's password. Requires an active recovery session (from reset link).
  Future<void> updatePassword(String newPassword);

  /// Persists home / feed location label to `profiles.city` and returns refreshed user.
  Future<UserModel> updateProfileCity(String city);
}
