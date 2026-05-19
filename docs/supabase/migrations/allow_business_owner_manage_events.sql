-- =============================================================================
-- Business owners: create events + ticket types (mobile + web)
-- =============================================================================
-- Run in Supabase Dashboard → SQL Editor (safe to re-run).
--
-- 1) RLS policies (explicit INSERT + organizer/business-owner paths)
-- 2) SECURITY DEFINER RPC — reliable create when RLS is misconfigured
-- =============================================================================

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS event_policy text;

ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.event_tickets ENABLE ROW LEVEL SECURITY;

-- Locations (create-event attaches venue rows here)
ALTER TABLE public.locations ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "locations_select" ON public.locations;
CREATE POLICY "locations_select" ON public.locations
  FOR SELECT USING (true);
DROP POLICY IF EXISTS "locations_insert_authenticated" ON public.locations;
CREATE POLICY "locations_insert_authenticated" ON public.locations
  FOR INSERT TO authenticated WITH CHECK (true);

-- Events: create new policies BEFORE dropping legacy ones
DROP POLICY IF EXISTS "events_insert_business_owner" ON public.events;
CREATE POLICY "events_insert_business_owner" ON public.events
  FOR INSERT TO authenticated
  WITH CHECK (
    organizer_id = auth.uid()
    OR (
      business_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = business_id AND b.owner_id = auth.uid()
      )
    )
  );

DROP POLICY IF EXISTS "events_manage_organizer" ON public.events;
CREATE POLICY "events_manage_organizer" ON public.events
  FOR ALL TO authenticated
  USING (organizer_id = auth.uid())
  WITH CHECK (organizer_id = auth.uid());

DROP POLICY IF EXISTS "events_manage_business_owner" ON public.events;
CREATE POLICY "events_manage_business_owner" ON public.events
  FOR ALL TO authenticated
  USING (
    business_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
  )
  WITH CHECK (
    business_id IS NOT NULL
    AND EXISTS (
      SELECT 1 FROM public.businesses b
      WHERE b.id = business_id AND b.owner_id = auth.uid()
    )
  );

-- Legacy names (idempotent cleanup / replace)
DROP POLICY IF EXISTS "events_insert" ON public.events;
DROP POLICY IF EXISTS "events_update_delete_owner" ON public.events;
DROP POLICY IF EXISTS "events_delete_owner" ON public.events;
DROP POLICY IF EXISTS "events_all_organizer" ON public.events;

-- Event tickets
DROP POLICY IF EXISTS "event_tickets_insert_owner" ON public.event_tickets;
CREATE POLICY "event_tickets_insert_owner" ON public.event_tickets
  FOR INSERT TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id
        AND (
          e.organizer_id = auth.uid()
          OR (
            e.business_id IS NOT NULL
            AND EXISTS (
              SELECT 1 FROM public.businesses b
              WHERE b.id = e.business_id AND b.owner_id = auth.uid()
            )
          )
        )
    )
  );

DROP POLICY IF EXISTS "event_tickets_manage_owner" ON public.event_tickets;
CREATE POLICY "event_tickets_manage_owner" ON public.event_tickets
  FOR ALL TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id
        AND (
          e.organizer_id = auth.uid()
          OR (
            e.business_id IS NOT NULL
            AND EXISTS (
              SELECT 1 FROM public.businesses b
              WHERE b.id = e.business_id AND b.owner_id = auth.uid()
            )
          )
        )
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_id
        AND (
          e.organizer_id = auth.uid()
          OR (
            e.business_id IS NOT NULL
            AND EXISTS (
              SELECT 1 FROM public.businesses b
              WHERE b.id = e.business_id AND b.owner_id = auth.uid()
            )
          )
        )
    )
  );

DROP POLICY IF EXISTS "event_tickets_all_organizer" ON public.event_tickets;
DROP POLICY IF EXISTS "event_tickets_update_delete_owner" ON public.event_tickets;

-- =============================================================================
-- RPC: bypass RLS after server-side ownership check (mobile create-event)
-- =============================================================================
CREATE OR REPLACE FUNCTION public.create_owner_event_with_tickets(
  p_event jsonb,
  p_tickets jsonb DEFAULT '[]'::jsonb
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_business_id uuid;
  v_event_id uuid;
  t jsonb;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  BEGIN
    v_business_id := NULLIF(trim(p_event->>'business_id'), '')::uuid;
  EXCEPTION
    WHEN invalid_text_representation THEN
      RAISE EXCEPTION 'Invalid business_id';
  END;

  IF v_business_id IS NULL THEN
    RAISE EXCEPTION 'business_id is required';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM public.businesses b
    WHERE b.id = v_business_id
      AND b.owner_id = v_uid
  ) THEN
    RAISE EXCEPTION 'Not authorized for this business listing' USING ERRCODE = '42501';
  END IF;

  INSERT INTO public.events (
    organizer_id,
    business_id,
    title,
    description,
    venue_name,
    venue_address,
    venue_lat,
    venue_lng,
    location_id,
    is_online,
    online_url,
    start_at,
    end_at,
    image_url,
    category,
    is_active,
    event_policy
  )
  VALUES (
    v_uid,
    v_business_id,
    COALESCE(NULLIF(trim(p_event->>'title'), ''), 'Untitled'),
    NULLIF(trim(p_event->>'description'), ''),
    NULLIF(trim(p_event->>'venue_name'), ''),
    NULLIF(trim(p_event->>'venue_address'), ''),
    NULLIF(p_event->>'venue_lat', '')::numeric,
    NULLIF(p_event->>'venue_lng', '')::numeric,
    NULLIF(NULLIF(trim(p_event->>'location_id'), ''), '')::uuid,
    COALESCE((p_event->>'is_online')::boolean, false),
    NULLIF(trim(p_event->>'online_url'), ''),
    (p_event->>'start_at')::timestamptz,
    (p_event->>'end_at')::timestamptz,
    NULLIF(trim(p_event->>'image_url'), ''),
    NULLIF(trim(p_event->>'category'), ''),
    COALESCE((p_event->>'is_active')::boolean, true),
    NULLIF(trim(p_event->>'event_policy'), '')
  )
  RETURNING id INTO v_event_id;

  FOR t IN SELECT elem FROM jsonb_array_elements(COALESCE(p_tickets, '[]'::jsonb)) AS arr(elem)
  LOOP
    INSERT INTO public.event_tickets (
      event_id,
      name,
      price,
      quantity_available,
      quantity_sold
    )
    VALUES (
      v_event_id,
      COALESCE(NULLIF(trim(t->>'name'), ''), 'General'),
      COALESCE(NULLIF(t->>'price', '')::numeric, 0),
      COALESCE(NULLIF(t->>'quantity_available', '')::int, 0),
      0
    );
  END LOOP;

  RETURN v_event_id;
END;
$$;

REVOKE ALL ON FUNCTION public.create_owner_event_with_tickets(jsonb, jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.create_owner_event_with_tickets(jsonb, jsonb) TO authenticated;
