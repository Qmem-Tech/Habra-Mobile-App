import 'package:equatable/equatable.dart';

class Deal extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String businessName;
  final String businessId;
  final double discountPercent;
  final String? promoCode;
  final DateTime? expiryDate;

  const Deal({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.businessName,
    required this.businessId,
    required this.discountPercent,
    this.promoCode,
    this.expiryDate,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        businessName,
        businessId,
        discountPercent,
        promoCode,
        expiryDate,
      ];
}
