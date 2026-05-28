-- 2212_misc_feature_tables.sql
-- Misc small feature tables whose calling code is in production but whose
-- create-table migration was never shipped.
--
-- Callsites:
--   api/v1/fasting_impact.py            -> fasting_impact_analysis
--   api/v1/skill_progressions.py        -> skill_attempt_logs
--   api/v1/subscription_transparency.py -> subscription_transparency_events, user_trial_status
--   api/v1/subscription_context.py      -> user_trial_status
--   api/v1/consistency_endpoints.py     -> streak_recovery_attempts
--
-- Idempotent.

-- ============================================================================
-- fasting_impact_analysis — per-user fasting effect snapshot.
-- Written by api/v1/fasting_impact.py:866 via .insert(analysis_record).
-- ============================================================================
CREATE TABLE IF NOT EXISTS fasting_impact_analysis (
  id                                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                                  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  period                                   text NOT NULL,
  analysis_date                            timestamptz,
  avg_weight_fasting_days                  numeric,
  avg_weight_non_fasting_days              numeric,
  weight_trend_fasting                     numeric,
  workouts_on_fasting_days                 integer,
  workouts_on_non_fasting_days             integer,
  avg_workout_completion_fasting           numeric,
  avg_workout_completion_non_fasting       numeric,
  goals_hit_on_fasting_days                integer,
  goals_hit_on_non_fasting_days            integer,
  goal_completion_rate_fasting             numeric,
  goal_completion_rate_non_fasting         numeric,
  correlation_score                        numeric,
  fasting_impact_summary                   text,
  recommendations                          jsonb,
  created_at                               timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_fasting_impact_analysis_user_created
  ON fasting_impact_analysis(user_id, created_at DESC);

ALTER TABLE fasting_impact_analysis ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS fasting_impact_analysis_owner ON fasting_impact_analysis;
CREATE POLICY fasting_impact_analysis_owner ON fasting_impact_analysis
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- skill_attempt_logs — per-attempt log for skill progressions.
-- Written by api/v1/skill_progressions.py:650 .insert(attempt_data).
-- ============================================================================
CREATE TABLE IF NOT EXISTS skill_attempt_logs (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  chain_id      uuid NOT NULL,
  step_order    integer NOT NULL,
  reps          integer NOT NULL DEFAULT 0,
  sets          integer NOT NULL DEFAULT 1,
  hold_seconds  integer,
  success       boolean NOT NULL DEFAULT false,
  notes         text,
  attempted_at  timestamptz NOT NULL DEFAULT now(),
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_skill_attempt_logs_user_chain_time
  ON skill_attempt_logs(user_id, chain_id, attempted_at DESC);

ALTER TABLE skill_attempt_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS skill_attempt_logs_owner ON skill_attempt_logs;
CREATE POLICY skill_attempt_logs_owner ON skill_attempt_logs
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- subscription_transparency_events — audit log of pricing/trial events shown
-- to the user. Written by api/v1/subscription_transparency.py:167.
-- user_id is nullable because the same endpoint logs pre-signup events keyed
-- by device_id only.
-- ============================================================================
CREATE TABLE IF NOT EXISTS subscription_transparency_events (
  id           uuid PRIMARY KEY,                      -- caller supplies uuid4()
  event_type   text NOT NULL,
  user_id      uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id    text,
  session_id   text,
  event_data   jsonb,
  app_version  text,
  platform     text,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_subscription_transparency_user_type
  ON subscription_transparency_events(user_id, event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_subscription_transparency_device_type
  ON subscription_transparency_events(device_id, event_type, created_at DESC)
  WHERE device_id IS NOT NULL;

ALTER TABLE subscription_transparency_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS subscription_transparency_events_owner_read
  ON subscription_transparency_events;
CREATE POLICY subscription_transparency_events_owner_read
  ON subscription_transparency_events FOR SELECT
  USING (user_id IS NULL OR auth.uid() = user_id);
DROP POLICY IF EXISTS subscription_transparency_events_owner_insert
  ON subscription_transparency_events;
CREATE POLICY subscription_transparency_events_owner_insert
  ON subscription_transparency_events FOR INSERT
  WITH CHECK (user_id IS NULL OR auth.uid() = user_id);

-- ============================================================================
-- user_trial_status — denormalized trial state used by trial-status APIs.
-- Materialized as a real table (not a view) because the calling code writes
-- features_used + reminder_sent flags that don't exist on user_subscriptions.
-- Callsites: api/v1/subscription_transparency.py:198,250,271 and
--            api/v1/subscription_context.py:399.
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_trial_status (
  id                   uuid PRIMARY KEY,                -- caller supplies uuid4()
  user_id              uuid NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
  trial_start_date     timestamptz NOT NULL,
  trial_end_date       timestamptz NOT NULL,
  trial_plan           text NOT NULL,
  trial_status         text NOT NULL DEFAULT 'active',
  reminder_sent_day_5  boolean NOT NULL DEFAULT false,
  reminder_sent_day_7  boolean NOT NULL DEFAULT false,
  features_used        jsonb NOT NULL DEFAULT '[]'::jsonb,
  created_at           timestamptz NOT NULL DEFAULT now(),
  updated_at           timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_trial_status_status_end
  ON user_trial_status(trial_status, trial_end_date);

ALTER TABLE user_trial_status ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_trial_status_owner ON user_trial_status;
CREATE POLICY user_trial_status_owner ON user_trial_status
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- streak_recovery_attempts — per-attempt log for streak recovery flow.
-- Written by api/v1/consistency_endpoints.py:332 + updated at :391.
-- ============================================================================
CREATE TABLE IF NOT EXISTS streak_recovery_attempts (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id                  uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  previous_streak_length   integer NOT NULL DEFAULT 0,
  days_since_last_workout  integer NOT NULL DEFAULT 0,
  recovery_type            text NOT NULL,
  motivation_message       text,
  recovery_workout_id      uuid,
  was_successful           boolean,
  completed_at             timestamptz,
  created_at               timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_streak_recovery_user_created
  ON streak_recovery_attempts(user_id, created_at DESC);

ALTER TABLE streak_recovery_attempts ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS streak_recovery_attempts_owner ON streak_recovery_attempts;
CREATE POLICY streak_recovery_attempts_owner ON streak_recovery_attempts
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ============================================================================
-- NOTE: health_metrics is NOT created here.
-- api/v1/cardio.py reads only `resting_heart_rate` from `health_metrics`
-- ordered by `recorded_at desc limit 1`. That value already lives on
-- `daily_activity.resting_heart_rate` (ordered by `activity_date`). Creating
-- a duplicate table would split the truth source — instead, cardio.py is
-- updated to read from daily_activity (see code follow-up).
-- ============================================================================
