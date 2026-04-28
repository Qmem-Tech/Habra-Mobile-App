# Business Owner Subscription Checklist

Reference checklist for what is allowed and not allowed per subscription tier.
This follows the current app behavior and policy gates.

## Source of truth

- Tier policy logic: `lib/core/subscription/business_subscription_policy.dart`
- Subscription gate state: `lib/features/home/presentation/bloc/business_owner_subscription_cubit.dart`
- Plan copy shown to users: `lib/features/home/presentation/pages/business_owner_subscription_page.dart`

## Tier matrix (Allowed vs Not Allowed)

### Basic

- Allowed:
  - Business listing
  - Customer reviews
  - Basic insights
  - Up to 1 active deal
  - Up to 1 active event
- Not allowed:
  - Verified badge
  - Analytics access (non-basic analytics features)
  - Feed boost weight above baseline
  - Higher deal/event limits from Pro/Premium

### Pro

- Allowed:
  - Show deals and promotions
  - Post events
  - Verified badge
  - Basic analytics access
  - Up to 5 active deals
  - Up to 3 active events
  - Feed boost weight level 1
- Not allowed:
  - Premium-level unlimited deal/event limits
  - Premium feed boost priority level 2
  - Premium/advanced analytics scope shown in Premium plan

### Premium

- Allowed:
  - Featured/top visibility positioning
  - Show deals and promotions
  - Post events
  - Verified badge
  - Advanced analytics
  - Effectively unlimited active deals (policy: 9999)
  - Effectively unlimited active events (policy: 9999)
  - Feed boost weight level 2
- Not allowed:
  - N/A within owner subscription scope (this is the highest tier)

## Operational checks before release

- RevenueCat entitlement mapping:
  - Pro SKU/package maps to `pro`
  - Premium SKU/package maps to `premium`
- Backend snapshot update checks:
  - `profiles.owner_tools_subscription_active`
  - `profiles.owner_tools_subscription_tier`
  - `profiles.owner_tools_subscription_status`
  - `profiles.owner_tools_subscription_source = revenuecat`
- UI gating checks:
  - Locked users without entitlement are redirected to subscribe flow
  - Active users can access paid owner tabs

## QA quick checklist

- Basic user cannot access paid analytics/verified features.
- Pro user can create up to 5 deals and 3 events, then sees limit enforcement.
- Premium user is not blocked by normal deal/event limits.
- Feed ranking/boost behavior increases from Basic -> Pro -> Premium.
- Restore purchases correctly re-applies tier permissions.