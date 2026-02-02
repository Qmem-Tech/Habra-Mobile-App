import '../../domain/repositories/search_repository.dart';
import 'mock_data/mock_search_data.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location,
  );
  Future<List<String>> getTrendingSearches();
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  // TODO: Replace with Firebase/API calls
  // Currently using mock data for UI/UX testing

  @override
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return MockSearchData.getMockSearchResults(query, category);
  }

  @override
  Future<List<String>> getTrendingSearches() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return MockSearchData.getMockTrendingSearches();
  }
}
