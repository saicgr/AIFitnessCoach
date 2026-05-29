-- 2214_mindfulness_sessions.sql
-- Backs the "Mindfulness minutes" key metric (Google Health parity).
--
-- Until now mindful_minutes_ring.dart hardcoded `minutes = 0` with a
-- TODO(backend) — there was no table to record completed meditation /
-- breathwork sessions and no aggregate to read them back. This adds:
--   1. mindfulness_sessions       — one row per completed in-app session
--   2. health_goals.{low,high}_hr_threshold — optional per-user overrides for
--      the new resting-HR health check (defaults are deterministic clinical refs)
--
-- Daily aggregation is by `local_date` (the user's timezone calendar day,
-- frozen at write time) so a session logged at 11:58pm local stays on that
-- local day and travelling across timezones never reshuffles history — same
-- pattern as migrations/259_hydration_local_date.sql.
--
-- Idempotent.

-- ----------------------------------------------------------------------------
-- mindfulness_sessions — one row per completed meditation/breathwork session.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mindfulness_sessions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  source           text NOT NULL DEFAULT 'meditation',   -- meditation | breathwork | sleep_story
  meditation_slug  text,                                 -- nullable; loosely links to meditations.slug (no FK — slugs are content, may rotate)
  duration_seconds integer NOT NULL CHECK (duration_seconds > 0 AND duration_seconds <= 14400),  -- > 0, capped at 4h to reject glitches
  completed_at     timestamptz NOT NULL DEFAULT now(),
  local_date       date NOT NULL,                        -- user-local calendar day for daily aggregation
  created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_mindfulness_sessions_user_localdate
  ON mindfulness_sessions(user_id, local_date DESC);

ALTER TABLE mindfulness_sessions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS mindfulness_sessions_owner ON mindfulness_sessions;
CREATE POLICY mindfulness_sessions_owner ON mindfulness_sessions
  FOR ALL USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- health_goals — optional resting-HR alert overrides. NULL => deterministic
-- defaults applied client-side (low < 40 bradycardia, high > 100 tachycardia;
-- 40-59 surfaced as informational "low-normal/athletic", never an alert).
-- ----------------------------------------------------------------------------
ALTER TABLE health_goals
  ADD COLUMN IF NOT EXISTS low_hr_threshold  integer,
  ADD COLUMN IF NOT EXISTS high_hr_threshold integer;
