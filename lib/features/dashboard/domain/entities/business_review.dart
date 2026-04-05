import 'package:equatable/equatable.dart';

/// Customer review on business, with optional owner response.
class BusinessReview extends Equatable {
  final String id;
  final String authorName;
  final String? authorImageUrl;
  final int rating;
  final String text;
  /// When the customer submitted the review (from `reviews.created_at`).
  final DateTime createdAt;
  /// Relative label at fetch time; UI may also use `formatShortTimeAgo(createdAt)`.
  final String timeAgo;
  final String? responseText;
  final String? responseTimeAgo;

  const BusinessReview({
    required this.id,
    required this.authorName,
    this.authorImageUrl,
    required this.rating,
    required this.text,
    required this.createdAt,
    required this.timeAgo,
    this.responseText,
    this.responseTimeAgo,
  });

  bool get hasResponse => responseText != null && responseText!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        authorName,
        authorImageUrl,
        rating,
        text,
        createdAt,
        timeAgo,
        responseText,
        responseTimeAgo,
      ];
}
