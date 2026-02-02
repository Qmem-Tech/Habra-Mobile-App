import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/jobs_repository.dart';

class ToggleBookmarkUseCase {
  final JobsRepository repository;

  ToggleBookmarkUseCase(this.repository);

  Future<Either<Failure, void>> call(String jobId, bool isBookmarked) async {
    return await repository.toggleBookmark(jobId, isBookmarked);
  }
}
