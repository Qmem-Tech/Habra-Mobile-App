import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/search_repository.dart';

class SearchUseCase {
  final SearchRepository repository;

  SearchUseCase(this.repository);

  Future<Either<Failure, SearchResults>> call(
    String query,
    SearchCategory category,
    String location,
  ) {
    return repository.search(query, category, location);
  }
}
