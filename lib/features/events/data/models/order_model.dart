import '../../domain/entities/order.dart' as events;
import '../../domain/entities/event_detail.dart';
import '../../domain/entities/selected_ticket.dart';
import '../../domain/entities/ticket_type.dart';
import 'event_detail_model.dart';
import 'ticket_type_model.dart';

class OrderModel extends events.Order {
  const OrderModel({
    required super.id,
    required super.event,
    required super.tickets,
    required super.subtotal,
    required super.serviceFee,
    required super.total,
    required super.createdAt,
    required super.status,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String,
      event: EventDetailModel.fromJson(json['event'] as Map<String, dynamic>),
      tickets: (json['tickets'] as List<dynamic>).map((e) {
        return SelectedTicket(
          ticketType: TicketTypeModel.fromJson(e['ticketType'] as Map<String, dynamic>),
          quantity: e['quantity'] as int,
        );
      }).toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      serviceFee: (json['serviceFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: events.OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
        orElse: () => events.OrderStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'event': (event is EventDetailModel
          ? event as EventDetailModel
          : EventDetailModel.fromEntity(event)).toJson(),
      'tickets': tickets.map((t) => {
            'ticketType': (t.ticketType is TicketTypeModel
                ? (t.ticketType as TicketTypeModel).toJson()
                : TicketTypeModel.fromEntity(t.ticketType).toJson()),
            'quantity': t.quantity,
          }).toList(),
      'subtotal': subtotal,
      'serviceFee': serviceFee,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'status': status.toString().split('.').last,
    };
  }

  factory OrderModel.fromEntity(events.Order entity) {
    final eventModel = entity.event is EventDetailModel
        ? entity.event as EventDetailModel
        : EventDetailModel.fromEntity(entity.event);

    return OrderModel(
      id: entity.id,
      event: eventModel,
      tickets: entity.tickets,
      subtotal: entity.subtotal,
      serviceFee: entity.serviceFee,
      total: entity.total,
      createdAt: entity.createdAt,
      status: entity.status,
    );
  }
}
