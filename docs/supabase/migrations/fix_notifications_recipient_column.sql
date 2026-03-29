-- Align `public.notifications` recipient column with the mobile app and docs (`user_id`).
-- Run in Supabase SQL Editor if PostgREST errors with:
--   column notifications.user_id does not exist
--
-- The app expects `user_id` (UUID, recipient = profiles.id / auth.uid()).
-- Override in the app only if you cannot migrate: NOTIFICATIONS_USER_ID_COLUMN=...
--
-- After running, open Table Editor → notifications and confirm `user_id` exists.
-- If RLS still fails, update policies so they use `user_id` (not `profile_id`).

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'user_id'
  ) THEN
    RAISE NOTICE 'notifications.user_id already exists; nothing to do.';
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'profile_id'
  ) THEN
    ALTER TABLE public.notifications RENAME COLUMN profile_id TO user_id;
    RAISE NOTICE 'Renamed notifications.profile_id -> user_id.';
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'notifications' AND column_name = 'recipient_id'
  ) THEN
    ALTER TABLE public.notifications RENAME COLUMN recipient_id TO user_id;
    RAISE NOTICE 'Renamed notifications.recipient_id -> user_id.';
    RETURN;
  END IF;

  RAISE EXCEPTION
    'notifications has no user_id, profile_id, or recipient_id. Add user_id UUID REFERENCES public.profiles(id) and backfill.';
END $$;
