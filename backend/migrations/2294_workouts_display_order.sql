-- 2294: workouts.display_order — deterministic intra-day ordering for days that
-- carry MORE THAN ONE workout on the same scheduled date.
--
-- Context (Phase 3 per-day resolution): the Program Library "Start" flow can now
-- STACK a new program's session alongside an existing workout on the same date
-- (the per-day "add" resolution tags the new row program_slot='addon'), and a
-- variant week with more sessions than the user's training weekdays lands two
-- sessions on one date. today.py orders same-date workouts by program_slot rank
-- then created_at — but a batch insert gives sibling rows near-identical
-- created_at, so the intra-slot order was non-deterministic (home card could
-- flicker between sessions). display_order is the stable per-day tiebreak: the
-- program expander sets it from the session/day index (lower = earlier in the
-- day). NULL for legacy / AI-decides / quick rows (treated as 0 at read time).
--
-- Applied via Supabase MCP apply_migration on 2026-06-27 (project
-- hpbzfahijszqmgsybuor). This file is the repo record of that change.

ALTER TABLE public.workouts
  ADD COLUMN IF NOT EXISTS display_order smallint;

COMMENT ON COLUMN public.workouts.display_order IS
  'Intra-day display order for multi-session days (lower shows first within a program_slot). Set by the program expander from the session/day index. NULL for legacy/AI/quick rows (treated as 0 at read time). today.py orders same-date workouts by program_slot, then COALESCE(display_order,0), then created_at.';
