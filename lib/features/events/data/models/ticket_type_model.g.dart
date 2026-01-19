// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket_type_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TicketTypeModel _$TicketTypeModelFromJson(Map<String, dynamic> json) =>
    TicketTypeModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      status: $enumDecode(_$TicketStatusEnumMap, json['status']),
      availableQuantity: (json['availableQuantity'] as num?)?.toInt(),
      icon: json['icon'] as String?,
    );

Map<String, dynamic> _$TicketTypeModelToJson(TicketTypeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'price': instance.price,
      'status': _$TicketStatusEnumMap[instance.status]!,
      'availableQuantity': instance.availableQuantity,
      'icon': instance.icon,
    };

const _$TicketStatusEnumMap = {
  TicketStatus.available: 'available',
  TicketStatus.lowStock: 'lowStock',
  TicketStatus.soldOut: 'soldOut',
};
