import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../entities/business.dart';
import '../entities/job.dart';

enum SearchCategory { all, events, business, jobs }

abstract class SearchRepository {
  Future<Either<Failure, List<String>>> getRecentSearches();
  Future<Either<Failure, void>> saveRecentSearch(String query);
  Future<Either<Failure, void>> clearRecentSearches();
  Future<Either<Failure, List<String>>> getTrendingSearches();
  Future<Either<Failure, SearchResults>> search(
    String query,
    SearchCategory category,
    String location,
  );
}

class SearchResults {
  final List<Event> events;
  final List<Business> businesses;
  final List<Job> jobs;

  const SearchResults({
    required this.events,
    required this.businesses,
    required this.jobs,
  });

  int get totalCount => events.length + businesses.length + jobs.length;
}
