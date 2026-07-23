-- ============================================================================
-- Migration 2320: diabetes_profiles + favorite_superset_pairs write-path repair
-- ============================================================================
-- Column-drift sweep 2026-07-21. Same failure mode as 2310 (which repaired the
-- glucose-alerts / medications write paths in this same feature area):
-- PostgREST rejects the ENTIRE payload when one key is not a real column
-- (PGRST204 / 42703), so a single phantom key means nothing persists at all.
--
-- BUG 1 — saving a diabetes profile has never worked.
--   api/v1/diabetes.py POST /diabetes/profile wrote 8 keys that are not
--   columns of diabetes_profiles (created by migration 114):
--     a1c_target, target_glucose_min_mg_dl, target_glucose_max_mg_dl,
--     fasting_target_min_mg_dl, fasting_target_max_mg_dl,
--     notifications_enabled, low_glucose_alert_threshold,
--     high_glucose_alert_threshold
--   So every INSERT 42703'd — the endpoint never created a profile, and
--   PATCH /diabetes/profile/{user_id}/targets (which splatted the same request
--   field names into an UPDATE) never changed a target.
--
--   Three of those are pure NAME DRIFT and are fixed in code, not here — the
--   columns already exist under migration 114's names:
--     target_glucose_min_mg_dl -> target_glucose_low   (INTEGER, NOT NULL)
--     target_glucose_max_mg_dl -> target_glucose_high  (INTEGER, NOT NULL)
--     a1c_target               -> target_a1c           (DECIMAL(4,2))
--   target_glucose_low/high are the operative pair: the time-in-range
--   aggregation in migration 114 (calculate_daily_glucose_summary) reads them.
--
--   The remaining five have no equivalent column and are added below. They are
--   clinical settings the caller explicitly sets on the profile-create request
--   and they are read back by DiabetesProfileResponse in api/v1/diabetes.py.
--
--   On the fasting pair specifically: diabetes_profiles already has
--   `target_glucose_fasting INTEGER NOT NULL DEFAULT 100`, but that is a SINGLE
--   fasting target, whereas the API (and the Flutter DiabetesProfile model,
--   target_fasting_min / target_fasting_max) models fasting as a RANGE. Folding
--   a min and a max onto one column would silently discard one of the two
--   user-set values, so the range gets its own two columns. The legacy
--   single-value column is left untouched (it has no readers; nothing here
--   depends on it) rather than dropped, which would be a destructive change
--   outside the scope of a write-path repair.
--
--   On the two alert thresholds + notifications_enabled: glucose_alerts also
--   stores per-alert-type thresholds (alert_type/threshold_value/enabled, set
--   via POST /diabetes/alerts). These profile-level columns are the defaults
--   the user configures at profile creation, NOT a replacement for that table.
--   They are stored rather than dropped because dropping them silently loses a
--   clinical value the user explicitly set. If a single source of truth is ever
--   wanted, glucose_alerts is the one to keep and these become its seed.
--
--   Names: the new columns deliberately match the API field names verbatim so
--   there is nothing to map (same choice as 2310's notification_method /
--   repeat_interval_minutes). That leaves this table mixing two naming styles
--   (target_glucose_low vs fasting_target_min_mg_dl); the alternative — a
--   third naming style plus another mapping layer — is what caused this bug.
--
--   Types: INTEGER mg/dL, matching target_glucose_low/high and
--   glucose_alerts.threshold_value. The request models type them as float, so
--   api/v1/diabetes.py rounds before writing (PostgREST will not coerce 70.0
--   into an integer column). All nullable with NO DEFAULT — a NULL here means
--   "never configured", and inventing a clinical number for an existing row is
--   exactly the kind of fabricated default that must not ship.
--
-- BUG 2 — saving a favorite superset pair has never worked.
--   api/v1/supersets_endpoints.py POST /supersets/favorites writes
--   exercise_1_id, exercise_2_id, muscle_1, muscle_2 and category, none of
--   which exist: migration 108 created favorite_superset_pairs with just the
--   two exercise NAMES. Every insert 42703'd, so the feature saved nothing.
--   All five are read back in this same module — GET /supersets/favorites/{id}
--   selects * and hands them to FavoriteSupersetPairResponse, which declares
--   every one of them — so they are a real feature missing its persistence,
--   not dead writes.
--
--   exercise_*_id is TEXT with no foreign key on purpose: the ids arriving here
--   come from more than one exercise id-space (exercise_library, custom user
--   exercises, imported catalogs), so an FK would reintroduce the same
--   "whole insert is rejected" failure this migration exists to remove.
--
--   category gets DEFAULT 'custom' — the only DEFAULT in this migration. It is
--   not a fabricated value: 'custom' is the response model's declared value for
--   an uncategorized pair, and a row saved before categories existed is exactly
--   that. New rows always carry an explicit category from the request model.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- diabetes_profiles
-- ---------------------------------------------------------------------------
ALTER TABLE diabetes_profiles ADD COLUMN IF NOT EXISTS fasting_target_min_mg_dl INTEGER;
ALTER TABLE diabetes_profiles ADD COLUMN IF NOT EXISTS fasting_target_max_mg_dl INTEGER;
ALTER TABLE diabetes_profiles ADD COLUMN IF NOT EXISTS notifications_enabled BOOLEAN;
ALTER TABLE diabetes_profiles ADD COLUMN IF NOT EXISTS low_glucose_alert_threshold INTEGER;
ALTER TABLE diabetes_profiles ADD COLUMN IF NOT EXISTS high_glucose_alert_threshold INTEGER;

