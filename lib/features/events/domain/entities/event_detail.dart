import 'package:equatable/equatable.dart';
import 'event_category.dart';
import 'ticket_type.dart';

class EventDetail extends Equatable {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final List<EventCategory> categories;
  final DateTime startDate;
  final DateTime endDate;
  final String venue;
  final String address;
  final String city;
  final String state;
  final String? zipCode;
  final double? latitude;
  final double? longitude;
  final double? minPrice;
  final double? maxPrice;
  final String? organizer;
  final bool isOnline;
  final String? onlineUrl;
  final List<TicketType> ticketTypes;
  final bool isBookmarked;
  final List<String>? policies;

  const EventDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.categories,
    required this.startDate,
    required this.endDate,
    required this.venue,
    required this.address,
    required this.city,
    required this.state,
    this.zipCode,
    this.latitude,
    this.longitude,
    this.minPrice,
    this.maxPrice,
    this.organizer,
    this.isOnline = false,
    this.onlineUrl,
    required this.ticketTypes,
    this.isBookmarked = false,
    this.policies,
  });

  String get fullAddress {
    final parts = [address, city, state];
    if (zipCode != null) parts.add(zipCode!);
    return parts.join(', ');
  }

  String get categoriesDisplay {
    return categories.map((c) => c.displayName).join(' • ');
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        categories,
        startDate,
        endDate,
        venue,
        address,
        city,
        state,
        zipCode,
        latitude,
        longitude,
        minPrice,
        maxPrice,
        organizer,
        isOnline,
        onlineUrl,
        ticketTypes,
        isBookmarked,
        policies,
      ];
}
