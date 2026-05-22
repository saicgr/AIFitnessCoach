-- Migration 2092: Cycle research-data consent toggle
--
-- Phase H of the cycle-tracking feature. Adds a single opt-in consent
-- column so a user can choose to contribute anonymised menstrual-cycle
-- data to women's-health research.
--
-- Why this is a dedicated column (not folded into health_data_consent):
--   * health_data_consent (migration 1962) is GDPR Art. 9 consent for
--     *processing* the user's own health data inside Zealova (HealthKit /
--     Health Connect sync, AI personalization). It is about the user's own
--     experience.
--   * cycle_research_consent is a *separate, narrower* opt-in for an
--     entirely different purpose: letting anonymised cycle data leave the
--     user's account for aggregate research. Bundling a research-donation
--     consent inside a service-enablement consent is exactly the GDPR
--     Art. 7(4) dark-pattern the consent_guard module exists to prevent —
--     so it gets its own column with its own audit timestamp.
--
-- Default FALSE: cycle data is NEVER used for research/sharing unless the
-- user explicitly opts in. Server-enforced — see services/consent_guard.py
-- (has_cycle_research_consent / require_cycle_research_consent).
--
-- The matching read-side flag for in-app phase-aware nutrition adjustment
-- (hormonal_profiles.cycle_sync_nutrition) already exists from migration
-- 121, so this migration only adds the research-export consent.
--
-- Idempotent: ADD COLUMN IF NOT EXISTS everywhere. Safe to re-run.

BEGIN;

-- ---------------------------------------------------------------------------
-- cycle_research_consent — opt-in research-data donation toggle
-- ---------------------------------------------------------------------------
ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS cycle_research_consent boolean NOT NULL DEFAULT false;

-- Record when the user granted (or last affirmed) research consent so the
-- opt-in timing is provable for audit / DSAR responses. NULL until the user
-- explicitly opts in. Mirrors the ai_data_processing_consented_at /
-- health_data_consented_at pattern from migration 1962.
ALTER TABLE public.user_ai_settings
    ADD COLUMN IF NOT EXISTS cycle_research_consented_at timestamptz;

COMMENT ON COLUMN public.user_ai_settings.cycle_research_consent IS
    'Opt-in consent to contribute anonymised menstrual-cycle data to women''s-health research. Default FALSE — server-enforced in consent_guard.py; when FALSE cycle data must not leave the backend for any research/sharing path. Separate from health_data_consent, which governs in-app processing of the user''s own health data.';

COMMENT ON COLUMN public.user_ai_settings.cycle_research_consented_at IS
    'Timestamp the user last affirmatively enabled cycle_research_consent. NULL until first opt-in; stamped server-side so it cannot be forged.';

COMMIT;
