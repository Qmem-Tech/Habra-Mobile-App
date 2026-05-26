import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/services/stripe_payment_service.dart';
import '../../domain/usecases/get_user_tickets_usecase.dart';
import '../../domain/usecases/create_order_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../domain/usecases/cancel_unpaid_event_order_usecase.dart';
import '../../domain/entities/order.dart' as events;
import 'tickets_state.dart';

class TicketsCubit extends Cubit<TicketsState> {
  final GetUserTicketsUseCase getUserTicketsUseCase;
  final CreateOrderUseCase createOrderUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final CancelUnpaidEventOrderUseCase cancelUnpaidEventOrderUseCase;
  final StripePaymentService stripePaymentService;

  TicketsCubit({
    required this.getUserTicketsUseCase,
    required this.createOrderUseCase,
    required this.processPaymentUseCase,
    required this.cancelUnpaidEventOrderUseCase,
    required this.stripePaymentService,
  }) : super(TicketsInitial());

  Future<void> loadUserTickets({
    bool upcomingOnly = true,
    bool showLoading = true,
  }) async {
    if (showLoading) emit(TicketsLoading());

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

  /// Retry Stripe PaymentSheet for an existing unpaid order (My Tickets).
  /// Returns an error message on failure, or null on success / user-cancelled sheet.
  Future<String?> retryOrderPayment(String orderId) async {
    final prev = state;
    var upcoming = true;
    if (prev is TicketsLoaded) {
      upcoming = prev.isUpcoming;
      emit(TicketsLoaded(
        tickets: prev.tickets,
        isUpcoming: upcoming,
        pendingOrderActionId: orderId,
      ));
    }

    if (!stripePaymentService.isConfigured) {
      if (prev is TicketsLoaded) {
        emit(TicketsLoaded(tickets: prev.tickets, isUpcoming: upcoming));
      }
      return 'Card payments are not configured.';
    }

    try {
      final fetch = await stripePaymentService.fetchPaymentSheetSession(orderId);
      final session = fetch.session;
      if (session == null || session.clientSecret.isEmpty) {
        if (prev is TicketsLoaded) {
          emit(TicketsLoaded(tickets: prev.tickets, isUpcoming: upcoming));
        }
        return fetch.errorMessage ??
            'Could not start payment. Check your connection and try again.';
      }

      await Future<void>.delayed(Duration.zero);

      final sheet = await stripePaymentService.presentPaymentSheet(
        paymentIntentClientSecret: session.clientSecret,
        customerId: session.customerId,
        customerEphemeralKeySecret: session.customerEphemeralKeySecret,
      );
      if (!sheet.succeeded) {
        if (prev is TicketsLoaded) {
          emit(TicketsLoaded(tickets: prev.tickets, isUpcoming: upcoming));
        }
        // User-cancelled: no toast. Real failure: surface the message.
        return sheet.wasCancelled ? null : sheet.message;
      }

      final processResult = await processPaymentUseCase(
        orderId: orderId,
        paymentMethod: {
          'type': 'stripe',
          'id': 'stripe_payment_sheet_v2',
          'payment_intent_id': session.paymentIntentId,
          'customer_id': session.customerId,
        },
      );

      String? message;
      processResult.fold(
        (f) => message = f.message,
        (order) {
          if (order.status == events.OrderStatus.processing ||
              order.status == events.OrderStatus.pending) {
            message =
                'Payment received — confirming your order. Pull to refresh in a moment.';
          }
        },
      );

      await loadUserTickets(upcomingOnly: upcoming, showLoading: false);
      return message;
    } catch (e) {
      if (prev is TicketsLoaded) {
        emit(TicketsLoaded(tickets: prev.tickets, isUpcoming: upcoming));
      }
      return e.toString();
    }
  }

  /// Cancels an unpaid order with an **optimistic** UI update: the row is
  /// removed from the list (or kept on failure) the moment the cancel RPC
  /// returns, so the "Removing…" spinner doesn't have to wait for a slow
  /// re-fetch of every ticket. A background refresh is fire-and-forget so the
  /// list eventually reconciles with the server.
  Future<String?> cancelUnpaidOrder(String orderId) async {
    final prev = state;
    if (prev is! TicketsLoaded) {
      // Nothing on screen to optimistically update — defer to the basic flow.
      final result = await cancelUnpaidEventOrderUseCase(orderId);
      await loadUserTickets(showLoading: false);
      String? err;
      result.fold((f) => err = f.message, (_) {});
      return err;
    }

    final upcoming = prev.isUpcoming;
    final originalTickets = prev.tickets;

    // 1. Show inline spinner on the row being removed.
    emit(TicketsLoaded(
      tickets: originalTickets,
      isUpcoming: upcoming,
      pendingOrderActionId: orderId,
    ));

    // 2. Run the cancel call.
    final result = await cancelUnpaidEventOrderUseCase(orderId);

    final failure = result.fold<Failure?>((f) => f, (_) => null);

    // 3. Emit the resolved state immediately — never leave the spinner on.
    if (failure == null) {
      final next = originalTickets
          .where((t) => t.orderId != orderId)
          .toList(growable: false);
      if (next.isEmpty) {
        emit(TicketsEmpty(isUpcoming: upcoming));
      } else {
        emit(TicketsLoaded(tickets: next, isUpcoming: upcoming));
      }
    } else {
      // Cancel failed — restore the original list without the spinner.
      emit(TicketsLoaded(tickets: originalTickets, isUpcoming: upcoming));
    }

    // 4. Background reconciliation. We don't await; the spinner is already
    // gone and the list is already correct optimistically.
    unawaited(loadUserTickets(upcomingOnly: upcoming, showLoading: false));

    return failure?.message;
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
  ///
  /// Emits [OrderLoading] → [PaymentProcessing] (creatingOrder → securingPayment →
  /// confirmingOrder) so the checkout UI can show a 3-step progress indicator.
  Future<void> performCheckout({
    required String eventId,
    required List<Map<String, dynamic>> tickets,
    required Map<String, dynamic> contactInfo,
    required Map<String, dynamic> paymentMethod,
    String? promoCode,
  }) async {
    emit(const OrderLoading(phase: PaymentPhase.creatingOrder));

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

    emit(PaymentProcessing(order, phase: PaymentPhase.securingPayment));

    if (!stripePaymentService.isConfigured) {
      emit(PaymentFailed(
        'Card payments are not configured. Set STRIPE_PUBLISHABLE_KEY and your payment backend.',
        order: order,
      ));
      return;
    }

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

    final sheet = await stripePaymentService.presentPaymentSheet(
      paymentIntentClientSecret: session.clientSecret,
      customerId: session.customerId,
      customerEphemeralKeySecret: session.customerEphemeralKeySecret,
    );
    if (!sheet.succeeded) {
      emit(PaymentFailed(
        sheet.wasCancelled
            ? 'Payment was cancelled. Your card was not charged.'
            : (sheet.message ?? 'Payment could not be completed.'),
        order: order,
      ));
      return;
    }

    emit(PaymentProcessing(order, phase: PaymentPhase.confirmingOrder));

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
            'Your payment went through. We’re confirming your order — check My Tickets in a moment.',
            order: completedOrder,
            awaitingConfirmation: true,
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
  }
}
