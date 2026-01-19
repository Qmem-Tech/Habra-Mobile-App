// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessListItemModel _$BusinessListItemModelFromJson(
        Map<String, dynamic> json) =>
    BusinessListItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => $enumDecode(_$BusinessCategoryEnumMap, e))
          .toList(),
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      distance: (json['distance'] as num?)?.toDouble(),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['reviewCount'] as num).toInt(),
      priceRange: json['priceRange'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      isOpen: json['isOpen'] as bool,
      closingTime: json['closingTime'] as String?,
      openingTime: json['openingTime'] as String?,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );

Map<String, dynamic> _$BusinessListItemModelToJson(
        BusinessListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'categories': instance.categories
          .map((e) => _$BusinessCategoryEnumMap[e]!)
          .toList(),
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'distance': instance.distance,
      'rating': instance.rating,
      'reviewCount': instance.reviewCount,
      'priceRange': instance.priceRange,
      'isVerified': instance.isVerified,
      'isOpen': instance.isOpen,
      'closingTime': instance.closingTime,
      'openingTime': instance.openingTime,
      'isFeatured': instance.isFeatured,
    };

const _$BusinessCategoryEnumMap = {
  BusinessCategory.all: 'all',
  BusinessCategory.food: 'food',
  BusinessCategory.beauty: 'beauty',
  BusinessCategory.grocery: 'grocery',
  BusinessCategory.legal: 'legal',
  BusinessCategory.coffee: 'coffee',
  BusinessCategory.spices: 'spices',
  BusinessCategory.restaurant: 'restaurant',
  BusinessCategory.cafe: 'cafe',
  BusinessCategory.barbershop: 'barbershop',
  BusinessCategory.salon: 'salon',
  BusinessCategory.import: 'import',
  BusinessCategory.other: 'other',
};
