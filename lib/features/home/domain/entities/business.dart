import 'package:equatable/equatable.dart';
import '../../../../core/subscription/business_subscription_tier.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distance; // in miles
  final String priceRange; // e.g., "$", "$$", "$$$"
  final String? status; // e.g., "Fresh spices arrived today"
  final bool isVerified;
  /// Large hero image for card layouts; UI may fall back to [imageUrl] when null.
  final String? coverImageUrl;
  /// Rounded logo; UI may fall back to [imageUrl] when null.
  final String? logoUrl;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final BusinessSubscriptionTier subscriptionTier;
  final BusinessSubscriptionStatus subscriptionStatus;

  const Business({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.priceRange,
    this.status,
    this.isVerified = false,
    this.coverImageUrl,
    this.logoUrl,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.subscriptionTier = BusinessSubscriptionTier.basic,
    this.subscriptionStatus = BusinessSubscriptionStatus.unknown,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        imageUrl,
        rating,
        reviewCount,
        distance,
        priceRange,
        status,
        isVerified,
        coverImageUrl,
        logoUrl,
        phoneNumber,
        latitude,
        longitude,
        subscriptionTier,
        subscriptionStatus,
      ];
}
