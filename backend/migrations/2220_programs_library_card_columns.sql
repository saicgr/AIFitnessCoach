-- 2220_programs_library_card_columns.sql
--
-- P0-2: Speed up GET /program-templates/library (browse_library).
--
-- The browse endpoint previously selected the full `workouts` JSONB blob for
-- all 259 program rows on every request, purely to compute two derived values
-- (whether a program has any workouts, and its sessions-per-week), then threw
-- the blob away. That made the payload multi-second and tripped the Dio
-- receiveTimeout on the client (error card).
--
-- Fix (infra root cause): precompute the two derived values into light card
-- columns so the browse endpoint can select only the small card fields, filter
-- has_workouts server-side, and use the sessions_per_week column directly.
--
--   has_workouts      BOOLEAN  -- mirrors _has_workouts(row): the `workouts`
--                                 JSONB object has a non-empty `workouts` array.
--   sessions_per_week INT      -- mirrors _sessions_per_week(row): count of
--                                 workouts whose `exercises` array is non-empty.
--                                 (The column already existed but was 100% NULL;
--                                  this backfills it.)
--
-- The backfill below uses the SAME definitions as the Python helpers in
-- backend/api/v1/program_templates.py so the response shape is identical.
--
-- Expected after run (verified live, May 2026):
--   total rows ~259, has_workouts=true ~252, has_workouts=false ~7.

-- 1) Add has_workouts (sessions_per_week already exists on the table).
ALTER TABLE public.programs
  ADD COLUMN IF NOT EXISTS has_workouts BOOLEAN;

-- 2) Backfill has_workouts.
--    Matches _has_workouts(): true iff workouts->'workouts' is a non-empty array.
UPDATE public.programs
SET has_workouts = (
  jsonb_typeof(workouts) = 'object'
  AND jsonb_typeof(workouts -> 'workouts') = 'array'
  AND jsonb_array_length(workouts -> 'workouts') > 0
);

-- 3) Backfill sessions_per_week for rows that have workouts.
--    Matches _sessions_per_week(): number of workouts whose `exercises` array
--    is non-empty. NULL when the program has no workouts at all.
UPDATE public.programs p
SET sessions_per_week = sub.spw
FROM (
  SELECT
    pr.id,
    COUNT(*) FILTER (
      WHERE jsonb_typeof(w.value -> 'exercises') = 'array'
        AND jsonb_array_length(w.value -> 'exercises') > 0
    ) AS spw
  FROM public.programs pr,
       LATERAL jsonb_array_elements(pr.workouts -> 'workouts') AS w(value)
  WHERE jsonb_typeof(pr.workouts) = 'object'
    AND jsonb_typeof(pr.workouts -> 'workouts') = 'array'
    AND jsonb_array_length(pr.workouts -> 'workouts') > 0
  GROUP BY pr.id
) sub
WHERE p.id = sub.id;

-- 4) Index the server-side filter so browse_library stays fast as the library
--    grows.
CREATE INDEX IF NOT EXISTS idx_programs_has_workouts
  ON public.programs (has_workouts);

-- 5) Normalize the 7 empty programs from NULL -> false. The backfill in step 2
--    leaves has_workouts NULL when `workouts` itself is NULL (jsonb_typeof(NULL)
--    short-circuits the AND to NULL). The browse filter .eq(has_workouts, True)
--    excludes them either way, but a NULL boolean is ambiguous — make it false.
UPDATE public.programs SET has_workouts = false WHERE has_workouts IS NULL;
