import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/saved_item.dart';

abstract class SavedItemsRepository {
  Future<Either<Failure, List<SavedItem>>> getSavedItems({
    SavedItemType? filterType,
  });
  Future<Either<Failure, void>> saveItem({
    required SavedItemType itemType,
    required String referenceId,
    String? title,
    String? subtitle,
    String? imageUrl,
  });
  Future<Either<Failure, void>> removeSavedItem(String savedItemId);
}
