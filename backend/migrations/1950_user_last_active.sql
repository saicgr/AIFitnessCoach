-- Migration 1950: surface `users.last_active_at` so the Discover tab can show
-- a green activity pulse on each leaderboard row (D section "Activity pulse").
-- `country_code` already exists on users (VARCHAR) so no-op there.
--
-- Trigger attaches only to workout_logs (NOT xp_transactions) to avoid update
-- storms during workout completion where many xp_transactions rows fire.
-- Debounced to 5 minutes — UI's "active in last 24h" doesn't need sub-minute
-- precision. One UPDATE per completed workout — negligible cost.

ALTER TABLE users ADD COLUMN IF NOT EXISTS last_active_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS idx_users_last_active_at ON users(last_active_at);

-- Debouncing trigger function
CREATE OR REPLACE FUNCTION bump_user_last_active()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE users
     SET last_active_at = NOW()
   WHERE id = NEW.user_id
     AND (last_active_at IS NULL OR last_active_at < NOW() - INTERVAL '5 minutes');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_bump_last_active ON workout_logs;
CREATE TRIGGER trg_bump_last_active
  AFTER INSERT ON workout_logs
  FOR EACH ROW
  EXECUTE FUNCTION bump_user_last_active();

-- Backfill from existing workout activity so the column isn't empty on day one.
UPDATE users u
   SET last_active_at = sub.max_at
  FROM (
    SELECT user_id, MAX(completed_at) AS max_at
      FROM workout_logs
     WHERE status = 'completed' AND completed_at IS NOT NULL
     GROUP BY user_id
  ) sub
 WHERE u.id = sub.user_id
   AND (u.last_active_at IS NULL OR u.last_active_at < sub.max_at);
