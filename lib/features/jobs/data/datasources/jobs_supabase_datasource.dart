import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../../core/utils/job_type_format.dart';
import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';
import '../models/job_listing_model.dart';
import 'jobs_remote_datasource.dart';

/// Supabase implementation of [JobsRemoteDataSource].
class JobsSupabaseDataSource implements JobsRemoteDataSource {
  JobsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  /// Strips `%` and trims so PostgREST `ilike` patterns stay predictable.
  static String _sanitizeIlike(String? raw) {
    if (raw == null) return '';
    return raw.replaceAll('%', '').trim();
  }

  static DateTime _startOfLocalDay(DateTime d) =>
      DateTime(d.year, d.month, d.day);

  /// Lower bound on `posted_at` for filter sheet date options ([JobFilters.dateRange]).
  static DateTime? _postedAtLowerBound(String? dateRange) {
    if (dateRange == null || dateRange.isEmpty) return null;
    if (dateRange == 'Anytime') return null;
    final now = DateTime.now();
    switch (dateRange) {
      case 'Today':
        return _startOfLocalDay(now);
      case 'Past 3 Days':
        return now.subtract(const Duration(days: 3));
      case 'Past Week':
        return now.subtract(const Duration(days: 7));
      default:
        return null;
    }
  }

  /// UI sends display labels (e.g. `Full-time`); DB stores slugs (`full-time`).
  static List<String> _jobTypeSlugsForFilter(List<String> labels) {
    final out = <String>{};
    for (final label in labels) {
      final slug = jobTypeNormalizeSlug(label);
      out.add(slug);
      if (slug == 'temporary') {
        out.add('internship');
      }
    }
    return out.toList();
  }

  @override
  Future<List<JobListing>> getJobs({
    String? location,
    JobFilters? filters,
    String? searchQuery,
    bool featuredOnly = false,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      List<String> bookmarkedJobIds = [];
      if (userId != null) {
        final bmRes = await _client.from('job_bookmarks').select('job_id').eq('user_id', userId);
        final bmList = bmRes as List;
        bookmarkedJobIds = bmList.map((e) => (e as Map)['job_id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      }

      // Only show jobs from approved businesses
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
          .from('jobs')
          .select('*, businesses!jobs_business_id_fkey(id, name, logo_url, address_city, address_state)')
          .eq('is_active', true)
          .inFilter('business_id', approvedIds);

      if (featuredOnly) query = query.eq('is_featured', true);
      // TODO: Add location filter when ready (filter by businesses in address_city/address_state)
      final q = _sanitizeIlike(searchQuery);
      if (q.isNotEmpty) {
        query = query.or(
          'title.ilike.%$q%,description.ilike.%$q%,location.ilike.%$q%,job_type.ilike.%$q%',
        );
      }
      final categories = filters?.categories;
      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('category', categories);
      }
      final jobTypes = filters?.jobTypes;
      if (jobTypes != null && jobTypes.isNotEmpty) {
        query = query.inFilter('job_type', _jobTypeSlugsForFilter(jobTypes));
      }
      final postedFrom = _postedAtLowerBound(filters?.dateRange);
      if (postedFrom != null) {
        query = query.gte('posted_at', postedFrom.toIso8601String());
      }

      final res = await query.order('posted_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final biz = row['businesses'];
        String companyName = '';
        String? companyLogoUrl;
        if (biz is Map<String, dynamic>) {
          companyName = parseStringRequired(biz['name']);
          companyLogoUrl = parseString(biz['logo_url']);
        }
        final id = parseStringRequired(row['id']);
        final sal = parseString(row['salary_display']);
        final fromMinMax = jobSalaryLineFromMinMax(
          parseInt(row['salary_min']),
          parseInt(row['salary_max']),
          salaryType: parseString(row['salary_type']),
        );
        final salaryLine = (sal != null && sal.isNotEmpty)
            ? sal
            : (fromMinMax.isEmpty ? null : fromMinMax);
        return JobListingModel(
          id: id,
          title: parseStringRequired(row['title']),
          companyName: companyName,
          companyLogoUrl: companyLogoUrl,
          jobType: parseStringRequired(row['job_type']),
          salary: salaryLine,
          location: parseString(row['location']),
          postedDate: parseTimestamp(row['posted_at']),
          category: parseString(row['category']),
          isFeatured: parseBool(row['is_featured']),
          isBookmarked: bookmarkedJobIds.contains(id),
        );
      }).toList();
    });
  }

