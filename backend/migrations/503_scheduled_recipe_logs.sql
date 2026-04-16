-- Migration: 503_scheduled_recipe_logs.sql
-- Description: Recurring + batch meal-reminder schedules.
--   - 'recurring' mode: daily/weekdays/weekends/custom-days at a fixed local time, fires forever
--   - 'batch' mode:    cook-once-eat-many; fires through a fixed array of (date, meal_type, servings)
--                      slots tied to a single recipe_cook_events row, then auto-disables
-- Created: 2026-04-14

CREATE TABLE IF NOT EXISTS scheduled_recipe_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    recipe_id UUID REFERENCES user_recipes(id) ON DELETE CASCADE,

    -- Mode + recurring fields
    schedule_mode TEXT NOT NULL DEFAULT 'recurring'
        CHECK (schedule_mode IN ('recurring', 'batch')),
    meal_type TEXT NOT NULL
        CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    servings NUMERIC(5,2) DEFAULT 1.0,

    schedule_kind TEXT
        CHECK (schedule_kind IS NULL
               OR schedule_kind IN ('daily', 'weekdays', 'weekends', 'custom')),
    days_of_week INT[],          -- 0=Sun..6=Sat; only used when schedule_kind='custom'
    local_time TIME,             -- HH:MM local; required for recurring
    timezone TEXT NOT NULL,      -- IANA, per feedback_user_local_time_only.md

    -- Cron lookup
    next_fire_at TIMESTAMPTZ NOT NULL,
    last_fired_at TIMESTAMPTZ,

    -- Batch-mode fields (NULL for recurring schedules)
    cook_event_id UUID,           -- FK added in migration 509 to avoid forward-ref
    batch_slots JSONB,            -- [{local_date, meal_type, local_time, servings}, ...]
    next_slot_index INT DEFAULT 0,

    -- Pause + enable controls
    paused_until DATE,            -- vacation mode integration
    enabled BOOLEAN DEFAULT TRUE,

    -- Notification log_recipe action defaults to notify+confirm; user can flip per-schedule
    silent_log BOOLEAN DEFAULT FALSE,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cron worker hot path: only enabled, not paused, due now
CREATE INDEX IF NOT EXISTS idx_scheduled_recipe_due
    ON scheduled_recipe_logs (next_fire_at)
    WHERE enabled = TRUE AND paused_until IS NULL;

CREATE INDEX IF NOT EXISTS idx_scheduled_recipe_user
    ON scheduled_recipe_logs (user_id, enabled);

CREATE INDEX IF NOT EXISTS idx_scheduled_recipe_recipe
    ON scheduled_recipe_logs (recipe_id) WHERE recipe_id IS NOT NULL;

ALTER TABLE scheduled_recipe_logs ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users manage own scheduled recipe logs" ON scheduled_recipe_logs;
CREATE POLICY "Users manage own scheduled recipe logs"
    ON scheduled_recipe_logs FOR ALL
    USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Service role full access scheduled recipe logs" ON scheduled_recipe_logs;
CREATE POLICY "Service role full access scheduled recipe logs"
    ON scheduled_recipe_logs FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

CREATE OR REPLACE FUNCTION set_scheduled_recipe_logs_updated_at()
RETURNS TRIGGER
SECURITY DEFINER SET search_path = public
AS $$ BEGIN NEW.updated_at = NOW(); RETURN NEW; END; $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_scheduled_recipe_logs_updated_at ON scheduled_recipe_logs;
CREATE TRIGGER trg_scheduled_recipe_logs_updated_at
    BEFORE UPDATE ON scheduled_recipe_logs
    FOR EACH ROW EXECUTE FUNCTION set_scheduled_recipe_logs_updated_at();

COMMENT ON TABLE scheduled_recipe_logs IS
    'Recurring meal reminders + cook-once-eat-many batch schedules. Fired by hourly cron in user-local time.';
COMMENT ON COLUMN scheduled_recipe_logs.batch_slots IS
    'For schedule_mode=batch: ordered array of {local_date, meal_type, local_time, servings}. Worker advances next_slot_index per fire.';
COMMENT ON COLUMN scheduled_recipe_logs.silent_log IS
    'Default FALSE = notify and let user one-tap confirm. TRUE = log silently (advanced opt-in).';
