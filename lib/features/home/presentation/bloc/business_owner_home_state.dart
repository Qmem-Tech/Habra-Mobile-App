import 'package:equatable/equatable.dart';
import '../../domain/entities/business_presence.dart';
import '../../domain/entities/owner_snapshot_metrics.dart';
import '../../domain/entities/owner_activity_item.dart';
import '../../domain/entities/setup_task.dart';
import '../../domain/entities/deal.dart';
import '../../domain/entities/job.dart';

abstract class BusinessOwnerHomeState extends Equatable {
  const BusinessOwnerHomeState();

  @override
  List<Object?> get props => [];
}

class BusinessOwnerHomeInitial extends BusinessOwnerHomeState {}

class BusinessOwnerHomeLoading extends BusinessOwnerHomeState {}

class BusinessOwnerHomeLoaded extends BusinessOwnerHomeState {
  final List<BusinessPresence> presences;
  final String? selectedPresenceId;
  final OwnerSnapshotMetrics snapshot;
  final List<OwnerActivityItem> recentActivity;
  final List<Deal> activeDeals;
  final List<Job> jobPosts;
  final List<SetupTask> setupTasks;
  final int setupCompletedCount;
  final bool isSetupIncomplete;

  const BusinessOwnerHomeLoaded({
    required this.presences,
    this.selectedPresenceId,
    required this.snapshot,
    required this.recentActivity,
    required this.activeDeals,
    required this.jobPosts,
    required this.setupTasks,
    this.setupCompletedCount = 0,
    this.isSetupIncomplete = false,
  });

  bool get isAllBusinessesView =>
      selectedPresenceId == null || selectedPresenceId == 'all';

  BusinessPresence? get selectedPresence {
    if (selectedPresenceId == null) return null;
    try {
      return presences.firstWhere((p) => p.id == selectedPresenceId);
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        presences,
        selectedPresenceId,
        snapshot,
        recentActivity,
        activeDeals,
        jobPosts,
        setupTasks,
        setupCompletedCount,
        isSetupIncomplete,
      ];

  BusinessOwnerHomeLoaded copyWith({
    List<BusinessPresence>? presences,
    String? selectedPresenceId,
    OwnerSnapshotMetrics? snapshot,
    List<OwnerActivityItem>? recentActivity,
    List<Deal>? activeDeals,
    List<Job>? jobPosts,
    List<SetupTask>? setupTasks,
    int? setupCompletedCount,
    bool? isSetupIncomplete,
  }) {
    return BusinessOwnerHomeLoaded(
      presences: presences ?? this.presences,
      selectedPresenceId: selectedPresenceId ?? this.selectedPresenceId,
      snapshot: snapshot ?? this.snapshot,
      recentActivity: recentActivity ?? this.recentActivity,
      activeDeals: activeDeals ?? this.activeDeals,
      jobPosts: jobPosts ?? this.jobPosts,
      setupTasks: setupTasks ?? this.setupTasks,
      setupCompletedCount: setupCompletedCount ?? this.setupCompletedCount,
      isSetupIncomplete: isSetupIncomplete ?? this.isSetupIncomplete,
    );
  }
}

class BusinessOwnerHomeError extends BusinessOwnerHomeState {
  final String message;

  const BusinessOwnerHomeError(this.message);

  @override
  List<Object?> get props => [message];
}
