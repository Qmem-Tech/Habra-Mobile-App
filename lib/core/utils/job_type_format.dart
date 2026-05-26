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

/// Formats a yearly amount stored in dollars (e.g. 85000 → `$85k`).
String _formatSalaryYearlyK(int amount) {
  if (amount == 0) return '\$0';
  if (amount.abs() < 1000) return '\$$amount';
  final k = (amount / 1000).round();
  return '\$${k}k';
}

/// Salary line from min/max when `salary_display` is absent.
///
/// [salaryType]: `yearly` → compact thousands (`$80k - $120k`); `hourly` →
/// amounts with `/hr`; otherwise legacy `$min - $max`.
String jobSalaryLineFromMinMax(
  int? min,
  int? max, {
  String? salaryType,
}) {
  final type = salaryType?.toLowerCase().trim();

  if (type == 'yearly') {
    if (min != null && max != null) {
      return '${_formatSalaryYearlyK(min)} - ${_formatSalaryYearlyK(max)}';
    }
    if (min != null) return 'From ${_formatSalaryYearlyK(min)}';
    if (max != null) return 'Up to ${_formatSalaryYearlyK(max)}';
    return '';
  }

  if (type == 'hourly') {
    if (min != null && max != null) return '\$$min - \$$max/hr';
    if (min != null) return 'From \$$min/hr';
    if (max != null) return 'Up to \$$max/hr';
    return '';
  }

  if (min != null && max != null) return '\$$min - \$$max';
  if (min != null) return 'From \$$min';
  if (max != null) return 'Up to \$$max';
  return '';
}
