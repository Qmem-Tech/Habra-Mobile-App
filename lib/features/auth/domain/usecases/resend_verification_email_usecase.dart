import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResendVerificationEmailUseCase {
  ResendVerificationEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String email) =>
      _repository.resendVerificationEmail(email);
}
