import '../../domain/entities/event.dart';

class EventModel extends Event {
  const EventModel({
    required super.id,
    required super.title,
    super.description,
    required super.imageUrl,
    required super.dateTime,
    required super.location,
    super.venue,
    super.price,
    super.organizer,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      location: json['location'] as String,
      venue: json['venue'] as String?,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      organizer: json['organizer'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'venue': venue,
      'price': price,
      'organizer': organizer,
    };
  }
}
