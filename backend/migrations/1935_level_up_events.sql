-- ============================================================================
-- Migration 1935: Persist level-up events + retroactive celebration
-- ============================================================================
-- Problem: if a user misses the in-app celebration dialog (backgrounded app,
-- network blip, dismissed too fast), they never see WHICH level their new
-- consumables came from. The consumables themselves are safe in user_consumables,
-- but the moment is lost.
--
-- Solution: persist every level-up as a row. Frontend shows a "You leveled up!"
-- banner for any unacknowledged events, user taps to replay the celebration.
-- ============================================================================

CREATE TABLE IF NOT EXISTS level_up_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  level_reached INT NOT NULL CHECK (level_reached BETWEEN 2 AND 250),
  is_milestone BOOLEAN NOT NULL DEFAULT false,
  merch_type TEXT,  -- copy of merch_type_for_level, if any
  rewards_snapshot JSONB NOT NULL DEFAULT '[]'::JSONB,  -- items array from distribute_level_rewards
  acknowledged_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_level_up_events_user_unacked
  ON level_up_events(user_id, created_at DESC)
  WHERE acknowledged_at IS NULL;

-- RLS
ALTER TABLE level_up_events ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS level_up_events_select_own ON level_up_events;
CREATE POLICY level_up_events_select_own ON level_up_events
  FOR SELECT USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS level_up_events_update_own ON level_up_events;
CREATE POLICY level_up_events_update_own ON level_up_events
  FOR UPDATE USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS level_up_events_service_insert ON level_up_events;
CREATE POLICY level_up_events_service_insert ON level_up_events
  FOR INSERT TO service_role WITH CHECK (true);

COMMENT ON TABLE level_up_events IS
'Migration 1935: One row per level gained. Shown as a retroactive celebration banner so users never miss a level-up reward, even if they missed the in-app dialog.';


-- ============================================================================
-- Patch distribute_level_rewards to also write event rows
-- ============================================================================

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
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 5);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          PERFORM add_consumable(p_user_id, 'premium_crate', 2);
          PERFORM add_consumable(p_user_id, 'streak_shield', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','xp_token_2x','quantity',5),
            jsonb_build_object('type','fitness_crate','quantity',3),
            jsonb_build_object('type','premium_crate','quantity',2),
            jsonb_build_object('type','streak_shield','quantity',2)
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
        ELSE NULL;
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
          PERFORM add_consumable(p_user_id, 'fitness_crate', 2);
          PERFORM add_consumable(p_user_id, 'streak_shield', 1);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',2),
            jsonb_build_object('type','streak_shield','quantity',1),
            jsonb_build_object('type','xp_token_2x','quantity',1)
          );
        WHEN 4 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          v_items := jsonb_build_array(jsonb_build_object('type','xp_token_2x','quantity',1));
        WHEN 6 THEN
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(jsonb_build_object('type','xp_token_2x','quantity',2));
        WHEN 7 THEN
          PERFORM add_consumable(p_user_id, 'fitness_crate', 2);
          PERFORM add_consumable(p_user_id, 'streak_shield', 2);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
          PERFORM add_consumable(p_user_id, 'premium_crate', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',2),
            jsonb_build_object('type','streak_shield','quantity',2),
            jsonb_build_object('type','xp_token_2x','quantity',1),
            jsonb_build_object('type','premium_crate','quantity',1)
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
        jsonb_build_object('type','merch','merch_type',v_merch_type,'claim_id',v_claim_id,'quantity',1)
      );
    END IF;

    -- NEW: persist the level-up as an event so the user can replay it
    INSERT INTO level_up_events (user_id, level_reached, is_milestone, merch_type, rewards_snapshot)
    VALUES (p_user_id, v_level, v_is_major, v_merch_type, v_items);

    v_reward := jsonb_build_object(
      'level', v_level,
      'is_milestone', v_is_major,
      'merch_type', v_merch_type,
      'items', v_items
    );
    v_rewards := v_rewards || jsonb_build_array(v_reward);
  END LOOP;

  RETURN jsonb_build_object('levels_gained', p_new_level - p_old_level, 'rewards', v_rewards);
END;
$$;


-- ============================================================================
-- RPC: acknowledge (mark all unseen level-ups as seen after user views them)
-- ============================================================================
CREATE OR REPLACE FUNCTION acknowledge_level_up_events(
  p_user_id UUID,
  p_event_ids UUID[] DEFAULT NULL
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INT;
BEGIN
  IF p_event_ids IS NULL THEN
    -- Acknowledge all
    UPDATE level_up_events
    SET acknowledged_at = NOW()
    WHERE user_id = p_user_id AND acknowledged_at IS NULL;
  ELSE
    UPDATE level_up_events
    SET acknowledged_at = NOW()
    WHERE user_id = p_user_id AND id = ANY(p_event_ids) AND acknowledged_at IS NULL;
  END IF;
  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;

GRANT SELECT, UPDATE ON level_up_events TO authenticated;
GRANT ALL ON level_up_events TO service_role;
GRANT EXECUTE ON FUNCTION acknowledge_level_up_events(UUID, UUID[]) TO authenticated, service_role;
