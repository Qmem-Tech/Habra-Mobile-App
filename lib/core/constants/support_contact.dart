/// Owner-facing support email (mailto from legal / verification banners).
/// Set in build: `--dart-define=SUPPORT_EMAIL=support@yourdomain.com`
const String kSupportEmail = String.fromEnvironment(
  'SUPPORT_EMAIL',
  defaultValue: '',
);
