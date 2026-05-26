import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/review.dart';
import '../repositories/businesses_repository.dart';

class GetBusinessReviewsUseCase {
  final BusinessesRepository repository;

  GetBusinessReviewsUseCase(this.repository);

  Future<Either<Failure, List<Review>>> call(String businessId) async {
    return await repository.getBusinessReviews(businessId);
  }
}
