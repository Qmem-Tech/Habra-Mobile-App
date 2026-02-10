/// Keys for [CacheClient] (static/semi-static data from Supabase).
class CacheKeys {
  CacheKeys._();

  static const String categories = 'cache_categories';
  static const String boostPlans = 'cache_boost_plans';
  static const String appSettings = 'cache_app_settings';
  static const String jobCategories = 'cache_job_categories';
}

/// Default TTLs for cached data.
class CacheTtl {
  CacheTtl._();

  static const Duration categories = Duration(hours: 24);
  static const Duration boostPlans = Duration(hours: 24);
  static const Duration appSettings = Duration(minutes: 60);
  static const Duration jobCategories = Duration(hours: 24);
}
