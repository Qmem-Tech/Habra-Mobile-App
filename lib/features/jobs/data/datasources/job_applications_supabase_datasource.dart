import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/job_application.dart';
import '../models/job_application_model.dart';
import 'job_applications_remote_datasource.dart';

/// Supabase implementation of [JobApplicationsRemoteDataSource].
class JobApplicationsSupabaseDataSource implements JobApplicationsRemoteDataSource {
  JobApplicationsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static ApplicationStatus _statusFromString(String? s) {
    if (s == null) return ApplicationStatus.pending;
    switch (s.toLowerCase()) {
      case 'reviewed':
        return ApplicationStatus.reviewed;
      case 'shortlisted':
        return ApplicationStatus.shortlisted;
      case 'rejected':
        return ApplicationStatus.rejected;
      case 'hired':
        return ApplicationStatus.hired;
      case 'accepted':
        return ApplicationStatus.accepted;
      default:
        return ApplicationStatus.pending;
    }
  }

  @override
  Future<JobApplication> submitApplication({
    required String jobId,
    required String fullName,
    required String email,
    required String phoneNumber,
    String? resumeUrl,
    String? coverLetter,
    Map<String, String>? screeningAnswers,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final jobRes = await _client.from('jobs').select('title, business_id').eq('id', jobId).maybeSingle();
      if (jobRes == null) throw Exception('Job not found');
      final jobRow = jobRes as Map;
      final bizId = parseString(jobRow['business_id']);
      final companyRes = bizId != null ? await _client.from('businesses').select('name').eq('id', bizId).maybeSingle() : null;
      final companyName = companyRes is Map<String, dynamic> ? parseStringRequired(companyRes['name']) : '';

      await _client.from('job_applications').insert({
        'job_id': jobId,
        'user_id': userId,
        'cover_message': coverLetter,
        'resume_url': resumeUrl,
        'status': 'pending',
      });

      final appRes = await _client
          .from('job_applications')
          .select('*')
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      if (appRes == null) {
        return JobApplicationModel(
          id: '',
          jobId: jobId,
          jobTitle: parseStringRequired(jobRow['title']),
          companyName: companyName,
          userId: userId,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          resumeUrl: resumeUrl,
          coverLetter: coverLetter,
          screeningAnswers: screeningAnswers ?? {},
          status: ApplicationStatus.pending,
          appliedDate: DateTime.now(),
        );
      }
      final row = Map<String, dynamic>.from(appRes as Map);
      return JobApplicationModel(
        id: parseStringRequired(row['id']),
        jobId: jobId,
        jobTitle: parseStringRequired(jobRow['title']),
        companyName: companyName,
        userId: userId,
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        resumeUrl: parseString(row['resume_url']),
        coverLetter: parseString(row['cover_message']),
        screeningAnswers: screeningAnswers ?? {},
        status: _statusFromString(row['status'] as String?),
        appliedDate: parseTimestampRequired(row['created_at']),
      );
    });
  }

  @override
  Future<List<JobApplication>> getApplications({bool activeOnly = false}) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return <JobApplication>[];

      var query = _client
          .from('job_applications')
          .select('*, jobs!job_applications_job_id_fkey(title, business_id), businesses!jobs_business_id_fkey(name)')
          .eq('user_id', userId);
      if (activeOnly) {
        query = query.inFilter('status', ['pending', 'reviewed', 'shortlisted']);
      }
      final res = await query.order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final jobRow = row['jobs'];
        final bizRow = jobRow is Map<String, dynamic> ? jobRow['businesses'] : null;
        final companyName = bizRow is Map<String, dynamic> ? parseStringRequired(bizRow['name']) : '';
        final jobTitle = jobRow is Map<String, dynamic> ? parseStringRequired(jobRow['title']) : '';
        return JobApplicationModel(
          id: parseStringRequired(row['id']),
          jobId: parseStringRequired(row['job_id']),
          jobTitle: jobTitle,
          companyName: companyName,
          userId: parseStringRequired(row['user_id']),
          fullName: '', // not in row; would need profiles join
          email: '',
          phoneNumber: '',
          resumeUrl: parseString(row['resume_url']),
          coverLetter: parseString(row['cover_message']),
          screeningAnswers: const {},
          status: _statusFromString(row['status'] as String?),
          appliedDate: parseTimestampRequired(row['created_at']),
        );
      }).toList();
    });
  }

  @override
  Future<JobApplication?> getApplicationForJob(String jobId) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final res = await _client
          .from('job_applications')
          .select('*, jobs(title, business_id)')
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      final row = Map<String, dynamic>.from(res as Map);
      final jobRow = row['jobs'];
      final companyName = ''; // would need businesses join
      return JobApplicationModel(
        id: parseStringRequired(row['id']),
        jobId: jobId,
        jobTitle: jobRow is Map<String, dynamic> ? parseStringRequired(jobRow['title']) : '',
        companyName: companyName,
        userId: parseStringRequired(row['user_id']),
        fullName: '',
        email: '',
        phoneNumber: '',
        resumeUrl: parseString(row['resume_url']),
        coverLetter: parseString(row['cover_message']),
        screeningAnswers: const {},
        status: _statusFromString(row['status'] as String?),
        appliedDate: parseTimestampRequired(row['created_at']),
      );
    });
  }
}
