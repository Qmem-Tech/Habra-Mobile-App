import 'package:equatable/equatable.dart';

enum TicketStatus {
  available,
  lowStock,
  soldOut,
}

class TicketType extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price;
  final TicketStatus status;
  final int? availableQuantity;
  final String? icon;

  const TicketType({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.status,
    this.availableQuantity,
    this.icon,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        status,
        availableQuantity,
        icon,
      ];
}
