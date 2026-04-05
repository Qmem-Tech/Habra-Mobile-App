/// Postgres enum `boost_plan_target` and columns `boost_plans.target_type`,
/// `boosts.target_type`. Must stay aligned with super admin and Supabase seed/migrations.
abstract final class BoostPlanTarget {
  BoostPlanTarget._();

  static const String businessListing = 'business_listing';
  static const String deal = 'deal';
  static const String job = 'job';
}
