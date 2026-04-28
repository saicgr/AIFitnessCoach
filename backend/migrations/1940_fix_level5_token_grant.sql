-- ============================================================================
-- Migration 1940: Retroactively fix level-5 xp_token_2x grant
-- ============================================================================
-- Problem: migration 1935 (and earlier reward distribution) granted only
-- 1 xp_token_2x at level 5 (Steadfast), but the All-Levels display in the
-- Flutter app advertises "2x 2x XP Token" for level 5. Users who already
-- leveled past 5 received 1 instead of the correct 2.
--
-- Solution:
--   1. Migration 1935 has been updated to grant 2 going forward.
--   2. This migration retroactively adds 1 xp_token_2x to every user who
--      has already reached level 5 or higher, so the running total matches
--      what the UI claims they earned.
--
-- Schema note: user_consumables is row-per-(user_id, item_type) with a
-- `quantity` column (see migration 219). Use add_consumable() rather than
-- a column UPDATE so the row is created if it doesn't exist yet and so we
-- get free RLS / SECURITY DEFINER semantics.
-- ============================================================================

DO $$
DECLARE
  v_user RECORD;
BEGIN
  FOR v_user IN
    SELECT user_id
    FROM user_xp
    WHERE current_level >= 5
  LOOP
    -- add_consumable() upserts: creates the (user_id, 'xp_token_2x') row
    -- with quantity=1 if missing, else increments quantity by the delta.
    PERFORM add_consumable(v_user.user_id, 'xp_token_2x', 1);
  END LOOP;
END $$;

COMMENT ON FUNCTION distribute_level_rewards(UUID, INTEGER, INTEGER) IS
  'Migration 1940: Level 5 (Steadfast) now grants 2 xp_token_2x to match the All-Levels UI; existing level-5+ users were back-filled with +1 token.';
