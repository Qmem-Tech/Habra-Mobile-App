import 'package:equatable/equatable.dart';

/// Customer review on business, with optional owner response.
class BusinessReview extends Equatable {
  final String id;
  final String authorName;
  final String? authorImageUrl;
  final int rating;
  final String text;
  final String timeAgo;
  final String? responseText;
  final String? responseTimeAgo;

  const BusinessReview({
    required this.id,
    required this.authorName,
    this.authorImageUrl,
    required this.rating,
    required this.text,
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
        timeAgo,
        responseText,
        responseTimeAgo,
      ];
}
