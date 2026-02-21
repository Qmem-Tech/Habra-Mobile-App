import '../../domain/entities/saved_item.dart';

class SavedItemModel extends SavedItem {
  const SavedItemModel({
    required super.id,
    required super.userId,
    required super.itemType,
    required super.referenceId,
    required super.savedAt,
    super.title,
    super.subtitle,
    super.imageUrl,
  });
}
