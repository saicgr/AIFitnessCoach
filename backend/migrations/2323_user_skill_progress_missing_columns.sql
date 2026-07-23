-- ============================================================================
-- Migration 2323: Add the 6 columns api/v1/skill_progressions.py has always
--                 written to user_skill_progress but that never existed
-- ============================================================================
-- Root cause: migration 081_skill_progressions.sql created
-- `user_skill_progress` with exactly 9 columns:
--
--   id, user_id, chain_id, current_step_order, unlocked_steps,
--   attempts_at_current, best_reps_at_current, started_at, last_practiced_at
--
-- The API and the pydantic model (`models/skill_progression.py`
-- UserSkillProgressBase / UserSkillProgress) were written against a richer
-- shape that 081 never shipped. Every write in
-- `backend/api/v1/skill_progressions.py` therefore carries at least one key
-- that is not a real column, and PostgREST rejects the ENTIRE payload when a
-- single key is unknown (PGRST204 / 42703). Concretely, TODAY:
--
--   POST /start-chain/{chain_id}   INSERT  is_completed, is_active,
--                                          created_at, updated_at   -> 500
--   POST /log-attempt              UPDATE  best_hold_at_current,
--                                          updated_at               -> 500
--   POST /unlock-next (final step) UPDATE  is_completed, completed_at,
--                                          updated_at               -> 500
--   POST /unlock-next (normal)     UPDATE  best_hold_at_current,
--                                          updated_at               -> 500
--   PUT  /toggle-active            UPDATE  is_active, updated_at     -> 500
--
-- i.e. the entire skill-progression feature is 100% dead at the write layer —
-- no user can start a chain, log an attempt, unlock a step, or pause a
-- progression. Reads are affected too: GET /user/{id}/progress?active_only=true
-- filters `.eq("is_active", True)` and `/summary` reads `is_completed` /
-- `is_active` off the row.
--
-- Triage per column (none of these is a rename of an existing column — the
-- write payloads already carry every real column alongside them):
--
--   is_active            NOT a rename. Owns the /toggle-active endpoint, the
--                        `active_only` list filter, and the active-vs-completed
--                        split in /summary. Reader exists -> ADD.
--   is_completed         NOT `completed_at` (bool state vs. timestamp; /summary
--                        buckets on the bool, and UserSkillProgress declares
--                        `is_completed: bool` non-optional). Reader exists -> ADD.
--   completed_at         Read by _parse_progress AND parsed by the Flutter model
--                        (`@JsonKey(name: 'completed_at')` in
--                        mobile/flutter/lib/data/models/skill_progression.dart,
--                        which derives `isCompleted => completedAt != null`).
--                        Reader exists -> ADD.
--   best_hold_at_current NOT `best_reps_at_current` (hold seconds vs. reps —
--                        different units, and hold-based chains like Dead Hang /
--                        Front Lever gate unlocking on min_hold_seconds). Read by
--                        _parse_progress and by /log-attempt's new-best check.
--                        Reader exists -> ADD.
--   updated_at           NOT `last_practiced_at`. Mapping it there would be the
--                        classic two-concepts-one-column mistake: /toggle-active
--                        writes updated_at while merely PAUSING a progression,
--                        which would falsely advance "last practiced" and
--                        corrupt the `daysSinceLastPractice` UI. Row-mutation
--                        audit stamp. Reader exists (response model) -> ADD.
--   created_at           NOT `started_at`. Both are written in the SAME insert
--                        payload, so one cannot be a rename of the other.
--                        Row-creation audit stamp. Reader exists (response
--                        model) -> ADD.
--
-- No column is dropped and no write is removed: every phantom key here has a
-- live reader, so this is case 2 of the triage (genuinely missing column),
-- not case 3 (dead write).
--
-- Nullability: the two audit stamps and completed_at / best_hold_at_current are
-- NULLABLE. Existing rows are backfilled only from data that actually exists
-- (started_at / last_practiced_at / skill_attempt_logs) — a row with no
-- evidence keeps NULL rather than being stamped with a fabricated NOW().
-- is_active / is_completed are NOT NULL with defaults that are factually
-- correct for the existing population: no row can ever have been paused or
-- completed, because both write paths have been 500-ing since 081 shipped.
--
-- Deliberately NOT added: a
-- `CHECK (is_completed = (completed_at IS NOT NULL))` invariant. It would hold
-- for today's code (the completion branch sets both keys together), but it
-- introduces a brand-new whole-payload rejection mode (23514) for any future
-- partial write — the exact failure class this migration exists to remove.
-- ============================================================================

BEGIN;

-- ----------------------------------------------------------------------------
-- 1. Columns
-- ----------------------------------------------------------------------------

