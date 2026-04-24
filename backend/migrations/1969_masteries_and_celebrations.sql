-- Migration 1969: Masteries (levelled badges) + celebration ack cursor
--
-- Supports the Badge Hub's MASTERIES grid (Steps Lv.6, Calories Lv.4 etc.)
-- and the app-open celebration ceremony (only replays trophies earned
-- since the last time the user ack'd a celebration).
--
-- Design notes:
--   • `mastery_definitions` is authoritative for *what* mastery types
--     exist and *what the level thresholds are*. We seed ~6 standard
--     masteries curated from Garmin/Strava/Whoop norms — never LLM-
--     generated (per feedback_no_llm_for_safety_classification.md).
--   • `user_masteries` tracks each user's current progress/level per
--     mastery type. Updated by the same triggers that fire trophies.
--   • `users.last_celebration_ack_at` is a simple cursor — the server
--     returns every trophy earned_at > cursor when the client asks for
--     pending celebrations, then the client POSTs ack to bump the cursor.

BEGIN;

-- ------------------------------------------------------------------
-- 1) Mastery definitions (static catalog, seeded below)
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mastery_definitions (
    key TEXT PRIMARY KEY,
    label TEXT NOT NULL,
    icon TEXT NOT NULL,                    -- Material icon key
    unit TEXT NOT NULL,                    -- 'steps' | 'calories' | 'km' | 'sessions' | 'minutes' | 'meters'
    -- Level thresholds stored as JSON array of cumulative values.
    -- Example: [25000, 50000, 100000, 250000, 500000, 1000000] means
    -- Lv 1 at 25k, Lv 2 at 50k, ... Lv 6 at 1M. Open-ended — clients treat
    -- the last entry as the "ongoing" level and re-level at every doubling.
    level_thresholds JSONB NOT NULL,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE mastery_definitions IS 'Authoritative catalog of mastery types + level thresholds.';
COMMENT ON COLUMN mastery_definitions.level_thresholds IS 'JSONB array of cumulative value thresholds. Index 0 = Lv 1, etc.';

-- Even though this table is a public catalog, PostgREST exposes it so we
-- still need RLS (supabase_linter: rls_disabled_in_public). Authenticated
-- users can read; only service role can write.
ALTER TABLE mastery_definitions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mastery_definitions_select ON mastery_definitions;
CREATE POLICY mastery_definitions_select ON mastery_definitions
    FOR SELECT
    USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');

DROP POLICY IF EXISTS mastery_definitions_service ON mastery_definitions;
CREATE POLICY mastery_definitions_service ON mastery_definitions
    FOR ALL
    USING (auth.role() = 'service_role');

-- ------------------------------------------------------------------
-- 2) Per-user mastery state
-- ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS user_masteries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    mastery_key TEXT NOT NULL REFERENCES mastery_definitions(key) ON DELETE CASCADE,
    current_value BIGINT NOT NULL DEFAULT 0,
    current_level INT NOT NULL DEFAULT 0,
    last_levelled_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_id, mastery_key)
);

CREATE INDEX IF NOT EXISTS idx_user_masteries_user_id ON user_masteries(user_id);
CREATE INDEX IF NOT EXISTS idx_user_masteries_key     ON user_masteries(mastery_key);

ALTER TABLE user_masteries ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS user_masteries_select ON user_masteries;
CREATE POLICY user_masteries_select ON user_masteries
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS user_masteries_service ON user_masteries;
CREATE POLICY user_masteries_service ON user_masteries
    FOR ALL USING (auth.role() = 'service_role');

COMMENT ON TABLE user_masteries IS 'Per-user progress + current level for each mastery type.';

-- ------------------------------------------------------------------
-- 3) Celebration ack cursor on users table
-- ------------------------------------------------------------------
ALTER TABLE users
    ADD COLUMN IF NOT EXISTS last_celebration_ack_at TIMESTAMPTZ;

COMMENT ON COLUMN users.last_celebration_ack_at IS
    'Cursor for pending-celebrations queue. Trophies with earned_at > this value are surfaced on app open.';

-- ------------------------------------------------------------------
-- 4) Seed mastery definitions
-- ------------------------------------------------------------------
-- Thresholds tuned from public norms (Garmin badge ladders, Whoop
-- strength-score bands, Strava monthly challenge bands). Values are
-- cumulative — Lv 1 at threshold[0], Lv 2 at threshold[1], etc.
INSERT INTO mastery_definitions (key, label, icon, unit, level_thresholds, sort_order) VALUES
    ('steps',
     'Steps',
     'directions_walk',
     'steps',
     '[25000, 100000, 250000, 500000, 1000000, 2500000]'::jsonb,
     10),
    ('calories',
     'Calories',
     'local_fire_department',
     'calories',
     '[2500, 10000, 25000, 50000, 100000, 250000]'::jsonb,
     20),
    ('running',
     'Running',
     'directions_run',
     'km',
     '[5, 25, 100, 250, 500, 1000]'::jsonb,
     30),
    ('active_minutes',
     'Active Minutes',
     'timer_outlined',
     'minutes',
     '[60, 300, 1000, 3000, 6000, 15000]'::jsonb,
     40),
    ('sessions',
     'Workout Sessions',
     'fitness_center',
     'sessions',
     '[5, 25, 50, 100, 250, 500]'::jsonb,
     50),
    ('elevation',
     'Elevation Gain',
     'terrain',
     'meters',
     '[500, 2500, 10000, 25000, 50000, 100000]'::jsonb,
     60)
ON CONFLICT (key) DO UPDATE
    SET label            = EXCLUDED.label,
        icon             = EXCLUDED.icon,
        unit             = EXCLUDED.unit,
        level_thresholds = EXCLUDED.level_thresholds,
        sort_order       = EXCLUDED.sort_order;

-- ------------------------------------------------------------------
-- 5) Helper: recompute mastery level from current value
-- ------------------------------------------------------------------
-- Returns the level the user should be at given their current cumulative
-- value and the definition's threshold ladder. Used by whatever ingestion
-- point updates `user_masteries.current_value` (steps sync, workout log
-- ingest, cardio log, etc.) to keep level in sync.
CREATE OR REPLACE FUNCTION mastery_level_for_value(
    p_thresholds JSONB,
    p_value BIGINT
)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
-- Pinning search_path prevents schema-resolution hijacking
-- (supabase_linter: function_search_path_mutable).
SET search_path = public, pg_temp
AS $$
DECLARE
    v_level INT := 0;
    v_threshold NUMERIC;
BEGIN
    FOR v_threshold IN
        SELECT (value)::NUMERIC
        FROM jsonb_array_elements(p_thresholds)
        ORDER BY (value)::NUMERIC ASC
    LOOP
        EXIT WHEN p_value < v_threshold;
        v_level := v_level + 1;
    END LOOP;
    RETURN v_level;
END;
$$;

COMMENT ON FUNCTION mastery_level_for_value IS
    'Given a mastery definition''s threshold array and a cumulative value, return the level the user should be at.';

COMMIT;
