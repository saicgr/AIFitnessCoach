-- Migration: 509_recipe_cook_events.sql
-- Description: Cook-once-eat-many model.
--   A cook event records a real cooking session: portions made, what's left, when it expires.
--   food_logs.cook_event_id ties a log back to a cook event; trigger decrements portions_remaining.
--   scheduled_recipe_logs.cook_event_id (added in 503) finally gets its FK here.
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS recipe_cook_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES user_recipes(id) ON DELETE SET NULL,

    cooked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    portions_made NUMERIC(5,2) NOT NULL CHECK (portions_made > 0),
    portions_remaining NUMERIC(5,2) NOT NULL CHECK (portions_remaining >= 0),

    storage TEXT NOT NULL DEFAULT 'fridge'
        CHECK (storage IN ('fridge','freezer','counter')),
    expires_at TIMESTAMPTZ NOT NULL,    -- defaulted by service from storage; user can override

    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Sanity: can't have more remaining than ever made
    CHECK (portions_remaining <= portions_made)
);

CREATE INDEX IF NOT EXISTS idx_cook_events_user_active
    ON recipe_cook_events (user_id, cooked_at DESC)
    WHERE portions_remaining > 0;
CREATE INDEX IF NOT EXISTS idx_cook_events_recipe
    ON recipe_cook_events (recipe_id) WHERE recipe_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_cook_events_expiring
    ON recipe_cook_events (expires_at) WHERE portions_remaining > 0;

ALTER TABLE recipe_cook_events ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users manage own cook events" ON recipe_cook_events;
CREATE POLICY "Users manage own cook events"
    ON recipe_cook_events FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
DROP POLICY IF EXISTS "Service role full access cook events" ON recipe_cook_events;
CREATE POLICY "Service role full access cook events"
    ON recipe_cook_events FOR ALL TO service_role USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION set_cook_events_updated_at()
RETURNS TRIGGER SECURITY DEFINER SET search_path = public
AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cook_events_updated_at ON recipe_cook_events;
CREATE TRIGGER trg_cook_events_updated_at
    BEFORE UPDATE ON recipe_cook_events
    FOR EACH ROW EXECUTE FUNCTION set_cook_events_updated_at();

-- food_logs gets:
--   cook_event_id        FK to a cook event when this log was a leftover serving
--   servings_consumed    NUMERIC for the decrement trigger (also useful for recipe logs in general)
--   nutrition_confidence aggregate confidence label propagated from recipe ingredients
ALTER TABLE food_logs
    ADD COLUMN IF NOT EXISTS cook_event_id UUID REFERENCES recipe_cook_events(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS servings_consumed NUMERIC(5,2),
    ADD COLUMN IF NOT EXISTS nutrition_confidence TEXT
        CHECK (nutrition_confidence IS NULL OR nutrition_confidence IN ('high','medium','low'));

CREATE INDEX IF NOT EXISTS idx_food_logs_cook_event
    ON food_logs (cook_event_id) WHERE cook_event_id IS NOT NULL;

-- Decrement portions_remaining when a food_log is created against a cook event.
CREATE OR REPLACE FUNCTION decrement_cook_event_remaining()
RETURNS TRIGGER
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
    IF NEW.cook_event_id IS NULL THEN
        RETURN NEW;
    END IF;

    UPDATE recipe_cook_events
        SET portions_remaining = GREATEST(portions_remaining - COALESCE(NEW.servings_consumed, 1), 0)
        WHERE id = NEW.cook_event_id;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_decrement_cook_event_remaining ON food_logs;
CREATE TRIGGER trg_decrement_cook_event_remaining
    AFTER INSERT ON food_logs
    FOR EACH ROW EXECUTE FUNCTION decrement_cook_event_remaining();

-- Now wire scheduled_recipe_logs.cook_event_id (was nullable column with no FK in 503)
DO $$ BEGIN
    ALTER TABLE scheduled_recipe_logs
        ADD CONSTRAINT scheduled_recipe_logs_cook_event_fk
        FOREIGN KEY (cook_event_id) REFERENCES recipe_cook_events(id) ON DELETE CASCADE;
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

COMMENT ON TABLE recipe_cook_events IS
    'A real cooking session: portions made, remaining, storage, expiry. Logs decrement remaining via trigger.';
COMMENT ON COLUMN food_logs.nutrition_confidence IS
    'Aggregate confidence across the recipe ingredients used: high (all branded/USDA) | medium (some AI) | low (mostly AI)';
