-- Migration 2296: nutrition_preferences.auto_adjust_weekly — opt-in flag for the
-- weekly adaptive-target auto-apply job.
--
-- Context: the adaptive TDEE engine (services/adaptive_tdee_service.py) already
-- computes an energy-balance TDEE from 14d intake + weight trend, and
-- /nutrition/recommendations surfaces a recommended new calorie target. Until
-- now that recommendation was NEVER written back to
-- nutrition_preferences.target_calories without an explicit user tap.
--
-- This flag lets a user opt in to "keep my targets in sync with my trend
-- automatically": when true, the weekly job (services/adaptive_weekly_job.py)
-- recomputes the adaptive TDEE and APPLIES the new target — but ONLY when the
-- service's data-quality/confidence score is high enough (>= 0.6). When the
-- score is below threshold the job leaves a pending weekly recommendation
-- instead of silently applying a low-confidence number.
--
-- Additive only; existing rows default to false (feature off, behavior
-- UNCHANGED). The one-tap POST /nutrition/adaptive/{user_id}/apply endpoint is
-- independent of this flag — this only governs the unattended weekly sweep.
--
-- Applied to prod (project hpbzfahijszqmgsybuor) via Supabase MCP apply_migration
-- on 2026-06-27. This file is the repo record of that change.

ALTER TABLE public.nutrition_preferences
  ADD COLUMN IF NOT EXISTS auto_adjust_weekly BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.nutrition_preferences.auto_adjust_weekly IS
  'Opt-in: when true, the weekly adaptive-target job recomputes the adaptive TDEE and auto-applies the new target_calories + macro split, but ONLY when the service data-quality score >= 0.6; otherwise it leaves a pending weekly recommendation. Default false (feature off). The one-tap /nutrition/adaptive/{user_id}/apply endpoint is independent of this flag.';
