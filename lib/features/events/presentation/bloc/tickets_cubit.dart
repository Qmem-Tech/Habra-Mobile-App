import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../domain/usecases/get_user_tickets_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../domain/entities/order.dart' as events;
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetUserTicketsUseCase getUserTicketsUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final StripePaymentService stripePaymentService;

  TicketsCubit({
    required this.getUserTicketsUseCase,
    required this.createOrderUseCase,
    required this.processPaymentUseCase,
    required this.stripePaymentService,
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
        } else if (order.status == events.OrderStatus.processing ||
            order.status == events.OrderStatus.pending) {
          emit(PaymentFailed(
            'Payment confirmation is still in progress. Please check My Tickets in a moment.',
            order: order,
          ));
        } else {
          emit(PaymentFailed(
            order.status == events.OrderStatus.refunded
                ? 'Payment was refunded.'
                : 'Payment could not be processed',
            order: order,
          ));
        }
      },
    );
  }

  /// Event tickets: Stripe PaymentSheet when configured; debug-only unpaid completion otherwise.
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

    if (stripePaymentService.isConfigured) {
      final fetch = await stripePaymentService.fetchPaymentSheetSession(order.id);
      final session = fetch.session;
      if (session == null || session.clientSecret.isEmpty) {
        emit(PaymentFailed(
          fetch.errorMessage ??
              'Could not start card payment. Deploy the payment Edge Function and set '
              'STRIPE_SECRET_KEY (sk_…) in Supabase secrets — not the publishable pk_ key.',
          order: order,
        ));
        return;
      }

      // Let the frame finish so the Stripe sheet can present reliably (esp. Android).
      await Future<void>.delayed(Duration.zero);

      final paid = await stripePaymentService.presentPaymentSheet(
        paymentIntentClientSecret: session.clientSecret,
        customerId: session.customerId,
        customerEphemeralKeySecret: session.customerEphemeralKeySecret,
      );
      if (!paid) {
        emit(PaymentFailed('Payment was cancelled.', order: order));
        return;
      }

      final processResult = await processPaymentUseCase(
        orderId: order.id,
        paymentMethod: {
          ...paymentMethod,
          'type': 'stripe',
          'id': 'stripe_payment_sheet_v2',
          'payment_intent_id': session.paymentIntentId,
          'customer_id': session.customerId,
        },
        promoCode: promoCode,
      );

      processResult.fold(
        (failure) => emit(PaymentFailed(failure.message, order: order)),
        (completedOrder) {
          if (completedOrder.status == events.OrderStatus.completed) {
            emit(PaymentSuccess(completedOrder));
          } else if (completedOrder.status == events.OrderStatus.processing ||
              completedOrder.status == events.OrderStatus.pending) {
            emit(PaymentFailed(
              'Payment confirmation is still processing. Your charge may still complete shortly.',
              order: completedOrder,
            ));
          } else {
            emit(PaymentFailed(
              completedOrder.status == events.OrderStatus.refunded
                  ? 'Payment was refunded.'
                  : 'Payment could not be processed',
              order: completedOrder,
            ));
          }
        },
      );
      return;
    }

    emit(PaymentFailed(
      'Card payments are not configured. Set STRIPE_PUBLISHABLE_KEY and your payment backend.',
      order: order,
    ));
  }
}
