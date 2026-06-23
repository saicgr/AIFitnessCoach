-- 2280_push_nudge_open_tracking.sql
-- Adaptive per-user tone (Goal 1F) + the only feedback loop on notification
-- effectiveness: record WHICH tone was sent and WHETHER the user opened it.
--
--   tone       — message tone sent (gentle / balanced / tough_love), written
--                by push_nudge_cron._try_dedup_insert.
--   opened_at  — stamped by POST /notifications/opened when the user taps the
--                push. The bandit (_select_tone_for_user) learns per-user open
--                rates per tone from these two columns.

ALTER TABLE public.push_nudge_log
  ADD COLUMN IF NOT EXISTS tone text;

ALTER TABLE public.push_nudge_log
  ADD COLUMN IF NOT EXISTS opened_at timestamptz;

COMMENT ON COLUMN public.push_nudge_log.tone IS
  'Message tone sent (gentle/balanced/tough_love). Feeds the adaptive-tone bandit.';
COMMENT ON COLUMN public.push_nudge_log.opened_at IS
  'When the user tapped this push (POST /notifications/opened). NULL = not opened.';
