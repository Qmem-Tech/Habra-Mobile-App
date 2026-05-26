import 'package:equatable/equatable.dart';
import '../../domain/entities/ticket.dart';
import '../../domain/entities/order.dart' as events;

abstract class TicketsState extends Equatable {
  const TicketsState();

  @override
  List<Object?> get props => [];
}

class TicketsInitial extends TicketsState {}

class TicketsLoading extends TicketsState {}

class TicketsLoaded extends TicketsState {
  final List<Ticket> tickets;
  final bool isUpcoming;

  /// Inline spinner on My Tickets for retry/cancel on this order.
  final String? pendingOrderActionId;

  const TicketsLoaded({
    required this.tickets,
    this.isUpcoming = true,
    this.pendingOrderActionId,
  });

  @override
  List<Object?> get props => [tickets, isUpcoming, pendingOrderActionId];
}

class TicketsError extends TicketsState {
  final String message;

  const TicketsError(this.message);

  @override
  List<Object?> get props => [message];
}

class TicketsEmpty extends TicketsState {
  final bool isUpcoming;

  const TicketsEmpty({this.isUpcoming = true});

  @override
  List<Object?> get props => [isUpcoming];
}

// Order States
class OrderInitial extends TicketsState {}

class OrderLoading extends TicketsState {
  /// Step shown in checkout progress UI ([PaymentPhase.creatingOrder]).
  final PaymentPhase phase;

  const OrderLoading({this.phase = PaymentPhase.creatingOrder});

  @override
  List<Object?> get props => [phase];
}

class OrderCreated extends TicketsState {
  final events.Order order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

/// Phases shown in the checkout progress UI. Mapped to a 3-step indicator on
/// CheckoutPage and a final-step confirmation banner.
enum PaymentPhase {
  /// Creating the order row in Supabase before fetching the Stripe client secret.
  creatingOrder,

  /// Stripe PaymentSheet is being prepared / presented.
  securingPayment,

  /// Sheet succeeded; waiting on Edge Function or webhook to flip status to completed.
  confirmingOrder,
}

class PaymentProcessing extends TicketsState {
  final events.Order order;
  final PaymentPhase phase;

  const PaymentProcessing(this.order, {this.phase = PaymentPhase.securingPayment});

  @override
  List<Object?> get props => [order, phase];
}

class PaymentSuccess extends TicketsState {
  final events.Order order;

  const PaymentSuccess(this.order);

  @override
  List<Object?> get props => [order];
}

class PaymentFailed extends TicketsState {
  final String message;
  final events.Order? order;

  /// Payment succeeded in Stripe but order is still `processing`/`pending` (webhook delay).
  final bool awaitingConfirmation;

  const PaymentFailed(
    this.message, {
    this.order,
    this.awaitingConfirmation = false,
  });

  @override
  List<Object?> get props => [message, order, awaitingConfirmation];
}

class OrderError extends TicketsState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
