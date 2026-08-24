-- Migration 2434: De-duplicate checkpoint_rewards and guard against re-seeding
--
-- checkpoint_rewards was never given a natural-key unique constraint --
-- only its surrogate `id` (a fresh UUID per row) has one. Migrations 222,
-- 223a and 224 seed this table with `INSERT ... ON CONFLICT DO NOTHING`,
-- but with no unique constraint on (checkpoint_type, metric_name,
-- period_type) there is nothing for ON CONFLICT to catch: every re-run of
-- those seed inserts (or of a script that re-applies them) just adds a
-- fresh copy. In production every one of the 26 seeded reward rows had
-- been inserted 3 times, tripling SUM(xp_reward) for anyone querying this
-- table directly (see tests/test_xp_database_integration.py::TestXPTotals,
-- which reads the guide totals straight from this table).
--
-- Fix: collapse to one row per (checkpoint_type, metric_name, period_type),
-- keeping the earliest `created_at`, then add the missing unique
-- constraint so this cannot silently recur.

DELETE FROM checkpoint_rewards a
USING checkpoint_rewards b
WHERE a.checkpoint_type = b.checkpoint_type
  AND a.metric_name IS NOT DISTINCT FROM b.metric_name
  AND a.period_type IS NOT DISTINCT FROM b.period_type
  AND (a.created_at, a.id) > (b.created_at, b.id);

ALTER TABLE checkpoint_rewards
  DROP CONSTRAINT IF EXISTS checkpoint_rewards_type_metric_period_key;
ALTER TABLE checkpoint_rewards
  ADD CONSTRAINT checkpoint_rewards_type_metric_period_key
  UNIQUE (checkpoint_type, metric_name, period_type);

-- VERIFY: select checkpoint_type, metric_name, period_type, count(*)
--   from checkpoint_rewards group by 1,2,3 having count(*) > 1; -- expect 0 rows
