import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../../core/error/exceptions.dart';
import '../../../../../core/models/legal_document_upload_result.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/business_legal_document.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/entities/owner_upcoming_event.dart';
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

  Future<void> loadDashboard(String businessId, {String? ownerId}) async {
    emit(DashboardLoading());
    final resolvedOwnerId =
        ownerId ?? Supabase.instance.client.auth.currentUser?.id;
    try {
      final analyticsFuture = _repository.getAnalytics(businessId);
      // Load all deal statuses so tab counts (Active / Expired / Drafts) are correct
      // before the user switches chips (see HAB-26).
      final dealsFuture = _repository.getDeals(businessId);
      final jobsFuture = _repository.getJobs(businessId);
      final reviewsOverviewFuture =
          _repository.getReviewsOverview(businessId);
      final reviewsFuture = _repository.getReviews(businessId);
      final eventsFuture = resolvedOwnerId != null
          ? _repository.getOwnerUpcomingEvents(
              resolvedOwnerId,
              businessId: businessId,
            )
          : Future<List<OwnerUpcomingEvent>>.value([]);

      final results = await Future.wait<Object?>([
        analyticsFuture,
        dealsFuture,
        jobsFuture,
        reviewsOverviewFuture,
        reviewsFuture,
        eventsFuture,
      ]);

      final rawEvents = results.length > 5 ? results[5] : null;
      final upcomingEvents = rawEvents is List<OwnerUpcomingEvent>
          ? (List<OwnerUpcomingEvent>.from(rawEvents)
            ..sort((a, b) => a.startAt.compareTo(b.startAt)))
          : <OwnerUpcomingEvent>[];

      emit(DashboardTabState(
        analytics: results[0] as DashboardAnalytics?,
        deals: results[1]! as List<DashboardDeal>,
        dealsFilter: DashboardDealStatus.active,
        jobs: results[2]! as List<DashboardJob>,
        jobsFilter: DashboardJobStatus.open,
        reviewsOverview: results[3] as RatingOverview?,
        reviews: results[4]! as List<BusinessReview>,
        upcomingEvents: upcomingEvents,
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
    // Filter is client-side only; keep full [deals] list so chip counts stay accurate.
    emit(current.copyWith(dealsFilter: status));
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

  Future<DashboardDeal?> createDeal(
      String businessId, Map<String, dynamic> data) async {
    return await _repository.createDeal(businessId, data);
  }

  Future<DashboardDeal?> updateDeal(
      String dealId, Map<String, dynamic> data) async {
    return await _repository.updateDeal(dealId, data);
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
      final deals = await _repository.getDeals(businessId);
      if (state is DashboardTabState) {
        emit((state as DashboardTabState).copyWith(deals: deals));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteDeal(String dealId) async {
    try {
      await _repository.deleteDeal(dealId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<DashboardJob?> createJob(
      String businessId, Map<String, dynamic> data) async {
    return await _repository.createJob(businessId, data);
  }

  Future<DashboardJob?> updateJob(
      String jobId, Map<String, dynamic> data) async {
    return await _repository.updateJob(jobId, data);
  }

  Future<bool> deleteJob(String jobId) async {
    try {
      await _repository.deleteJob(jobId);
      return true;
    } catch (_) {
      return false;
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

}
