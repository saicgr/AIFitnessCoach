-- Backstop against the onboarding-race bug where two writers
-- (/workouts/generate and /workouts/generate-stream) both produced
-- a "today" workout with different gym_profile_id values, slipping past
-- the application-level dedup which conditionally narrowed by gym_profile_id.
-- Even with the dedup queries fixed in code, a partial unique index ensures
-- exactly one is_current=TRUE row per (user_id, day) regardless of races.
--
-- Losing INSERTs raise unique_violation (Postgres 23505); the writer
-- catches and refetches the winner.
--
-- The all-zeros user_id is the catalogue/template sentinel (publicly shared
-- workouts, exemplar program seeds). Multiple is_current rows on the same
-- day are intentional there, so it's excluded from the constraint.

-- Step 1 — collapse pre-existing duplicates for real users so the index can build.
-- Pick the winner: prefer completed > most recently generated > most recently created.
WITH ranked AS (
  SELECT id,
         user_id,
         (scheduled_date AT TIME ZONE 'UTC')::date AS day,
         ROW_NUMBER() OVER (
           PARTITION BY user_id, (scheduled_date AT TIME ZONE 'UTC')::date
           ORDER BY (status = 'completed') DESC,
                    generated_at DESC NULLS LAST,
                    created_at DESC
         ) AS rn
  FROM workouts
  WHERE is_current = TRUE
    AND status <> 'cancelled'
    AND user_id <> '00000000-0000-0000-0000-000000000000'
),
losers AS (
  SELECT r.id, r.user_id, r.day,
         (SELECT id FROM ranked w WHERE w.user_id = r.user_id AND w.day = r.day AND w.rn = 1) AS winner_id
  FROM ranked r
  WHERE r.rn > 1
)
UPDATE workouts w
SET is_current   = FALSE,
    valid_to     = COALESCE(w.valid_to, NOW()),
    superseded_by = losers.winner_id
FROM losers
WHERE w.id = losers.id;

-- Step 2 — partial unique index. Excludes the all-zeros template user.
CREATE UNIQUE INDEX IF NOT EXISTS workouts_one_current_per_user_day
ON workouts (user_id, ((scheduled_date AT TIME ZONE 'UTC')::date))
WHERE is_current = TRUE
  AND status <> 'cancelled'
  AND user_id <> '00000000-0000-0000-0000-000000000000';
