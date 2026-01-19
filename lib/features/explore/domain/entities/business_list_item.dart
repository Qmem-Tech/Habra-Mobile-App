import 'package:equatable/equatable.dart';
import 'business_category.dart';

class BusinessListItem extends Equatable {
  final String id;
  final String name;
  final String imageUrl;
  final List<BusinessCategory> categories;
  final String address;
  final String city;
  final String state;
  final double? distance; // in miles
  final double rating;
  final int reviewCount;
  final String? priceRange; // $, $$, $$$, $$$$
  final bool isVerified;
  final bool isOpen;
  final String? closingTime;
  final String? openingTime;
  final bool isFeatured;

  const BusinessListItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.categories,
    required this.address,
    required this.city,
    required this.state,
    this.distance,
    required this.rating,
    required this.reviewCount,
    this.priceRange,
    this.isVerified = false,
    required this.isOpen,
    this.closingTime,
    this.openingTime,
    this.isFeatured = false,
  });

  String get fullAddress => '$address, $city, $state';

  String get displayDistance {
    if (distance == null) return '';
    if (distance! < 1) {
      return '${(distance! * 10).round() / 10} mi';
    }
    return '${distance!.toStringAsFixed(1)} mi';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        imageUrl,
        categories,
        address,
        city,
        state,
        distance,
        rating,
        reviewCount,
        priceRange,
        isVerified,
        isOpen,
        closingTime,
        openingTime,
        isFeatured,
      ];
}
