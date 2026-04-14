-- Migration 1914: Add user_query column to food_logs
-- Captures the user's originating input (search query, chat message, photo caption,
-- scanned product name, or selected dish label) at log time, so the Daily tab's
-- multi-item group header can title each log with what the user actually searched.
--
-- Nullable column, no backfill. Legacy rows remain null and fall through to
-- ai_feedback / "N items" in the frontend title resolution chain.

ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS user_query TEXT;

-- Optional GIN index for future full-text search over user_query; only created
-- when the column is non-null to keep it small.
CREATE INDEX IF NOT EXISTS idx_food_logs_user_query_tsv
    ON food_logs USING gin (to_tsvector('english', user_query))
    WHERE user_query IS NOT NULL;
