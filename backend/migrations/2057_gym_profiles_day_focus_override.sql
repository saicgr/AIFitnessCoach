-- gym_profiles.day_focus_override
--
-- Lets users pin a specific focus (Upper, Lower, Push, Pull, Legs, Full Body,
-- Chest, Back, Shoulders, Arms, Core) to specific weekday(s) when the
-- training_split is "Let AI Decide" (`dont_know` / `nothing_structured`).
--
-- Key = weekday index as string ('0'..'6', Mon=0). Value = focus token.
-- Missing key → AI picks the focus for that day (current behaviour).
--
-- Read at workout-generation time by `get_workout_focus()` in
-- `backend/api/v1/workouts_db_helpers.py` — when an override exists for the
-- target weekday, it's used directly; otherwise the legacy heuristic runs.
--
-- Other splits (PPL, Upper/Lower, PHUL, Full Body, Body Part) ignore this
-- column — their day-to-focus mapping is already deterministic.

ALTER TABLE gym_profiles
    ADD COLUMN IF NOT EXISTS day_focus_override JSONB NOT NULL DEFAULT '{}'::jsonb;

COMMENT ON COLUMN gym_profiles.day_focus_override IS
    'Optional per-weekday focus pin for AI-Decide split. Keys are weekday ints 0..6 (Mon=0) as strings; values are focus tokens (upper/lower/full_body/push/pull/legs/chest/back/shoulders/arms/core). Empty object = full auto.';
