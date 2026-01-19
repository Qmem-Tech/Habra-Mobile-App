import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/event_list_item.dart';
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/event_filters.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/order.dart' as events;
import '../../domain/repositories/events_repository.dart';
import '../datasources/events_remote_datasource.dart';

class EventsRepositoryImpl implements EventsRepository {
  final EventsRemoteDataSource remoteDataSource;

  EventsRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<EventListItem>>> getEvents({
    String? location,
    EventFilters? filters,
    String? searchQuery,
  }) async {
    try {
      final events = await remoteDataSource.getEvents(
        location: location,
        filters: filters,
        searchQuery: searchQuery,
      );
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EventDetail>> getEventDetail(String eventId) async {
    try {
      final event = await remoteDataSource.getEventDetail(eventId);
      return Right(event);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<EventListItem>>> getSimilarEvents(String eventId) async {
    try {
      final events = await remoteDataSource.getSimilarEvents(eventId);
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Ticket>>> getUserTickets({bool upcomingOnly = true}) async {
    try {
      final tickets = await remoteDataSource.getUserTickets(upcomingOnly: upcomingOnly);
      return Right(tickets);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Ticket>> getTicketDetail(String ticketId) async {
    try {
      final ticket = await remoteDataSource.getTicketDetail(ticketId);
      return Right(ticket);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, events.Order>> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    try {
      final order = await remoteDataSource.createOrder(
        eventId: eventId,
        tickets: tickets,
        contactInfo: contactInfo,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, events.Order>> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    try {
      final order = await remoteDataSource.processPayment(
        orderId: orderId,
        paymentMethod: paymentMethod,
        promoCode: promoCode,
      );
      return Right(order);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
