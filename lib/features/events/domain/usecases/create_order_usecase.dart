import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order.dart' as events;
import '../repositories/events_repository.dart';

class CreateOrderUseCase {
  final EventsRepository repository;

  CreateOrderUseCase(this.repository);

  Future<Either<Failure, events.Order>> call({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    return await repository.createOrder(
      eventId: eventId,
      tickets: tickets,
      contactInfo: contactInfo,
    );
  }
}
