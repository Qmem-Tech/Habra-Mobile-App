import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../../domain/repositories/search_repository.dart';
import '../../domain/usecases/search_usecase.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchUseCase searchUseCase;
  final SearchRepository searchRepository;
  String _lastLocation = '';
  UserGeoForFeed? _lastUserGeo;

  SearchCubit({
    required this.searchUseCase,
    required this.searchRepository,
  }) : super(SearchInitial()) {
    _loadRecentSearches();
    _loadTrendingSearches();
  }

  Future<void> _loadRecentSearches() async {
    final result = await searchRepository.getRecentSearches();
    result.fold(
      (failure) => null,
      (searches) => emit(SearchInitial(
        recentSearches: searches,
        trendingSearches: state.trendingSearches,
        selectedCategory: state.selectedCategory,
      )),
    );
  }

  Future<void> _loadTrendingSearches() async {
    final result = await searchRepository.getTrendingSearches();
    result.fold(
      (failure) => null,
      (trending) {
        final currentState = state;
        if (currentState is SearchInitial) {
          emit(SearchInitial(
            recentSearches: currentState.recentSearches,
            trendingSearches: trending,
            selectedCategory: currentState.selectedCategory,
          ));
        } else {
          emit(SearchInitial(
            trendingSearches: trending,
            selectedCategory: currentState.selectedCategory,
          ));
        }
      },
    );
  }

  Future<void> search(
    String query,
    SearchCategory category,
    String location, {
    UserGeoForFeed? userGeo,
  }) async {
    _lastLocation = location;
    _lastUserGeo = userGeo;
    if (query.isEmpty) {
      emit(SearchInitial(
        recentSearches: state.recentSearches,
        trendingSearches: state.trendingSearches,
        selectedCategory: category,
      ));
      return;
    }

    emit(SearchLoading(
      recentSearches: state.recentSearches,
      trendingSearches: state.trendingSearches,
      selectedCategory: category,
    ));

    final result = await searchUseCase(
      query,
      category,
      location,
      userGeo: userGeo,
    );
    result.fold(
      (failure) => emit(SearchError(
        failure.message,
        recentSearches: state.recentSearches,
        trendingSearches: state.trendingSearches,
        selectedCategory: category,
      )),
      (results) => emit(SearchResultsLoaded(
        results: results,
        query: query,
        category: category,
        recentSearches: state.recentSearches,
        trendingSearches: state.trendingSearches,
        selectedCategory: category,
      )),
    );
  }

  Future<void> clearRecentSearches() async {
    final result = await searchRepository.clearRecentSearches();
    result.fold(
      (failure) => null,
      (_) => emit(SearchInitial(
        recentSearches: [],
        trendingSearches: state.trendingSearches,
        selectedCategory: state.selectedCategory,
      )),
    );
  }

  void setCategory(SearchCategory category) {
    final currentState = state;
    if (currentState is SearchResultsLoaded) {
      // If there's a query, re-search with new category
      if (currentState.query.isNotEmpty) {
        search(currentState.query, category, _lastLocation, userGeo: _lastUserGeo);
      } else {
        emit(SearchInitial(
          recentSearches: currentState.recentSearches,
          trendingSearches: currentState.trendingSearches,
          selectedCategory: category,
        ));
      }
    } else {
      emit(SearchInitial(
        recentSearches: currentState.recentSearches,
        trendingSearches: currentState.trendingSearches,
        selectedCategory: category,
      ));
    }
  }
}
