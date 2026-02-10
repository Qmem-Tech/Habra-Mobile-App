import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../error/exceptions.dart';

/// Maps Supabase and Auth errors to app exceptions for consistent handling.
class SupabaseFailureMapper {
  SupabaseFailureMapper._();

  /// Converts any error from a Supabase/Auth call into an app exception.
  static Never throwFromError(Object error, [StackTrace? stackTrace]) {
    if (error is supabase.AuthException) {
      throw AuthException(
        error.message,
        error.statusCode ?? error.code,
      );
    }
    if (error is supabase.FunctionException) {
      throw ServerException(
        error.message,
        error.statusCode,
      );
    }
    if (error is supabase.PostgrestException) {
      final code = error.code;
      final message = error.message;
      if (code == 'PGRST301' || code == '42501' || message.contains('policy')) {
        throw ForbiddenException(
          _userFriendly('You don\'t have permission for this action.'),
        );
      }
      throw ServerException(
        _userFriendly(message),
        code,
      );
    }
    if (error is supabase.StorageException) {
      if (error.statusCode == '403') {
        throw ForbiddenException(
          _userFriendly('You don\'t have permission for this file.'),
        );
      }
      throw ServerException(
        _userFriendly(error.message),
        error.statusCode,
      );
    }
    if (error is supabase.RealtimeException) {
      throw ServerException(
        _userFriendly(error.message),
        error.code,
      );
    }

    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('TimeoutException') ||
        message.contains('Connection')) {
      throw NetworkException(
        _userFriendly('No connection. Check your network and try again.'),
      );
    }

    throw ServerException(
      _userFriendly('Something went wrong. Please try again.'),
    );
  }

  static String _userFriendly(String raw) {
    if (raw.isEmpty) return 'Something went wrong. Please try again.';
    return raw.length > 200 ? '${raw.substring(0, 200)}...' : raw;
  }

  /// Wraps an async Supabase call and converts errors to exceptions.
  static Future<T> guard<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      throwFromError(e, st);
    }
  }
}
