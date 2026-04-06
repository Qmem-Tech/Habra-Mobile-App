import 'package:equatable/equatable.dart';

enum SavedItemType { event, deal, job }

class SavedItem extends Equatable {
  final String id;
  final String userId;
  final SavedItemType itemType;
  final String referenceId;
  final DateTime savedAt;
  final String? title;
  final String? subtitle;
  final String? imageUrl;

  const SavedItem({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.referenceId,
    required this.savedAt,
    this.title,
    this.subtitle,
    this.imageUrl,
  });

  @override
  List<Object?> get props => [id, userId, itemType, referenceId, savedAt];
}
