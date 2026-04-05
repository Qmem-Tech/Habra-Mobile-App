-- Optional compare-at price for boost plan cards (strikethrough in mobile UI).
ALTER TABLE public.boost_plans
  ADD COLUMN IF NOT EXISTS original_price_usd NUMERIC(10, 2);
