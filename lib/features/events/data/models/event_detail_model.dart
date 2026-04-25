import '../../domain/entities/event_detail.dart';
import '../../domain/entities/event_category.dart';
import 'ticket_type_model.dart';

class EventDetailModel extends EventDetail {
  const EventDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.imageUrl,
    required super.categories,
    required super.startDate,
    required super.endDate,
    required super.venue,
    required super.address,
    required super.city,
    required super.state,
    super.zipCode,
    super.latitude,
    super.longitude,
    super.minPrice,
    super.maxPrice,
    super.organizer,
    super.isOnline,
    super.onlineUrl,
    required super.ticketTypes,
    super.isBookmarked,
    super.policies,
  });

  factory EventDetailModel.fromJson(Map<String, dynamic> json) {
    return EventDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      categories: (json['categories'] as List<dynamic>)
          .map((e) => EventCategory.values.firstWhere(
                (cat) => cat.toString() == 'EventCategory.$e',
                orElse: () => EventCategory.all,
              ))
          .toList(),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      venue: json['venue'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String?,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null,
      maxPrice: json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null,
      organizer: json['organizer'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      onlineUrl: json['onlineUrl'] as String?,
      ticketTypes: (json['ticketTypes'] as List<dynamic>)
          .map((e) => TicketTypeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      isBookmarked: json['isBookmarked'] as bool? ?? false,
      policies: json['policies'] != null
          ? (json['policies'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'categories': categories.map((c) => c.toString().split('.').last).toList(),
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'venue': venue,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'latitude': latitude,
      'longitude': longitude,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'organizer': organizer,
      'isOnline': isOnline,
      'onlineUrl': onlineUrl,
      'ticketTypes': ticketTypes.map((tt) {
        return tt is TicketTypeModel
            ? tt.toJson()
            : TicketTypeModel.fromEntity(tt).toJson();
      }).toList(),
      'isBookmarked': isBookmarked,
      'policies': policies,
    };
  }

  factory EventDetailModel.fromEntity(EventDetail entity) {
    final ticketTypeModels = entity.ticketTypes.map((tt) {
      return tt is TicketTypeModel
          ? tt
          : TicketTypeModel.fromEntity(tt);
    }).toList();

    return EventDetailModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      imageUrl: entity.imageUrl,
      categories: entity.categories,
      startDate: entity.startDate,
      endDate: entity.endDate,
      venue: entity.venue,
      address: entity.address,
      city: entity.city,
      state: entity.state,
      zipCode: entity.zipCode,
      latitude: entity.latitude,
      longitude: entity.longitude,
      minPrice: entity.minPrice,
      maxPrice: entity.maxPrice,
      organizer: entity.organizer,
      isOnline: entity.isOnline,
      onlineUrl: entity.onlineUrl,
      ticketTypes: ticketTypeModels,
      isBookmarked: entity.isBookmarked,
      policies: entity.policies,
    );
  }
}
