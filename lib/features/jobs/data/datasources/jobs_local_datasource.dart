import '../../../../core/storage/local_storage.dart';
import '../../../../core/constants/storage_keys.dart';

abstract class JobsLocalDataSource {
  Future<List<String>> getBookmarkedJobIds();
  Future<void> saveBookmarkedJobIds(List<String> jobIds);
  Future<void> toggleBookmark(String jobId, bool isBookmarked);
}

class JobsLocalDataSourceImpl implements JobsLocalDataSource {
  final LocalStorage localStorage;

  JobsLocalDataSourceImpl(this.localStorage);

  @override
  Future<List<String>> getBookmarkedJobIds() async {
    final bookmarks = await localStorage.getStringList(
      StorageKeys.bookmarkedJobs,
    );
    return bookmarks ?? [];
  }

  @override
  Future<void> saveBookmarkedJobIds(List<String> jobIds) async {
    await localStorage.setStringList(
      StorageKeys.bookmarkedJobs,
      jobIds,
    );
  }

  @override
  Future<void> toggleBookmark(String jobId, bool isBookmarked) async {
    final bookmarks = await getBookmarkedJobIds();
    if (isBookmarked) {
      if (!bookmarks.contains(jobId)) {
        bookmarks.add(jobId);
      }
    } else {
      bookmarks.remove(jobId);
    }
    await saveBookmarkedJobIds(bookmarks);
  }
}
