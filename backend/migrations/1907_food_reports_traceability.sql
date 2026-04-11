-- Add traceability columns to food_reports for debugging bad analyses
-- Captures the original query, full analysis response, report type, and all food items

ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS report_type TEXT DEFAULT 'wrong_nutrition'
    CHECK (report_type IN ('wrong_nutrition', 'wrong_food', 'other'));

ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS original_query TEXT;

ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS analysis_response JSONB;

ALTER TABLE food_reports ADD COLUMN IF NOT EXISTS all_food_items JSONB;

-- Index on report_type for filtering
CREATE INDEX IF NOT EXISTS idx_food_reports_report_type
    ON food_reports(report_type);

COMMENT ON COLUMN food_reports.report_type IS 'Type of report: wrong_nutrition (bad macros), wrong_food (misidentified food), other';
COMMENT ON COLUMN food_reports.original_query IS 'Original text the user typed (e.g., "mexican coke chipotle")';
COMMENT ON COLUMN food_reports.analysis_response IS 'Full Gemini/cache response JSON for tracing what was returned';
COMMENT ON COLUMN food_reports.all_food_items IS 'All food items returned by the analysis (not just the one being reported)';
