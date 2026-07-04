-- Migration 2309: habits.sort_order — the reorder endpoint
-- (habits_endpoints.py /reorder) has always written this column per habit,
-- but it never existed, so user drag-reordering never persisted (42703,
-- swallowed). Column-drift sweep 2026-07-04 (see 2306-2308).

BEGIN;

ALTER TABLE habits ADD COLUMN IF NOT EXISTS sort_order INT;

COMMIT;
