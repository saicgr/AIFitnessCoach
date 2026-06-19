-- Migration 2272: extend food_logs.source_type allowlist with the two
-- internal provenances that were silently 500-ing into swallowed excepts:
--   'scheduled_log' (jobs/scheduled_meal_logs_worker.py:373)
--   'meal_plan'     (services/meal_plan_service.py:545)
-- Both insert directly into food_logs (bypassing core/db create_food_log), so
-- the food_logs_source_type_check from migration 1960 rejected them (23514) and
-- the callers' except blocks swallowed the failure — scheduled meal logs and
-- meal-plan logs never persisted. Extending the allowlist preserves the
-- distinct provenance for analytics (vs. collapsing to 'history').
--
-- Additive only (widens the IN list) so VALIDATE cannot fail on existing rows.
-- NOT VALID + VALIDATE avoids a blocking full-table scan on the live DB.
-- Applied to prod (project hpbzfahijszqmgsybuor) via Supabase MCP 2026-06-19.
ALTER TABLE food_logs DROP CONSTRAINT IF EXISTS food_logs_source_type_check;

ALTER TABLE food_logs
  ADD CONSTRAINT food_logs_source_type_check
  CHECK (source_type IN (
    'text', 'image', 'barcode', 'restaurant',
    'menu', 'buffet', 'watch', 'history', 'manual',
    'scheduled_log', 'meal_plan'
  )) NOT VALID;

ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_source_type_check;
