import 'package:equatable/equatable.dart';

/// Boost listing plan option.
class BoostPlan extends Equatable {
  final String id;
  final String title;
  final String description;
  final String priceFormatted;
  final String? originalPriceFormatted;
  final int durationWeeks;

  const BoostPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.priceFormatted,
    this.originalPriceFormatted,
    required this.durationWeeks,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        priceFormatted,
        originalPriceFormatted,
        durationWeeks,
      ];
}
