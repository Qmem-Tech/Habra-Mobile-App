import '../config/app_config.dart';

/// Owner-facing support email (mailto from legal / verification banners).
/// Set in build: `--dart-define=SUPPORT_EMAIL=support@yourdomain.com` ([AppConfig]).
String get kSupportEmail => AppConfig.supportEmail;
