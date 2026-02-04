import '../../dashboard/domain/entities/dashboard_deal.dart';
import '../../dashboard/domain/entities/dashboard_job.dart';
import '../../dashboard/domain/repositories/dashboard_repository.dart';
import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_location.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';
import '../../domain/repositories/boosts_repository.dart';
import '../datasources/boosts_remote_datasource.dart';

class BoostsRepositoryImpl implements BoostsRepository {
  BoostsRepositoryImpl({
    required BoostsRemoteDataSource remoteDataSource,
    required DashboardRepository dashboardRepository,
  })  : _remote = remoteDataSource,
        _dashboard = dashboardRepository;

  final BoostsRemoteDataSource _remote;
  final DashboardRepository _dashboard;

  @override
  Future<List<BoostOption>> getBoostOptions() => _remote.getBoostOptions();

  @override
  Future<List<BoostLocation>> getLocations(String businessId) =>
      _remote.getLocations(businessId);

  @override
  Future<List<DashboardDeal>> getDealsForBoost(String businessId) =>
      _dashboard.getDeals(businessId, status: DashboardDealStatus.active);

  @override
  Future<List<DashboardJob>> getJobsForBoost(String businessId) =>
      _dashboard.getJobs(businessId);

  @override
  Future<List<ActiveBoost>> getActiveBoosts(String businessId) =>
      _remote.getActiveBoosts(businessId);

  @override
  Future<List<PastBoost>> getPastBoosts(String businessId) =>
      _remote.getPastBoosts(businessId);

  @override
  Future<ActiveBoost?> getActiveBoostDetail(String boostId) =>
      _remote.getActiveBoostDetail(boostId);

  @override
  Future<void> submitBoostOrder({
    required String businessId,
    required String optionType,
    required String selectedId,
    required String planId,
    required String price,
    required bool autoRenew,
  }) =>
      _remote.submitBoostOrder(
        businessId: businessId,
        optionType: optionType,
        selectedId: selectedId,
        planId: planId,
        price: price,
        autoRenew: autoRenew,
      );

  @override
  Future<void> cancelBoost(String boostId, {String? reason}) =>
      _remote.cancelBoost(boostId, reason: reason);

  @override
  Future<void> setAutoRenew(String boostId, bool autoRenew) =>
      _remote.setAutoRenew(boostId, autoRenew);
}
