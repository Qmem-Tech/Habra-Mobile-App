import 'package:equatable/equatable.dart';
import 'business_category.dart';

class BusinessFilters extends Equatable {
  final BusinessCategory? category;
  final double? minRating;
  final String? priceRange;
  final bool? isOpenNow;
  final double? maxDistance;
  final bool? isVerified;

  const BusinessFilters({
    this.category,
    this.minRating,
    this.priceRange,
    this.isOpenNow,
    this.maxDistance,
    this.isVerified,
  });

  BusinessFilters copyWith({
    BusinessCategory? category,
    double? minRating,
    String? priceRange,
    bool? isOpenNow,
    double? maxDistance,
    bool? isVerified,
  }) {
    return BusinessFilters(
      category: category ?? this.category,
      minRating: minRating ?? this.minRating,
      priceRange: priceRange ?? this.priceRange,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      maxDistance: maxDistance ?? this.maxDistance,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        minRating != null ||
        priceRange != null ||
        isOpenNow != null ||
        maxDistance != null ||
        isVerified != null;
  }

  @override
  List<Object?> get props => [
        category,
        minRating,
        priceRange,
        isOpenNow,
        maxDistance,
        isVerified,
      ];
}
