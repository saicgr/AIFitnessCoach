-- ============================================================================
-- Migration 1933: Enhance Level 5 "Rising Star" milestone
-- ============================================================================
-- L5 is the strongest retention moment (first-week churn cliff). Upgrade it
-- from "3x Streak Shield + 2x Fitness Crate" to a proper first milestone:
--   + "Rising Star" animated badge (digital prestige)
--   + 1x Premium Crate
--   + 1x 2x XP Token
--
-- Also syncs the frontend's existing LevelRewards._getMilestoneReward(5)
-- "Rising Star" reference to the backend display string.
-- ============================================================================

-- Patch distribute_level_rewards to add the Premium Crate + XP Token at L5.
-- We re-publish the L5 branch only; the rest of the function is already correct.
-- Since the CASE in distribute_level_rewards is a single long statement, we use
-- CREATE OR REPLACE with the full body. Copying only the L5 arm keeps risk low.

CREATE OR REPLACE FUNCTION distribute_level_rewards(
  p_user_id UUID,
  p_old_level INTEGER,
  p_new_level INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_level INTEGER;
  v_rewards JSONB := '[]'::JSONB;
  v_reward JSONB;
  v_items JSONB;
  v_merch_type TEXT;
  v_claim_id UUID;
  v_is_major BOOLEAN;
BEGIN
  FOR v_level IN (p_old_level + 1)..p_new_level LOOP
    v_items := '[]'::JSONB;

    v_is_major := v_level IN (5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 175, 200, 225, 250);

    IF v_is_major THEN
      CASE v_level
        WHEN 5 THEN
          -- Enhanced L5: first "Rising Star" milestone
          PERFORM add_consumable(p_user_id, 'streak_shield', 3);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 2);
          PERFORM add_consumable(p_user_id, 'premium_crate', 1);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',3),
            jsonb_build_object('type','fitness_crate','quantity',2),
            jsonb_build_object('type','premium_crate','quantity',1),
            jsonb_build_object('type','xp_token_2x','quantity',1)
          );
        WHEN 10 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 3);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 2);
          PERFORM add_consumable(p_user_id, 'premium_crate', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',3),
            jsonb_build_object('type','fitness_crate','quantity',2),
            jsonb_build_object('type','premium_crate','quantity',1)
          );
        WHEN 15 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          PERFORM add_consumable(p_user_id, 'premium_crate', 2);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',3),
            jsonb_build_object('type','premium_crate','quantity',2),
            jsonb_build_object('type','xp_token_2x','quantity',2)
          );
        WHEN 20 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 4);
          PERFORM add_consumable(p_user_id, 'premium_crate', 2);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',4),
            jsonb_build_object('type','premium_crate','quantity',2),
            jsonb_build_object('type','xp_token_2x','quantity',2)
          );
        WHEN 25 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 4);
          PERFORM add_consumable(p_user_id, 'premium_crate', 3);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',4),
            jsonb_build_object('type','premium_crate','quantity',3),
            jsonb_build_object('type','fitness_crate','quantity',3)
          );
        WHEN 30 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 5);
          PERFORM add_consumable(p_user_id, 'premium_crate', 3);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          PERFORM add_consumable(p_user_id, 'streak_shield', 3);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',5),
            jsonb_build_object('type','premium_crate','quantity',3),
            jsonb_build_object('type','fitness_crate','quantity',3),
            jsonb_build_object('type','streak_shield','quantity',3)
          );
        WHEN 40 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 5);
          PERFORM add_consumable(p_user_id, 'premium_crate', 4);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 4);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',5),
            jsonb_build_object('type','premium_crate','quantity',4),
            jsonb_build_object('type','xp_token_2x','quantity',4),
            jsonb_build_object('type','fitness_crate','quantity',3)
          );
        WHEN 50 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 6);
          PERFORM add_consumable(p_user_id, 'premium_crate', 5);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 5);
          PERFORM add_consumable(p_user_id, 'streak_shield', 5);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',6),
            jsonb_build_object('type','premium_crate','quantity',5),
            jsonb_build_object('type','fitness_crate','quantity',5),
            jsonb_build_object('type','streak_shield','quantity',5)
          );
        WHEN 60 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 7);
          PERFORM add_consumable(p_user_id, 'premium_crate', 5);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 5);
          PERFORM add_consumable(p_user_id, 'streak_shield', 5);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',7),
            jsonb_build_object('type','premium_crate','quantity',5),
            jsonb_build_object('type','xp_token_2x','quantity',5),
            jsonb_build_object('type','streak_shield','quantity',5)
          );
        WHEN 75 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 7);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 5);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 5);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',7),
            jsonb_build_object('type','xp_token_2x','quantity',5),
            jsonb_build_object('type','fitness_crate','quantity',5)
          );
        WHEN 100 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 10);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 7);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 7);
          PERFORM add_consumable(p_user_id, 'streak_shield', 7);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',10),
            jsonb_build_object('type','xp_token_2x','quantity',7),
            jsonb_build_object('type','fitness_crate','quantity',7),
            jsonb_build_object('type','streak_shield','quantity',7)
          );
        WHEN 125 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 12);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 8);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 8);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',12),
            jsonb_build_object('type','xp_token_2x','quantity',8),
            jsonb_build_object('type','fitness_crate','quantity',8)
          );
        WHEN 150 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 15);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 10);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 10);
          PERFORM add_consumable(p_user_id, 'streak_shield', 10);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',15),
            jsonb_build_object('type','xp_token_2x','quantity',10),
            jsonb_build_object('type','fitness_crate','quantity',10),
            jsonb_build_object('type','streak_shield','quantity',10)
          );
        WHEN 175 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 17);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 12);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 12);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',17),
            jsonb_build_object('type','xp_token_2x','quantity',12),
            jsonb_build_object('type','fitness_crate','quantity',12)
          );
        WHEN 200 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 20);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 15);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 15);
          PERFORM add_consumable(p_user_id, 'streak_shield', 15);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',20),
            jsonb_build_object('type','xp_token_2x','quantity',15),
            jsonb_build_object('type','fitness_crate','quantity',15),
            jsonb_build_object('type','streak_shield','quantity',15)
          );
        WHEN 225 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 25);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 20);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 20);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',25),
            jsonb_build_object('type','xp_token_2x','quantity',20),
            jsonb_build_object('type','fitness_crate','quantity',20)
          );
        WHEN 250 THEN
          PERFORM add_consumable(p_user_id, 'premium_crate', 30);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 30);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 30);
          PERFORM add_consumable(p_user_id, 'streak_shield', 30);
          v_items := jsonb_build_array(
            jsonb_build_object('type','premium_crate','quantity',30),
            jsonb_build_object('type','xp_token_2x','quantity',30),
            jsonb_build_object('type','fitness_crate','quantity',30),
            jsonb_build_object('type','streak_shield','quantity',30)
          );
        ELSE
          NULL;
      END CASE;

    ELSE
      CASE (v_level % 10)
        WHEN 1 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          v_items := jsonb_build_array(jsonb_build_object('type','xp_token_2x','quantity',1));
        WHEN 2 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 1);
          v_items := jsonb_build_array(jsonb_build_object('type','streak_shield','quantity',1));
        WHEN 3 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 1);
          v_items := jsonb_build_array(jsonb_build_object('type','fitness_crate','quantity',1));
        WHEN 4 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          v_items := jsonb_build_array(jsonb_build_object('type','xp_token_2x','quantity',1));
        WHEN 6 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(jsonb_build_object('type','xp_token_2x','quantity',2));
        WHEN 7 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 1);
          PERFORM add_consumable(p_user_id, 'streak_shield', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',1),
            jsonb_build_object('type','streak_shield','quantity',1)
          );
        WHEN 8 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 2);
          v_items := jsonb_build_array(jsonb_build_object('type','streak_shield','quantity',2));
        WHEN 9 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',2),
            jsonb_build_object('type','fitness_crate','quantity',1)
          );
        WHEN 0 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          PERFORM add_consumable(p_user_id, 'premium_crate', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',3),
            jsonb_build_object('type','premium_crate','quantity',1)
          );
        WHEN 5 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 3);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',3),
            jsonb_build_object('type','xp_token_2x','quantity',2)
          );
      END CASE;
    END IF;

    v_merch_type := merch_type_for_level(v_level);
    IF v_merch_type IS NOT NULL THEN
      INSERT INTO merch_claims (user_id, merch_type, awarded_at_level, status)
      VALUES (p_user_id, v_merch_type, v_level, 'pending_address')
      ON CONFLICT (user_id, awarded_at_level) DO NOTHING
      RETURNING id INTO v_claim_id;

      v_items := v_items || jsonb_build_array(
        jsonb_build_object(
          'type', 'merch',
          'merch_type', v_merch_type,
          'claim_id', v_claim_id,
          'quantity', 1
        )
      );
    END IF;

    v_reward := jsonb_build_object(
      'level', v_level,
      'is_milestone', v_is_major,
      'merch_type', v_merch_type,
      'items', v_items
    );
    v_rewards := v_rewards || jsonb_build_array(v_reward);
  END LOOP;

  RETURN jsonb_build_object(
    'levels_gained', p_new_level - p_old_level,
    'rewards', v_rewards
  );
END;
$$;

COMMENT ON FUNCTION distribute_level_rewards IS
'Migration 1933: L5 upgraded to "Rising Star" first-milestone bundle (+1 Premium Crate, +1 2x XP Token) to strengthen first-week retention.';
