import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/saved_items_repository.dart';

class RemoveSavedItemUseCase {
  final SavedItemsRepository repository;

  RemoveSavedItemUseCase(this.repository);

  Future<Either<Failure, void>> call(String savedItemId) {
    return repository.removeSavedItem(savedItemId);
  }
}
