import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_location.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';

abstract class BoostsRemoteDataSource {
  Future<List<BoostOption>> getBoostOptions();
  Future<List<BoostLocation>> getLocations(String businessId);
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

class BoostsRemoteDataSourceImpl implements BoostsRemoteDataSource {
  @override
  Future<List<BoostOption>> getBoostOptions() async {
    return [];
  }

  @override
  Future<List<BoostLocation>> getLocations(String businessId) async {
    return [];
  }

  @override
  Future<List<ActiveBoost>> getActiveBoosts(String businessId) async {
    return [];
  }

  @override
  Future<List<PastBoost>> getPastBoosts(String businessId) async {
    return [];
  }

  @override
  Future<ActiveBoost?> getActiveBoostDetail(String boostId) async {
    return null;
  }

  @override
  Future<void> submitBoostOrder({
    required String businessId,
    required String optionType,
    required String selectedId,
    required String planId,
    required String price,
    required bool autoRenew,
  }) async {}

  @override
  Future<void> cancelBoost(String boostId, {String? reason}) async {}

  @override
  Future<void> setAutoRenew(String boostId, bool autoRenew) async {}
}
