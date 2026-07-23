-- Migration 2324: gate phantom leaderboard tier rewards.
--
-- BUG (found 2026-07-22): a brand-new account (created 2026-07-22) reached
-- Level 11 / 11,472 XP ~90 seconds after signup. 98% of that XP came from
-- award_tier_rewards_for_week issuing first-time top1/top5/top10 bonuses for a
-- week the account did not exist during, on 2-person boards, with metric_value
-- = 0. `_tier_from_rank` returns 'top1' for rank 1 of 2, and Section B cascades
-- top1 → also grants top5 + top10. Across the xp/volume/streaks boards that is
-- 10,200+ XP for doing nothing.
--
-- Root cause: award_tier_rewards_for_week trusts every weekly_leaderboard_archive
-- row as a legitimate competitive finish. In a tiny cohort (max 4 users in prod)
-- every ranked user is simultaneously top1/top5/top10, and the snapshot can
-- include rows for accounts created after the archived week closed.
--
-- FIX: skip ALL reward issuance (and the tier-history write, so phoenix_rising /
-- tier_persistence can't fire off phantom history later) for an archive row when
-- ANY of:
--   * total_participants < MIN_COHORT (20) — a handful of users is not a
--     leaderboard, so "top 1%" is meaningless;
--   * metric_value <= 0 — the account did nothing that week;
--   * the user's account was created on/after the week's END (week_start + 7d) —
--     it could not have competed in that week.
--
-- Only the guard is added; the rest of the function is byte-for-byte the live
-- definition (pulled via pg_get_functiondef).

CREATE OR REPLACE FUNCTION public.award_tier_rewards_for_week(
  p_week_start date,
  p_board_type text DEFAULT 'xp'::text,
  p_scope text DEFAULT 'global'::text
)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  -- Minimum cohort size for a board to count as a real leaderboard.
  v_min_cohort INT := 20;
BEGIN
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

    -- ── PHANTOM-REWARD GATE (migration 2324) ──────────────────────────────
    -- Skip the entire row — no tier history, no XP, no badges — when the
    -- "finish" isn't a real competitive result. See migration header.
    IF v_total < v_min_cohort
       OR COALESCE(r.metric_value::numeric, 0) <= 0
       OR EXISTS (
            SELECT 1 FROM users u
             WHERE u.id = r.user_id
               AND u.created_at >= (p_week_start + INTERVAL '7 days')
          ) THEN
      CONTINUE;
    END IF;

    INSERT INTO user_tier_history (user_id, week_start, board_type, tier, percentile, rank)
    VALUES (r.user_id, p_week_start, p_board_type, v_tier,
            CASE WHEN v_total > 0 THEN ROUND(100.0 * (v_total - r.rank + 1)::NUMERIC / v_total::NUMERIC, 1) ELSE 0 END,
            r.rank)
    ON CONFLICT (user_id, week_start, board_type) DO UPDATE
      SET tier = EXCLUDED.tier, percentile = EXCLUDED.percentile, rank = EXCLUDED.rank;

    SELECT tier, rank INTO v_prev_tier, v_prev_rank
      FROM user_tier_history
     WHERE user_id = r.user_id AND week_start = v_prev_week AND board_type = p_board_type;

    IF v_prev_tier IS NOT NULL
       AND _tier_rank(v_prev_tier) >= _tier_rank('top10')
       AND _tier_rank(v_tier) < _tier_rank('top10') THEN
      IF use_consumable(r.user_id, 'rank_shield'::VARCHAR) THEN
        INSERT INTO weekly_tier_rewards_audit
          (user_id, week_start, board_type, tier, consecutive_weeks, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_prev_tier, NULL, 0, NULL, 'shield_save')
        ON CONFLICT DO NOTHING;
        v_shield_saved := TRUE;
        v_tier := v_prev_tier;
      END IF;
    END IF;

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
      UPDATE tier_streaks
         SET current_weeks = 0, tier = v_tier, last_week_start = p_week_start, updated_at = NOW()
       WHERE user_id = r.user_id AND board_type = p_board_type;
    END IF;

    SELECT current_weeks INTO v_current_weeks
      FROM tier_streaks WHERE user_id = r.user_id AND board_type = p_board_type;

    INSERT INTO user_tier_cumulative (user_id, board_type)
    VALUES (r.user_id, p_board_type)
    ON CONFLICT (user_id, board_type) DO NOTHING;

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

    INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, reward_kind)
    VALUES (r.user_id, p_week_start, p_board_type, v_tier, 'cumulative_counted')
    ON CONFLICT DO NOTHING;

    SELECT * INTO v_cum FROM user_tier_cumulative
     WHERE user_id = r.user_id AND board_type = p_board_type;

    IF NOT v_shield_saved AND _tier_rank(v_tier) > 0 THEN
      SELECT xp, badge_id INTO v_xp, v_badge_id
        FROM tier_persistence_xp
       WHERE board_type = p_board_type AND tier = v_tier AND consecutive_weeks = v_current_weeks;

      IF v_xp IS NOT NULL THEN
        INSERT INTO weekly_tier_rewards_audit
          (user_id, week_start, board_type, tier, consecutive_weeks, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_current_weeks, v_xp, v_badge_id, 'tier_persistence')
        ON CONFLICT DO NOTHING;
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

    IF _tier_rank(v_tier) >= _tier_rank('top10') THEN
      IF NOT EXISTS (SELECT 1 FROM user_first_time_bonuses
                       WHERE user_id = r.user_id
                         AND bonus_type = 'discover_first_top10_' || p_board_type) THEN
        INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
        VALUES (r.user_id, p_week_start, p_board_type, 'top10',
                (SELECT xp_reward FROM achievement_types WHERE id = 'discover_breakthrough_top10_' || p_board_type),
                'discover_breakthrough_top10_' || p_board_type, 'first_time_tier')
        ON CONFLICT DO NOTHING;
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

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
        ON CONFLICT DO NOTHING;
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

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
        ON CONFLICT DO NOTHING;
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

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
        ON CONFLICT DO NOTHING;
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

        IF v_audit_inserted > 0 THEN
          PERFORM award_xp(r.user_id, v_cum_xp, 'tier_cumulative', p_board_type,
                           v_cum.weeks_in_top10 || ' total weeks in Top 10% (' || p_board_type || ')',
                           TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, v_cum_badge, v_cum_xp);
        END IF;
      END;
    END IF;

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
      ON CONFLICT DO NOTHING;
      GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

      IF v_audit_inserted > 0 THEN
        PERFORM award_xp(r.user_id, v_peak_xp, 'peak_rank', p_board_type,
                         'New personal peak rank #' || r.rank || ' (' || p_board_type || ')',
                         TRUE, TRUE);
      END IF;
    END IF;

    IF v_prev_rank IS NOT NULL AND (v_prev_rank - r.rank) >= 5 THEN
      INSERT INTO weekly_tier_rewards_audit (user_id, week_start, board_type, tier, xp_awarded, badge_id, reward_kind)
      VALUES (r.user_id, p_week_start, p_board_type, v_tier, v_rising_xp,
              'discover_rising_star_' || p_board_type, 'rising_star')
      ON CONFLICT DO NOTHING;
      GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

      IF v_audit_inserted > 0 THEN
        PERFORM award_xp(r.user_id, v_rising_xp, 'rising_star', p_board_type,
                         'Rising Star: up ' || (v_prev_rank - r.rank) || ' ranks (' || p_board_type || ')',
                         TRUE, TRUE);
        INSERT INTO user_achievements (user_id, achievement_id, trigger_value, xp_awarded)
        VALUES (r.user_id, 'discover_rising_star_' || p_board_type, (v_prev_rank - r.rank), v_rising_xp);
      END IF;
    END IF;

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
        ON CONFLICT DO NOTHING;
        GET DIAGNOSTICS v_audit_inserted = ROW_COUNT;

        IF v_audit_inserted > 0 THEN
          PERFORM award_xp(r.user_id, v_phoenix_xp, 'phoenix_rising', p_board_type,
                           'Phoenix Rising: back on the board (' || p_board_type || ')',
                           TRUE, TRUE);
          INSERT INTO user_achievements (user_id, achievement_id, xp_awarded)
          VALUES (r.user_id, 'discover_phoenix_rising_' || p_board_type, v_phoenix_xp);
        END IF;
      END IF;
    END IF;

    PERFORM maybe_grant_free_rank_shield(r.user_id, p_week_start, p_board_type);

  END LOOP;

  RETURN v_rows_processed;
END;
$function$;
