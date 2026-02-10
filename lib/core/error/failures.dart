import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Auth-related failures (invalid credentials, email not confirmed)
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// RLS / permission denied
class ForbiddenFailure extends Failure {
  const ForbiddenFailure(super.message);
}
