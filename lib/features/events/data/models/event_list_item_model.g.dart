// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event_list_item_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EventListItemModel _$EventListItemModelFromJson(Map<String, dynamic> json) =>
    EventListItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => $enumDecode(_$EventCategoryEnumMap, e))
          .toList(),
      dateTime: DateTime.parse(json['dateTime'] as String),
      venue: json['venue'] as String,
      location: json['location'] as String,
      price: (json['price'] as num?)?.toDouble(),
      priceRange: json['priceRange'] as String?,
      isBookmarked: json['isBookmarked'] as bool? ?? false,
    );

Map<String, dynamic> _$EventListItemModelToJson(EventListItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'imageUrl': instance.imageUrl,
      'categories': instance.categories
          .map((e) => _$EventCategoryEnumMap[e]!)
          .toList(),
      'dateTime': instance.dateTime.toIso8601String(),
      'venue': instance.venue,
      'location': instance.location,
      'price': instance.price,
      'priceRange': instance.priceRange,
      'isBookmarked': instance.isBookmarked,
    };

const _$EventCategoryEnumMap = {
  EventCategory.all: 'all',
  EventCategory.concerts: 'concerts',
  EventCategory.parties: 'parties',
  EventCategory.cultural: 'cultural',
  EventCategory.music: 'music',
  EventCategory.nightlife: 'nightlife',
  EventCategory.food: 'food',
  EventCategory.networking: 'networking',
  EventCategory.community: 'community',
};
