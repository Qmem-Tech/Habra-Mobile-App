import 'dart:io';

import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Default store links when admin has not set custom URLs.
abstract final class AppStoreLinks {
  static const playStore =
      'https://play.google.com/store/apps/details?id=com.habra.habra';
  static const appStore = 'https://apps.apple.com/app/habra/id000000000';
}

/// Reads minimum versions from `app_settings` (super admin) with fallback to
/// legacy `app_config`. Compares against the installed build via semver.
class AppVersionService {
  AppVersionService();

  final Logger _log = Logger();

  static const _settingsKeys = [
    'min_app_version_android',
    'min_app_version_ios',
    'force_update_message',
    'store_url_android',
    'store_url_ios',
  ];

  Future<AppVersionStatus> evaluate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _AppVersion.parse('${info.version}+${info.buildNumber}');

      final settings = await _fetchAppSettings();
      final isAndroid = Platform.isAndroid;
      final minRaw = isAndroid
          ? settings['min_app_version_android']
          : settings['min_app_version_ios'];
      final storeUrl = _firstNonEmpty([
        isAndroid ? settings['store_url_android'] : settings['store_url_ios'],
      ]);
      final message = settings['force_update_message'];

      var min = _AppVersion.tryParse(minRaw);
      var resolvedStore = storeUrl;
      _AppVersion? latest;

      if (min == null) {
        final legacy = await _fetchLegacyAppConfig(isAndroid);
        min = legacy.min;
        latest = legacy.latest;
        resolvedStore ??= legacy.storeUrl;
      }

      resolvedStore ??= isAndroid ? AppStoreLinks.playStore : AppStoreLinks.appStore;

      if (min != null && current.compareTo(min) < 0) {
        return AppVersionStatus.forceUpdate(
          current: current,
          required: min,
          storeUrl: resolvedStore,
          message: message?.isNotEmpty == true
              ? message
              : 'A newer version of Habra is required to continue. Please update to keep using the app.',
        );
      }
      if (latest != null && current.compareTo(latest) < 0) {
        return AppVersionStatus.recommended(
          current: current,
          recommended: latest,
          storeUrl: resolvedStore,
          message: message,
        );
      }
      return AppVersionStatus.ok(current: current);
    } catch (e, st) {
      _log.w(
        'AppVersionService.evaluate failed; allowing app to start: $e',
        stackTrace: st,
      );
      return const AppVersionStatus._(kind: AppVersionStatusKind.ok);
    }
  }

  Future<Map<String, String?>> _fetchAppSettings() async {
    final rows = await Supabase.instance.client
        .from('app_settings')
        .select('key, value')
        .inFilter('key', _settingsKeys);

    final out = <String, String?>{};
    for (final row in (rows as List)) {
      final key = row['key'] as String?;
      if (key == null) continue;
      out[key] = _settingString(row['value']);
    }
    return out;
  }

  Future<({ _AppVersion? min, _AppVersion? latest, String? storeUrl })>
      _fetchLegacyAppConfig(bool isAndroid) async {
    final res = await Supabase.instance.client
        .from('app_config')
        .select()
        .limit(1)
        .maybeSingle();
    if (res == null) {
      return (min: null, latest: null, storeUrl: null);
    }
    final row = Map<String, dynamic>.from(res as Map);
    final platform = isAndroid ? 'android' : 'ios';
    return (
      min: _AppVersion.tryParse(row['min_$platform']?.toString()),
      latest: _AppVersion.tryParse(row['latest_$platform']?.toString()),
      storeUrl: row['store_url_$platform']?.toString(),
    );
  }

  String? _firstNonEmpty(List<String?> values) {
    for (final v in values) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? _settingString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final t = value.trim();
      return t.isEmpty ? null : t;
    }
    if (value is num) return value.toString();
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}

enum AppVersionStatusKind { ok, recommended, forceUpdate }

class AppVersionStatus {
  const AppVersionStatus._({
    required this.kind,
    this.current,
    this.required,
    this.recommended,
    this.storeUrl,
    this.message,
  });

  const AppVersionStatus.ok({_AppVersion? current})
      : this._(kind: AppVersionStatusKind.ok, current: current);

  const AppVersionStatus.recommended({
    required _AppVersion current,
    required _AppVersion recommended,
    String? storeUrl,
    String? message,
  }) : this._(
          kind: AppVersionStatusKind.recommended,
          current: current,
          recommended: recommended,
          storeUrl: storeUrl,
          message: message,
        );

  const AppVersionStatus.forceUpdate({
    required _AppVersion current,
    required _AppVersion required,
    String? storeUrl,
    String? message,
  }) : this._(
          kind: AppVersionStatusKind.forceUpdate,
          current: current,
          required: required,
          storeUrl: storeUrl,
          message: message,
        );

  final AppVersionStatusKind kind;
  final _AppVersion? current;
  final _AppVersion? required;
  final _AppVersion? recommended;
  final String? storeUrl;
  final String? message;

  bool get mustUpdate => kind == AppVersionStatusKind.forceUpdate;
  bool get hasUpdate =>
      kind == AppVersionStatusKind.recommended || mustUpdate;
}

class _AppVersion implements Comparable<_AppVersion> {
  const _AppVersion(this.parts, this.build);

  factory _AppVersion.parse(String raw) {
    final v = _AppVersion.tryParse(raw);
    if (v == null) throw FormatException('Bad version: $raw');
    return v;
  }

  static _AppVersion? tryParse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final plus = trimmed.indexOf('+');
    final versionPart = plus < 0 ? trimmed : trimmed.substring(0, plus);
    final buildPart = plus < 0 ? '' : trimmed.substring(plus + 1);
    final parts = versionPart.split('.').map((s) {
      return int.tryParse(s.trim()) ?? 0;
    }).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return _AppVersion(parts, int.tryParse(buildPart.trim()) ?? 0);
  }

  final List<int> parts;
  final int build;

  @override
  int compareTo(_AppVersion other) {
    for (var i = 0; i < parts.length || i < other.parts.length; i++) {
      final a = i < parts.length ? parts[i] : 0;
      final b = i < other.parts.length ? other.parts[i] : 0;
      if (a != b) return a.compareTo(b);
    }
    return build.compareTo(other.build);
  }

  @override
  String toString() => '${parts.join('.')}+$build';
}
