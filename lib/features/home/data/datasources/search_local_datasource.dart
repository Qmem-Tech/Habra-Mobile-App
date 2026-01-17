import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';

abstract class SearchLocalDataSource {
  Future<List<String>> getRecentSearches();
  Future<void> saveRecentSearch(String query);
  Future<void> clearRecentSearches();
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  final LocalStorage localStorage;
  static const String _recentSearchesKey = 'recent_searches';

  SearchLocalDataSourceImpl(this.localStorage);

  @override
  Future<List<String>> getRecentSearches() async {
    final searchesJson = await localStorage.getString(_recentSearchesKey);
    if (searchesJson == null) return [];

    // Simple implementation - store as comma-separated string
    // In production, use JSON encoding
    return searchesJson.split(',').where((s) => s.isNotEmpty).toList();
  }

  @override
  Future<void> saveRecentSearch(String query) async {
    final recent = await getRecentSearches();
    if (recent.contains(query)) {
      recent.remove(query);
    }
    recent.insert(0, query);

    // Keep only last 10 searches
    final limited = recent.take(10).toList();
    await localStorage.setString(_recentSearchesKey, limited.join(','));
  }

  @override
  Future<void> clearRecentSearches() async {
    await localStorage.remove(_recentSearchesKey);
  }
}
