-- 2389 — repair double-encoded chat_history.context_json
--
-- ROOT CAUSE (fixed in the same change): api/v1/chat.py `_save_chat_to_db`
-- wrote `json.dumps(context_dict)` into the JSONB column `context_json`, so
-- every coach turn persisted as a jsonb *string* (a double-encoded scalar)
-- instead of a jsonb object. Effects:
--   * the client's `contextJson is Map` test failed, so reopening a saved
--     conversation lost every action card, chart block and agent identity
--     (E2E register row 36);
--   * every jsonb operator silently misses on those rows — e.g.
--     `.eq("context_json->>proactive", "true")` in api/v1/home/bootstrap.py:398
--     and api/v1/admin/observability.py:177 can never match a chat.py-written
--     row.
-- The other writer (api/v1/push_nudge_cron.py `_mirror_proactive_to_chat`)
-- always passed a dict, which is why exactly the chat.py rows are strings.
--
-- This migration re-parses the legacy string rows in place. Every affected row
-- was written by json.dumps(dict), so the inner text is always a JSON object —
-- verified on production before writing this file:
--   select count(*) filter (where (context_json #>> '{}') ~ '^\s*\{.*\}\s*$')
--     from chat_history where jsonb_typeof(context_json) = 'string';
--   -> 37 of 37
-- The WHERE clause re-checks that shape anyway, so a row that is a bare string
-- for some other reason is left untouched rather than corrupted.
--
-- SAFETY: chat_history is small (51 rows) and the UPDATE is a short row-level
-- lock, no table rewrite, no ACCESS EXCLUSIVE. The pre-image of every touched
-- row is copied to chat_history_context_json_backup_2389 first (logged-data
-- durability), so the repair is reversible with the rollback statement at the
-- bottom.

BEGIN;

-- 1. Back up the pre-image of every row we are about to rewrite.
CREATE TABLE IF NOT EXISTS chat_history_context_json_backup_2389 (
    id             uuid PRIMARY KEY,
    context_json   jsonb,
    backed_up_at   timestamptz NOT NULL DEFAULT now()
);

INSERT INTO chat_history_context_json_backup_2389 (id, context_json)
SELECT id, context_json
FROM chat_history
WHERE jsonb_typeof(context_json) = 'string'
  AND (context_json #>> '{}') ~ '^\s*\{.*\}\s*$'
ON CONFLICT (id) DO NOTHING;

-- 2. Re-parse the double-encoded payload into a real jsonb object.
UPDATE chat_history
SET context_json = (context_json #>> '{}')::jsonb
WHERE jsonb_typeof(context_json) = 'string'
  AND (context_json #>> '{}') ~ '^\s*\{.*\}\s*$';

COMMIT;

-- VERIFY (expect: object only, no 'string' bucket left):
--   select jsonb_typeof(context_json), count(*) from chat_history group by 1;
--   select count(*) from chat_history where context_json ? 'action_data';
--
-- ROLLBACK (restores the exact pre-image):
--   UPDATE chat_history c
--   SET context_json = b.context_json
--   FROM chat_history_context_json_backup_2389 b
--   WHERE c.id = b.id;
