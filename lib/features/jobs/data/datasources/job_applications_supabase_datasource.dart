import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/application_experience_entry.dart';
import '../../domain/entities/job_application.dart';
import '../models/job_application_model.dart';
import 'job_applications_remote_datasource.dart';

const String _resumesBucket = 'resumes';

/// Supabase implementation of [JobApplicationsRemoteDataSource].
class JobApplicationsSupabaseDataSource implements JobApplicationsRemoteDataSource {
  JobApplicationsSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<String> uploadResume(String userId, String jobId, File file) async {
    return SupabaseFailureMapper.guard(() async {
      final ext = file.path.split('.').last.toLowerCase();
      if (!['pdf', 'doc', 'docx'].contains(ext)) {
        throw Exception('Please upload PDF, DOC, or DOCX (max 5MB)');
      }
      if (await file.length() > 5 * 1024 * 1024) {
        throw Exception('File must be under 5MB');
      }
      final path = '$userId/$jobId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from(_resumesBucket).upload(
            path,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return _client.storage.from(_resumesBucket).getPublicUrl(path);
    });
  }

  static Map<String, String> _screeningAnswersFromRow(dynamic v) {
    if (v == null) return {};
    if (v is Map<String, dynamic>) {
      return v.map((key, val) => MapEntry(key, val?.toString() ?? ''));
    }
    if (v is Map) {
      return v.map(
        (key, val) => MapEntry(key.toString(), val?.toString() ?? ''),
      );
    }
    return {};
  }

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
    String? photoUrl,
    Map<String, String>? screeningAnswers,
    List<ApplicationExperienceEntry>? workExperience,
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

      var insertPayload = <String, dynamic>{
        'job_id': jobId,
        'user_id': userId,
        'full_name': fullName,
        'email': email,
        'phone': phoneNumber,
        'cover_message': coverLetter,
        'resume_url': resumeUrl,
        'photo_url': photoUrl,
        'screening_answers': screeningAnswers ?? <String, String>{},
        'status': 'pending',
      };
      if (workExperience != null && workExperience.isNotEmpty) {
        insertPayload['experience'] =
            workExperience.map((e) => e.toJson()).toList();
      }
      try {
        await _client.from('job_applications').insert(insertPayload);
      } on PostgrestException catch (e) {
        final msg = e.message.toLowerCase();
        if (insertPayload.containsKey('experience') &&
            msg.contains('experience')) {
          insertPayload = Map<String, dynamic>.from(insertPayload)
            ..remove('experience');
          await _client.from('job_applications').insert(insertPayload);
        } else {
          rethrow;
        }
      }

      final appRes = await _client
          .from('job_applications')
          .select('*')
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final parsedAnswers =
          screeningAnswers ?? const <String, String>{};
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
          photoUrl: photoUrl,
          screeningAnswers: parsedAnswers,
          status: ApplicationStatus.pending,
          appliedDate: DateTime.now(),
        );
      }
      final row = Map<String, dynamic>.from(appRes as Map);
      final storedAnswers = _screeningAnswersFromRow(row['screening_answers']);
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
        photoUrl: parseString(row['photo_url']),
        screeningAnswers:
            storedAnswers.isNotEmpty ? storedAnswers : parsedAnswers,
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
          .select(
            '*, jobs!job_applications_job_id_fkey(title, business_id, businesses!jobs_business_id_fkey(name)), profiles!job_applications_user_id_fkey(full_name, avatar_url)',
          )
          .eq('user_id', userId);
      if (activeOnly) {
        query = query.inFilter('status', ['pending', 'reviewed', 'shortlisted']);
      }
      final res = await query.order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map((row) {
        final jobRow = row['jobs'];
        final bizRow = jobRow is Map<String, dynamic> ? jobRow['businesses'] : null;
        final profileRow = row['profiles'];
        final companyName = bizRow is Map<String, dynamic> ? parseStringRequired(bizRow['name']) : '';
        final jobTitle = jobRow is Map<String, dynamic> ? parseStringRequired(jobRow['title']) : '';
        final fullName = parseString(row['full_name']) ??
            (profileRow is Map<String, dynamic> ? parseString(profileRow['full_name']) : null) ??
            '';
        final email = parseString(row['email']) ??
            (profileRow is Map<String, dynamic> ? parseString(profileRow['email']) : null) ??
            '';
        final phone = parseString(row['phone']) ??
            (profileRow is Map<String, dynamic> ? parseString(profileRow['phone']) : null) ??
            '';
        return JobApplicationModel(
          id: parseStringRequired(row['id']),
          jobId: parseStringRequired(row['job_id']),
          jobTitle: jobTitle,
          companyName: companyName,
          userId: parseStringRequired(row['user_id']),
          fullName: fullName,
          email: email,
          phoneNumber: phone,
          resumeUrl: parseString(row['resume_url']),
          coverLetter: parseString(row['cover_message']),
          photoUrl: parseString(row['photo_url']),
          screeningAnswers: _screeningAnswersFromRow(row['screening_answers']),
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
          .select(
            '*, jobs!job_applications_job_id_fkey(title, business_id, businesses!jobs_business_id_fkey(name))',
          )
          .eq('job_id', jobId)
          .eq('user_id', userId)
          .maybeSingle();
      if (res == null) return null;
      final row = Map<String, dynamic>.from(res as Map);
      final jobRow = row['jobs'];
      final bizRow =
          jobRow is Map<String, dynamic> ? jobRow['businesses'] : null;
      final companyName = bizRow is Map<String, dynamic>
          ? parseStringRequired(bizRow['name'])
          : '';
      return JobApplicationModel(
        id: parseStringRequired(row['id']),
        jobId: jobId,
        jobTitle: jobRow is Map<String, dynamic> ? parseStringRequired(jobRow['title']) : '',
        companyName: companyName,
        userId: parseStringRequired(row['user_id']),
        fullName: parseString(row['full_name']) ?? '',
        email: parseString(row['email']) ?? '',
        phoneNumber: parseString(row['phone']) ?? '',
        resumeUrl: parseString(row['resume_url']),
        coverLetter: parseString(row['cover_message']),
        photoUrl: parseString(row['photo_url']),
        screeningAnswers: _screeningAnswersFromRow(row['screening_answers']),
        status: _statusFromString(row['status'] as String?),
        appliedDate: parseTimestampRequired(row['created_at']),
      );
    });
  }
}
