import '../../../domain/repositories/search_repository.dart';
import '../../models/event_model.dart';
import '../../models/business_model.dart';
import '../../models/job_model.dart';
import '../mock_data/mock_home_data.dart';

class MockSearchData {
  static SearchResults getMockSearchResults(String query, SearchCategory category) {
    final allEvents = MockHomeData.getMockEvents('Washington, D.C.');
    final allBusinesses = MockHomeData.getMockBusinesses('Washington, D.C.');
    final allJobs = MockHomeData.getMockJobs('Washington, D.C.');

    // Filter based on query and category
    List<EventModel> events = [];
    List<BusinessModel> businesses = [];
    List<JobModel> jobs = [];

    final lowerQuery = query.toLowerCase();

    if (category == SearchCategory.all || category == SearchCategory.events) {
      events = allEvents.where((event) =>
        event.title.toLowerCase().contains(lowerQuery) ||
        (event.description?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
    }

    if (category == SearchCategory.all || category == SearchCategory.business) {
      businesses = allBusinesses.where((business) =>
        business.name.toLowerCase().contains(lowerQuery) ||
        business.category.toLowerCase().contains(lowerQuery)
      ).toList();
    }

    if (category == SearchCategory.all || category == SearchCategory.jobs) {
      jobs = allJobs.where((job) =>
        job.title.toLowerCase().contains(lowerQuery) ||
        job.companyName.toLowerCase().contains(lowerQuery) ||
        (job.description?.toLowerCase().contains(lowerQuery) ?? false)
      ).toList();
    }

    return SearchResults(
      events: events,
      businesses: businesses,
      jobs: jobs,
    );
  }

  static List<String> getMockTrendingSearches() {
    return [
      'New Year Party 2026',
      'Teddy Afro Concert',
      'Ethiopian Food Festival',
      'Homecare Jobs Seattle',
    ];
  }
}
