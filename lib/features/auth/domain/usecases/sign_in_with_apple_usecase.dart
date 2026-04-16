import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class SignInWithAppleUseCase {
  final AuthRepository repository;

  SignInWithAppleUseCase(this.repository);

  Future<Either<Failure, User>> call({UserRole? oauthIntendedRole}) =>
      repository.signInWithApple(oauthIntendedRole: oauthIntendedRole);
}
