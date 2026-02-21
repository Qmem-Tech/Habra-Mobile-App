import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/saved_item.dart';
import '../repositories/saved_items_repository.dart';

class SaveItemUseCase {
  final SavedItemsRepository repository;

  SaveItemUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required SavedItemType itemType,
    required String referenceId,
  }) {
    return repository.saveItem(itemType: itemType, referenceId: referenceId);
  }
}
