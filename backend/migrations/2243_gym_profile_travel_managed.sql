-- Migration 2243: Travel-managed gym profile flag (Feature 3B)
--
-- Context: one-tap Travel Mode activates a single dedicated bodyweight gym
-- profile per user. We tag that profile with `is_travel_managed = TRUE` so the
-- activate-travel endpoint can find-or-restore-or-create exactly ONE such
-- profile (never a duplicate) and the UI can render bodyweight-specific copy.
--
-- The profile is otherwise an ordinary gym_profile (it participates in the
-- per-gym stream: archived_at soft-archive, gym_profile_id on logs, the
-- last-live-profile guard). This flag is purely additive.
--
-- Idempotent (ADD COLUMN IF NOT EXISTS / CREATE UNIQUE INDEX IF NOT EXISTS).

ALTER TABLE gym_profiles
    ADD COLUMN IF NOT EXISTS is_travel_managed BOOLEAN NOT NULL DEFAULT FALSE;

-- At most ONE travel-managed profile per user. Partial unique index so the
-- find-or-restore-or-create logic can never strand a user with two travel
-- profiles (the endpoint reuses/restores the existing one instead of inserting).
CREATE UNIQUE INDEX IF NOT EXISTS idx_gym_profiles_one_travel_per_user
    ON gym_profiles(user_id)
    WHERE is_travel_managed = TRUE;

COMMENT ON COLUMN gym_profiles.is_travel_managed IS
    'TRUE for the single per-user bodyweight Travel/Hotel profile activated via '
    'POST /gym-profiles/travel-mode/activate. At most one per user (partial unique '
    'index). Otherwise an ordinary gym_profile (soft-archive + per-gym attribution apply).';
