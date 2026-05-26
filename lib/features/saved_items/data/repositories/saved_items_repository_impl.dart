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
      final String? typeStr = switch (filterType) {
        null => null,
        SavedItemType.deal => 'deal',
        SavedItemType.event => 'event',
        SavedItemType.job => 'job',
        SavedItemType.business => 'business',
      };
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
    String? title,
    String? subtitle,
    String? imageUrl,
  }) async {
    try {
      final typeStr = switch (itemType) {
        SavedItemType.deal => 'deal',
        SavedItemType.event => 'event',
        SavedItemType.job => 'job',
        SavedItemType.business => 'business',
      };
      await remoteDataSource.saveItem(
        itemType: typeStr,
        referenceId: referenceId,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
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
