# Boost Store Linking Runbook

Use this when boost purchase fails with "Plan not linked to the store" or "Product not found".

## 1) Verify boost plans have `billing_product_id`

```sql
SELECT id, title, target_type, duration_weeks, billing_product_id
FROM public.boost_plans
WHERE is_active = true
ORDER BY target_type, duration_weeks;
```

If any active plan has empty `billing_product_id`, run:

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

## 2) Verify RevenueCat offering/package mapping

- Ensure each `billing_product_id` exists as a product in App Store Connect / Play Console.
- In RevenueCat, attach each of those products to packages in the offering used for boosts.
- If using a dedicated boost offering, set `REVENUECAT_BOOST_OFFERING_ID` in `dart_defines.json`.
- If `REVENUECAT_BOOST_OFFERING_ID` is empty, the app searches all offerings.

## 3) Runtime diagnostics in app

When mapping fails, the app dialog now includes:
- `plan.id`
- `target_type`
- offering filter value
- sample list of available product identifiers from RevenueCat

Use those values to quickly identify whether the mismatch is in Supabase or RevenueCat.
