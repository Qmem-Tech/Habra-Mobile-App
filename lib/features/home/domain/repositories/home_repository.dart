import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../entities/deal.dart';
import '../entities/business.dart';
import '../entities/job.dart';
import '../home_feed_location.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Event>>> getHappeningThisWeek(HomeFeedLocation location);
  Future<Either<Failure, List<Deal>>> getHotDealsNearYou(HomeFeedLocation location);
  Future<Either<Failure, List<Business>>> getPopularBusinesses(HomeFeedLocation location);
  Future<Either<Failure, List<Job>>> getLatestJobs(HomeFeedLocation location);
}
