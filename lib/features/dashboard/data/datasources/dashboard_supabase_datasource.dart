import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/utils/job_type_format.dart';
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

  static String _formatReceivedOnLabel(DateTime dt) {
    return DateFormat.yMMMd().format(dt.toLocal());
  }

  static String _applicantExperiencePeriod(
    int startYear,
    int startMonth,
    int? endYear,
    int? endMonth,
    bool isCurrent,
  ) {
    final sm = startMonth.clamp(1, 12);
    final start = DateFormat('MMM yyyy').format(DateTime(startYear, sm));
    if (isCurrent) {
      return '$start – Present';
    }
    final ey = endYear ?? startYear;
    final em = (endMonth ?? 12).clamp(1, 12);
    final end = DateFormat('MMM yyyy').format(DateTime(ey, em));
    return '$start – $end';
  }

  static String _applicantExperienceDuration(
    int startYear,
    int startMonth,
    int? endYear,
    int? endMonth,
    bool isCurrent,
  ) {
    final now = DateTime.now();
    final sm = startMonth.clamp(1, 12);
    final em = isCurrent
        ? now.month
        : (endMonth ?? 12).clamp(1, 12);
    final ey = isCurrent ? now.year : (endYear ?? startYear);
    final startOrd = startYear * 12 + sm;
    final endOrd = ey * 12 + em;
    if (endOrd < startOrd) return '';
    final totalMonths = endOrd - startOrd + 1;
    final years = totalMonths ~/ 12;
    final months = totalMonths % 12;
    if (years == 0) {
      return months == 1 ? '1 mo' : '$months mos';
    }
    if (months == 0) {
      return years == 1 ? '1 yr' : '$years yrs';
    }
    final yPart = years == 1 ? '1 yr' : '$years yrs';
    final mPart = months == 1 ? '1 mo' : '$months mos';
    return '$yPart $mPart';
  }

  static List<ApplicantExperience> _applicantExperiencesFromRow(dynamic raw) {
    if (raw == null) return [];
    if (raw is! List) return [];
    final out = <ApplicantExperience>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final m = Map<String, dynamic>.from(item);
      final title = parseString(m['title'])?.trim() ?? '';
      final company = parseString(m['company'])?.trim() ?? '';
      if (title.isEmpty && company.isEmpty) continue;
      final sy = parseInt(m['start_year']);
      final sm = parseInt(m['start_month']);
      if (sy == null || sm == null) continue;
      final isCurrent = m['is_current'] == true;
      final ey = parseInt(m['end_year']);
      final em = parseInt(m['end_month']);
      final typeSlug = parseString(m['employment_type']);
      final employmentType = jobTypeFormatLabel(typeSlug);
      final period = _applicantExperiencePeriod(sy, sm, ey, em, isCurrent);
      final duration =
          _applicantExperienceDuration(sy, sm, ey, em, isCurrent);
      out.add(
        ApplicantExperience(
          title: title.isEmpty ? 'Role' : title,
          company: company.isEmpty ? 'Company' : company,
          employmentType: employmentType,
          period: period,
          duration: duration.isEmpty ? '—' : duration,
        ),
      );
    }
    return out;
  }

  static String? _resumeFileNameFromUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final u = Uri.parse(url.trim());
      if (u.pathSegments.isEmpty) return 'Resume';
      final last = u.pathSegments.last;
      if (last.isEmpty) return 'Resume';
      return last.split('?').first;
    } catch (_) {
      return 'Resume';
    }
  }

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

  DashboardJob _mapRowToDashboardJob(
    Map<String, dynamic> row, {
    required int applicantsCount,
    int viewsCount = 0,
  }) {
    final jobId = parseStringRequired(row['id']);
    final biz = row[SupabaseTables.businesses];
    final employerName =
        biz is Map<String, dynamic> ? parseString(biz['name']) : null;
    final employerLogoUrl =
        biz is Map<String, dynamic> ? parseString(biz['logo_url']) : null;
    final postedAt = parseTimestamp(row['posted_at']) ??
        parseTimestamp(row['created_at']) ??
        DateTime.now();
    final createdAt = parseTimestamp(row['created_at']);
    final updatedAt = parseTimestamp(row['updated_at']);
    final salaryMin = parseInt(row['salary_min']);
    final salaryMax = parseInt(row['salary_max']);
    final salaryDisplay =
        DashboardJob.salaryLineFromMinMax(salaryMin, salaryMax);
    final slug = DashboardJob.normalizeJobTypeSlug(parseString(row['job_type']));
    final statusStr = parseString(row['status']) ?? 'open';
    final jobStatus = statusStr == 'draft'
        ? DashboardJobStatus.draft
        : statusStr == 'closed'
            ? DashboardJobStatus.closed
            : DashboardJobStatus.open;
    final locRaw = parseString(row['location']);
    final bool isRemote;
    if (row.containsKey('is_remote') && row['is_remote'] != null) {
      isRemote = parseBool(row['is_remote']);
    } else {
      isRemote = locRaw != null && locRaw.toLowerCase().trim() == 'remote';
    }
    return DashboardJob(
      id: jobId,
      businessId: parseStringRequired(row['business_id']),
      title: parseStringRequired(row['title']),
      jobType: DashboardJob.formatJobTypeLabel(slug),
      jobTypeSlug: slug,
      location: parseStringRequired(row['location'], 'Remote'),
      salaryDisplay: salaryDisplay,
      salaryMin: salaryMin,
      salaryMax: salaryMax,
      description: parseString(row['description']),
      requirements: parseString(row['requirements']),
      isRemote: isRemote,
      salaryType: parseString(row['salary_type']),
      viewsCount: viewsCount,
      applicantsCount: applicantsCount,
      postedTimeAgo: _timeAgo(postedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      employerName: employerName,
      employerLogoUrl: employerLogoUrl,
      status: jobStatus,
    );
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
          if (status == DashboardDealStatus.active) {
            query = query.inFilter('status', ['active', 'inactive']);
          } else {
            query = query.eq('status', _dealStatusToString(status));
          }
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
            if (status == DashboardDealStatus.active) {
              query = query.inFilter('status', ['active', 'inactive']);
            } else {
              query = query.eq('status', _dealStatusToString(status));
            }
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
    final discountedPriceDouble = parseDouble(row['discounted_price']);
    final discountedPrice = discountedPriceDouble != null
        ? discountedPriceDouble.round()
        : parseInt(row['discounted_price']);
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
      category: dealCategory,
      discountPercentage: parseInt(row['discount_percentage']),
      discountedPrice: discountedPrice,
      validFrom: validFrom,
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
        result.add(_mapRowToDashboardJob(row, applicantsCount: applicants));
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
        result.add(_mapRowToDashboardJob(row, applicantsCount: applicants));
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
      final replyByReviewId =
          await _latestReviewRepliesByReviewIdForBusiness(businessId);
      return rows.map((row) {
        final profile = row[SupabaseTables.profiles];
        final authorName = profile is Map<String, dynamic>
            ? parseStringRequired(profile['full_name'], 'Anonymous')
            : 'Anonymous';
        final authorImg = profile is Map<String, dynamic>
            ? parseString(profile['avatar_url'])
            : null;
        final createdAt = parseTimestampRequired(row['created_at']);
        final reviewId = parseStringRequired(row['id']);
        final replyRow = replyByReviewId[reviewId];
        final replyFromTable = parseString(replyRow?['body']);
        final replyFromColumn = parseString(row['reply_text']);
        final repliedFromTable =
            replyRow != null ? parseTimestamp(replyRow['created_at']) : null;
        final repliedFromColumn = parseTimestamp(row['replied_at']);
        final String? responseText;
        final DateTime? repliedAt;
        if (replyFromTable != null && replyFromTable.isNotEmpty) {
          responseText = replyFromTable;
          repliedAt = repliedFromTable ?? repliedFromColumn;
        } else if (replyFromColumn != null && replyFromColumn.isNotEmpty) {
          responseText = replyFromColumn;
          repliedAt = repliedFromColumn ?? repliedFromTable;
        } else {
          responseText = null;
          repliedAt = null;
        }
        return BusinessReview(
          id: reviewId,
          authorName: authorName,
          authorImageUrl: authorImg,
          rating: parseInt(row['rating']) ?? 5,
          text: parseStringRequired(row['comment']),
          timeAgo: _timeAgo(createdAt),
          responseText: responseText,
          responseTimeAgo:
              repliedAt != null ? _timeAgo(repliedAt) : null,
        );
      }).toList();
    });
  }

  /// Latest owner reply per review from `review_replies` (canonical Habra schema).
  static bool _postgrestMissingReviewRepliesTable(PostgrestException e) {
    final lower = e.message.toLowerCase();
    if (!lower.contains('review_replies') &&
        !lower.contains('review replies')) {
      return false;
    }
    return lower.contains('does not exist') ||
        lower.contains('schema cache') ||
        lower.contains('could not find');
  }

  Future<Map<String, Map<String, dynamic>>> _latestReviewRepliesByReviewIdForBusiness(
    String businessId,
  ) async {
    try {
      final res = await _client
          .from(SupabaseTables.reviewReplies)
          .select('review_id, body, created_at')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      final out = <String, Map<String, dynamic>>{};
      for (final row in list) {
        final rid = parseString(row['review_id']);
        if (rid == null || rid.isEmpty) continue;
        out.putIfAbsent(rid, () => row);
      }
      return out;
    } on PostgrestException catch (e) {
      if (_postgrestMissingReviewRepliesTable(e)) {
        return {};
      }
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Applicants
  // ---------------------------------------------------------------------------
  static ApplicantStatus _applicantListStatusFromDb(String statusStr) {
    if (statusStr == 'pending') return ApplicantStatus.newApplicant;
    return ApplicantStatus.reviewed;
  }

  static String? _jobApplicationPipelineLabel(String statusStr) {
    switch (statusStr) {
      case 'shortlisted':
        return 'Interview Scheduled';
      case 'hired':
        return 'Hired';
      case 'rejected':
        return 'Not selected';
      case 'reviewed':
        return 'Reviewed';
      default:
        return null;
    }
  }

  @override
  Future<List<JobApplicant>> getApplicants(String jobId,
      {ApplicantStatus? status}) async {
    return SupabaseFailureMapper.guard(() async {
      var query = _client
          .from(SupabaseTables.jobApplications)
          .select('*, ${SupabaseTables.profiles}!job_applications_user_id_fkey(full_name, avatar_url)')
          .eq('job_id', jobId);
      if (status != null) {
        if (status == ApplicantStatus.newApplicant) {
          query = query.eq('status', 'pending');
        } else {
          query = query.neq('status', 'pending');
        }
      }
      final res = await query.order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final profile = row[SupabaseTables.profiles];
        final name = profile is Map<String, dynamic>
            ? parseStringRequired(profile['full_name'], 'Applicant')
            : 'Applicant';
        final createdAt = parseTimestampRequired(row['created_at']);
        final updatedAt = parseTimestamp(row['updated_at']);
        final statusStr = parseString(row['status']) ?? 'pending';
        final appPhoto = parseString(row['photo_url']);
        final profileAvatar = profile is Map<String, dynamic>
            ? parseString(profile['avatar_url'])
            : null;
        final avatarUrl = appPhoto ?? profileAvatar;
        return JobApplicant(
          id: parseStringRequired(row['id']),
          name: name,
          location: '',
          timeAgo: _timeAgo(createdAt),
          bioSnippet: parseString(row['cover_message']),
          avatarUrl: avatarUrl,
          status: _applicantListStatusFromDb(statusStr),
          statusLabel: _jobApplicationPipelineLabel(statusStr),
          statusTimeAgo: updatedAt != null ? _timeAgo(updatedAt) : null,
          rawStatus: statusStr,
        );
      }).toList();
    });
  }

  @override
  Future<void> markAllApplicantsReadForJob(String jobId) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.jobApplications).update({
        'status': 'reviewed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('job_id', jobId).eq('status', 'pending');
    });
  }

  @override
  Future<ApplicantDetail?> getApplicantDetail(
      String applicantId, String jobId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.jobApplications)
          .select(
            '*, ${SupabaseTables.profiles}!job_applications_user_id_fkey(full_name, avatar_url, email, phone), ${SupabaseTables.jobs}!job_applications_job_id_fkey(title)',
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
      final createdAt = parseTimestampRequired(row['created_at']);
      final resumeUrl = parseString(row['resume_url']);
      final statusStr = parseString(row['status']) ?? 'pending';
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
        receivedOnLabel: _formatReceivedOnLabel(createdAt),
        appliedAgo: _timeAgo(createdAt),
        applicationStatus: statusStr,
        coverLetter: _mergeCoverLetterAndScreening(
          row['cover_message'],
          row['screening_answers'],
        ),
        experience: _applicantExperiencesFromRow(row['experience']),
        resumeFileName: _resumeFileNameFromUrl(resumeUrl),
        resumeFileUrl: resumeUrl,
      );
    });
  }

  @override
  Future<void> updateJobApplicationStatus(
    String applicationId,
    String jobId,
    String status,
  ) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.jobApplications).update({
        'status': status,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', applicationId).eq('job_id', jobId);
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

  @override
  Future<DashboardDeal> updateDeal(
      String dealId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = Map<String, dynamic>.from(data);
      payload.remove('business_id');
      payload.removeWhere((_, v) => v == null);
      final res = await _client
          .from(SupabaseTables.deals)
          .update(payload)
          .eq('id', dealId)
          .select('*, ${SupabaseTables.businesses}!deals_business_id_fkey(name)')
          .single();
      return _rowToDashboardDeal(Map<String, dynamic>.from(res));
    });
  }

  @override
  Future<void> updateDealStatus(
      String dealId, DashboardDealStatus status) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.deals).update({
        'status': _dealStatusToString(status),
      }).eq('id', dealId);
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
        'requirements': data['requirements'],
        'is_remote': data['is_remote'],
        'salary_type': data['salary_type'],
        'is_active': !isDraft,
      };
      if (!_missingJobColumns.contains('status')) {
        payload['status'] = status;
      }
      payload.removeWhere((_, v) => v == null);

      Map<String, dynamic> row;
      while (true) {
        try {
          row = Map<String, dynamic>.from(await _insertJob(payload));
          break;
        } on PostgrestException catch (e) {
          if (!_stripMissingJobColumn(payload, e.message)) rethrow;
        }
      }

      return _mapRowToDashboardJob(row, applicantsCount: 0);
    });
  }

  @override
  Future<DashboardJob> updateJob(
      String jobId, Map<String, dynamic> data) async {
    return SupabaseFailureMapper.guard(() async {
      final payload = Map<String, dynamic>.from(data);
      payload.remove('business_id');
      final status = payload['status'] as String?;
      if (status != null) {
        payload['is_active'] = status != 'draft';
      }
      payload.removeWhere((_, v) => v == null);

      Map<String, dynamic> row;
      while (true) {
        try {
          row =
              Map<String, dynamic>.from(await _updateJobSelect(jobId, payload));
          break;
        } on PostgrestException catch (e) {
          if (!_stripMissingJobColumn(payload, e.message)) rethrow;
        }
      }

      final appRes = await _client
          .from(SupabaseTables.jobApplications)
          .select('id')
          .eq('job_id', jobId);
      final applicants = (appRes as List).length;
      return _mapRowToDashboardJob(row, applicantsCount: applicants);
    });
  }

  Future<dynamic> _updateJobSelect(
      String jobId, Map<String, dynamic> payload) async {
    try {
      return await _client
          .from(SupabaseTables.jobs)
          .update(payload)
          .eq('id', jobId)
          .select(
              '*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
          .single();
    } on PostgrestException catch (e) {
      if (e.message.contains('could not find') ||
          e.message.contains('relationship') ||
          e.code == 'PGRST200') {
        return await _client
            .from(SupabaseTables.jobs)
            .update(payload)
            .eq('id', jobId)
            .select()
            .single();
      }
      rethrow;
    }
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
    const cols = ['status', 'requirements', 'is_remote', 'salary_type'];
    for (final col in cols) {
      if (!payload.containsKey(col)) continue;
      if (!_jobPayloadErrorMentionsColumn(lower, col)) continue;
      payload.remove(col);
      _missingJobColumns.add(col);
      return true;
    }
    return false;
  }

  bool _jobPayloadErrorMentionsColumn(String lower, String col) {
    if (!lower.contains(col) && !lower.contains(col.replaceAll('_', ' '))) {
      return false;
    }
    return lower.contains('does not exist') ||
        lower.contains('schema cache') ||
        lower.contains('could not find') ||
        (lower.contains('column') && lower.contains('jobs'));
  }

  // ---------------------------------------------------------------------------
  // Reply to review
  // ---------------------------------------------------------------------------
  @override
  Future<void> replyToReview(String reviewId, String replyText) async {
    return SupabaseFailureMapper.guard(() async {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final reviewSnap = await _client
          .from(SupabaseTables.reviews)
          .select('business_id')
          .eq('id', reviewId)
          .maybeSingle();
      if (reviewSnap == null) {
        throw Exception('Review not found');
      }
      final businessId = parseStringRequired(
        Map<String, dynamic>.from(reviewSnap as Map)['business_id'],
      );

      var savedViaRepliesTable = false;
      try {
        await _upsertOwnerReplyInReviewReplies(
          reviewId: reviewId,
          businessId: businessId,
          replyText: replyText,
          timestampUtc: timestamp,
        );
        savedViaRepliesTable = true;
      } on PostgrestException catch (e) {
        if (!_postgrestMissingReviewRepliesTable(e)) {
          rethrow;
        }
      }

      var savedViaReviewColumns = false;
      PostgrestException? reviewColumnFailure;
      try {
        await _updateReviewsReplyColumns(reviewId, replyText, timestamp);
        savedViaReviewColumns = true;
      } on PostgrestException catch (e) {
        reviewColumnFailure = e;
      }

      if (!savedViaRepliesTable) {
        if (reviewColumnFailure != null) {
          throw reviewColumnFailure;
        }
        if (!savedViaReviewColumns) {
          throw Exception(
            'Could not save your reply. Add the review_replies table (or reply_text '
            'on reviews) and check RLS for business owners.',
          );
        }
      }
    });
  }

  Future<void> _upsertOwnerReplyInReviewReplies({
    required String reviewId,
    required String businessId,
    required String replyText,
    required String timestampUtc,
  }) async {
    final existing = await _client
        .from(SupabaseTables.reviewReplies)
        .select('id')
        .eq('review_id', reviewId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (existing != null) {
      final row = Map<String, dynamic>.from(existing as Map);
      final id = parseString(row['id']);
      if (id != null && id.isNotEmpty) {
        await _client.from(SupabaseTables.reviewReplies).update({
          'body': replyText,
          'created_at': timestampUtc,
        }).eq('id', id);
        return;
      }
    }
    await _client.from(SupabaseTables.reviewReplies).insert({
      'review_id': reviewId,
      'business_id': businessId,
      'body': replyText,
    });
  }

  Future<void> _updateReviewsReplyColumns(
    String reviewId,
    String replyText,
    String timestamp,
  ) async {
    var payload = <String, dynamic>{
      'reply_text': replyText,
      'replied_at': timestamp,
    };
    try {
      await _client
          .from(SupabaseTables.reviews)
          .update(payload)
          .eq('id', reviewId);
    } on PostgrestException catch (e) {
      final lower = e.message.toLowerCase();
      if (payload.containsKey('replied_at') && lower.contains('replied_at')) {
        payload = Map<String, dynamic>.from(payload)..remove('replied_at');
        await _client
            .from(SupabaseTables.reviews)
            .update(payload)
            .eq('id', reviewId);
      } else {
        rethrow;
      }
    }
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
