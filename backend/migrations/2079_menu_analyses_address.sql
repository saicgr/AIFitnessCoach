-- Migration: Menu Analyses — restaurant address
-- Created: 2026-05-16
-- Description: Leapfrog phase L5 — adds an optional free-text restaurant
--              address to saved menu analyses. Plain text, any country /
--              any format; no geocoding, no format enforcement. Powers the
--              richer Saved Menus cards (photo + name + address) and sets
--              up a future "directions / pre-arrival recommendations" flow.

ALTER TABLE menu_analyses
    ADD COLUMN IF NOT EXISTS address TEXT;

COMMENT ON COLUMN menu_analyses.address IS
    'Optional free-text restaurant address (any country / any format). '
    'Not geocoded. Used for the Saved Menus card subtitle + near-duplicate '
    '(name+address) detection when saving.';
