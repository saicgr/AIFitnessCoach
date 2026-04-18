-- Migration 1941: per-user leaderboard privacy toggles.
-- Three independent flags, safe defaults (visible + identified + stats-visible).

ALTER TABLE users ADD COLUMN IF NOT EXISTS show_on_leaderboard   BOOLEAN NOT NULL DEFAULT TRUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS leaderboard_anonymous BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_stats_visible BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN users.show_on_leaderboard IS
'Master. FALSE = excluded from Discover leaderboards entirely (not counted in percentile pool, not shown in Near You / Rising Stars / Top 10).';

COMMENT ON COLUMN users.leaderboard_anonymous IS
'TRUE = shown on leaderboard but name/username/avatar masked as "Anonymous athlete". Still ranked.';

COMMENT ON COLUMN users.profile_stats_visible IS
'TRUE = bio + 6-axis fitness radar visible when another user taps my leaderboard entry. FALSE = rank + metric only on peek.';

CREATE INDEX IF NOT EXISTS idx_users_show_on_leaderboard
  ON users(show_on_leaderboard)
  WHERE show_on_leaderboard = TRUE;
