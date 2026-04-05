import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/models/legal_document_upload_result.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/business_legal_document.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(DashboardInitial());

  final DashboardRepository _repository;

  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId) {
    return _repository.getOwnerBusinesses(ownerId);
  }

  /// Show a load error without hitting the network (e.g. no business to load).
  void setLoadError(String message) {
    emit(DashboardError(message));
  }

  Future<void> loadDashboard(String businessId) async {
    emit(DashboardLoading());
    try {
      final analytics = await _repository.getAnalytics(businessId);
      final deals = await _repository.getDeals(
        businessId,
        status: DashboardDealStatus.active,
      );
      final jobs = await _repository.getJobs(businessId);
      final reviewsOverview = await _repository.getReviewsOverview(businessId);
      final reviews = await _repository.getReviews(businessId);
      emit(DashboardTabState(
        analytics: analytics,
        deals: deals,
        dealsFilter: DashboardDealStatus.active,
        jobs: jobs,
        jobsFilter: DashboardJobStatus.open,
        reviewsOverview: reviewsOverview,
        reviews: reviews,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  /// Reloads reviews and rating overview only — does not emit [DashboardLoading],
  /// so the user stays on the current dashboard tab (e.g. Reviews) with visible content.
  Future<void> refreshReviewsForBusiness(String businessId) async {
    final current = state;
    if (current is! DashboardTabState) return;
    try {
      final overview = await _repository.getReviewsOverview(businessId);
      final reviews = await _repository.getReviews(businessId);
      if (state is! DashboardTabState) return;
      final s = state as DashboardTabState;
      emit(s.copyWith(
        reviewsOverview: overview ?? s.reviewsOverview,
        reviews: reviews,
      ));
    } catch (_) {
      // Reply already succeeded; keep showing the previous list rather than error state.
    }
  }

  Future<void> setDealsFilter(String businessId, DashboardDealStatus? status) async {
    final current = state;
    if (current is! DashboardTabState) return;
    emit(current.copyWith(dealsFilter: status));
    try {
      final deals = await _repository.getDeals(businessId, status: status);
      if (state is DashboardTabState) {
        emit((state as DashboardTabState).copyWith(deals: deals));
      }
    } catch (_) {}
  }

  void setJobsFilter(DashboardJobStatus? status) {
    final current = state;
    if (current is! DashboardTabState) return;
    emit(current.copyWith(jobsFilter: status));
  }

  Future<void> loadApplicants(String jobId, String jobTitle, String jobSubtitle,
      {ApplicantStatus? filter}) async {
    emit(ApplicantsLoading());
    try {
      final applicants =
          await _repository.getApplicants(jobId, status: filter);
      emit(ApplicantsLoaded(
        jobId: jobId,
        jobTitle: jobTitle,
        jobSubtitle: jobSubtitle,
        applicants: applicants,
        filter: filter,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  /// Marks every `pending` application for the current [ApplicantsLoaded.jobId] as `reviewed`.
  Future<bool> markAllApplicantsReadForJob() async {
    final current = state;
    if (current is! ApplicantsLoaded) return false;
    try {
      await _repository.markAllApplicantsReadForJob(current.jobId);
      final applicants = await _repository.getApplicants(current.jobId);
      emit(ApplicantsLoaded(
        jobId: current.jobId,
        jobTitle: current.jobTitle,
        jobSubtitle: current.jobSubtitle,
        applicants: applicants,
        filter: current.filter,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadApplicantDetail(String applicantId, String jobId) async {
    emit(ApplicantDetailLoading());
    try {
      final detail = await _repository.getApplicantDetail(applicantId, jobId);
      if (detail != null) {
        emit(ApplicantDetailLoaded(detail));
      } else {
        emit(const ApplicantDetailError('Applicant not found'));
      }
    } catch (e) {
      emit(ApplicantDetailError(e.toString()));
    }
  }

  /// Updates [status] on `job_applications` (e.g. `rejected`, `hired`) and refreshes detail without a full-screen loader.
  Future<bool> updateJobApplicationStatus({
    required String applicationId,
    required String jobId,
    required String status,
  }) async {
    final current = state;
    if (current is! ApplicantDetailLoaded) return false;
    try {
      await _repository.updateJobApplicationStatus(applicationId, jobId, status);
      final detail = await _repository.getApplicantDetail(applicationId, jobId);
      if (detail != null) {
        emit(ApplicantDetailLoaded(detail));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadBoostPlans({
    required String targetType,
    int selectedIndex = 1,
  }) async {
    emit(BoostPlansLoading());
    try {
      final plans = await _repository.getBoostPlans(targetType);
      emit(BoostPlansLoaded(plans, selectedIndex: selectedIndex));
    } catch (e) {
      emit(DashboardError(e.toString()));
    }
  }

  Future<DashboardDeal?> createDeal(
      String businessId, Map<String, dynamic> data) async {
    try {
      return await _repository.createDeal(businessId, data);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  Future<DashboardDeal?> updateDeal(
      String dealId, Map<String, dynamic> data) async {
    try {
      return await _repository.updateDeal(dealId, data);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  /// Pause ([inactive]) or resume ([active]) without replacing the whole dashboard state on failure.
  Future<bool> setDealPaused(String businessId, String dealId, bool paused) async {
    final current = state;
    if (current is! DashboardTabState) return false;
    try {
      await _repository.updateDealStatus(
        dealId,
        paused ? DashboardDealStatus.inactive : DashboardDealStatus.active,
      );
      final deals = await _repository.getDeals(
        businessId,
        status: current.dealsFilter,
      );
      if (state is DashboardTabState) {
        emit((state as DashboardTabState).copyWith(deals: deals));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<DashboardJob?> createJob(
      String businessId, Map<String, dynamic> data) async {
    try {
      return await _repository.createJob(businessId, data);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  Future<DashboardJob?> updateJob(
      String jobId, Map<String, dynamic> data) async {
    try {
      return await _repository.updateJob(jobId, data);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  /// Posts an owner reply. Returns `null` on success, or a short message to show
  /// in a SnackBar (never emits [DashboardError], so the dashboard tab stays intact).
  Future<String?> replyToReview(String reviewId, String replyText) async {
    try {
      await _repository.replyToReview(reviewId, replyText);
      return null;
    } catch (e) {
      return _replyToReviewUserMessage(e);
    }
  }

  static String _replyToReviewUserMessage(Object e) {
    if (e is ForbiddenException) {
      return e.message;
    }
    if (e is NetworkException) {
      return e.message;
    }
    final raw = e is Exception ? e.toString() : e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('reply_text') &&
        (lower.contains('column') ||
            lower.contains('schema') ||
            lower.contains('could not find'))) {
      return 'Review replies need a reply_text column on reviews in Supabase. '
          'Run the migration to add reply_text (and optionally replied_at), then try again.';
    }
    if (lower.contains('replied_at') &&
        (lower.contains('column') ||
            lower.contains('schema') ||
            lower.contains('could not find'))) {
      return 'Update the app or add the replied_at column on reviews; '
          'the reply may still work if reply_text exists.';
    }
    if (raw.length <= 220) {
      return raw;
    }
    return '${raw.substring(0, 217)}...';
  }

  Future<bool> updateBusiness(
      String businessId, Map<String, dynamic> data) async {
    try {
      await _repository.updateBusiness(businessId, data);
      return true;
    } catch (e) {
      emit(DashboardError(e.toString()));
      return false;
    }
  }

  Future<bool> updateBusinessHours(
      String businessId, Map<String, dynamic> hours) async {
    try {
      await _repository.updateBusinessHours(businessId, hours);
      return true;
    } catch (e) {
      emit(DashboardError(e.toString()));
      return false;
    }
  }

  Future<Map<String, dynamic>?> getBusinessHours(String businessId) async {
    try {
      return await _repository.getBusinessHours(businessId);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId) =>
      _repository.getLegalDocumentsStatus(businessId);

  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId) =>
      _repository.listBusinessLegalDocuments(businessId);

  Future<void> uploadLegalDocument(
    String businessId,
    String documentType,
    LegalDocumentUploadResult upload, {
    String? fileName,
  }) =>
      _repository.uploadLegalDocument(businessId, documentType, upload, fileName: fileName);

  Future<void> deleteLegalDocument(String documentId) =>
      _repository.deleteLegalDocument(documentId);

  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId) =>
      _repository.getBusinessIdsNeedingLegalDocs(ownerId);

  Future<String?> createBusiness(
      String ownerId, Map<String, dynamic> data) async {
    try {
      return await _repository.createBusiness(ownerId, data);
    } catch (e) {
      emit(DashboardError(e.toString()));
      return null;
    }
  }

  void setBoostPlanSelected(int index) {
    final current = state;
    if (current is BoostPlansLoaded) {
      emit(BoostPlansLoaded(current.plans, selectedIndex: index));
    }
  }

  void clearApplicantDetail() {
    if (state is ApplicantDetailLoaded || state is ApplicantDetailError) {
      emit(DashboardInitial());
    }
  }

  void clearApplicants() {
    if (state is ApplicantsLoaded) {
      emit(DashboardInitial());
    }
  }

  void clearBoostPlans() {
    if (state is BoostPlansLoaded) {
      emit(DashboardInitial());
    }
  }
}
