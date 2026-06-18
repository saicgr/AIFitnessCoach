-- 2259_digestion_logs.sql
--
-- Nutrition overhaul (Phase 2B / Phase 6) — gut-health one-tap log.
--
-- A sibling to food_logs holding Bristol-Stool-Scale entries plus optional
-- urgency / duration / tags / note. One-tap-friendly: only bristol_type is
-- effectively required; everything else is nullable. Correlated against
-- food_logs.tags / foods over lagged windows by get_digestion_patterns
-- (migration 2260) to surface "dairy days → looser stool" style insights.
--
-- Convention mirrors food_logs exactly:
--   * user_id UUID -> users(id) ON DELETE CASCADE (users.id == auth.uid()).
--   * logged_at TIMESTAMPTZ for the event time (defaults to now()).
--   * RLS: own-row SELECT/INSERT/UPDATE/DELETE + service_role full access.

CREATE TABLE IF NOT EXISTS digestion_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Bristol Stool Scale (1 = hard lumps … 7 = liquid). The single required
    -- signal. 1-2 = constipation-leaning, 3-4 = ideal, 5-7 = loose-leaning.
    bristol_type SMALLINT NOT NULL CHECK (bristol_type BETWEEN 1 AND 7),

    -- Optional one-tap extras.
    urgency SMALLINT CHECK (urgency IS NULL OR urgency BETWEEN 1 AND 5),
    duration_seconds INTEGER CHECK (duration_seconds IS NULL OR duration_seconds >= 0),
    tags TEXT[],                         -- open-vocab (e.g. 'incomplete','painful','normal')
    notes TEXT,
    source TEXT,                         -- 'manual' | 'chat' | ... (provenance, nullable)

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Query index for the regularity series + correlation lag joins.
CREATE INDEX IF NOT EXISTS idx_digestion_logs_user_time
    ON digestion_logs (user_id, logged_at DESC);

-- GIN for tag correlation, partial like food_logs.
CREATE INDEX IF NOT EXISTS idx_digestion_logs_tags_gin
    ON digestion_logs USING GIN (tags)
    WHERE tags IS NOT NULL;

-- RLS — mirror food_logs / cardio_logs.
ALTER TABLE digestion_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own digestion logs"
    ON digestion_logs FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users insert own digestion logs"
    ON digestion_logs FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own digestion logs"
    ON digestion_logs FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users delete own digestion logs"
    ON digestion_logs FOR DELETE
    USING (auth.uid() = user_id);

CREATE POLICY "Service role full access digestion logs"
    ON digestion_logs FOR ALL
    USING (auth.role() = 'service_role');

COMMENT ON TABLE digestion_logs IS
    'Gut-health one-tap log (Phase 6). Bristol scale + optional urgency/'
    'duration/tags/note. Sibling to food_logs; correlated by get_digestion_patterns.';
COMMENT ON COLUMN digestion_logs.bristol_type IS
    'Bristol Stool Scale 1-7 (1 hard lumps … 4 ideal … 7 liquid).';
COMMENT ON COLUMN digestion_logs.urgency IS
    'Optional 1-5 urgency rating; NULL when the user only tapped the scale.';
