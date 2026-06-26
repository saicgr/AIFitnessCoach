-- Migration 2289: Add variant_base_id + default_variant_id columns to programs
--
-- Adds two nullable FK columns to `programs`:
--   variant_base_id       → branded_programs.id   (the dedicated generated variant base for this program)
--   default_variant_id    → program_variants.id    (the pre-selected variant shown on the detail screen)
--
-- ── How linking works (NOT done here — done at runtime by a script) ──────────
--
-- Per-program variant generation and column back-fill is performed by:
--   backend/scripts/generate_curated_variants.py
--
-- That script:
--   1. For each curated program, generates a dedicated branded_programs base
--      named "<editorial_name> (Zealova Library)" with is_active=false (so it
--      never surfaces in any branded-facing UI).
--   2. Generates program_variants + program_variant_weeks for each
--      (duration_weeks × sessions_per_week) combo in the matrix
--      {1,2,4,8,12,intended_weeks} × {3,4,5,intended_sessions} using
--      gemini-3.1-flash-lite.
--   3. Sets programs.variant_base_id = <generated base id> and
--      programs.default_variant_id = <closest variant to intended weeks/sessions>.
--
-- Each curated program therefore owns its OWN generated variant library — not
-- a borrowed unrelated branded base (Reddit PPL, PHUL, etc.). The base UUIDs
-- are runtime-created and cannot be hardcoded here.
--
-- Fixed programs that stay NULL (no variants generated):
--   73d9ec23-5845-498f-8015-e961e141cec5  HYROX Full Simulation (race-day sim)
--   6e9539c2-feef-497d-9d0b-8c499838d2f8  30-Day Plank Challenge
--
-- ── Step 1: Add columns (idempotent — safe to re-run) ────────────────────────

ALTER TABLE programs
  ADD COLUMN IF NOT EXISTS variant_base_id UUID
    REFERENCES branded_programs(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS default_variant_id UUID
    REFERENCES program_variants(id) ON DELETE SET NULL;

-- ── Step 2: No UPDATE block ───────────────────────────────────────────────────
--
-- The variant_base_id / default_variant_id values are set at runtime by
-- generate_curated_variants.py (see above). Do NOT add static UPDATE statements
-- here — the generated base UUIDs differ per environment and would be wrong.
