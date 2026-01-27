import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/jobs_repository.dart';

class GetJobCategoriesUseCase {
  final JobsRepository repository;

  GetJobCategoriesUseCase(this.repository);

  Future<Either<Failure, List<String>>> call() async {
    return await repository.getJobCategories();
  }
}
