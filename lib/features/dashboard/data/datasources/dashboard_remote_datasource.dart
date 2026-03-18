import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';

abstract class DashboardRemoteDataSource {
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId);
  Future<DashboardAnalytics?> getAnalytics(String businessId);
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status});
  Future<List<DashboardJob>> getJobs(String businessId);
  Future<RatingOverview?> getReviewsOverview(String businessId);
  Future<List<BusinessReview>> getReviews(String businessId);
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status});
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId);
  Future<List<BoostPlan>> getBoostPlans();
  Future<DashboardDeal> createDeal(String businessId, Map<String, dynamic> data);
  Future<DashboardJob> createJob(String businessId, Map<String, dynamic> data);
  Future<void> replyToReview(String reviewId, String replyText);
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data);
  Future<void> updateBusinessHours(String businessId, Map<String, dynamic> hours);
  Future<Map<String, String?>?> getBusinessHours(String businessId);
  Future<String> createBusiness(String ownerId, Map<String, dynamic> data);
  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId);
  Future<void> uploadLegalDocument(String businessId, String documentType, String fileUrl, {String? fileName});
  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId);
}
