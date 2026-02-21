import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../domain/entities/feedback_submission.dart';
import '../models/feedback_submission_model.dart';
import 'feedback_remote_datasource.dart';

/// Submits feedback to Supabase `feedback` table.
/// Backend: table feedback (id, user_id, type, text, created_at).
class FeedbackSupabaseDataSource implements FeedbackRemoteDataSource {
  FeedbackSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  static String _typeToString(FeedbackType type) {
    switch (type) {
      case FeedbackType.positive:
        return 'positive';
      case FeedbackType.negative:
        return 'negative';
      case FeedbackType.bugReport:
        return 'bug_report';
      case FeedbackType.suggestion:
        return 'suggestion';
    }
  }

  @override
  Future<void> submitFeedback(FeedbackSubmissionModel submission) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      await _client.from('feedback').insert({
        'user_id': userId,
        'type': _typeToString(submission.type),
        'text': submission.text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }
}
