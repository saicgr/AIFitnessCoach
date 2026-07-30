-- 2380 — make a NULL/invalid feature_gates.reset_period impossible.
--
-- WHY
-- ---
-- Migration 2330 repaired the one row that had already rotted (`ai_chat`), but
-- not the CAUSE: `feature_gates.reset_period` is nullable with no DEFAULT and no
-- CHECK, and `core/premium_gate.py::_get_current_usage` read NULL as "sum all
-- time usage". Any gate row seeded without a reset_period therefore turns its
-- `free_limit` into a LIFETIME cap instead of a per-day/per-month one — which is
-- exactly how a free user got 10 coach messages *ever* rather than 10 per day.
--
-- Six rows still carry a NULL period today. Each is a pure tier-gated feature —
-- free_limit is 0 or NULL, so nothing is metered and the period is currently
-- inert — but raising any of those free_limits above 0 would silently reinstate
-- the lifetime-cap bug. Per-row decision (all -> 'daily'):
--
--   advanced_analytics   free_limit NULL, minimum_tier premium — never metered;
--                        'daily' so a future non-null free_limit resets daily.
--   custom_workouts      free_limit 0,    minimum_tier premium — same.
--   form_video_analysis  free_limit 0,    minimum_tier premium — same. This is
--                        the only one enforced today (services/media_job_service.py),
--                        and it is blocked by the tier check before metering.
--   priority_support     free_limit 0,    minimum_tier ultra   — same.
--   trainer_mode         free_limit 0,    minimum_tier ultra   — same.
--   workout_sharing      free_limit 0,    minimum_tier ultra   — same.
--
-- 'daily' (not 'monthly') is the safe default: if a row is ever mis-seeded, the
-- worst case costs a user one day of a feature, never their whole account.
--
-- SAFETY: feature_gates holds 12 rows, so the NOT NULL scan and the CHECK
-- validation are instantaneous. The CHECK is still added NOT VALID and validated
-- separately (VALIDATE takes only SHARE UPDATE EXCLUSIVE) so the pattern stays
-- correct if this table ever grows. No data is dropped.

-- 1. Backfill every NULL to the decided value.
UPDATE feature_gates
SET reset_period = 'daily'
WHERE reset_period IS NULL;

-- 2. Normalise casing/whitespace so the CHECK below cannot reject a live row.
UPDATE feature_gates
SET reset_period = lower(btrim(reset_period))
WHERE reset_period <> lower(btrim(reset_period));

-- 3. New rows get a real period even if the writer forgets one.
ALTER TABLE feature_gates
    ALTER COLUMN reset_period SET DEFAULT 'daily';

-- 4. NULL becomes impossible.
ALTER TABLE feature_gates
    ALTER COLUMN reset_period SET NOT NULL;

-- 5. And so does any value core/premium_gate.py cannot window on.
--    Keep in sync with VALID_RESET_PERIODS in core/feature_gate_policy.py.
ALTER TABLE feature_gates
    DROP CONSTRAINT IF EXISTS feature_gates_reset_period_valid;

ALTER TABLE feature_gates
    ADD CONSTRAINT feature_gates_reset_period_valid
    CHECK (reset_period IN ('daily', 'monthly')) NOT VALID;

ALTER TABLE feature_gates
    VALIDATE CONSTRAINT feature_gates_reset_period_valid;

COMMENT ON COLUMN feature_gates.reset_period IS
    'Window a free_limit is metered over: daily | monthly. NOT NULL — a NULL used '
    'to be read as "sum all-time usage", turning a daily free cap into a lifetime '
    'one (see migrations 2330/2380 and core/feature_gate_policy.py).';
