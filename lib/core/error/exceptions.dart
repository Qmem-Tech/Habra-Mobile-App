class ServerException implements Exception {
  final String message;
  final String? code;
  ServerException(this.message, [this.code]);
}

class CacheException implements Exception {
  final String message;
  CacheException(this.message);
}

class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
}

/// Auth-related errors (invalid credentials, email not confirmed, etc.)
class AuthException implements Exception {
  final String message;
  final String? code;
  AuthException(this.message, [this.code]);
}

/// RLS / permission denied (403, PGRST301)
class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
}
