import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_remote_datasource.dart';
import '../models/user_model.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../domain/entities/user.dart';

/// Supabase implementation of [AuthRemoteDataSource].
/// Uses Supabase Auth + public.profiles for login, register, guest, Google.
class AuthSupabaseRemoteDataSource implements AuthRemoteDataSource {
  AuthSupabaseRemoteDataSource();

  SupabaseClient get _client => Supabase.instance.client;
  GoogleSignIn get _googleSignIn => GoogleSignIn();

  Future<UserModel> _sessionToUser() async {
    final session = _client.auth.currentSession;
    final userId = session?.user.id;
    if (userId == null) throw AuthException('No session');

    final res = await SupabaseFailureMapper.guard(() => _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle());

    if (res == null) {
      throw ServerException(
        'Profile not found. Please try again or contact support.',
      );
    }
    final profile = res as Map<String, dynamic>;
    return UserModel.fromSupabaseProfile(profile);
  }

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return _sessionToUser();
    } catch (e) {
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
  Future<UserModel> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw AuthException('Google sign-in did not return an ID token');
      }
      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      return _sessionToUser();
    } catch (e) {
      if (e is AuthException) rethrow;
      SupabaseFailureMapper.throwFromError(e);
    }
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
      await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': roleString},
      );
      return _sessionToUser();
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
}
