import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/listing_category.dart';
import '../../domain/repositories/categories_repository.dart';
import '../datasources/categories_remote_datasource.dart';

class CategoriesRepositoryImpl implements CategoriesRepository {
  CategoriesRepositoryImpl({required CategoriesRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final CategoriesRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<ListingCategory>>> getActiveListingCategories() async {
    try {
      final list = await _remote.getActiveListingCategories();
      return Right(list);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
