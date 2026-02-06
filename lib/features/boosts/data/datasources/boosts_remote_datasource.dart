import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_location.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';
import 'mock_data/mock_boosts_data.dart';

/// Remote (mock) data source for boosts. Replace with real API when backend is ready.
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
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return MockBoostsData.getBoostOptions();
  }

  @override
  Future<List<BoostLocation>> getLocations(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockBoostsData.getLocations(businessId);
  }

  @override
  Future<List<ActiveBoost>> getActiveBoosts(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return MockBoostsData.getActiveBoosts(businessId);
  }

  @override
  Future<List<PastBoost>> getPastBoosts(String businessId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return MockBoostsData.getPastBoosts(businessId);
  }

  @override
  Future<ActiveBoost?> getActiveBoostDetail(String boostId) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return MockBoostsData.getActiveBoostDetail(boostId);
  }

  @override
  Future<void> submitBoostOrder({
    required String businessId,
    required String optionType,
    required String selectedId,
    required String planId,
    required String price,
    required bool autoRenew,
  }) async {
    await Future<void>.delayed(const Duration(seconds: 2));
  }

  @override
  Future<void> cancelBoost(String boostId, {String? reason}) async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
  }

  @override
  Future<void> setAutoRenew(String boostId, bool autoRenew) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
