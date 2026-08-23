-- Migration 2411: restore importer provenance values on food_logs.input_type
--
-- Migration 2295 documented that the nutrition importer (Part A) stores its
-- provenance app in food_logs.input_type: 'myfitnesspal' | 'macrofactor' |
-- 'cronometer' | 'apple_health' (see services/nutrition_import/transform.py
-- group_food_logs, which sets input_type=<source>). Migration 2319 (bill scan)
-- later rewrote food_logs_input_type_check wholesale and dropped those four
-- values, so every CSV/Apple Health import commit has 500ed with
-- "new row for relation food_logs violates check constraint
-- food_logs_input_type_check" (23514) ever since — 0 rows land, no matter how
-- valid the export is.
--
-- Additive only. NOT VALID + VALIDATE avoids a blocking full-table scan on the
-- live food_logs table.

ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_input_type_check;
ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_input_type_check
  CHECK (input_type IN (
    'text', 'voice', 'camera', 'gallery', 'barcode',
    'menu_scan', 'buffet_scan', 'bill_scan', 'multi_image_scan',
    'chat', 'ai_suggestion', 'manual', 'image', 'copy', 'watch',
    'myfitnesspal', 'macrofactor', 'cronometer', 'apple_health'
  )) NOT VALID;
ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_input_type_check;

COMMENT ON COLUMN food_logs.input_type IS
  'Specific input method: text | voice | camera | gallery | barcode | menu_scan | buffet_scan | bill_scan | multi_image_scan | chat | ai_suggestion | manual | image | copy | watch, or importer provenance myfitnesspal | macrofactor | cronometer | apple_health. Enforced by food_logs_input_type_check.';
