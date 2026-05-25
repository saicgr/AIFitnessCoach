-- Migration 2104: Exercise Library i18n
-- Creates per-locale translation tables for exercise library entities.
--
-- Per-locale rows beyond 'en' must be populated externally
-- (translation provider TBD). DO NOT call Gemini/OpenAI for batch
-- translation per project policy.
--
-- Supported locales (36):
--   en, ar, bn, cs, de, es, fi, fr, ha, hi, id, it, ja, jv, kn, ko,
--   ml, mr, ms, ne, nl, or, pa, pl, pt, ru, sv, sw, ta, te, th, tl,
--   tr, ur, vi, zh
--
-- All statements are idempotent (CREATE TABLE IF NOT EXISTS / IF NOT EXISTS
-- for indexes). Run-safe to apply multiple times.
--
-- Seeding: backend/scripts/seed_exercise_library_i18n_en.py populates
-- the 'en' baseline. Other locales are a follow-up pass.


-- ============================================================================
-- Table 1: exercise_library_i18n
-- Per-locale name, instructions, and muscle labels for each exercise row.
-- exercise_id references exercise_library(id) — kept as TEXT to match the
-- UUID column type used by exercise_library.
-- ============================================================================

CREATE TABLE IF NOT EXISTS exercise_library_i18n (
    exercise_id         TEXT        NOT NULL,
    locale              TEXT        NOT NULL,
    name                TEXT,
    instructions        TEXT,
    primary_muscle_localized   TEXT,
    secondary_muscles_localized JSONB NOT NULL DEFAULT '[]'::jsonb,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (exercise_id, locale)
);

COMMENT ON TABLE exercise_library_i18n IS
    'Per-locale overrides for exercise_library text fields. '
    'Always has an en row (seeded by seed_exercise_library_i18n_en.py). '
    'Non-en rows must be populated externally — no LLM batch translation allowed.';

COMMENT ON COLUMN exercise_library_i18n.exercise_id IS
    'FK to exercise_library.id (TEXT/UUID). Not a hard FK to preserve resilience '
    'if an exercise row is deleted.';

CREATE INDEX IF NOT EXISTS idx_exercise_library_i18n_locale
    ON exercise_library_i18n (locale);

CREATE INDEX IF NOT EXISTS idx_exercise_library_i18n_exercise_id
    ON exercise_library_i18n (exercise_id);


-- ============================================================================
-- Table 2: equipment_types_i18n
-- Per-locale display name and aliases array for equipment taxonomy rows.
-- equipment_type_id is the UUID PK from equipment_types.
-- ============================================================================

CREATE TABLE IF NOT EXISTS equipment_types_i18n (
    equipment_type_id   UUID        NOT NULL,
    locale              TEXT        NOT NULL,
    display_name        TEXT        NOT NULL,
    aliases             JSONB       NOT NULL DEFAULT '[]'::jsonb,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (equipment_type_id, locale)
);

COMMENT ON TABLE equipment_types_i18n IS
    'Per-locale display labels for equipment_types rows. '
    'equipment_type_id soft-references equipment_types.id.';

CREATE INDEX IF NOT EXISTS idx_equipment_types_i18n_locale
    ON equipment_types_i18n (locale);


-- ============================================================================
-- Table 3: muscle_group_i18n
-- Canonical muscle group codes (e.g. 'chest', 'quads') with per-locale
-- display names. Source codes are derived from exercise_library.target_muscle
-- and exercise_library.body_part distinct values.
-- ============================================================================

CREATE TABLE IF NOT EXISTS muscle_group_i18n (
    muscle_group_code   TEXT        NOT NULL,
    locale              TEXT        NOT NULL,
    display_name        TEXT        NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (muscle_group_code, locale)
);

COMMENT ON TABLE muscle_group_i18n IS
    'Per-locale display names for canonical muscle group codes. '
    'Codes are the normalised lowercase values from exercise_library.target_muscle '
    'and exercise_library.body_part (seeded by seed_exercise_library_i18n_en.py).';

CREATE INDEX IF NOT EXISTS idx_muscle_group_i18n_locale
    ON muscle_group_i18n (locale);


-- ============================================================================
-- Table 4: movement_pattern_i18n
-- Canonical movement pattern codes with per-locale display names.
-- Source codes are derived from exercise_library.category distinct values.
-- ============================================================================

CREATE TABLE IF NOT EXISTS movement_pattern_i18n (
    pattern_code        TEXT        NOT NULL,
    locale              TEXT        NOT NULL,
    display_name        TEXT        NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (pattern_code, locale)
);

COMMENT ON TABLE movement_pattern_i18n IS
    'Per-locale display names for movement pattern codes, e.g. push/pull/hinge. '
    'Codes derived from exercise_library.category distinct values.';

CREATE INDEX IF NOT EXISTS idx_movement_pattern_i18n_locale
    ON movement_pattern_i18n (locale);


-- ============================================================================
-- Table 5: set_type_i18n
-- Per-locale labels for set type codes (warmup, working, drop, failure, amrap).
-- ============================================================================

CREATE TABLE IF NOT EXISTS set_type_i18n (
    set_type_code       TEXT        NOT NULL,
    locale              TEXT        NOT NULL,
    display_name        TEXT        NOT NULL,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (set_type_code, locale)
);

COMMENT ON TABLE set_type_i18n IS
    'Per-locale labels for set types (warmup / working / drop / failure / amrap). '
    'Codes are the canonical values enforced by the workout generation schema.';

CREATE INDEX IF NOT EXISTS idx_set_type_i18n_locale
    ON set_type_i18n (locale);


-- ============================================================================
-- Seed: set_type en rows (these are fully enumerable, no external lookup needed)
-- ============================================================================

INSERT INTO set_type_i18n (set_type_code, locale, display_name) VALUES
    ('warmup',   'en', 'Warm-up'),
    ('working',  'en', 'Working'),
    ('drop',     'en', 'Drop Set'),
    ('failure',  'en', 'To Failure'),
    ('amrap',    'en', 'AMRAP')
ON CONFLICT (set_type_code, locale) DO NOTHING;
