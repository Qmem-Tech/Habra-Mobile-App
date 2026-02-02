import '../models/event_list_item_model.dart';
import '../models/event_detail_model.dart';
import '../models/ticket_model.dart';
import '../models/order_model.dart';
import '../../domain/entities/event_filters.dart';
import 'mock_data/mock_events_data.dart';

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
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    return MockEventsData.getMockEvents(
      location: location,
      categories: filters?.eventTypes,
      searchQuery: searchQuery,
    );
  }

  @override
  Future<EventDetailModel> getEventDetail(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return MockEventsData.getEventDetail(eventId);
  }

  @override
  Future<List<EventListItemModel>> getSimilarEvents(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockEventsData.getSimilarEvents(eventId);
  }

  @override
  Future<List<TicketModel>> getUserTickets({bool upcomingOnly = true}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return MockEventsData.getUserTickets(upcomingOnly: upcomingOnly);
  }

  @override
  Future<TicketModel> getTicketDetail(String ticketId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return MockEventsData.getTicketDetail(ticketId);
  }

  @override
  Future<OrderModel> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    await Future.delayed(const Duration(milliseconds: 1000));
    return MockEventsData.createOrder(
      eventId: eventId,
      tickets: tickets,
      contactInfo: contactInfo,
    );
  }

  @override
  Future<OrderModel> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 2000));
    return MockEventsData.processPayment(
      orderId: orderId,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
  }
}
