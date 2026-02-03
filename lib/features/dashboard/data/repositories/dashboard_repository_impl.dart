import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final DashboardRemoteDataSource _remote;

  @override
  Future<DashboardAnalytics?> getAnalytics(String businessId) =>
      _remote.getAnalytics(businessId);

  @override
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status}) =>
      _remote.getDeals(businessId, status: status);

  @override
  Future<List<DashboardJob>> getJobs(String businessId) =>
      _remote.getJobs(businessId);

  @override
  Future<RatingOverview?> getReviewsOverview(String businessId) =>
      _remote.getReviewsOverview(businessId);

  @override
  Future<List<BusinessReview>> getReviews(String businessId) =>
      _remote.getReviews(businessId);

  @override
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status}) =>
      _remote.getApplicants(jobId, status: status);

  @override
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId) =>
      _remote.getApplicantDetail(applicantId, jobId);

  @override
  Future<List<BoostPlan>> getBoostPlans() => _remote.getBoostPlans();
}
