import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/job.dart';
import '../../domain/home_feed_location.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<Event>>> getHappeningThisWeek(HomeFeedLocation location) async {
    try {
      final events = await remoteDataSource.getHappeningThisWeek(location);
      return Right(events);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Deal>>> getHotDealsNearYou(HomeFeedLocation location) async {
    try {
      final deals = await remoteDataSource.getHotDealsNearYou(location);
      return Right(deals);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Business>>> getPopularBusinesses(HomeFeedLocation location) async {
    try {
      final businesses = await remoteDataSource.getPopularBusinesses(location);
      return Right(businesses);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Job>>> getLatestJobs(HomeFeedLocation location) async {
    try {
      final jobs = await remoteDataSource.getLatestJobs(location);
      return Right(jobs);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
