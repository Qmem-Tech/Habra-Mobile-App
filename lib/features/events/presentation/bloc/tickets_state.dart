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

  const TicketsLoaded({
    required this.tickets,
    this.isUpcoming = true,
  });

  @override
  List<Object?> get props => [tickets, isUpcoming];
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

class OrderLoading extends TicketsState {}

class OrderCreated extends TicketsState {
  final events.Order order;

  const OrderCreated(this.order);

  @override
  List<Object?> get props => [order];
}

class PaymentProcessing extends TicketsState {
  final events.Order order;

  const PaymentProcessing(this.order);

  @override
  List<Object?> get props => [order];
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

  const PaymentFailed(this.message, {this.order});

  @override
  List<Object?> get props => [message, order];
}

class OrderError extends TicketsState {
  final String message;

  const OrderError(this.message);

  @override
  List<Object?> get props => [message];
}