COMMENT ON COLUMN diabetes_profiles.fasting_target_min_mg_dl IS
    'Lower bound of the user''s fasting glucose target range (mg/dL). NULL = not configured. Supersedes the single-value target_glucose_fasting column.';
COMMENT ON COLUMN diabetes_profiles.fasting_target_max_mg_dl IS
    'Upper bound of the user''s fasting glucose target range (mg/dL). NULL = not configured.';
COMMENT ON COLUMN diabetes_profiles.notifications_enabled IS
    'Whether the user wants glucose alert notifications. NULL = not configured. Per-alert-type enablement lives in glucose_alerts.enabled.';
COMMENT ON COLUMN diabetes_profiles.low_glucose_alert_threshold IS
    'Profile-level default low-glucose alert threshold (mg/dL). NULL = not configured. Per-alert rows in glucose_alerts hold the operative thresholds.';
COMMENT ON COLUMN diabetes_profiles.high_glucose_alert_threshold IS
    'Profile-level default high-glucose alert threshold (mg/dL). NULL = not configured.';

-- ---------------------------------------------------------------------------
-- favorite_superset_pairs
-- ---------------------------------------------------------------------------
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS exercise_1_id TEXT;
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS exercise_2_id TEXT;
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS muscle_1 TEXT;
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS muscle_2 TEXT;
ALTER TABLE favorite_superset_pairs ADD COLUMN IF NOT EXISTS category TEXT DEFAULT 'custom';

COMMENT ON COLUMN favorite_superset_pairs.exercise_1_id IS
    'Resolved id of the first exercise, when the client knows one. TEXT and unconstrained: ids span several exercise id-spaces.';
COMMENT ON COLUMN favorite_superset_pairs.exercise_2_id IS
    'Resolved id of the second exercise, when the client knows one.';
COMMENT ON COLUMN favorite_superset_pairs.muscle_1 IS
    'Primary muscle worked by exercise 1, used to render and re-suggest the pair.';
COMMENT ON COLUMN favorite_superset_pairs.muscle_2 IS
    'Primary muscle worked by exercise 2.';
COMMENT ON COLUMN favorite_superset_pairs.category IS
    'Pairing rationale: antagonist | compound_set | upper_lower | custom.';

COMMIT;

-- ============================================================================
-- After applying: refresh the column-drift snapshot so the gate sees the new
-- columns —
--   python backend/scripts/audit_supabase_column_drift.py --refresh
-- ============================================================================
