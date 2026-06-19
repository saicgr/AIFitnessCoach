-- Migration 2273: extend food_logs.source_type allowlist with 'chat'.
-- The coach-chat "recommended meal" card (mobile recommended_meal_card.dart)
-- logs via POST /nutrition/log-direct with source_type='chat', but the
-- food_logs_source_type_check (migrations 1960/2272) rejected it (23514),
-- surfacing as a 500 (PYTHON-FASTAPI-56 / log_food_direct). 'chat' is a
-- legitimate provenance worth preserving for analytics (vs. collapsing to
-- 'manual'), so widen the allowlist.
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
    'scheduled_log', 'meal_plan', 'chat'
  )) NOT VALID;

ALTER TABLE food_logs VALIDATE CONSTRAINT food_logs_source_type_check;
