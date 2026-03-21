-- =============================================================================
-- EVENT TICKET PURCHASES + ORGANIZER NOTIFICATION
-- =============================================================================
-- Run in Supabase Dashboard → SQL Editor.
-- Creates event_ticket_purchases table for per-ticket sales tracking.
-- Web app uses this for sold/left counts per ticket type.
-- Trigger creates notification for event organizer when a customer buys tickets.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. event_ticket_purchases TABLE
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.event_ticket_purchases (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  event_ticket_id UUID NOT NULL REFERENCES public.event_tickets(id) ON DELETE CASCADE,
  buyer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  total_cents INT,
  status TEXT NOT NULL DEFAULT 'completed' CHECK (status IN ('completed', 'pending', 'refunded')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_event_ticket_purchases_event ON public.event_ticket_purchases(event_id);
CREATE INDEX IF NOT EXISTS idx_event_ticket_purchases_ticket ON public.event_ticket_purchases(event_ticket_id);
CREATE INDEX IF NOT EXISTS idx_event_ticket_purchases_buyer ON public.event_ticket_purchases(buyer_id);

-- -----------------------------------------------------------------------------
-- 2. RLS
-- -----------------------------------------------------------------------------
ALTER TABLE public.event_ticket_purchases ENABLE ROW LEVEL SECURITY;

-- Organizers can read purchases for their events
DROP POLICY IF EXISTS "event_ticket_purchases_select_organizer" ON public.event_ticket_purchases;
CREATE POLICY "event_ticket_purchases_select_organizer" ON public.event_ticket_purchases
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.events e
      WHERE e.id = event_ticket_purchases.event_id
        AND e.organizer_id = auth.uid()
    )
  );

-- Buyers can read their own purchases
DROP POLICY IF EXISTS "event_ticket_purchases_select_buyer" ON public.event_ticket_purchases;
CREATE POLICY "event_ticket_purchases_select_buyer" ON public.event_ticket_purchases
  FOR SELECT USING (buyer_id = auth.uid());

-- Authenticated users can insert (customers buying tickets)
DROP POLICY IF EXISTS "event_ticket_purchases_insert_authenticated" ON public.event_ticket_purchases;
CREATE POLICY "event_ticket_purchases_insert_authenticated" ON public.event_ticket_purchases
  FOR INSERT TO authenticated
  WITH CHECK (buyer_id = auth.uid());

-- -----------------------------------------------------------------------------
-- 3. TRIGGER: Notify organizer on ticket purchase
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.notify_on_ticket_purchase()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_organizer_id UUID;
  v_event_title TEXT;
  v_ticket_name TEXT;
BEGIN
  SELECT e.organizer_id, e.title
  INTO v_organizer_id, v_event_title
  FROM public.events e
  WHERE e.id = NEW.event_id;

  IF v_organizer_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT et.name INTO v_ticket_name
  FROM public.event_tickets et
  WHERE et.id = NEW.event_ticket_id;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (
    v_organizer_id,
    'New Ticket Sale',
    'A customer purchased ' || NEW.quantity || ' ticket(s)' ||
      CASE WHEN v_ticket_name IS NOT NULL THEN ' (' || v_ticket_name || ')' ELSE '' END ||
      ' for ' || COALESCE(v_event_title, 'your event') || '.',
    'ticket_purchase',
    jsonb_build_object(
      'event_id', NEW.event_id,
      'event_ticket_id', NEW.event_ticket_id,
      'quantity', NEW.quantity,
      'purchase_id', NEW.id
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_event_ticket_purchase_notify ON public.event_ticket_purchases;
CREATE TRIGGER on_event_ticket_purchase_notify
  AFTER INSERT ON public.event_ticket_purchases
  FOR EACH ROW EXECUTE FUNCTION public.notify_on_ticket_purchase();