  @override
  Future<JobDetail> getJobDetail(String jobId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('jobs')
          .select('*, businesses!jobs_business_id_fkey(id, name, logo_url, address_city, address_state, rating, approval_status)')
          .eq('id', jobId)
          .maybeSingle();
      if (res == null) throw Exception('Job not found');
      final row = Map<String, dynamic>.from(res as Map);
      final biz = row['businesses'];
      if (biz is Map<String, dynamic> && parseString(biz['approval_status']) != 'approved') {
        throw Exception('Job not found');
      }
      String companyName = '';
      String companyId = parseStringRequired(row['business_id']);
      String? companyLogoUrl;
      double? companyRating;
      if (biz is Map<String, dynamic>) {
        companyName = parseStringRequired(biz['name']);
        companyLogoUrl = parseString(biz['logo_url']);
        companyRating = parseDouble(biz['rating']);
      }
      final desc = parseString(row['description']);
      final reqList = desc != null && desc.isNotEmpty ? desc.split('\n').where((e) => e.trim().isNotEmpty).toList() : <String>[];
      final userId = _client.auth.currentUser?.id;
      bool bookmarked = false;
      if (userId != null) {
        final bm = await _client
            .from('job_bookmarks')
            .select('job_id')
            .eq('user_id', userId)
            .eq('job_id', parseStringRequired(row['id']))
            .maybeSingle();
        bookmarked = bm != null;
      }
      final sal = parseString(row['salary_display']);
      final fromMinMax = jobSalaryLineFromMinMax(
        parseInt(row['salary_min']),
        parseInt(row['salary_max']),
        salaryType: parseString(row['salary_type']),
      );
      final salaryLine = (sal != null && sal.isNotEmpty)
          ? sal
          : (fromMinMax.isEmpty ? null : fromMinMax);
      return JobDetail(
        id: parseStringRequired(row['id']),
        title: parseStringRequired(row['title']),
        companyName: companyName,
        companyId: companyId,
        companyLogoUrl: companyLogoUrl,
        companyRating: companyRating,
        jobType: parseStringRequired(row['job_type']),
        salary: salaryLine,
        location: parseString(row['location']),
        postedDate: parseTimestamp(row['posted_at']),
        description: desc,
        requirements: reqList,
        benefits: const [],
        category: parseString(row['category']),
        isFeatured: parseBool(row['is_featured']),
        isRemote: parseString(row['location'])?.toLowerCase().contains('remote') ?? false,
        latitude: null,
        longitude: null,
        isBookmarked: bookmarked,
      );
    });
  }

  @override
  Future<List<String>> getJobCategories() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client.from('jobs').select('category').eq('is_active', true);
      final set = <String>{};
      for (final row in res as List) {
        final c = (row as Map)['category'];
        if (c != null && c.toString().isNotEmpty) set.add(c.toString());
      }
      return set.toList()..sort();
    });
  }

  @override
  Future<List<String>> getJobTypes() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client.from('jobs').select('job_type').eq('is_active', true);
      final set = <String>{};
      for (final row in res as List) {
        final t = (row as Map)['job_type'];
        if (t != null && t.toString().isNotEmpty) set.add(t.toString());
      }
      return set.toList()..sort();
    });
  }

  @override
  Future<List<String>> getBookmarkedJobIds() async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <String>[];
      final res = await _client.from('job_bookmarks').select('job_id').eq('user_id', userId);
      return (res as List).map((e) => (e as Map)['job_id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    });
  }

  @override
  Future<Map<String, DateTime>> getBookmarkedJobSavedAtByJobId() async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <String, DateTime>{};
      final res = await _client
          .from('job_bookmarks')
          .select('job_id, created_at')
          .eq('user_id', userId);
      final map = <String, DateTime>{};
      for (final e in res as List) {
        final row = e as Map;
        final id = row['job_id']?.toString() ?? '';
        if (id.isEmpty) continue;
        final at = parseTimestamp(row['created_at']);
        if (at != null) map[id] = at;
      }
      return map;
    });
  }

  @override
  Future<void> toggleBookmark(String jobId, bool isBookmarked) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return;
      if (isBookmarked) {
        await _client.from('job_bookmarks').upsert({
          'user_id': userId,
          'job_id': jobId,
        });
      } else {
        await _client.from('job_bookmarks').delete().eq('user_id', userId).eq('job_id', jobId);
      }
    });
  }
}
