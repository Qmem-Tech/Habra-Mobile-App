import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../error/exceptions.dart' as app;

/// Maps Supabase and Auth errors to app exceptions for consistent handling.
class SupabaseFailureMapper {
  SupabaseFailureMapper._();

  /// Converts any error from a Supabase/Auth call into an app exception.
  static Never throwFromError(Object error, [StackTrace? stackTrace]) {
    if (error is app.AuthException) throw error;
    if (error is app.ServerException) throw error;
    if (error is app.NetworkException) throw error;
    if (error is app.EmailVerificationRequiredException) throw error;
    if (error is app.ForbiddenException) throw error;

    if (error is supabase.AuthException) {
      throw app.AuthException(
        _friendlyAuthMessage(error.message),
        error.statusCode ?? error.code,
      );
    }
    if (error is supabase.FunctionException) {
      throw app.ServerException(
        error.toString(),
        null,
      );
    }
    if (error is supabase.PostgrestException) {
      final code = error.code;
      final message = error.message;
      if (code == 'PGRST301' || code == '42501' || message.contains('policy')) {
        throw app.ForbiddenException(
          _userFriendly('You don\'t have permission for this action.'),
        );
      }
      throw app.ServerException(
        _userFriendly(message),
        code,
      );
    }
    if (error is supabase.StorageException) {
      if (error.statusCode == '403') {
        throw app.ForbiddenException(
          _userFriendly('You don\'t have permission for this file.'),
        );
      }
      throw app.ServerException(
        _userFriendly(error.message),
        error.statusCode,
      );
    }
    if (error is PlatformException) {
      throw app.ServerException(
        _friendlyPlatformException(error),
        error.code,
      );
    }

    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('TimeoutException') ||
        message.contains('Connection')) {
      throw app.NetworkException(
        _userFriendly('No connection. Check your network and try again.'),
      );
    }

    throw app.ServerException(_fallbackMessage(message));
  }

  /// Prefer a short, readable line; avoid dropping OAuth/HTTP context entirely.
  static String _fallbackMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Something went wrong. Please try again.';
    }
    final lower = trimmed.toLowerCase();
    if (lower.contains('sign_in_failed') ||
        lower.contains('sign_in_canceled') ||
        lower.contains('canceled')) {
      return 'Google sign-in was cancelled or failed. Try again or use email and password.';
    }
    if (lower.contains('developer_error') || lower.contains('12500')) {
      return 'Google Sign-In is not configured for this build. '
          'Add SHA-1/256 to Firebase/Google Cloud and set GOOGLE_WEB_CLIENT_ID for Android.';
    }
    // Android: com.google.android.gms.common.api.ApiException: 10 = DEVELOPER_ERROR
    if (RegExp(r'apiexception:\s*10\b', caseSensitive: false).hasMatch(trimmed)) {
      return 'Google Sign-In error (code 10): your Android app is not registered correctly. '
          'In Google Cloud Console → APIs & Services → Credentials, open the '
          'OAuth 2.0 Client ID of type Android for package com.habra.habra and add '
          'this build\'s SHA-1 (debug: run gradlew signingReport). Also set '
          'GOOGLE_WEB_CLIENT_ID to your Web client ID for Supabase.';
    }
    // Obfuscated Play services traces (R8), e.g. m4.b / j4.b + : 10 — ApiException DEVELOPER_ERROR
    if (RegExp(
          r'\b[a-z]\d\.b\b.*\b10\b',
          caseSensitive: false,
        ).hasMatch(lower) ||
        RegExp(r'\bj\d\.b\b.*\b10\b', caseSensitive: false).hasMatch(lower)) {
      return 'Google Sign-In failed due to Android OAuth configuration (code 10). '
          'Verify package name/SHA-1 in Google Cloud and ensure GOOGLE_WEB_CLIENT_ID is set.';
    }
    return _userFriendly(trimmed);
  }

  static String _friendlyPlatformException(PlatformException e) {
    final parts = <String>[
      if (e.message != null && e.message!.trim().isNotEmpty) e.message!.trim(),
      if (e.details != null && '$e.details'.trim().isNotEmpty) '$e.details'.trim(),
    ];
    final combined = parts.join(' ');
    if (combined.isEmpty) {
      return 'Sign-in failed (${e.code}). Please try again.';
    }
    return _fallbackMessage(combined);
  }

  static String _userFriendly(String raw) {
    if (raw.isEmpty) return 'Something went wrong. Please try again.';
    var cleaned = raw.trim();
    if (cleaned.toLowerCase().startsWith('exception:')) {
      cleaned = cleaned.substring(cleaned.indexOf(':') + 1).trim();
    }
    final lower = cleaned.toLowerCase();
    if (lower.contains('too many requests') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit') ||
        lower.contains('rate limit') ||
        lower.contains('429')) {
      return 'Too many email requests. Please wait a few minutes before trying again.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please check your inbox and verify your email before continuing.';
    }
    return cleaned.length > 200 ? '${cleaned.substring(0, 200)}...' : cleaned;
  }

  /// Maps GoTrue / OAuth messages to clearer copy for sign-in UI.
  static String _friendlyAuthMessage(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'Sign-in failed. Please try again.';
    }
    final lower = trimmed.toLowerCase();
    if (lower.contains('email not confirmed') ||
        lower.contains('email address not confirmed')) {
      return 'Please verify your email first, then try Google sign-in again.';
    }
    if (lower.contains('already registered') ||
        lower.contains('user already registered') ||
        lower.contains('email address is already registered') ||
        (lower.contains('duplicate') && lower.contains('email'))) {
      return 'This email is already registered. Use your email and password to sign in. '
          'To use Google with the same account, your project must allow linking providers '
          'with the same email (Supabase Dashboard → Authentication → Providers).';
    }
    if (lower.contains('identity') &&
        (lower.contains('already linked') || lower.contains('another user'))) {
      return 'This Google account is linked to a different user. Try another Google account '
          'or sign in with email and password.';
    }
    if (lower.contains('invalid_grant') ||
        lower.contains('invalid id token') ||
        lower.contains('bad jwt') ||
        lower.contains('invalid jwt')) {
      return 'Google could not complete sign-in. Confirm GOOGLE_WEB_CLIENT_ID matches '
          'Supabase Google settings, then try again or use email and password.';
    }
    if (lower.contains('provider') &&
        (lower.contains('disabled') || lower.contains('not enabled'))) {
      return 'Google sign-in is disabled in your Supabase project. Enable it under Authentication → Providers.';
    }
    return _userFriendly(trimmed);
  }

  /// Wraps an async Supabase call and converts errors to app exceptions.
  static Future<T> guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      throwFromError(e, st);
    }
  }
}
