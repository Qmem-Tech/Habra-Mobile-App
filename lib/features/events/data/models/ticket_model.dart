import '../../domain/entities/ticket.dart';
import 'event_detail_model.dart';

class TicketModel extends Ticket {
  const TicketModel({
    required super.id,
    required super.ticketId,
    required super.event,
    required super.ticketTypeName,
    required super.price,
    required super.purchaseDate,
    super.isVerified,
    super.qrCode,
    super.orderPaymentStatus,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      event: EventDetailModel.fromJson(json['event'] as Map<String, dynamic>),
      ticketTypeName: json['ticketTypeName'] as String,
      price: (json['price'] as num).toDouble(),
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      isVerified: json['isVerified'] as bool? ?? false,
      qrCode: json['qrCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'event': (event is EventDetailModel
          ? event as EventDetailModel
          : EventDetailModel.fromEntity(event)).toJson(),
      'ticketTypeName': ticketTypeName,
      'price': price,
      'purchaseDate': purchaseDate.toIso8601String(),
      'isVerified': isVerified,
      'qrCode': qrCode,
    };
  }

  factory TicketModel.fromEntity(Ticket entity) {
    final eventModel = entity.event is EventDetailModel
        ? entity.event as EventDetailModel
        : EventDetailModel.fromEntity(entity.event);

    return TicketModel(
      id: entity.id,
      ticketId: entity.ticketId,
      event: eventModel,
      ticketTypeName: entity.ticketTypeName,
      price: entity.price,
      purchaseDate: entity.purchaseDate,
      isVerified: entity.isVerified,
      qrCode: entity.qrCode,
      orderPaymentStatus: entity.orderPaymentStatus,
    );
  }
}
