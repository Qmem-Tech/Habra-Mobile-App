-- Ticket resale marketplace: users can list tickets for sale
CREATE TABLE IF NOT EXISTS public.ticket_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  ticket_id UUID NOT NULL REFERENCES public.tickets(id) ON DELETE CASCADE,
  seller_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  asking_price NUMERIC(10,2) NOT NULL,
  status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'sold', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(ticket_id)
);

CREATE INDEX IF NOT EXISTS idx_ticket_listings_status ON public.ticket_listings(status) WHERE status = 'available';
CREATE INDEX IF NOT EXISTS idx_ticket_listings_seller ON public.ticket_listings(seller_id);

ALTER TABLE public.ticket_listings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ticket_listings_select_available" ON public.ticket_listings
  FOR SELECT USING (status = 'available' OR seller_id = auth.uid());

CREATE POLICY "ticket_listings_insert_own" ON public.ticket_listings
  FOR INSERT WITH CHECK (seller_id = auth.uid());

CREATE POLICY "ticket_listings_update_own" ON public.ticket_listings
  FOR UPDATE USING (seller_id = auth.uid());
