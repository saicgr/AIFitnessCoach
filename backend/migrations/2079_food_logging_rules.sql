-- Migration 2079: L3 "It remembers you" — standing food-logging rules.
--
-- Why: MacroFactor's analysis instructions are per-log only. Zealova lets a
-- user define STANDING rules ("no bun", "I always use 0-cal sweetener", "we
-- cook low-oil South Indian", "skim milk not whole") that are auto-fed into
-- EVERY future food photo + text analysis without re-typing.
--
-- Storage: a JSONB array column on `nutrition_preferences` — the lowest-friction
-- option (no new table, no extra join on the hot food-analysis path; the row
-- is already fetched for daily targets). Each element:
--   {
--     "id":         "<uuid>",       -- stable id for edit/delete
--     "text":       "no bun",       -- the rule, user-authored free text
--     "created_at": "<iso8601>",
--     "enabled":    true            -- soft-disable without deleting (C9 stale-rule review)
--   }
--
-- C9 edge cases this column supports:
--   * Per-log override   — a per-log instruction is passed alongside and the
--     prompt is told the instruction wins for THIS log (handled in prompts).
--   * Conflicting rules  — surfaced by the backend rules service / settings UI;
--     the array keeps every rule so a conflict pair stays visible to resolve.
--   * Stale rule         — `enabled=false` soft-disables; rules are fully
--     reviewable/editable from the settings screen.
--   * Per-user           — column is on nutrition_preferences which is keyed by
--     user_id, so rules never cross-apply on a shared device.

ALTER TABLE nutrition_preferences
  ADD COLUMN IF NOT EXISTS food_logging_rules JSONB NOT NULL DEFAULT '[]'::jsonb;

COMMENT ON COLUMN nutrition_preferences.food_logging_rules IS
  'L3 standing food-logging rules: JSONB array of {id,text,created_at,enabled}. Auto-injected into every food photo + text analysis prompt. Per-log instructions override these.';
