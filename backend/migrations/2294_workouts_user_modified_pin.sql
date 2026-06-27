-- 2294: Pin hand-edited workouts against the regenerate cascade (F5).
--
-- Context: Hevy-Trainer churn ask "let me modify/alter the workouts coming in
-- the future" — and even when you edit one, a program change blows it away.
-- Today every program mutation funnels through
-- invalidate_workouts_after_program_change → invalidate_upcoming_workouts, which
-- DELETES all future incomplete workouts so /today regenerates them. A workout
-- the user hand-edited (swap, add, reorder, PATCH) gets silently overwritten.
--
-- is_user_modified marks a workout as user-owned. The invalidation helpers
-- (api/v1/workouts/utils.py) now SKIP pinned rows, so a hand-edited future
-- workout survives program changes. "Reset to plan" (PATCH .../reset) clears the
-- flag and lets it regenerate again. user_modified_at is for telemetry / sort.
--
-- Applied via Supabase MCP apply_migration (project hpbzfahijszqmgsybuor).

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS is_user_modified BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS user_modified_at TIMESTAMPTZ;
