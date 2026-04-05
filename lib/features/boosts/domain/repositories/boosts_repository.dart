import '../../../dashboard/domain/entities/dashboard_deal.dart';
import '../../../dashboard/domain/entities/dashboard_job.dart';
import '../entities/active_boost.dart';
import '../entities/boost_location.dart';
import '../entities/boost_option.dart';
import '../entities/past_boost.dart';

/// Repository for boosts feature: options, locations, active/past boosts, actions.
abstract class BoostsRepository {
  Future<List<BoostOption>> getBoostOptions();
  /// All businesses (locations) for the signed-in owner.
  Future<List<BoostLocation>> getLocations();
  /// Active deals across all of the signed-in owner's businesses.
  Future<List<DashboardDeal>> getDealsForBoost();
  /// Open/draft jobs across all of the signed-in owner's businesses.
  Future<List<DashboardJob>> getJobsForBoost();
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
