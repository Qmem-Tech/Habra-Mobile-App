import '../models/event_list_item_model.dart';
import '../models/event_detail_model.dart';
import '../models/ticket_model.dart';
import '../models/order_model.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/entities/create_event_data.dart';

abstract class EventsRemoteDataSource {
  Future<List<EventListItemModel>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  });

  /// Public listings linked to a business listing (`events.business_id`).
  Future<List<EventListItemModel>> getEventsByBusinessId(String businessId);

  Future<EventDetailModel> getEventDetail(String eventId);

  Future<List<EventListItemModel>> getSimilarEvents(String eventId);

  Future<List<TicketModel>> getUserTickets({bool upcomingOnly = true});

  Future<TicketModel> getTicketDetail(String ticketId);

  Future<OrderModel> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  });

  Future<OrderModel> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  });

  Future<EventDetailModel> createEvent(CreateEventData data);

  /// Updates an existing event row (organizer-only). Ticket types are unchanged.
  Future<EventDetailModel> updateEvent(String eventId, CreateEventData data);
}

class EventsRemoteDataSourceImpl implements EventsRemoteDataSource {
  @override
  Future<List<EventListItemModel>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    return [];
  }

  @override
  Future<List<EventListItemModel>> getEventsByBusinessId(String businessId) async {
    return [];
  }

  @override
  Future<EventDetailModel> getEventDetail(String eventId) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must provide event $eventId',
    );
  }

  @override
  Future<List<EventListItemModel>> getSimilarEvents(String eventId) async {
    return [];
  }

  @override
  Future<List<TicketModel>> getUserTickets({bool upcomingOnly = true}) async {
    return [];
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must provide ticket $ticketId',
    );
  }

  @override
  Future<OrderModel> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must handle createOrder.',
    );
  }

  @override
  Future<OrderModel> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must handle processPayment.',
    );
  }

  @override
  Future<EventDetailModel> createEvent(CreateEventData data) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must handle createEvent.',
    );
  }

  @override
  Future<EventDetailModel> updateEvent(String eventId, CreateEventData data) async {
    throw UnimplementedError(
      'Use EventsSupabaseDataSource; backend must handle updateEvent.',
    );
  }
}
