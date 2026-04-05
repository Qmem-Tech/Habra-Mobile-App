import 'package:equatable/equatable.dart';

import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_filter.dart';
import '../../domain/entities/boost_location.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';
import '../../../dashboard/domain/entities/dashboard_deal.dart';
import '../../../dashboard/domain/entities/dashboard_job.dart';

abstract class BoostsState extends Equatable {
  const BoostsState();

  @override
  List<Object?> get props => [];
}

class BoostsInitial extends BoostsState {}

class BoostsLoading extends BoostsState {}

class BoostsLoaded extends BoostsState {
  const BoostsLoaded({
    required this.activeBoosts,
    required this.pastBoosts,
    required this.filter,
  });

  final List<ActiveBoost> activeBoosts;
  final List<PastBoost> pastBoosts;
  final BoostFilter filter;

  List<ActiveBoost> get displayedActive => activeBoosts;
  List<PastBoost> get displayedPast => pastBoosts;

  bool get hasActiveBoosts => activeBoosts.isNotEmpty;
  bool get hasPastBoosts => pastBoosts.isNotEmpty;
  bool get isEmpty => activeBoosts.isEmpty && pastBoosts.isEmpty;

  @override
  List<Object?> get props => [activeBoosts, pastBoosts, filter];

  BoostsLoaded copyWith({
    List<ActiveBoost>? activeBoosts,
    List<PastBoost>? pastBoosts,
    BoostFilter? filter,
  }) {
    return BoostsLoaded(
      activeBoosts: activeBoosts ?? this.activeBoosts,
      pastBoosts: pastBoosts ?? this.pastBoosts,
      filter: filter ?? this.filter,
    );
  }
}

class BoostOptionsLoaded extends BoostsState {
  const BoostOptionsLoaded(this.options);

  final List<BoostOption> options;

  @override
  List<Object?> get props => [options];
}

class BoostLocationsLoaded extends BoostsState {
  const BoostLocationsLoaded(this.locations, this.selectedIds);

  final List<BoostLocation> locations;
  final Set<String> selectedIds;

  @override
  List<Object?> get props => [
        locations,
        selectedIds.length,
        ...(selectedIds.toList()..sort()),
      ];
}

class BoostDealsLoaded extends BoostsState {
  const BoostDealsLoaded(this.deals, this.selectedId);

  final List<DashboardDeal> deals;
  final String? selectedId;

  @override
  List<Object?> get props => [deals, selectedId];
}

class BoostJobsLoaded extends BoostsState {
  const BoostJobsLoaded(this.jobs, this.selectedId);

  final List<DashboardJob> jobs;
  final String? selectedId;

  @override
  List<Object?> get props => [jobs, selectedId];
}

class ActiveBoostDetailLoaded extends BoostsState {
  const ActiveBoostDetailLoaded(this.boost);

  final ActiveBoost boost;

  @override
  List<Object?> get props => [boost];
}

class BoostsError extends BoostsState {
  const BoostsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
