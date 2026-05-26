import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_deals_usecase.dart';
import '../../domain/usecases/get_deal_detail_usecase.dart';
import '../../domain/usecases/redeem_deal_usecase.dart';
import '../../domain/entities/deal.dart';
import 'deals_state.dart';

class DealsCubit extends Cubit<DealsState> {
  final GetDealsUseCase getDealsUseCase;
  final GetDealDetailUseCase getDealDetailUseCase;
  final RedeemDealUseCase redeemDealUseCase;

  DealsCubit({
    required this.getDealsUseCase,
    required this.getDealDetailUseCase,
    required this.redeemDealUseCase,
  }) : super(DealsInitial());

  Future<void> loadDeals({
    String? location,
    String? category,
    DealType? dealType,
  }) async {
    emit(DealsLoading());

    final result = await getDealsUseCase(
      location: location,
      category: category,
      dealType: dealType,
    );

    result.fold(
      (failure) => emit(DealsError(failure.message)),
      (deals) => emit(DealsLoaded(deals)),
    );
  }

  Future<void> loadDealDetail(String dealId) async {
    emit(DealDetailLoading());

    final result = await getDealDetailUseCase(dealId);

    result.fold(
      (failure) => emit(DealDetailError(failure.message)),
      (deal) => emit(DealDetailLoaded(deal)),
    );
  }

  Future<void> redeemDeal(String dealId) async {
    emit(RedeemDealLoading());

    final dealResult = await getDealDetailUseCase(dealId);
    final deal = dealResult.fold<Deal?>(
      (failure) {
        emit(RedeemDealError(failure.message));
        return null;
      },
      (d) => d,
    );
    if (deal == null) return;

    final redeemResult = await redeemDealUseCase(dealId);
    redeemResult.fold(
      (failure) => emit(RedeemDealError(failure.message)),
      (redemption) => emit(
        RedeemDealLoaded(
          redemptionCode: redemption.code,
          redemptionId: redemption.id,
          deal: deal,
        ),
      ),
    );
  }
}
