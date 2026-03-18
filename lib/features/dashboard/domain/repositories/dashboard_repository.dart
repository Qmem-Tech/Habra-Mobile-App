import '../../../home/domain/entities/business_presence.dart';
import '../entities/applicant_detail.dart';
import '../entities/boost_plan.dart';
import '../entities/business_review.dart';
import '../entities/dashboard_analytics.dart';
import '../entities/dashboard_deal.dart';
import '../entities/dashboard_job.dart';
import '../entities/job_applicant.dart';

/// Repository for business owner dashboard data.
abstract class DashboardRepository {
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

/// Status of legal documents for a business.
class LegalDocumentsStatus {
  final int uploadedCount;
  final int approvedCount;
  final bool hasRejected;

  const LegalDocumentsStatus({
    required this.uploadedCount,
    required this.approvedCount,
    this.hasRejected = false,
  });

  bool get hasRequiredUploaded => uploadedCount >= 2;
  bool get isFullyApproved => approvedCount >= 2;
}

/// Rating overview for reviews tab.
class RatingOverview {
  final double averageRating;
  final int totalReviews;
  final Map<int, int> distribution;

  const RatingOverview({
    required this.averageRating,
    required this.totalReviews,
    required this.distribution,
  });
}
