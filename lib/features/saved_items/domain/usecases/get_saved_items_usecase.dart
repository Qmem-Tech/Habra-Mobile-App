import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/saved_item.dart';
import '../repositories/saved_items_repository.dart';

class GetSavedItemsUseCase {
  final SavedItemsRepository repository;

  GetSavedItemsUseCase(this.repository);

  Future<Either<Failure, List<SavedItem>>> call({SavedItemType? filterType}) {
    return repository.getSavedItems(filterType: filterType);
  }
}
