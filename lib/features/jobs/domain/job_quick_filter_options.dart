/// Horizontal chips on Jobs home. Labels must match `jobs.job_type` in Supabase
/// so `inFilter('job_type', …)` works (same strings as the filters sheet).
const String kJobsQuickFilterAll = 'All Jobs';

const List<String> kJobsQuickFilterJobTypes = [
  'Full-time',
  'Part-time',
  'Contract',
  'Temporary',
];

/// All chip labels in scroll order (first = clear type filter).
List<String> jobsQuickFilterChipLabels() =>
    [kJobsQuickFilterAll, ...kJobsQuickFilterJobTypes];
