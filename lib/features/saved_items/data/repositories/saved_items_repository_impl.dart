import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/saved_item.dart';
import '../../domain/repositories/saved_items_repository.dart';
import '../datasources/saved_items_remote_datasource.dart';

class SavedItemsRepositoryImpl implements SavedItemsRepository {
  final SavedItemsRemoteDataSource remoteDataSource;

  SavedItemsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<SavedItem>>> getSavedItems({
    SavedItemType? filterType,
  }) async {
    try {
      final String? typeStr = filterType != null
          ? (filterType == SavedItemType.deal ? 'deal' : 'event')
          : null;
      final list = await remoteDataSource.getSavedItems(filterType: typeStr);
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveItem({
    required SavedItemType itemType,
    required String referenceId,
  }) async {
    try {
      await remoteDataSource.saveItem(
        itemType: itemType == SavedItemType.deal ? 'deal' : 'event',
        referenceId: referenceId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeSavedItem(String savedItemId) async {
    try {
      await remoteDataSource.removeSavedItem(savedItemId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
