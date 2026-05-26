import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/listing_category.dart';

abstract class CategoriesRepository {
  Future<Either<Failure, List<ListingCategory>>> getActiveListingCategories();
}
