import 'package:equatable/equatable.dart';
import 'event_category.dart';

class EventFilters extends Equatable {
  final List<EventCategory> eventTypes;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minPrice;
  final double? maxPrice;
  final String? location;

  const EventFilters({
    this.eventTypes = const [],
    this.startDate,
    this.endDate,
    this.minPrice,
    this.maxPrice,
    this.location,
  });

  EventFilters copyWith({
    List<EventCategory>? eventTypes,
    DateTime? startDate,
    DateTime? endDate,
    double? minPrice,
    double? maxPrice,
    String? location,
  }) {
    return EventFilters(
      eventTypes: eventTypes ?? this.eventTypes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      location: location ?? this.location,
    );
  }

  bool get hasActiveFilters {
    return eventTypes.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        minPrice != null ||
        maxPrice != null ||
        (location != null && location!.isNotEmpty);
  }

  EventFilters reset() {
    return const EventFilters();
  }

  @override
  List<Object?> get props => [
        eventTypes,
        startDate,
        endDate,
        minPrice,
        maxPrice,
        location,
      ];
}
