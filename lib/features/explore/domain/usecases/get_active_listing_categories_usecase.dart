import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/listing_category.dart';
import '../repositories/categories_repository.dart';

class GetActiveListingCategoriesUseCase {
  final CategoriesRepository repository;

  GetActiveListingCategoriesUseCase(this.repository);

  Future<Either<Failure, List<ListingCategory>>> call() {
    return repository.getActiveListingCategories();
  }
}
