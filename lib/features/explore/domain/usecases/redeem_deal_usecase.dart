import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/deal_redemption.dart';
import '../repositories/businesses_repository.dart';

class RedeemDealUseCase {
  final BusinessesRepository repository;

  RedeemDealUseCase(this.repository);

  Future<Either<Failure, DealRedemption>> call(String dealId) async {
    return repository.redeemDeal(dealId);
  }
}
