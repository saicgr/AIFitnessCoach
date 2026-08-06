-- 2404_fix_plank_challenge_duration_weeks.sql
--
-- UI_E2E 2026-08-05 row 30 (HIGH): Program library card + Program detail —
-- 30-Day Plank Challenge shows three different lengths on one screen: the
-- title says 30 days, the stat tile says "1 WEEKS", the phase list spans
-- Week 1-2 / 3-4 / 5, and the schedule actually contains 30 daily sessions.
--
-- ROOT CAUSE: data-entry bug on programs.id = 6e9539c2-feef-497d-9d0b-
-- 8c499838d2f8 ("30-Day Plank Challenge") — programs.duration_weeks is
-- stored as 1, but every OTHER field on the same row already agrees on 5
-- weeks:
--   * programs.workouts->>'duration' = '5 weeks' (the program's own embedded
--     metadata)
--   * programs.workouts->'workouts' has exactly 30 day-entries at
--     sessions_per_week=6 (30 / 6 = 5 weeks)
--   * programs.phases[2].week_end = 5 (the "Peak Holds" phase explicitly
--     ends week 5)
-- Only the top-level duration_weeks COLUMN (read by the library card + stat
-- tile) disagrees. Verified this is an ISOLATED data bug, not a systemic
-- class: a full-catalog scan (297 programs) cross-checking duration_weeks
-- against both the embedded blob's duration string/day-count and the
-- phases' max week_end found exactly this ONE mismatched row.
--
-- FIX: correct the single column to match every other source of truth on
-- the row. No code change needed — the stat tile / library card already
-- render `programs.duration_weeks` directly.

UPDATE programs
SET duration_weeks = 5
WHERE id = '6e9539c2-feef-497d-9d0b-8c499838d2f8'
  AND duration_weeks = 1;
