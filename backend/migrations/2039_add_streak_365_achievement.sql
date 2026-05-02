-- Migration 2039: Add streak_365_days to achievement_types
-- streak_365_days was referenced in trophy_triggers.py but missing from the table,
-- causing FK violations whenever the trigger fired for a 365-day streak.

INSERT INTO achievement_types (id, name, description, category, icon, tier, points, threshold_value, threshold_unit, is_repeatable)
VALUES (
    'streak_365_days',
    'Year of Iron',
    'Complete workouts 365 days in a row',
    'consistency',
    '👑',
    'platinum',
    2000,
    365,
    'days',
    true
)
ON CONFLICT (id) DO NOTHING;
