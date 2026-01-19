import 'package:equatable/equatable.dart';
import 'event_detail.dart';

class Ticket extends Equatable {
  final String id;
  final String ticketId;
  final EventDetail event;
  final String ticketTypeName;
  final double price;
  final DateTime purchaseDate;
  final bool isVerified;
  final String? qrCode;

  const Ticket({
    required this.id,
    required this.ticketId,
    required this.event,
    required this.ticketTypeName,
    required this.price,
    required this.purchaseDate,
    this.isVerified = false,
    this.qrCode,
  });

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
      ];
}
