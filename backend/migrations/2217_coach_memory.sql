-- ============================================================================
-- Migration 2217 — coach_memory (persistent, typed coach memory)
-- ============================================================================
-- Gives the AI coach durable, cross-session, cross-day memory of facts the
-- user tells it ("I have lower back pain", "I'm vegetarian", "training for a
-- 5K"). This is the system of record; a denormalized embedding index lives in
-- ChromaDB (collection `coach_memory`) for relevance retrieval only.
--
-- Design (proper, typed memory — not a flat fact bucket):
--   memory_type:
--     'semantic'  durable identity / preference / goal / constraint / equipment
--     'episodic'  time-stamped event or transient state (decays)
--     'state'     OPEN LOOP needing follow-up (e.g. back pain awaiting check-in)
--     'derived'   coach-authored observation inferred from data (lower trust)
--   status:
--     'provisional' extracted at low confidence; NOT injected until reinforced
--     'active'      injected into coach prompt + briefing
--     'open'        active AND an open loop (has follow_up_after + resolution_prompt)
--     'resolved'    loop closed ("back feels better") — kept for history, not injected
--     'superseded'  replaced by a newer fact (superseded_by points at it)
--     'dismissed'   user deleted it — tombstone so extraction won't re-add
--
-- Authoritative-source deference: memory stores QUALITATIVE/contextual facts,
-- never numbers tracked elsewhere (weight, RHR, logged food, completed
-- workouts). Injury-shaped facts dual-write: the structured injury_history row
-- (existing engine) AND a coach_memory row (conversational follow-up), linked
-- via linked_table/linked_id so the injection layer dedupes to one fact.
--
-- Privacy: gated by users.coach_memory_enabled (added here) AND the existing
-- chat-history consent. RLS mirrors coach_daily_insights (migration 2094):
-- user SELECT/UPDATE/DELETE through the users.auth_id join + a service-role
-- full-access policy for backend writes.
--
-- Idempotent: safe to re-run.
-- ============================================================================

BEGIN;

CREATE TABLE IF NOT EXISTS public.coach_memory (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,

  memory_type text NOT NULL DEFAULT 'semantic'
    CHECK (memory_type IN ('semantic','episodic','state','derived')),
  -- Open vocabulary canonical tag (semantically assigned by the extractor;
  -- NOT a hard whitelist — new tags are allowed). Common: preference, goal,
  -- constraint, equipment, dietary, injury, life_event, nutrition,
  -- observation, schedule, motivation, other.
  category text NOT NULL DEFAULT 'other',
  content text NOT NULL,

  status text NOT NULL DEFAULT 'active'
    CHECK (status IN ('provisional','active','open','resolved','superseded','dismissed')),
  salience real NOT NULL DEFAULT 0.5,      -- 0..1 importance
  confidence real NOT NULL DEFAULT 0.7,    -- 0..1 extraction confidence
  sensitive boolean NOT NULL DEFAULT false,

  -- Provenance: every memory links back to the turn that created it.
  source_session_id uuid,                  -- chat_sessions.id (Phase C); nullable
  source_message_id uuid,                  -- chat_history.id
  source_quote text,                       -- verbatim user words

  -- Open-loop engine (state memories).
  follow_up_after timestamptz,             -- when the briefing may resurface it
  resolution_prompt text,                  -- "How's the back this morning?"
  follow_up_count integer NOT NULL DEFAULT 0,  -- times surfaced; auto-expire after N

  -- Lifecycle.
  superseded_by uuid REFERENCES public.coach_memory(id) ON DELETE SET NULL,
  expires_at timestamptz,                  -- nullable; decaying episodics
  last_referenced_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  -- Linkage to an authoritative structured row (avoids shadowing/dupes).
  linked_table text,                       -- e.g. 'injury_history'
  linked_id uuid
);

-- Retrieval hot path: active memories for a user, highest salience first.
CREATE INDEX IF NOT EXISTS idx_coach_memory_user_status_salience
  ON public.coach_memory (user_id, status, salience DESC);

CREATE INDEX IF NOT EXISTS idx_coach_memory_user_type
  ON public.coach_memory (user_id, memory_type);

-- Open-loop due check: which loops should the briefing resurface now.
CREATE INDEX IF NOT EXISTS idx_coach_memory_open_followup
  ON public.coach_memory (user_id, follow_up_after)
  WHERE status = 'open';

-- Provenance lookup (delete-by-message, dedupe by source).
CREATE INDEX IF NOT EXISTS idx_coach_memory_user_source_msg
  ON public.coach_memory (user_id, source_message_id)
  WHERE source_message_id IS NOT NULL;

-- Linked-row lookup (injury dedupe in the injector).
CREATE INDEX IF NOT EXISTS idx_coach_memory_linked
  ON public.coach_memory (user_id, linked_table, linked_id)
  WHERE linked_id IS NOT NULL;

COMMENT ON TABLE public.coach_memory IS
  'Persistent typed coach memory (semantic/episodic/state/derived). System of record; ChromaDB collection coach_memory mirrors embeddings for relevance retrieval. Added in 2217.';

-- ---------------------------------------------------------------------------
-- updated_at trigger (mirrors the app convention used elsewhere).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_coach_memory_updated_at()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_coach_memory_updated_at ON public.coach_memory;
CREATE TRIGGER trg_coach_memory_updated_at
  BEFORE UPDATE ON public.coach_memory
  FOR EACH ROW EXECUTE FUNCTION public.set_coach_memory_updated_at();

-- ---------------------------------------------------------------------------
-- RLS — mirror coach_daily_insights (2094): own-rows via users.auth_id join,
-- plus service-role full access for backend writes.
-- ---------------------------------------------------------------------------
ALTER TABLE public.coach_memory ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users view own coach_memory" ON public.coach_memory;
CREATE POLICY "Users view own coach_memory"
  ON public.coach_memory FOR SELECT
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Users update own coach_memory" ON public.coach_memory;
CREATE POLICY "Users update own coach_memory"
  ON public.coach_memory FOR UPDATE
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Users delete own coach_memory" ON public.coach_memory;
CREATE POLICY "Users delete own coach_memory"
  ON public.coach_memory FOR DELETE
  USING (user_id IN (SELECT id FROM public.users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS "Service role full access coach_memory" ON public.coach_memory;
CREATE POLICY "Service role full access coach_memory"
  ON public.coach_memory FOR ALL
  USING (auth.role() = 'service_role')
  WITH CHECK (auth.role() = 'service_role');

-- ---------------------------------------------------------------------------
-- Master memory toggle on the users row (privacy control).
-- Default true — extraction additionally requires chat-history consent.
-- ---------------------------------------------------------------------------
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS coach_memory_enabled boolean NOT NULL DEFAULT true;

COMMENT ON COLUMN public.users.coach_memory_enabled IS
  'User master switch for coach long-term memory (extraction + injection). Added in 2217.';

COMMIT;
