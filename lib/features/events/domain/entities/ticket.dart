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

  /// True when this row represents the whole order (no per-ticket rows yet in DB).
  final bool isSyntheticOrderRow;

  /// Parent event order id (`orders.id`) — used for retry payment / cancel unpaid order.
  final String orderId;

  const Ticket({
    required this.id,
    required this.ticketId,
    required this.event,
    required this.ticketTypeName,
    required this.price,
    required this.purchaseDate,
    required this.orderId,
    this.isVerified = false,
    this.qrCode,
    this.orderPaymentStatus = OrderStatus.completed,
    this.isSyntheticOrderRow = false,
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
        isSyntheticOrderRow,
        orderId,
      ];
}
