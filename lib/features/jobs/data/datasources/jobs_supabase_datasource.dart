import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/job_detail.dart';
import '../../domain/entities/job_filters.dart';
import '../../domain/entities/job_listing.dart';
import '../models/job_listing_model.dart';
import 'jobs_remote_datasource.dart';

/// Supabase implementation of [JobsRemoteDataSource].
class JobsSupabaseDataSource implements JobsRemoteDataSource {
  JobsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

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
        if (bmRes is List) {
          bookmarkedJobIds = (bmRes as List).map((e) => (e as Map)['job_id']?.toString() ?? '').where((s) => s.isNotEmpty).toList();
        }
      }

      var query = _client
          .from('jobs')
          .select('*, businesses!jobs_business_id_fkey(id, name, logo_url, address_city, address_state)')
          .eq('is_active', true);

      if (featuredOnly) query = query.eq('is_featured', true);
      if (location != null && location.isNotEmpty) {
        final bizRes = await _client
            .from('businesses')
            .select('id')
            .eq('approval_status', 'approved')
            .or('address_city.ilike.%$location%,address_state.ilike.%$location%');
        if (bizRes is List && bizRes.isNotEmpty) {
          final ids = (bizRes as List).map((e) => (e as Map)['id']).whereType<String>().toList();
          if (ids.isNotEmpty) query = query.inFilter('business_id', ids);
        }
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }
      final categories = filters?.categories;
      if (categories != null && categories.isNotEmpty) {
        query = query.inFilter('category', categories);
      }
      final jobTypes = filters?.jobTypes;
      if (jobTypes != null && jobTypes.isNotEmpty) {
        query = query.inFilter('job_type', jobTypes);
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
        return JobListingModel(
          id: id,
          title: parseStringRequired(row['title']),
          companyName: companyName,
          companyLogoUrl: companyLogoUrl,
          jobType: parseStringRequired(row['job_type']),
          salary: parseString(row['salary_display']),
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
          .select('*, businesses!jobs_business_id_fkey(id, name, logo_url, address_city, address_state, rating)')
          .eq('id', jobId)
          .maybeSingle();
      if (res == null) throw Exception('Job not found');
      final row = Map<String, dynamic>.from(res as Map);
      final biz = row['businesses'];
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
      return JobDetail(
        id: parseStringRequired(row['id']),
        title: parseStringRequired(row['title']),
        companyName: companyName,
        companyId: companyId,
        companyLogoUrl: companyLogoUrl,
        companyRating: companyRating,
        jobType: parseStringRequired(row['job_type']),
        salary: parseString(row['salary_display']),
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
