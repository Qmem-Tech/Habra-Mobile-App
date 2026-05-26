import 'package:equatable/equatable.dart';
import 'business_list_item.dart';

enum DealType {
  hotDeal,
  happyHour,
  limitedTime,
  other;

  String get displayName {
    switch (this) {
      case DealType.hotDeal:
        return 'Hot Deal';
      case DealType.happyHour:
        return 'Happy Hour';
      case DealType.limitedTime:
        return 'Limited Time';
      case DealType.other:
        return 'Deal';
    }
  }
}

class Deal extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final BusinessListItem business;
  final DealType type;
  final double? originalPrice;
  final double? discountedPrice;
  final String? discountText; // e.g., "20% Off", "Buy 1 Get 1 Free"
  final DateTime? expiresAt;
  final String? termsAndConditions;
  final List<String> dealDetails; // What's included
  final String? redemptionCode;
  final bool isRedeemable;
  final String? validDays; // e.g., "Mon-Fri"
  final String? validTime; // e.g., "5-7 PM"

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.business,
    required this.type,
    this.originalPrice,
    this.discountedPrice,
    this.discountText,
    this.expiresAt,
    this.termsAndConditions,
    this.dealDetails = const [],
    this.redemptionCode,
    this.isRedeemable = false,
    this.validDays,
    this.validTime,
  });

  String get displayPrice {
    if (discountedPrice != null) {
      return '\$${discountedPrice!.toStringAsFixed(2)}';
    }
    return discountText ?? 'Special Offer';
  }

  String? get originalPriceDisplay {
    if (originalPrice != null) {
      return '\$${originalPrice!.toStringAsFixed(2)}';
    }
    return null;
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        business,
        type,
        originalPrice,
        discountedPrice,
        discountText,
        expiresAt,
        termsAndConditions,
        dealDetails,
        redemptionCode,
        isRedeemable,
        validDays,
        validTime,
      ];
}
