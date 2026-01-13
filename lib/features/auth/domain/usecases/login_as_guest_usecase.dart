import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class LoginAsGuestUseCase {
  final AuthRepository repository;

  LoginAsGuestUseCase(this.repository);

  Future<Either<Failure, User>> call() {
    return repository.loginAsGuest();
  }
}
