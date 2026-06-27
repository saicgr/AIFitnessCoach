-- 2293: Persistent exercise substitutions ("swap going forward").
--
-- Context: Hevy-Trainer churn driver #1 ("I want to swap an exercise once, not
-- every week") + #2 ("if you swap, no more progressive overload"). Today an
-- exercise swap (POST /swap-exercise) mutates ONE workout's exercises_json and
-- writes an audit row to exercise_swaps — it reverts on the next AI generation,
-- and progression history (keyed by exercise_name) is orphaned for the new lift.
--
-- This table records, per (user, original exercise A), the substitute B the user
-- prefers going forward. Two consumers read it:
--   * generation post-filter (generation_endpoints.py): replace any generated A
--     with B, so future workouts honor the swap.
--   * weight suggestions (weight_suggestions.py): when reading B's history, also
--     read A's, so progressive overload follows the swap (existing decay model in
--     strength_recalc.py then carries the trajectory).
--
-- No FK on user_id: the codebase has a known public.users.id vs auth.users.id
-- drift (see exercise_swaps→auth.users vs performance_logs→users); we store and
-- query with the same user_id the swap/generation paths already use, so a hard FK
-- would only risk insert failures. Fail-open is the contract everywhere here.
--
-- Applied via Supabase MCP apply_migration (project hpbzfahijszqmgsybuor).

CREATE TABLE IF NOT EXISTS public.user_exercise_substitutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  -- Slot context (informational + future slot-matching refinement). The active
  -- key is original_exercise_name_norm; muscle_group/movement_pattern are stored
  -- best-effort from the substitute's library row.
  muscle_group TEXT NOT NULL DEFAULT '',
  movement_pattern TEXT,
  -- The swap pair. *_norm = lower(trim()) to match strength_recalc._norm_key.
  original_exercise_name TEXT NOT NULL,
  original_exercise_name_norm TEXT NOT NULL,
  substitute_exercise_name TEXT NOT NULL,
  substitute_exercise_name_norm TEXT NOT NULL,
  substitute_library_id TEXT,
  reason TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- One active substitute per source exercise per user. Upsert target.
  CONSTRAINT uq_user_sub_original UNIQUE (user_id, original_exercise_name_norm)
);

-- Generation reads all active subs for a user.
CREATE INDEX IF NOT EXISTS idx_user_subs_active
  ON public.user_exercise_substitutions (user_id)
  WHERE is_active;

-- Weight suggestions reads originals (A) that map TO a given substitute (B).
CREATE INDEX IF NOT EXISTS idx_user_subs_substitute
  ON public.user_exercise_substitutions (user_id, substitute_exercise_name_norm)
  WHERE is_active;
