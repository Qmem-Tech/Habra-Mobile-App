/// Shared helpers for mapping Supabase row data to app types.
library;

/// Parses optional ISO8601 timestamp from [value].
DateTime? parseTimestamp(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

/// Parses required ISO8601 timestamp; returns [DateTime.now()] if invalid.
DateTime parseTimestampRequired(dynamic value) {
  final t = parseTimestamp(value);
  return t ?? DateTime.now();
}

/// Returns [value] as String or null.
String? parseString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

/// Returns non-null String, defaulting to [defaultValue].
String parseStringRequired(dynamic value, [String defaultValue = '']) {
  return parseString(value) ?? defaultValue;
}

/// Returns [value] as int or null.
int? parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Returns [value] as double or null.
double? parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Returns [value] as bool; defaults to false if null.
bool parseBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  if (value is int) return value != 0;
  return false;
}

/// Returns list of strings from Postgres TEXT[] or JSON array.
List<String> parseStringList(dynamic value) {
  if (value == null) return const [];
  if (value is List) {
    return value
        .map((e) => parseString(e))
        .whereType<String>()
        .toList();
  }
  return const [];
}
