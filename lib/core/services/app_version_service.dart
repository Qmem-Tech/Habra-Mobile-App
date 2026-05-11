import 'dart:io';

import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Pulls remote version requirements from the `app_config` table and compares
/// them against the installed build, so we can force the user to update before
/// they hit a broken API contract.
///
/// Schema expected (single row, `id = 1` by convention):
///
/// ```sql
/// create table public.app_config (
///   id            int primary key default 1,
///   min_android   text,            -- '1.2.0+34' or just '1.2.0'
///   min_ios       text,
///   latest_android text,
///   latest_ios    text,
///   store_url_android text,
///   store_url_ios     text,
///   message       text,            -- shown on the force-update page
///   updated_at    timestamptz default now()
/// );
/// alter table public.app_config enable row level security;
/// create policy "Anyone can read app_config" on public.app_config
///   for select using (true);
/// ```
///
/// The service degrades gracefully — if Supabase is unreachable or the table
/// doesn't exist, no update is required.
class AppVersionService {
  AppVersionService();

  final Logger _log = Logger();

  Future<AppVersionStatus> evaluate() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = _AppVersion.parse('${info.version}+${info.buildNumber}');

      final res = await Supabase.instance.client
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle();
      if (res == null) {
        return AppVersionStatus.ok(current: current);
      }
      final row = Map<String, dynamic>.from(res as Map);

      final platformKey = Platform.isAndroid ? 'android' : 'ios';
      final minRaw = row['min_$platformKey']?.toString();
      final latestRaw = row['latest_$platformKey']?.toString();
      final storeUrl = row['store_url_$platformKey']?.toString();
      final message = row['message']?.toString();

      final min = _AppVersion.tryParse(minRaw);
      final latest = _AppVersion.tryParse(latestRaw);

      if (min != null && current.compareTo(min) < 0) {
        return AppVersionStatus.forceUpdate(
          current: current,
          required: min,
          storeUrl: storeUrl,
          message: message ??
              'A newer version of Habra is required to continue. Please update to keep using the app.',
        );
      }
      if (latest != null && current.compareTo(latest) < 0) {
        return AppVersionStatus.recommended(
          current: current,
          recommended: latest,
          storeUrl: storeUrl,
          message: message,
        );
      }
      return AppVersionStatus.ok(current: current);
    } catch (e, st) {
      _log.w('AppVersionService.evaluate failed; allowing app to start: $e',
          stackTrace: st);
      return const AppVersionStatus._(kind: AppVersionStatusKind.ok);
    }
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

  /// Parses "1.2.0+34" or "1.2.0". Missing parts default to 0.
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
