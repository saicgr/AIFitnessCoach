-- Migration 2319: bill/receipt scanning + menu source hint
--
-- Menu scan gains two things this migration has to make room for:
--
--   1. BILL MODE — scan the itemized check at the end of the meal, or a
--      delivery-app order (DoorDash / Uber Eats), and tick off what YOU ate.
--      Bill-logged rows write input_type='bill_scan', which the existing
--      food_logs_input_type_check (1960) rejects, and saved bills need
--      menu_analyses.analysis_type='bill', which its CHECK also rejects.
--
--   2. SOURCE HINT — where a scanned menu came from. A printed menu, a backlit
--      menu BOARD and a DoorDash screenshot fail in completely different ways
--      (no descriptions / glare / app chrome), so the scan prompt branches on
--      this. Persisting it means a re-scan of a saved menu re-uses the same
--      branch instead of guessing again.
--
-- Rollback:
--   ALTER TABLE menu_analyses DROP COLUMN IF EXISTS source_hint;
--   (and restore the two CHECK constraints to their pre-2319 value lists)

-- ============================================================
-- 1. food_logs.input_type — allow 'bill_scan'
-- ============================================================

ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_input_type_check;
ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_input_type_check
  CHECK (input_type IN (
    'text', 'voice', 'camera', 'gallery', 'barcode',
    'menu_scan', 'buffet_scan', 'bill_scan', 'multi_image_scan',
    'chat', 'ai_suggestion', 'manual', 'image', 'copy', 'watch'
  )) NOT VALID;
ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_input_type_check;

COMMENT ON COLUMN food_logs.input_type IS
  'Specific input method: text | voice | camera | gallery | barcode | menu_scan | buffet_scan | bill_scan | multi_image_scan | chat | ai_suggestion | manual | image | copy | watch. Enforced by food_logs_input_type_check.';

-- ============================================================
-- 2. menu_analyses — allow 'bill' + record the source
-- ============================================================

ALTER TABLE menu_analyses DROP CONSTRAINT IF EXISTS menu_analyses_analysis_type_check;
ALTER TABLE menu_analyses
  ADD CONSTRAINT menu_analyses_analysis_type_check
  CHECK (analysis_type IN ('plate', 'menu', 'buffet', 'bill'));

ALTER TABLE menu_analyses
  ADD COLUMN IF NOT EXISTS source_hint TEXT
  CHECK (source_hint IS NULL OR source_hint IN ('printed', 'board', 'digital'));

COMMENT ON COLUMN menu_analyses.source_hint IS
  'Surface the menu was captured from: printed (paper menu) | board (overhead / drive-thru / TV display) | digital (QR menu, PDF, restaurant site, delivery-app screenshot). Selects the OCR prompt preamble; NULL on rows saved before 2319 (treated as printed).';
