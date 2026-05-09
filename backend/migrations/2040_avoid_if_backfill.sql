-- Migration: 2040_avoid_if_backfill.sql
-- Backfills avoid_if[] = ARRAY['knee'] for the deep-knee-flexion / heavy-knee-
-- loading squat & lunge variants surfaced by validation harness
-- render_suggest_substitutes_20260508_205357 (knee-injury substitute requests
-- returned 12/88 rows containing one of these as a "safe" alternative).
--
-- Source rows live in BOTH exercise_library and exercise_library_manual; the
-- MV is rebuilt from UNION ALL of those two tables (mig 2037). Backfill both.
-- Then refresh the MV so the API sees the change immediately.
--
-- Idempotent: only updates rows where 'knee' isn't already in avoid_if.

-- 1. exercise_library
UPDATE public.exercise_library
SET avoid_if = COALESCE(avoid_if, ARRAY[]::text[]) || ARRAY['knee']
WHERE NOT ('knee' = ANY(COALESCE(avoid_if, ARRAY[]::text[])))
  AND (
       LOWER(exercise_name) LIKE '%hindu squat%'
    OR LOWER(exercise_name) LIKE '%baithak%'
    OR LOWER(exercise_name) = 'hack squat'
    OR LOWER(exercise_name) LIKE 'hack squat %'
    OR LOWER(exercise_name) = 'reverse hack squat'
    OR LOWER(exercise_name) LIKE 'reverse hack squat %'
    OR LOWER(exercise_name) LIKE '%walking lunge%'
  );

-- 2. exercise_library_manual
UPDATE public.exercise_library_manual
SET avoid_if = COALESCE(avoid_if, ARRAY[]::text[]) || ARRAY['knee']
WHERE NOT ('knee' = ANY(COALESCE(avoid_if, ARRAY[]::text[])))
  AND (
       LOWER(exercise_name) LIKE '%hindu squat%'
    OR LOWER(exercise_name) LIKE '%baithak%'
    OR LOWER(exercise_name) = 'hack squat'
    OR LOWER(exercise_name) LIKE 'hack squat %'
    OR LOWER(exercise_name) = 'reverse hack squat'
    OR LOWER(exercise_name) LIKE 'reverse hack squat %'
    OR LOWER(exercise_name) LIKE '%walking lunge%'
  );

-- 3. Refresh the materialized view so the new avoid_if values surface
--    immediately to the API. The refresh_exercise_library_cleaned() helper
--    has an unrelated bug (NULL on mv_refresh_queue.queued_at NOT NULL), so
--    we issue REFRESH directly here.
REFRESH MATERIALIZED VIEW CONCURRENTLY public.exercise_library_cleaned;
