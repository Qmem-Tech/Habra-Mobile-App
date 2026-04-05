/// Normalized slug for `jobs.job_type` (hyphenated, lower case).
String jobTypeNormalizeSlug(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'full-time';
  return raw.trim().toLowerCase().replaceAll('_', '-');
}

/// Human-readable label from slug (e.g. `full-time` → `Full-Time`).
String jobTypeFormatLabel(String? raw) {
  final slug = jobTypeNormalizeSlug(raw);
  return slug
      .split('-')
      .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
      .join('-');
}

/// Salary line from min/max when `salary_display` is absent.
String jobSalaryLineFromMinMax(int? min, int? max) {
  if (min != null && max != null) return '\$$min - \$$max';
  if (min != null) return 'From \$$min';
  if (max != null) return 'Up to \$$max';
  return '';
}
