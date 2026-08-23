-- ============================================================================
-- Migration 2424: Rebalance reward-economy unlock levels (findings #300, #371)
-- ============================================================================
-- Every cosmetic (badges, frames, chat titles, themes, coach voices) and
-- every physical merch tier was gated between Level 5 and Level 250. A
-- Level-3 account after 2-5 days of unusually heavy use is nowhere near any
-- of these thresholds, and Level 50 (the first coach voice, the first merch
-- item) is roughly two orders of magnitude beyond what the account had
-- earned. Live read against `user_xp` confirmed: total_xp 419-547,
-- current_level 3, after 2-5 days of heavy logging.
--
-- Fix: rescale the whole unlock ladder down (roughly /2.5, rounded) so the
-- first tier is reachable in the opening days and the top tier is reachable
-- within a season, while keeping relative ordering/scarcity intact. Coach
-- voices (finding #300) move specifically to Level 15, inside the 10-15
-- range the finding calls a level "a committed user reaches inside a
-- season". Merch thresholds are rescaled the same way via
-- merch_type_for_level, which distribute_level_rewards already calls by
-- level -- no change needed to distribute_level_rewards itself.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Cosmetics catalog: rescale unlock_level (badges, frames, chat_titles,
--    themes). Coach voices get their own explicit target (see finding #300).
-- ----------------------------------------------------------------------------
UPDATE cosmetics SET unlock_level = 2   WHERE id = 'badge_rising_star';
UPDATE cosmetics SET unlock_level = 4   WHERE id = 'badge_iron_will';
UPDATE cosmetics SET unlock_level = 10  WHERE id = 'badge_dedicated';
UPDATE cosmetics SET unlock_level = 20  WHERE id = 'badge_veteran';
UPDATE cosmetics SET unlock_level = 30  WHERE id = 'badge_elite';
UPDATE cosmetics SET unlock_level = 40  WHERE id = 'badge_legend';
UPDATE cosmetics SET unlock_level = 80  WHERE id = 'badge_mythic';
UPDATE cosmetics SET unlock_level = 100 WHERE id = 'badge_transcendent';

UPDATE cosmetics SET unlock_level = 10  WHERE id = 'frame_bronze';
UPDATE cosmetics SET unlock_level = 20  WHERE id = 'frame_silver';
UPDATE cosmetics SET unlock_level = 30  WHERE id = 'frame_gold_holographic';
UPDATE cosmetics SET unlock_level = 40  WHERE id = 'frame_platinum';
UPDATE cosmetics SET unlock_level = 80  WHERE id = 'frame_mythic';

UPDATE cosmetics SET unlock_level = 10  WHERE id = 'title_dedicated';
UPDATE cosmetics SET unlock_level = 20  WHERE id = 'title_veteran';
UPDATE cosmetics SET unlock_level = 30  WHERE id = 'title_elite';
UPDATE cosmetics SET unlock_level = 40  WHERE id = 'title_legend';

UPDATE cosmetics SET unlock_level = 4   WHERE id = 'theme_iron';
UPDATE cosmetics SET unlock_level = 30  WHERE id = 'theme_gold';

UPDATE cosmetics SET unlock_level = 30  WHERE id = 'stats_card_elite';

-- Coach voices (finding #300): explicit reachable-in-a-season target.
UPDATE cosmetics SET unlock_level = 15 WHERE id IN ('coach_voice_chad', 'coach_voice_serena');

-- ----------------------------------------------------------------------------
-- 2. Retroactively grant/backfill cosmetics for users who now qualify under
--    the lowered thresholds (mirrors migration 1936 section 8's backfill).
-- ----------------------------------------------------------------------------
INSERT INTO user_cosmetics (user_id, cosmetic_id, unlocked_at_level)
SELECT u.user_id, c.id, c.unlock_level
FROM user_xp u
CROSS JOIN cosmetics c
WHERE c.is_active = true
  AND c.unlock_level IS NOT NULL
  AND c.unlock_level <= u.current_level
ON CONFLICT (user_id, cosmetic_id) DO NOTHING;

DO $$
DECLARE
  r RECORD;
BEGIN
  FOR r IN
    SELECT DISTINCT user_id FROM user_cosmetics
  LOOP
    PERFORM grant_level_cosmetics(r.user_id, 0, 250);
  END LOOP;
END$$;

-- ----------------------------------------------------------------------------
-- 3. Merch: rescale merch_type_for_level (finding #371 -- "reconsider Level
--    50 as the first physical reward"). Same relative spacing, first tier
--    now Level 20 instead of Level 50.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION merch_type_for_level(p_level INT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN CASE p_level
    WHEN 20  THEN 'sticker_pack'
    WHEN 40  THEN 't_shirt'
    WHEN 60  THEN 'hoodie'
    WHEN 80  THEN 'full_merch_kit'
    WHEN 100 THEN 'signed_premium_kit'
    ELSE NULL
  END;
END;
$$;

-- Backfill merch_claims for users already at/above the new, lower thresholds
-- who leveled up before this migration ran (distribute_level_rewards only
-- fires on the level-up transition, so it never saw these levels as "new").
INSERT INTO merch_claims (user_id, merch_type, awarded_at_level, status)
SELECT u.user_id, m.merch_type, m.lvl, 'pending_address'
FROM user_xp u
CROSS JOIN LATERAL (
  VALUES (20, 'sticker_pack'), (40, 't_shirt'), (60, 'hoodie'),
         (80, 'full_merch_kit'), (100, 'signed_premium_kit')
) AS m(lvl, merch_type)
WHERE u.current_level >= m.lvl
ON CONFLICT (user_id, awarded_at_level) WHERE awarded_at_level IS NOT NULL DO NOTHING;
-- NOTE: ux_merch_claims_user_level is a PARTIAL unique index
-- (WHERE awarded_at_level IS NOT NULL). ON CONFLICT cannot infer a partial
-- index unless the same predicate is repeated here.

-- VERIFY: select id, unlock_level from cosmetics where id in ('coach_voice_chad','coach_voice_serena'); -- expect 15, 15
-- VERIFY: select merch_type_for_level(20), merch_type_for_level(100); -- expect 'sticker_pack', 'signed_premium_kit'
