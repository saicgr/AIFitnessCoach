-- Migration 2236: Soft-delete (archive) for gym profiles
--
-- Context: deleting a gym profile must NOT orphan the progress logged there. We convert the
-- DELETE endpoint to a soft-archive (archived_at = now()). Archived gyms are hidden from
-- pickers and workout generation but stay joinable so historical per-gym progress survives and
-- can still be filtered (shown as "Archived"). gym_profile_id on old logs never goes stale.
--
-- The active-profile partial unique index is recreated to also require archived_at IS NULL,
-- so an archived profile can never be the active one (defensive — the endpoint also deactivates
-- on archive).

ALTER TABLE gym_profiles
    ADD COLUMN IF NOT EXISTS archived_at TIMESTAMPTZ;

-- Fast "my live (non-archived) profiles" lookups used by pickers + generation.
CREATE INDEX IF NOT EXISTS idx_gym_profiles_user_live
    ON gym_profiles(user_id, display_order)
    WHERE archived_at IS NULL;

-- One active profile per user, AND it must be non-archived.
DROP INDEX IF EXISTS idx_gym_profiles_active_per_user;
CREATE UNIQUE INDEX IF NOT EXISTS idx_gym_profiles_active_per_user
    ON gym_profiles(user_id)
    WHERE is_active = true AND archived_at IS NULL;

COMMENT ON COLUMN gym_profiles.archived_at IS
    'Soft-delete timestamp. NULL = live. Non-NULL = archived: hidden from pickers/generation '
    'but retained so historical per-gym progress (workout_logs/performance_logs.gym_profile_id) '
    'stays attributed and filterable.';
