import 'package:equatable/equatable.dart';
import 'event_detail.dart';
import 'order.dart';

class Ticket extends Equatable {
  final String id;
  final String ticketId;
  final EventDetail event;
  final String ticketTypeName;
  final double price;
  final DateTime purchaseDate;
  final bool isVerified;
  final String? qrCode;

  /// Parent order payment lifecycle (`orders.status`).
  final OrderStatus orderPaymentStatus;

  const Ticket({
    required this.id,
    required this.ticketId,
    required this.event,
    required this.ticketTypeName,
    required this.price,
    required this.purchaseDate,
    this.isVerified = false,
    this.qrCode,
    this.orderPaymentStatus = OrderStatus.completed,
  });

  bool get isPaymentConfirmed => orderPaymentStatus == OrderStatus.completed;

  @override
  List<Object?> get props => [
        id,
        ticketId,
        event,
        ticketTypeName,
        price,
        purchaseDate,
        isVerified,
        qrCode,
        orderPaymentStatus,
      ];
}
