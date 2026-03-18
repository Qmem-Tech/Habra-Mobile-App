import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordForEmailUseCase {
  ResetPasswordForEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String email) =>
      _repository.resetPasswordForEmail(email);
}
