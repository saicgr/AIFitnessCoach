-- 1983_hydration_source.sql
--
-- Adds the `source` column to hydration_logs so each entry can be tagged with
-- where it was created from. Today's "Water 1000ml 19:58" row in the Fuel
-- tab gives no hint of context — was it a workout sip, a chat-agent log, or
-- a Home quick-add? This column drives a per-row icon + "via X" badge in the
-- UI and a small breakdown chart when ≥2 sources contributed in a day.
--
-- Allowed values:
--   'home'       — Home screen quick-add (water tile / hero action card)
--   'workout'    — During-workout hydration prompt or rest-timer log
--   'nutrition'  — Fuel/Water tab in the Nutrition section
--   'chat'       — AI coach (Gemini/MCP nutrition tool) logged on user's behalf
--   'manual'     — Generic / pre-feature default; legacy rows backfill to this
--   'unknown'    — Reserved bucket for forward-compat (new client surfaces
--                  not yet recognized by the server enum). Server-side code
--                  in `_normalize_hydration_source` downgrades unrecognized
--                  values here rather than 422'ing the request.

ALTER TABLE hydration_logs
    ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'manual'
        CHECK (source IN ('home', 'workout', 'nutrition', 'chat', 'manual', 'unknown'));

COMMENT ON COLUMN hydration_logs.source IS
    'Surface this hydration entry was created from. Drives the per-row icon + ''via X'' badge on the Fuel/Water tab and the source-breakdown chart. Defaults to ''manual'' for legacy rows.';

-- Composite index supports the per-source aggregation queries used by the
-- breakdown chart on the Fuel/Water tab.
CREATE INDEX IF NOT EXISTS ix_hydration_logs_user_source
    ON hydration_logs (user_id, source);
