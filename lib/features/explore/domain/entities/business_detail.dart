import 'package:equatable/equatable.dart';
import 'business_category.dart';
import 'business_list_item.dart';
import 'review.dart';
import 'deal.dart';

class BusinessDetail extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final List<BusinessCategory> categories;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final double latitude;
  final double longitude;
  final String? phoneNumber;
  final String? website;
  final double rating;
  final int reviewCount;
  final String? priceRange;
  final bool isVerified;
  final bool isOpen;
  final String? closingTime;
  final String? openingTime;
  final List<String> hours; // e.g., ["Mon-Fri: 9 AM - 6 PM"]
  final List<Deal> currentDeals;
  final List<Review> reviews;
  final List<BusinessListItem> similarBusinesses;
  final List<String> photos;

  const BusinessDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.categories,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.latitude,
    required this.longitude,
    this.phoneNumber,
    this.website,
    required this.rating,
    required this.reviewCount,
    this.priceRange,
    this.isVerified = false,
    required this.isOpen,
    this.closingTime,
    this.openingTime,
    this.hours = const [],
    this.currentDeals = const [],
    this.reviews = const [],
    this.similarBusinesses = const [],
    this.photos = const [],
  });

  String get fullAddress => '$address, $city, $state $zipCode';

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrls,
        categories,
        address,
        city,
        state,
        zipCode,
        latitude,
        longitude,
        phoneNumber,
        website,
        rating,
        reviewCount,
        priceRange,
        isVerified,
        isOpen,
        closingTime,
        openingTime,
        hours,
        currentDeals,
        reviews,
        similarBusinesses,
        photos,
      ];
}
