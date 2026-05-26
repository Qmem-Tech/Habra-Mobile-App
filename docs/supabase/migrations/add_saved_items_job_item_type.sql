-- Allow `job` in saved_items.item_type (optional: jobs also use job_bookmarks;
-- this enables future unified rows or SaveItemUseCase(SavedItemType.job).)
-- PostgreSQL auto-names inline CHECK as saved_items_item_type_check on some versions;
-- adjust the constraint name if your DB differs (inspect \d saved_items).

ALTER TABLE public.saved_items
  DROP CONSTRAINT IF EXISTS saved_items_item_type_check;

ALTER TABLE public.saved_items
  ADD CONSTRAINT saved_items_item_type_check
  CHECK (item_type IN ('event', 'deal', 'job'));
