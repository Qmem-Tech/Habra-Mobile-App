-- Saved events/deals for the mobile "Saved items" feature.
-- Fixes PostgREST: "Could not find the table 'public.saved_items' in the schema cache"
-- when the table was never created on an older project.

CREATE TABLE IF NOT EXISTS public.saved_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  item_type TEXT NOT NULL CHECK (item_type IN ('event', 'deal')),
  reference_id UUID NOT NULL,
  title TEXT,
  subtitle TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, item_type, reference_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_items_user_created
  ON public.saved_items(user_id, created_at DESC);

ALTER TABLE public.saved_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "saved_items_select_own" ON public.saved_items;
CREATE POLICY "saved_items_select_own" ON public.saved_items
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_items_insert_own" ON public.saved_items;
CREATE POLICY "saved_items_insert_own" ON public.saved_items
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_items_delete_own" ON public.saved_items;
CREATE POLICY "saved_items_delete_own" ON public.saved_items
  FOR DELETE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "saved_items_update_own" ON public.saved_items;
CREATE POLICY "saved_items_update_own" ON public.saved_items
  FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "admin_saved_items" ON public.saved_items;
CREATE POLICY "admin_saved_items" ON public.saved_items
  FOR ALL USING (public.is_admin());
