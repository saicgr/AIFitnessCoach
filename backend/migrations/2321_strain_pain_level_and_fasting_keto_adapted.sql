-- ============================================================================
-- Migration 2321: Add the two genuinely-missing columns behind the
--                 phantom-column write tail (strain_history, fasting_preferences)
-- ============================================================================
-- Context: PostgREST rejects an ENTIRE write payload when ONE key is not a real
-- column (PGRST204 / 42703). The 2026-07 column-drift audit found 20 such keys
-- across 8 backend files. Most were rename drift or dead writes and were fixed
-- in code (no schema change). Exactly TWO were a real feature missing its
-- column — those are added here.
--
-- Fixed in CODE, not here (listed so the next reader doesn't go looking):
--   live_chat_queue.category / .escalated_from_ai      -> already on support_tickets
--   strain_history.muscle_group / .occurred_during     -> body_part is the store
--   saved_workouts.title / .exercises_json / .data     -> workout_name / exercises / real cols
--   user_program_assignments.variant_id / .desired_weeks
--                            / .sessions_per_week      -> no reader; total_workouts holds the choice
--   user_program_assignments.program_name / .week_number -> custom_program_name / current_week
--   workouts.workout_name                              -> name
--   food_logs.weight_g                                 -> per-item weight inside food_items JSONB
--
-- ----------------------------------------------------------------------------
-- 1. strain_history.pain_level
-- ----------------------------------------------------------------------------
-- The Report Strain screen (mobile/flutter/lib/screens/strain_prevention/
-- report_strain_screen.dart) collects a 0-10 soreness slider per muscle and
-- POSTs it as `pain_level` on every /strain-prevention/record-strain call.
-- RecordStrainRequest has declared the field since the endpoint shipped, but
-- strain_history (migration 110) never had the column, so EVERY strain report
-- 42703'd — the insert raised, the endpoint 500'd, and nothing was recorded.
-- `severity` is not a substitute: the client derives it as a 3-bucket average
-- of fatigue + soreness, so the raw pain reading is lost the moment it is
-- discarded. Nullable — reports made through other paths
-- (strain_prevention_service.record_strain) legitimately have no pain reading,
-- and there is no honest default for "user did not say".
-- ----------------------------------------------------------------------------
ALTER TABLE public.strain_history
    ADD COLUMN IF NOT EXISTS pain_level SMALLINT;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'strain_history_pain_level_range'
    ) THEN
        ALTER TABLE public.strain_history
            ADD CONSTRAINT strain_history_pain_level_range
            CHECK (pain_level IS NULL OR (pain_level >= 0 AND pain_level <= 10));
    END IF;
END $$;

COMMENT ON COLUMN public.strain_history.pain_level IS
    'User-reported pain/soreness at the time of the strain, 0-10. NULL when the '
    'report came from a path that does not ask (auto-detected volume strain).';

-- ----------------------------------------------------------------------------
-- 2. fasting_preferences.is_keto_adapted
-- ----------------------------------------------------------------------------
-- A READER already exists: api/v1/fasting.py row_to_preferences() maps
-- row["is_keto_adapted"] into FastingPreferencesResponse.is_keto_adapted, which
-- is a REQUIRED bool on the response model (api/v1/fasting_models.py:128), and
-- the Flutter zone engine shifts every fasting zone boundary by 2 hours for
-- keto-adapted users (FastingZone.forElapsedHours(..., isKetoAdapted:), in
-- mobile/flutter/lib/data/models/fasting.dart). The write side has always sent
-- the key, so the ENTIRE fasting-preferences upsert (protocol, schedule, every
-- notification toggle) 42703'd — no user could save fasting preferences at all.
--
-- NOT NULL DEFAULT FALSE is the genuinely correct default, not a fabricated
-- one: both the request model (UpdateFastingPreferencesRequest.is_keto_adapted)
-- and the read fallback (row.get("is_keto_adapted", False)) already treat
-- "unset" as false, and false is the physiologically correct assumption for a
-- user who has never told us otherwise (no zone shift applied).
-- ----------------------------------------------------------------------------
ALTER TABLE public.fasting_preferences
    ADD COLUMN IF NOT EXISTS is_keto_adapted BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN public.fasting_preferences.is_keto_adapted IS
    'User reports being fat/keto adapted. Shifts the fasting zone timeline '
    'earlier by ~2h in the client. Defaults false = no shift.';

-- ============================================================================
-- Post-apply: refresh the drift snapshot so the auditor stops flagging these
--   python backend/scripts/audit_supabase_column_drift.py --refresh
-- ============================================================================
