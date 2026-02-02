import 'package:equatable/equatable.dart';

enum OwnerActivityType {
  review,
  applicant,
  message,
  deal,
  general,
}

/// A single recent activity item on business owner home (review, applicant, etc.).
class OwnerActivityItem extends Equatable {
  final String id;
  final OwnerActivityType type;
  final String title;
  final String? subtitle;
  final String? body;
  final String? authorName;
  final DateTime createdAt;
  final String? actionLabel;
  final String? actionId;
  final String? imageUrl;

  const OwnerActivityItem({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.body,
    this.authorName,
    required this.createdAt,
    this.actionLabel,
    this.actionId,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        subtitle,
        body,
        authorName,
        createdAt,
        actionLabel,
        actionId,
        imageUrl,
      ];
}
