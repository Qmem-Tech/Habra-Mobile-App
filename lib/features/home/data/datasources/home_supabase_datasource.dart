import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/domain/normalized_location.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../../../../core/subscription/business_subscription_policy.dart';
import '../../../../core/subscription/business_subscription_tier.dart';
import '../../../../core/supabase/nearby_feed_rpc_helper.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/location/geo_distance_miles.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/utils/job_type_format.dart';
import '../../domain/home_feed_location.dart';
import '../models/business_model.dart';
import '../models/deal_model.dart';
import '../models/event_model.dart';
import '../models/job_model.dart';
import 'home_remote_datasource.dart';

/// Supabase implementation of [HomeRemoteDataSource].
/// Fetches events, deals, businesses, jobs from Supabase for the home feed.
class HomeSupabaseDataSource implements HomeRemoteDataSource {
  HomeSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static bool _isMissingLocationsRelationship(PostgrestException e) {
    final message = e.message.toLowerCase();
    return e.code == 'PGRST200' ||
        (message.contains('locations') &&
            (message.contains('schema cache') ||
                message.contains('could not find') ||
                message.contains('relationship')));
  }

  /// When [geo] is set, intersect with `habra_feed_nearby_business_ids` when possible.
  /// If RPC fails or returns empty, keeps full approved list (fallback).
  Future<List<String>> _approvedBusinessIdsForGeo(UserGeoForFeed? geo) async {
    final approvedBizRes = await _client
        .from('businesses')
        .select('id')
        .eq('approval_status', 'approved')
        .eq('is_active', true);
    final approvedBizList = approvedBizRes as List;
    if (approvedBizList.isEmpty) return [];
    var ids = approvedBizList
        .map((e) => (e as Map)['id'])
        .whereType<String>()
        .toList();
    if (ids.isEmpty || geo == null) return ids;

    final nearby = await NearbyFeedRpcHelper(_client).nearbyBusinessIds(geo);
    if (nearby == null || nearby.isEmpty) return ids;
    final set = nearby.toSet();
    final filtered = ids.where(set.contains).toList();
    return filtered.isEmpty ? ids : filtered;
  }

  @override
  Future<List<EventModel>> getHappeningThisWeek(HomeFeedLocation location) async {
    return SupabaseFailureMapper.guard(() async {
      final now = DateTime.now();
      final endOfWeek = now.add(const Duration(days: 7));

      Future<List<Map<String, dynamic>>> fetch(String select) async {
        var query = _client
            .from('events')
            .select(select)
            .eq('is_active', true)
            .gte('start_at', now.toIso8601String())
            .lte('start_at', endOfWeek.toIso8601String());

        final geo = location.geo;
        if (geo != null) {
          final eventIds = await NearbyFeedRpcHelper(_client).nearbyEventIds(geo);
          if (eventIds != null && eventIds.isNotEmpty) {
            query = query.inFilter('id', eventIds);
          }
        }

        final res = await query.order('start_at', ascending: true).limit(10);
        return (res as List).cast<Map<String, dynamic>>();
      }

      late final List<Map<String, dynamic>> list;
      try {
        list = await fetch('*, ${SupabaseTables.locations}(*)');
      } on PostgrestException catch (e) {
        if (_isMissingLocationsRelationship(e)) {
          list = await fetch('*');
        } else {
          rethrow;
        }
      }
      return list.map((row) {
        final id = parseStringRequired(row['id']);
        final title = parseStringRequired(row['title']);
        final description = parseString(row['description']);
        final imageUrl = parseString(row['image_url']) ??
            'https://placehold.co/400x300?text=Event';
        final startAt = parseTimestampRequired(row['start_at']);
        final normalizedLocation =
            NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
        final isOnline = parseBool(row['is_online']);
        final venue = isOnline
            ? 'Online'
            : (normalizedLocation?.name ?? parseString(row['venue_name']));
        final venueAddress = isOnline
            ? parseString(row['online_url'])
            : (normalizedLocation?.displayAddress.isNotEmpty == true
                ? normalizedLocation!.displayAddress
                : parseString(row['venue_address']));
        final locationStr = venueAddress ?? venue ?? '';
        return EventModel(
          id: id,
          title: title,
          description: description,
          imageUrl: imageUrl,
          dateTime: startAt,
          location: locationStr,
          venue: venue,
          price: null,
          organizer: null,
        );
      }).toList();
    });
  }

