import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../../domain/usecases/get_businesses_usecase.dart';
import '../../domain/usecases/get_business_detail_usecase.dart';
import '../../domain/entities/business_filters.dart';
import 'businesses_state.dart';

class BusinessesCubit extends Cubit<BusinessesState> {
  final GetBusinessesUseCase getBusinessesUseCase;
  final GetBusinessDetailUseCase getBusinessDetailUseCase;

  BusinessesCubit({
    required this.getBusinessesUseCase,
    required this.getBusinessDetailUseCase,
  }) : super(BusinessesInitial());

  Future<void> loadBusinesses({
    String? location,
    BusinessFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
    UserGeoForFeed? userGeo,
  }) async {
    if (state is! BusinessesLoaded) {
      emit(BusinessesLoading());
    }

    final result = await getBusinessesUseCase(
      location: location,
      filters: filters,
      searchQuery: searchQuery,
      featuredOnly: featuredOnly,
      userGeo: userGeo,
    );

    result.fold(
      (failure) => emit(BusinessesError(failure.message)),
      (businesses) => emit(BusinessesLoaded(
        businesses: businesses,
        activeFilters: filters,
        searchQuery: searchQuery,
      )),
    );
  }

  Future<void> loadBusinessDetail(String businessId) async {
    emit(BusinessDetailLoading());

    final result = await getBusinessDetailUseCase(businessId);

    result.fold(
      (failure) => emit(BusinessDetailError(failure.message)),
      (business) => emit(BusinessDetailLoaded(business)),
    );
  }
}
