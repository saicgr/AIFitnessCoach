-- Add per-set timing columns to performance_logs
-- Tracks how long each set took and actual rest taken before it

ALTER TABLE performance_logs
  ADD COLUMN IF NOT EXISTS set_duration_seconds INTEGER,
  ADD COLUMN IF NOT EXISTS rest_duration_seconds INTEGER;

COMMENT ON COLUMN performance_logs.set_duration_seconds IS 'Time in seconds from set start to completion';
COMMENT ON COLUMN performance_logs.rest_duration_seconds IS 'Actual rest taken before this set (null for first set)';
