-- Migration 1960: normalize food_logs source_type + input_type
--
-- Purpose
-- --------
-- `input_type` (added in 1959) has been sitting in the schema unused by every
-- phone write path — only the watch path populated it, and it did so in
-- uppercase ("VOICE" / "MANUAL"). This migration:
--   1. Widens both columns to VARCHAR(30) so new values like
--      'multi_image_scan' fit.
--   2. Normalizes any existing uppercase input_type rows to lowercase so
--      they match the new CHECK allowlist.
--   3. Backfills input_type on historic rows from source_type so analytics
--      aren't NULL-heavy from day one.
--   4. Adds CHECK constraints (NOT VALID then VALIDATE) that enforce a
--      lowercase allowlist going forward — prevents typos and future drift.
--   5. Creates idx_food_logs_input_type for queries filtering by input
--      method.
--
-- Rollback
-- --------
--   ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_source_type_check;
--   ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_input_type_check;
--   DROP INDEX IF EXISTS idx_food_logs_input_type;
--   -- (Column widening and backfilled rows are safe to leave in place.)

-- 1. Widen both columns (multi_image_scan = 16 chars, etc.).
ALTER TABLE food_logs ALTER COLUMN source_type TYPE VARCHAR(30);
ALTER TABLE food_logs ALTER COLUMN input_type  TYPE VARCHAR(30);

-- 2. Normalize pre-existing watch rows ("VOICE" / "MANUAL") to lowercase.
UPDATE food_logs
   SET input_type = LOWER(input_type)
 WHERE input_type IS NOT NULL
   AND input_type <> LOWER(input_type);

-- 3a. Remap any historic source_type values that fall outside the new
-- allowlist. The chat agent used to write source_type='chat' directly (this
-- code path now writes source_type='text', input_type='chat'). Rewriting
-- the old rows to match the new convention keeps the CHECK constraint
-- happy and preserves the chat-origin signal in input_type.
UPDATE food_logs
   SET input_type = COALESCE(input_type, 'chat'),
       source_type = 'text'
 WHERE source_type = 'chat';

-- 3b. Backfill input_type from source_type where NULL. Keeps mapping
-- conservative — we pick the most likely method, not a fabricated guess.
UPDATE food_logs SET input_type = CASE
  WHEN source_type = 'image'      THEN 'image'
  WHEN source_type = 'text'       THEN 'text'
  WHEN source_type = 'barcode'    THEN 'barcode'
  WHEN source_type = 'restaurant' THEN 'manual'
  WHEN source_type = 'menu'       THEN 'menu_scan'
  WHEN source_type = 'buffet'     THEN 'buffet_scan'
  WHEN source_type = 'watch'      THEN 'voice'
  WHEN source_type = 'history'    THEN 'copy'
  ELSE 'text'
END
WHERE input_type IS NULL;

-- 4a. CHECK on source_type. NOT VALID + VALIDATE avoids a blocking full
-- table scan on the live DB. If VALIDATE fails, some historic row has a
-- value outside the allowlist — audit with
--   SELECT DISTINCT source_type FROM food_logs;
-- and extend the allowlist or the UPDATE above before re-running.
ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_source_type_check
  CHECK (source_type IN (
    'text', 'image', 'barcode', 'restaurant',
    'menu', 'buffet', 'watch', 'history', 'manual'
  )) NOT VALID;
ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_source_type_check;

-- 4b. CHECK on input_type — the richer, method-specific column.
ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_input_type_check
  CHECK (input_type IN (
    'text', 'voice', 'camera', 'gallery', 'barcode',
    'menu_scan', 'buffet_scan', 'multi_image_scan',
    'chat', 'ai_suggestion', 'manual', 'image', 'copy', 'watch'
  )) NOT VALID;
ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_input_type_check;

-- 5. Index for analytics ("how many logs came from voice this week?").
CREATE INDEX IF NOT EXISTS idx_food_logs_input_type ON food_logs(input_type);

COMMENT ON COLUMN food_logs.source_type IS
  'Broad category bucket: text | image | barcode | restaurant | menu | buffet | watch | history | manual. Enforced by food_logs_source_type_check.';
COMMENT ON COLUMN food_logs.input_type IS
  'Specific input method: text | voice | camera | gallery | barcode | menu_scan | buffet_scan | multi_image_scan | chat | ai_suggestion | manual | image | copy | watch. Enforced by food_logs_input_type_check.';
