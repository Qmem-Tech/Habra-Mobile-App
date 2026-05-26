import 'app_config.dart';

/// Column on `public.notifications` that stores the recipient (`profiles.id` / `auth.uid()`).
///
/// Default matches [habra_full_schema.sql](docs/supabase/habra_full_schema.sql). If Supabase
/// returns **column notifications.user_id does not exist**, your table likely uses another
/// name (e.g. `profile_id`): run the migration in
/// `docs/supabase/migrations/fix_notifications_recipient_column.sql`, **or** run the app with:
/// `flutter run --dart-define=NOTIFICATIONS_USER_ID_COLUMN=profile_id`
String get kNotificationsRecipientColumn => AppConfig.notificationsUserIdColumn;
