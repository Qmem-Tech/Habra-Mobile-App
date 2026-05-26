import 'package:equatable/equatable.dart';
import 'ticket_type.dart';

class SelectedTicket extends Equatable {
  final TicketType ticketType;
  final int quantity;

  const SelectedTicket({
    required this.ticketType,
    this.quantity = 1,
  });

  double get totalPrice => ticketType.price * quantity;

  SelectedTicket copyWith({
    TicketType? ticketType,
    int? quantity,
  }) {
    return SelectedTicket(
      ticketType: ticketType ?? this.ticketType,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [ticketType, quantity];
}
