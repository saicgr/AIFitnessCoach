-- Relax workouts_one_current_per_user_day to allow user-manual workouts to
-- coexist with the day's canonical (auto-generated) plan.
--
-- Background: migration 2048 introduced a partial unique index ensuring
-- exactly one is_current=TRUE row per (user_id, day) to prevent the
-- onboarding-race bug where two background generators both produced a
-- "today" workout. That constraint is correct for AUTO-generated workouts
-- but wrongly blocks the legitimate use case of a user MANUALLY creating an
-- extra workout for a day that already has an auto-generated plan.
--
-- Per product spec (user clarification 2026-05-03): "one current per day
-- unless the user created manually then they can have two."
--
-- App-side fix (already shipped): backend/api/v1/workouts/crud.py and
-- quick.py now set is_current=FALSE on user-manual creates so they don't
-- claim the canonical slot. This migration is belt-and-suspenders: even if
-- a future code path forgets to set is_current=FALSE, rows whose
-- generation_source marks them as user-driven will be excluded from the
-- partial unique index — they get to coexist no matter what.
--
-- The list endpoint (backend/core/db/workout_db.py:list_workouts) was
-- updated to surface BOTH canonical (is_current=TRUE) AND manual extras
-- (is_current=FALSE, valid_to IS NULL, manual generation_source) so the
-- user actually sees their additions.

DROP INDEX IF EXISTS workouts_one_current_per_user_day;

CREATE UNIQUE INDEX workouts_one_current_per_user_day
ON workouts (user_id, ((scheduled_date AT TIME ZONE 'UTC')::date))
WHERE is_current = TRUE
  AND status <> 'cancelled'
  AND user_id <> '00000000-0000-0000-0000-000000000000'
  AND COALESCE(generation_source, '') NOT IN (
    'manual',
    'user_created',
    'quick_workout',
    'manual_create'
  );

COMMENT ON INDEX workouts_one_current_per_user_day IS
  'Enforces one canonical (auto-generated) is_current workout per user per '
  'day. Manual user creations are excluded from the constraint by '
  'generation_source so users can add extra sessions on top of the daily '
  'plan. See migration 2049 for rationale.';
