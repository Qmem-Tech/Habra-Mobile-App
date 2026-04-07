import '../../../../core/models/legal_document_upload_result.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../entities/applicant_detail.dart';
import '../entities/business_legal_document.dart';
import '../entities/boost_plan.dart';
import '../entities/business_review.dart';
import '../entities/dashboard_analytics.dart';
import '../entities/dashboard_deal.dart';
import '../entities/dashboard_job.dart';
import '../entities/job_applicant.dart';
import '../entities/owner_upcoming_event.dart';

/// Repository for business owner dashboard data.
abstract class DashboardRepository {
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId);
  Future<DashboardAnalytics?> getAnalytics(String businessId);
  Future<List<DashboardDeal>> getDeals(String businessId, {DashboardDealStatus? status});
  Future<List<DashboardDeal>> getActiveDealsForCurrentOwner();
  Future<List<DashboardJob>> getJobs(String businessId);
  Future<List<DashboardJob>> getOpenJobsForCurrentOwner();
  Future<RatingOverview?> getReviewsOverview(String businessId);
  Future<List<BusinessReview>> getReviews(String businessId);
  Future<List<JobApplicant>> getApplicants(String jobId, {ApplicantStatus? status});
  Future<void> markAllApplicantsReadForJob(String jobId);
  Future<ApplicantDetail?> getApplicantDetail(String applicantId, String jobId);
  Future<void> updateJobApplicationStatus(
    String applicationId,
    String jobId,
    String status,
  );
  Future<List<BoostPlan>> getBoostPlans(String targetType);
  Future<DashboardDeal> createDeal(String businessId, Map<String, dynamic> data);
  Future<DashboardDeal> updateDeal(String dealId, Map<String, dynamic> data);
  Future<void> updateDealStatus(String dealId, DashboardDealStatus status);
  Future<void> deleteDeal(String dealId);
  Future<DashboardJob> createJob(String businessId, Map<String, dynamic> data);
  Future<DashboardJob> updateJob(String jobId, Map<String, dynamic> data);
  Future<void> deleteJob(String jobId);
  Future<void> replyToReview(String reviewId, String replyText);
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data);
  Future<void> updateBusinessHours(String businessId, Map<String, dynamic> hours);
  /// `opening_time`, `closing_time` (legacy), optional `weekly_hours` (Map per weekday).
  Future<Map<String, dynamic>?> getBusinessHours(String businessId);
  Future<String> createBusiness(String ownerId, Map<String, dynamic> data);
  /// Replaces rows in `business_categories` for this business (owner flow).
  Future<void> replaceBusinessCategoryLinks(String businessId, List<String> categoryIds);
  Future<List<String>> listCategoryIdsForBusiness(String businessId);
  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId);
  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId);
  Future<void> uploadLegalDocument(
    String businessId,
    String documentType,
    LegalDocumentUploadResult upload, {
    String? fileName,
  });
  /// Copies legal document rows from [fromBusinessId] to [toBusinessId] (branch inherits parent files + status).
  Future<void> copyLegalDocumentsFromBusiness(
    String fromBusinessId,
    String toBusinessId,
  );
  Future<void> deleteLegalDocument(String documentId);
  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId);

  /// Events the user organizes, optionally scoped to a business (includes rows with null `business_id`).
  Future<List<OwnerUpcomingEvent>> getOwnerUpcomingEvents(
    String ownerId, {
    String? businessId,
  });
}

/// Status of legal documents for a business.
///
/// **API assumptions:** `business_legal_documents.document_type` values include
/// `business_license` (required for new uploads), optional `ein_proof`, and legacy
/// `doc_1` / `doc_2`. Rows use `review_status` when present (Super Admin), else `status`:
/// `pending` | `approved` | `rejected`.
///
/// Use [needsOwnerAction] for upload prompts; [isFullyApproved] when every row
/// is approved. While docs are `pending` review, [awaitingLegalDocReview] is true
/// and the owner should not be nagged to upload again.
///
/// [hasPendingRows] is derived from rows with status `pending` (case-insensitive).
/// [rejectionReasons] come from `rejection_reason` on rejected rows.
class LegalDocumentsStatus {
  final int uploadedCount;
  final int approvedCount;
  final bool hasRejected;
  final bool hasBusinessLicense;
  final bool businessLicenseApproved;
  final bool hasEinProof;
  final bool einProofApproved;
  final bool hasLegacyDocPair;
  final bool hasPendingRows;
  final List<String> rejectionReasons;

  const LegalDocumentsStatus({
    required this.uploadedCount,
    required this.approvedCount,
    this.hasRejected = false,
    this.hasBusinessLicense = false,
    this.businessLicenseApproved = false,
    this.hasEinProof = false,
    this.einProofApproved = false,
    this.hasLegacyDocPair = false,
    this.hasPendingRows = false,
    this.rejectionReasons = const [],
  });

  /// At least business license on file, or two legacy generic documents.
  bool get hasRequiredUploaded =>
      hasBusinessLicense || hasLegacyDocPair || uploadedCount >= 2;

  /// License approved; if EIN was uploaded it must be approved too. Legacy: both docs approved.
  bool get isFullyApproved {
    if (hasLegacyDocPair || (!hasBusinessLicense && uploadedCount >= 2)) {
      return approvedCount >= 2 && !hasRejected;
    }
    if (!businessLicenseApproved) return false;
    if (hasEinProof && !einProofApproved) return false;
    return true;
  }

  /// Owner must upload (or re-upload after rejection).
  bool get needsOwnerAction => !hasRequiredUploaded || hasRejected;

  /// Nothing on file yet and nothing rejected (first-time upload prompt).
  bool get missingInitialUpload => !hasRequiredUploaded && !hasRejected;

  /// Submitted and not rejected, but at least one row still `pending` admin review.
  /// If the admin marked all rows approved, [hasPendingRows] is false so this is false
  /// even if [isFullyApproved] were miscalculated.
  bool get awaitingLegalDocReview =>
      hasRequiredUploaded &&
      !hasRejected &&
      !isFullyApproved &&
      hasPendingRows;

  /// All required documents approved; show success / compliance-complete UI.
  bool get showLegalApprovalSuccess =>
      hasRequiredUploaded && !hasRejected && isFullyApproved;
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
