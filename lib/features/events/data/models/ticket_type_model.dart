import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ticket_type.dart';

part 'ticket_type_model.g.dart';

@JsonSerializable()
class TicketTypeModel extends TicketType {
  const TicketTypeModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.status,
    super.availableQuantity,
    super.icon,
  });

  factory TicketTypeModel.fromJson(Map<String, dynamic> json) =>
      _$TicketTypeModelFromJson(json);

  Map<String, dynamic> toJson() => _$TicketTypeModelToJson(this);

  factory TicketTypeModel.fromEntity(TicketType entity) {
    return TicketTypeModel(
      id: entity.id,
      name: entity.name,
      description: entity.description,
      price: entity.price,
      status: entity.status,
      availableQuantity: entity.availableQuantity,
      icon: entity.icon,
    );
  }
}