ALTER TABLE public.user_skill_progress
    ADD COLUMN IF NOT EXISTS is_active            BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS is_completed         BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS completed_at         TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS best_hold_at_current INTEGER,
    -- No inline DEFAULT NOW(): a volatile default on ADD COLUMN stamps every
    -- PRE-EXISTING row with the migration-run timestamp — a fabricated creation
    -- date for progressions that started long before this migration. Existing
    -- rows stay NULL (honestly unknown); the DEFAULT below applies to FUTURE
    -- inserts only. This is what the header comment promises.
    ADD COLUMN IF NOT EXISTS created_at           TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS updated_at           TIMESTAMP WITH TIME ZONE;

ALTER TABLE public.user_skill_progress
    ALTER COLUMN created_at SET DEFAULT NOW(),
    ALTER COLUMN updated_at SET DEFAULT NOW();

COMMENT ON COLUMN public.user_skill_progress.is_active IS
    'User is actively working this chain. FALSE = paused via PUT /toggle-active; paused chains are excluded from GET /progress?active_only=true and from /summary active_progressions.';
COMMENT ON COLUMN public.user_skill_progress.is_completed IS
    'Every step in the chain has been unlocked. Set together with completed_at by POST /unlock-next when no next step exists.';
COMMENT ON COLUMN public.user_skill_progress.completed_at IS
    'When the final step was unlocked. NULL until the chain is finished. The Flutter model derives isCompleted from this being non-NULL.';
COMMENT ON COLUMN public.user_skill_progress.best_hold_at_current IS
    'Best hold, in SECONDS, achieved at current_step_order (static holds: dead hang, front lever, planche). Reset to NULL on step unlock. Distinct from best_reps_at_current, which counts reps.';
COMMENT ON COLUMN public.user_skill_progress.created_at IS
    'Row creation stamp. Distinct from started_at, which is the domain event "user started this chain".';
COMMENT ON COLUMN public.user_skill_progress.updated_at IS
    'Last row mutation stamp, maintained by trigger_user_skill_progress_updated_at. Distinct from last_practiced_at: pausing a progression bumps updated_at but must NOT bump last_practiced_at.';

-- ----------------------------------------------------------------------------
-- 2. Backfill existing rows from real data only (no fabricated values)
-- ----------------------------------------------------------------------------

-- created_at: the row was created when the user started the chain.
UPDATE public.user_skill_progress
SET created_at = started_at
WHERE created_at IS NULL
  AND started_at IS NOT NULL;

-- updated_at: last known mutation = the most recent practice, else the start.
UPDATE public.user_skill_progress
SET updated_at = COALESCE(last_practiced_at, started_at)
WHERE updated_at IS NULL
  AND COALESCE(last_practiced_at, started_at) IS NOT NULL;

-- best_hold_at_current: skill_attempt_logs.hold_seconds is the only place hold
-- time has ever been persisted (that table's writes were never broken), so the
-- best hold at the user's CURRENT step is recoverable exactly.
UPDATE public.user_skill_progress p
SET best_hold_at_current = a.max_hold
FROM (
    SELECT user_id, chain_id, step_order, MAX(hold_seconds) AS max_hold
    FROM public.skill_attempt_logs
    WHERE hold_seconds IS NOT NULL
    GROUP BY user_id, chain_id, step_order
) a
WHERE a.user_id = p.user_id
  AND a.chain_id = p.chain_id
  AND a.step_order = p.current_step_order
  AND p.best_hold_at_current IS NULL;

-- is_active / is_completed intentionally keep their column defaults for
-- existing rows: /toggle-active and the completion branch of /unlock-next have
-- never once succeeded, so no existing row can be paused or completed.

-- ----------------------------------------------------------------------------
-- 3. Keep updated_at honest without relying on every caller remembering it
-- ----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.update_user_skill_progress_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_user_skill_progress_updated_at ON public.user_skill_progress;
CREATE TRIGGER trigger_user_skill_progress_updated_at
    BEFORE UPDATE ON public.user_skill_progress
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_skill_progress_updated_at();

-- ----------------------------------------------------------------------------
-- 4. Index for the active_only list query
--    GET /user/{user_id}/progress?active_only=true
--      -> .eq(user_id).eq(is_active, true).order(last_practiced_at desc)
-- ----------------------------------------------------------------------------

CREATE INDEX IF NOT EXISTS idx_user_skill_progress_user_active
    ON public.user_skill_progress (user_id, last_practiced_at DESC)
    WHERE is_active;

COMMIT;

-- ============================================================================
-- Verification (run after applying)
-- ============================================================================
-- SELECT column_name, data_type, is_nullable, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'user_skill_progress'
-- ORDER BY ordinal_position;
--   -> must now list is_active, is_completed, completed_at,
--      best_hold_at_current, created_at, updated_at
--
-- Then refresh the drift snapshot so the gate goes green:
--   python backend/scripts/audit_supabase_column_drift.py --refresh
--   python backend/scripts/audit_supabase_column_drift.py --check
-- ============================================================================
