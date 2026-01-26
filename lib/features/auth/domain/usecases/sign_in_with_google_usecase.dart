import '../entities/user.dart';
import '../repositories/auth_repository.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

class SignInWithGoogleUseCase {
  final AuthRepository repository;

  SignInWithGoogleUseCase(this.repository);

  Future<Either<Failure, User>> call() {
    return repository.signInWithGoogle();
    // return repository.signInWithGoogle();
  }
}
