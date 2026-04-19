-- Migration 1957: get_weekly_recap — JSONB summary consumed by the Flutter
-- Weekly Recap modal. Reads from weekly_leaderboard_archive + audit trail +
-- xp_transactions + tier_streaks/cumulative. No writes.
--
-- Target week defaults to the most-recently-snapshotted week (prev complete
-- ISO week). Caller can also pass an explicit week_start for retroactive
-- rendering (e.g. "view last week's recap again" from settings).

CREATE OR REPLACE FUNCTION get_weekly_recap(
  p_user_id UUID,
  p_week_start DATE DEFAULT NULL,
  p_board_type TEXT DEFAULT 'xp'
) RETURNS JSONB
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_week_start DATE;
  v_prev_week DATE;
  v_rank_current INT;
  v_rank_previous INT;
  v_rank_delta INT;
  v_tier_current TEXT;
  v_tier_previous TEXT;
  v_xp_this_week INT;
  v_shields_used INT;
  v_awards JSONB;
  v_passes JSONB;
  v_overtaken JSONB;
  v_consecutive_weeks INT;
  v_next_milestone_weeks INT;
  v_next_milestone_xp INT;
  v_result JSONB;
BEGIN
  v_week_start := COALESCE(p_week_start,
    (DATE_TRUNC('week', NOW()::TIMESTAMP)::DATE) - INTERVAL '7 days');
  v_prev_week := v_week_start - INTERVAL '7 days';

  -- Ranks
  SELECT rank INTO v_rank_current
    FROM weekly_leaderboard_archive
   WHERE user_id = p_user_id AND week_start = v_week_start
     AND board_type = p_board_type AND scope = 'global';

  SELECT rank INTO v_rank_previous
    FROM weekly_leaderboard_archive
   WHERE user_id = p_user_id AND week_start = v_prev_week
     AND board_type = p_board_type AND scope = 'global';

  v_rank_delta := CASE
    WHEN v_rank_current IS NOT NULL AND v_rank_previous IS NOT NULL
      THEN (v_rank_previous - v_rank_current)
    ELSE NULL
  END;

  -- Tiers
  SELECT tier INTO v_tier_current
    FROM user_tier_history
   WHERE user_id = p_user_id AND week_start = v_week_start AND board_type = p_board_type;
  SELECT tier INTO v_tier_previous
    FROM user_tier_history
   WHERE user_id = p_user_id AND week_start = v_prev_week AND board_type = p_board_type;

  -- XP earned this week (any source)
  SELECT COALESCE(SUM(xp_amount), 0) INTO v_xp_this_week
    FROM xp_transactions
   WHERE user_id = p_user_id
     AND created_at >= v_week_start::TIMESTAMPTZ
     AND created_at < (v_week_start + INTERVAL '7 days')::TIMESTAMPTZ;

  -- Shield saves this week
  SELECT COUNT(*)::INT INTO v_shields_used
    FROM weekly_tier_rewards_audit
   WHERE user_id = p_user_id AND week_start = v_week_start
     AND board_type = p_board_type AND reward_kind = 'shield_save';

  -- Awards unlocked — pull from audit with joined achievement name/icon
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'kind', wa.reward_kind,
      'badge_id', wa.badge_id,
      'badge_name', at.name,
      'badge_icon', at.icon,
      'rarity', at.rarity,
      'xp', wa.xp_awarded,
      'tier', wa.tier,
      'consecutive_weeks', wa.consecutive_weeks
  ) ORDER BY wa.xp_awarded DESC), '[]'::jsonb) INTO v_awards
    FROM weekly_tier_rewards_audit wa
    LEFT JOIN achievement_types at ON at.id = wa.badge_id
   WHERE wa.user_id = p_user_id
     AND wa.week_start = v_week_start
     AND wa.board_type = p_board_type
     AND wa.reward_kind IN ('tier_persistence','first_time_tier','cumulative_weeks',
                            'peak_rank','rising_star','phoenix_rising','shield_save')
     AND wa.xp_awarded > 0;

  -- Passes (users I overtook: they were ahead last week, behind this week)
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'user_id', u.id,
      'username', CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username END,
      'display_name', CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name END,
      'avatar_url', CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url) END,
      'previous_rank', prev.rank,
      'current_rank', curr.rank
  ) ORDER BY curr.rank), '[]'::jsonb) INTO v_passes
    FROM weekly_leaderboard_archive curr
    JOIN weekly_leaderboard_archive prev
      ON prev.user_id = curr.user_id
     AND prev.board_type = curr.board_type
     AND prev.scope = curr.scope
     AND prev.week_start = v_prev_week
    JOIN users u ON u.id = curr.user_id
   WHERE curr.week_start = v_week_start
     AND curr.board_type = p_board_type
     AND curr.scope = 'global'
     AND v_rank_current IS NOT NULL
     AND v_rank_previous IS NOT NULL
     AND prev.rank < v_rank_previous     -- they were ahead of me last week
     AND curr.rank > v_rank_current      -- they're behind me this week
     AND curr.user_id <> p_user_id
   LIMIT 5;

  -- Overtaken by (users who passed me: they were behind last week, ahead this week)
  SELECT COALESCE(jsonb_agg(jsonb_build_object(
      'user_id', u.id,
      'username', CASE WHEN u.leaderboard_anonymous THEN NULL ELSE u.username END,
      'display_name', CASE WHEN u.leaderboard_anonymous THEN 'Anonymous athlete' ELSE u.name END,
      'avatar_url', CASE WHEN u.leaderboard_anonymous THEN NULL ELSE COALESCE(u.avatar_url, u.photo_url) END,
      'previous_rank', prev.rank,
      'current_rank', curr.rank
  ) ORDER BY curr.rank), '[]'::jsonb) INTO v_overtaken
    FROM weekly_leaderboard_archive curr
    JOIN weekly_leaderboard_archive prev
      ON prev.user_id = curr.user_id
     AND prev.board_type = curr.board_type
     AND prev.scope = curr.scope
     AND prev.week_start = v_prev_week
    JOIN users u ON u.id = curr.user_id
   WHERE curr.week_start = v_week_start
     AND curr.board_type = p_board_type
     AND curr.scope = 'global'
     AND v_rank_current IS NOT NULL
     AND v_rank_previous IS NOT NULL
     AND prev.rank > v_rank_previous
     AND curr.rank < v_rank_current
     AND curr.user_id <> p_user_id
   LIMIT 5;

  -- Streak + next milestone
  SELECT current_weeks INTO v_consecutive_weeks
    FROM tier_streaks
   WHERE user_id = p_user_id AND board_type = p_board_type;
  v_consecutive_weeks := COALESCE(v_consecutive_weeks, 0);

  SELECT consecutive_weeks, xp INTO v_next_milestone_weeks, v_next_milestone_xp
    FROM tier_persistence_xp
   WHERE board_type = p_board_type
     AND tier = v_tier_current
     AND consecutive_weeks > v_consecutive_weeks
   ORDER BY consecutive_weeks ASC
   LIMIT 1;

  v_result := jsonb_build_object(
    'week_start', v_week_start,
    'board_type', p_board_type,
    'rank_current', v_rank_current,
    'rank_previous', v_rank_previous,
    'rank_delta', v_rank_delta,
    'tier_current', v_tier_current,
    'tier_previous', v_tier_previous,
    'xp_earned_this_week', v_xp_this_week,
    'shields_used', v_shields_used,
    'awards_unlocked', v_awards,
    'passes', v_passes,
    'overtaken_by', v_overtaken,
    'consecutive_weeks_in_tier', v_consecutive_weeks,
    'next_milestone_weeks', v_next_milestone_weeks,
    'next_milestone_xp', v_next_milestone_xp
  );

  RETURN v_result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_weekly_recap(UUID, DATE, TEXT) TO authenticated, service_role;
