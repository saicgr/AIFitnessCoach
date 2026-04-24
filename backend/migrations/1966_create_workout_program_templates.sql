-- Migration: 1966_create_workout_program_templates.sql
-- Description: Store imported *blank templates* from creator programs (Jeff Nippard,
-- Renaissance Periodization, Greg Nuckols, Wendler 5/3/1, nSuns, GZCLP, Starting
-- Strength, StrongLifts, Metallicadpa PPL, Lyle McDonald, BWS, BUFF Dudes, etc.).
--
-- A template is NOT history — it is a prescription the user is following. When the
-- workout generator runs, it reads the active template and resolves %1RM / %TM
-- against the user's CURRENT 1RM (from get_user_strength_history), then rounds to
-- rounding_multiple_kg. A user may also have filled-in history cells in the same
-- spreadsheet — those are split off and land in workout_history_imports separately.

CREATE TABLE IF NOT EXISTS workout_program_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,

    -- Identity.
    source_app TEXT NOT NULL,                 -- 'nippard_powerbuilding_v3' | 'rp_male_physique_20' | 'wendler_531_bbb' | ...
    program_name TEXT NOT NULL,
    program_creator TEXT,
    program_version TEXT,                     -- e.g. "v3.2" when the creator publishes versions
    total_weeks INTEGER CHECK (total_weeks IS NULL OR total_weeks > 0),
    days_per_week INTEGER CHECK (days_per_week IS NULL OR (days_per_week BETWEEN 1 AND 7)),

    -- User inputs captured at import time. These are snapshots — the
    -- template player re-resolves against the user's LIVE 1RM at run time.
    unit_hint TEXT NOT NULL
      CHECK (unit_hint IN ('kg', 'lb')),
    one_rm_inputs JSONB,                      -- {"squat_kg": 140, "bench_kg": 100, ...}
    body_weight_kg NUMERIC(6, 2),
    rounding_multiple_kg NUMERIC(4, 2) DEFAULT 2.5 CHECK (rounding_multiple_kg > 0),
    training_max_factor NUMERIC(3, 2) DEFAULT 1.0 CHECK (training_max_factor > 0 AND training_max_factor <= 1.0),
      -- Wendler 5/3/1 convention: TM = 0.9 × true 1RM. Other programs use 1.0.

    -- The actual prescription — full normalized tree with weeks → days → exercises → sets.
    raw_prescription JSONB NOT NULL,

    notes TEXT,
    import_job_id UUID,
    source_file_s3_key TEXT,                  -- original file retained for re-parse if resolver improves

    -- Activation state (only one active program per user at a time is enforced in app layer).
    active BOOLEAN NOT NULL DEFAULT false,
    current_week INTEGER DEFAULT 1 CHECK (current_week >= 1),
    current_day INTEGER DEFAULT 1 CHECK (current_day >= 1),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    paused_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_templates_user_active
  ON workout_program_templates (user_id, active);

CREATE INDEX IF NOT EXISTS idx_templates_user_source
  ON workout_program_templates (user_id, source_app);

CREATE INDEX IF NOT EXISTS idx_templates_job
  ON workout_program_templates (import_job_id)
  WHERE import_job_id IS NOT NULL;

-- Partial unique index: at most one active program per user.
CREATE UNIQUE INDEX IF NOT EXISTS uq_templates_one_active_per_user
  ON workout_program_templates (user_id)
  WHERE active = true;

ALTER TABLE workout_program_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own templates"
  ON workout_program_templates FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users insert own templates"
  ON workout_program_templates FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own templates"
  ON workout_program_templates FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users delete own templates"
  ON workout_program_templates FOR DELETE
  USING (auth.uid() = user_id);

CREATE POLICY "Service role full access templates"
  ON workout_program_templates FOR ALL
  USING (auth.role() = 'service_role');

CREATE OR REPLACE FUNCTION update_workout_program_templates_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_workout_program_templates_updated_at
  ON workout_program_templates;
CREATE TRIGGER trigger_update_workout_program_templates_updated_at
    BEFORE UPDATE ON workout_program_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_workout_program_templates_updated_at();

COMMENT ON TABLE workout_program_templates IS
  'Imported creator programs (Nippard, RP, Wendler, nSuns, etc.). Drives workout generation when active=true.';
COMMENT ON COLUMN workout_program_templates.raw_prescription IS
  'weeks -> days -> exercises -> sets. Schema: CanonicalProgramTemplate in workout_import.canonical.';
COMMENT ON COLUMN workout_program_templates.training_max_factor IS
  'Wendler 5/3/1 uses 0.9 (TM = 0.9 × 1RM). Others use 1.0.';
