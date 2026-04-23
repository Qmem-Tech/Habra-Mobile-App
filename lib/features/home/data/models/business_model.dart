import '../../domain/entities/business.dart';

class BusinessModel extends Business {
  const BusinessModel({
    required super.id,
    required super.name,
    required super.category,
    required super.imageUrl,
    required super.rating,
    required super.reviewCount,
    required super.distance,
    required super.priceRange,
    super.status,
    super.isVerified,
    super.coverImageUrl,
    super.logoUrl,
    super.phoneNumber,
    super.latitude,
    super.longitude,
  });

  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      distance: (json['distance'] as num).toDouble(),
      priceRange: json['priceRange'] as String,
      status: json['status'] as String?,
      isVerified: json['isVerified'] as bool? ?? false,
      coverImageUrl: json['coverImageUrl'] as String?,
      logoUrl: json['logoUrl'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'distance': distance,
      'priceRange': priceRange,
      'status': status,
      'isVerified': isVerified,
      'coverImageUrl': coverImageUrl,
      'logoUrl': logoUrl,
      'phoneNumber': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
