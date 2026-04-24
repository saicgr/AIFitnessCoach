-- Per-user partial progress toward a trophy. Separate from
-- user_achievements (completed earns only) so we can render progress bars
-- on locked trophies ("8/10 workouts logged").
--
-- Missing table caused GET /api/v1/progress/trophies/{user_id} to 500 with
-- PGRST205 "Could not find the table 'public.trophy_progress'". The code
-- has been writing/reading it for months (trophy_triggers.py +
-- trophies.py:218) but the DDL was never committed.
--
-- achievement_id is VARCHAR because public.achievement_types.id uses
-- human-readable slugs ('first_workout', not a UUID).

CREATE TABLE IF NOT EXISTS public.trophy_progress (
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    achievement_id VARCHAR NOT NULL REFERENCES public.achievement_types(id) ON DELETE CASCADE,
    current_value NUMERIC NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, achievement_id)
);

CREATE INDEX IF NOT EXISTS idx_trophy_progress_user
    ON public.trophy_progress (user_id);

ALTER TABLE public.trophy_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "trophy_progress_select_own" ON public.trophy_progress;
CREATE POLICY "trophy_progress_select_own" ON public.trophy_progress
    FOR SELECT
    USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "trophy_progress_service_write" ON public.trophy_progress;
CREATE POLICY "trophy_progress_service_write" ON public.trophy_progress
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

COMMENT ON TABLE public.trophy_progress IS
    'Per-user partial progress toward a trophy (achievement_types row). Upserted by trophy_triggers on workout/meal/hydration events; read by GET /progress/trophies/{user_id} to render locked-trophy progress bars.';
