-- Migration 2413: backfill weight_logs from existing body_measurements rows.
--
-- Rows 352: every in-app weight write path (api/v1/metrics.py, fasting_impact.py,
-- wellness/events.py) has only ever inserted into body_measurements, while 18
-- backend readers (home_signals.py, fasting_impact_endpoints.py, email_cron.py,
-- adaptive_tdee_service.py, ...) read weight_logs — which only the CSV importer
-- wrote. Those call sites now dual-write going forward (see the three files
-- above), but that does nothing for weight history an account already has
-- sitting in body_measurements. Backfill it once so existing accounts aren't
-- stuck at zero weight_logs rows until their next new weigh-in.
--
-- Idempotent: the NOT EXISTS guard matches on (user_id, logged_at), so
-- re-running this after new dual-writes have landed for the same timestamps
-- is a no-op rather than a duplicate.

INSERT INTO weight_logs (user_id, weight_kg, logged_at, source, notes)
SELECT
    bm.user_id,
    bm.weight_kg,
    bm.measured_at,
    'manual',
    bm.notes
FROM body_measurements bm
WHERE bm.weight_kg IS NOT NULL
  AND bm.user_id IS NOT NULL
  AND bm.measured_at IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM weight_logs wl
      WHERE wl.user_id = bm.user_id
        AND wl.logged_at = bm.measured_at
  );
