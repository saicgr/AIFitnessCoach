-- Migration 2096: Workout card variant cache.
--
-- Caches pre-generated lighter / moderate variants of a source workout so
-- the home workout card's "Switch to lighter" / "Cycle-adjusted" buttons
-- are instant. Keyed by (source_workout_id, target_intensity) — re-running
-- the generator for the same input always returns the same cached variant.
--
-- Plan reference: §1b.2, §1b.8.
--
-- RLS: owner is the user_id of the source workout. Resolved via a join to
-- public.workouts.user_id → public.users.id → users.auth_id (matching the
-- coach_daily_insights pattern in migration 2094).
--
-- Idempotent: safe to re-run.

BEGIN;

CREATE TABLE IF NOT EXISTS public.workout_variants (
  source_id        uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  target_intensity text NOT NULL CHECK (target_intensity IN ('deload', 'moderate')),
  variant_id       uuid NOT NULL REFERENCES public.workouts(id) ON DELETE CASCADE,
  generated_at     timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (source_id, target_intensity)
);

CREATE INDEX IF NOT EXISTS idx_workout_variants_variant_id
  ON public.workout_variants (variant_id);

ALTER TABLE public.workout_variants ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own workout_variants" ON public.workout_variants;
CREATE POLICY "Users view own workout_variants"
  ON public.workout_variants FOR SELECT
  USING (
    auth.uid() = (
      SELECT u.auth_id
        FROM public.users u
        JOIN public.workouts w ON w.user_id = u.id
       WHERE w.id = source_id
    )
  );

DROP POLICY IF EXISTS "Users insert own workout_variants" ON public.workout_variants;
CREATE POLICY "Users insert own workout_variants"
  ON public.workout_variants FOR INSERT
  WITH CHECK (
    auth.uid() = (
      SELECT u.auth_id
        FROM public.users u
        JOIN public.workouts w ON w.user_id = u.id
       WHERE w.id = source_id
    )
  );

DROP POLICY IF EXISTS "Service role full access workout_variants" ON public.workout_variants;
CREATE POLICY "Service role full access workout_variants"
  ON public.workout_variants FOR ALL
  USING (auth.role() = 'service_role');

COMMENT ON TABLE public.workout_variants IS
  'Cache of pre-generated lighter/moderate variants for the home workout card. (source_id, target_intensity) is unique; variant_id points at the generated workout row.';

COMMIT;
