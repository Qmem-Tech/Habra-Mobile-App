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
///
/// **API assumptions:** `business_legal_documents.document_type` values include
/// `business_license` (required for new uploads), optional `ein_proof`, and legacy
/// `doc_1` / `doc_2`. Rows have `status`: `pending` | `approved` | `rejected`.
///
/// Use [needsOwnerAction] for upload prompts; [isFullyApproved] when every row
/// is approved. While docs are `pending` review, [awaitingLegalDocReview] is true
/// and the owner should not be nagged to upload again.
class LegalDocumentsStatus {
  final int uploadedCount;
  final int approvedCount;
  final bool hasRejected;
  final bool hasBusinessLicense;
  final bool businessLicenseApproved;
  final bool hasEinProof;
  final bool einProofApproved;
  final bool hasLegacyDocPair;

  const LegalDocumentsStatus({
    required this.uploadedCount,
    required this.approvedCount,
    this.hasRejected = false,
    this.hasBusinessLicense = false,
    this.businessLicenseApproved = false,
    this.hasEinProof = false,
    this.einProofApproved = false,
    this.hasLegacyDocPair = false,
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

  /// Submitted and not rejected, but at least one row still pending admin approval.
  bool get awaitingLegalDocReview =>
      hasRequiredUploaded && !hasRejected && !isFullyApproved;
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
