import 'package:equatable/equatable.dart';
import '../../domain/entities/deal.dart';

abstract class DealsState extends Equatable {
  const DealsState();

  @override
  List<Object?> get props => [];
}

class DealsInitial extends DealsState {}

class DealsLoading extends DealsState {}

class DealsLoaded extends DealsState {
  final List<Deal> deals;

  const DealsLoaded(this.deals);

  @override
  List<Object?> get props => [deals];
}

class DealsError extends DealsState {
  final String message;

  const DealsError(this.message);

  @override
  List<Object?> get props => [message];
}

// Deal Detail States
class DealDetailInitial extends DealsState {}

class DealDetailLoading extends DealsState {}

class DealDetailLoaded extends DealsState {
  final Deal deal;

  const DealDetailLoaded(this.deal);

  @override
  List<Object?> get props => [deal];
}

class DealDetailError extends DealsState {
  final String message;

  const DealDetailError(this.message);

  @override
  List<Object?> get props => [message];
}

// Redeem Deal States
class RedeemDealInitial extends DealsState {}

class RedeemDealLoading extends DealsState {}

class RedeemDealLoaded extends DealsState {
  final String redemptionCode;
  final String redemptionId;
  final Deal deal;

  const RedeemDealLoaded({
    required this.redemptionCode,
    required this.redemptionId,
    required this.deal,
  });

  @override
  List<Object?> get props => [redemptionCode, redemptionId, deal];
}

class RedeemDealError extends DealsState {
  final String message;

  const RedeemDealError(this.message);

  @override
  List<Object?> get props => [message];
}
