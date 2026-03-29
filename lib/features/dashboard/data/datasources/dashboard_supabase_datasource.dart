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

  // ---------------------------------------------------------------------------
  // Owner businesses
  // ---------------------------------------------------------------------------
  @override
  Future<List<BusinessPresence>> getOwnerBusinesses(String ownerId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businesses)
          .select('*')
          .eq('owner_id', ownerId)
          .order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map(_rowToPresence).toList();
    });
  }

  BusinessPresence _rowToPresence(Map<String, dynamic> row) {
    final logoUrl = parseString(row['logo_url']);
    final backgroundUrl = parseString(row['background_url']);
    final imageUrl = logoUrl ?? 'https://placehold.co/400x300?text=Business';
    return BusinessPresence(
      id: parseStringRequired(row['id']),
      name: parseStringRequired(row['name']),
      locationName: parseString(row['address_street']),
      category: parseString(row['description']) ?? 'Business',
      city: parseString(row['address_city']),
      state: parseString(row['address_state']),
      phone: parseString(row['phone']),
      email: parseString(row['email']),
      website: parseString(row['website']),
      imageUrl: imageUrl,
      logoUrl: logoUrl,
      backgroundUrl: backgroundUrl,
      isVerified: parseBool(row['is_verified']),
      isOpenNow: parseBool(row['is_active']),
      rating: parseDouble(row['rating']),
      reviewCount: parseInt(row['review_count']),
      statusText: parseString(row['approval_status']),
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

      return DashboardAnalytics(
        totalViewsFormatted: '0',
        viewsChangePercent: 0,
        clicksFormatted: '0',
        clicksChangePercent: 0,
        messagesFormatted: '0',
        messagesChangePercent: 0,
        viewsOverTime: const [],
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
      var query = _client
          .from(SupabaseTables.deals)
          .select('*, ${SupabaseTables.businesses}!deals_business_id_fkey(name)')
          .eq('business_id', businessId);
      if (status != null) {
        query = query.eq('status', _dealStatusToString(status));
      }
      final res = await query.order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
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
    final validUntil = parseTimestamp(row['valid_until']);
    final validFrom = parseTimestamp(row['valid_from']);
    String validity = '';
    if (validFrom != null && validUntil != null) {
      validity =
          '${validFrom.month}/${validFrom.day} - ${validUntil.month}/${validUntil.day}';
    }
    return DashboardDeal(
      id: parseStringRequired(row['id']),
      title: parseStringRequired(row['title']),
      description: parseStringRequired(row['description']),
      imageUrl: parseString(row['image_url']) ??
          'https://placehold.co/400x300?text=Deal',
      dealTypeLabel: '$discountPct% off',
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
      final res = await _client
          .from(SupabaseTables.jobs)
          .select('*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
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
      final res = await _client
          .from(SupabaseTables.reviews)
          .select('*, ${SupabaseTables.profiles}!reviews_user_id_fkey(full_name, avatar_url)')
          .eq('business_id', businessId)
          .order('created_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
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
          .select('*, ${SupabaseTables.profiles}!job_applications_user_id_fkey(full_name, avatar_url, email, phone), ${SupabaseTables.jobs}!job_applications_job_id_fkey(title)')
          .eq('id', applicantId)
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
      final profileEmail = profile is Map<String, dynamic>
          ? parseString(profile['email'])
          : parseString(row['email']);
      final profilePhone = profile is Map<String, dynamic>
          ? parseString(profile['phone'])
          : parseString(row['phone']);
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
        coverLetter: parseStringRequired(row['cover_message']),
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
  Future<List<BoostPlan>> getBoostPlans() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.boostPlans)
          .select('*')
          .eq('is_active', true)
          .order('price_cents', ascending: true);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        final priceCents = parseInt(row['price_cents']) ?? 0;
        final price = priceCents / 100.0;
        final durationWeeks = parseInt(row['duration_weeks']) ?? 1;
        return BoostPlan(
          id: parseStringRequired(row['id']),
          title: parseStringRequired(row['title']),
          description: parseString(row['description']) ?? '',
          priceFormatted: '\$${price.toStringAsFixed(2)}',
          durationWeeks: durationWeeks,
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
        'status': status,
      };
      payload.removeWhere((_, v) => v == null);
      final res = await _client
          .from(SupabaseTables.jobs)
          .insert(payload)
          .select('*, ${SupabaseTables.businesses}!jobs_business_id_fkey(name, logo_url)')
          .single();
      final row = Map<String, dynamic>.from(res);
      final biz = row[SupabaseTables.businesses];
      final statusStr = parseString(row['status']) ?? status;
      final jobStatus = statusStr == 'draft'
          ? DashboardJobStatus.draft
          : statusStr == 'closed'
              ? DashboardJobStatus.closed
              : DashboardJobStatus.open;
      return DashboardJob(
        id: parseStringRequired(row['id']),
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
      payload['approval_status'] = 'pending';
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
  @override
  Future<void> updateBusinessHours(
      String businessId, Map<String, dynamic> hours) async {
    return SupabaseFailureMapper.guard(() async {
      await _client.from(SupabaseTables.businesses).update({
        'opening_time': hours['opening_time'],
        'closing_time': hours['closing_time'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', businessId);
    });
  }

  // ---------------------------------------------------------------------------
  // Get business hours
  // ---------------------------------------------------------------------------
  @override
  Future<Map<String, String?>?> getBusinessHours(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businesses)
          .select('opening_time, closing_time')
          .eq('id', businessId)
          .maybeSingle();
      if (res == null) return null;
      final row = Map<String, dynamic>.from(res);
      final opening = row['opening_time']?.toString();
      final closing = row['closing_time']?.toString();
      return {
        'opening_time': _normalizeTime(opening),
        'closing_time': _normalizeTime(closing),
      };
    });
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
          .select('status, document_type, rejection_reason')
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
        final status = _legalDocumentRowStatus(row['status']);
        final type = parseString(row['document_type']) ?? '';
        types.add(type);
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
        if (type == 'business_license') {
          hasBusinessLicense = true;
          if (status == 'approved') businessLicenseApproved = true;
        }
        if (type == 'ein_proof') {
          hasEinProof = true;
          if (status == 'approved') einProofApproved = true;
        }
      }
      final hasLegacyDocPair = types.contains('doc_1') && types.contains('doc_2');
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

  @override
  Future<List<BusinessLegalDocument>> listBusinessLegalDocuments(String businessId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.businessLegalDocuments)
          .select(
            'id, business_id, document_type, file_url, file_name, status, uploaded_at, reviewed_at, rejection_reason',
          )
          .eq('business_id', businessId)
          .order('uploaded_at', ascending: false);
      final rows = (res as List).cast<Map<String, dynamic>>();
      return rows.map((row) {
        return BusinessLegalDocument(
          id: parseStringRequired(row['id']),
          businessId: parseStringRequired(row['business_id']),
          documentType: parseStringRequired(row['document_type']),
          fileUrl: parseStringRequired(row['file_url']),
          fileName: parseString(row['file_name']),
          status: parseStringRequired(row['status'], 'pending'),
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
  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}';
  }
}
