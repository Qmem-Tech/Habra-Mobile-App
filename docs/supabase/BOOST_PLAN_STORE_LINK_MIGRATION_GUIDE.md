# Boost Plan Store Link Migration Guide

This is the single source of truth to fix and verify the boost purchase error:

- **"Plan not linked to the store"**
- **"Product not found"**

Use this file later when you are ready to migrate.

---

## Goal

Ensure every active row in `public.boost_plans` has a valid `billing_product_id` that matches:

1. App Store / Google Play product identifier
2. RevenueCat package `storeProduct.identifier`

---

## Prerequisites

- Supabase project access (SQL Editor)
- RevenueCat dashboard access
- Store products already created (App Store / Play Console)

Recommended ID format used in this repo:

`com.habra.habra.boost.<target_type>.<duration_weeks>wk`

Examples:

- `com.habra.habra.boost.business_listing.1wk`
- `com.habra.habra.boost.deal.2wk`
- `com.habra.habra.boost.job.4wk`

---

## Step 1: Schema Safety (add column if missing)

Run:

```sql
ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS billing_product_id TEXT;

COMMENT ON COLUMN public.boost_plans.billing_product_id IS
  'Store product id (App Store / Play) used to map plan -> RevenueCat package.';
```

---

## Step 2: Backfill Missing IDs (safe for existing data)

Run:

```sql
UPDATE public.boost_plans
SET billing_product_id = CONCAT(
  'com.habra.habra.boost.',
  target_type::text,
  '.',
  duration_weeks::text,
  'wk'
)
WHERE is_active = true
  AND (billing_product_id IS NULL OR btrim(billing_product_id) = '');
```

Notes:

- This only updates active plans with missing IDs.
- If your store IDs use a different naming convention, edit the pattern first.

---

## Step 3: Verification Queries

### 3.1 Show active plans and current linkage

```sql
SELECT
  id,
  title,
  target_type,
  duration_weeks,
  price_usd,
  billing_product_id,
  is_active
FROM public.boost_plans
WHERE is_active = true
ORDER BY target_type, duration_weeks, price_usd;
```

### 3.2 Find active plans still missing linkage

```sql
SELECT
  id,
  title,
  target_type,
  duration_weeks
FROM public.boost_plans
WHERE is_active = true
  AND (billing_product_id IS NULL OR btrim(billing_product_id) = '');
```

Expected result: **0 rows**

### 3.3 Detect duplicates (same store product mapped to multiple plans)

```sql
SELECT
  billing_product_id,
  COUNT(*) AS plan_count
FROM public.boost_plans
WHERE is_active = true
  AND billing_product_id IS NOT NULL
  AND btrim(billing_product_id) <> ''
GROUP BY billing_product_id
HAVING COUNT(*) > 1
ORDER BY plan_count DESC, billing_product_id;
```

Expected result: ideally **0 rows** unless intentionally shared

### 3.4 Naming sanity check for current convention

```sql
SELECT
  id,
  title,
  target_type,
  duration_weeks,
  billing_product_id
FROM public.boost_plans
WHERE is_active = true
  AND (
    billing_product_id IS NULL
    OR btrim(billing_product_id) = ''
    OR billing_product_id <> CONCAT(
      'com.habra.habra.boost.',
      target_type::text,
      '.',
      duration_weeks::text,
      'wk'
    )
  )
ORDER BY target_type, duration_weeks;
```

---

## Step 4: RevenueCat Mapping Checklist

For each `billing_product_id` from Step 3.1:

1. Product exists in App Store/Play with exact same identifier.
2. Product is imported in RevenueCat.
3. Product is attached to a RevenueCat package.
4. Package is in the correct offering:
   - If `REVENUECAT_BOOST_OFFERING_ID` is set, product must be in that offering.
   - If empty, app searches all offerings.

---

## Step 5: App Runtime Config Check

Ensure `dart_defines.json` includes:

```json
"REVENUECAT_BOOST_OFFERING_ID": ""
```

Use a real offering ID if you want to constrain lookup to one offering.

---

## Step 6: Test Flow (after migration)

1. Open boost purchase screen.
2. Select an active boost plan.
3. Tap **Boost Now**.

Expected:

- No **"Plan not linked to the store"** dialog.
- No **"Product not found"** dialog.
- Purchase flow reaches boost activation (`submitBoostOrder`).

If product mapping still fails, the app now shows:

- plan id
- target type
- offering filter
- sample available product IDs from RevenueCat

Use those diagnostics to determine whether the issue is in Supabase data or RevenueCat offering setup.

---

## Optional: Seed Data Standard (for new environments)

When seeding fresh environments, include `billing_product_id` directly in seed rows so the issue does not recur.

---

## Rollback / Recovery

If you need to revert only the backfill values added by this guide (and keep manually curated IDs untouched), run a targeted rollback only for IDs following this pattern:

```sql
UPDATE public.boost_plans
SET billing_product_id = NULL
WHERE billing_product_id LIKE 'com.habra.habra.boost.%'
  AND is_active = true;
```

Use with care.

---

## Quick Copy-Paste Bundle (minimal)

If you only want the essentials later:

```sql
ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS billing_product_id TEXT;

UPDATE public.boost_plans
SET billing_product_id = CONCAT(
  'com.habra.habra.boost.',
  target_type::text,
  '.',
  duration_weeks::text,
  'wk'
)
WHERE is_active = true
  AND (billing_product_id IS NULL OR btrim(billing_product_id) = '');

SELECT id, title, target_type, duration_weeks, billing_product_id
FROM public.boost_plans
WHERE is_active = true
ORDER BY target_type, duration_weeks;
```
