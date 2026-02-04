import '../../../dashboard/domain/entities/dashboard_deal.dart';
import '../../../dashboard/domain/entities/dashboard_job.dart';
import '../entities/active_boost.dart';
import '../entities/boost_location.dart';
import '../entities/boost_option.dart';
import '../entities/past_boost.dart';

/// Repository for boosts feature: options, locations, active/past boosts, actions.
abstract class BoostsRepository {
  Future<List<BoostOption>> getBoostOptions();
  Future<List<BoostLocation>> getLocations(String businessId);
  Future<List<DashboardDeal>> getDealsForBoost(String businessId);
  Future<List<DashboardJob>> getJobsForBoost(String businessId);
  Future<List<ActiveBoost>> getActiveBoosts(String businessId);
  Future<List<PastBoost>> getPastBoosts(String businessId);
  Future<ActiveBoost?> getActiveBoostDetail(String boostId);
  Future<void> submitBoostOrder({
    required String businessId,
    required String optionType,
    required String selectedId,
    required String planId,
    required String price,
    required bool autoRenew,
  });
  Future<void> cancelBoost(String boostId, {String? reason});
  Future<void> setAutoRenew(String boostId, bool autoRenew);
}
