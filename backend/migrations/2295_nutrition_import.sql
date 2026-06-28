-- Migration 2295: nutrition importer (Part A).
--
-- Adds 'import' to the food_logs.source_type allowlist (historical logs brought
-- in from MyFitnessPal / MacroFactor / Cronometer / Apple Health) and creates
-- the `nutrition_import_jobs` table that backs the async preview→commit flow
-- (POST /nutrition/import → GET status → POST commit). Provenance app is stored
-- in food_logs.input_type ('myfitnesspal'|'macrofactor'|'cronometer'|'apple_health').
--
-- Additive only. NOT VALID + VALIDATE avoids a blocking full-table scan on the
-- live food_logs table.

-- 1) Widen source_type allowlist with 'import'.
ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_source_type_check
  CHECK (source_type IN (
    'text', 'image', 'barcode', 'restaurant',
    'menu', 'buffet', 'watch', 'history', 'manual',
    'scheduled_log', 'meal_plan', 'chat', 'import'
  )) NOT VALID;

ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_source_type_check;

-- 2) Import job table — backs the async dry-run preview + commit.
--    `parsed_rows` holds the normalized rows between preview and commit (the raw
--    uploaded CSV is parsed in-memory and never persisted — PII). Capped client
--    side; large imports are chunked on commit.
CREATE TABLE IF NOT EXISTS nutrition_import_jobs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source VARCHAR(30) NOT NULL,            -- myfitnesspal|macrofactor|cronometer|apple_health|auto
    status VARCHAR(20) NOT NULL DEFAULT 'parsing',
        -- parsing | preview_ready | committing | done | error
    preview JSONB,                          -- {count,date_range,days,sample_rows,unmapped_columns,overlap_days,weight_rows,unreadable_rows}
    parsed_rows JSONB,                       -- normalized food rows awaiting commit
    parsed_weight JSONB,                     -- normalized weight rows awaiting commit
    result JSONB,                            -- {imported,skipped,replaced,weight_imported,failed}
    error TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_nutrition_import_jobs_user
    ON nutrition_import_jobs (user_id, created_at DESC);

COMMENT ON TABLE nutrition_import_jobs IS
    'Async nutrition import jobs (Part A importer). parsed_rows/parsed_weight hold normalized data between dry-run preview and commit; raw CSVs are never persisted.';
