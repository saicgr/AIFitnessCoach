-- ============================================================================
-- Migration 2218 — chat_sessions + chat_history.session_id (Ask-Coach sessions)
-- ============================================================================
-- Turns the single flat per-user chat log into named, searchable sessions
-- (like ChatGPT/Gemini conversations). Each session gets an AI-generated 3-5
-- word title from its first message. Existing flat history is backfilled into
-- ONE "Previous chat" session per user so nothing is lost.
--
-- RLS mirrors coach_daily_insights (2094): own-rows via the users.auth_id join
-- + a service-role full-access policy for backend writes.
--
-- Idempotent: safe to re-run (the backfill only touches NULL session_id rows).
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.chat_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  title text,                                   -- NULL until the title job runs
  is_archived boolean NOT NULL DEFAULT false,
  message_count integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  last_message_at timestamptz NOT NULL DEFAULT now()
);

-- Session list hot path: a user's sessions, most-recent activity first.
CREATE INDEX IF NOT EXISTS idx_chat_sessions_user_last_msg
  ON public.chat_sessions (user_id, last_message_at DESC);

COMMENT ON TABLE public.chat_sessions IS
  'Ask-Coach conversation sessions (named, searchable). One flat log per user is migrated into a single "Previous chat" session. Added in 2218.';

-- Add the FK on chat_history. ON DELETE CASCADE so deleting a session removes
-- its turns. Nullable so a turn can briefly exist before its session is set.
ALTER TABLE public.chat_history
  ADD COLUMN IF NOT EXISTS session_id uuid
    REFERENCES public.chat_sessions(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_chat_history_session_ts
  ON public.chat_history (session_id, timestamp)
  WHERE session_id IS NOT NULL;

COMMENT ON COLUMN public.chat_history.session_id IS
  'Owning chat_sessions.id. NULL only transiently / for un-backfilled rows. Added in 2218.';

-- ---------------------------------------------------------------------------
-- updated_at trigger.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_chat_sessions_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_chat_sessions_updated_at ON public.chat_sessions;
CREATE TRIGGER trg_chat_sessions_updated_at
  BEFORE UPDATE ON public.chat_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_chat_sessions_updated_at();

-- ---------------------------------------------------------------------------
-- RLS.
-- ---------------------------------------------------------------------------
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own chat_sessions" ON public.chat_sessions;
CREATE POLICY "Users view own chat_sessions"
  ON public.chat_sessions FOR SELECT
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Users update own chat_sessions" ON public.chat_sessions;
CREATE POLICY "Users update own chat_sessions"
  ON public.chat_sessions FOR UPDATE
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Users delete own chat_sessions" ON public.chat_sessions;
CREATE POLICY "Users delete own chat_sessions"
  ON public.chat_sessions FOR DELETE
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Service role full access chat_sessions" ON public.chat_sessions;
CREATE POLICY "Service role full access chat_sessions"
  ON public.chat_sessions FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ---------------------------------------------------------------------------
-- Backfill: one "Previous chat" session per user that has un-sessioned history.
-- created_at = first message, last_message_at = last message, count = rows.
-- ---------------------------------------------------------------------------
WITH per_user AS (
  SELECT user_id,
         min(timestamp) AS first_ts,
         max(timestamp) AS last_ts,
         count(*)       AS cnt
  FROM public.chat_history
  WHERE session_id IS NULL
  GROUP BY user_id
), inserted AS (
  INSERT INTO public.chat_sessions
    (user_id, title, created_at, updated_at, last_message_at, message_count)
  SELECT user_id, 'Previous chat', first_ts, last_ts, last_ts, cnt
  FROM per_user
  RETURNING id, user_id
)
UPDATE public.chat_history ch
SET session_id = i.id
FROM inserted i
WHERE ch.user_id = i.user_id
  AND ch.session_id IS NULL;

COMMIT;
