-- =============================================================================
-- HABRA — Full Supabase Backend Schema + RLS
-- =============================================================================
-- Copy and paste this entire file into Supabase Dashboard → SQL Editor → New query
-- and run it ONCE. Order of statements matters (FK dependencies).
--
-- If you already ran this script twice and got errors: the first run usually
-- succeeded; you can ignore the second run's errors. To reset and run again,
-- run docs/supabase/habra_teardown_schema.sql first, then this file once.
--
-- After running, complete configuration in Dashboard: see HABRA_SUPABASE_CONFIG.md
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. ENUMS
-- -----------------------------------------------------------------------------
CREATE TYPE app_role AS ENUM ('customer', 'businessOwner', 'admin', 'guest');
CREATE TYPE order_status AS ENUM ('pending', 'completed', 'cancelled', 'refunded');
CREATE TYPE ticket_status AS ENUM ('valid', 'used', 'cancelled');
CREATE TYPE deal_status AS ENUM ('draft', 'active', 'expired', 'inactive');
CREATE TYPE job_application_status AS ENUM ('pending', 'reviewed', 'shortlisted', 'rejected', 'hired');
CREATE TYPE boost_status AS ENUM ('active', 'paused', 'completed', 'cancelled');
CREATE TYPE business_approval_status AS ENUM ('pending', 'approved', 'rejected');

-- -----------------------------------------------------------------------------
-- 2. PROFILES (no FK to businesses yet)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  full_name TEXT NOT NULL DEFAULT '',
  avatar_url TEXT,
  role app_role NOT NULL DEFAULT 'customer',
  phone TEXT,
  is_suspended BOOLEAN DEFAULT false,
  email_verified_at TIMESTAMPTZ,
  locale TEXT DEFAULT 'en',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 3. BUSINESSES
-- -----------------------------------------------------------------------------
CREATE TABLE public.businesses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  slug TEXT UNIQUE,
  description TEXT,
  phone TEXT,
  email TEXT,
  website TEXT,
  address_street TEXT,
  address_city TEXT NOT NULL,
  address_state TEXT,
  address_zip TEXT,
  address_country TEXT DEFAULT 'US',
  latitude NUMERIC,
  longitude NUMERIC,
  logo_url TEXT,
  image_urls TEXT[] DEFAULT '{}',
  rating NUMERIC(3,2) DEFAULT 0,
  review_count INT DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  is_verified BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  approval_status business_approval_status NOT NULL DEFAULT 'pending',
  reviewed_at TIMESTAMPTZ,
  reviewed_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  rejection_reason TEXT,
  opening_time TIME,
  closing_time TIME,
  price_range TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ADD COLUMN primary_business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL;

-- -----------------------------------------------------------------------------
-- 4. REMAINING TABLES
-- -----------------------------------------------------------------------------
CREATE TABLE public.categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  slug TEXT UNIQUE
);

CREATE TABLE public.business_categories (
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  PRIMARY KEY (business_id, category_id)
);

