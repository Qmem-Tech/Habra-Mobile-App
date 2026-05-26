/// Abstract cache client for static/semi-static data (e.g. categories, boost plans).
///
/// Implementations can be in-memory (with TTL) or persistent.
abstract class CacheClient {
  /// Gets a value by key. Returns null if missing or expired.
  Future<T?> get<T>(String key);

  /// Sets a value with optional [ttl]. [ttl] null means no expiry.
  Future<void> set<T>(String key, T value, {Duration? ttl});

  /// Removes a key.
  Future<void> remove(String key);

  /// Clears all entries (optional; in-memory only).
  Future<void> clear();
}
