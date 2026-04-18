-- Migration 1944: weekly/daily snapshots of fitness radar shapes + history RPC.
-- Applied to prod Supabase 2026-04-18 via MCP.
--
-- Enables shape-growth retention:
--   * "Your shape grew this month" nudges
--   * Scrub-through-time radar in the Discover peek sheet
--   * Screenshot-shareable progression strips
--
-- Storage: ~60 bytes/user/day. At 10K daily active → 220MB/year. Negligible.

CREATE TABLE IF NOT EXISTS fitness_profile_snapshots (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  snapshot_date DATE NOT NULL,
  strength NUMERIC NOT NULL DEFAULT 0,
  muscle NUMERIC NOT NULL DEFAULT 0,
  recovery NUMERIC NOT NULL DEFAULT 0,
  consistency NUMERIC NOT NULL DEFAULT 0,
  endurance NUMERIC NOT NULL DEFAULT 0,
  nutrition NUMERIC NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, snapshot_date)
);

CREATE INDEX IF NOT EXISTS idx_fps_user_date
  ON fitness_profile_snapshots(user_id, snapshot_date DESC);

ALTER TABLE fitness_profile_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS fps_select_own ON fitness_profile_snapshots;
CREATE POLICY fps_select_own ON fitness_profile_snapshots
  FOR SELECT USING (user_id = (SELECT id FROM users WHERE auth_id = auth.uid()));

DROP POLICY IF EXISTS fps_service_write ON fitness_profile_snapshots;
CREATE POLICY fps_service_write ON fitness_profile_snapshots
  FOR ALL TO service_role USING (true) WITH CHECK (true);

GRANT SELECT ON fitness_profile_snapshots TO authenticated;
GRANT ALL ON fitness_profile_snapshots TO service_role;


CREATE OR REPLACE FUNCTION snapshot_all_active_fitness_profiles(
  p_snapshot_date DATE DEFAULT CURRENT_DATE
) RETURNS INTEGER
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_count INT := 0;
BEGIN
  INSERT INTO fitness_profile_snapshots
    (user_id, snapshot_date, strength, muscle, recovery, consistency, endurance, nutrition)
  SELECT
    u.id, p_snapshot_date,
    COALESCE(_score_strength(u.id), 0),
    COALESCE(_score_muscle(u.id), 0),
    COALESCE(_score_recovery(u.id), 0),
    COALESCE(_score_consistency(u.id), 0),
    COALESCE(_score_endurance(u.id), 0),
    COALESCE(_score_nutrition(u.id), 0)
  FROM users u
  WHERE EXISTS (
      SELECT 1 FROM workout_logs wl
      WHERE wl.user_id = u.id AND wl.status = 'completed'
        AND wl.completed_at > NOW() - INTERVAL '14 days'
    ) OR EXISTS (
      SELECT 1 FROM food_logs fl
      WHERE fl.user_id = u.id AND fl.deleted_at IS NULL
        AND fl.logged_at > NOW() - INTERVAL '14 days'
    )
  ON CONFLICT (user_id, snapshot_date) DO UPDATE SET
    strength    = EXCLUDED.strength,
    muscle      = EXCLUDED.muscle,
    recovery    = EXCLUDED.recovery,
    consistency = EXCLUDED.consistency,
    endurance   = EXCLUDED.endurance,
    nutrition   = EXCLUDED.nutrition;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION snapshot_all_active_fitness_profiles(DATE) TO service_role;


-- Self-only history lookup for Insights/retention features.
CREATE OR REPLACE FUNCTION get_fitness_shape_history(
  p_user_id UUID,
  p_days_back INT DEFAULT 30
) RETURNS TABLE (
  snapshot_date DATE,
  strength NUMERIC, muscle NUMERIC, recovery NUMERIC,
  consistency NUMERIC, endurance NUMERIC, nutrition NUMERIC
)
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  RETURN QUERY
  SELECT s.snapshot_date, s.strength, s.muscle, s.recovery,
         s.consistency, s.endurance, s.nutrition
  FROM fitness_profile_snapshots s
  WHERE s.user_id = p_user_id
    AND s.snapshot_date >= CURRENT_DATE - (p_days_back || ' days')::INTERVAL
  ORDER BY s.snapshot_date;
END;
$$;

GRANT EXECUTE ON FUNCTION get_fitness_shape_history(UUID, INT) TO authenticated, service_role;
