import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/models/legal_document_upload_result.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../../home/domain/entities/business_presence.dart';
import '../../domain/entities/applicant_detail.dart';
import '../../domain/entities/business_legal_document.dart';
import '../../domain/entities/boost_plan.dart';
import '../../domain/entities/business_review.dart';
import '../../domain/entities/dashboard_analytics.dart';
import '../../domain/entities/dashboard_deal.dart';
import '../../domain/entities/dashboard_job.dart';
import '../../domain/entities/job_applicant.dart';
import '../../domain/entities/owner_upcoming_event.dart';
import '../../domain/repositories/dashboard_repository.dart';
import 'dashboard_remote_datasource.dart';

class DashboardSupabaseDataSource implements DashboardRemoteDataSource {
  DashboardSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  /// Combines free-text cover message with structured screening answers for the detail UI.
  String _mergeCoverLetterAndScreening(
    dynamic coverMessage,
    dynamic screeningRaw,
  ) {
    final cover = (parseString(coverMessage) ?? '').trim();
    final screeningLines = <String>[];
    if (screeningRaw is Map) {
      screeningRaw.forEach((dynamic k, dynamic v) {
        screeningLines.add('$k: ${v ?? ''}');
      });
    }
    if (screeningLines.isEmpty) {
      return cover;
    }
    final block = 'Screening responses\n${screeningLines.join('\n')}';
    if (cover.isEmpty) return block;
    return '$cover\n\n$block';
  }

