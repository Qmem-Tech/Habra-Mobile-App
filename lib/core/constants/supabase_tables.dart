/// Central Supabase table name constants.
/// Matches the web admin `endpoints.ts` / `MOBILE_APP_SYNC_PACKAGE.md`.
class SupabaseTables {
  SupabaseTables._();

  static const String profiles = 'profiles';
  static const String businesses = 'businesses';
  static const String deals = 'deals';
  static const String jobs = 'jobs';
  static const String reviews = 'reviews';
  static const String jobApplications = 'job_applications';
  static const String boostPlans = 'boost_plans';
  static const String boosts = 'boosts';
  static const String dealRedemptions = 'deal_redemptions';
  static const String events = 'events';
  static const String eventTickets = 'event_tickets';
  static const String orders = 'orders';
  static const String tickets = 'tickets';
  static const String ticketListings = 'ticket_listings';
  static const String feedback = 'feedback';
  static const String savedItems = 'saved_items';
  static const String categories = 'categories';
  static const String businessCategories = 'business_categories';
}

/// Supabase storage bucket names.
class SupabaseBuckets {
  SupabaseBuckets._();

  static const String avatars = 'avatars';
  static const String businesses = 'businesses';
  static const String deals = 'deals';
  static const String events = 'events';
  static const String reviews = 'reviews';
}
