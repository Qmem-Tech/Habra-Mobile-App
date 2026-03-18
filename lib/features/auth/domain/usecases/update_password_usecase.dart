import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class UpdatePasswordUseCase {
  UpdatePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, void>> call(String newPassword) =>
      _repository.updatePassword(newPassword);
}
