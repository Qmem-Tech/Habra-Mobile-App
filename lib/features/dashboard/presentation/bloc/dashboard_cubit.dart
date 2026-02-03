import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_state.dart';

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._repository) : super(DashboardInitial());

  final DashboardRepository _repository;

  Future<void> loadDashboard(String businessId) async {
    emit(DashboardLoading());
    try {
      final analytics = await _repository.getAnalytics(businessId);
      final deals = await _repository.getDeals(businessId);
      final jobs = await _repository.getJobs(businessId);
      final reviewsOverview = await _repository.getReviewsOverview(businessId);
      final reviews = await _repository.getReviews(businessId);
      emit(DashboardTabState(
        analytics: analytics,
        deals: deals,
        dealsFilter: DashboardDealStatus.active,
        jobs: jobs,
        reviewsOverview: reviewsOverview,
        reviews: reviews,
      ));
    } catch (e) {
      emit(DashboardError(e.toString()));
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

  Future<void> loadBoostPlans({int selectedIndex = 1}) async {
    emit(BoostPlansLoading());
    try {
      final plans = await _repository.getBoostPlans();
      emit(BoostPlansLoaded(plans, selectedIndex: selectedIndex));
    } catch (e) {
      emit(DashboardError(e.toString()));
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
