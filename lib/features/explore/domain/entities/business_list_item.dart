import 'package:equatable/equatable.dart';
import 'business_category.dart';

class BusinessListItem extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final List<BusinessCategory> categories;
  /// Category row IDs from `business_categories` / `categories` (for dynamic filters).
  final List<String> listingCategoryIds;
  final String address;
  final String city;
  final String state;
  final double? distance; // in miles
  final double rating;
  final int reviewCount;
  final String? priceRange; // $, $$, $$$, $$$$
  final bool isVerified;
  final bool isOpen;
  final String? closingTime;
  final String? openingTime;
  final bool isFeatured;
  /// Standard or Premium subscription (`subscription_tier` is `pro` or `premium`).
  final bool isSubscribed;
  /// E.164 or raw digits; optional (e.g. for call flows).
  final String? phone;
  final double? latitude;
  final double? longitude;

  const BusinessListItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.categories,
    this.listingCategoryIds = const [],
    required this.address,
    required this.city,
    required this.state,
    this.distance,
    required this.rating,
    required this.reviewCount,
    this.priceRange,
    this.isVerified = false,
    required this.isOpen,
    this.closingTime,
    this.openingTime,
    this.isFeatured = false,
    this.isSubscribed = false,
    this.phone,
    this.latitude,
    this.longitude,
  });

  String get fullAddress => '$address, $city, $state';

  String get displayDistance {
    if (distance == null) return '';
    final miles = distance!;
    if (miles.isNaN) return '—';
    if (miles < 0.05) return '< 0.1 mi';
    if (miles < 1) {
      return '${(miles * 10).round() / 10} mi';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        categories,
        listingCategoryIds,
        address,
        city,
        state,
        distance,
        rating,
        reviewCount,
        priceRange,
        isVerified,
        isOpen,
        closingTime,
        openingTime,
        isFeatured,
        isSubscribed,
        phone,
        latitude,
        longitude,
      ];
}