CREATE TABLE public.deals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  original_price NUMERIC(10,2),
  discounted_price NUMERIC(10,2),
  discount_percentage INT,
  valid_from TIMESTAMPTZ NOT NULL,
  valid_until TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  category TEXT,
  status deal_status DEFAULT 'active',
  redemption_count INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizer_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  business_id UUID REFERENCES public.businesses(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  description TEXT,
  venue_name TEXT,
  venue_address TEXT,
  venue_lat NUMERIC,
  venue_lng NUMERIC,
  start_at TIMESTAMPTZ NOT NULL,
  end_at TIMESTAMPTZ NOT NULL,
  image_url TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.event_tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  event_id UUID NOT NULL REFERENCES public.events(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  price NUMERIC(10,2) NOT NULL DEFAULT 0,
  quantity_available INT NOT NULL,
  quantity_sold INT DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.jobs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  job_type TEXT NOT NULL,
  location TEXT,
  salary_min NUMERIC,
  salary_max NUMERIC,
  salary_display TEXT,
  category TEXT,
  is_active BOOLEAN DEFAULT true,
  is_featured BOOLEAN DEFAULT false,
  posted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  image_urls TEXT[] DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(business_id, user_id)
);

CREATE TABLE public.review_replies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  review_id UUID NOT NULL REFERENCES public.reviews(id) ON DELETE CASCADE,
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  body TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.deal_redemptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  deal_id UUID NOT NULL REFERENCES public.deals(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  redeemed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type TEXT NOT NULL DEFAULT 'event',
  event_id UUID REFERENCES public.events(id) ON DELETE SET NULL,
  status order_status NOT NULL DEFAULT 'pending',
  total_amount NUMERIC(10,2) NOT NULL,
  payment_method TEXT,
  payment_id TEXT,
  contact_email TEXT,
  contact_phone TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.tickets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  event_ticket_id UUID NOT NULL REFERENCES public.event_tickets(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  status ticket_status DEFAULT 'valid',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.job_applications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  cover_message TEXT,
  resume_url TEXT,
  status job_application_status DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(job_id, user_id)
);

CREATE TABLE public.job_bookmarks (
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  job_id UUID NOT NULL REFERENCES public.jobs(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, job_id)
);

CREATE TABLE public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT,
  type TEXT,
  data JSONB,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.boost_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  price_cents INT NOT NULL,
  duration_weeks INT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.boosts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id UUID NOT NULL REFERENCES public.businesses(id) ON DELETE CASCADE,
  boost_plan_id UUID NOT NULL REFERENCES public.boost_plans(id) ON DELETE CASCADE,
  deal_id UUID REFERENCES public.deals(id) ON DELETE SET NULL,
  job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
  status boost_status NOT NULL DEFAULT 'active',
  starts_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ends_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  resource_type TEXT NOT NULL,
  resource_id TEXT,
  old_data JSONB,
  new_data JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.app_settings (
  key TEXT PRIMARY KEY,
  value JSONB NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 5. INDEXES
-- -----------------------------------------------------------------------------
CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_businesses_owner ON public.businesses(owner_id);
CREATE INDEX idx_businesses_city_active ON public.businesses(address_city, is_active);
CREATE INDEX idx_businesses_approval_status ON public.businesses(approval_status) WHERE approval_status = 'pending';
CREATE INDEX idx_deals_business_valid ON public.deals(business_id, valid_until) WHERE status = 'active';
CREATE INDEX idx_events_start ON public.events(start_at) WHERE is_active;
CREATE INDEX idx_jobs_business_posted ON public.jobs(business_id, posted_at DESC);
CREATE INDEX idx_reviews_business ON public.reviews(business_id);
CREATE INDEX idx_orders_user ON public.orders(user_id);
CREATE INDEX idx_notifications_user_unread ON public.notifications(user_id, is_read);
CREATE INDEX idx_job_applications_job ON public.job_applications(job_id);
CREATE INDEX idx_audit_log_created_at ON public.audit_log(created_at DESC);
CREATE INDEX idx_audit_log_actor ON public.audit_log(actor_id);

-- Optional: full-text search on businesses
ALTER TABLE public.businesses ADD COLUMN IF NOT EXISTS search_vector tsvector
  GENERATED ALWAYS AS (to_tsvector('english', name || ' ' || COALESCE(description, ''))) STORED;
CREATE INDEX IF NOT EXISTS idx_businesses_search ON public.businesses USING GIN(search_vector);

-- -----------------------------------------------------------------------------
-- 6. HELPER FUNCTIONS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin');
$$;

-- -----------------------------------------------------------------------------
-- 7. TRIGGER: Create profile on sign-up (auth.users insert)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  user_role app_role;
BEGIN
  user_role := COALESCE(
    (NEW.raw_user_meta_data->>'role')::app_role,
    'customer'::app_role
  );
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    user_role
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- 8. TRIGGER: updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_profiles_updated_at ON public.profiles;
CREATE TRIGGER tr_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_businesses_updated_at ON public.businesses;
CREATE TRIGGER tr_businesses_updated_at BEFORE UPDATE ON public.businesses FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_deals_updated_at ON public.deals;
CREATE TRIGGER tr_deals_updated_at BEFORE UPDATE ON public.deals FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_events_updated_at ON public.events;
CREATE TRIGGER tr_events_updated_at BEFORE UPDATE ON public.events FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_jobs_updated_at ON public.jobs;
CREATE TRIGGER tr_jobs_updated_at BEFORE UPDATE ON public.jobs FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_reviews_updated_at ON public.reviews;
CREATE TRIGGER tr_reviews_updated_at BEFORE UPDATE ON public.reviews FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_orders_updated_at ON public.orders;
CREATE TRIGGER tr_orders_updated_at BEFORE UPDATE ON public.orders FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
DROP TRIGGER IF EXISTS tr_app_settings_updated_at ON public.app_settings;
CREATE TRIGGER tr_app_settings_updated_at BEFORE UPDATE ON public.app_settings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 9. TRIGGER: Recompute business rating when reviews change
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_business_rating()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  bid UUID;
  avg_rating NUMERIC;
  cnt INT;
BEGIN
  IF TG_OP = 'DELETE' THEN
    bid := OLD.business_id;
  ELSE
    bid := NEW.business_id;
  END IF;
  SELECT AVG(rating)::NUMERIC(3,2), COUNT(*) INTO avg_rating, cnt
  FROM public.reviews WHERE business_id = bid;
  UPDATE public.businesses
  SET rating = COALESCE(avg_rating, 0), review_count = COALESCE(cnt, 0)
  WHERE id = bid;
  IF TG_OP = 'DELETE' THEN RETURN OLD; ELSE RETURN NEW; END IF;
END;
$$;

DROP TRIGGER IF EXISTS on_review_change_rating ON public.reviews;
CREATE TRIGGER on_review_change_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.update_business_rating();

-- -----------------------------------------------------------------------------
-- 10. ROW LEVEL SECURITY (RLS) — Enable and policies
-- -----------------------------------------------------------------------------

-- Profiles
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select" ON public.profiles FOR SELECT USING (true);
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "profiles_delete_own" ON public.profiles FOR DELETE USING (auth.uid() = id);
CREATE POLICY "profiles_admin_update" ON public.profiles FOR UPDATE USING (public.is_admin());

-- Businesses
ALTER TABLE public.businesses ENABLE ROW LEVEL SECURITY;
CREATE POLICY "businesses_select" ON public.businesses FOR SELECT USING (
  (approval_status = 'approved' AND is_active = true) OR owner_id = auth.uid()
);
CREATE POLICY "businesses_insert" ON public.businesses FOR INSERT WITH CHECK (
  auth.uid() = owner_id
  AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'businessOwner')
);
CREATE POLICY "businesses_update_owner" ON public.businesses FOR UPDATE USING (owner_id = auth.uid());
CREATE POLICY "businesses_delete_owner" ON public.businesses FOR DELETE USING (owner_id = auth.uid());

-- Categories
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "categories_select" ON public.categories FOR SELECT USING (true);
CREATE POLICY "categories_admin_all" ON public.categories FOR ALL USING (public.is_admin());

-- Business categories
ALTER TABLE public.business_categories ENABLE ROW LEVEL SECURITY;
CREATE POLICY "business_categories_select" ON public.business_categories FOR SELECT USING (true);
CREATE POLICY "business_categories_insert" ON public.business_categories FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);
CREATE POLICY "business_categories_delete" ON public.business_categories FOR DELETE USING (
  EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Deals
ALTER TABLE public.deals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "deals_select" ON public.deals FOR SELECT USING (
  (status = 'active' AND EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.approval_status = 'approved' AND b.is_active = true))
  OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);
CREATE POLICY "deals_insert" ON public.deals FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "deals_update_delete" ON public.deals FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- Events
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "events_select" ON public.events FOR SELECT USING (is_active = true OR organizer_id = auth.uid());
CREATE POLICY "events_all_organizer" ON public.events FOR ALL USING (organizer_id = auth.uid());

-- Event tickets
ALTER TABLE public.event_tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "event_tickets_select" ON public.event_tickets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND (e.is_active = true OR e.organizer_id = auth.uid()))
);
CREATE POLICY "event_tickets_all_organizer" ON public.event_tickets FOR ALL USING (
  EXISTS (SELECT 1 FROM public.events e WHERE e.id = event_id AND e.organizer_id = auth.uid())
);

