import '../../domain/repositories/search_repository.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location,
  );
  Future<List<String>> getTrendingSearches();
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  @override
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location,
  ) async {
    return const SearchResults(
      events: [],
      businesses: [],
      jobs: [],
    );
  }

  @override
  Future<List<String>> getTrendingSearches() async {
    return [];
  }
}
