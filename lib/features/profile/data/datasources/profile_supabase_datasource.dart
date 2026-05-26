import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_remote_datasource.dart';

/// Profile CRUD via Supabase `profiles` table.
///
/// Core columns (always present): id, email, full_name, role, avatar_url, phone, created_at.
/// Optional columns the app can use: bio, city, interests.
/// Run `add_profiles_optional_columns.sql` to add any that are missing.
class ProfileSupabaseDataSource implements ProfileRemoteDataSource {
  ProfileSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

  /// Column names that failed a schema check and should be excluded from writes.
  static final Set<String> _missingColumns = {};

  /// Whether we've done the initial schema probe.
  static bool _schemaProbed = false;

  @override
  Future<UserProfile> getProfile(String userId) async {
    return SupabaseFailureMapper.guard(() async {
      final res = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (res == null) throw Exception('Profile not found');
      final row = Map<String, dynamic>.from(res as Map);

      if (!_schemaProbed) {
        _schemaProbed = true;
        for (final col in ['bio', 'city', 'interests']) {
          if (!row.containsKey(col)) _missingColumns.add(col);
        }
      }

      return UserProfile(
        userId: parseStringRequired(row['id']),
        email: parseStringRequired(row['email']),
        fullName: parseStringRequired(row['full_name']),
        phone: parseString(row['phone']),
        bio: row.containsKey('bio') ? parseString(row['bio']) : null,
        location: parseString(row['city']) ?? parseString(row['location']),
        avatarUrl: parseString(row['avatar_url']),
        interests: row.containsKey('interests')
            ? parseStringList(row['interests'])
            : const [],
        createdAt: parseTimestamp(row['created_at']),
      );
    });
  }

  @override
  Future<UserProfile> updateProfile(String userId, UserProfileUpdate update) async {
    return SupabaseFailureMapper.guard(() async {
      final Map<String, dynamic> payload = {};
      if (update.fullName != null) payload['full_name'] = update.fullName!;
      if (update.phone != null) payload['phone'] = update.phone!;
      if (update.avatarUrl != null) payload['avatar_url'] = update.avatarUrl!;

      if (update.location != null && !_missingColumns.contains('city')) {
        payload['city'] = update.location!;
      }
      if (update.bio != null && !_missingColumns.contains('bio')) {
        payload['bio'] = update.bio!;
      }
      if (update.interests != null && !_missingColumns.contains('interests')) {
        payload['interests'] = update.interests!;
      }

      if (payload.isEmpty) return getProfile(userId);

      try {
        await _client.from('profiles').update(payload).eq('id', userId);
      } on PostgrestException catch (e) {
        final stripped = _stripMissingColumns(payload, e.message);
        if (stripped) {
          if (payload.isNotEmpty) {
            await _client.from('profiles').update(payload).eq('id', userId);
          }
        } else {
          rethrow;
        }
      }
      return getProfile(userId);
    });
  }

  /// Inspects a Postgrest error message for column-not-found hints, removes
  /// the offending keys from [payload], and records them for future calls.
  /// Returns `true` if at least one column was stripped (retry is possible).
  bool _stripMissingColumns(Map<String, dynamic> payload, String message) {
    bool stripped = false;
    for (final col in ['bio', 'city', 'interests']) {
      if (payload.containsKey(col) && message.contains(col)) {
        _missingColumns.add(col);
        payload.remove(col);
        stripped = true;
      }
    }
    return stripped;
  }

  static const String _avatarsBucket = 'avatars';

  @override
  Future<String> uploadAvatar(String userId, File imageFile) async {
    return SupabaseFailureMapper.guard(() async {
      final path = '$userId/avatar.jpg';
      await _client.storage.from(_avatarsBucket).upload(
            path,
            imageFile,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _client.storage.from(_avatarsBucket).getPublicUrl(path);
      return url;
    });
  }
}
