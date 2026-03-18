import 'package:equatable/equatable.dart';

/// A single business or location managed by the owner (for selector and list).
class BusinessPresence extends Equatable {
  final String id;
  final String name;
  final String? locationName;
  final String category;
  final String? city;
  final String? state;
  final String imageUrl;
  final String? logoUrl;
  final String? backgroundUrl;
  final bool isVerified;
  final bool isOpenNow;
  final double? rating;
  final int? reviewCount;
  final String? statusText;
  final int? openOrdersCount;
  final String? businessGroupName;

  const BusinessPresence({
    required this.id,
    required this.name,
    this.locationName,
    required this.category,
    this.city,
    this.state,
    required this.imageUrl,
    this.logoUrl,
    this.backgroundUrl,
    this.isVerified = false,
    this.isOpenNow = true,
    this.rating,
    this.reviewCount,
    this.statusText,
    this.openOrdersCount,
    this.businessGroupName,
  });

  String get displayName => locationName != null ? '$name - $locationName' : name;
  String get shortDisplayName {
    if (name.length > 12) return '${name.substring(0, 10)}..';
    return name;
  }

  String get locationDisplay {
    if (city != null && state != null) return '$city, $state';
    if (locationName != null) return locationName!;
    return category;
  }

  /// User-friendly status text. Shows "Pending for approval" when not yet approved.
  String get statusDisplayText {
    if (statusText == 'pending') return 'Pending for approval';
    if (statusText == 'rejected') return 'Rejected';
    return category;
  }

  /// True when the business is awaiting admin approval.
  bool get isPendingApproval => statusText == 'pending';

  /// True when logo and background are both uploaded (required for full setup).
  bool get hasRequiredImages =>
      (logoUrl != null && logoUrl!.isNotEmpty) &&
      (backgroundUrl != null && backgroundUrl!.isNotEmpty);

  @override
  List<Object?> get props => [
        id,
        name,
        locationName,
        category,
        city,
        state,
        imageUrl,
        logoUrl,
        backgroundUrl,
        isVerified,
        isOpenNow,
        rating,
        reviewCount,
        statusText,
        openOrdersCount,
        businessGroupName,
      ];
}
