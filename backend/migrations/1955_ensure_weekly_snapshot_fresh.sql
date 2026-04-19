-- Migration 1955: lazy self-trigger for the weekly snapshot + reward pipeline.
--
-- Called by get_discover_snapshot on every Discover open. Takes a Postgres
-- advisory lock so only one request per transaction does the work — concurrent
-- openers skip. Archive-existence check prevents re-running after completion.
--
-- Per-board BEGIN/EXCEPTION wrapping means one board failing (e.g. if a
-- downstream table is in an unusual state) doesn't abort the other two.
-- Discover endpoint wraps this call in its own try/except so a total failure
-- here never breaks the tab.

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
  -- Previous complete ISO week (Mon → Sun we've already finished).
  -- DATE_TRUNC('week', NOW()) gives this Monday's date; subtract 7 for prev.
  v_target := (DATE_TRUNC('week', NOW()::TIMESTAMP)::DATE) - INTERVAL '7 days';

  -- Advisory lock — serialize concurrent firings. If we can't acquire,
  -- another request is already doing the work.
  IF NOT pg_try_advisory_xact_lock(hashtext('weekly_snapshot')) THEN
    RETURN QUERY SELECT v_target, 0, 0, FALSE;
    RETURN;
  END IF;

  -- If archive already has rows for the target week, nothing to do.
  IF EXISTS (SELECT 1 FROM weekly_leaderboard_archive WHERE week_start = v_target LIMIT 1) THEN
    RETURN QUERY SELECT v_target, 0, 0, FALSE;
    RETURN;
  END IF;

  -- Run the snapshot (writes rows for all 3 boards + global scope)
  BEGIN
    v_rows := snapshot_weekly_leaderboard(v_target);
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'snapshot_weekly_leaderboard failed: %', SQLERRM;
    v_rows := 0;
  END;

  -- Run tier rewards for all 3 boards. Each board is isolated — one failure
  -- doesn't abort the others.
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
