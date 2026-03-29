import '../../domain/entities/listing_category.dart';

abstract class CategoriesRemoteDataSource {
  Future<List<ListingCategory>> getActiveListingCategories();
}
