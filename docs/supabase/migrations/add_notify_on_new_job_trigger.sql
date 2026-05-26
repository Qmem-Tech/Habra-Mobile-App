-- When a new job is posted, create notifications for users who have FCM tokens.
-- Run AFTER add_notifications_fcm_token.sql.
--
-- These notifications appear in the app's notification list. Push delivery
-- requires a Supabase Edge Function (see docs/PUSH_NOTIFICATIONS_SETUP.md).

CREATE OR REPLACE FUNCTION public.notify_users_on_new_job()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  business_name TEXT;
BEGIN
  SELECT name INTO business_name FROM public.businesses WHERE id = NEW.business_id;

  INSERT INTO public.notifications (user_id, title, body, type, data)
  SELECT
    p.id,
    'New Job Posted',
    COALESCE(business_name, 'A business') || ' posted: ' || NEW.title,
    'job',
    jsonb_build_object('action_id', NEW.id, 'job_id', NEW.id)
  FROM public.profiles p
  WHERE p.fcm_token IS NOT NULL
    AND p.id != (SELECT owner_id FROM public.businesses WHERE id = NEW.business_id);

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_job_created_notify ON public.jobs;
CREATE TRIGGER on_job_created_notify
  AFTER INSERT ON public.jobs
  FOR EACH ROW EXECUTE FUNCTION public.notify_users_on_new_job();
