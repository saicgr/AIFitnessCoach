-- Backfill performance_logs.metrics (canonical JSONB bag) from the typed
-- first-class columns, for historical rows logged before the metric bag
-- existed. Mirrors services/metric_registry.build_metrics_bag():
--   weight_kg  -> bag "weight_kg"
--   reps       -> bag "reps"        (column: reps_completed)
--   distance_m -> bag "distance_m"  (column: distance_meters, when not null)
--   time_s     -> bag "time_s"      (column: set_duration_seconds, when not null)
--
-- jsonb_strip_nulls drops any key whose source column is NULL, so the bag stays
-- clean (never stores weight_kg:null). Idempotent + safe to re-run: only rows
-- where metrics IS NULL are touched, and a row with no usable typed values is
-- skipped (the stripped object would be '{}').
--
-- NOT executed automatically — run manually after verifying the row count:
--   psql "$DATABASE_URL" -f backend/scripts/backfill_performance_metrics.sql

UPDATE performance_logs
SET metrics = jsonb_strip_nulls(
        jsonb_build_object(
            'weight_kg',  weight_kg,
            'reps',       reps_completed,
            'distance_m', distance_meters,
            'time_s',     set_duration_seconds
        )
    )
WHERE metrics IS NULL
  AND jsonb_strip_nulls(
        jsonb_build_object(
            'weight_kg',  weight_kg,
            'reps',       reps_completed,
            'distance_m', distance_meters,
            'time_s',     set_duration_seconds
        )
      ) <> '{}'::jsonb;
