import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/supabase_tables.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/feedback_submission.dart';
import '../../domain/entities/feedback_ticket.dart';
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

      await _client.from(SupabaseTables.feedback).insert({
        'user_id': userId,
        'type': _typeToString(submission.type),
        'text': submission.text,
      });
    });
  }

  static FeedbackTicketStatus _statusFromString(String? s) {
    switch (s) {
      case 'in_progress':
        return FeedbackTicketStatus.inProgress;
      case 'resolved':
        return FeedbackTicketStatus.resolved;
      default:
        return FeedbackTicketStatus.open;
    }
  }

  static String _statusToString(FeedbackTicketStatus status) {
    switch (status) {
      case FeedbackTicketStatus.open:
        return 'open';
      case FeedbackTicketStatus.inProgress:
        return 'in_progress';
      case FeedbackTicketStatus.resolved:
        return 'resolved';
    }
  }

  FeedbackTicket _rowToTicket(Map<String, dynamic> row) {
    final profiles = row['profiles'];
    String? submitterName;
    String? submitterEmail;
    if (profiles is Map<String, dynamic>) {
      submitterName = parseString(profiles['full_name']);
      submitterEmail = parseString(profiles['email']);
    }
    return FeedbackTicket(
      id: parseStringRequired(row['id']),
      userId: parseStringRequired(row['user_id']),
      type: parseStringRequired(row['type']),
      text: parseStringRequired(row['text']),
      createdAt: parseTimestampRequired(row['created_at']),
      status: _statusFromString(parseString(row['status'])),
      adminNotes: parseString(row['admin_notes']),
      resolvedAt: parseTimestamp(row['resolved_at']),
      resolvedBy: parseString(row['resolved_by']),
      submitterName: submitterName,
      submitterEmail: submitterEmail,
    );
  }

  @override
  Future<List<FeedbackTicket>> listFeedbackForAdmin() async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from(SupabaseTables.feedback)
          .select(
            'id, user_id, type, text, created_at, status, admin_notes, resolved_at, resolved_by, '
            'profiles!feedback_user_id_fkey(full_name, email)',
          )
          .order('created_at', ascending: false);
      final list = (res as List).cast<Map<String, dynamic>>();
      return list.map(_rowToTicket).toList();
    });
  }

  @override
  Future<void> updateFeedbackAdmin({
    required String id,
    required FeedbackTicketStatus status,
    String? adminNotes,
  }) async {
    return SupabaseFailureMapper.guard(() async {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Not authenticated');

      final row = <String, dynamic>{
        'status': _statusToString(status),
        'admin_notes': adminNotes,
      };
      if (status == FeedbackTicketStatus.resolved) {
        row['resolved_at'] = DateTime.now().toUtc().toIso8601String();
        row['resolved_by'] = userId;
      } else {
        row['resolved_at'] = null;
        row['resolved_by'] = null;
      }

      await _client.from(SupabaseTables.feedback).update(row).eq('id', id);
    });
  }
}
