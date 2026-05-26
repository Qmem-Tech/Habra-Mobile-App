import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/business_detail.dart';
import '../repositories/businesses_repository.dart';

class GetBusinessDetailUseCase {
  final BusinessesRepository repository;

  GetBusinessDetailUseCase(this.repository);

  Future<Either<Failure, BusinessDetail>> call(String businessId) async {
    return await repository.getBusinessDetail(businessId);
  }
}
