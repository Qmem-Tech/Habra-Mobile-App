import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../repositories/auth_repository.dart';

class DeleteAccountUseCase {
  DeleteAccountUseCase(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, void>> call() => repository.deleteAccount();
}
