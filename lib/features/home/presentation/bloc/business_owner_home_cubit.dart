import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/mock_data/mock_business_owner_data.dart';
import 'business_owner_home_state.dart';

/// Cubit for business owner home: presences, snapshot, activity, deals, jobs, setup.
/// Uses mock data; replace with use cases when backend is ready.
class BusinessOwnerHomeCubit extends Cubit<BusinessOwnerHomeState> {
  BusinessOwnerHomeCubit() : super(BusinessOwnerHomeInitial());

  Future<void> loadOwnerHome({bool showSetupIncomplete = false}) async {
    emit(BusinessOwnerHomeLoading());

    await Future.delayed(const Duration(milliseconds: 600));

    final presences = MockBusinessOwnerData.getMockPresences();
    final selectedId = presences.firstWhere(
      (p) => p.id == MockBusinessOwnerData.defaultBusinessId,
      orElse: () => presences.first,
    ).id;

    final snapshot = MockBusinessOwnerData.getMockTodaySnapshot();
    final activity = MockBusinessOwnerData.getMockRecentActivity();
    final deals = MockBusinessOwnerData.getMockOwnerActiveDeals();
    final jobs = MockBusinessOwnerData.getMockOwnerJobPosts();
    final setupTasks = MockBusinessOwnerData.getMockSetupTasks(
      completedCount: showSetupIncomplete ? 1 : 3,
    );
    final setupCompletedCount = showSetupIncomplete ? 1 : 3;

    emit(BusinessOwnerHomeLoaded(
      presences: presences,
      selectedPresenceId: selectedId,
      snapshot: snapshot,
      recentActivity: activity,
      activeDeals: deals,
      jobPosts: jobs,
      setupTasks: setupTasks,
      setupCompletedCount: setupCompletedCount,
      isSetupIncomplete: showSetupIncomplete,
    ));
  }

  /// Load "All Businesses" view (monthly snapshot, your businesses list).
  void selectPresence(String? presenceId) {
    final current = state;
    if (current is! BusinessOwnerHomeLoaded) return;

    final isAll = presenceId == null || presenceId == 'all';
    final snapshot = isAll
        ? MockBusinessOwnerData.getMockMonthlySnapshot()
        : MockBusinessOwnerData.getMockTodaySnapshot();

    emit(current.copyWith(
      selectedPresenceId: presenceId ?? current.selectedPresenceId,
      snapshot: snapshot,
    ));
  }

  void setSelectedPresenceId(String? id) {
    final current = state;
    if (current is! BusinessOwnerHomeLoaded) return;
    selectPresence(id);
  }
}
