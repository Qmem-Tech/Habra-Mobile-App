import 'package:equatable/equatable.dart';

/// User's own review with business info for "My Reviews" list.
class MyReview extends Equatable {
  final String id;
  final String businessId;
  final String businessName;
  final String? businessImageUrl;
  final int rating;
  final String comment;
  final DateTime createdAt;

  const MyReview({
    required this.id,
    required this.businessId,
    required this.businessName,
    this.businessImageUrl,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, businessId, businessName, rating, comment, createdAt];
}
