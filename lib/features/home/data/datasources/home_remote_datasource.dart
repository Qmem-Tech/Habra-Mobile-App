import '../../domain/home_feed_location.dart';
import '../models/event_model.dart';
import '../models/deal_model.dart';
import '../models/business_model.dart';
import '../models/job_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<EventModel>> getHappeningThisWeek(HomeFeedLocation location);
  Future<List<DealModel>> getHotDealsNearYou(HomeFeedLocation location);
  Future<List<BusinessModel>> getPopularBusinesses(HomeFeedLocation location);
  Future<List<JobModel>> getLatestJobs(HomeFeedLocation location);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  @override
  Future<List<EventModel>> getHappeningThisWeek(HomeFeedLocation location) async {
    return [];
  }

  @override
  Future<List<DealModel>> getHotDealsNearYou(HomeFeedLocation location) async {
    return [];
  }

  @override
  Future<List<BusinessModel>> getPopularBusinesses(HomeFeedLocation location) async {
    return [];
  }

  @override
  Future<List<JobModel>> getLatestJobs(HomeFeedLocation location) async {
    return [];
  }
}
