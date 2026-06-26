-- 2286_program_phases.sql
-- Authored phase blocks for the redesigned full-screen Program Detail page
-- (Overview tab): e.g. Foundation / Build / Peak & taper with week ranges.
-- Array of {index, title, subtitle, week_start, week_end}. Null = derive client-side.
-- Applied to prod via Supabase MCP on 2026-06-25; idempotent for repo parity.
ALTER TABLE programs ADD COLUMN IF NOT EXISTS phases jsonb;
