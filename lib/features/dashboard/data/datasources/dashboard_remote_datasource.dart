import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'mock_data/mock_dashboard_data.dart';

/// Remote (mock) data source for dashboard. Replace with real API when backend is ready.
abstract class DashboardRemoteDataSource {
  Future<DashboardAnalytics?> getAnalytics(String businessId);
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status});
  Future<List<DashboardJob>> getJobs(String businessId);
  Future<RatingOverview?> getReviewsOverview(String businessId);
  Future<List<BusinessReview>> getReviews(String businessId);
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status});
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId);
  Future<List<BoostPlan>> getBoostPlans();
}

class DashboardRemoteDataSourceImpl implements DashboardRemoteDataSource {
  @override
  Future<DashboardAnalytics?> getAnalytics(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return MockDashboardData.getMockAnalytics();
  }

  @override
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockDashboardData.getMockDeals(status: status);
  }

  @override
  Future<List<DashboardJob>> getJobs(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockDashboardData.getMockJobs();
  }

  @override
  Future<RatingOverview?> getReviewsOverview(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockDashboardData.getMockRatingOverview();
  }

  @override
  Future<List<BusinessReview>> getReviews(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockDashboardData.getMockReviews();
  }

  @override
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockDashboardData.getMockApplicants(jobId, status: status);
  }

  @override
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockDashboardData.getMockApplicantDetail(applicantId);
  }

  @override
  Future<List<BoostPlan>> getBoostPlans() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockDashboardData.getMockBoostPlans();
  }
}
