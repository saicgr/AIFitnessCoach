-- 2233_streak_freeze.sql
-- Workstream B9 — Streak-freeze AUTO-EARN + ledger (match/beat Gravl's freeze
-- syncing + streak rewards). Builds on migration 2095, which added
-- `users.xp_streak_freezes_available` (the live balance) and
-- `user_login_streaks.last_freeze_used_at` (same-day double-apply guard).
--
-- What 2095 was missing and this migration adds:
--   1. An auditable LEDGER (`xp_streak_freeze_ledger`) so every earn/use of a
--      freeze is recorded with a reason. Gravl shows users "you earned a freeze"
--      / "a freeze saved your streak" — that history needs a backing table.
--   2. AUTO-EARN bookkeeping on `user_login_streaks`:
--        * `freezes_earned_total`  — cumulative freezes ever auto-granted.
--        * `last_freeze_earned_streak` — the streak-day count at which the most
--          recent freeze was auto-granted, so the 70-day (10-week) cadence can
--          be computed without re-scanning the ledger on every login.
--   3. `auto_protected_today` on the login-streak row — set TRUE on the day a
--      banked freeze auto-bridged a missed day (distinct from a manual
--      /use-freeze spend), so the client can show the right celebration copy.
--
-- DO NOT APPLY in this run (reserved migration 2233). Fully idempotent:
-- every object uses IF NOT EXISTS so re-running is a no-op.

-- ---------------------------------------------------------------------------
-- 1. Auto-earn bookkeeping columns on the login-streak row.
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_login_streaks
  ADD COLUMN IF NOT EXISTS freezes_earned_total integer NOT NULL DEFAULT 0;

ALTER TABLE public.user_login_streaks
  ADD COLUMN IF NOT EXISTS last_freeze_earned_streak integer NOT NULL DEFAULT 0;

ALTER TABLE public.user_login_streaks
  ADD COLUMN IF NOT EXISTS auto_protected_today boolean NOT NULL DEFAULT false;

COMMENT ON COLUMN public.user_login_streaks.freezes_earned_total IS
  'Cumulative count of freezes AUTO-granted to this user (1 per 10 weeks / 70 streak-days of activity). Manual grants/admin gifts are not counted here.';
COMMENT ON COLUMN public.user_login_streaks.last_freeze_earned_streak IS
  'The current_streak value at which the most recent auto-earned freeze was granted. Used to gate the next auto-grant at +70 streak-days without re-scanning the ledger.';
COMMENT ON COLUMN public.user_login_streaks.auto_protected_today IS
  'TRUE for the local day a banked freeze auto-bridged a missed day (passive protection). Distinct from a manual /use-freeze spend so the client can show "a freeze saved your streak" copy.';

-- ---------------------------------------------------------------------------
-- 2. Freeze ledger — append-only audit trail of every earn/use.
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.xp_streak_freeze_ledger (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  -- 'earned'  : auto-granted (10-week cadence) or admin gift.
  -- 'used'    : manually spent via /api/v1/xp/use-freeze.
  -- 'auto_used': a banked freeze passively bridged a missed day.
  delta       integer NOT NULL,            -- +1 earned, -1 used/auto_used
  reason      text NOT NULL,               -- 'auto_earn_10wk' | 'manual_use' | 'auto_protect' | 'admin_gift'
  -- Balance AFTER this entry was applied (denormalised for fast "current
  -- balance" reads and tamper-evident reconciliation against users.*).
  balance_after integer NOT NULL,
  -- The streak-day count when this entry happened (context for the UI).
  streak_day  integer,
  -- The user-local date this ledger entry is attributed to.
  event_date  date,
  created_at  timestamptz NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.xp_streak_freeze_ledger IS
  'Append-only audit log of streak-freeze earns and uses. Source of truth for the freeze history shown in the streak timeframe sheet. users.xp_streak_freezes_available is the fast live balance; this table is the history.';

-- Fast "this user's freeze history, newest first" reads.
CREATE INDEX IF NOT EXISTS idx_xp_streak_freeze_ledger_user_created
  ON public.xp_streak_freeze_ledger (user_id, created_at DESC);

-- Idempotency guard: at most one auto_earn ledger row per user per streak_day,
-- so a retried login can't double-grant a freeze for the same milestone day.
CREATE UNIQUE INDEX IF NOT EXISTS uq_xp_streak_freeze_auto_earn_per_streakday
  ON public.xp_streak_freeze_ledger (user_id, streak_day)
  WHERE reason = 'auto_earn_10wk';

-- ---------------------------------------------------------------------------
-- 3. RLS — a user can read only their own ledger; writes are service-role only
--    (the Python /xp endpoints run with the service key).
-- ---------------------------------------------------------------------------
ALTER TABLE public.xp_streak_freeze_ledger ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'xp_streak_freeze_ledger'
      AND policyname = 'freeze_ledger_select_own'
  ) THEN
    CREATE POLICY freeze_ledger_select_own
      ON public.xp_streak_freeze_ledger
      FOR SELECT
      USING (auth.uid() = user_id);
  END IF;
END$$;
