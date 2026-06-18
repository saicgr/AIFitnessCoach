-- 2262: Fix award_xp 500 on level-up (P0003 "query returned more than one row")
--
-- Root cause:
--   award_xp -> level-up -> distribute_level_rewards -> INSERT INTO level_up_events
--   -> AFTER INSERT trigger level_up_events_grant_cosmetics -> grant_level_cosmetics().
--   grant_level_cosmetics() did:
--       INSERT INTO user_cosmetics (...)
--       SELECT ... FROM eligible e
--       ON CONFLICT (...) DO NOTHING
--       RETURNING cosmetic_id INTO v_cosmetic_id;   -- <-- BUG
--   In PL/pgSQL, a data-modifying `... RETURNING <col> INTO <scalar>` is implicitly
--   single-row: if the statement returns >1 row it raises P0003 (TOO_MANY_ROWS),
--   even without the STRICT keyword. Any level-up that unlocks >=2 cosmetics in one
--   level (unlock_level 10, 25, 50, 75, 100, 200 each have >=2 active cosmetics)
--   therefore threw, and the exception propagated all the way back through the
--   award_xp RPC -> HTTP 500 on POST /api/v1/xp/award-goal-xp and a silent failure
--   in crud_completion._award_workout_complete_xp. So crossing those levels broke
--   XP awards entirely.
--
-- Fix:
--   `v_cosmetic_id` was dead — it was assigned by RETURNING and never read again
--   (the newly-unlocked set is recollected immediately after via array_agg into
--   v_newly_unlocked). Drop the `RETURNING ... INTO` clause (and the now-unused
--   declaration) so the multi-row INSERT just runs. Behavior is otherwise identical.

CREATE OR REPLACE FUNCTION grant_level_cosmetics(
  p_user_id UUID,
  p_old_level INTEGER,
  p_new_level INTEGER
)
RETURNS SETOF TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_newly_unlocked TEXT[];
  v_first_badge TEXT;
  v_first_frame TEXT;
  v_has_equipped_badge BOOLEAN;
  v_has_equipped_frame BOOLEAN;
BEGIN
  -- Find eligible cosmetics and grant them. This INSERT can return MANY rows
  -- (>=2 cosmetics unlock at levels 10/25/50/75/100/200); do NOT assign RETURNING
  -- into a scalar or it raises P0003 "query returned more than one row".
  WITH eligible AS (
    SELECT c.id
    FROM cosmetics c
    WHERE c.is_active = true
      AND c.unlock_level IS NOT NULL
      AND c.unlock_level > p_old_level
      AND c.unlock_level <= p_new_level
  )
  INSERT INTO user_cosmetics (user_id, cosmetic_id, unlocked_at_level)
  SELECT p_user_id, e.id, (SELECT unlock_level FROM cosmetics WHERE id = e.id)
  FROM eligible e
  ON CONFLICT (user_id, cosmetic_id) DO NOTHING;

  -- Collect all newly-owned cosmetic IDs in this range (idempotent)
  SELECT array_agg(uc.cosmetic_id) INTO v_newly_unlocked
  FROM user_cosmetics uc
  JOIN cosmetics c ON c.id = uc.cosmetic_id
  WHERE uc.user_id = p_user_id
    AND c.unlock_level BETWEEN p_old_level + 1 AND p_new_level;

  -- Auto-equip first badge if none equipped
  SELECT EXISTS (
    SELECT 1 FROM user_cosmetics uc
    JOIN cosmetics c ON c.id = uc.cosmetic_id
    WHERE uc.user_id = p_user_id AND uc.is_equipped AND c.type = 'badge'
  ) INTO v_has_equipped_badge;

  IF NOT v_has_equipped_badge THEN
    SELECT uc.cosmetic_id INTO v_first_badge
    FROM user_cosmetics uc
    JOIN cosmetics c ON c.id = uc.cosmetic_id
    WHERE uc.user_id = p_user_id AND c.type = 'badge'
    ORDER BY c.unlock_level DESC NULLS LAST
    LIMIT 1;
    IF v_first_badge IS NOT NULL THEN
      PERFORM equip_cosmetic(p_user_id, v_first_badge);
    END IF;
  END IF;

  -- Auto-equip first frame if none equipped
  SELECT EXISTS (
    SELECT 1 FROM user_cosmetics uc
    JOIN cosmetics c ON c.id = uc.cosmetic_id
    WHERE uc.user_id = p_user_id AND uc.is_equipped AND c.type = 'frame'
  ) INTO v_has_equipped_frame;

  IF NOT v_has_equipped_frame THEN
    SELECT uc.cosmetic_id INTO v_first_frame
    FROM user_cosmetics uc
    JOIN cosmetics c ON c.id = uc.cosmetic_id
    WHERE uc.user_id = p_user_id AND c.type = 'frame'
    ORDER BY c.unlock_level DESC NULLS LAST
    LIMIT 1;
    IF v_first_frame IS NOT NULL THEN
      PERFORM equip_cosmetic(p_user_id, v_first_frame);
    END IF;
  END IF;

  -- Return newly unlocked IDs for the caller to surface in celebration
  RETURN QUERY SELECT unnest(COALESCE(v_newly_unlocked, ARRAY[]::TEXT[]));
END;
$$;
