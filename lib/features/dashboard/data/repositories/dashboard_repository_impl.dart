import '../../../../../core/models/legal_document_upload_result.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/entities/owner_upcoming_event.dart';
import '../../domain/entities/business_legal_document.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl({required DashboardRemoteDataSource remoteDataSource})
      : _remote = remoteDataSource;

  final DashboardRemoteDataSource _remote;

  @override
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId) =>
      _remote.getOwnerBusinesses(ownerId);

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

  @override
  Future<DashboardDeal> createDeal(String businessId, Map<String, dynamic> data) =>
      _remote.createDeal(businessId, data);

  @override
  Future<DashboardJob> createJob(String businessId, Map<String, dynamic> data) =>
      _remote.createJob(businessId, data);

  @override
  Future<void> replyToReview(String reviewId, String replyText) =>
      _remote.replyToReview(reviewId, replyText);

  @override
  Future<void> updateBusiness(String businessId, Map<String, dynamic> data) =>
      _remote.updateBusiness(businessId, data);

  @override
  Future<void> updateBusinessHours(String businessId, Map<String, dynamic> hours) =>
      _remote.updateBusinessHours(businessId, hours);

  @override
  Future<Map<String, dynamic>?> getBusinessHours(String businessId) =>
      _remote.getBusinessHours(businessId);

  @override
  Future<String> createBusiness(String ownerId, Map<String, dynamic> data) =>
      _remote.createBusiness(ownerId, data);

  @override
  Future<void> replaceBusinessCategoryLinks(String businessId, List<String> categoryIds) =>
      _remote.replaceBusinessCategoryLinks(businessId, categoryIds);

  @override
  Future<List<String>> listCategoryIdsForBusiness(String businessId) =>
      _remote.listCategoryIdsForBusiness(businessId);

  @override
  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId) =>
      _remote.getLegalDocumentsStatus(businessId);

  @override
  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId) =>
      _remote.listBusinessLegalDocuments(businessId);

  @override
  Future<void> uploadLegalDocument(
    String businessId,
    String documentType,
    LegalDocumentUploadResult upload, {
    String? fileName,
  }) =>
      _remote.uploadLegalDocument(businessId, documentType, upload, fileName: fileName);

  @override
  Future<void> deleteLegalDocument(String documentId) =>
      _remote.deleteLegalDocument(documentId);

  @override
  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId) =>
      _remote.getBusinessIdsNeedingLegalDocs(ownerId);

  @override
  Future<List<OwnerUpcomingEvent>> getOwnerUpcomingEvents(
    String ownerId, {
    String? businessId,
  }) =>
      _remote.getOwnerUpcomingEvents(ownerId, businessId: businessId);
}
