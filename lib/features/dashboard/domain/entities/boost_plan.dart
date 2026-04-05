import 'package:equatable/equatable.dart';

/// Boost listing plan option.
class BoostPlan extends Equatable {
  final String id;
  final String title;
  final String description;
  final String priceFormatted;
  final String? originalPriceFormatted;
  final int durationWeeks;
  /// App Store / Play product id; must match RevenueCat package store product.
  final String? billingProductId;

  const BoostPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.priceFormatted,
    this.originalPriceFormatted,
    required this.durationWeeks,
    this.billingProductId,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priceFormatted,
        originalPriceFormatted,
        durationWeeks,
        billingProductId,
      ];
}
