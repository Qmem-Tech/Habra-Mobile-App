import '../../domain/entities/deal.dart';

class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.businessName,
    required super.businessId,
    required super.discountPercent,
    super.promoCode,
    super.expiryDate,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      businessName: json['businessName'] as String,
      businessId: json['businessId'] as String,
      discountPercent: (json['discountPercent'] as num).toDouble(),
      promoCode: json['promoCode'] as String?,
      expiryDate: json['expiryDate'] != null
          ? DateTime.parse(json['expiryDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'businessName': businessName,
      'businessId': businessId,
      'discountPercent': discountPercent,
      'promoCode': promoCode,
      'expiryDate': expiryDate?.toIso8601String(),
    };
  }
}
