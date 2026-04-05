-- Owner replies (dashboard "Reply to Review"). Required for posting; replied_at is optional (app retries without it).
ALTER TABLE public.reviews
  ADD COLUMN IF NOT EXISTS reply_text TEXT,
  ADD COLUMN IF NOT EXISTS replied_at TIMESTAMPTZ;

COMMENT ON COLUMN public.reviews.reply_text IS 'Business owner public reply to the review';
COMMENT ON COLUMN public.reviews.replied_at IS 'When the owner reply was posted';
