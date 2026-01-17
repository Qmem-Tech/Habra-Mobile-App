import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/event.dart';
import '../entities/deal.dart';
import '../entities/business.dart';
import '../entities/job.dart';

abstract class HomeRepository {
  Future<Either<Failure, List<Event>>> getHappeningThisWeek(String location);
  Future<Either<Failure, List<Deal>>> getHotDealsNearYou(String location);
  Future<Either<Failure, List<Business>>> getPopularBusinesses(String location);
  Future<Either<Failure, List<Job>>> getLatestJobs(String location);
}
