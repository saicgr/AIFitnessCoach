-- Migration 2239: persist the in-app 0-100 sleep score (+ wake-up count) on daily_activity
--
-- FEATURE 1 (morning sleep-score push) must name the EXACT 0-100 score the in-app
-- Sleep screen shows. The app computes that number client-side via
-- mobile/flutter/lib/screens/health/widgets/sleep_score.dart::computeSleepScore
-- (which has access to mid-sleep history for the Consistency component the server
-- snapshot lacks). So the app now syncs the computed number into this column and the
-- push reads it directly — the server-side Python port (services/sleep_score.py) is
-- only a fallback when this column is NULL.
--
-- wake_ups is the count of distinct awakenings (>= 3 min) the app already aggregates
-- from Health Connect / HealthKit; the push copy cites it ("only a few wake-ups").
--
-- Idempotent: ADD COLUMN IF NOT EXISTS + COMMENT are safe to re-run. SMALLINT is
-- ample (score 0-100, wake_ups realistically < 50).

ALTER TABLE daily_activity
    ADD COLUMN IF NOT EXISTS sleep_score SMALLINT;

ALTER TABLE daily_activity
    ADD COLUMN IF NOT EXISTS wake_ups SMALLINT;

COMMENT ON COLUMN daily_activity.sleep_score IS
    'The in-app 0-100 sleep score (computeSleepScore in sleep_score.dart), synced '
    'by the client so the morning sleep-score push cites the exact number the Sleep '
    'screen shows. NULL => fall back to services/sleep_score.py compute_sleep_score.';

COMMENT ON COLUMN daily_activity.wake_ups IS
    'Count of distinct awakenings (segments >= 3 min) during the night, aggregated '
    'client-side from SLEEP_AWAKE / SLEEP_AWAKE_IN_BED. Cited in the sleep-score push copy.';
