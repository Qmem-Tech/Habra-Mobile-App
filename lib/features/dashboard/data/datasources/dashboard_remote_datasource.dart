import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';

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
    return null;
  }

  @override
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status}) async {
    return [];
  }

  @override
  Future<List<DashboardJob>> getJobs(String businessId) async {
    return [];
  }

  @override
  Future<RatingOverview?> getReviewsOverview(String businessId) async {
    return null;
  }

  @override
  Future<List<BusinessReview>> getReviews(String businessId) async {
    return [];
  }

  @override
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status}) async {
    return [];
  }

  @override
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId) async {
    return null;
  }

  @override
  Future<List<BoostPlan>> getBoostPlans() async {
    return [];
  }
}
