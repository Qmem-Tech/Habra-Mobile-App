# Business Subscription Integration Plan

## Pricing Tiers

- Basic: free forever
  - Business listing
  - Customer reviews
  - Basic insights
  - Max active deals: 1
  - Max active events: 1
- Pro: $14.99 / month
  - Show deals and promotions
  - Post events
  - Verified badge
  - Basic analytics
  - Max active deals: 5
  - Max active events: 3
- Premium: $29.99 / month
  - Featured in top search/feed boost
  - Show deals and promotions
  - Post events
  - Verified badge
  - Advanced analytics
  - Max active deals: unlimited
  - Max active events: unlimited

## Data Contract

- `businesses.subscription_tier`: `basic|pro|premium`
- `businesses.subscription_status`: `active|inactive|trialing|past_due|canceled`
- Existing `businesses.is_verified` remains source of eligibility; app adds tier check.

## Gating Rules

- Analytics tab:
  - Basic: locked message with upgrade prompt
  - Pro/Premium: full analytics
- Deals:
  - Enforce active deal limits at publish time
- Events:
  - Enforce active event limits at create time
- Verified badge:
  - Only displayed when business is verified and tier is Pro/Premium
- Feed/Search boost:
  - Premium > Pro > Basic ordering weight

## UI Notes

- Subscription screen should follow the "Grow Your Business" inspiration:
  - headline and benefits
  - clear Basic/Pro/Premium cards
  - explicit current plan state
  - actionable "Choose Plan" flow

## Rollout

- Backward compatibility:
  - Missing tier/status values default to `basic` and `unknown`
- Existing boolean dashboard gate remains compatible with current billing modes.
