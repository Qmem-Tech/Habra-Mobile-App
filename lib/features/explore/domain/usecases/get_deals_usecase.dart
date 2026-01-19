import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../repositories/businesses_repository.dart';

class GetDealsUseCase {
  final BusinessesRepository repository;

  GetDealsUseCase(this.repository);

  Future<Either<Failure, List<Deal>>> call({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    return await repository.getDeals(
      location: location,
      category: category,
      dealType: dealType,
    );
  }
}
