import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../domain/entities/owner_snapshot_metrics.dart';
import '../../domain/entities/owner_activity_item.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/job.dart';
import 'business_owner_home_state.dart';

const String _storageKeyPrefix = 'business_owner_selected_presence';

/// Cubit for business owner home: loads real presences from Supabase,
/// plus deals, jobs, reviews as activity and lists for each selected business.
class BusinessOwnerHomeCubit extends Cubit<BusinessOwnerHomeState> {
  BusinessOwnerHomeCubit(this._dashboardRepository, this._localStorage)
      : super(BusinessOwnerHomeInitial());

  final DashboardRepository _dashboardRepository;
  final LocalStorage _localStorage;

  String? _ownerId;

  Future<void> loadOwnerHome({
    required String ownerId,
    bool showSetupIncomplete = false,
  }) async {
    _ownerId = ownerId;
    emit(BusinessOwnerHomeLoading());
    try {
      final presences = await _dashboardRepository.getOwnerBusinesses(ownerId);

      if (presences.isEmpty) {
        await _localStorage.remove('${_storageKeyPrefix}_$ownerId');
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
        return;
      }

      final savedId = await _localStorage.getString('${_storageKeyPrefix}_$ownerId');
      final validIds = presences.map((p) => p.id).toSet();
      final initialId = savedId != null &&
              (savedId == 'all' || validIds.contains(savedId))
          ? savedId
          : presences.first.id;

      final deals = initialId == 'all'
          ? <Deal>[]
          : await _loadDealsForHome(initialId);
      final jobs = initialId == 'all'
          ? <Job>[]
          : await _loadJobsForHome(initialId);
      final activity = initialId == 'all'
          ? <OwnerActivityItem>[]
          : await _loadActivityForHome(initialId);
      final snapshot = initialId == 'all'
          ? _emptySnapshot
          : await _loadSnapshot(initialId);

      emit(BusinessOwnerHomeLoaded(
        presences: presences,
        selectedPresenceId: initialId,
        snapshot: snapshot,
        recentActivity: activity,
        activeDeals: deals,
        jobPosts: jobs,
        setupTasks: const [],
        setupCompletedCount: 0,
        isSetupIncomplete: showSetupIncomplete,
      ));
    } catch (e) {
      emit(BusinessOwnerHomeError(e.toString()));
    }
  }

  void selectPresence(String? presenceId) async {
    final current = state;
    if (current is! BusinessOwnerHomeLoaded) return;

    final id = presenceId ?? current.selectedPresenceId;
    if (id == null || id == 'all') {
      if (_ownerId != null) {
        await _localStorage.setString('${_storageKeyPrefix}_$_ownerId', 'all');
      }
      emit(current.copyWith(
        selectedPresenceId: 'all',
        snapshot: _emptySnapshot,
        activeDeals: const [],
        jobPosts: const [],
        recentActivity: const [],
      ));
      return;
    }

    try {
      if (_ownerId != null) {
        await _localStorage.setString('${_storageKeyPrefix}_$_ownerId', id);
      }
      final deals = await _loadDealsForHome(id);
      final jobs = await _loadJobsForHome(id);
      final activity = await _loadActivityForHome(id);
      final snapshot = await _loadSnapshot(id);

      emit(current.copyWith(
        selectedPresenceId: id,
        snapshot: snapshot,
        activeDeals: deals,
        jobPosts: jobs,
        recentActivity: activity,
      ));
    } catch (_) {
      if (_ownerId != null) {
        await _localStorage.setString('${_storageKeyPrefix}_$_ownerId', id);
      }
      emit(current.copyWith(selectedPresenceId: id));
    }
  }

  void setSelectedPresenceId(String? id) {
    selectPresence(id);
  }

  Future<List<Deal>> _loadDealsForHome(String businessId) async {
    try {
      final dashDeals = await _dashboardRepository.getDeals(businessId);
      return dashDeals
          .map((d) => Deal(
                id: d.id,
                title: d.title,
                description: d.description,
                imageUrl: d.imageUrl,
                businessName: d.merchantName ?? '',
                businessId: businessId,
                discountPercent: 0,
                expiryDate: d.expiryDate,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Job>> _loadJobsForHome(String businessId) async {
    try {
      final dashJobs = await _dashboardRepository.getJobs(businessId);
      return dashJobs
          .map((j) => Job(
                id: j.id,
                title: j.title,
                companyName: j.employerName ?? '',
                companyId: businessId,
                jobType: j.jobType,
                location: j.location,
                salary: j.salaryDisplay,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OwnerActivityItem>> _loadActivityForHome(
      String businessId) async {
    try {
      final reviews = await _dashboardRepository.getReviews(businessId);
      return reviews
          .take(5)
          .map((r) => OwnerActivityItem(
                id: r.id,
                type: OwnerActivityType.review,
                title: '${r.authorName} left a ${r.rating}-star review',
                body: r.text,
                authorName: r.authorName,
                createdAt: DateTime.now(),
                actionLabel: r.hasResponse ? null : 'Reply',
                actionId: r.id,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<OwnerSnapshotMetrics> _loadSnapshot(String businessId) async {
    try {
      final analytics = await _dashboardRepository.getAnalytics(businessId);
      if (analytics == null) return _emptySnapshot;
      return OwnerSnapshotMetrics(
        views: int.tryParse(analytics.totalViewsFormatted) ?? 0,
        clicks: int.tryParse(analytics.clicksFormatted) ?? 0,
        messages: int.tryParse(analytics.messagesFormatted) ?? 0,
        viewsChangePercent: analytics.viewsChangePercent,
        clicksChangePercent: analytics.clicksChangePercent,
        messagesChangePercent: analytics.messagesChangePercent,
      );
    } catch (_) {
      return _emptySnapshot;
    }
  }

  static const OwnerSnapshotMetrics _emptySnapshot = OwnerSnapshotMetrics(
    views: 0,
    clicks: 0,
    messages: 0,
  );
}
