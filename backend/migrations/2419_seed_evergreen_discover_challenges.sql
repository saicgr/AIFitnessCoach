-- Migration: Seed evergreen Discover challenges (finding #240)
-- Community -> Challenges -> Discover shows "No Challenges Found" for every
-- new user because `challenges` has zero seeded/curated rows — the feature
-- is fully built (see CHALLENGE_SYSTEM.md) but ships with no cold-start
-- content, so a user can only participate by authoring one and recruiting
-- friends they don't have yet. Seeds a small set of system-owned
-- (created_by NULL), public, long-lived challenges spanning the existing
-- ChallengeType values so Discover is never empty. end_date is 5 years out
-- so `active_only` (end_date >= now()) keeps them visible without an
-- ongoing refresh job.

INSERT INTO challenges (title, description, challenge_type, goal_value, goal_unit, start_date, end_date, created_by, is_public, participant_count)
SELECT * FROM (VALUES
    ('10,000 Steps a Day', 'Hit 10,000 steps every day this month.', 'step_count', 10000::double precision, 'steps', now(), now() + interval '5 years', NULL::uuid, true, 0),
    ('4 Workouts a Week', 'Complete 4 workouts every week — consistency over intensity.', 'workout_count', 4::double precision, 'workouts', now(), now() + interval '5 years', NULL::uuid, true, 0),
    ('30-Day Workout Streak', 'Log a workout every day for 30 days straight.', 'workout_streak', 30::double precision, 'days', now(), now() + interval '5 years', NULL::uuid, true, 0),
    ('100,000 kg Volume Club', 'Rack up 100,000 kg of total lifted volume.', 'total_volume', 100000::double precision, 'kg', now(), now() + interval '5 years', NULL::uuid, true, 0),
    ('12 Workouts This Month', 'Complete 12 workouts this month, whenever it fits your schedule.', 'workout_count', 12::double precision, 'workouts', now(), now() + interval '5 years', NULL::uuid, true, 0),
    ('7-Day Streak Starter', 'Log a workout every day for one week to build the habit.', 'workout_streak', 7::double precision, 'days', now(), now() + interval '5 years', NULL::uuid, true, 0)
) AS seed(title, description, challenge_type, goal_value, goal_unit, start_date, end_date, created_by, is_public, participant_count)
WHERE NOT EXISTS (
    SELECT 1 FROM challenges c
    WHERE c.created_by IS NULL AND c.title = seed.title
);

-- VERIFY: select title, challenge_type, goal_value, goal_unit, end_date from challenges where created_by is null order by title;