  @override
  Future<List<DealModel>> getHotDealsNearYou(HomeFeedLocation location) async {
    return SupabaseFailureMapper.guard(() async {
      final approvedIds = await _approvedBusinessIdsForGeo(location.geo);
      if (approvedIds.isEmpty) return [];

      var query = _client
          .from('deals')
          .select('*, businesses!deals_business_id_fkey(id, name, logo_url)')
          .eq('status', 'active')
          .gte('valid_until', DateTime.now().toIso8601String())
          .inFilter('business_id', approvedIds);
      final res = await query.order('valid_until', ascending: true).limit(10);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final biz = row['businesses'];
        String businessName = '';
        String businessId = parseStringRequired(row['business_id']);
        String? businessLogoUrl;
        if (biz is Map<String, dynamic>) {
          businessName = parseStringRequired(biz['name']);
          businessLogoUrl = parseString(biz['logo_url']);
        }
        final discountPct = parseInt(row['discount_percentage']) ?? 0;
        return DealModel(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          description: parseStringRequired(row['description']),
          imageUrl: parseString(row['image_url']) ??
              'https://placehold.co/400x300?text=Deal',
          businessName: businessName,
          businessId: businessId,
          businessLogoUrl: businessLogoUrl,
          discountPercent: discountPct.toDouble(),
          promoCode: null,
          expiryDate: parseTimestamp(row['valid_until']),
        );
      }).toList();
    });
  }

  @override
  Future<List<BusinessModel>> getPopularBusinesses(HomeFeedLocation location) async {
    return SupabaseFailureMapper.guard(() async {
      Future<List<Map<String, dynamic>>> fetch(String select) async {
        var query = _client
            .from('businesses')
            .select(select)
            .eq('approval_status', 'approved')
            .eq('is_active', true);

        final geo = location.geo;
        if (geo != null) {
          final nearby = await NearbyFeedRpcHelper(_client).nearbyBusinessIds(geo);
          if (nearby != null && nearby.isNotEmpty) {
            query = query.inFilter('id', nearby);
          }
        }

        final res = await query.order('rating', ascending: false).limit(10);
        return (res as List).cast<Map<String, dynamic>>();
      }

      late final List<Map<String, dynamic>> list;
      try {
        list = await fetch('*, ${SupabaseTables.locations}(*)');
      } on PostgrestException catch (e) {
        if (_isMissingLocationsRelationship(e)) {
          list = await fetch('*');
        } else {
          rethrow;
        }
      }
      return list.map((row) {
        final normalizedLocation =
            NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
        final category = parseString(row['description']) ??
            normalizedLocation?.city ??
            parseString(row['address_city']) ??
            'Business';
        final imageUrls = parseStringList(row['image_urls']);
        final logo = parseString(row['logo_url']);
        final cover = imageUrls.isNotEmpty
            ? imageUrls.first
            : parseString(row['cover_image_url']);
        final listImage = logo ??
            (imageUrls.isNotEmpty ? imageUrls.first : null) ??
            'https://placehold.co/400x300?text=Business';
        final lat = normalizedLocation?.latitude ?? parseDouble(row['latitude']);
        final lng = normalizedLocation?.longitude ?? parseDouble(row['longitude']);
        final tier = businessTierFromRaw(parseString(row['subscription_tier']));
        final subStatus = businessSubscriptionStatusFromRaw(
          parseString(row['subscription_status']),
        );
        final dist =
            distanceMilesFromGeo(location.geo, lat, lng) ?? 0.0;
        return BusinessModel(
          id: parseStringRequired(row['id']),
          name: parseStringRequired(row['name']),
          category: category.length > 30
              ? '${category.substring(0, 30)}...'
              : category,
          imageUrl: listImage,
          rating: parseDouble(row['rating']) ?? 0.0,
          reviewCount: parseInt(row['review_count']) ?? 0,
          distance: dist,
          priceRange: parseString(row['price_range']) ?? '\$',
          status: null,
          isVerified: parseBool(row['is_verified']) &&
              BusinessSubscriptionPolicy.canUseVerifiedBadge(tier),
          coverImageUrl: cover,
          logoUrl: logo,
          phoneNumber: parseString(row['phone_number']),
          latitude: lat,
          longitude: lng,
          subscriptionTier: tier,
          subscriptionStatus: subStatus,
        );
      }).toList()
        ..sort((a, b) {
          final weightB = BusinessSubscriptionPolicy.feedBoostWeight(
            b.subscriptionTier,
          );
          final weightA = BusinessSubscriptionPolicy.feedBoostWeight(
            a.subscriptionTier,
          );
          if (weightB != weightA) return weightB.compareTo(weightA);
          return b.rating.compareTo(a.rating);
        });
    });
  }

  @override
  Future<List<JobModel>> getLatestJobs(HomeFeedLocation location) async {
    return SupabaseFailureMapper.guard(() async {
      final ids = await _approvedBusinessIdsForGeo(location.geo);
      if (ids.isEmpty) return [];

      var query = _client
          .from('jobs')
          .select('*, businesses!jobs_business_id_fkey(id, name, logo_url)')
          .eq('is_active', true)
          .inFilter('business_id', ids);
      final res = await query.order('posted_at', ascending: false).limit(10);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final biz = row['businesses'];
        String companyName = '';
        String companyId = parseStringRequired(row['business_id']);
        if (biz is Map<String, dynamic>) {
          companyName = parseStringRequired(biz['name']);
        }
        final sal = parseString(row['salary_display']);
        final fromMinMax = jobSalaryLineFromMinMax(
          parseInt(row['salary_min']),
          parseInt(row['salary_max']),
          salaryType: parseString(row['salary_type']),
        );
        return JobModel(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          companyName: companyName,
          companyId: companyId,
          jobType: jobTypeFormatLabel(parseString(row['job_type'])),
          description: parseString(row['description']),
          location: parseString(row['location']),
          salary: (sal != null && sal.isNotEmpty) ? sal : (fromMinMax.isEmpty ? null : fromMinMax),
          postedDate: parseTimestamp(row['posted_at']),
          createdAt: parseTimestamp(row['created_at']),
          updatedAt: parseTimestamp(row['updated_at']),
        );
      }).toList();
    });
  }
}
