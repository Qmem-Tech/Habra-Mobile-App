import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/owner_snapshot_metrics.dart';
import 'business_owner_home_state.dart';

/// Cubit for business owner home: presences, snapshot, activity, deals, jobs, setup.
/// Loads from backend (currently empty until BO APIs are wired).
class BusinessOwnerHomeCubit extends Cubit<BusinessOwnerHomeState> {
  BusinessOwnerHomeCubit() : super(BusinessOwnerHomeInitial());

  static const OwnerSnapshotMetrics _emptySnapshot = OwnerSnapshotMetrics(
    views: 0,
    clicks: 0,
    messages: 0,
  );

  Future<void> loadOwnerHome({bool showSetupIncomplete = false}) async {
    emit(BusinessOwnerHomeLoading());

    await Future.delayed(const Duration(milliseconds: 300));

    emit(BusinessOwnerHomeLoaded(
      presences: const [],
      selectedPresenceId: null,
      snapshot: _emptySnapshot,
      recentActivity: const [],
      activeDeals: const [],
      jobPosts: const [],
      setupTasks: const [],
      setupCompletedCount: 0,
      isSetupIncomplete: showSetupIncomplete,
    ));
  }

  void selectPresence(String? presenceId) {
    final current = state;
    if (current is! BusinessOwnerHomeLoaded) return;

    emit(current.copyWith(
      selectedPresenceId: presenceId ?? current.selectedPresenceId,
      snapshot: _emptySnapshot,
    ));
  }

  void setSelectedPresenceId(String? id) {
    final current = state;
    if (current is! BusinessOwnerHomeLoaded) return;
    selectPresence(id);
  }
}
