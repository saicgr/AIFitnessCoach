-- Migration 1952: rank_shield consumable. Clones the streak_shield pattern
-- (migration 219 + 1938) for leaderboard resilience. When a user was in Top
-- 10% last week and falls out this week, the reward engine auto-consumes a
-- rank_shield to preserve their tier-streak counter.
--
-- The shield is PER BOARD (xp / volume / streaks) — a user can be defending
-- XP but not volume. Consumable table doesn't split by board, so the RPC
-- passes 'rank_shield' and the cooldown table tracks the board separately.
-- Cap inventory at 4 so passive users don't ever-green into infinite shields.

-- Extend user_consumables CHECK to include 'rank_shield'
ALTER TABLE user_consumables DROP CONSTRAINT IF EXISTS user_consumables_item_type_check;
ALTER TABLE user_consumables ADD CONSTRAINT user_consumables_item_type_check
  CHECK (item_type IN ('streak_shield', 'xp_token_2x', 'fitness_crate', 'premium_crate', 'rank_shield'));

-- Per-board cooldown tracker so we grant at most one free rank_shield per 4
-- weeks per board.
CREATE TABLE IF NOT EXISTS user_rank_shield_cooldowns (
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  board_type TEXT NOT NULL CHECK (board_type IN ('xp', 'volume', 'streaks')),
  last_free_grant_week DATE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (user_id, board_type)
);

ALTER TABLE user_rank_shield_cooldowns ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS ursc_select_own ON user_rank_shield_cooldowns;
CREATE POLICY ursc_select_own ON user_rank_shield_cooldowns FOR SELECT USING (auth.uid() = user_id);
DROP POLICY IF EXISTS ursc_service_write ON user_rank_shield_cooldowns;
CREATE POLICY ursc_service_write ON user_rank_shield_cooldowns FOR ALL TO service_role USING (true) WITH CHECK (true);
GRANT SELECT ON user_rank_shield_cooldowns TO authenticated;
GRANT ALL ON user_rank_shield_cooldowns TO service_role;


-- ─── maybe_grant_free_rank_shield ──────────────────────────────────────────
-- Called per-active-user at the end of the weekly reward run. Grants one
-- shield if: (a) user has <4 shields already in inventory, AND (b) they
-- haven't been granted one in the last 28 days for this board.
CREATE OR REPLACE FUNCTION maybe_grant_free_rank_shield(
  p_user_id UUID,
  p_week_start DATE,
  p_board_type TEXT
) RETURNS INT
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_last DATE;
  v_current_qty INT;
BEGIN
  -- Read cooldown
  SELECT last_free_grant_week INTO v_last
    FROM user_rank_shield_cooldowns
   WHERE user_id = p_user_id AND board_type = p_board_type;

  -- Respect cooldown
  IF v_last IS NOT NULL AND v_last > p_week_start - INTERVAL '28 days' THEN
    RETURN 0;
  END IF;

  -- Inventory cap — never stack more than 4 shields regardless of board
  SELECT COALESCE(quantity, 0) INTO v_current_qty
    FROM user_consumables
   WHERE user_id = p_user_id AND item_type = 'rank_shield';

  IF v_current_qty >= 4 THEN
    -- Still mark cooldown so a dormant user doesn't grant-on-wake
    INSERT INTO user_rank_shield_cooldowns (user_id, board_type, last_free_grant_week)
    VALUES (p_user_id, p_board_type, p_week_start)
    ON CONFLICT (user_id, board_type) DO UPDATE
      SET last_free_grant_week = EXCLUDED.last_free_grant_week,
          updated_at = NOW();
    RETURN 0;
  END IF;

  -- Grant
  PERFORM add_consumable(p_user_id, 'rank_shield'::VARCHAR, 1);

  -- Mark cooldown
  INSERT INTO user_rank_shield_cooldowns (user_id, board_type, last_free_grant_week)
  VALUES (p_user_id, p_board_type, p_week_start)
  ON CONFLICT (user_id, board_type) DO UPDATE
    SET last_free_grant_week = EXCLUDED.last_free_grant_week,
        updated_at = NOW();

  RETURN 1;
END;
$$;

GRANT EXECUTE ON FUNCTION maybe_grant_free_rank_shield(UUID, DATE, TEXT) TO service_role;


-- ─── One-time seed: every leaderboard-visible user gets 1 starter shield ───
-- Idempotent: uses add_consumable, existing users with inventory just get +1
-- (capped at 4 via the next auto-grant anyway). Skip the cap check on seed
-- because 1 is safely below 4 for any fresh account.
INSERT INTO user_consumables (user_id, item_type, quantity)
SELECT u.id, 'rank_shield', 1
  FROM users u
 WHERE u.show_on_leaderboard = TRUE
ON CONFLICT (user_id, item_type) DO UPDATE
  SET quantity = LEAST(user_consumables.quantity + 1, 4),
      updated_at = NOW();
