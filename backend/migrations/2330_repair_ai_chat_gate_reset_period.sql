-- 2330 — repair the legacy `ai_chat` feature gate's NULL reset_period.
--
-- WHY
-- ---
-- `core/premium_gate.py::_get_current_usage` treats a NULL `reset_period` as
-- "sum all time usage". The legacy `ai_chat` row (seeded by 022_subscriptions)
-- has free_limit = 10 and reset_period = NULL, so while chat enforcement was
-- pointed at that key a free user got **10 coach messages for the lifetime of
-- their account** — not 10 per day. The in-app "messages left today" strip
-- meanwhile counted a different key entirely (`ai_chat_messages`, 20/day), so
-- the counter never moved and the wall arrived with a generic error.
--
-- Chat enforcement now uses `ai_chat_messages` (see CHAT_FEATURE_KEY in
-- backend/api/v1/chat.py), which is the canonical daily gate. This migration
-- defuses the stale row so that if anything is ever re-pointed at `ai_chat`
-- it imposes a DAILY limit rather than silently reinstating a lifetime cap.
--
-- Deliberately NOT deleting or disabling the row:
--   * deleting it would break any historical `feature_usage` rows keyed to it
--   * disabling it makes check_premium_gate raise 402 "currently disabled"
--     for any caller still passing the key, which is a worse failure mode
--     than simply having a correct daily window.

UPDATE feature_gates
SET reset_period = 'daily'
WHERE feature_key = 'ai_chat'
  AND reset_period IS NULL;

-- Confirm the canonical gate is intact and daily. Idempotent.
UPDATE feature_gates
SET reset_period = 'daily'
WHERE feature_key = 'ai_chat_messages'
  AND (reset_period IS NULL OR reset_period <> 'daily');
