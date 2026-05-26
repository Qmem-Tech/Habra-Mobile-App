-- When a business listing is approved, notify the owner (in-app row).
-- Push delivery: ensure FCM token sync in the app + an Edge Function or webhook
-- that sends FCM HTTP v1 when `notifications` rows are inserted (see docs/PUSH_NOTIFICATIONS_SETUP.md).
-- Transactional email: use Supabase Auth hooks, Resend, or a separate Edge Function — not covered here.

CREATE OR REPLACE FUNCTION public.notify_owner_on_business_approved()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  owner uuid;
BEGIN
  IF TG_OP <> 'UPDATE' THEN
    RETURN NEW;
  END IF;
  IF COALESCE(OLD.approval_status, '') = 'approved' THEN
    RETURN NEW;
  END IF;
  IF COALESCE(NEW.approval_status, '') <> 'approved' THEN
    RETURN NEW;
  END IF;

  owner := NEW.owner_id;
  IF owner IS NULL THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  VALUES (
    owner,
    'Business approved',
    COALESCE(NEW.name, 'Your business') || ' is live on Habra.',
    'business_approved',
    jsonb_build_object(
      'type', 'business_approved',
      'business_id', NEW.id::text
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS tr_business_approved_notify ON public.businesses;
CREATE TRIGGER tr_business_approved_notify
  AFTER UPDATE OF approval_status ON public.businesses
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_owner_on_business_approved();

COMMENT ON FUNCTION public.notify_owner_on_business_approved() IS
  'Inserts an in-app notification when approval_status becomes approved';
