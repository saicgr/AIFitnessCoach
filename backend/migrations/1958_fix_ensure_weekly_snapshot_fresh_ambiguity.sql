-- Migration 1958: hotfix for 1955 — the RETURNS TABLE(week_start DATE, ...)
-- declaration implicitly creates `week_start` as an OUT parameter, which
-- shadowed the `weekly_leaderboard_archive.week_start` column inside the
-- existence check. Qualify with table alias `wla`.

CREATE OR REPLACE FUNCTION ensure_weekly_snapshot_fresh()
RETURNS TABLE(
  week_start DATE,
  rows_written INT,
  rewards_written INT,
  ran BOOLEAN
)
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_target DATE;
  v_rows INT := 0;
  v_rewards INT := 0;
  v_board TEXT;
  v_board_rewards INT;
BEGIN
  v_target := (DATE_TRUNC('week', NOW()::TIMESTAMP)::DATE) - INTERVAL '7 days';

  IF NOT pg_try_advisory_xact_lock(hashtext('weekly_snapshot')) THEN
    RETURN QUERY SELECT v_target, 0, 0, FALSE;
    RETURN;
  END IF;

  IF EXISTS (SELECT 1 FROM weekly_leaderboard_archive wla WHERE wla.week_start = v_target LIMIT 1) THEN
    RETURN QUERY SELECT v_target, 0, 0, FALSE;
    RETURN;
  END IF;

  BEGIN
    v_rows := snapshot_weekly_leaderboard(v_target);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'snapshot_weekly_leaderboard failed: %', SQLERRM;
    v_rows := 0;
  END;

  FOREACH v_board IN ARRAY ARRAY['xp','volume','streaks'] LOOP
    BEGIN
      v_board_rewards := award_tier_rewards_for_week(v_target, v_board, 'global');
      v_rewards := v_rewards + COALESCE(v_board_rewards, 0);
    EXCEPTION WHEN OTHERS THEN
      RAISE NOTICE 'award_tier_rewards_for_week failed for %: %', v_board, SQLERRM;
    END;
  END LOOP;

  RETURN QUERY SELECT v_target, v_rows, v_rewards, TRUE;
END;
$$;

GRANT EXECUTE ON FUNCTION ensure_weekly_snapshot_fresh() TO authenticated, service_role;
