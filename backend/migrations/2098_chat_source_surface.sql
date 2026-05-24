-- ============================================================================
-- Migration 2098 — chat_history.source_surface + insight_id
-- ============================================================================
-- Plan §1c.5 — when the user taps "Chat with coach" on the coach hero card
-- (or "Ask coach" on a workout-card glyph), the same Gemini insight that
-- the card showed is inserted at the top of today's chat session as a
-- normal coach turn. Persistence keys it by `insight_id` so a user opening
-- chat hours later still sees the original morning brief in the timeline.
--
-- `source_surface` identifies the surface that seeded the turn:
--   'coach_hero' | 'workout_card' | 'pillar_stat' | NULL (organic chat)
--
-- `insight_id` references coach_daily_insights.id when the row was seeded
-- from a daily-insight row. NULL otherwise.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS so re-applying is safe.
-- ============================================================================

ALTER TABLE public.chat_history
    ADD COLUMN IF NOT EXISTS source_surface TEXT,
    ADD COLUMN IF NOT EXISTS insight_id UUID
        REFERENCES public.coach_daily_insights(id) ON DELETE SET NULL;

-- Lookup index keyed by (user_id, insight_id) so the chat screen's
-- "already seeded today?" check is a one-row probe, not a table scan.
CREATE INDEX IF NOT EXISTS idx_chat_history_user_insight
    ON public.chat_history (user_id, insight_id)
    WHERE insight_id IS NOT NULL;

COMMENT ON COLUMN public.chat_history.source_surface IS
    'Which app surface (coach_hero / workout_card / pillar_stat) seeded this turn. NULL for organic chat. Added in 2098.';
COMMENT ON COLUMN public.chat_history.insight_id IS
    'When present, this turn was seeded from coach_daily_insights.id. Lets the client dedupe across reopen + invalidate card on edit. Added in 2098.';
