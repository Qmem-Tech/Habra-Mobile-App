import 'package:equatable/equatable.dart';

class Business extends Equatable {
  final String id;
  final String name;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;
  final double distance; // in miles
  final String priceRange; // e.g., "$", "$$", "$$$"
  final String? status; // e.g., "Fresh spices arrived today"
  final bool isVerified;

  const Business({
    required this.id,
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
    required this.distance,
    required this.priceRange,
    this.status,
    this.isVerified = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        category,
        imageUrl,
        rating,
        reviewCount,
        distance,
        priceRange,
        status,
        isVerified,
      ];
}
