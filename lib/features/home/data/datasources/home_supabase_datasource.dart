import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
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

  @override
  Future<List<EventModel>> getHappeningThisWeek(String location) async {
    return SupabaseFailureMapper.guard(() async {
      final now = DateTime.now();
      final endOfWeek = now.add(const Duration(days: 7));
      var query = _client
          .from('events')
          .select('*')
          .eq('is_active', true)
          .gte('start_at', now.toIso8601String())
          .lte('start_at', endOfWeek.toIso8601String());
      // TODO: Add location filter when ready: query.or('venue_name.ilike.%$location%,venue_address.ilike.%$location%')
      final res = await query.order('start_at', ascending: true).limit(10);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final id = parseStringRequired(row['id']);
        final title = parseStringRequired(row['title']);
        final description = parseString(row['description']);
        final imageUrl = parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Event';
        final startAt = parseTimestampRequired(row['start_at']);
        final venue = parseString(row['venue_name']);
        final venueAddress = parseString(row['venue_address']);
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
  Future<List<DealModel>> getHotDealsNearYou(String location) async {
    return SupabaseFailureMapper.guard(() async {
      // Only deals from approved businesses
      final approvedBizRes = await _client
          .from('businesses')
          .select('id')
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      final approvedBizList = approvedBizRes as List;
      if (approvedBizList.isEmpty) return [];
      final approvedIds = approvedBizList.map((e) => (e as Map)['id']).whereType<String>().toList();
      if (approvedIds.isEmpty) return [];

      var query = _client
          .from('deals')
          .select('*, businesses!deals_business_id_fkey(id, name)')
          .eq('status', 'active')
          .gte('valid_until', DateTime.now().toIso8601String())
          .inFilter('business_id', approvedIds);
      // TODO: Add location filter when ready (filter businesses by address_city/address_state)
      final res = await query.order('valid_until', ascending: true).limit(10);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final biz = row['businesses'];
        String businessName = '';
        String businessId = parseStringRequired(row['business_id']);
        if (biz is Map<String, dynamic>) {
          businessName = parseStringRequired(biz['name']);
        }
        final discountPct = parseInt(row['discount_percentage']) ?? 0;
        return DealModel(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          description: parseStringRequired(row['description']),
          imageUrl: parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Deal',
          businessName: businessName,
          businessId: businessId,
          discountPercent: discountPct.toDouble(),
          promoCode: null,
          expiryDate: parseTimestamp(row['valid_until']),
        );
      }).toList();
    });
  }

  @override
  Future<List<BusinessModel>> getPopularBusinesses(String location) async {
    return SupabaseFailureMapper.guard(() async {
      var query = _client
          .from('businesses')
          .select('*')
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      // TODO: Add location filter when ready: query.or('address_city.ilike.%$location%,address_state.ilike.%$location%')
      final res = await query.order('rating', ascending: false).limit(10);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final category = parseString(row['description']) ?? parseString(row['address_city']) ?? 'Business';
        return BusinessModel(
          id: parseStringRequired(row['id']),
          name: parseStringRequired(row['name']),
          category: category.length > 30 ? '${category.substring(0, 30)}...' : category,
          imageUrl: parseString(row['logo_url']) ?? (parseStringList(row['image_urls']).isNotEmpty ? parseStringList(row['image_urls']).first : 'https://placehold.co/400x300?text=Business'),
          rating: parseDouble(row['rating']) ?? 0.0,
          reviewCount: parseInt(row['review_count']) ?? 0,
          distance: 0,
          priceRange: parseString(row['price_range']) ?? '\$',
          status: null,
          isVerified: parseBool(row['is_verified']),
        );
      }).toList();
    });
  }

  @override
  Future<List<JobModel>> getLatestJobs(String location) async {
    return SupabaseFailureMapper.guard(() async {
      // Only jobs from approved businesses
      var bizQuery = _client
          .from('businesses')
          .select('id')
          .eq('approval_status', 'approved')
          .eq('is_active', true);
      // TODO: Add location filter when ready: bizQuery.or('address_city.ilike.%$location%,address_state.ilike.%$location%')
      final bizRes = await bizQuery;
      final bizList = bizRes as List;
      if (bizList.isEmpty) return [];
      final ids = bizList.map((e) => (e as Map)['id']).whereType<String>().toList();
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
        return JobModel(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          companyName: companyName,
          companyId: companyId,
          jobType: parseStringRequired(row['job_type']),
          description: parseString(row['description']),
          location: parseString(row['location']),
          salary: parseString(row['salary_display']),
          postedDate: parseTimestamp(row['posted_at']),
        );
      }).toList();
    });
  }
}
