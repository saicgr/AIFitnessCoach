-- Migration 1951: tier-persistence state machine + idempotency audit + XP
-- lookup seed. Supports the Discover engagement overhaul (Sections A + B +
-- parts of C from the plan file).
--
-- Four new tables + one seed table:
--   * tier_streaks             — current "consecutive weeks in tier" counter
--                                 per user per board. Reset on drop.
--   * user_tier_history        — immutable per-week record of tier achieved.
--   * user_tier_cumulative     — lifetime counters (weeks-in-topN, peak rank,
--                                 peak tier) per user per board.
--   * weekly_tier_rewards_audit — idempotency guard. ALL XP awards INSERT
--                                 here first. Conflict = already awarded, skip.
--   * tier_persistence_xp      — static lookup (board, tier, weeks)→(xp,badge).
--
-- Per plan file §Risks: Volume + Streaks boards seed at 60% of XP amounts so
-- we don't inflate economies on boards where activity is naturally repetitive.
-- All values rounded to nearest 5 for clean UX display.
--
-- Idempotency semantics:
--   weekly_tier_rewards_audit uses a functional unique index so (user_id,
--   week_start, board_type, reward_kind, COALESCE(badge_id, '')) is unique.
--   Bare UNIQUE constraint would treat NULLs as distinct, defeating the guard
--   for reward_kind rows with no badge (peak_rank, silent rewards).

-- ─── tier_streaks ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS tier_streaks (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  tier TEXT NOT NULL CHECK (tier IN ('top1', 'top5', 'top10', 'top25', 'active', 'starter')),
  current_weeks INT NOT NULL DEFAULT 0 CHECK (current_weeks >= 0),
  last_week_start DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, board_type)
);

CREATE INDEX IF NOT EXISTS idx_tier_streaks_tier ON tier_streaks(board_type, tier) WHERE current_weeks > 0;

ALTER TABLE tier_streaks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ts_select_own ON tier_streaks;
CREATE POLICY ts_select_own ON tier_streaks FOR SELECT USING (true);  -- public read (for row enrichment)
DROP POLICY IF EXISTS ts_service_write ON tier_streaks;
CREATE POLICY ts_service_write ON tier_streaks FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT ON tier_streaks TO authenticated;
GRANT ALL ON tier_streaks TO service_role;


-- ─── user_tier_history ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_tier_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  tier TEXT NOT NULL,
  percentile NUMERIC,
  rank INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, week_start, board_type)
);

CREATE INDEX IF NOT EXISTS idx_tier_history_user_week ON user_tier_history(user_id, week_start DESC);
CREATE INDEX IF NOT EXISTS idx_tier_history_week_board ON user_tier_history(week_start, board_type);

ALTER TABLE user_tier_history ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS uth_select_public ON user_tier_history;
CREATE POLICY uth_select_public ON user_tier_history FOR SELECT USING (true);
DROP POLICY IF EXISTS uth_service_write ON user_tier_history;
CREATE POLICY uth_service_write ON user_tier_history FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT ON user_tier_history TO authenticated;
GRANT ALL ON user_tier_history TO service_role;


-- ─── user_tier_cumulative ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS user_tier_cumulative (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  weeks_in_top25 INT NOT NULL DEFAULT 0,
  weeks_in_top10 INT NOT NULL DEFAULT 0,
  weeks_in_top5 INT NOT NULL DEFAULT 0,
  weeks_in_top1 INT NOT NULL DEFAULT 0,
  peak_rank INT,
  peak_tier TEXT,
  peak_achieved_at TIMESTAMPTZ,
  last_tier_entry_week DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, board_type)
);

CREATE INDEX IF NOT EXISTS idx_cumulative_peak_tier ON user_tier_cumulative(peak_tier) WHERE peak_tier IS NOT NULL;

