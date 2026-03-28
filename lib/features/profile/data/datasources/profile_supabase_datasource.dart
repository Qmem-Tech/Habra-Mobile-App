import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/supabase/supabase_failure_mapper.dart';
import '../../../../core/supabase/supabase_mappers.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import 'profile_remote_datasource.dart';

/// Profile CRUD via Supabase `profiles` table.
/// Expected columns: id, email, full_name, role, avatar_url (optional), phone (optional), bio (optional), city/location (optional).
class ProfileSupabaseDataSource implements ProfileRemoteDataSource {
  ProfileSupabaseDataSource();

  SupabaseClient get _client => Supabase.instance.client;

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
      return UserProfile(
        userId: parseStringRequired(row['id']),
        email: parseStringRequired(row['email']),
        fullName: parseStringRequired(row['full_name']),
        phone: parseString(row['phone']),
        bio: parseString(row['bio']),
        location: parseString(row['city']) ?? parseString(row['location']),
        avatarUrl: parseString(row['avatar_url']),
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
      if (update.bio != null) payload['bio'] = update.bio!;
      if (update.location != null) payload['city'] = update.location!;
      if (update.avatarUrl != null) payload['avatar_url'] = update.avatarUrl!;
      if (payload.isEmpty) return getProfile(userId);

      await _client.from('profiles').update(payload).eq('id', userId);
      return getProfile(userId);
    });
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
