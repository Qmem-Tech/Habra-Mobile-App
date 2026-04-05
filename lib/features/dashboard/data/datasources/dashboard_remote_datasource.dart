import '../../../../../core/models/legal_document_upload_result.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/entities/business_legal_document.dart';
import '../../domain/entities/owner_upcoming_event.dart';
import '../../domain/repositories/dashboard_repository.dart';

abstract class DashboardRemoteDataSource {
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId);
  Future<DashboardAnalytics?> getAnalytics(String businessId);
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status});
  /// Active deals for every business owned by the signed-in user (boost flow).
  Future<List<DashboardDeal>> getActiveDealsForCurrentOwner();
  Future<List<DashboardJob>> getJobs(String businessId);
  /// Open/draft jobs for every business owned by the signed-in user (boost flow).
  Future<List<DashboardJob>> getOpenJobsForCurrentOwner();
  Future<RatingOverview?> getReviewsOverview(String businessId);
  Future<List<BusinessReview>> getReviews(String businessId);
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status});
  /// Sets every `pending` application for [jobId] to `reviewed` (owner has seen them).
  Future<void> markAllApplicantsReadForJob(String jobId);
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId);
  /// [status] must be a valid `job_application_status` enum value (e.g. `rejected`, `hired`).
  Future<void> updateJobApplicationStatus(
    String applicationId,
    String jobId,
    String status,
  );
  Future<List<BoostPlan>> getBoostPlans(String targetType);
  Future<DashboardDeal> createDeal(String businessId, Map<String, dynamic> data);
  Future<DashboardDeal> updateDeal(String dealId, Map<String, dynamic> data);
  Future<void> updateDealStatus(String dealId, DashboardDealStatus status);
  Future<DashboardJob> createJob(String businessId, Map<String, dynamic> data);
  Future<DashboardJob> updateJob(String jobId, Map<String, dynamic> data);
  Future<void> replyToReview(String reviewId, String replyText);
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data);
  Future<void> updateBusinessHours(String businessId, Map<String, dynamic> hours);
  Future<Map<String, dynamic>?> getBusinessHours(String businessId);
  Future<String> createBusiness(String ownerId, Map<String, dynamic> data);
  Future<void> replaceBusinessCategoryLinks(String businessId, List<String> categoryIds);
  /// Category UUIDs linked to this business in `business_categories`.
  Future<List<String>> listCategoryIdsForBusiness(String businessId);
  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId);
  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId);
  Future<void> uploadLegalDocument(
    String businessId,
    String documentType,
    LegalDocumentUploadResult upload, {
    String? fileName,
  });
  Future<void> deleteLegalDocument(String documentId);
  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId);

  Future<List<OwnerUpcomingEvent>> getOwnerUpcomingEvents(
    String ownerId, {
    String? businessId,
  });
}
