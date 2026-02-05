-- ============================================================================
-- Migration 231: Level-Up Rewards Distribution
-- ============================================================================
-- This migration adds automatic reward distribution when users level up.
-- Rewards are given based on the new level achieved.
-- ============================================================================

-- Drop the old award_xp function since we're changing its return type
DROP FUNCTION IF EXISTS award_xp(UUID, INT, TEXT, TEXT, TEXT, BOOLEAN);

-- ============================================================================
-- Function to distribute level-up rewards
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
BEGIN
  -- Loop through each new level achieved
  FOR v_level IN (p_old_level + 1)..p_new_level LOOP
    v_reward := NULL;

    -- ====================================================================
    -- REWARD SCHEDULE BY LEVEL
    -- ====================================================================

    -- Milestone levels get special rewards
    IF v_level IN (5, 10, 15, 20, 25, 30, 40, 50, 60, 70, 80, 90, 100) THEN
      -- Milestone levels: Fitness Crate
      PERFORM add_consumable(p_user_id, 'fitness_crate', 1);
      v_reward := jsonb_build_object(
        'level', v_level,
        'type', 'fitness_crate',
        'quantity', 1,
        'description', 'Milestone Reward: Fitness Crate'
      );

    ELSIF v_level % 10 = 3 OR v_level % 10 = 8 THEN
      -- Levels ending in 3 or 8: Streak Shield
      -- (Levels 3, 8, 13, 18, 23, 28, etc.)
      PERFORM add_consumable(p_user_id, 'streak_shield', 1);
      v_reward := jsonb_build_object(
        'level', v_level,
        'type', 'streak_shield',
        'quantity', 1,
        'description', 'Level Up Reward: Streak Shield'
      );

    ELSIF v_level % 10 = 6 THEN
      -- Levels ending in 6: 2x XP Token
      -- (Levels 6, 16, 26, 36, etc.)
      PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
      v_reward := jsonb_build_object(
        'level', v_level,
        'type', 'xp_token_2x',
        'quantity', 1,
        'description', 'Level Up Reward: 2x XP Token'
      );
    END IF;

    -- Add premium crate at major milestones (every 25 levels)
    IF v_level IN (25, 50, 75, 100, 125, 150, 175, 200, 225, 250) THEN
      PERFORM add_consumable(p_user_id, 'premium_crate', 1);
      v_reward := COALESCE(v_reward, '{}'::JSONB) || jsonb_build_object(
        'bonus_type', 'premium_crate',
        'bonus_quantity', 1,
        'bonus_description', 'Major Milestone: Premium Crate'
      );
    END IF;

    -- Record the reward if any was given
    IF v_reward IS NOT NULL THEN
      v_rewards := v_rewards || v_reward;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'levels_gained', p_new_level - p_old_level,
    'rewards', v_rewards
  );
END;
$$;

-- ============================================================================
-- Update award_xp to call distribute_level_rewards on level up
-- ============================================================================
CREATE OR REPLACE FUNCTION award_xp(
    p_user_id UUID,
    p_xp_amount INT,
    p_source TEXT,
    p_source_id TEXT DEFAULT NULL,
    p_description TEXT DEFAULT NULL,
    p_is_verified BOOLEAN DEFAULT false
) RETURNS JSONB AS $$
DECLARE
    v_user_xp user_xp;
    v_new_total BIGINT;
    v_level_info RECORD;
    v_trust_level INT;
    v_xp_multiplier DECIMAL := 1.0;
    v_old_level INT;
    v_new_level INT;
    v_level_up_rewards JSONB;
    v_2x_until TIMESTAMPTZ;
BEGIN
    -- Check for active 2x XP token
    SELECT active_2x_token_until INTO v_2x_until
    FROM user_xp WHERE user_id = p_user_id;

    IF v_2x_until IS NOT NULL AND v_2x_until > NOW() THEN
        v_xp_multiplier := 2.0;
    END IF;

    -- Get current trust level and level
    SELECT COALESCE(trust_level, 1), COALESCE(current_level, 1)
    INTO v_trust_level, v_old_level
    FROM user_xp WHERE user_id = p_user_id;

    -- Apply trust level multiplier (anti-fraud)
    -- Trust level 1: 50% XP (new users)
    -- Trust level 2: 100% XP (verified)
    -- Trust level 3: 100% XP + bonus for verified (trusted)
    IF v_trust_level = 1 THEN
        v_xp_multiplier := v_xp_multiplier * 0.5;
    ELSIF v_trust_level >= 2 AND p_is_verified THEN
        v_xp_multiplier := v_xp_multiplier * 1.2;  -- 20% bonus for verified actions
    END IF;

    -- Insert XP transaction
    INSERT INTO xp_transactions (user_id, xp_amount, source, source_id, description, is_verified)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT, p_source, p_source_id, p_description, p_is_verified);

    -- Update or insert user_xp record
    INSERT INTO user_xp (user_id, total_xp)
    VALUES (p_user_id, FLOOR(p_xp_amount * v_xp_multiplier)::INT)
    ON CONFLICT (user_id) DO UPDATE
    SET total_xp = user_xp.total_xp + FLOOR(p_xp_amount * v_xp_multiplier)::INT,
        updated_at = NOW();

    -- Get new total XP
    SELECT total_xp INTO v_new_total FROM user_xp WHERE user_id = p_user_id;

    -- Calculate new level info
    SELECT * INTO v_level_info FROM calculate_level_from_xp(v_new_total);

    -- Update level info
    UPDATE user_xp
    SET current_level = v_level_info.level,
        title = v_level_info.title,
        xp_to_next_level = v_level_info.xp_for_next,
        xp_in_current_level = v_level_info.xp_in_level,
        prestige_level = v_level_info.prestige,
        updated_at = NOW()
    WHERE user_id = p_user_id
    RETURNING * INTO v_user_xp;

    v_new_level := v_user_xp.current_level;

    -- Check for level up and distribute rewards
    v_level_up_rewards := NULL;
    IF v_new_level > COALESCE(v_old_level, 1) THEN
        v_level_up_rewards := distribute_level_rewards(p_user_id, COALESCE(v_old_level, 1), v_new_level);
    END IF;

    -- Return full result as JSONB
    RETURN jsonb_build_object(
        'id', v_user_xp.id,
        'user_id', v_user_xp.user_id,
        'total_xp', v_user_xp.total_xp,
        'current_level', v_user_xp.current_level,
        'xp_to_next_level', v_user_xp.xp_to_next_level,
        'xp_in_current_level', v_user_xp.xp_in_current_level,
        'prestige_level', v_user_xp.prestige_level,
        'title', v_user_xp.title,
        'trust_level', v_user_xp.trust_level,
        'xp_awarded', FLOOR(p_xp_amount * v_xp_multiplier)::INT,
        'multiplier_applied', v_xp_multiplier,
        'leveled_up', (v_new_level > COALESCE(v_old_level, 1)),
        'old_level', v_old_level,
        'new_level', v_new_level,
        'level_up_rewards', v_level_up_rewards
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Comments
-- ============================================================================
COMMENT ON FUNCTION distribute_level_rewards IS
'Distributes consumable rewards when a user levels up. Returns JSONB with reward details.';

COMMENT ON FUNCTION award_xp IS
'Awards XP to a user, handles level calculations, and now returns JSONB with level-up rewards.';

-- ============================================================================
-- Grant execute permissions
-- ============================================================================
GRANT EXECUTE ON FUNCTION distribute_level_rewards TO authenticated;
GRANT EXECUTE ON FUNCTION distribute_level_rewards TO service_role;
