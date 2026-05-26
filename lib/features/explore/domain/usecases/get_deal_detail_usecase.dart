import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal.dart';
import '../repositories/businesses_repository.dart';

class GetDealDetailUseCase {
  final BusinessesRepository repository;

  GetDealDetailUseCase(this.repository);

  Future<Either<Failure, Deal>> call(String dealId) async {
    return await repository.getDealDetail(dealId);
  }
}
