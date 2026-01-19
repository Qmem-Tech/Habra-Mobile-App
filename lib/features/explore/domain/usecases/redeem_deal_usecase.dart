import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/businesses_repository.dart';

class RedeemDealUseCase {
  final BusinessesRepository repository;

  RedeemDealUseCase(this.repository);

  Future<Either<Failure, String>> call(String dealId) async {
    return await repository.redeemDeal(dealId);
  }
}
