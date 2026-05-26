import 'package:equatable/equatable.dart';

class Event extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String imageUrl;
  final DateTime dateTime;
  final String location;
  final String? venue;
  final double? price;
  final String? organizer;

  const Event({
    required this.id,
    required this.title,
    this.description,
    required this.imageUrl,
    required this.dateTime,
    required this.location,
    this.venue,
    this.price,
    this.organizer,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        imageUrl,
        dateTime,
        location,
        venue,
        price,
        organizer,
      ];
}
