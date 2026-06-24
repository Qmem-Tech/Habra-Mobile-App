import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../entities/business_list_item.dart';
import '../entities/business_filters.dart';
import '../repositories/businesses_repository.dart';

class GetBusinessesUseCase {
  final BusinessesRepository repository;

  GetBusinessesUseCase(this.repository);

  Future<Either<Failure, List<BusinessListItem>>> call({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
    UserGeoForFeed? userGeo,
  }) async {
    return await repository.getBusinesses(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
      featuredOnly: featuredOnly,
      userGeo: userGeo,
    );
  }
}
