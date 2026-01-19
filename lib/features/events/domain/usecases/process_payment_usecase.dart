import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/order.dart' as events;
import '../repositories/events_repository.dart';

class ProcessPaymentUseCase {
  final EventsRepository repository;

  ProcessPaymentUseCase(this.repository);

  Future<Either<Failure, events.Order>> call({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    return await repository.processPayment(
      orderId: orderId,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );
  }
}
