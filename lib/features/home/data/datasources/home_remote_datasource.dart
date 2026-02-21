import '../models/event_model.dart';
import '../models/deal_model.dart';
import '../models/business_model.dart';
import '../models/job_model.dart';

abstract class HomeRemoteDataSource {
  Future<List<EventModel>> getHappeningThisWeek(String location);
  Future<List<DealModel>> getHotDealsNearYou(String location);
  Future<List<BusinessModel>> getPopularBusinesses(String location);
  Future<List<JobModel>> getLatestJobs(String location);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  @override
  Future<List<EventModel>> getHappeningThisWeek(String location) async {
    return [];
  }

  @override
  Future<List<DealModel>> getHotDealsNearYou(String location) async {
    return [];
  }

  @override
  Future<List<BusinessModel>> getPopularBusinesses(String location) async {
    return [];
  }

  @override
  Future<List<JobModel>> getLatestJobs(String location) async {
    return [];
  }
}