-- Jobs
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "jobs_select" ON public.jobs FOR SELECT USING (
  (is_active = true AND EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.approval_status = 'approved' AND b.is_active = true))
  OR EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);
CREATE POLICY "jobs_all_owner" ON public.jobs FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- Reviews
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
CREATE POLICY "reviews_select" ON public.reviews FOR SELECT USING (true);
CREATE POLICY "reviews_insert" ON public.reviews FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "reviews_update_delete_own" ON public.reviews FOR ALL USING (auth.uid() = user_id);

-- Review replies
ALTER TABLE public.review_replies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "review_replies_select" ON public.review_replies FOR SELECT USING (true);
CREATE POLICY "review_replies_insert_update" ON public.review_replies FOR ALL USING (
  EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid())
);

-- Deal redemptions
ALTER TABLE public.deal_redemptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "deal_redemptions_select_own" ON public.deal_redemptions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "deal_redemptions_select_business" ON public.deal_redemptions FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.deals d JOIN public.businesses b ON d.business_id = b.id WHERE d.id = deal_id AND b.owner_id = auth.uid())
);
CREATE POLICY "deal_redemptions_insert" ON public.deal_redemptions FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Orders
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
CREATE POLICY "orders_select" ON public.orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "orders_insert" ON public.orders FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Tickets
ALTER TABLE public.tickets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "tickets_select" ON public.tickets FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.orders o WHERE o.id = order_id AND o.user_id = auth.uid())
);

