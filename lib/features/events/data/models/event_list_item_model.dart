import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/event_category.dart';

part 'event_list_item_model.g.dart';

@JsonSerializable()
class EventListItemModel extends EventListItem {
  const EventListItemModel({
    required super.id,
    required super.title,
    required super.imageUrl,
    required super.categories,
    required super.dateTime,
    required super.venue,
    required super.location,
    super.price,
    super.priceRange,
    super.isBookmarked,
  });

  factory EventListItemModel.fromJson(Map<String, dynamic> json) =>
      _$EventListItemModelFromJson(json);

  Map<String, dynamic> toJson() => _$EventListItemModelToJson(this);

  factory EventListItemModel.fromEntity(EventListItem entity) {
    return EventListItemModel(
      id: entity.id,
      title: entity.title,
      imageUrl: entity.imageUrl,
      categories: entity.categories,
      dateTime: entity.dateTime,
      venue: entity.venue,
      location: entity.location,
      price: entity.price,
      priceRange: entity.priceRange,
      isBookmarked: entity.isBookmarked,
    );
  }
}
