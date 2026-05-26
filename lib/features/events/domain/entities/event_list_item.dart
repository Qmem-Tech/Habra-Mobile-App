import 'package:equatable/equatable.dart';
import 'event_category.dart';

class EventListItem extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final List<EventCategory> categories;
  final DateTime dateTime;
  final String venue;
  final String location;
  final double? price;
  final String? priceRange;
  final bool isBookmarked;

  const EventListItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.categories,
    required this.dateTime,
    required this.venue,
    required this.location,
    this.price,
    this.priceRange,
    this.isBookmarked = false,
  });

  String get displayPrice {
    if (priceRange != null) return priceRange!;
    if (price != null) return '\$${price!.toStringAsFixed(0)}';
    return 'Free';
  }

  @override
  List<Object?> get props => [
        id,
        title,
        imageUrl,
        categories,
        dateTime,
        venue,
        location,
        price,
        priceRange,
        isBookmarked,
      ];
}
