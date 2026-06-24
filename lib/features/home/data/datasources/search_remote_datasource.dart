import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/domain/normalized_location.dart';
import '../../../../core/location/geo_coordinates.dart';
import '../../../../core/location/geo_distance_miles.dart';
import '../../../../core/location/user_geo_for_feed.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/utils/job_type_format.dart';
import '../../domain/entities/business.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/job.dart';
import '../../domain/repositories/search_repository.dart';

abstract class SearchRemoteDataSource {
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location, {
    UserGeoForFeed? userGeo,
  });
  Future<List<String>> getTrendingSearches();
}

/// Supabase-backed search; replaces the previous stub that always returned empty lists.
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  SearchRemoteDataSourceImpl();

  SupabaseClient get _client => Supabase.instance.client;

  static const int _perTypeLimit = 30;

  String _sanitizeIlike(String raw) {
    return raw.replaceAll('%', '').trim();
  }

  @override
  Future<SearchResults> search(
    String query,
    SearchCategory category,
    String location, {
    UserGeoForFeed? userGeo,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final q = _sanitizeIlike(query);
      if (q.isEmpty) {
        return const SearchResults(events: [], businesses: [], jobs: []);
      }

      final events = <Event>[];
      final businesses = <Business>[];
      final jobs = <Job>[];

      Future<void> searchEvents() async {
        var rowQuery = _client
            .from('events')
            .select('*')
            .eq('is_active', true)
            .or('title.ilike.%$q%,description.ilike.%$q%,venue_name.ilike.%$q%')
            .order('start_at', ascending: true)
            .limit(_perTypeLimit);
        final res = await rowQuery;
        for (final row in (res as List).cast<Map<String, dynamic>>()) {
          final id = parseStringRequired(row['id']);
          final title = parseStringRequired(row['title']);
          final description = parseString(row['description']);
          final imageUrl = parseString(row['image_url']) ?? 'https://placehold.co/400x300?text=Event';
          final startAt = parseTimestampRequired(row['start_at']);
          final venue = parseString(row['venue_name']);
          final venueAddress = parseString(row['venue_address']);
          final locationStr = venueAddress ?? venue ?? '';
          events.add(Event(
            id: id,
            title: title,
            description: description,
            imageUrl: imageUrl,
            dateTime: startAt,
            location: locationStr,
            venue: venue,
            price: null,
            organizer: null,
          ));
        }
      }

      Future<void> searchBusinesses() async {
        Future<List<Map<String, dynamic>>> fetch(String select) async {
          final res = await _client
              .from('businesses')
              .select(select)
              .eq('approval_status', 'approved')
              .eq('is_active', true)
              .eq('is_verified', true)
              .or('name.ilike.%$q%,description.ilike.%$q%,address_city.ilike.%$q%')
              .order('rating', ascending: false)
              .limit(_perTypeLimit);
          return (res as List).cast<Map<String, dynamic>>();
        }

        late final List<Map<String, dynamic>> rows;
        try {
          rows = await fetch('*, ${SupabaseTables.locations}(*)');
        } on PostgrestException catch (e) {
          if (e.code == 'PGRST200' ||
              e.message.contains('could not find') ||
              e.message.contains('relationship') ||
              e.message.contains('locations')) {
            rows = await fetch('*');
          } else {
            rethrow;
          }
        }

        for (final row in rows) {
          final normalizedLocation =
              NormalizedLocation.maybeFromEmbedded(row[SupabaseTables.locations]);
          final categoryLabel = parseString(row['description']) ??
              normalizedLocation?.city ??
              parseString(row['address_city']) ??
              'Business';
          final coords = resolveListingCoordinates(
            location: normalizedLocation,
            businessRow: row,
          );
          final lat = coords?.lat;
          final lng = coords?.lng;
          final distance =
              distanceMilesFromGeo(userGeo, lat, lng) ?? double.nan;
          businesses.add(Business(
            id: parseStringRequired(row['id']),
            name: parseStringRequired(row['name']),
            category: categoryLabel.length > 30
                ? '${categoryLabel.substring(0, 30)}...'
                : categoryLabel,
            imageUrl: parseString(row['logo_url']) ??
                (parseStringList(row['image_urls']).isNotEmpty
                    ? parseStringList(row['image_urls']).first
                    : 'https://placehold.co/400x300?text=Business'),
            rating: parseDouble(row['rating']) ?? 0.0,
            reviewCount: parseInt(row['review_count']) ?? 0,
            distance: distance,
            priceRange: parseString(row['price_range']) ?? '\$',
            status: null,
            isVerified: parseBool(row['is_verified']),
            latitude: lat,
            longitude: lng,
          ));
        }
      }

      Future<void> searchJobs() async {
        final approvedBizRes = await _client
            .from('businesses')
            .select('id')
            .eq('approval_status', 'approved')
            .eq('is_active', true)
            .eq('is_verified', true);
        final approvedIds =
            (approvedBizRes as List).map((e) => (e as Map)['id']).whereType<String>().toList();
        if (approvedIds.isEmpty) return;

        final res = await _client
            .from('jobs')
            .select('*, businesses!jobs_business_id_fkey(id, name)')
            .eq('is_active', true)
            .inFilter('business_id', approvedIds)
            .or('title.ilike.%$q%,description.ilike.%$q%')
            .order('posted_at', ascending: false)
            .limit(_perTypeLimit);
        for (final row in (res as List).cast<Map<String, dynamic>>()) {
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
          jobs.add(Job(
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
          ));
        }
      }

      switch (category) {
        case SearchCategory.all:
          await Future.wait([searchEvents(), searchBusinesses(), searchJobs()]);
          break;
        case SearchCategory.events:
          await searchEvents();
          break;
        case SearchCategory.business:
          await searchBusinesses();
          break;
        case SearchCategory.jobs:
          await searchJobs();
          break;
      }

      return SearchResults(events: events, businesses: businesses, jobs: jobs);
    });
  }

  @override
  Future<List<String>> getTrendingSearches() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('events')
          .select('title')
          .eq('is_active', true)
          .gte('start_at', DateTime.now().toIso8601String())
          .order('start_at', ascending: true)
          .limit(8);
      final titles = (res as List)
          .map((e) => parseString((e as Map)['title']))
          .whereType<String>()
          .where((t) => t.isNotEmpty)
          .toSet()
          .toList();
      return titles;
    });
  }
}
