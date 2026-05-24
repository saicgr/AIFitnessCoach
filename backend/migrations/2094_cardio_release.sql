-- Migration 2094 — "Cardio Gets Real" release (Phase A foundation)
--
-- Adds columns to existing tables — DOES NOT create parallel cardio metric
-- or VO2max history tables, because `public.cardio_metrics` (with
-- vo2_max_estimate, resting_hr, max_hr, fitness_age, measured_at, source)
-- already serves that purpose. The new `cardio_metric_snapshots` table is
-- ONLY for derived metrics that have no source table (race-predictor
-- outputs, ACWR ratio, weekly-distance rollups) — gives Custom Trends a
-- stable per-day history for these computed values.
--
-- Personal records are NOT duplicated into a new cardio_pr table —
-- `public.personal_records` already has weight_kg, reps, estimated_1rm_kg,
-- previous_1rm_kg, improvement_kg, improvement_percent, is_all_time_pr,
-- celebration_message. Adding `sport` + `is_first_time_activity` lets us
-- store cardio PRs in the same table by introducing new record_type values
-- ('longest_distance','fastest_mile','fastest_5k','fastest_10k',
--  'longest_duration_session','best_avg_speed','biggest_weekly_distance_km').
--
-- Readiness extension reuses `readiness_scores` table — no new table.
--
-- Both `cardio_logs` (imported sessions) and `cardio_sessions` (manual
-- in-app logs) receive the same set of new fields, since both surfaces
-- now need weather + dedup + privacy + auto-pause + indoor mode + tags.

BEGIN;

-- ---------------------------------------------------------------------------
-- users: week-start sync + distance-unit pref + route-privacy default
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS week_starts_sunday boolean,
  ADD COLUMN IF NOT EXISTS distance_unit text DEFAULT 'mi'
    CHECK (distance_unit IN ('mi','km')),
  ADD COLUMN IF NOT EXISTS route_privacy_meters integer DEFAULT 200
    CHECK (route_privacy_meters >= 0 AND route_privacy_meters <= 2000);

COMMENT ON COLUMN public.users.week_starts_sunday IS
  'NULL = use device locale default; true/false = explicit user choice. Synced from week_start_provider.';
COMMENT ON COLUMN public.users.distance_unit IS
  '"mi" or "km" — used for cardio splits, pace formatting, race-predictor display.';
COMMENT ON COLUMN public.users.route_privacy_meters IS
  'Default meters to obfuscate from start AND end of every shared route. 0 disables privacy globally.';

-- ---------------------------------------------------------------------------
-- cardio_logs: weather + S3-route + dedup + auto-pause + indoor + tags
-- ---------------------------------------------------------------------------
ALTER TABLE public.cardio_logs
  ADD COLUMN IF NOT EXISTS weather_json jsonb,
  ADD COLUMN IF NOT EXISTS route_polyline_s3_key text,
  ADD COLUMN IF NOT EXISTS dedup_group_id uuid,
  ADD COLUMN IF NOT EXISTS is_hidden_duplicate boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS paused_segments jsonb,
  ADD COLUMN IF NOT EXISTS indoor_metadata jsonb,
  ADD COLUMN IF NOT EXISTS tags text[];

COMMENT ON COLUMN public.cardio_logs.weather_json IS
  '{temp_c, humidity_pct, wind_kph, condition, source}. Populated post-log via weather_service. NULL for indoor or pre-2026-05.';
COMMENT ON COLUMN public.cardio_logs.route_polyline_s3_key IS
  'S3 key for route GPS polyline (list of [lat,lng,alt,ts]). Inline gps_polyline kept for <100-point short routes.';
COMMENT ON COLUMN public.cardio_logs.dedup_group_id IS
  'Set when multiple sources logged the same activity. Loser rows get is_hidden_duplicate=true; primary row dedup_group_id=its own id.';
COMMENT ON COLUMN public.cardio_logs.paused_segments IS
  'List of [{start_ts, end_ts}] for auto-pause-detected breaks (pace=0 >10s). Pace chart renders these as gaps.';
COMMENT ON COLUMN public.cardio_logs.indoor_metadata IS
  '{is_indoor:bool, treadmill_speed_kmh?:float, incline_pct?:float, source:"manual"|"step_estimate"}.';
COMMENT ON COLUMN public.cardio_logs.tags IS
  'Auto-derived flags: hill, negative_split, new_route, dawn_run, dusk_run, etc.';

