import 'package:equatable/equatable.dart';

enum OwnerDealStatus { draft, published, paused, expired, unknown }

class Deal extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String businessName;
  final String businessId;
  /// Business logo for deal cards (e.g. small circle over hero image).
  final String? businessLogoUrl;
  final double discountPercent;
  final String? promoCode;
  final DateTime? expiryDate;
  final OwnerDealStatus status;

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.businessName,
    required this.businessId,
    this.businessLogoUrl,
    required this.discountPercent,
    this.promoCode,
    this.expiryDate,
    this.status = OwnerDealStatus.unknown,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        businessName,
        businessId,
        businessLogoUrl,
        discountPercent,
        promoCode,
        expiryDate,
        status,
      ];
}
