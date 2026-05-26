import '../../domain/entities/deal.dart';
import 'business_list_item_model.dart';
class DealModel extends Deal {
  const DealModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.business,
    required super.type,
    super.originalPrice,
    super.discountedPrice,
    super.discountText,
    super.expiresAt,
    super.termsAndConditions,
    super.dealDetails,
    super.redemptionCode,
    super.isRedeemable,
    super.validDays,
    super.validTime,
  });

  factory DealModel.fromJson(Map<String, dynamic> json) {
    return DealModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      business: BusinessListItemModel.fromJson(json['business'] as Map<String, dynamic>),
      type: DealType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => DealType.other,
      ),
      originalPrice: json['originalPrice'] as double?,
      discountedPrice: json['discountedPrice'] as double?,
      discountText: json['discountText'] as String?,
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      termsAndConditions: json['termsAndConditions'] as String?,
      dealDetails: (json['dealDetails'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      redemptionCode: json['redemptionCode'] as String?,
      isRedeemable: json['isRedeemable'] as bool? ?? false,
      validDays: json['validDays'] as String?,
      validTime: json['validTime'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'business': business is BusinessListItemModel
          ? (business as BusinessListItemModel).toJson()
          : BusinessListItemModel.fromEntity(business).toJson(),
      'type': type.name,
      'originalPrice': originalPrice,
      'discountedPrice': discountedPrice,
      'discountText': discountText,
      'expiresAt': expiresAt?.toIso8601String(),
      'termsAndConditions': termsAndConditions,
      'dealDetails': dealDetails,
      'redemptionCode': redemptionCode,
      'isRedeemable': isRedeemable,
      'validDays': validDays,
      'validTime': validTime,
    };
  }
}
