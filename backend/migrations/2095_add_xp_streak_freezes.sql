-- 2095_add_xp_streak_freezes.sql
-- Add streak-freeze accounting for the XP / login streak. Mirrors the existing
-- nutrition_streak_freeze pattern (nutrition_preferences_provider.dart:284).
--
-- - users.xp_streak_freezes_available: how many freezes the user currently has
--   banked. Default 2 (Duolingo-style cap, matches the nutrition freeze).
-- - user_login_streaks.last_freeze_used_at: the local date a freeze was last
--   used, so a misfire can't be double-applied on the same day.
-- - xp_events.used_freeze: per-event flag set when a freeze landed for that
--   day. The streak compute RPC can later treat used_freeze=true as a
--   streak-continuing day. (RPC modification is intentionally out of this
--   migration — schema must exist before the RPC can read it.)
--
-- Fully idempotent: every ADD COLUMN uses IF NOT EXISTS so re-running is a
-- no-op.

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS xp_streak_freezes_available integer NOT NULL DEFAULT 2;

ALTER TABLE public.user_login_streaks
  ADD COLUMN IF NOT EXISTS last_freeze_used_at date;

ALTER TABLE public.xp_events
  ADD COLUMN IF NOT EXISTS used_freeze boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.users.xp_streak_freezes_available IS
  'Banked XP-streak freezes. Decremented by /api/v1/xp/use-freeze. Cap=2, regenerates on month rollover (handled by Python — no scheduled SQL job).';
COMMENT ON COLUMN public.user_login_streaks.last_freeze_used_at IS
  'Local date the last freeze was applied. Prevents double-apply on the same day.';
COMMENT ON COLUMN public.xp_events.used_freeze IS
  'True when a streak freeze was used to bridge this day. Streak compute treats true as a continuing day.';
