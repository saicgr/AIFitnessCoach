-- Migration 1954: award_tier_rewards_for_week — the core reward engine.
--
-- Called by ensure_weekly_snapshot_fresh AFTER snapshot_weekly_leaderboard
-- has populated weekly_leaderboard_archive for the given week. Iterates that
-- archive and issues XP + badges + shields for every eligible user.
--
-- Every XP award path follows the same pattern:
--   1. INSERT ... ON CONFLICT DO NOTHING into weekly_tier_rewards_audit.
--   2. If insert returned a row → proceed with award_xp() + user_achievements
--      insert.
--   3. If conflict → award was already issued (retry / dup cron), skip.
-- This guarantees idempotency even under concurrent rewarders.
--
-- All XP goes through award_xp() (migration 1901) so user_xp.total_xp stays
-- consistent and level-up side-effects (rewards, animations) fire correctly.

CREATE OR REPLACE FUNCTION _tier_from_rank(p_rank INT, p_total INT)
RETURNS TEXT
LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
BEGIN
  IF p_total IS NULL OR p_total = 0 OR p_rank IS NULL OR p_rank = 0 THEN
    RETURN 'starter';
  END IF;
  -- Same ceil-based thresholds compute_user_percentile uses (migration 1948)
  IF p_rank <= GREATEST(1, CEIL(p_total::NUMERIC * 0.01)) THEN RETURN 'top1'; END IF;
  IF p_rank <= GREATEST(1, CEIL(p_total::NUMERIC * 0.05)) THEN RETURN 'top5'; END IF;
  IF p_rank <= GREATEST(1, CEIL(p_total::NUMERIC * 0.10)) THEN RETURN 'top10'; END IF;
  IF p_rank <= GREATEST(1, CEIL(p_total::NUMERIC * 0.25)) THEN RETURN 'top25'; END IF;
  IF p_rank <= GREATEST(1, CEIL(p_total::NUMERIC * 0.50)) THEN RETURN 'active'; END IF;
  RETURN 'starter';
END;
$$;

-- Numeric ranking of tiers for "is this tier ≥ that tier" comparisons.
CREATE OR REPLACE FUNCTION _tier_rank(p_tier TEXT)
RETURNS INT
LANGUAGE plpgsql IMMUTABLE SET search_path = public AS $$
BEGIN
  RETURN CASE p_tier
    WHEN 'top1' THEN 4
    WHEN 'top5' THEN 3
    WHEN 'top10' THEN 2
    WHEN 'top25' THEN 1
    ELSE 0
  END;
END;
$$;


CREATE OR REPLACE FUNCTION award_tier_rewards_for_week(
  p_week_start DATE,
  p_board_type TEXT DEFAULT 'xp',
  p_scope TEXT DEFAULT 'global'
) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  r RECORD;
  v_tier TEXT;
  v_prev_tier TEXT;
  v_prev_rank INT;
  v_total INT;
  v_prev_week DATE := p_week_start - INTERVAL '7 days';
  v_prev2_week DATE := p_week_start - INTERVAL '14 days';
  v_current_weeks INT;
  v_shield_saved BOOLEAN;
  v_xp INT;
  v_badge_id TEXT;
  v_audit_inserted INT;
  v_xp_first INT;
  v_rows_processed INT := 0;
  v_cum RECORD;
  v_new_peak BOOLEAN;
  v_peak_xp INT := CASE p_board_type WHEN 'xp' THEN 200 ELSE 120 END;
  v_rising_xp INT := CASE p_board_type WHEN 'xp' THEN 300 ELSE 180 END;
  v_phoenix_xp INT := CASE p_board_type WHEN 'xp' THEN 500 ELSE 300 END;
  v_consistency_xp INT := CASE p_board_type WHEN 'xp' THEN 3000 ELSE 1800 END;
  v_prestige_xp INT := CASE p_board_type WHEN 'xp' THEN 10000 ELSE 6000 END;
