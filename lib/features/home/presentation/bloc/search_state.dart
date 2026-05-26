import 'package:equatable/equatable.dart';
import '../../domain/repositories/search_repository.dart';

abstract class SearchState extends Equatable {
  final List<String> recentSearches;
  final List<String> trendingSearches;
  final SearchCategory selectedCategory;

  const SearchState({
    this.recentSearches = const [],
    this.trendingSearches = const [],
    this.selectedCategory = SearchCategory.all,
  });

  @override
  List<Object?> get props => [recentSearches, trendingSearches, selectedCategory];
}

class SearchInitial extends SearchState {
  const SearchInitial({
    super.recentSearches,
    super.trendingSearches,
    super.selectedCategory,
  });
}

class SearchLoading extends SearchState {
  const SearchLoading({
    required super.recentSearches,
    required super.trendingSearches,
    super.selectedCategory,
  });
}

class SearchResultsLoaded extends SearchState {
  final SearchResults results;
  final String query;
  final SearchCategory category;

  const SearchResultsLoaded({
    required this.results,
    required this.query,
    required this.category,
    required super.recentSearches,
    required super.trendingSearches,
    super.selectedCategory,
  });

  @override
  List<Object?> get props => [
        results,
        query,
        category,
        ...super.props,
      ];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(
    this.message, {
    required super.recentSearches,
    required super.trendingSearches,
    super.selectedCategory,
  });

  @override
  List<Object?> get props => [message, ...super.props];
}
