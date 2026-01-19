import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/business_list_item.dart';
import '../../domain/entities/business_category.dart';

part 'business_list_item_model.g.dart';

@JsonSerializable()
class BusinessListItemModel extends BusinessListItem {
  const BusinessListItemModel({
    required super.id,
    required super.name,
    required super.imageUrl,
    required super.categories,
    required super.address,
    required super.city,
    required super.state,
    super.distance,
    required super.rating,
    required super.reviewCount,
    super.priceRange,
    super.isVerified,
    required super.isOpen,
    super.closingTime,
    super.openingTime,
    super.isFeatured,
  });

  factory BusinessListItemModel.fromJson(Map<String, dynamic> json) =>
      _$BusinessListItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessListItemModelToJson(this);

  factory BusinessListItemModel.fromEntity(BusinessListItem entity) {
    return BusinessListItemModel(
      id: entity.id,
      name: entity.name,
      imageUrl: entity.imageUrl,
      categories: entity.categories,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      distance: entity.distance,
      rating: entity.rating,
      reviewCount: entity.reviewCount,
      priceRange: entity.priceRange,
      isVerified: entity.isVerified,
      isOpen: entity.isOpen,
      closingTime: entity.closingTime,
      openingTime: entity.openingTime,
      isFeatured: entity.isFeatured,
    );
  }
}
