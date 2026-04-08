import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/error/exceptions.dart' as app_errors;
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../domain/entities/user.dart';

/// Supabase implementation of [AuthRemoteDataSource].
/// Uses Supabase Auth + public.profiles for login, register, guest, Google.
class AuthSupabaseRemoteDataSource implements AuthRemoteDataSource {
  AuthSupabaseRemoteDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  String get _authRedirectUrl => SupabaseConfig.authRedirectUrl;

  /// Web OAuth client ID (same as Supabase Google provider). On iOS, Google
  /// Sign-In 8.x also requires the iOS client ID ([AppConfig.googleIosClientId] /
  /// `GOOGLE_IOS_CLIENT_ID` → Info.plist `GIDClientID` via `pod install`).
  /// Single instance so [signOut] and [signInWithGoogle] share plugin state.
  late final GoogleSignIn _googleSignIn = () {
    final webClientId = AppConfig.googleWebClientId;
    final iosClientId = AppConfig.googleIosClientId;
    final useIosClientId = !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.iOS &&
        iosClientId.isNotEmpty;

    if (webClientId.isNotEmpty) {
      return GoogleSignIn(
        serverClientId: webClientId,
        clientId: useIosClientId ? iosClientId : null,
      );
    }
    if (useIosClientId) {
      return GoogleSignIn(clientId: iosClientId);
    }
    return GoogleSignIn();
  }();

  Future<UserModel> _sessionToUser() async {
    final session = _client.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null) throw app_errors.AuthException('No session');

    final res = await SupabaseFailureMapper.guard(() => _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle());