-- ---------------------------------------------------------------------------
-- cardio_sessions (manual in-app cardio): same column set as cardio_logs
-- so the two surfaces stay symmetric. Existing weather_conditions varchar
-- is left intact for backward-compat; weather_json supersedes it.
-- ---------------------------------------------------------------------------
ALTER TABLE public.cardio_sessions
  ADD COLUMN IF NOT EXISTS weather_json jsonb,
  ADD COLUMN IF NOT EXISTS route_polyline_s3_key text,
  ADD COLUMN IF NOT EXISTS dedup_group_id uuid,
  ADD COLUMN IF NOT EXISTS is_hidden_duplicate boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS paused_segments jsonb,
  ADD COLUMN IF NOT EXISTS indoor_metadata jsonb,
  ADD COLUMN IF NOT EXISTS tags text[];

-- ---------------------------------------------------------------------------
-- readiness_scores: extend with RHR delta + weekly TRIMP for the
-- "Recovery readiness" tile + cardio_load_state ("undertrained" /
-- "balanced" / "overreaching"). All optional — service computes when data
-- is available; fields are NULL when no signal.
-- ---------------------------------------------------------------------------
ALTER TABLE public.readiness_scores
  ADD COLUMN IF NOT EXISTS rhr_baseline_bpm integer,
  ADD COLUMN IF NOT EXISTS rhr_today_bpm integer,
  ADD COLUMN IF NOT EXISTS rhr_delta_pct numeric,
  ADD COLUMN IF NOT EXISTS weekly_trimp numeric,
  ADD COLUMN IF NOT EXISTS cardio_load_state text
    CHECK (cardio_load_state IS NULL OR cardio_load_state IN ('undertrained','balanced','overreaching'));

-- ---------------------------------------------------------------------------
-- personal_records: extend to hold cardio PRs alongside strength PRs.
-- record_type vocabulary is convention (not enforced) to keep the table
-- generic across both PR families. Cardio PRs leave weight_kg/reps/1rm
-- NULL and use record_value/record_unit; sport carries 'running'/'cycling'/
-- 'walking'/'rowing'/etc.
-- ---------------------------------------------------------------------------
ALTER TABLE public.personal_records
  ADD COLUMN IF NOT EXISTS sport text,
  ADD COLUMN IF NOT EXISTS is_first_time_activity boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.personal_records.sport IS
  'For cardio PRs: running/cycling/walking/rowing/swimming/hiking. NULL for strength PRs.';
COMMENT ON COLUMN public.personal_records.is_first_time_activity IS
  'True for the first-ever activity of a sport — suppress confetti, render as "First time!" badge.';

-- ---------------------------------------------------------------------------
-- cardio_metric_snapshots: ONLY for derived metrics that have no source
-- table. Race-predictor outputs (predicted 5K/10K/half/marathon times),
-- ACWR ratio + acute_load + chronic_load, rolling weekly distance, longest
-- run window, fastest mile window. These are computed daily by
-- cardio_metric_snapshot_job and consumed by Custom Trends as stable
-- history points — without this, Custom Trends would have to recompute
-- the values on every chart render.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.cardio_metric_snapshots (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  snapshot_date date      NOT NULL,
  metric_key  text        NOT NULL,
  value_numeric numeric,
  meta        jsonb,
  computed_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, snapshot_date, metric_key)
);

COMMENT ON TABLE public.cardio_metric_snapshots IS
  'Daily snapshot store for DERIVED cardio metrics (race predictor, ACWR, rolling-window stats). Populated by cardio_metric_snapshot_job. Custom Trends reads from here.';
COMMENT ON COLUMN public.cardio_metric_snapshots.metric_key IS
  'race_predicted_5k_sec / race_predicted_10k_sec / race_predicted_half_sec / race_predicted_marathon_sec / training_load_acute / training_load_chronic / training_load_acwr / cardio_weekly_distance_m / cardio_longest_run_m / cardio_fastest_mile_sec / cardio_pace_avg_sec_per_km / cardio_weather_temp_at_run_c / refuel_carbs_recommended_g.';

CREATE INDEX IF NOT EXISTS idx_cardio_metric_snapshots_user_metric_date
  ON public.cardio_metric_snapshots (user_id, metric_key, snapshot_date DESC);

-- ---------------------------------------------------------------------------
-- Indexes for the cardio dedup query (user + sport + ± time window)
-- and for the dedup-group lookup on detail view.
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_cardio_logs_user_perf_activity
  ON public.cardio_logs (user_id, performed_at, activity_type);

CREATE INDEX IF NOT EXISTS idx_cardio_logs_dedup_group
  ON public.cardio_logs (dedup_group_id)
  WHERE dedup_group_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_cardio_sessions_user_started_type
  ON public.cardio_sessions (user_id, started_at, cardio_type);

CREATE INDEX IF NOT EXISTS idx_cardio_sessions_dedup_group
  ON public.cardio_sessions (dedup_group_id)
  WHERE dedup_group_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- Personal-records lookup for the cardio PR Ask-Coach context and for the
-- trophies sheet's cardio section.
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_personal_records_user_sport_current
  ON public.personal_records (user_id, sport, is_current_record)
  WHERE sport IS NOT NULL;

COMMIT;
