/// RevenueCat **public (app-specific) SDK** keys for [Purchases.configure].
///
/// **This file is the only place** the Habra app reads these keys (`AppConfig` →
/// `main.dart` → `RevenueCatService.initialize`). Do not use `dart_defines.json`
/// for SDK keys — use this file instead.
///
/// Dashboard: **Project settings → API keys → Public / app-specific** per
/// platform (`goog_…` Android, `appl_…` iOS, or `test_…` Test Store). Never put
/// the **secret** API key in the app.
///
/// For a public Git repo, avoid committing real keys or use a private branch.
class RevenueCatSdkKeys {
  RevenueCatSdkKeys._();

  // static const String android = 'test_BFouWfPhlfrdJuMYNDYJFNqXgHG';
  static const String android = 'goog_eyaxJQGStKwWdjNMEmDGGHVlzDX';

  // static const String ios = 'test_BFouWfPhlfrdJuMYNDYJFNqXgHG';
  static const String ios = 'appl_KZMUwRipaJcODnyyLhcqLycQnuP';
}
