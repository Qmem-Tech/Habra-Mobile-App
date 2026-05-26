import 'package:equatable/equatable.dart';
import 'business_category.dart';

class BusinessFilters extends Equatable {
  final BusinessCategory? category;
  /// When set, filters businesses that have this `categories.id` in `business_categories`.
  final String? listingCategoryId;
  final double? minRating;
  final String? priceRange;
  final bool? isOpenNow;
  final double? maxDistance;
  final bool? isVerified;

  const BusinessFilters({
    this.category,
    this.listingCategoryId,
    this.minRating,
    this.priceRange,
    this.isOpenNow,
    this.maxDistance,
    this.isVerified,
  });

  BusinessFilters copyWith({
    BusinessCategory? category,
    String? listingCategoryId,
    double? minRating,
    String? priceRange,
    bool? isOpenNow,
    double? maxDistance,
    bool? isVerified,
  }) {
    return BusinessFilters(
      category: category ?? this.category,
      listingCategoryId: listingCategoryId ?? this.listingCategoryId,
      minRating: minRating ?? this.minRating,
      priceRange: priceRange ?? this.priceRange,
      isOpenNow: isOpenNow ?? this.isOpenNow,
      maxDistance: maxDistance ?? this.maxDistance,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  bool get hasActiveFilters {
    return category != null ||
        listingCategoryId != null ||
        minRating != null ||
        priceRange != null ||
        isOpenNow != null ||
        maxDistance != null ||
        isVerified != null;
  }

  @override
  List<Object?> get props => [
        category,
        listingCategoryId,
        minRating,
        priceRange,
        isOpenNow,
        maxDistance,
        isVerified,
      ];
}
