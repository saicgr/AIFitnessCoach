-- Migration 2229: Race/event goal date (Gap 11)
-- custom_goals already carries goal_type ('endurance'/'sport') + progression
-- 'periodized'; this adds the dated-event fields that unlock the deterministic
-- periodization schedule (base → build → peak → taper → race week) and the
-- daily auto-adjust the coach reads.

ALTER TABLE custom_goals ADD COLUMN IF NOT EXISTS event_date DATE;
ALTER TABLE custom_goals ADD COLUMN IF NOT EXISTS event_name TEXT;

-- Fast lookup of a user's active dated goal (the soonest upcoming event).
CREATE INDEX IF NOT EXISTS idx_custom_goals_event_date
    ON custom_goals (user_id, event_date)
    WHERE event_date IS NOT NULL AND is_active = TRUE;

COMMENT ON COLUMN custom_goals.event_date IS 'Gap 11 — race/event date; drives periodization phase + daily auto-adjust.';
COMMENT ON COLUMN custom_goals.event_name IS 'Gap 11 — human race/event name (e.g. "Chicago Marathon").';
