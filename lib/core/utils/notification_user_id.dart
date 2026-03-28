import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the Supabase auth user id for notification queries.
///
/// **API:** `notifications.user_id` is assumed to match `auth.users.id`.
/// Passing a placeholder (e.g. `'current_user'`) breaks the query; always prefer auth.
String? resolveNotificationUserId(String? passedFromCaller) {
  final authId = Supabase.instance.client.auth.currentUser?.id;
  if (authId != null && authId.isNotEmpty) {
    return authId;
  }
  final p = passedFromCaller?.trim();
  if (p != null && p.isNotEmpty && p != 'current_user') {
    return p;
  }
  return null;
}
