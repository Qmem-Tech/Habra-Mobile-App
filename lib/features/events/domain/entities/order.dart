import 'package:equatable/equatable.dart';
import 'event_detail.dart';
import 'selected_ticket.dart';

class Order extends Equatable {
  final String id;
  final EventDetail event;
  final List<SelectedTicket> tickets;
  final double subtotal;
  final double serviceFee;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;

  /// Individual ticket row IDs from `tickets` table (for QR / entry). Filled after payment completes.
  final List<String> issuedTicketIds;

  const Order({
    required this.id,
    required this.event,
    required this.tickets,
    required this.subtotal,
    required this.serviceFee,
    required this.total,
    required this.createdAt,
    required this.status,
    this.issuedTicketIds = const [],
  });

  int get totalTickets {
    return tickets.fold(0, (sum, ticket) => sum + ticket.quantity);
  }

  @override
  List<Object?> get props => [
        id,
        event,
        tickets,
        subtotal,
        serviceFee,
        total,
        createdAt,
        status,
        issuedTicketIds,
      ];
}

enum OrderStatus {
  pending,
  completed,
  failed,
  cancelled,
}
