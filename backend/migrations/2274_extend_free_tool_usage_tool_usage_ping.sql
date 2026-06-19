-- Migration 2274: extend free_tool_usage.tool allowlist with 'usage-ping'.
-- POST /api/v1/free-tools/usage/{slug} (free_tools.py:increment_usage) throttles
-- the social-proof usage counter by inserting a free_tool_usage row with the
-- synthetic tool key 'usage-ping'. The free_tool_usage_tool_chk constraint only
-- listed the four real tools, so every throttle insert raised 23514
-- (PYTHON-FASTAPI-55 / increment_usage). 'usage-ping' is an internal throttle
-- bucket (not a user-facing tool), so widen the allowlist to permit it.
--
-- Additive only (widens the IN list) so VALIDATE cannot fail on existing rows.
-- Applied to prod (project hpbzfahijszqmgsybuor) via Supabase MCP 2026-06-19.
ALTER TABLE free_tool_usage DROP CONSTRAINT IF EXISTS free_tool_usage_tool_chk;

ALTER TABLE free_tool_usage
  ADD CONSTRAINT free_tool_usage_tool_chk
  CHECK (tool = ANY (ARRAY[
    'ai-food-photo'::text,
    'ai-workout-generator'::text,
    'ai-roast-routine'::text,
    'email-signup'::text,
    'usage-ping'::text
  ])) NOT VALID;

ALTER TABLE free_tool_usage VALIDATE CONSTRAINT free_tool_usage_tool_chk;
