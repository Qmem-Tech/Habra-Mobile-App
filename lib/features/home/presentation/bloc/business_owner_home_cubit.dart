import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/local_storage.dart';
import '../../../dashboard/domain/entities/dashboard_deal.dart';
import '../../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../domain/entities/business_presence.dart';
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

  /// Max items shown in the home "Recent activity" section (single source of truth).
  static const int recentActivityHomeLimit = 4;

  final DashboardRepository _dashboardRepository;
  final LocalStorage _localStorage;

  String? _ownerId;

  List<OwnerActivityItem> _capRecentActivity(List<OwnerActivityItem> items) {
    if (items.length <= recentActivityHomeLimit) return items;
    return items.take(recentActivityHomeLimit).toList();
  }

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

      final List<Deal> deals;
      final List<Job> jobs;
      final List<OwnerActivityItem> activity;
      final OwnerSnapshotMetrics snapshot;

      if (initialId == 'all') {
        final result = await _loadAggregated(presences);
        deals = result.deals;
        jobs = result.jobs;
        activity = result.activity;
        snapshot = result.snapshot;
      } else {
        deals = await _loadDealsForHome(initialId);
        jobs = await _loadJobsForHome(initialId);
        activity = await _loadActivityForHome(initialId);
        snapshot = await _loadSnapshot(initialId);
      }

      emit(BusinessOwnerHomeLoaded(
        presences: presences,
        selectedPresenceId: initialId,
        snapshot: snapshot,
        recentActivity: _capRecentActivity(activity),
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
      final result = await _loadAggregated(current.presences);
      emit(current.copyWith(
        selectedPresenceId: 'all',
        snapshot: result.snapshot,
        activeDeals: result.deals,
        jobPosts: result.jobs,
        recentActivity: _capRecentActivity(result.activity),
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
        recentActivity: _capRecentActivity(activity),
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

  Future<_AggregatedData> _loadAggregated(List<BusinessPresence> presences) async {
    final bizIds = presences.map((p) => p.id).where((id) => id != 'all').toList();
    if (bizIds.isEmpty) {
      return _AggregatedData(
        deals: const [],
        jobs: const [],
        activity: const [],
        snapshot: _emptySnapshot,
      );
    }

    final allDeals = <Deal>[];
    final allJobs = <Job>[];
    final allActivity = <OwnerActivityItem>[];
    int totalViews = 0, totalClicks = 0, totalMessages = 0;

    for (final bizId in bizIds) {
      allDeals.addAll(await _loadDealsForHome(bizId));
      allJobs.addAll(await _loadJobsForHome(bizId));
      allActivity.addAll(await _loadActivityForHome(bizId));
      final snap = await _loadSnapshot(bizId);
      totalViews += snap.views;
      totalClicks += snap.clicks;
      totalMessages += snap.messages;
    }

    allActivity.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return _AggregatedData(
      deals: allDeals,
      jobs: allJobs,
      activity: allActivity.take(recentActivityHomeLimit).toList(),
      snapshot: OwnerSnapshotMetrics(
        views: totalViews,
        clicks: totalClicks,
        messages: totalMessages,
      ),
    );
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
                status: _mapOwnerDealStatus(d.status),
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
                salary: j.salaryDisplay.isEmpty ? null : j.salaryDisplay,
                createdAt: j.createdAt,
                updatedAt: j.updatedAt,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<OwnerActivityItem>> _loadActivityForHome(
      String businessId) async {
    final ownerId = _ownerId;
    if (ownerId == null) return [];
    try {
      final reviews = await _dashboardRepository.getReviews(businessId);
      final events = await _dashboardRepository.getOwnerUpcomingEvents(
        ownerId,
        businessId: businessId,
      );
      final now = DateTime.now();
      final reviewRecencyCutoff = now.subtract(const Duration(days: 180));
      final sortedRecentReviews = reviews
          .where((r) =>
              r.createdAt.year > 1970 &&
              !r.createdAt.isBefore(reviewRecencyCutoff))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final reviewItems =
          sortedRecentReviews.take(recentActivityHomeLimit).map((r) => OwnerActivityItem(
            id: r.id,
            type: OwnerActivityType.review,
            title: '${r.authorName} left a ${r.rating}-star review',
            body: r.text,
            authorName: r.authorName,
            createdAt: r.createdAt,
            actionLabel: r.hasResponse ? null : 'Reply',
            actionId: r.id,
          ));
      final eventItems = events.map(
        (e) => OwnerActivityItem(
          id: e.id,
          type: OwnerActivityType.event,
          title: e.title,
          subtitle: 'Your event',
          body:
              'Starts ${e.startAt.year}-${e.startAt.month.toString().padLeft(2, '0')}-${e.startAt.day.toString().padLeft(2, '0')} · ${_formatEventTime(e.startAt)}',
          createdAt: e.startAt,
        ),
      );
      final merged = [...eventItems, ...reviewItems].toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return merged.take(recentActivityHomeLimit).toList();
    } catch (_) {
      return [];
    }
  }

  String _formatEventTime(DateTime dt) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final am = h < 12;
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$h12:$m ${am ? 'AM' : 'PM'}';
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

  OwnerDealStatus _mapOwnerDealStatus(DashboardDealStatus status) {
    switch (status) {
      case DashboardDealStatus.draft:
        return OwnerDealStatus.draft;
      case DashboardDealStatus.active:
        return OwnerDealStatus.published;
      case DashboardDealStatus.inactive:
        return OwnerDealStatus.paused;
      case DashboardDealStatus.expired:
        return OwnerDealStatus.expired;
    }
  }
}

class _AggregatedData {
  final List<Deal> deals;
  final List<Job> jobs;
  final List<OwnerActivityItem> activity;
  final OwnerSnapshotMetrics snapshot;

  const _AggregatedData({
    required this.deals,
    required this.jobs,
    required this.activity,
    required this.snapshot,
  });
}
