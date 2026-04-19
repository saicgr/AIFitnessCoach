-- Migration 1953: seed achievement_types rows for all Discover-engagement
-- badges. Four families:
--   1. First-time-tier entries (9 rows: 3 tiers × 3 boards, non-repeatable)
--   2. Persistence badges (36 rows: 4 tiers × 3 milestones × 3 boards, non-repeatable)
--   3. Cumulative weeks-in-tier badges (6 rows: 2 milestones × 3 boards, non-repeatable)
--   4. Repeatable flair (6 rows: rising_star + phoenix_rising, 3 boards each)
--
-- xp_reward on these rows is informational (the actual award amount is issued
-- by award_tier_rewards_for_week via award_xp() — for persistence it reads
-- tier_persistence_xp). Category 'discover' introduces a new value — no CHECK
-- constraint exists on category so no constraint bump needed.
--
-- sort_order: 9000-series reserved for discover to avoid collision with the
-- existing 360+ trophies (migration 162).

DO $$
DECLARE
  v_board TEXT;
  v_tier TEXT;
  v_weeks INT;
  v_tier_level INT;
  v_persistence_name TEXT;
  v_persistence_rarity TEXT;
  v_persistence_icon TEXT;
  v_xp_mult NUMERIC;
BEGIN
  FOREACH v_board IN ARRAY ARRAY['xp','volume','streaks'] LOOP
    -- Volume + Streaks boards pay 60% of headline XP amounts (see plan §Risks)
    v_xp_mult := CASE v_board WHEN 'xp' THEN 1.0 ELSE 0.6 END;

    ----------------------------------------------------------------
    -- 1. First-time-tier entries (one-shot for each board)
    ----------------------------------------------------------------
    INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, rarity, xp_reward, is_repeatable, sort_order)
    VALUES
      ('discover_breakthrough_top10_' || v_board,
       'Breakthrough',
       'First time reaching Top 10% on the ' || v_board || ' leaderboard',
       'discover', '🎯', 'silver', 2, 'rare',
       ROUND(1000 * v_xp_mult)::INT, FALSE, 9000),
      ('discover_rarefied_air_top5_' || v_board,
       'Rarefied Air',
       'First time reaching Top 5% on the ' || v_board || ' leaderboard',
       'discover', '💎', 'gold', 3, 'epic',
       ROUND(2500 * v_xp_mult)::INT, FALSE, 9010),
      ('discover_legend_born_top1_' || v_board,
       'Legend Born',
       'First time reaching Top 1% on the ' || v_board || ' leaderboard',
       'discover', '👑', 'platinum', 4, 'legendary',
       ROUND(5000 * v_xp_mult)::INT, FALSE, 9020)
    ON CONFLICT (id) DO NOTHING;

    ----------------------------------------------------------------
    -- 2. Persistence badges — 4 tiers × 3 milestones
    ----------------------------------------------------------------
    FOREACH v_tier IN ARRAY ARRAY['top1','top5','top10','top25'] LOOP
      v_tier_level := CASE v_tier
        WHEN 'top1' THEN 4 WHEN 'top5' THEN 3 WHEN 'top10' THEN 2 ELSE 1 END;

      FOREACH v_weeks IN ARRAY ARRAY[3,5,10] LOOP
        v_persistence_name := CASE v_weeks
          WHEN 3 THEN 'Podium Hat-Trick'
          WHEN 5 THEN 'Iron Throne'
          WHEN 10 THEN 'Immortal' END;
        v_persistence_rarity := CASE v_weeks
          WHEN 3 THEN 'rare'
          WHEN 5 THEN 'epic'
          WHEN 10 THEN 'legendary' END;
        v_persistence_icon := CASE v_weeks
          WHEN 3 THEN '🥉' WHEN 5 THEN '👑' WHEN 10 THEN '⚜️' END;

        INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, rarity, xp_reward, is_repeatable, sort_order)
        VALUES (
          'discover_' || CASE v_weeks WHEN 3 THEN 'podium_hattrick' WHEN 5 THEN 'iron_throne' WHEN 10 THEN 'immortal' END
            || '_' || v_tier || '_' || v_weeks || 'w_' || v_board,
          v_persistence_name || ' ' || v_weeks || 'w',
          'Held ' || v_tier || ' for ' || v_weeks || ' consecutive weeks on ' || v_board,
          'discover', v_persistence_icon,
          CASE v_weeks WHEN 3 THEN 'silver' WHEN 5 THEN 'gold' WHEN 10 THEN 'platinum' END,
          v_tier_level, v_persistence_rarity,
          (SELECT xp FROM tier_persistence_xp
            WHERE board_type = v_board AND tier = v_tier AND consecutive_weeks = v_weeks),
          FALSE, 9100 + v_tier_level * 10 + v_weeks
        )
        ON CONFLICT (id) DO NOTHING;
      END LOOP;
    END LOOP;

    ----------------------------------------------------------------
    -- 3. Cumulative weeks-in-tier (lifetime counters)
    ----------------------------------------------------------------
    INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, rarity, xp_reward, is_repeatable, sort_order)
    VALUES
      ('discover_consistency_king_top10_10w_' || v_board,
       'Consistency King',
       '10 total weeks in Top 10% on ' || v_board,
       'discover', '🏆', 'gold', 3, 'epic',
       ROUND(3000 * v_xp_mult)::INT, FALSE, 9300),
      ('discover_prestige_frame_top10_25w_' || v_board,
       'Prestige',
       '25 total weeks in Top 10% on ' || v_board,
       'discover', '🏵️', 'platinum', 4, 'legendary',
       ROUND(10000 * v_xp_mult)::INT, FALSE, 9310)
    ON CONFLICT (id) DO NOTHING;

    ----------------------------------------------------------------
    -- 4. Repeatable flair badges (1-week visibility, multiple earns OK)
    ----------------------------------------------------------------
    INSERT INTO achievement_types (id, name, description, category, icon, tier, tier_level, rarity, xp_reward, is_repeatable, sort_order)
    VALUES
      ('discover_rising_star_' || v_board,
       'Rising Star',
       'Rose 5+ ranks from the previous week on ' || v_board,
       'discover', '🚀', 'silver', 2, 'rare',
       ROUND(300 * v_xp_mult)::INT, TRUE, 9400),
      ('discover_phoenix_rising_' || v_board,
       'Phoenix Rising',
       'Returned to Top 25% after 2+ weeks off ' || v_board,
       'discover', '🔥', 'gold', 3, 'epic',
       ROUND(500 * v_xp_mult)::INT, TRUE, 9410)
    ON CONFLICT (id) DO NOTHING;

  END LOOP;
END $$;
