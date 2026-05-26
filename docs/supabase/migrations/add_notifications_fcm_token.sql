-- Add FCM token to profiles for push notifications.
-- Run in Supabase Dashboard → SQL Editor.
--
-- When a user logs in, the app stores their FCM token here.
-- Supabase Edge Functions or webhooks can use this to send push via FCM API.

ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- Index for finding users by token (optional, for cleanup)
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON public.profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- Ensure notifications table has image_url for rich notifications (optional)
ALTER TABLE public.notifications
ADD COLUMN IF NOT EXISTS image_url TEXT;
