-- 2255_workout_completeness_degraded_flag.sql
--
-- Minimum-completeness invariant for generated workouts (never ship a thin
-- "1 exercise" 60-min workout).
--
-- A generated workout must hold >= its duration/type-derived exercise floor
-- OR be explicitly tagged degraded with a truthful reason (genuinely tiny
-- candidate pool: niche equipment / injury-constrained / heavy exclusions).
-- The guarantee is enforced in APPLICATION code (services/workout_completeness.py
-- terminal stage + reserve-pool backfill); these columns are the durable,
-- queryable flag + a fail-open tripwire at the create_workout chokepoint.
--
-- Deliberately ADDITIVE ONLY (nullable columns, defaults). NO CHECK / trigger
-- on exercise count: a hard DB guard could 500 generation on an unanticipated
-- edge case and leave the user with NO workout, which is worse than a thin one
-- (cf. migration 2048's unique index, which 500'd until a catch+refetch was
-- added). Generation must always fail open.

ALTER TABLE workouts
    ADD COLUMN IF NOT EXISTS is_degraded BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS degraded_reason TEXT;

COMMENT ON COLUMN workouts.is_degraded IS
    'Migration 2255. TRUE when this generated workout shipped below its '
    'duration/type-derived exercise floor because the real candidate pool was '
    'genuinely too small. FALSE for normal workouts. Set by the completeness '
    'terminal stage or the create_workout fail-open tripwire.';

COMMENT ON COLUMN workouts.degraded_reason IS
    'Migration 2255. Machine-readable reason when is_degraded=TRUE: '
    'tiny_equipment_pool | injury_constrained | niche_focus | heavy_exclusions | '
    'write_guard_fallback. NULL otherwise.';