    if (res == null) {
      throw app_errors.ServerException(
        'Profile not found. Please try again or contact support.',
      );
    }
    return UserModel.fromSupabaseProfile(Map<String, dynamic>.from(res));
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final isEmailVerified = response.user?.emailConfirmedAt != null;
      if (!isEmailVerified) {
        // Prevent unverified accounts from entering authenticated app flows.
        await _client.auth.signOut();
        throw app_errors.EmailVerificationRequiredException(email);
      }
      final userId = response.user?.id;
      if (userId == null) {
        await _client.auth.signOut();
        throw app_errors.EmailVerificationRequiredException(email);
      }
      final profile = await SupabaseFailureMapper.guard(
        () => _client
            .from('profiles')
            .select('email_verified_at')
            .eq('id', userId)
            .maybeSingle(),
      );
      final profileVerifiedAt =
          profile is Map<String, dynamic> ? profile['email_verified_at'] : null;
      if (profileVerifiedAt == null) {
        // Auto-heal legacy profiles: if auth is verified, sync profile marker.
        await SupabaseFailureMapper.guard(
          () => _client
              .from('profiles')
              .update({'email_verified_at': DateTime.now().toIso8601String()})
              .eq('id', userId),
        );
      }
      return _sessionToUser();
    } catch (e) {
      if (e is app_errors.EmailVerificationRequiredException) rethrow;
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<UserModel> loginAsGuest() async {
    try {
      await _client.auth.signInAnonymously();
      return _sessionToUser();
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<UserModel> signInWithGoogle({bool forceAccountPicker = false}) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        if (AppConfig.googleIosClientId.isEmpty) {
          throw app_errors.AuthException(
            'Google Sign-In on iOS needs GOOGLE_IOS_CLIENT_ID in dart_defines.json '
            '(create an iOS OAuth client in Google Cloud Console for this app’s bundle ID), '
            'then run: cd ios && pod install, and rebuild the app.',
          );
        }
      }
      if (forceAccountPicker) {
        await _googleSignIn.signOut();
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw app_errors.AuthException('Google sign-in was cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw app_errors.AuthException(
          'Google sign-in did not return an ID token. '
          'On Android, set GOOGLE_WEB_CLIENT_ID (web client ID from Google Cloud) '
          'so the plugin can return a token for Supabase.',
        );
      }
      final accessToken = googleAuth.accessToken;
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken:
            accessToken != null && accessToken.isNotEmpty ? accessToken : null,
      );
      return _sessionToUser();
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<UserModel> signInWithApple() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw app_errors.AuthException(
        'Sign in with Apple is only available on iPhone and iPad.',
      );
    }
    try {
      final rawNonce = _generateAppleSignInNonce();
      final nonce = _sha256OfString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      final idToken = appleCredential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw app_errors.AuthException(
          'Apple sign-in did not return an identity token',
        );
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      final userId = _client.auth.currentUser?.id;
      if (userId != null) {
        await _syncAppleProfileDisplayName(
          userId: userId,
          email: _client.auth.currentUser?.email,
          credential: appleCredential,
        );
      }

      return _sessionToUser();
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  /// Apple only sends [PersonNameComponents]-style names in the native credential,
  /// not in the ID token, so Supabase `raw_user_meta_data` often has no `full_name`.
  /// [AuthorizationCredentialAppleID.givenName]/[familyName] are usually non-null only
  /// on the first successful sign-in for that app + Apple ID.
  Future<void> _syncAppleProfileDisplayName({
    required String userId,
    required String? email,
    required AuthorizationCredentialAppleID credential,
  }) async {
    final fromApple = _fullNameFromAppleCredential(credential);
    if (fromApple != null && fromApple.isNotEmpty) {
      await SupabaseFailureMapper.guard(() async {
        await _client
            .from('profiles')
            .update({'full_name': fromApple})
            .eq('id', userId);
      });
      try {
        await _client.auth.updateUser(
          UserAttributes(
            data: {'full_name': fromApple, 'name': fromApple},
          ),
        );
      } catch (_) {
        // Keep profile row; auth metadata is best-effort.
      }
      return;
    }

    final row = await SupabaseFailureMapper.guard(
      () => _client
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle(),
    );
    final existing = row is Map<String, dynamic>
        ? (row['full_name'] as String? ?? '').trim()
        : '';
    if (existing.isNotEmpty) return;

    final fallback = _appleProfileNameFallback(email);
    if (fallback == null || fallback.isEmpty) return;

    await SupabaseFailureMapper.guard(() async {
      await _client
          .from('profiles')
          .update({'full_name': fallback})
          .eq('id', userId);
    });
  }

  @override
  Future<UserModel> register(
    String email,
    String password,
    String name,
    UserRole role,
  ) async {
    try {
      final roleString = UserModel.roleToString(role);
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': roleString},
        emailRedirectTo: _authRedirectUrl,
      );
      if (response.user != null) {
        await SupabaseFailureMapper.guard(
          () => _client
              .from('profiles')
              .update({'email_verified_at': null})
              .eq('id', response.user!.id),
        );
      }
      // Enforce verification flow even if a session is returned unexpectedly.
      final isEmailVerified = response.user?.emailConfirmedAt != null;
      if (!isEmailVerified && response.user != null) {
        // Re-trigger delivery so the verification message is sent reliably.
        try {
          await _client.auth.resend(
            type: OtpType.signup,
            email: response.user!.email ?? email,
            emailRedirectTo: _authRedirectUrl,
          );
        } catch (_) {
          // Keep verification flow even if resend fails here.
        }
        if (response.session != null) {
          await _client.auth.signOut();
        }
        throw app_errors.EmailVerificationRequiredException(
          response.user!.email ?? email,
        );
      }
      if (response.session != null && response.user != null) {
        await _client.auth.signOut();
        throw app_errors.EmailVerificationRequiredException(
          response.user!.email ?? email,
        );
      }
      return _sessionToUser();
    } catch (e) {
      if (e is app_errors.EmailVerificationRequiredException) rethrow;
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: _authRedirectUrl,
      );
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: _authRedirectUrl,
      );
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
      await _client.auth.signOut();
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }

  @override
  Future<UserModel> updateProfileCity(String city) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw app_errors.AuthException('Not signed in');
      }
      await SupabaseFailureMapper.guard(() async {
        await _client.from('profiles').update({'city': city}).eq('id', userId);
      });
      return _sessionToUser();
    } catch (e) {
      SupabaseFailureMapper.throwFromError(e);
    }
  }
}

String _generateAppleSignInNonce([int length = 32]) {
  const charset =
      '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
  final random = Random.secure();
  return List.generate(length, (_) => charset[random.nextInt(charset.length)])
      .join();
}

String _sha256OfString(String input) =>
    sha256.convert(utf8.encode(input)).toString();

String? _fullNameFromAppleCredential(AuthorizationCredentialAppleID credential) {
  final given = credential.givenName?.trim() ?? '';
  final family = credential.familyName?.trim() ?? '';
  if (given.isEmpty && family.isEmpty) return null;
  if (given.isEmpty) return family;
  if (family.isEmpty) return given;
  return '$given $family';
}

/// When Apple returns no name (returning user or user chose not to share), avoid an empty UI label.
String? _appleProfileNameFallback(String? email) {
  if (email == null || email.isEmpty) return null;
  final at = email.indexOf('@');
  if (at <= 0) return null;
  final local = email.substring(0, at).trim();
  if (local.isEmpty) return null;
  if (local.toLowerCase().contains('privaterelay')) return 'Apple User';
  return local;
}
