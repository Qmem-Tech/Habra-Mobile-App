import 'package:supabase_flutter/supabase_flutter.dart';

/// After the user confirms email in a **browser** (e.g. laptop), the device may still hold a
/// stale JWT. Refresh loads the latest [User.emailConfirmedAt] from Supabase when a session exists.
Future<void> tryRefreshSupabaseSession() async {
  if (Supabase.instance.client.auth.currentSession == null) return;
  try {
    await Supabase.instance.client.auth.refreshSession();
  } catch (_) {}
}
