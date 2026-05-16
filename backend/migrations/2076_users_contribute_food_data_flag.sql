-- 2076_users_contribute_food_data_flag.sql
--
-- Phase 2 §2.11: opt-out flag for user-contributed food data sharing.
--
-- Default ON (most users want better experience for themselves AND others).
-- Settings UI lets the user opt out. When opted out:
--   - Read path: still hits THEIR existing user_contributed rows (their data)
--   - Write path: skips upsert into food_overrides_user_contributed
--   - Promotion job: their existing rows still factor into cross-user
--     averaging UNTIL they hit "Delete my contributions" (separate action).
--
-- The deletion path is implemented at the API layer
-- (DELETE FROM food_overrides_user_contributed WHERE user_id = $1)
-- so we don't auto-purge on toggle — explicit user action only.

ALTER TABLE users
  ADD COLUMN IF NOT EXISTS contribute_food_data BOOLEAN NOT NULL DEFAULT TRUE;

COMMENT ON COLUMN users.contribute_food_data IS
  'Per-user opt-out for food-data contribution. When FALSE, the runtime path skips writes to food_overrides_user_contributed AND excludes this user from cross-user promotion job aggregation. Default TRUE (opt-in by default). User-facing toggle in Settings → Privacy.';
