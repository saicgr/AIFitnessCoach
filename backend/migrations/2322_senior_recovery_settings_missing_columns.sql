-- ============================================================================
-- Migration 2322: senior_recovery_settings — add the 6 columns the senior
--                 fitness API has been writing to a table that never had them
-- ============================================================================
-- Found by scripts/audit_supabase_column_drift.py (22 violations, the largest
-- single cluster in the tree — 11 phantom keys x 2 write sites).
--
-- WHAT WAS BROKEN
--   api/v1/senior_fitness.py builds its senior-settings payload from ITS OWN
--   field names, which drifted from the table migration 113 actually created.
--   PostgREST rejects an ENTIRE write payload when one key is not a real
--   column (PGRST204 / 42703), so EVERY
--       PUT /api/v1/senior-fitness/{user_id}/settings
--   touching any of those fields failed in full — including the keys that WERE
--   real (recovery_multiplier, max_intensity_percent, prefer_low_impact) —
--   swallowed by the endpoint's try/except. A senior user's saved recovery
--   preferences have never been persisted by that endpoint.
--
-- TRIAGE (full detail + the canonical map live in api/v1/senior_fitness.py)
--   8 of the 11 phantom keys were pure NAME drift and are fixed in code, with
--   no schema change, by writing the real column:
--       avoid_high_impact           -> avoid_high_impact_cardio
--       warmup_extension_minutes    -> extended_warmup_minutes
--       cooldown_extension_minutes  -> extended_cooldown_minutes
--       include_balance_work        -> include_balance_exercises
--       min_rest_days_between_workouts -> min_rest_days_strength
--         (the schema models rest per modality; the strength floor is the
--          binding constraint the recovery-status endpoint and the SQL
--          check_senior_recovery_status() both use. min_rest_days_cardio is
--          left alone.)
--     ...plus recovery_multiplier / max_intensity_percent / prefer_low_impact,
--     which were already correct and were only collateral damage.
--
--   The remaining 6 are genuinely missing columns for features that HAVE live
--   readers, so they are added here:
--
--   rest_between_sets_multiplier  read by POST /senior-fitness/apply-workout-modifications
--                                 (scales each exercise's rest_seconds) and by
--                                 GET /{id}/recovery-status; parsed by the
--                                 Flutter model SeniorRecoverySettings
--                                 (`rest_between_sets_multiplier`).
--   prefer_seated_exercises       read by GET /{id}/prompt-context (feeds the AI
--                                 coach "include seated options") and set by the
--                                 75+ age defaults; parsed by the same Flutter
--                                 model.
--   include_warmup_extension      gate for extended_warmup_minutes — read by
--   include_cooldown_extension    apply-workout-modifications, which adds the
--                                 minutes only when the toggle is on. Stored
--                                 separately from the minutes so switching the
--                                 extension off does not destroy the user's
--                                 configured duration.
--   joint_protection_mode         read by GET /{id}/prompt-context.
--   protected_joints              read by GET /{id}/prompt-context (named joints
--                                 are injected into the coach prompt).
--
-- DEFAULTS
--   Every default below is the behaviour-preserving / identity value — the same
--   one the API already falls back to when the key is absent — so backfilling
--   existing rows changes nothing that is live today. No fabricated numbers.
--     rest_between_sets_multiplier 1.0  = identity multiplier (no rest change)
--     include_*_extension          TRUE = migration 113's "safety on" posture
--                                        for seniors, and the API's own default
--     prefer_seated_exercises      FALSE / joint_protection_mode FALSE /
--     protected_joints '{}'        = "not configured"
-- ============================================================================

ALTER TABLE public.senior_recovery_settings
    -- 1.0 = leave rest between sets untouched. Bounds mirror the validated API
    -- contract (SeniorSettingsUpdate: ge=1.0, le=2.0) so a nonsense value can
    -- never reach the workout-modification math.
    ADD COLUMN IF NOT EXISTS rest_between_sets_multiplier NUMERIC(3,2)
        NOT NULL DEFAULT 1.0,
    ADD COLUMN IF NOT EXISTS prefer_seated_exercises BOOLEAN
        NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS include_warmup_extension BOOLEAN
        NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS include_cooldown_extension BOOLEAN
        NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS joint_protection_mode BOOLEAN
        NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS protected_joints TEXT[]
        NOT NULL DEFAULT '{}';

-- Range guard for the one numeric column. Added separately (and idempotently)
-- so re-running the migration cannot fail on a duplicate constraint name.
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'senior_recovery_settings_rest_multiplier_range'
          AND conrelid = 'public.senior_recovery_settings'::regclass
    ) THEN
        ALTER TABLE public.senior_recovery_settings
            ADD CONSTRAINT senior_recovery_settings_rest_multiplier_range
            CHECK (rest_between_sets_multiplier >= 1.0
               AND rest_between_sets_multiplier <= 2.0);
    END IF;
END
$$;


COMMENT ON COLUMN public.senior_recovery_settings.rest_between_sets_multiplier IS
    'Multiplier applied to each exercise''s rest_seconds for this senior user. '
    '1.0 = unchanged. Read by /senior-fitness/apply-workout-modifications.';

COMMENT ON COLUMN public.senior_recovery_settings.prefer_seated_exercises IS
    'User prefers seated variations where one exists. Feeds the AI coach prompt '
    'context (/senior-fitness/{user_id}/prompt-context).';

COMMENT ON COLUMN public.senior_recovery_settings.include_warmup_extension IS
    'Whether extended_warmup_minutes is actually applied. Separate from the '
    'minutes so turning the extension off preserves the configured duration.';

COMMENT ON COLUMN public.senior_recovery_settings.include_cooldown_extension IS
    'Whether extended_cooldown_minutes is actually applied. Separate from the '
    'minutes so turning the extension off preserves the configured duration.';

COMMENT ON COLUMN public.senior_recovery_settings.joint_protection_mode IS
    'Master switch for joint-protective programming; gates protected_joints in '
    'the AI coach prompt context.';

COMMENT ON COLUMN public.senior_recovery_settings.protected_joints IS
    'Named joints to protect (e.g. {knees,shoulders}). Injected into the AI '
    'coach prompt context when joint_protection_mode is true.';


-- ============================================================================
-- Post-apply
-- ============================================================================
-- Refresh the drift snapshot so the audit gate stops flagging these six:
--   python backend/scripts/audit_supabase_column_drift.py --refresh
-- ============================================================================
