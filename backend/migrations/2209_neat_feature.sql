-- 2209_neat_feature.sql
-- Backfills missing NEAT-feature tables that are referenced by:
--   services/neat_service_helpers.py
--   services/neat_service_helpers_part2.py
--   api/v1/neat.py
--   api/v1/neat_endpoints.py
--
-- The other NEAT tables already exist on the live DB:
--   neat_goals, neat_hourly_activity, neat_streaks, user_neat_achievements,
--   neat_reminder_preferences, neat_daily_scores
--
-- Idempotent.

-- ----------------------------------------------------------------------------
-- daily_neat_activity — aggregated per-day NEAT roll-up written by
-- services.neat_service_helpers._update_daily_summary.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS daily_neat_activity (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date            date NOT NULL,
  total_steps              integer NOT NULL DEFAULT 0,
  step_goal                integer,
  goal_met                 boolean NOT NULL DEFAULT false,
  active_hours             integer NOT NULL DEFAULT 0,
  sedentary_hours          integer NOT NULL DEFAULT 0,
  neat_score               integer,
  longest_sedentary_period integer,
  created_at               timestamptz NOT NULL DEFAULT now(),
  updated_at               timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT daily_neat_activity_user_date_uq UNIQUE (user_id, activity_date)
);
CREATE INDEX IF NOT EXISTS idx_daily_neat_activity_user_date
  ON daily_neat_activity(user_id, activity_date DESC);

ALTER TABLE daily_neat_activity ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS daily_neat_activity_owner ON daily_neat_activity;
CREATE POLICY daily_neat_activity_owner ON daily_neat_activity
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- hourly_neat_activity — per-hour bucket written by record_hourly_activity.
-- Distinct from existing neat_hourly_activity (which uses different columns
-- — was_sedentary/met_hourly_goal/active_minutes). The helper writes
-- is_active/source/recorded_at.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS hourly_neat_activity (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  activity_date date NOT NULL,
  hour          smallint NOT NULL CHECK (hour BETWEEN 0 AND 23),
  steps         integer NOT NULL DEFAULT 0,
  is_active     boolean NOT NULL DEFAULT false,
  source        text NOT NULL DEFAULT 'unknown',
  recorded_at   timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT hourly_neat_activity_user_date_hour_uq UNIQUE (user_id, activity_date, hour)
);
CREATE INDEX IF NOT EXISTS idx_hourly_neat_activity_user_date
  ON hourly_neat_activity(user_id, activity_date, hour);

ALTER TABLE hourly_neat_activity ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS hourly_neat_activity_owner ON hourly_neat_activity;
CREATE POLICY hourly_neat_activity_owner ON hourly_neat_activity
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- user_neat_settings — per-user step goal + reminder prefs (helper writes
-- both goal + reminder fields onto the same row).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_neat_settings (
  id                          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                     uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  current_goal                integer NOT NULL DEFAULT 5000,
  baseline_steps              integer NOT NULL DEFAULT 0,
  week_number                 integer NOT NULL DEFAULT 1,
  -- reminder preferences read/written by part2.get_reminder_preferences /
  -- update_reminder_preferences
  reminder_enabled            boolean NOT NULL DEFAULT true,
  reminder_interval_minutes   integer NOT NULL DEFAULT 60,
  quiet_hours_start           text   NOT NULL DEFAULT '22:00',
  quiet_hours_end             text   NOT NULL DEFAULT '07:00',
  work_hours_only             boolean NOT NULL DEFAULT false,
  work_hours_start            text   NOT NULL DEFAULT '09:00',
  work_hours_end              text   NOT NULL DEFAULT '17:00',
  min_sedentary_hours         integer NOT NULL DEFAULT 2,
  exclude_weekends            boolean NOT NULL DEFAULT false,
  created_at                  timestamptz NOT NULL DEFAULT now(),
  updated_at                  timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE user_neat_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_neat_settings_owner ON user_neat_settings;
CREATE POLICY user_neat_settings_owner ON user_neat_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- user_neat_streaks — per-user-per-streak-type counts (helper file).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_neat_streaks (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  streak_type     text NOT NULL,
  current_streak  integer NOT NULL DEFAULT 0,
  longest_streak  integer NOT NULL DEFAULT 0,
  last_updated    timestamptz NOT NULL DEFAULT now(),
  created_at      timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT user_neat_streaks_user_type_uq UNIQUE (user_id, streak_type)
);
CREATE INDEX IF NOT EXISTS idx_user_neat_streaks_user
  ON user_neat_streaks(user_id);

ALTER TABLE user_neat_streaks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_neat_streaks_owner ON user_neat_streaks;
CREATE POLICY user_neat_streaks_owner ON user_neat_streaks
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- neat_scores — per-day calculated score (api/v1/neat.py /score/* endpoints).
-- This is the *score* table (separate from neat_daily_scores which already
-- exists and uses different columns).
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS neat_scores (
  id                     uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  score_date             date NOT NULL,
  total_score            integer NOT NULL DEFAULT 0,
  step_score             integer NOT NULL DEFAULT 0,
  consistency_score      integer NOT NULL DEFAULT 0,
  active_hours_score     integer NOT NULL DEFAULT 0,
  movement_breaks_score  integer NOT NULL DEFAULT 0,
  total_steps            integer NOT NULL DEFAULT 0,
  active_hours           integer NOT NULL DEFAULT 0,
  movement_breaks        integer NOT NULL DEFAULT 0,
  step_goal_met          boolean NOT NULL DEFAULT false,
  grade                  text NOT NULL DEFAULT 'C',
  percentile             numeric,
  message                text NOT NULL DEFAULT '',
  calculated_at          timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT neat_scores_user_date_uq UNIQUE (user_id, score_date)
);
CREATE INDEX IF NOT EXISTS idx_neat_scores_user_date
  ON neat_scores(user_id, score_date DESC);
CREATE INDEX IF NOT EXISTS idx_neat_scores_user_goal_met
  ON neat_scores(user_id, step_goal_met);

ALTER TABLE neat_scores ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS neat_scores_owner ON neat_scores;
CREATE POLICY neat_scores_owner ON neat_scores
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- neat_achievement_definitions — global config/lookup, NOT user-scoped.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS neat_achievement_definitions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code        text UNIQUE,
  name        text NOT NULL,
  description text,
  category    text NOT NULL,
  tier        text,
  threshold   numeric NOT NULL DEFAULT 0,
  icon        text,
  points      integer NOT NULL DEFAULT 0,
  is_active   boolean NOT NULL DEFAULT true,
  sort_order  integer NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_neat_achievement_defs_active_sort
  ON neat_achievement_definitions(is_active, sort_order);

-- Public lookup — anyone authenticated can read; only service role writes.
ALTER TABLE neat_achievement_definitions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS neat_achievement_definitions_read ON neat_achievement_definitions;
CREATE POLICY neat_achievement_definitions_read
  ON neat_achievement_definitions FOR SELECT USING (true);

-- ----------------------------------------------------------------------------
-- neat_settings — used by api/v1/watch_sync.py to look up daily_step_goal
-- for the watch's activity-rings display. Per-user row.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS neat_settings (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  daily_step_goal integer NOT NULL DEFAULT 10000,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

ALTER TABLE neat_settings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS neat_settings_owner ON neat_settings;
CREATE POLICY neat_settings_owner ON neat_settings
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
