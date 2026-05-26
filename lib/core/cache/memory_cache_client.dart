import 'dart:convert';

import 'cache_client.dart';

/// In-memory cache with optional TTL per entry.
///
/// Used for categories, boost_plans, app_settings to avoid repeated Supabase
/// calls. Serializes via JSON for simplicity; use [get] / [set] with
/// List/Map primitives or ensure T is json-serializable.
class MemoryCacheClient implements CacheClient {
  MemoryCacheClient();

  final Map<String, _Entry> _store = {};

  @override
  Future<T?> get<T>(String key) async {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _store.remove(key);
      return null;
    }
    final decoded = jsonDecode(entry.json) as dynamic;
    return decoded as T;
  }

  @override
  Future<void> set<T>(String key, T value, {Duration? ttl}) async {
    final expiresAt =
        ttl != null ? DateTime.now().add(ttl) : null;
    final json = jsonEncode(value);
    _store[key] = _Entry(json: json, expiresAt: expiresAt);
  }

  @override
  Future<void> remove(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }
}

class _Entry {
  final String json;
  final DateTime? expiresAt;
  _Entry({required this.json, this.expiresAt});
}
