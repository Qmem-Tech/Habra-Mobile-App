import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_user_tickets_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../domain/entities/order.dart' as events;
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetUserTicketsUseCase getUserTicketsUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;

  TicketsCubit({
    required this.getUserTicketsUseCase,
    required this.createOrderUseCase,
    required this.processPaymentUseCase,
  }) : super(TicketsInitial());

  Future<void> loadUserTickets({bool upcomingOnly = true}) async {
    emit(TicketsLoading());

    final result = await getUserTicketsUseCase(upcomingOnly: upcomingOnly);

    result.fold(
      (failure) => emit(TicketsError(failure.message)),
      (tickets) {
        if (tickets.isEmpty) {
          emit(TicketsEmpty(isUpcoming: upcomingOnly));
        } else {
          emit(TicketsLoaded(tickets: tickets, isUpcoming: upcomingOnly));
        }
      },
    );
  }

  Future<void> createOrder({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
  }) async {
    emit(OrderLoading());

    final result = await createOrderUseCase(
      eventId: eventId,
      tickets: tickets,
      contactInfo: contactInfo,
    );

    result.fold(
      (failure) => emit(OrderError(failure.message)),
      (order) => emit(OrderCreated(order)),
    );
  }

  Future<void> processPayment({
    required String orderId,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    final currentState = state;
    events.Order? currentOrder;

    if (currentState is OrderCreated) {
      currentOrder = currentState.order;
      emit(PaymentProcessing(currentOrder));
    }

    final result = await processPaymentUseCase(
      orderId: orderId,
      paymentMethod: paymentMethod,
      promoCode: promoCode,
    );

    result.fold(
      (failure) => emit(PaymentFailed(
        failure.message,
        order: currentOrder,
      )),
      (order) {
        if (order.status == events.OrderStatus.completed) {
          emit(PaymentSuccess(order));
        } else {
          emit(PaymentFailed(
            'Payment could not be processed',
            order: order,
          ));
        }
      },
    );
  }
}
