import 'package:equatable/equatable.dart';
import 'event_category.dart';

/// Data for creating a new event.
class CreateEventData extends Equatable {
  const CreateEventData({
    required this.title,
    required this.description,
    required this.venueName,
    required this.venueAddress,
    this.venueLat,
    this.venueLng,
    required this.startAt,
    required this.endAt,
    this.imageUrl,
    this.category = EventCategory.community,
    this.businessId,
    required this.ticketTypes,
  });

  final String title;
  final String description;
  final String venueName;
  final String venueAddress;
  final double? venueLat;
  final double? venueLng;
  final DateTime startAt;
  final DateTime endAt;
  final String? imageUrl;
  final EventCategory category;
  final String? businessId;
  final List<CreateEventTicketType> ticketTypes;

  @override
  List<Object?> get props => [
        title,
        description,
        venueName,
        venueAddress,
        venueLat,
        venueLng,
        startAt,
        endAt,
        imageUrl,
        category,
        businessId,
        ticketTypes,
      ];
}

/// Ticket type for event creation.
class CreateEventTicketType extends Equatable {
  const CreateEventTicketType({
    required this.name,
    required this.price,
    required this.quantityAvailable,
  });

  final String name;
  final double price;
  final int quantityAvailable;

  @override
  List<Object?> get props => [name, price, quantityAvailable];
}