  // ---------------------------------------------------------------------------
  // Owner businesses
  // ---------------------------------------------------------------------------
  @override
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businesses)
          .select('*, ${SupabaseTables.businessCategories}(${SupabaseTables.categories}(name))')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map(_rowToPresence).toList();
    });
  }

  BusinessPresence _rowToPresence(Map<String, dynamic> row) {
    final logoUrl = parseString(row['logo_url']);
    final backgroundUrl = parseString(row['background_url']);
    final galleryUrls = parseStringList(row['image_urls']);
    final imageUrl = logoUrl ?? 'https://placehold.co/400x300?text=Business';

    String category = parseString(row['description']) ?? 'Business';
    final catLinks = row[SupabaseTables.businessCategories];
    if (catLinks is List && catLinks.isNotEmpty) {
      final firstLink = catLinks.first;
      if (firstLink is Map) {
        final catRow = firstLink[SupabaseTables.categories];
        if (catRow is Map) {
          final catName = parseString(catRow['name']);
          if (catName != null && catName.isNotEmpty) category = catName;
        }
      }
    }

    return BusinessPresence(
      id: parseStringRequired(row['id']),
      name: parseStringRequired(row['name']),
      locationName: parseString(row['address_street']),
      category: category,
      city: parseString(row['address_city']),
      state: parseString(row['address_state']),
      phone: parseString(row['phone']),
      email: parseString(row['email']),
      website: parseString(row['website']),
      imageUrl: imageUrl,
      logoUrl: logoUrl,
      backgroundUrl: backgroundUrl,
      imageUrls: galleryUrls,
      isVerified: parseBool(row['is_verified']),
      isOpenNow: parseBool(row['is_active']),
      rating: parseDouble(row['rating']),
      reviewCount: parseInt(row['review_count']),
      statusText: parseString(row['approval_status']),
    );
  }

  Future<List<String>> _currentOwnerBusinessIds() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return [];
    final res = await _client
        .from(SupabaseTables.businesses)
        .select('id')
        .eq('owner_id', uid);
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map((r) => parseStringRequired(r['id'])).toList();
  }

  /// True when PostgREST reports `jobs.status` is missing (older DBs use `is_active` only).
  bool _isMissingJobsStatusColumn(PostgrestException e) {
    final m = e.message.toLowerCase();
    if (!m.contains('status')) return false;
    return m.contains('does not exist') ||
        m.contains('schema cache') ||
        (m.contains('column') && m.contains('jobs'));
  }

  /// When `status` exists: only open/draft. When the column is absent, rows have no status → include.
  bool _jobRowEligibleForBoost(Map<String, dynamic> row) {
    final s = parseString(row['status']);
    if (s == null) return true;
    return s == 'open' || s == 'draft';
  }

  Future<List<Map<String, dynamic>>> _fetchJobsForOwnerBusinessIds(
    List<String> ids, {
    required bool filterStatusInQuery,
  }) async {
    List<dynamic> res;
    try {
      var query = _client
          .from(SupabaseTables.jobs)
          .select(
              '*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
          .inFilter('business_id', ids);
      if (filterStatusInQuery) {
        query = query.inFilter('status', ['open', 'draft']);
      }
      res = await query.order('created_at', ascending: false) as List;
    } on PostgrestException catch (e) {
      if (e.message.contains('could not find') ||
          e.message.contains('relationship') ||
          e.code == 'PGRST200') {
        var query = _client
            .from(SupabaseTables.jobs)
            .select()
            .inFilter('business_id', ids);
        if (filterStatusInQuery) {
          query = query.inFilter('status', ['open', 'draft']);
        }
        res = await query.order('created_at', ascending: false) as List;
      } else {
        rethrow;
      }
    }
    return res.cast<Map<String, dynamic>>();
  }

  // ---------------------------------------------------------------------------
  // Analytics
  // ---------------------------------------------------------------------------
  @override
  Future<DashboardAnalytics?> getAnalytics(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final dealCount = await _client
          .from(SupabaseTables.deals)
          .select('id')
          .eq('business_id', businessId)
          .eq('status', 'active');
      final jobCount = await _client
          .from(SupabaseTables.jobs)
          .select('id')
          .eq('business_id', businessId)
          .eq('is_active', true);
      final reviewRes = await _client
          .from(SupabaseTables.reviews)
          .select('rating')
          .eq('business_id', businessId);

      final dealsList = (dealCount as List);
      final jobsList = (jobCount as List);
      final reviewsList = (reviewRes as List).cast<Map<String, dynamic>>();

      double avgRating = 0;
      if (reviewsList.isNotEmpty) {
        final sum = reviewsList.fold<double>(
            0, (s, r) => s + (parseDouble(r['rating']) ?? 0));
        avgRating = sum / reviewsList.length;
      }

      final firstJobTitle = jobsList.isNotEmpty
          ? (await _client
                  .from(SupabaseTables.jobs)
                  .select('title')
                  .eq('business_id', businessId)
                  .eq('is_active', true)
                  .limit(1)
                  .maybeSingle()
              is Map<String, dynamic>
              ? parseString((await _client
                      .from(SupabaseTables.jobs)
                      .select('title')
                      .eq('business_id', businessId)
                      .eq('is_active', true)
                      .limit(1)
                      .maybeSingle() as Map?)?['title'])
              : null)
          : null;

      List<Map<String, dynamic>> viewRows = [];
      try {
        final cutoffUtc =
            DateTime.now().toUtc().subtract(const Duration(days: 16));
        final vr = await _client
            .from(SupabaseTables.businessListingViews)
            .select('created_at')
            .eq('business_id', businessId)
            .gte('created_at', cutoffUtc.toIso8601String());
        viewRows = (vr as List).cast<Map<String, dynamic>>();
      } catch (_) {
        viewRows = [];
      }

      final viewTimes = <DateTime>[];
      for (final row in viewRows) {
        final raw = row['created_at'];
        if (raw == null) continue;
        final parsed = DateTime.tryParse(raw.toString());
        if (parsed != null) {
          viewTimes.add(parsed.toLocal());
        }
      }

      final viewsSeries = _listingViewsLastSevenDays(viewTimes);
      final currentViews7 =
          viewsSeries.fold<int>(0, (sum, p) => sum + p.views);
      final previousViews7 = _sumPreviousSevenDays(viewTimes);
      final viewsTrend = _percentChange(currentViews7, previousViews7)
          .clamp(-999.0, 999.0)
          .toDouble();

      return DashboardAnalytics(
        totalViewsFormatted: _formatCompactMetric(currentViews7),
        viewsChangePercent: viewsTrend,
        clicksFormatted: '0',
        clicksChangePercent: 0,
        messagesFormatted: '0',
        messagesChangePercent: 0,
        viewsOverTime: viewsSeries,
        rating: avgRating > 0 ? avgRating : null,
        reviewCount: reviewsList.length,
        activeDealsCount: dealsList.length,
        activeJobsCount: jobsList.length,
        activeJobTitle: firstJobTitle,
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Deals
  // ---------------------------------------------------------------------------
  @override
  Future<List<DashboardDeal>> getDeals(String businessId,
      {DashboardDealStatus? status}) async {
    return SupabaseFailureMapper.guard(() async {
      List<dynamic> res;
      try {
        var query = _client
            .from(SupabaseTables.deals)
            .select(
                '*, ${SupabaseTables.businesses}!deals_business_id_fkey(name)')
            .eq('business_id', businessId);
        if (status != null) {
          query = query.eq('status', _dealStatusToString(status));
        }
        res = await query.order('created_at', ascending: false) as List;
      } on PostgrestException catch (e) {
        if (e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.code == 'PGRST200') {
          var query = _client
              .from(SupabaseTables.deals)
              .select()
              .eq('business_id', businessId);
          if (status != null) {
            query = query.eq('status', _dealStatusToString(status));
          }
          res = await query.order('created_at', ascending: false) as List;
        } else {
          rethrow;
        }
      }
      final rows = res.cast<Map<String, dynamic>>();
      return rows.map(_rowToDashboardDeal).toList();
    });
  }

  static String _dealStatusToString(DashboardDealStatus s) {
    switch (s) {
      case DashboardDealStatus.active:
        return 'active';
      case DashboardDealStatus.expired:
        return 'expired';
      case DashboardDealStatus.draft:
        return 'draft';
      case DashboardDealStatus.inactive:
        return 'inactive';
    }
  }

  static DashboardDealStatus _dealStatusFromString(String? s) {
    switch (s) {
      case 'active':
        return DashboardDealStatus.active;
      case 'expired':
        return DashboardDealStatus.expired;
      case 'draft':
        return DashboardDealStatus.draft;
      case 'inactive':
        return DashboardDealStatus.inactive;
      default:
        return DashboardDealStatus.draft;
    }
  }

  DashboardDeal _rowToDashboardDeal(Map<String, dynamic> row) {
    final biz = row[SupabaseTables.businesses];
    final merchantName =
        biz is Map<String, dynamic> ? parseString(biz['name']) : null;
    final discountPct = parseInt(row['discount_percentage']) ?? 0;
    final discountedPrice = parseInt(row['discounted_price']);
    final dealCategory = parseString(row['category']);
    final validUntil = parseTimestamp(row['valid_until']);
    final validFrom = parseTimestamp(row['valid_from']);
    String validity = '';
    if (validFrom != null && validUntil != null) {
      validity =
          '${validFrom.month}/${validFrom.day} - ${validUntil.month}/${validUntil.day}';
    }
    final String dealTypeLabel;
    if (dealCategory == 'fixed_amount' &&
        discountedPrice != null &&
        discountedPrice > 0) {
      dealTypeLabel = '\$$discountedPrice off';
    } else if (dealCategory == 'free_item') {
      dealTypeLabel = 'Free item';
    } else {
      dealTypeLabel = '$discountPct% off';
    }
    return DashboardDeal(
      id: parseStringRequired(row['id']),
      businessId: parseStringRequired(row['business_id']),
      title: parseStringRequired(row['title']),
      description: parseStringRequired(row['description']),
      imageUrl: parseString(row['image_url']) ??
          'https://placehold.co/400x300?text=Deal',
      dealTypeLabel: dealTypeLabel,
      validityDescription: validity,
      redeemedCount: parseInt(row['redemption_count']) ?? 0,
      expiryDate: validUntil,
      status: _dealStatusFromString(parseString(row['status'])),
      merchantName: merchantName,
    );
  }

  // ---------------------------------------------------------------------------
  // Jobs
  // ---------------------------------------------------------------------------
  @override
  Future<List<DashboardJob>> getJobs(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      List<dynamic> res;
      try {
        res = await _client
            .from(SupabaseTables.jobs)
            .select('*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false) as List;
      } on PostgrestException catch (e) {
        if (e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.code == 'PGRST200') {
          res = await _client
              .from(SupabaseTables.jobs)
              .select()
              .eq('business_id', businessId)
              .order('created_at', ascending: false) as List;
        } else {
          rethrow;
        }
      }
      final rows = res.cast<Map<String, dynamic>>();
      final List<DashboardJob> result = [];
      for (final row in rows) {
        final jobId = parseStringRequired(row['id']);
        final appCount = await _client
            .from(SupabaseTables.jobApplications)
            .select('id')
            .eq('job_id', jobId);
        final applicants = (appCount as List).length;
        final biz = row[SupabaseTables.businesses];
        final employerName =
            biz is Map<String, dynamic> ? parseString(biz['name']) : null;
        final employerLogoUrl =
            biz is Map<String, dynamic> ? parseString(biz['logo_url']) : null;
        final postedAt = parseTimestamp(row['posted_at']) ??
            parseTimestamp(row['created_at']) ??
            DateTime.now();
        final salaryMin = parseInt(row['salary_min']);
        final salaryMax = parseInt(row['salary_max']);
        String salaryDisplay = '';
        if (salaryMin != null && salaryMax != null) {
          salaryDisplay = '\$$salaryMin - \$$salaryMax';
        } else if (salaryMin != null) {
          salaryDisplay = 'From \$$salaryMin';
        }
        final statusStr = parseString(row['status']) ?? 'open';
        final jobStatus = statusStr == 'draft'
            ? DashboardJobStatus.draft
            : statusStr == 'closed'
                ? DashboardJobStatus.closed
                : DashboardJobStatus.open;
        result.add(DashboardJob(
          id: jobId,
          businessId: parseStringRequired(row['business_id']),
          title: parseStringRequired(row['title']),
          jobType: parseStringRequired(row['job_type'], 'Full-time'),
          location: parseStringRequired(row['location'], 'Remote'),
          salaryDisplay: salaryDisplay,
          viewsCount: 0,
          applicantsCount: applicants,
          postedTimeAgo: _timeAgo(postedAt),
          employerName: employerName,
          employerLogoUrl: employerLogoUrl,
          status: jobStatus,
        ));
      }
      return result;
    });
  }

  @override
  Future<List<DashboardDeal>> getActiveDealsForCurrentOwner() async {
    return SupabaseFailureMapper.guard(() async {
      final ids = await _currentOwnerBusinessIds();
      if (ids.isEmpty) return [];
      List<dynamic> res;
      try {
        var query = _client
            .from(SupabaseTables.deals)
            .select(
                '*, ${SupabaseTables.businesses}!deals_business_id_fkey(name)')
            .inFilter('business_id', ids)
            .eq('status', _dealStatusToString(DashboardDealStatus.active));
        res = await query.order('created_at', ascending: false) as List;
      } on PostgrestException catch (e) {
        if (e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.code == 'PGRST200') {
          res = await _client
              .from(SupabaseTables.deals)
              .select()
              .inFilter('business_id', ids)
              .eq('status', _dealStatusToString(DashboardDealStatus.active))
              .order('created_at', ascending: false) as List;
        } else {
          rethrow;
        }
      }
      final rows = res.cast<Map<String, dynamic>>();
      return rows.map(_rowToDashboardDeal).toList();
    });
  }

  @override
  Future<List<DashboardJob>> getOpenJobsForCurrentOwner() async {
    return SupabaseFailureMapper.guard(() async {
      final ids = await _currentOwnerBusinessIds();
      if (ids.isEmpty) return [];
      List<Map<String, dynamic>> rows;
      try {
        rows =
            await _fetchJobsForOwnerBusinessIds(ids, filterStatusInQuery: true);
      } on PostgrestException catch (e) {
        if (_isMissingJobsStatusColumn(e)) {
          rows = await _fetchJobsForOwnerBusinessIds(
            ids,
            filterStatusInQuery: false,
          );
          rows = rows.where(_jobRowEligibleForBoost).toList();
        } else {
          rethrow;
        }
      }
      final List<DashboardJob> result = [];
      for (final row in rows) {
        final jobId = parseStringRequired(row['id']);
        final appCount = await _client
            .from(SupabaseTables.jobApplications)
            .select('id')
            .eq('job_id', jobId);
        final applicants = (appCount as List).length;
        final biz = row[SupabaseTables.businesses];
        final employerName =
            biz is Map<String, dynamic> ? parseString(biz['name']) : null;
        final employerLogoUrl =
            biz is Map<String, dynamic> ? parseString(biz['logo_url']) : null;
        final postedAt = parseTimestamp(row['posted_at']) ??
            parseTimestamp(row['created_at']) ??
            DateTime.now();
        final salaryMin = parseInt(row['salary_min']);
        final salaryMax = parseInt(row['salary_max']);
        String salaryDisplay = '';
        if (salaryMin != null && salaryMax != null) {
          salaryDisplay = '\$$salaryMin - \$$salaryMax';
        } else if (salaryMin != null) {
          salaryDisplay = 'From \$$salaryMin';
        }
        final statusStr = parseString(row['status']) ?? 'open';
        final jobStatus = statusStr == 'draft'
            ? DashboardJobStatus.draft
            : statusStr == 'closed'
                ? DashboardJobStatus.closed
                : DashboardJobStatus.open;
        result.add(DashboardJob(
          id: jobId,
          businessId: parseStringRequired(row['business_id']),
          title: parseStringRequired(row['title']),
          jobType: parseStringRequired(row['job_type'], 'Full-time'),
          location: parseStringRequired(row['location'], 'Remote'),
          salaryDisplay: salaryDisplay,
          viewsCount: 0,
          applicantsCount: applicants,
          postedTimeAgo: _timeAgo(postedAt),
          employerName: employerName,
          employerLogoUrl: employerLogoUrl,
          status: jobStatus,
        ));
      }
      return result;
    });
  }

  // ---------------------------------------------------------------------------
  // Reviews
  // ---------------------------------------------------------------------------
  @override
  Future<RatingOverview?> getReviewsOverview(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.reviews)
          .select('rating')
          .eq('business_id', businessId);
      final rows = (res as List).cast<Map<String, dynamic>>();
      if (rows.isEmpty) {
        return const RatingOverview(
            averageRating: 0, totalReviews: 0, distribution: {});
      }
      final dist = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
      double sum = 0;
      for (final r in rows) {
        final rating = (parseInt(r['rating']) ?? 5).clamp(1, 5);
        dist[rating] = (dist[rating] ?? 0) + 1;
        sum += rating;
      }
      return RatingOverview(
        averageRating: sum / rows.length,
        totalReviews: rows.length,
        distribution: dist,
      );
    });
  }

  @override
  Future<List<BusinessReview>> getReviews(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      List<dynamic> res;
      try {
        res = await _client
            .from(SupabaseTables.reviews)
            .select(
                '*, ${SupabaseTables.profiles}!reviews_user_id_fkey(full_name, avatar_url)')
            .eq('business_id', businessId)
            .order('created_at', ascending: false) as List;
      } on PostgrestException catch (e) {
        if (e.message.contains('could not find') ||
            e.message.contains('relationship') ||
            e.code == 'PGRST200') {
          res = await _client
              .from(SupabaseTables.reviews)
              .select()
              .eq('business_id', businessId)
              .order('created_at', ascending: false) as List;
        } else {
          rethrow;
        }
      }
      final rows = res.cast<Map<String, dynamic>>();
      return rows.map((row) {
        final profile = row[SupabaseTables.profiles];
        final authorName = profile is Map<String, dynamic>
            ? parseStringRequired(profile['full_name'], 'Anonymous')
            : 'Anonymous';
        final authorImg = profile is Map<String, dynamic>
            ? parseString(profile['avatar_url'])
            : null;
        final createdAt = parseTimestampRequired(row['created_at']);
        return BusinessReview(
          id: parseStringRequired(row['id']),
          authorName: authorName,
          authorImageUrl: authorImg,
          rating: parseInt(row['rating']) ?? 5,
          text: parseStringRequired(row['comment']),
          timeAgo: _timeAgo(createdAt),
          responseText: parseString(row['reply_text']),
          responseTimeAgo: row['replied_at'] != null
              ? _timeAgo(parseTimestampRequired(row['replied_at']))
              : null,
        );
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Applicants
  // ---------------------------------------------------------------------------
  @override
  Future<List<JobApplicant>> getApplicants(String jobId,
      {ApplicantStatus? status}) async {
    return SupabaseFailureMapper.guard(() async {
      var query = _client
          .from(SupabaseTables.jobApplications)
          .select('*, ${SupabaseTables.profiles}!job_applications_user_id_fkey(full_name, avatar_url)')
          .eq('job_id', jobId);
      if (status != null) {
        final statusStr =
            status == ApplicantStatus.reviewed ? 'reviewed' : 'pending';
        query = query.eq('status', statusStr);
      }
      final res = await query.order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final profile = row[SupabaseTables.profiles];
        final name = profile is Map<String, dynamic>
            ? parseStringRequired(profile['full_name'], 'Applicant')
            : 'Applicant';
        final createdAt = parseTimestampRequired(row['created_at']);
        final statusStr = parseString(row['status']) ?? 'pending';
        return JobApplicant(
          id: parseStringRequired(row['id']),
          name: name,
          location: '',
          timeAgo: _timeAgo(createdAt),
          bioSnippet: parseString(row['cover_message']),
          status: statusStr == 'reviewed'
              ? ApplicantStatus.reviewed
              : ApplicantStatus.newApplicant,
        );
      }).toList();
    });
  }

  @override
  Future<ApplicantDetail?> getApplicantDetail(
      String applicantId, String jobId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.jobApplications)
          .select(
            '*, ${SupabaseTables.profiles}!job_applications_user_id_fkey(full_name, avatar_url), ${SupabaseTables.jobs}!job_applications_job_id_fkey(title)',
          )
          .eq('id', applicantId)
          .eq('job_id', jobId)
          .maybeSingle();
      if (res == null) return null;
      final row = Map<String, dynamic>.from(res);
      final profile = row[SupabaseTables.profiles];
      final job = row[SupabaseTables.jobs];
      final profileName = profile is Map<String, dynamic>
          ? parseStringRequired(profile['full_name'], 'Applicant')
          : parseString(row['full_name']) ?? 'Applicant';
      final profileImg = profile is Map<String, dynamic>
          ? parseString(profile['avatar_url'])
          : null;
      final appPhoto = parseString(row['photo_url']);
      // Prefer columns on job_applications (apply form); profiles may omit email/phone.
      final profileEmail = parseString(row['email']) ??
          (profile is Map<String, dynamic> ? parseString(profile['email']) : null);
      final profilePhone = parseString(row['phone']) ??
          (profile is Map<String, dynamic> ? parseString(profile['phone']) : null);
      return ApplicantDetail(
        id: parseStringRequired(row['id']),
        name: profileName,
        profileImageUrl: appPhoto ?? profileImg,
        applicationPhotoUrl: appPhoto,
        email: profileEmail,
        phone: profilePhone,
        location: '',
        appliedFor:
            job is Map<String, dynamic> ? parseStringRequired(job['title']) : '',
        receivedDate: _timeAgo(parseTimestampRequired(row['created_at'])),
        coverLetter: _mergeCoverLetterAndScreening(
          row['cover_message'],
          row['screening_answers'],
        ),
        experience: const [],
        resumeFileName: parseString(row['resume_url']) != null
            ? 'Resume'
            : null,
        resumeFileUrl: parseString(row['resume_url']),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Boost plans
  // ---------------------------------------------------------------------------
  @override
  Future<List<BoostPlan>> getBoostPlans(String targetType) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.boostPlans)
          .select('*')
          .eq('is_active', true)
          .eq('target_type', targetType)
          .order('price_usd', ascending: true);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final priceUsd = parseDouble(row['price_usd']) ?? 0.0;
        final originalUsd = parseDouble(row['original_price_usd']);
        final durationWeeks = parseInt(row['duration_weeks']) ?? 1;
        String? originalPriceFormatted;
        if (originalUsd != null &&
            originalUsd > priceUsd + 0.009) {
          originalPriceFormatted = '\$${originalUsd.toStringAsFixed(2)}';
        }
        return BoostPlan(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          description: parseString(row['description']) ?? '',
          priceFormatted: '\$${priceUsd.toStringAsFixed(2)}',
          originalPriceFormatted: originalPriceFormatted,
          durationWeeks: durationWeeks,
          billingProductId: parseString(row['billing_product_id']),
        );
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Create Deal
  // ---------------------------------------------------------------------------
  @override
  Future<DashboardDeal> createDeal(
      String businessId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = <String, dynamic>{
        'business_id': businessId,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'discount_percentage': data['discount_percentage'],
        'original_price': data['original_price'],
        'discounted_price': data['discounted_price'],
        'valid_from': data['valid_from'],
        'valid_until': data['valid_until'],
        'image_url': data['image_url'],
        'category': data['category'],
        'status': data['status'] ?? 'draft',
      };
      payload.removeWhere((_, v) => v == null);
      final res = await _client
          .from(SupabaseTables.deals)
          .insert(payload)
          .select('*, ${SupabaseTables.businesses}!deals_business_id_fkey(name)')
          .single();
      return _rowToDashboardDeal(Map<String, dynamic>.from(res));
    });
  }

  // ---------------------------------------------------------------------------
  // Create Job
  // ---------------------------------------------------------------------------

  /// Columns that the app expects on `jobs` but may not exist yet.
  static final Set<String> _missingJobColumns = {};

  @override
  Future<DashboardJob> createJob(
      String businessId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final status = data['status'] as String? ?? 'open';
      final isDraft = status == 'draft';
      final payload = <String, dynamic>{
        'business_id': businessId,
        'title': data['title'] ?? '',
        'description': data['description'],
        'location': data['location'],
        'job_type': data['job_type'] ?? 'full-time',
        'salary_min': data['salary_min'],
        'salary_max': data['salary_max'],
        'is_active': !isDraft,
      };
      if (!_missingJobColumns.contains('status')) {
        payload['status'] = status;
      }
      payload.removeWhere((_, v) => v == null);

      Map<String, dynamic> row;
      try {
        row = Map<String, dynamic>.from(await _insertJob(payload));
      } on PostgrestException catch (e) {
        if (_stripMissingJobColumn(payload, e.message)) {
          row = Map<String, dynamic>.from(await _insertJob(payload));
        } else {
          rethrow;
        }
      }

      final biz = row[SupabaseTables.businesses];
      final statusStr = parseString(row['status']) ?? (isDraft ? 'draft' : 'open');
      final jobStatus = statusStr == 'draft'
          ? DashboardJobStatus.draft
          : statusStr == 'closed'
              ? DashboardJobStatus.closed
              : DashboardJobStatus.open;
      return DashboardJob(
        id: parseStringRequired(row['id']),
        businessId: parseStringRequired(row['business_id']),
        title: parseStringRequired(row['title']),
        jobType: parseStringRequired(row['job_type'], 'Full-time'),
        location: parseStringRequired(row['location'], 'Remote'),
        salaryDisplay: '',
        viewsCount: 0,
        applicantsCount: 0,
        postedTimeAgo: 'Just now',
        employerName:
            biz is Map<String, dynamic> ? parseString(biz['name']) : null,
        employerLogoUrl:
            biz is Map<String, dynamic> ? parseString(biz['logo_url']) : null,
        status: jobStatus,
      );
    });
  }

  Future<dynamic> _insertJob(Map<String, dynamic> payload) async {
    try {
      return await _client
          .from(SupabaseTables.jobs)
          .insert(payload)
          .select('*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
          .single();
    } on PostgrestException catch (e) {
      // FK hint may not match — retry with a bare select.
      if (e.message.contains('could not find') ||
          e.message.contains('relationship') ||
          e.code == 'PGRST200') {
        return await _client
            .from(SupabaseTables.jobs)
            .insert(payload)
            .select()
            .single();
      }
      rethrow;
    }
  }

  bool _stripMissingJobColumn(Map<String, dynamic> payload, String message) {
    final lower = message.toLowerCase();
    for (final col in ['status']) {
      if (lower.contains(col) && payload.containsKey(col)) {
        payload.remove(col);
        _missingJobColumns.add(col);
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Reply to review
  // ---------------------------------------------------------------------------
  @override
  Future<void> replyToReview(String reviewId, String replyText) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.reviews).update({
        'reply_text': replyText,
        'replied_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewId);
    });
  }

  // ---------------------------------------------------------------------------
  // Create business
  // ---------------------------------------------------------------------------
  @override
  Future<String> createBusiness(
      String ownerId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = Map<String, dynamic>.from(data);
      payload['owner_id'] = ownerId;
      if (!payload.containsKey('approval_status')) {
        payload['approval_status'] = 'pending';
      }
      payload['updated_at'] = DateTime.now().toIso8601String();
      final res = await _client
          .from(SupabaseTables.businesses)
          .insert(payload)
          .select('id')
          .single();
      final row = Map<String, dynamic>.from(res);
      return parseStringRequired(row['id']);
    });
  }

  @override
  Future<void> replaceBusinessCategoryLinks(
    String businessId,
    List<String> categoryIds,
  ) async {
    return SupabaseFailureMapper.guard(() async {
      await _client
          .from(SupabaseTables.businessCategories)
          .delete()
          .eq('business_id', businessId);
      final unique = categoryIds.where((e) => e.trim().isNotEmpty).toSet().toList();
      if (unique.isEmpty) return;
      await _client.from(SupabaseTables.businessCategories).insert(
            unique
                .map(
                  (id) => {
                    'business_id': businessId,
                    'category_id': id,
                  },
                )
                .toList(),
          );
    });
  }

  @override
  Future<List<String>> listCategoryIdsForBusiness(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businessCategories)
          .select('category_id')
          .eq('business_id', businessId);
      final list = res as List<dynamic>;
      final ids = <String>[];
      for (final row in list) {
        if (row is! Map) continue;
        final id = parseString(Map<String, dynamic>.from(row)['category_id']);
        if (id != null && id.isNotEmpty) ids.add(id);
      }
      return ids;
    });
  }

  // ---------------------------------------------------------------------------
  // Update business
  // ---------------------------------------------------------------------------
  @override
  Future<void> updateBusiness(
      String businessId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = Map<String, dynamic>.from(data);
      payload['updated_at'] = DateTime.now().toIso8601String();
      await _client
          .from(SupabaseTables.businesses)
          .update(payload)
          .eq('id', businessId);
    });
  }

  // ---------------------------------------------------------------------------
  // Update business hours
  // ---------------------------------------------------------------------------
  static final Set<String> _missingBusinessColumns = {};

  @override
  Future<void> updateBusinessHours(
      String businessId, Map<String, dynamic> hours) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = <String, dynamic>{
        'opening_time': hours['opening_time'],
        'closing_time': hours['closing_time'],
        'updated_at': DateTime.now().toIso8601String(),
      };
      final weekly = hours['weekly_hours'];
      if (weekly != null &&
          !_missingBusinessColumns.contains('weekly_hours')) {
        payload['weekly_hours'] = weekly;
      }
      try {
        await _client
            .from(SupabaseTables.businesses)
            .update(payload)
            .eq('id', businessId);
      } on PostgrestException catch (e) {
        if (_stripWeeklyHoursIfMissing(payload, e.message)) {
          await _client
              .from(SupabaseTables.businesses)
              .update(payload)
              .eq('id', businessId);
        } else {
          rethrow;
        }
      }
    });
  }

  bool _stripWeeklyHoursIfMissing(
    Map<String, dynamic> payload,
    String message,
  ) {
    final lower = message.toLowerCase();
    if (!payload.containsKey('weekly_hours')) return false;
    if (lower.contains('weekly_hours')) {
      payload.remove('weekly_hours');
      _missingBusinessColumns.add('weekly_hours');
      return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Get business hours
  // ---------------------------------------------------------------------------
  @override
  Future<Map<String, dynamic>?> getBusinessHours(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      Map<String, dynamic>? row;
      if (!_missingBusinessColumns.contains('weekly_hours')) {
        try {
          final res = await _client
              .from(SupabaseTables.businesses)
              .select('opening_time, closing_time, weekly_hours')
              .eq('id', businessId)
              .maybeSingle();
          if (res != null) {
            row = Map<String, dynamic>.from(res as Map);
          }
        } on PostgrestException catch (e) {
          if (_weeklyHoursSelectMissing(e.message)) {
            _missingBusinessColumns.add('weekly_hours');
          } else {
            rethrow;
          }
        }
      }
      row ??= await _getBusinessHoursLegacyRow(businessId);
      if (row == null) return null;
      final opening = row['opening_time']?.toString();
      final closing = row['closing_time']?.toString();
      final weeklyRaw = row['weekly_hours'];
      Map<String, dynamic>? weeklyMap;
      if (weeklyRaw is Map<String, dynamic>) {
        weeklyMap = weeklyRaw;
      } else if (weeklyRaw is Map) {
        weeklyMap = Map<String, dynamic>.from(weeklyRaw);
      }
      return {
        'opening_time': _normalizeTime(opening),
        'closing_time': _normalizeTime(closing),
        if (weeklyMap != null) 'weekly_hours': weeklyMap,
      };
    });
  }

  bool _weeklyHoursSelectMissing(String message) {
    final lower = message.toLowerCase();
    return lower.contains('weekly_hours') ||
        (lower.contains('column') && lower.contains('does not exist'));
  }

  Future<Map<String, dynamic>?> _getBusinessHoursLegacyRow(
      String businessId) async {
    final res = await _client
        .from(SupabaseTables.businesses)
        .select('opening_time, closing_time')
        .eq('id', businessId)
        .maybeSingle();
    if (res == null) return null;
    return Map<String, dynamic>.from(res as Map);
  }

  static String? _normalizeTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.isEmpty) return null;
    final h = parts[0].padLeft(2, '0');
    final m = parts.length > 1 ? parts[1].padLeft(2, '0') : '00';
    return '$h:$m';
  }

  // ---------------------------------------------------------------------------
  // Legal documents
  // ---------------------------------------------------------------------------
  @override
  Future<LegalDocumentsStatus> getLegalDocumentsStatus(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businessLegalDocuments)
          .select('status, review_status, document_type, rejection_reason')
          .eq('business_id', businessId);
      final rows = (res as List).cast<Map<String, dynamic>>();
      var approvedCount = 0;
      var hasRejected = false;
      var hasPendingRows = false;
      var hasBusinessLicense = false;
      var businessLicenseApproved = false;
      var hasEinProof = false;
      var einProofApproved = false;
      final types = <String>{};
      final rejectionReasons = <String>[];
      for (final row in rows) {
        final status = _legalDocumentStatusFromRow(row);
        final type = parseString(row['document_type']) ?? '';
        types.add(type);
        final typeKey = _normalizeLegalDocumentType(type);
        if (status == 'pending') hasPendingRows = true;
        if (status == 'approved') approvedCount++;
        if (status == 'rejected') {
          hasRejected = true;
          final reason = parseString(row['rejection_reason']);
          if (reason != null && reason.trim().isNotEmpty) {
            final trimmed = reason.trim();
            if (!rejectionReasons.contains(trimmed)) {
              rejectionReasons.add(trimmed);
            }
          }
        }
        if (typeKey == 'business_license') {
          hasBusinessLicense = true;
          if (status == 'approved') businessLicenseApproved = true;
        }
        if (typeKey == 'ein_proof') {
          hasEinProof = true;
          if (status == 'approved') einProofApproved = true;
        }
      }
      final normalizedTypes = types.map(_normalizeLegalDocumentType).toSet();
      final hasLegacyDocPair =
          normalizedTypes.contains('doc_1') && normalizedTypes.contains('doc_2');
      return LegalDocumentsStatus(
        uploadedCount: rows.length,
        approvedCount: approvedCount,
        hasRejected: hasRejected,
        hasBusinessLicense: hasBusinessLicense,
        businessLicenseApproved: businessLicenseApproved,
        hasEinProof: hasEinProof,
        einProofApproved: einProofApproved,
        hasLegacyDocPair: hasLegacyDocPair,
        hasPendingRows: hasPendingRows,
        rejectionReasons: rejectionReasons,
      );
    });
  }

  static String _legalDocumentRowStatus(dynamic value) =>
      (parseString(value) ?? '').trim().toLowerCase();

  /// Aligns mobile + admin consoles that may use `business-license`, `Business License`, etc.
  static String _normalizeLegalDocumentType(String? type) {
    final raw = (type ?? '').trim().toLowerCase();
    if (raw.isEmpty) return '';
    return raw.replaceAll('-', '_').replaceAll(' ', '_');
  }

  /// Prefers `review_status` when the column exists (Super Admin alignment).
  static String _legalDocumentStatusFromRow(Map<String, dynamic> row) {
    final r = _legalDocumentRowStatus(row['review_status']);
    if (r.isNotEmpty) return r;
    return _legalDocumentRowStatus(row['status']);
  }

  @override
  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businessLegalDocuments)
          .select(
            'id, business_id, document_type, file_url, file_name, status, review_status, uploaded_at, reviewed_at, rejection_reason',
          )
          .eq('business_id', businessId)
          .order('uploaded_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final status = _legalDocumentStatusFromRow(row);
        return BusinessLegalDocument(
          id: parseStringRequired(row['id']),
          businessId: parseStringRequired(row['business_id']),
          documentType: parseStringRequired(row['document_type']),
          fileUrl: parseStringRequired(row['file_url']),
          fileName: parseString(row['file_name']),
          status: status.isNotEmpty ? status : 'pending',
          uploadedAt: parseTimestamp(row['uploaded_at']),
          reviewedAt: parseTimestamp(row['reviewed_at']),
          rejectionReason: parseString(row['rejection_reason']),
        );
      }).toList();
    });
  }

  @override
  Future<void> uploadLegalDocument(
    String businessId,
    String documentType,
    LegalDocumentUploadResult upload, {
    String? fileName,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      // Remove any previously rejected row for the same business + type so the
      // rejection doesn't permanently lock the dashboard after re-submission.
      await _client
          .from(SupabaseTables.businessLegalDocuments)
          .delete()
          .eq('business_id', businessId)
          .eq('document_type', documentType)
          .eq('status', 'rejected');

      final row = <String, dynamic>{
        'business_id': businessId,
        'document_type': documentType,
        'file_url': upload.publicUrl,
        'storage_bucket': upload.storageBucket,
        'storage_path': upload.storagePath,
        'mime_type': upload.mimeType,
        'file_size_bytes': upload.fileSizeBytes,
        'file_name': fileName,
        'status': 'pending',
      };
      row.removeWhere((k, v) => v == null);
      await _client.from(SupabaseTables.businessLegalDocuments).insert(row);
    });
  }

  @override
  Future<void> deleteLegalDocument(String documentId) async {
    return SupabaseFailureMapper.guard(() async {
      await _client
          .from(SupabaseTables.businessLegalDocuments)
          .delete()
          .eq('id', documentId);
    });
  }

  @override
  Future<List<String>> getBusinessIdsNeedingLegalDocs(String ownerId) async {
    return SupabaseFailureMapper.guard(() async {
      final businesses = await _client
          .from(SupabaseTables.businesses)
          .select('id')
          .eq('owner_id', ownerId);
      final bizList = (businesses as List).cast<Map<String, dynamic>>();
      final ids = <String>[];
      for (final row in bizList) {
        final businessId = parseStringRequired(row['id']);
        final status = await getLegalDocumentsStatus(businessId);
        if (status.needsOwnerAction) {
          ids.add(businessId);
        }
      }
      return ids;
    });
  }

  @override
  Future<List<OwnerUpcomingEvent>> getOwnerUpcomingEvents(
    String ownerId, {
    String? businessId,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.events)
          .select('id,title,start_at,business_id')
          .eq('organizer_id', ownerId)
          .eq('is_active', true)
          .order('start_at', ascending: false)
          .limit(30);
      var rows = (res as List).cast<Map<String, dynamic>>();
      if (businessId != null) {
        rows = rows
            .where((row) =>
                row['business_id'] == null ||
                parseString(row['business_id']) == businessId)
            .toList();
      }
      return rows
          .map(
            (row) => OwnerUpcomingEvent(
              id: parseStringRequired(row['id']),
              title: parseStringRequired(row['title']),
              startAt: parseTimestampRequired(row['start_at']),
            ),
          )
          .take(10)
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static DateTime _dateOnlyLocal(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static String _weekdayShort(DateTime d) {
    const abbrev = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return abbrev[d.weekday - 1];
  }

  static List<DailyViewsPoint> _listingViewsLastSevenDays(
    List<DateTime> viewTimes,
  ) {
    final now = DateTime.now();
    final today = _dateOnlyLocal(now);
    final bucketStarts = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
    final counts = List<int>.filled(7, 0);
    for (final t in viewTimes) {
      final d = _dateOnlyLocal(t);
      for (var i = 0; i < 7; i++) {
        if (d == bucketStarts[i]) {
          counts[i]++;
          break;
        }
      }
    }
    return List.generate(
      7,
      (i) => DailyViewsPoint(
        dayLabel: _weekdayShort(bucketStarts[i]),
        views: counts[i],
      ),
    );
  }

  static int _sumPreviousSevenDays(List<DateTime> viewTimes) {
    final today = _dateOnlyLocal(DateTime.now());
    final prevEnd = today.subtract(const Duration(days: 7));
    final prevStart = today.subtract(const Duration(days: 13));
    var sum = 0;
    for (final t in viewTimes) {
      final d = _dateOnlyLocal(t);
      if (!d.isBefore(prevStart) && !d.isAfter(prevEnd)) {
        sum++;
      }
    }
    return sum;
  }

  static double _percentChange(int current, int previous) {
    if (previous <= 0) {
      return current > 0 ? 100 : 0;
    }
    return ((current - previous) / previous) * 100.0;
  }

  static String _formatCompactMetric(int n) {
    if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    }
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
