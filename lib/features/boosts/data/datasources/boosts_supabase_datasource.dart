import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/active_boost.dart';
import '../../domain/entities/boost_location.dart';
import '../../domain/entities/boost_option.dart';
import '../../domain/entities/past_boost.dart';
import 'boosts_remote_datasource.dart';

class BoostsSupabaseDataSource implements BoostsRemoteDataSource {
  BoostsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<List<BoostOption>> getBoostOptions() async {
    return const [
      BoostOption(
        id: 'business_listing',
        type: BoostOptionType.businessListing,
        priceLabel: 'From \$29/week',
        title: 'Boost Business Listing',
        description: 'Get more visibility for your business profile',
      ),
      BoostOption(
        id: 'deal',
        type: BoostOptionType.deal,
        priceLabel: 'From \$19/week',
        title: 'Boost a Deal',
        description: 'Promote your deal to more customers',
      ),
      BoostOption(
        id: 'job',
        type: BoostOptionType.job,
        priceLabel: 'From \$24/week',
        title: 'Boost a Job Post',
        description: 'Reach more applicants for your open positions',
      ),
    ];
  }

  @override
  Future<List<BoostLocation>> getLocations(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businesses)
          .select('id, name, address_street, address_city, rating, review_count')
          .eq('owner_id', _client.auth.currentUser!.id)
          .order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final city = parseString(row['address_city']) ?? '';
        final street = parseString(row['address_street']) ?? '';
        final address = [street, city].where((s) => s.isNotEmpty).join(', ');
        return BoostLocation(
          id: parseStringRequired(row['id']),
          name: parseStringRequired(row['name']),
          address: address,
          viewsPerMonth: '0',
          rating: parseDouble(row['rating']) ?? 0,
        );
      }).toList();
    });
  }

  @override
  Future<List<ActiveBoost>> getActiveBoosts(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final now = DateTime.now().toIso8601String();
      final res = await _client
          .from(SupabaseTables.boosts)
          .select('*, ${SupabaseTables.boostPlans}!boosts_boost_plan_id_fkey(name), ${SupabaseTables.deals}(title), ${SupabaseTables.jobs}(title)')
          .eq('business_id', businessId)
          .gte('ends_at', now)
          .neq('status', 'cancelled')
          .order('starts_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map(_rowToActiveBoost).toList();
    });
  }

  @override
  Future<List<PastBoost>> getPastBoosts(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final now = DateTime.now().toIso8601String();
      final res = await _client
          .from(SupabaseTables.boosts)
          .select('*, ${SupabaseTables.boostPlans}!boosts_boost_plan_id_fkey(name), ${SupabaseTables.deals}(title), ${SupabaseTables.jobs}(title)')
          .eq('business_id', businessId)
          .lt('ends_at', now)
          .order('ends_at', ascending: false)
          .limit(20);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final dealTitle = row[SupabaseTables.deals] is Map
            ? parseString((row[SupabaseTables.deals] as Map)['title'])
            : null;
        final jobTitle = row[SupabaseTables.jobs] is Map
            ? parseString((row[SupabaseTables.jobs] as Map)['title'])
            : null;
        final title = dealTitle ?? jobTitle ?? 'Business Listing';
        BoostOptionType type = BoostOptionType.businessListing;
        if (row['deal_id'] != null) type = BoostOptionType.deal;
        if (row['job_id'] != null) type = BoostOptionType.job;
        final starts = parseTimestampRequired(row['starts_at']);
        final ends = parseTimestampRequired(row['ends_at']);
        return PastBoost(
          id: parseStringRequired(row['id']),
          type: type,
          title: title,
          dateRange: '${starts.month}/${starts.day} - ${ends.month}/${ends.day}',
          views: '0',
        );
      }).toList();
    });
  }

  @override
  Future<ActiveBoost?> getActiveBoostDetail(String boostId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.boosts)
          .select('*, ${SupabaseTables.boostPlans}!boosts_boost_plan_id_fkey(name), ${SupabaseTables.deals}(title, image_url), ${SupabaseTables.jobs}(title)')
          .eq('id', boostId)
          .maybeSingle();
      if (res == null) return null;
      return _rowToActiveBoost(Map<String, dynamic>.from(res as Map));
    });
  }

  ActiveBoost _rowToActiveBoost(Map<String, dynamic> row) {
    final dealData = row[SupabaseTables.deals];
    final jobData = row[SupabaseTables.jobs];
    final planData = row[SupabaseTables.boostPlans];
    final dealTitle = dealData is Map ? parseString(dealData['title']) : null;
    final jobTitle = jobData is Map ? parseString(jobData['title']) : null;
    final title = dealTitle ?? jobTitle ?? 'Business Listing';
    String typeLabel = 'Business Listing';
    if (row['deal_id'] != null) typeLabel = 'Deal Boost';
    if (row['job_id'] != null) typeLabel = 'Job Boost';
    final imageUrl = dealData is Map
        ? parseString(dealData['image_url']) ?? ''
        : '';
    return ActiveBoost(
      id: parseStringRequired(row['id']),
      typeLabel: typeLabel,
      title: title,
      imageUrl: imageUrl,
      startDate: parseTimestampRequired(row['starts_at']),
      endDate: parseTimestampRequired(row['ends_at']),
      views: '0',
      clicks: '0',
      calls: '0',
      viewsChangePercent: 0,
      clicksChangePercent: 0,
      callsChangePercent: 0,
      autoRenew: parseBool(row['auto_renew']),
      planLabel: planData is Map ? parseString(planData['name']) : null,
    );
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
    return SupabaseFailureMapper.guard(() async {
      final planRes = await _client
          .from(SupabaseTables.boostPlans)
          .select('duration_weeks')
          .eq('id', planId)
          .maybeSingle();
      final durationWeeks = planRes != null
          ? parseInt(planRes['duration_weeks']) ?? 1
          : 1;
      final durationDays = durationWeeks * 7;
      final startsAt = DateTime.now();
      final endsAt = startsAt.add(Duration(days: durationDays));
      final payload = <String, dynamic>{
        'business_id': businessId,
        'boost_plan_id': planId,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'status': 'active',
        'auto_renew': autoRenew,
      };
      if (optionType == 'deal') payload['deal_id'] = selectedId;
      if (optionType == 'job') payload['job_id'] = selectedId;
      await _client.from(SupabaseTables.boosts).insert(payload);
    });
  }

  @override
  Future<void> cancelBoost(String boostId, {String? reason}) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.boosts).update({
        'status': 'cancelled',
      }).eq('id', boostId);
    });
  }

  @override
  Future<void> setAutoRenew(String boostId, bool autoRenew) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.boosts).update({
        'auto_renew': autoRenew,
      }).eq('id', boostId);
    });
  }
}
