-- ============================================================================
-- Migration 1931: Cost-realistic merch schedule + engagement notifications
-- ============================================================================
-- Why:
--   - L75 shaker at 3% user reach = ~73% of total merch cost at 1M users
--     -> Kill L75 merch, replace with pure digital prestige
--   - First physical reward moves to L50 as a Sticker Pack (~$3/unit, widely
--     reachable, becomes free marketing on user's laptops/bottles)
--   - L100 T-shirt onward unchanged
--
-- Changes:
--   1. Widen merch_type CHECK to include 'sticker_pack'
--   2. Update merch_type_for_level(): L50 = sticker_pack, L75 = NULL (no merch),
--      L100 t_shirt, L150 hoodie, L200 full_merch_kit, L250 signed_premium_kit
--   3. distribute_level_rewards() uses the new merch_type_for_level
--   4. Track last merch nudge sent per user (for push/email dedup)
-- ============================================================================

-- Widen merch_type check
ALTER TABLE merch_claims DROP CONSTRAINT IF EXISTS merch_claims_merch_type_check;
ALTER TABLE merch_claims
  ADD CONSTRAINT merch_claims_merch_type_check
  CHECK (merch_type IS NULL OR merch_type IN (
    'sticker_pack',
    'shaker_bottle',
    't_shirt',
    'hoodie',
    'full_merch_kit',
    'signed_premium_kit'
  ));


-- Update merch_type_for_level
CREATE OR REPLACE FUNCTION merch_type_for_level(p_level INT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN CASE p_level
    WHEN 50  THEN 'sticker_pack'
    WHEN 100 THEN 't_shirt'
    WHEN 150 THEN 'hoodie'
    WHEN 200 THEN 'full_merch_kit'
    WHEN 250 THEN 'signed_premium_kit'
    ELSE NULL
  END;
END;
$$;


-- Track last merch nudge sent (for "close to milestone" dedup)
ALTER TABLE user_xp
  ADD COLUMN IF NOT EXISTS last_merch_nudge_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS last_merch_nudge_level INT;

COMMENT ON COLUMN user_xp.last_merch_nudge_at IS
'Timestamp of last merch-milestone proximity nudge (push or email). Used to dedupe engagement notifications to at most 1/day.';


-- For finding merch-proximity candidates cheaply
CREATE INDEX IF NOT EXISTS idx_user_xp_level_merch_nudge
  ON user_xp(current_level, last_merch_nudge_at)
  WHERE current_level BETWEEN 97 AND 99
     OR current_level BETWEEN 147 AND 149
     OR current_level BETWEEN 197 AND 199
     OR current_level BETWEEN 247 AND 249;
