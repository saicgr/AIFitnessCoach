-- ============================================================================
-- 2372 — Program assignment progress + lifecycle. E2E register row 54.
-- ============================================================================
--
-- SYMPTOM: a started program "permanently suppresses generation on its
-- weekdays, with no date expiry — and progress never increments".
--
-- ROOT CAUSE (two halves, one cause):
--   1. NOTHING in the backend ever writes user_program_assignments
--      .workouts_completed / .progress_percentage / .current_week /
--      .completed_at. `grep -rn workouts_completed api/ services/ core/` finds
--      exactly one hit for this table — a READ in program_templates.py:2741.
--      Live proof (2026-07-29): every assignment row is
--      progress_percentage=0, workouts_completed=0, current_week=1,
--      completed_at=NULL — including one with 32 expanded workouts.
--   2. /today suppresses AI generation on every weekday any assignment with
--      is_active=true AND status='active' prescribes
--      (api/v1/workouts/today.py:_assignment_covered_weekdays). Because (1)
--      means an assignment never reaches a terminal state, that suppression
--      has no end date: once a program is started, its weekdays are dead to
--      AI generation forever, even after its last scheduled week has passed.
--
-- FIX (this migration = half one, the writer, at the DB chokepoint so EVERY
-- path that completes/creates/deletes a program workout keeps the counters
-- honest — the completion endpoint, the coach agent, a manual repair, all of
-- them):
--   * program_assignment_progress_sync(uuid[]) recomputes the counters for the
--     given assignments (NULL = all) DIRECTLY from the workouts rows, so the
--     numbers are derived, never incremented, and can never drift.
--   * A statement-level trigger on workouts (transition tables, one aggregate
--     per statement — not per row) calls it for the affected assignments.
--   * An assignment whose workouts are ALL completed settles to
--     status='completed', is_active=false, completed_at=now() — which is what
--     ends the /today weekday suppression.
--   * program_assignment_settle_elapsed(uuid) closes the time half: an
--     active/paused assignment with no workout scheduled on or after today has
--     no plan left to run, so it settles ('completed' when every session was
--     done, otherwise 'abandoned' with an explanatory note). Called at the
--     program read chokepoints from
--     services/program_assignment_progress.py and by
--     scripts/settle_program_assignments.py.
--
-- SAFETY: two functions + one statement-level trigger. No column DDL, no table
-- rewrite. CREATE TRIGGER takes a brief lock on public.workouts (1,256 rows).
-- Both function bodies are exception-guarded so a progress-sync failure can
-- never block a user from finishing a workout (it RAISEs a WARNING instead).
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Derive-and-persist progress for a set of assignments.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.program_assignment_progress_sync(
    p_assignment_ids uuid[] DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rows integer := 0;
BEGIN
    WITH agg AS (
        SELECT a.id AS assignment_id,
               COUNT(w.id)                                   AS tot,
               COUNT(w.id) FILTER (WHERE w.is_completed)     AS done,
               MAX(w.template_week) FILTER (
                   WHERE w.scheduled_date <= now()
               )                                             AS week_started,
               MAX(w.scheduled_date)                         AS last_scheduled
        FROM public.user_program_assignments a
        LEFT JOIN public.workouts w ON w.assignment_id = a.id
        WHERE p_assignment_ids IS NULL OR a.id = ANY(p_assignment_ids)
        GROUP BY a.id
    ),
    upd AS (
        UPDATE public.user_program_assignments a
        SET workouts_completed  = agg.done,
            total_workouts      = agg.tot,
            progress_percentage = CASE
                WHEN agg.tot > 0
                THEN LEAST(100, GREATEST(0,
                     ROUND(100.0 * agg.done / agg.tot)::int))
                ELSE 0 END,
            current_week        = GREATEST(1, COALESCE(agg.week_started, 1)),
            -- All sessions done → the program is finished. Settling it is what
            -- releases the /today weekday suppression.
            status = CASE
                WHEN agg.tot > 0 AND agg.done >= agg.tot
                     AND a.status IN ('active', 'paused', 'scheduled')
                THEN 'completed' ELSE a.status END,
            is_active = CASE
                WHEN agg.tot > 0 AND agg.done >= agg.tot
                     AND a.status IN ('active', 'paused', 'scheduled')
                THEN false ELSE a.is_active END,
            completed_at = CASE
                WHEN agg.tot > 0 AND agg.done >= agg.tot
                THEN COALESCE(a.completed_at, now())
                ELSE a.completed_at END,
            updated_at = now()
        FROM agg
        WHERE a.id = agg.assignment_id
          AND (
            a.workouts_completed  IS DISTINCT FROM agg.done
         OR a.total_workouts      IS DISTINCT FROM agg.tot
         OR a.progress_percentage IS DISTINCT FROM (CASE
                WHEN agg.tot > 0
                THEN LEAST(100, GREATEST(0,
                     ROUND(100.0 * agg.done / agg.tot)::int))
                ELSE 0 END)
         OR a.current_week        IS DISTINCT FROM
                GREATEST(1, COALESCE(agg.week_started, 1))
         OR (agg.tot > 0 AND agg.done >= agg.tot
             AND a.status IN ('active', 'paused', 'scheduled'))
          )
        RETURNING 1
    )
    SELECT count(*) INTO v_rows FROM upd;
    RETURN v_rows;
END;
$$;

COMMENT ON FUNCTION public.program_assignment_progress_sync(uuid[]) IS
  'Row 54: derives user_program_assignments progress counters from the '
  'assignment''s workouts rows and settles a fully-completed assignment. '
  'Called by trg_workouts_sync_assignment_progress and by '
  'services/program_assignment_progress.py.';

-- ---------------------------------------------------------------------------
-- 2. Statement-level trigger — one aggregate per statement, not per row.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_sync_assignment_progress_ins()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ids uuid[];
BEGIN
    SELECT array_agg(DISTINCT assignment_id) INTO v_ids
    FROM new_rows WHERE assignment_id IS NOT NULL;
    IF v_ids IS NOT NULL THEN
        PERFORM public.program_assignment_progress_sync(v_ids);
    END IF;
    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    -- Never block a workout write on a progress-sync failure; the read-time
    -- recompute in services/program_assignment_progress.py is the second net.
    RAISE WARNING 'program assignment progress sync (insert) failed: %',
        SQLERRM;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_sync_assignment_progress_del()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ids uuid[];
BEGIN
    SELECT array_agg(DISTINCT assignment_id) INTO v_ids
    FROM old_rows WHERE assignment_id IS NOT NULL;
    IF v_ids IS NOT NULL THEN
        PERFORM public.program_assignment_progress_sync(v_ids);
    END IF;
    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'program assignment progress sync (delete) failed: %',
        SQLERRM;
    RETURN NULL;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_sync_assignment_progress_upd()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ids uuid[];
BEGIN
    SELECT array_agg(DISTINCT id) INTO v_ids FROM (
        SELECT assignment_id AS id FROM new_rows WHERE assignment_id IS NOT NULL
        UNION
        SELECT assignment_id FROM old_rows WHERE assignment_id IS NOT NULL
    ) s;
    IF v_ids IS NOT NULL THEN
        PERFORM public.program_assignment_progress_sync(v_ids);
    END IF;
    RETURN NULL;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'program assignment progress sync (update) failed: %',
        SQLERRM;
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS trg_workouts_sync_assignment_progress_ins
    ON public.workouts;
CREATE TRIGGER trg_workouts_sync_assignment_progress_ins
    AFTER INSERT ON public.workouts
    REFERENCING NEW TABLE AS new_rows
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trg_sync_assignment_progress_ins();

DROP TRIGGER IF EXISTS trg_workouts_sync_assignment_progress_del
    ON public.workouts;
CREATE TRIGGER trg_workouts_sync_assignment_progress_del
    AFTER DELETE ON public.workouts
    REFERENCING OLD TABLE AS old_rows
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trg_sync_assignment_progress_del();

DROP TRIGGER IF EXISTS trg_workouts_sync_assignment_progress_upd
    ON public.workouts;
CREATE TRIGGER trg_workouts_sync_assignment_progress_upd
    AFTER UPDATE ON public.workouts
    REFERENCING NEW TABLE AS new_rows OLD TABLE AS old_rows
    FOR EACH STATEMENT
    EXECUTE FUNCTION public.trg_sync_assignment_progress_upd();

-- ---------------------------------------------------------------------------
-- 3. Time half — an assignment with nothing left on the calendar is over.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.program_assignment_settle_elapsed(
    p_user_id uuid DEFAULT NULL
)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_rows integer := 0;
BEGIN
    WITH candidate AS (
        SELECT a.id,
               a.started_at,
               COUNT(w.id)                               AS tot,
               COUNT(w.id) FILTER (WHERE w.is_completed) AS done,
               MAX(w.scheduled_date)                     AS last_scheduled
        FROM public.user_program_assignments a
        LEFT JOIN public.workouts w ON w.assignment_id = a.id
        WHERE a.status IN ('active', 'paused')
          AND (p_user_id IS NULL OR a.user_id = p_user_id)
        GROUP BY a.id, a.started_at
    ),
    elapsed AS (
        SELECT * FROM candidate
        WHERE (
            -- The whole scheduled window is in the past.
            (tot > 0 AND last_scheduled < date_trunc('day', now()))
            -- Or the assignment never produced a plan at all (and is not
            -- mid-expansion: the deferred assign path fills weeks 2..N in a
            -- background task on the same day it is created).
         OR (tot = 0 AND started_at < date_trunc('day', now()))
        )
    ),
    upd AS (
        UPDATE public.user_program_assignments a
        SET status = CASE
                WHEN e.tot > 0 AND e.done >= e.tot THEN 'completed'
                ELSE 'abandoned' END,
            is_active = false,
            completed_at = CASE
                WHEN e.tot > 0 AND e.done >= e.tot
                THEN COALESCE(a.completed_at, now())
                ELSE a.completed_at END,
            notes = CASE
                WHEN e.tot > 0 AND e.done >= e.tot THEN a.notes
                ELSE trim(both E'\n' from
                     COALESCE(a.notes, '') || E'\n' ||
                     'auto-settled ' || to_char(now(), 'YYYY-MM-DD') ||
                     ': the program''s scheduled window has elapsed (' ||
                     e.done || '/' || e.tot || ' sessions completed)')
                END,
            updated_at = now()
        FROM elapsed e
        WHERE a.id = e.id
        RETURNING 1
    )
    SELECT count(*) INTO v_rows FROM upd;
    RETURN v_rows;
END;
$$;

COMMENT ON FUNCTION public.program_assignment_settle_elapsed(uuid) IS
  'Row 54: settles an active/paused assignment whose scheduled window has '
  'fully elapsed (or that never produced workouts) so /today weekday '
  'suppression can never be unbounded.';

-- ---------------------------------------------------------------------------
-- 4. Repair the existing rows (progress has never been written for any of them).
-- ---------------------------------------------------------------------------
SELECT public.program_assignment_progress_sync(NULL);
SELECT public.program_assignment_settle_elapsed(NULL);

COMMIT;
