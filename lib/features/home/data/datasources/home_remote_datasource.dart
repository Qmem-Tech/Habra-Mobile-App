import '../models/event_model.dart';
import '../models/deal_model.dart';
import '../models/business_model.dart';
import '../models/job_model.dart';
import 'mock_data/mock_home_data.dart';

abstract class HomeRemoteDataSource {
  Future<List<EventModel>> getHappeningThisWeek(String location);
  Future<List<DealModel>> getHotDealsNearYou(String location);
  Future<List<BusinessModel>> getPopularBusinesses(String location);
  Future<List<JobModel>> getLatestJobs(String location);
}

class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  // TODO: Replace with Supabase when home_supabase_datasource is wired in DI.
  // Currently using mock data for UI/UX testing.

  @override
  Future<List<EventModel>> getHappeningThisWeek(String location) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return MockHomeData.getMockEvents(location);
  }

  @override
  Future<List<DealModel>> getHotDealsNearYou(String location) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockHomeData.getMockDeals(location);
  }

  @override
  Future<List<BusinessModel>> getPopularBusinesses(String location) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockHomeData.getMockBusinesses(location);
  }

  @override
  Future<List<JobModel>> getLatestJobs(String location) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return MockHomeData.getMockJobs(location);
  }
}
