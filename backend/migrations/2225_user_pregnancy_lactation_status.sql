-- Migration 2225: Pregnancy / lactation status on users.
-- Read by get_micronutrient_gaps (nutrition coach tool) to pick the correct
-- RDA target — pregnancy/lactation raise needs for folate, iron, iodine, etc.
-- Applied to the live DB 2026-06-01 via Supabase MCP.

ALTER TABLE users ADD COLUMN IF NOT EXISTS is_pregnant BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS is_lactating BOOLEAN NOT NULL DEFAULT FALSE;

COMMENT ON COLUMN users.is_pregnant IS 'User self-reported pregnant — raises micronutrient RDA targets (folate/iron/iodine/etc.).';
COMMENT ON COLUMN users.is_lactating IS 'User self-reported breastfeeding — raises micronutrient RDA targets.';
