-- Migration: 2038 — Refresh hook for exercise_library_cleaned MV
-- Why: The MV created in 2037 is stale until refreshed. Base-table writes
--      (`exercise_library`, `exercise_library_manual`, `exercise_safety_tags`)
--      must mark the MV dirty so a refresh job (or admin) can reconcile.
-- How: A small `mv_refresh_queue` table + a trigger fn that inserts a marker
--      row + a `refresh_exercise_library_cleaned()` helper that reads the
--      queue, runs CONCURRENTLY refresh, and clears the marker.
--
-- Backend wires this up in two places:
--   1. Per-process startup probe — calls the helper if the queue is non-empty
--      OR the MV is empty (covers fresh deploys).
--   2. Import scripts (`scripts/seed_*.py`, custom-exercise admin endpoints)
--      `SELECT refresh_exercise_library_cleaned();` after their writes.

CREATE TABLE IF NOT EXISTS public.mv_refresh_queue (
    mv_name      text PRIMARY KEY,
    queued_at    timestamptz NOT NULL DEFAULT now(),
    last_refresh timestamptz
);

GRANT SELECT, INSERT, UPDATE ON public.mv_refresh_queue TO service_role;

CREATE OR REPLACE FUNCTION public.mark_exercise_library_cleaned_dirty()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.mv_refresh_queue (mv_name, queued_at)
    VALUES ('exercise_library_cleaned', now())
    ON CONFLICT (mv_name) DO UPDATE SET queued_at = EXCLUDED.queued_at;
    -- pg_notify allows long-running listeners to refresh in near real time
    PERFORM pg_notify('mv_refresh', 'exercise_library_cleaned');
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS exercise_library_mv_dirty ON public.exercise_library;
CREATE TRIGGER exercise_library_mv_dirty
AFTER INSERT OR UPDATE OR DELETE ON public.exercise_library
FOR EACH STATEMENT EXECUTE FUNCTION public.mark_exercise_library_cleaned_dirty();

DROP TRIGGER IF EXISTS exercise_library_manual_mv_dirty ON public.exercise_library_manual;
CREATE TRIGGER exercise_library_manual_mv_dirty
AFTER INSERT OR UPDATE OR DELETE ON public.exercise_library_manual
FOR EACH STATEMENT EXECUTE FUNCTION public.mark_exercise_library_cleaned_dirty();

-- exercise_safety_tags drives exercise_safety_index_mat — same dirty-marker pattern.
CREATE OR REPLACE FUNCTION public.mark_exercise_safety_index_mat_dirty()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO public.mv_refresh_queue (mv_name, queued_at)
    VALUES ('exercise_safety_index_mat', now())
    ON CONFLICT (mv_name) DO UPDATE SET queued_at = EXCLUDED.queued_at;
    PERFORM pg_notify('mv_refresh', 'exercise_safety_index_mat');
    RETURN NULL;
END;
$$;

DROP TRIGGER IF EXISTS exercise_safety_tags_mv_dirty ON public.exercise_safety_tags;
CREATE TRIGGER exercise_safety_tags_mv_dirty
AFTER INSERT OR UPDATE OR DELETE ON public.exercise_safety_tags
FOR EACH STATEMENT EXECUTE FUNCTION public.mark_exercise_safety_index_mat_dirty();

-- Helper: refresh exercise_library_cleaned (and the dependent safety MV) if dirty.
-- Returns the queued_at timestamp it consumed (NULL if no refresh was needed).
CREATE OR REPLACE FUNCTION public.refresh_exercise_library_cleaned(force boolean DEFAULT false)
RETURNS timestamptz
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_queued timestamptz;
BEGIN
    SELECT queued_at INTO v_queued
    FROM public.mv_refresh_queue
    WHERE mv_name = 'exercise_library_cleaned';

    IF NOT force AND v_queued IS NULL THEN
        RETURN NULL;
    END IF;

    REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_library_cleaned;
    -- Cascade: safety MV depends on cleaned MV
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_safety_index_mat;

    UPDATE public.mv_refresh_queue
    SET last_refresh = now(), queued_at = NULL
    WHERE mv_name IN ('exercise_library_cleaned', 'exercise_safety_index_mat');

    RETURN COALESCE(v_queued, now());
END;
$$;

GRANT EXECUTE ON FUNCTION public.refresh_exercise_library_cleaned(boolean) TO service_role;
