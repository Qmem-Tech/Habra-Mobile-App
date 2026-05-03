import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event_list_item.dart';
import '../entities/event_detail.dart';
import '../entities/event_filters.dart';
import '../entities/ticket.dart';
import '../entities/order.dart' as events;
import '../entities/create_event_data.dart';

abstract class EventsRepository {
  Future<Either<Failure, List<EventListItem>>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  });

  /// Events hosted by this business listing (`events.business_id`).
  Future<Either<Failure, List<EventListItem>>> getEventsByBusinessId(
    String businessId,
  );

  Future<Either<Failure, EventDetail>> getEventDetail(String eventId);

  Future<Either<Failure, List<EventListItem>>> getSimilarEvents(String eventId);

  Future<Either<Failure, List<Ticket>>> getUserTickets({
    bool upcomingOnly = true,
  });

  Future<Either<Failure, Ticket>> getTicketDetail(String ticketId);

  Future<Either<Failure, events.Order>> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  });

  Future<Either<Failure, events.Order>> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  });

  Future<Either<Failure, EventDetail>> createEvent(CreateEventData data);

  Future<Either<Failure, EventDetail>> updateEvent(
    String eventId,
    CreateEventData data,
  );
}
