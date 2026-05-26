import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/businesses_repository.dart';

class WriteReviewUseCase {
  final BusinessesRepository repository;

  WriteReviewUseCase(this.repository);

  Future<Either<Failure, Review>> call({
    required String businessId,
    required int rating,
    required String comment,
    List<String>? photoUrls,
  }) async {
    return await repository.writeReview(
      businessId: businessId,
      rating: rating,
      comment: comment,
      photoUrls: photoUrls,
    );
  }
}
