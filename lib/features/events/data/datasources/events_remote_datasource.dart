import '../models/event_list_item_model.dart';
import '../models/event_detail_model.dart';
import '../models/ticket_model.dart';
import '../models/order_model.dart';
import '../../domain/entities/event_filters.dart';

abstract class EventsRemoteDataSource {
  Future<List<EventListItemModel>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  });

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
}
