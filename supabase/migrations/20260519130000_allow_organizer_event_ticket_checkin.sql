-- See docs/supabase/migrations/allow_organizer_event_ticket_checkin.sql

ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "orders_select_event_organizer" ON public.orders;
CREATE POLICY "orders_select_event_organizer" ON public.orders
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = orders.event_id
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

DROP POLICY IF EXISTS "tickets_select_event_organizer" ON public.tickets;
CREATE POLICY "tickets_select_event_organizer" ON public.tickets
  FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.events e ON e.id = o.event_id
      WHERE o.id = tickets.order_id
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

DROP POLICY IF EXISTS "tickets_update_event_organizer" ON public.tickets;
CREATE POLICY "tickets_update_event_organizer" ON public.tickets
  FOR UPDATE TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.orders o
      JOIN public.events e ON e.id = o.event_id
      WHERE o.id = tickets.order_id
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
      SELECT 1 FROM public.orders o
      JOIN public.events e ON e.id = o.event_id
      WHERE o.id = tickets.order_id
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

CREATE OR REPLACE FUNCTION public.check_in_event_ticket(
  p_ticket_id uuid,
  p_event_id uuid
)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_uid uuid := auth.uid();
  v_ticket public.tickets%ROWTYPE;
  v_order public.orders%ROWTYPE;
  v_event public.events%ROWTYPE;
  v_ticket_type_name text;
  v_attendee_name text;
BEGIN
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_ticket FROM public.tickets WHERE id = p_ticket_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'not_found');
  END IF;

  SELECT * INTO v_order FROM public.orders WHERE id = v_ticket.order_id;
  IF NOT FOUND THEN
    RETURN jsonb_build_object('result', 'not_found');
  END IF;

  SELECT * INTO v_event FROM public.events WHERE id = v_order.event_id;
  IF NOT FOUND OR v_event.id IS DISTINCT FROM p_event_id THEN
    RETURN jsonb_build_object('result', 'wrong_event');
  END IF;

  IF NOT (
    v_event.organizer_id = v_uid
    OR (
      v_event.business_id IS NOT NULL
      AND EXISTS (
        SELECT 1 FROM public.businesses b
        WHERE b.id = v_event.business_id AND b.owner_id = v_uid
      )
    )
  ) THEN
    RAISE EXCEPTION 'Not authorized to check in tickets for this event'
      USING ERRCODE = '42501';
  END IF;

  IF v_order.status::text IS DISTINCT FROM 'completed' THEN
    RETURN jsonb_build_object('result', 'unpaid');
  END IF;

  IF v_ticket.status::text = 'used' THEN
    SELECT name INTO v_ticket_type_name
    FROM public.event_tickets WHERE id = v_ticket.event_ticket_id;
    RETURN jsonb_build_object(
      'result', 'already_used',
      'ticket_type', v_ticket_type_name
    );
  END IF;

  IF v_ticket.status::text = 'cancelled' THEN
    RETURN jsonb_build_object('result', 'cancelled');
  END IF;

  UPDATE public.tickets SET status = 'used' WHERE id = p_ticket_id;

  SELECT name INTO v_ticket_type_name
  FROM public.event_tickets WHERE id = v_ticket.event_ticket_id;

  SELECT full_name INTO v_attendee_name
  FROM public.profiles WHERE id = v_order.user_id;

  RETURN jsonb_build_object(
    'result', 'valid',
    'ticket_type', v_ticket_type_name,
    'attendee_name', NULLIF(trim(v_attendee_name), '')
  );
END;
$$;

REVOKE ALL ON FUNCTION public.check_in_event_ticket(uuid, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.check_in_event_ticket(uuid, uuid) TO authenticated;

NOTIFY pgrst, 'reload schema';
