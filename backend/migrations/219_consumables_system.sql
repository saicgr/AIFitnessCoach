-- ============================================================================
-- Migration 219: Consumables & Rewards System
-- ============================================================================
-- This migration creates the consumables inventory system for XP items
-- like streak shields, 2x XP tokens, and crates.
-- ============================================================================

-- Create the user_consumables table
CREATE TABLE IF NOT EXISTS user_consumables (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_type VARCHAR(50) NOT NULL CHECK (item_type IN (
    'streak_shield',
    'xp_token_2x',
    'fitness_crate',
    'premium_crate'
  )),
  quantity INTEGER DEFAULT 0 CHECK (quantity >= 0),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),

  -- Each user can only have one record per item type
  UNIQUE(user_id, item_type)
);

-- Add 2x XP token activation tracking to user_xp (if not exists)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'user_xp' AND column_name = 'active_2x_token_until'
  ) THEN
    ALTER TABLE user_xp ADD COLUMN active_2x_token_until TIMESTAMPTZ;
  END IF;
END $$;

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_user_consumables_user_id
ON user_consumables(user_id);

CREATE INDEX IF NOT EXISTS idx_user_consumables_item_type
ON user_consumables(user_id, item_type);

-- Enable RLS
ALTER TABLE user_consumables ENABLE ROW LEVEL SECURITY;

-- RLS Policies
DROP POLICY IF EXISTS "Users can view own consumables" ON user_consumables;
CREATE POLICY "Users can view own consumables"
ON user_consumables
FOR SELECT
USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Service can manage consumables" ON user_consumables;
CREATE POLICY "Service can manage consumables"
ON user_consumables
FOR ALL
USING (true)
WITH CHECK (true);

-- Grant access
GRANT SELECT ON user_consumables TO authenticated;
GRANT ALL ON user_consumables TO service_role;

-- ============================================================================
-- Function to initialize user consumables (called on first XP action)
-- ============================================================================
CREATE OR REPLACE FUNCTION init_user_consumables(p_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Insert default consumables if not exist
  INSERT INTO user_consumables (user_id, item_type, quantity)
  VALUES
    (p_user_id, 'streak_shield', 3),     -- Start with 3 shields
    (p_user_id, 'xp_token_2x', 1),        -- Start with 1 token
    (p_user_id, 'fitness_crate', 0),
    (p_user_id, 'premium_crate', 0)
  ON CONFLICT (user_id, item_type) DO NOTHING;
END;
$$;

-- ============================================================================
-- Function to get user consumables
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_consumables(p_user_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_result JSONB;
BEGIN
  -- Initialize if needed
  PERFORM init_user_consumables(p_user_id);

  -- Get all consumables
  SELECT jsonb_object_agg(item_type, quantity)
  INTO v_result
  FROM user_consumables
  WHERE user_id = p_user_id;

  RETURN COALESCE(v_result, '{}'::JSONB);
END;
$$;

-- ============================================================================
-- Function to add consumables
-- ============================================================================
CREATE OR REPLACE FUNCTION add_consumable(
  p_user_id UUID,
  p_item_type VARCHAR(50),
  p_quantity INTEGER
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_new_quantity INTEGER;
BEGIN
  -- Ensure record exists
  PERFORM init_user_consumables(p_user_id);

  -- Add quantity
  UPDATE user_consumables
  SET quantity = quantity + p_quantity,
      updated_at = NOW()
  WHERE user_id = p_user_id AND item_type = p_item_type
  RETURNING quantity INTO v_new_quantity;

  RETURN COALESCE(v_new_quantity, 0);
END;
$$;

-- ============================================================================
-- Function to use (decrement) a consumable
-- ============================================================================
CREATE OR REPLACE FUNCTION use_consumable(
  p_user_id UUID,
  p_item_type VARCHAR(50)
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_quantity INTEGER;
BEGIN
  -- Check current quantity
  SELECT quantity INTO v_current_quantity
  FROM user_consumables
  WHERE user_id = p_user_id AND item_type = p_item_type;

  IF v_current_quantity IS NULL OR v_current_quantity < 1 THEN
    RETURN FALSE;
  END IF;

  -- Decrement
  UPDATE user_consumables
  SET quantity = quantity - 1,
      updated_at = NOW()
  WHERE user_id = p_user_id AND item_type = p_item_type;

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- Function to activate 2x XP token
-- ============================================================================
CREATE OR REPLACE FUNCTION activate_2x_token(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_used BOOLEAN;
BEGIN
  -- Try to use the token
  SELECT use_consumable(p_user_id, 'xp_token_2x') INTO v_used;

  IF NOT v_used THEN
    RETURN FALSE;
  END IF;

  -- Set activation period (24 hours)
  UPDATE user_xp
  SET active_2x_token_until = NOW() + INTERVAL '24 hours'
  WHERE user_id = p_user_id;

  RETURN TRUE;
END;
$$;

-- ============================================================================
-- Function to check if 2x XP is active
-- ============================================================================
CREATE OR REPLACE FUNCTION is_2x_xp_active(p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_active_until TIMESTAMPTZ;
BEGIN
  SELECT active_2x_token_until INTO v_active_until
  FROM user_xp
  WHERE user_id = p_user_id;

  RETURN v_active_until IS NOT NULL AND v_active_until > NOW();
END;
$$;

-- ============================================================================
-- Function to award level-up consumables
-- Call this when user levels up
-- ============================================================================
CREATE OR REPLACE FUNCTION award_level_up_consumables(
  p_user_id UUID,
  p_new_level INTEGER
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_rewards JSONB := '{}'::JSONB;
BEGIN
  -- Ensure consumables exist
  PERFORM init_user_consumables(p_user_id);

  -- Odd levels: +1 Streak Shield
  IF p_new_level % 2 = 1 THEN
    PERFORM add_consumable(p_user_id, 'streak_shield', 1);
    v_rewards := v_rewards || '{"streak_shield": 1}'::JSONB;
  END IF;

  -- Even levels: +1 2x XP Token
  IF p_new_level % 2 = 0 THEN
    PERFORM add_consumable(p_user_id, 'xp_token_2x', 1);
    v_rewards := v_rewards || '{"xp_token_2x": 1}'::JSONB;
  END IF;

  -- Every 5 levels: +1 Fitness Crate
  IF p_new_level % 5 = 0 THEN
    PERFORM add_consumable(p_user_id, 'fitness_crate', 1);
    v_rewards := v_rewards || '{"fitness_crate": 1}'::JSONB;
  END IF;

  -- Every 10 levels: +1 Premium Crate
  IF p_new_level % 10 = 0 THEN
    PERFORM add_consumable(p_user_id, 'premium_crate', 1);
    v_rewards := v_rewards || '{"premium_crate": 1}'::JSONB;
  END IF;

  RETURN v_rewards;
END;
$$;

-- Add comments
COMMENT ON TABLE user_consumables IS 'Inventory of consumable items: streak shields, 2x XP tokens, and crates';
COMMENT ON COLUMN user_consumables.item_type IS 'Type of consumable: streak_shield, xp_token_2x, fitness_crate, premium_crate';
COMMENT ON COLUMN user_consumables.quantity IS 'Current quantity of this item owned by the user';