ALTER TABLE user_tier_cumulative ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS utc_select_public ON user_tier_cumulative;
CREATE POLICY utc_select_public ON user_tier_cumulative FOR SELECT USING (true);
DROP POLICY IF EXISTS utc_service_write ON user_tier_cumulative;
CREATE POLICY utc_service_write ON user_tier_cumulative FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT ON user_tier_cumulative TO authenticated;
GRANT ALL ON user_tier_cumulative TO service_role;


-- ─── weekly_tier_rewards_audit ─────────────────────────────────────────────
-- Core idempotency guard. Every XP award path INSERTs here first with
-- ON CONFLICT DO NOTHING. If the insert returns zero rows, reward was
-- already given — skip. This survives retries, duplicate cron invocations,
-- and concurrent rewarders.
CREATE TABLE IF NOT EXISTS weekly_tier_rewards_audit (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  week_start DATE NOT NULL,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  tier TEXT,
  consecutive_weeks INT,
  xp_awarded INT NOT NULL DEFAULT 0,
  badge_id TEXT,                      -- NULL for silent/no-badge rewards
  reward_kind TEXT NOT NULL,           -- tier_persistence, first_time_tier, cumulative_weeks, peak_rank, rising_star, phoenix_rising, shield_save
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Functional unique index — treats NULL badge_id as '' so peak_rank-style
-- silent rewards still dedupe correctly.
CREATE UNIQUE INDEX IF NOT EXISTS uq_tier_rewards_audit
  ON weekly_tier_rewards_audit (user_id, week_start, board_type, reward_kind, COALESCE(badge_id, ''));

CREATE INDEX IF NOT EXISTS idx_audit_user_week ON weekly_tier_rewards_audit(user_id, week_start DESC);

ALTER TABLE weekly_tier_rewards_audit ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS wtra_select_own ON weekly_tier_rewards_audit;
CREATE POLICY wtra_select_own ON weekly_tier_rewards_audit FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS wtra_service_write ON weekly_tier_rewards_audit;
CREATE POLICY wtra_service_write ON weekly_tier_rewards_audit FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT ON weekly_tier_rewards_audit TO authenticated;
GRANT ALL ON weekly_tier_rewards_audit TO service_role;


-- ─── tier_persistence_xp ───────────────────────────────────────────────────
-- Static lookup table. award_tier_rewards_for_week reads (board, tier, weeks)
-- to determine XP + badge at milestone.
-- Volume + Streaks boards use 60% of XP-board values (see plan §Risks).
-- Badges only defined at 3w/5w/10w — 1w milestones are XP only.
CREATE TABLE IF NOT EXISTS tier_persistence_xp (
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  tier TEXT NOT NULL CHECK (tier IN ('top1', 'top5', 'top10', 'top25')),
  consecutive_weeks INT NOT NULL CHECK (consecutive_weeks IN (1, 3, 5, 10)),
  xp INT NOT NULL,
  badge_id TEXT,
  PRIMARY KEY (board_type, tier, consecutive_weeks)
);

-- XP board seed (100%)
INSERT INTO tier_persistence_xp (board_type, tier, consecutive_weeks, xp, badge_id) VALUES
  ('xp', 'top1', 1, 100, NULL),
  ('xp', 'top1', 3, 500, 'discover_podium_hattrick_top1_3w_xp'),
  ('xp', 'top1', 5, 2000, 'discover_iron_throne_top1_5w_xp'),
  ('xp', 'top1', 10, 10000, 'discover_immortal_top1_10w_xp'),
  ('xp', 'top5', 1, 75, NULL),
  ('xp', 'top5', 3, 350, 'discover_podium_hattrick_top5_3w_xp'),
  ('xp', 'top5', 5, 1200, 'discover_iron_throne_top5_5w_xp'),
  ('xp', 'top5', 10, 5000, 'discover_immortal_top5_10w_xp'),
  ('xp', 'top10', 1, 50, NULL),
  ('xp', 'top10', 3, 200, 'discover_podium_hattrick_top10_3w_xp'),
  ('xp', 'top10', 5, 750, 'discover_iron_throne_top10_5w_xp'),
  ('xp', 'top10', 10, 2500, 'discover_immortal_top10_10w_xp'),
  ('xp', 'top25', 1, 25, NULL),
  ('xp', 'top25', 3, 100, 'discover_podium_hattrick_top25_3w_xp'),
  ('xp', 'top25', 5, 300, 'discover_iron_throne_top25_5w_xp'),
  ('xp', 'top25', 10, 1000, 'discover_immortal_top25_10w_xp')
ON CONFLICT DO NOTHING;

-- Volume board seed (60%, rounded to nearest 5)
INSERT INTO tier_persistence_xp (board_type, tier, consecutive_weeks, xp, badge_id) VALUES
  ('volume', 'top1', 1, 60, NULL),
  ('volume', 'top1', 3, 300, 'discover_podium_hattrick_top1_3w_volume'),
  ('volume', 'top1', 5, 1200, 'discover_iron_throne_top1_5w_volume'),
  ('volume', 'top1', 10, 6000, 'discover_immortal_top1_10w_volume'),
  ('volume', 'top5', 1, 45, NULL),
  ('volume', 'top5', 3, 210, 'discover_podium_hattrick_top5_3w_volume'),
  ('volume', 'top5', 5, 720, 'discover_iron_throne_top5_5w_volume'),
  ('volume', 'top5', 10, 3000, 'discover_immortal_top5_10w_volume'),
  ('volume', 'top10', 1, 30, NULL),
  ('volume', 'top10', 3, 120, 'discover_podium_hattrick_top10_3w_volume'),
  ('volume', 'top10', 5, 450, 'discover_iron_throne_top10_5w_volume'),
  ('volume', 'top10', 10, 1500, 'discover_immortal_top10_10w_volume'),
  ('volume', 'top25', 1, 15, NULL),
  ('volume', 'top25', 3, 60, 'discover_podium_hattrick_top25_3w_volume'),
  ('volume', 'top25', 5, 180, 'discover_iron_throne_top25_5w_volume'),
  ('volume', 'top25', 10, 600, 'discover_immortal_top25_10w_volume')
ON CONFLICT DO NOTHING;

-- Streaks board seed (60%, same amounts as volume)
INSERT INTO tier_persistence_xp (board_type, tier, consecutive_weeks, xp, badge_id) VALUES
  ('streaks', 'top1', 1, 60, NULL),
  ('streaks', 'top1', 3, 300, 'discover_podium_hattrick_top1_3w_streaks'),
  ('streaks', 'top1', 5, 1200, 'discover_iron_throne_top1_5w_streaks'),
  ('streaks', 'top1', 10, 6000, 'discover_immortal_top1_10w_streaks'),
  ('streaks', 'top5', 1, 45, NULL),
  ('streaks', 'top5', 3, 210, 'discover_podium_hattrick_top5_3w_streaks'),
  ('streaks', 'top5', 5, 720, 'discover_iron_throne_top5_5w_streaks'),
  ('streaks', 'top5', 10, 3000, 'discover_immortal_top5_10w_streaks'),
  ('streaks', 'top10', 1, 30, NULL),
  ('streaks', 'top10', 3, 120, 'discover_podium_hattrick_top10_3w_streaks'),
  ('streaks', 'top10', 5, 450, 'discover_iron_throne_top10_5w_streaks'),
  ('streaks', 'top10', 10, 1500, 'discover_immortal_top10_10w_streaks'),
  ('streaks', 'top25', 1, 15, NULL),
  ('streaks', 'top25', 3, 60, 'discover_podium_hattrick_top25_3w_streaks'),
  ('streaks', 'top25', 5, 180, 'discover_iron_throne_top25_5w_streaks'),
  ('streaks', 'top25', 10, 600, 'discover_immortal_top25_10w_streaks')
ON CONFLICT DO NOTHING;

GRANT SELECT ON tier_persistence_xp TO authenticated, service_role;
