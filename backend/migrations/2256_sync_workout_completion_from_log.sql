-- 2256_sync_workout_completion_from_log.sql
--
-- Durable invariant: a COMPLETED workout_log must ALWAYS imply
-- workouts.is_completed = TRUE. The one chokepoint that makes the two never
-- diverge again.
--
-- WHY: workout completion is two independent client writes —
--   (1) POST /performance/workout-logs   -> creates workout_logs (status='completed')
--                                            + performance_logs   [reliable]
--   (2) POST /workouts/{id}/complete      -> flips workouts.is_completed [fragile]
-- They are not transactional. When (2) failed (a transient error while online)
-- the offline queue only retried on a connectivity *change*, so a finished
-- workout could stay is_completed=FALSE forever while its log + every set were
-- safely saved — the UI then correctly showed it as still-upcoming. Observed on
-- 2 of 81 completed logs. This trigger derives the UI-truth flag straight from
-- the durable log write so write (2) can never strand a completion again.
--
-- SAFETY (verified against live data 2026-06):
--   * Fires only WHEN NEW.status = 'completed' AND NEW.workout_id IS NOT NULL.
--     - watch_sync per-set rows carry NO workout_id -> excluded.
--     - 'in_progress' logs never fire it.
--   * Idempotent: guarded by `is_completed IS DISTINCT FROM true`; only ever
--     ADDS a completion, never clears one. Does not fight /uncomplete (which
--     writes `workouts`, not `workout_logs`, and already refuses tracked
--     workouts that have logs).
--   * 'marked_done' completions create no workout_log and still flip the flag
--     via /complete directly — unchanged.
--
-- LATENT-COUPLING CAVEAT: workout_logs.status DEFAULTs to 'completed'. Today the
-- ONLY inserter of a workout_id-bearing log is the completion-finalize path, so
-- the default is correct. If a FUTURE "start session" flow inserts a
-- workout_logs row at workout START, it MUST set status='in_progress'
-- explicitly — otherwise the default would mark the workout complete on start.

CREATE OR REPLACE FUNCTION sync_workout_completion_from_log()
RETURNS trigger AS $$
BEGIN
    UPDATE workouts
    SET is_completed         = true,
        completed_at         = COALESCE(completed_at, NEW.completed_at, now()),
        completion_method    = COALESCE(completion_method, 'tracked'),
        last_modified_at     = now(),
        last_modified_method = COALESCE(last_modified_method, 'completed')
    WHERE id = NEW.workout_id
      AND is_completed IS DISTINCT FROM true;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION sync_workout_completion_from_log() IS
    'Migration 2256. A completed workout_log implies workouts.is_completed. '
    'Idempotent, additive-only (never clears a completion).';

DROP TRIGGER IF EXISTS trg_sync_workout_completion ON workout_logs;

CREATE TRIGGER trg_sync_workout_completion
    AFTER INSERT OR UPDATE OF status ON workout_logs
    FOR EACH ROW
    WHEN (NEW.status = 'completed' AND NEW.workout_id IS NOT NULL)
    EXECUTE FUNCTION sync_workout_completion_from_log();
