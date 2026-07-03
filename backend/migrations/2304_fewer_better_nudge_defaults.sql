-- ============================================================================
-- 2304: "Fewer, better" nudge defaults + unread coach-message tracking
-- ============================================================================
-- Context: the push nudge engine had never fired in production (no cron
-- trigger — push_nudge_log was empty), so no user has ever experienced these
-- values; retuning them wholesale is safe. Direct user feedback: notifications
-- felt "many and very dismissable". New defaults: max 3 personal nudges/day,
-- win-back ("guilt") ladder opt-in instead of opt-out.

-- 1) Daily cap 4 → 3 (only where still at the old seeded default)
UPDATE users
SET notification_preferences = notification_preferences || '{"daily_nudge_limit": 3}'::jsonb
WHERE notification_preferences IS NOT NULL
  AND (notification_preferences->>'daily_nudge_limit')::int = 4;

-- 2) Win-back / guilt ladder OFF by default (engine never fired; seeded value,
--    not a user choice — the Settings toggle remains for opt-in)
UPDATE users
SET notification_preferences = notification_preferences || '{"guilt_notifications": false}'::jsonb
WHERE notification_preferences IS NOT NULL
  AND (notification_preferences->>'guilt_notifications')::boolean = true;

-- 3) Unread coach-message tracking: server-side last-seen stamp for the
--    coach chat (feeds the Coach-tab badge via /home/bootstrap)
ALTER TABLE users ADD COLUMN IF NOT EXISTS coach_chat_last_seen_at TIMESTAMPTZ;

COMMENT ON COLUMN users.coach_chat_last_seen_at IS
  'Last time the user opened the coach chat; proactive chat_history rows newer than this count as unread (Coach tab badge).';