BEGIN
  -- Iterate every archived leaderboard row for this week/board/scope
  FOR r IN
    SELECT user_id, rank, metric_value, total_participants
      FROM weekly_leaderboard_archive
     WHERE week_start = p_week_start
       AND board_type = p_board_type
       AND scope = p_scope
  LOOP
    v_rows_processed := v_rows_processed + 1;
    v_total := r.total_participants;
    v_tier := _tier_from_rank(r.rank, v_total);
    v_shield_saved := FALSE;

    -- 1. Record tier history (immutable per-week log)
    INSERT INTO user_tier_history (user_id, week_start, board_type, tier, percentile, rank)
    VALUES (r.user_id, p_week_start, p_board_type, v_tier,
            CASE WHEN v_total > 0 THEN ROUND(100.0 * (v_total - r.rank + 1)::NUMERIC / v_total::NUMERIC, 1) ELSE 0 END,
            r.rank)
    ON CONFLICT (user_id, week_start, board_type) DO UPDATE
      SET tier = EXCLUDED.tier, percentile = EXCLUDED.percentile, rank = EXCLUDED.rank;

    -- 2. Look up prev-week tier (for shield / delta / phoenix logic)
    SELECT tier, rank INTO v_prev_tier, v_prev_rank
      FROM user_tier_history
     WHERE user_id = r.user_id AND week_start = v_prev_week AND board_type = p_board_type;

    -- 3. SHIELD SAVE CHECK — BEFORE updating tier_streaks so preservation works.
    --    Triggers when user was top10+ last week and fell out this week.
    IF v_prev_tier IS NOT NULL
       AND _tier_rank(v_prev_tier) >= _tier_rank('top10')
       AND _tier_rank(v_tier) < _tier_rank('top10') THEN
      IF use_consumable(r.user_id, 'rank_shield'::VARCHAR) THEN
        INSERT INTO weekly_tier_rewards_audit
          (user_id, week_start, board_type, tier, consecutive_weeks, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_prev_tier, NULL, 0, NULL, 'shield_save')
        ON CONFLICT DO NOTHING;
        v_shield_saved := TRUE;
        -- Effective tier for downstream streak math = prev tier (preserve)
        v_tier := v_prev_tier;
      END IF;
    END IF;

    -- 4. tier_streaks update
    --    Qualifying tiers only; lower = reset.
    IF _tier_rank(v_tier) > 0 THEN
      INSERT INTO tier_streaks AS ts (user_id, board_type, tier, current_weeks, last_week_start, updated_at)
      VALUES (r.user_id, p_board_type, v_tier, 1, p_week_start, NOW())
      ON CONFLICT (user_id, board_type) DO UPDATE
        SET tier = EXCLUDED.tier,
            current_weeks = CASE
              WHEN ts.last_week_start = v_prev_week AND _tier_rank(ts.tier) >= _tier_rank(EXCLUDED.tier) THEN ts.current_weeks + 1
              WHEN ts.last_week_start = v_prev_week AND _tier_rank(ts.tier) < _tier_rank(EXCLUDED.tier) THEN 1
              ELSE 1
            END,
            last_week_start = p_week_start,
            updated_at = NOW();
    ELSE
      -- Non-qualifying tier: reset streak but keep the row so history survives
      UPDATE tier_streaks
         SET current_weeks = 0, tier = v_tier, last_week_start = p_week_start, updated_at = NOW()
       WHERE user_id = r.user_id AND board_type = p_board_type;
    END IF;

    SELECT current_weeks INTO v_current_weeks
      FROM tier_streaks WHERE user_id = r.user_id AND board_type = p_board_type;

    -- 5. user_tier_cumulative — init row, bump weeks-in-topN, track peak
    INSERT INTO user_tier_cumulative (user_id, board_type)
    VALUES (r.user_id, p_board_type)
    ON CONFLICT (user_id, board_type) DO NOTHING;

    -- Increment cumulative counters (guarded against double-count by audit table)
    UPDATE user_tier_cumulative SET
      weeks_in_top25 = weeks_in_top25 + CASE WHEN _tier_rank(v_tier) >= 1 THEN 1 ELSE 0 END,
      weeks_in_top10 = weeks_in_top10 + CASE WHEN _tier_rank(v_tier) >= 2 THEN 1 ELSE 0 END,
      weeks_in_top5  = weeks_in_top5  + CASE WHEN _tier_rank(v_tier) >= 3 THEN 1 ELSE 0 END,
      weeks_in_top1  = weeks_in_top1  + CASE WHEN _tier_rank(v_tier) >= 4 THEN 1 ELSE 0 END,
      updated_at = NOW()
    WHERE user_id = r.user_id AND board_type = p_board_type
      AND NOT EXISTS (
        SELECT 1 FROM weekly_tier_rewards_audit wa
         WHERE wa.user_id = r.user_id
           AND wa.week_start = p_week_start
           AND wa.board_type = p_board_type
           AND wa.reward_kind = 'cumulative_counted'
      );
    -- Mark as counted
    INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, reward_kind)
    VALUES (r.user_id, p_week_start, p_board_type, v_tier, 'cumulative_counted')
    ON CONFLICT DO NOTHING;

    SELECT * INTO v_cum FROM user_tier_cumulative
     WHERE user_id = r.user_id AND board_type = p_board_type;

    -- 6. SECTION A — Tier persistence XP
    --    Skip if shield saved this week (the shield IS the reward for staying)
    IF NOT v_shield_saved AND _tier_rank(v_tier) > 0 THEN
      SELECT xp, badge_id INTO v_xp, v_badge_id
        FROM tier_persistence_xp
       WHERE board_type = p_board_type AND tier = v_tier AND consecutive_weeks = v_current_weeks;

      IF v_xp IS NOT NULL THEN
        INSERT INTO weekly_tier_rewards_audit
          (user_id, week_start, board_type, tier, consecutive_weeks, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_current_weeks, v_xp, v_badge_id, 'tier_persistence');
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

        IF v_audit_inserted > 0 THEN
          PERFORM award_xp(
            r.user_id, v_xp, 'tier_persistence', p_board_type,
            'Held ' || v_tier || ' for ' || v_current_weeks || ' consecutive weeks (' || p_board_type || ')',
            TRUE, TRUE
          );
          IF v_badge_id IS NOT NULL THEN
            INSERT INTO user_achievements (user_id, achievement_id, trigger_value, xp_awarded)
            VALUES (r.user_id, v_badge_id, v_current_weeks, v_xp);
          END IF;
        END IF;
      END IF;
    END IF;

    -- 7. SECTION B — First-time-tier entries (top10 / top5 / top1)
    --    User earns the bonus the first time they hit that tier on this board.
    --    Reaching top1 also grants top5 and top10 if never earned before.
    IF _tier_rank(v_tier) >= _tier_rank('top10') THEN
      -- top10 first-time
      IF NOT EXISTS (SELECT 1 FROM user_first_time_bonuses
                       WHERE user_id = r.user_id
                         AND bonus_type = 'discover_first_top10_' || p_board_type) THEN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, 'top10',
                (SELECT xp_reward FROM achievement_types WHERE id = 'discover_breakthrough_top10_' || p_board_type),
                'discover_breakthrough_top10_' || p_board_type, 'first_time_tier')
        ON CONFLICT DO NOTHING
        RETURNING 1 INTO v_audit_inserted;

        IF v_audit_inserted > 0 THEN
          v_xp_first := (SELECT xp_reward FROM achievement_types WHERE id = 'discover_breakthrough_top10_' || p_board_type);
          INSERT INTO user_first_time_bonuses (user_id, bonus_type, xp_awarded)
          VALUES (r.user_id, 'discover_first_top10_' || p_board_type, v_xp_first);
          PERFORM award_xp(r.user_id, v_xp_first, 'tier_first_time', p_board_type,
                           'First time in Top 10% (' || p_board_type || ')', TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, 'discover_breakthrough_top10_' || p_board_type, v_xp_first);
        END IF;
      END IF;
    END IF;
    IF _tier_rank(v_tier) >= _tier_rank('top5') THEN
      IF NOT EXISTS (SELECT 1 FROM user_first_time_bonuses
                       WHERE user_id = r.user_id
                         AND bonus_type = 'discover_first_top5_' || p_board_type) THEN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, 'top5',
                (SELECT xp_reward FROM achievement_types WHERE id = 'discover_rarefied_air_top5_' || p_board_type),
                'discover_rarefied_air_top5_' || p_board_type, 'first_time_tier')
        ON CONFLICT DO NOTHING
        RETURNING 1 INTO v_audit_inserted;

        IF v_audit_inserted > 0 THEN
          v_xp_first := (SELECT xp_reward FROM achievement_types WHERE id = 'discover_rarefied_air_top5_' || p_board_type);
          INSERT INTO user_first_time_bonuses (user_id, bonus_type, xp_awarded)
          VALUES (r.user_id, 'discover_first_top5_' || p_board_type, v_xp_first);
          PERFORM award_xp(r.user_id, v_xp_first, 'tier_first_time', p_board_type,
                           'First time in Top 5% (' || p_board_type || ')', TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, 'discover_rarefied_air_top5_' || p_board_type, v_xp_first);
        END IF;
      END IF;
    END IF;
    IF _tier_rank(v_tier) >= _tier_rank('top1') THEN
      IF NOT EXISTS (SELECT 1 FROM user_first_time_bonuses
                       WHERE user_id = r.user_id
                         AND bonus_type = 'discover_first_top1_' || p_board_type) THEN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, 'top1',
                (SELECT xp_reward FROM achievement_types WHERE id = 'discover_legend_born_top1_' || p_board_type),
                'discover_legend_born_top1_' || p_board_type, 'first_time_tier')
        ON CONFLICT DO NOTHING
        RETURNING 1 INTO v_audit_inserted;

        IF v_audit_inserted > 0 THEN
          v_xp_first := (SELECT xp_reward FROM achievement_types WHERE id = 'discover_legend_born_top1_' || p_board_type);
          INSERT INTO user_first_time_bonuses (user_id, bonus_type, xp_awarded)
          VALUES (r.user_id, 'discover_first_top1_' || p_board_type, v_xp_first);
          PERFORM award_xp(r.user_id, v_xp_first, 'tier_first_time', p_board_type,
                           'First time in Top 1% (' || p_board_type || ')', TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, 'discover_legend_born_top1_' || p_board_type, v_xp_first);
        END IF;
      END IF;
    END IF;

    -- 8. SECTION B — Cumulative weeks-in-top10 milestones
    IF v_cum.weeks_in_top10 IN (10, 25) THEN
      DECLARE
        v_cum_badge TEXT := CASE v_cum.weeks_in_top10
          WHEN 10 THEN 'discover_consistency_king_top10_10w_' || p_board_type
          WHEN 25 THEN 'discover_prestige_frame_top10_25w_' || p_board_type END;
        v_cum_xp INT := CASE v_cum.weeks_in_top10
          WHEN 10 THEN v_consistency_xp
          WHEN 25 THEN v_prestige_xp END;
      BEGIN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_cum_xp, v_cum_badge, 'cumulative_weeks')
        ON CONFLICT DO NOTHING
        RETURNING 1 INTO v_audit_inserted;

        IF v_audit_inserted > 0 THEN
          PERFORM award_xp(r.user_id, v_cum_xp, 'tier_cumulative', p_board_type,
                           v_cum.weeks_in_top10 || ' total weeks in Top 10% (' || p_board_type || ')',
                           TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, v_cum_badge, v_cum_xp);
        END IF;
      END;
    END IF;

    -- 9. SECTION B — New personal peak rank (silent, no badge)
    v_new_peak := v_cum.peak_rank IS NULL OR r.rank < v_cum.peak_rank;
    IF v_new_peak THEN
      UPDATE user_tier_cumulative SET
        peak_rank = r.rank,
        peak_tier = CASE WHEN _tier_rank(v_tier) > COALESCE(_tier_rank(peak_tier), 0) THEN v_tier ELSE peak_tier END,
        peak_achieved_at = NOW(),
        updated_at = NOW()
       WHERE user_id = r.user_id AND board_type = p_board_type;

      INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, reward_kind)
      VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_peak_xp, 'peak_rank')
      ON CONFLICT DO NOTHING
      RETURNING 1 INTO v_audit_inserted;

      IF v_audit_inserted > 0 THEN
        PERFORM award_xp(r.user_id, v_peak_xp, 'peak_rank', p_board_type,
                         'New personal peak rank #' || r.rank || ' (' || p_board_type || ')',
                         TRUE, TRUE);
        -- No user_achievements insert: this reward is silent.
      END IF;
    END IF;

    -- 10. SECTION C — Rising Star (rank ↑5+ from prev week)
    IF v_prev_rank IS NOT NULL AND (v_prev_rank - r.rank) >= 5 THEN
      INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
      VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_rising_xp,
              'discover_rising_star_' || p_board_type, 'rising_star')
      ON CONFLICT DO NOTHING
      RETURNING 1 INTO v_audit_inserted;

      IF v_audit_inserted > 0 THEN
        PERFORM award_xp(r.user_id, v_rising_xp, 'rising_star', p_board_type,
                         'Rising Star: ↑' || (v_prev_rank - r.rank) || ' ranks (' || p_board_type || ')',
                         TRUE, TRUE);
        INSERT INTO user_achievements (user_id, achievement_id, trigger_value, xp_awarded)
        VALUES (r.user_id, 'discover_rising_star_' || p_board_type, (v_prev_rank - r.rank), v_rising_xp);
      END IF;
    END IF;

    -- 11. SECTION C — Phoenix Rising (absent 2+ prev weeks, back in top25+)
    IF _tier_rank(v_tier) >= _tier_rank('top25') THEN
      IF NOT EXISTS (
        SELECT 1 FROM weekly_leaderboard_archive
         WHERE user_id = r.user_id
           AND board_type = p_board_type
           AND scope = p_scope
           AND week_start IN (v_prev_week, v_prev2_week)
      ) THEN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_phoenix_xp,
                'discover_phoenix_rising_' || p_board_type, 'phoenix_rising')
        ON CONFLICT DO NOTHING
        RETURNING 1 INTO v_audit_inserted;

        IF v_audit_inserted > 0 THEN
          PERFORM award_xp(r.user_id, v_phoenix_xp, 'phoenix_rising', p_board_type,
                           'Phoenix Rising: back on the board (' || p_board_type || ')',
                           TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, 'discover_phoenix_rising_' || p_board_type, v_phoenix_xp);
        END IF;
      END IF;
    END IF;

    -- 12. Top-up rank shield inventory (cooldown + cap guarded internally)
    PERFORM maybe_grant_free_rank_shield(r.user_id, p_week_start, p_board_type);

  END LOOP;

  RETURN v_rows_processed;
END;
$$;

GRANT EXECUTE ON FUNCTION award_tier_rewards_for_week(DATE, TEXT, TEXT) TO service_role;
