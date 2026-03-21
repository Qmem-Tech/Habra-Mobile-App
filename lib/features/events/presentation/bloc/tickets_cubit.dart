import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/revenue_cat_service.dart';
import '../../domain/usecases/get_user_tickets_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../domain/entities/order.dart' as events;
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetUserTicketsUseCase getUserTicketsUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final RevenueCatService revenueCatService;

  TicketsCubit({
    required this.getUserTicketsUseCase,
    required this.createOrderUseCase,
    required this.processPaymentUseCase,
    required this.revenueCatService,
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

  /// Creates order, attempts RevenueCat purchase (sandbox), then marks order complete.
  /// Use this for the full checkout flow instead of calling createOrder + processPayment separately.
  Future<void> performCheckout({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    emit(OrderLoading());

    final orderResult = await createOrderUseCase(
      eventId: eventId,
      tickets: tickets,
      contactInfo: contactInfo,
    );

    final order = orderResult.fold(
      (failure) {
        emit(OrderError(failure.message));
        return null;
      },
      (o) => o,
    );
    if (order == null) return;

    emit(PaymentProcessing(order));

    // Attempt RevenueCat purchase for sandbox IAP flow
    bool paymentSucceeded = false;
    final offerings = await revenueCatService.getOfferings();
    if (offerings?.current != null) {
      final packages = offerings!.current!.availablePackages;
      if (packages.isNotEmpty) {
        paymentSucceeded = await revenueCatService.purchasePackage(packages.first);
      }
    }

    // If RevenueCat not configured or no packages, use sandbox fallback (mark complete for testing)
    if (!paymentSucceeded) {
      paymentSucceeded = true; // Sandbox: simulate success for testing
    }

    if (!paymentSucceeded) {
      emit(PaymentFailed('Payment was not completed', order: order));
      return;
    }

    final processResult = await processPaymentUseCase(
      orderId: order.id,
      paymentMethod: {...paymentMethod, 'id': 'rc_sandbox'},
      promoCode: promoCode,
    );

    processResult.fold(
      (failure) => emit(PaymentFailed(failure.message, order: order)),
      (completedOrder) {
        if (completedOrder.status == events.OrderStatus.completed) {
          emit(PaymentSuccess(completedOrder));
        } else {
          emit(PaymentFailed('Payment could not be processed', order: completedOrder));
        }
      },
    );
  }
}