-- Job applications
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_applications_select_own" ON public.job_applications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "job_applications_select_business" ON public.job_applications FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.jobs j JOIN public.businesses b ON j.business_id = b.id WHERE j.id = job_id AND b.owner_id = auth.uid())
);
CREATE POLICY "job_applications_insert" ON public.job_applications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "job_applications_update_business" ON public.job_applications FOR UPDATE USING (
  EXISTS (SELECT 1 FROM public.jobs j JOIN public.businesses b ON j.business_id = b.id WHERE j.id = job_id AND b.owner_id = auth.uid())
);

-- Job bookmarks
ALTER TABLE public.job_bookmarks ENABLE ROW LEVEL SECURITY;
CREATE POLICY "job_bookmarks_all" ON public.job_bookmarks FOR ALL USING (auth.uid() = user_id);

-- Notifications
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notifications_select" ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notifications_update" ON public.notifications FOR UPDATE USING (auth.uid() = user_id);
-- Allow insert for system (e.g. from Edge Function) or same user
CREATE POLICY "notifications_insert" ON public.notifications FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Boosts
ALTER TABLE public.boosts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "boosts_select" ON public.boosts FOR SELECT USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "boosts_insert" ON public.boosts FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));
CREATE POLICY "boosts_update_delete" ON public.boosts FOR ALL USING (EXISTS (SELECT 1 FROM public.businesses b WHERE b.id = business_id AND b.owner_id = auth.uid()));

-- Boost plans
ALTER TABLE public.boost_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "boost_plans_select" ON public.boost_plans FOR SELECT USING (true);
CREATE POLICY "boost_plans_admin" ON public.boost_plans FOR ALL USING (public.is_admin());

-- Audit log (admin read; inserts via trigger or Edge Function with service_role)
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
CREATE POLICY "audit_log_select_admin" ON public.audit_log FOR SELECT USING (public.is_admin());

-- App settings (admin only)
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "app_settings_admin" ON public.app_settings FOR ALL USING (public.is_admin());

-- -----------------------------------------------------------------------------
-- 11. ADMIN OVERRIDE POLICIES (super admin full access)
-- -----------------------------------------------------------------------------
CREATE POLICY "admin_businesses" ON public.businesses FOR ALL USING (public.is_admin());
CREATE POLICY "admin_deals" ON public.deals FOR ALL USING (public.is_admin());
CREATE POLICY "admin_events" ON public.events FOR ALL USING (public.is_admin());
CREATE POLICY "admin_event_tickets" ON public.event_tickets FOR ALL USING (public.is_admin());
CREATE POLICY "admin_jobs" ON public.jobs FOR ALL USING (public.is_admin());
CREATE POLICY "admin_reviews" ON public.reviews FOR ALL USING (public.is_admin());
CREATE POLICY "admin_review_replies" ON public.review_replies FOR ALL USING (public.is_admin());
CREATE POLICY "admin_orders_select" ON public.orders FOR SELECT USING (public.is_admin());
CREATE POLICY "admin_tickets_select" ON public.tickets FOR SELECT USING (public.is_admin());
CREATE POLICY "admin_notifications_select" ON public.notifications FOR SELECT USING (public.is_admin());
CREATE POLICY "admin_job_applications" ON public.job_applications FOR ALL USING (public.is_admin());
CREATE POLICY "admin_boosts" ON public.boosts FOR ALL USING (public.is_admin());

-- =============================================================================
-- END OF SCHEMA. Next: run HABRA_SUPABASE_CONFIG.md steps in Dashboard.
-- =============================================================================
