/// Push notification service (no-op when Firebase is not configured).
///
/// To enable push notifications:
/// 1. Add firebase_core and firebase_messaging to pubspec.yaml
/// 2. Add google-services.json (Android) and GoogleService-Info.plist (iOS)
/// 3. See docs/PUSH_NOTIFICATIONS_SETUP.md
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService _instance = PushNotificationService._();

  factory PushNotificationService() => _instance;

  /// No-op. Call when Firebase is configured to initialize FCM.
  Future<void> initialize() async {}

  /// No-op. Call after login to register FCM token in Supabase profiles.
  Future<void> registerTokenForUser(String userId) async {}

  /// No-op. Call on logout to clear token.
  Future<void> clearTokenForUser(String userId) async {}
}
