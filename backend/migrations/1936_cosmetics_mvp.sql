-- ============================================================================
-- Migration 1936: Cosmetics MVP — unlock + render real badges & frames
-- ============================================================================
-- Turns the "coming soon" labels into actually-unlocked, actually-rendered
-- digital cosmetics. The catalog lives in `cosmetics`; per-user unlocks in
-- `user_cosmetics`. At most one cosmetic of each `type` can be equipped.
--
-- Covered in this MVP (rendered on frontend):
--   - badges (emoji + colored pill, shown on profile header + inventory)
--   - frames (colored circular border around avatar)
--   - chat_titles (rank text stored — rendering next to username is phase 2)
--
-- Deferred (seeded but not rendered yet):
--   - themes (accent color packs)
--   - coach_voice (TTS voice packs — needs backend TTS swap)
--   - stats_card (Share Gallery templates)
-- ============================================================================


-- ============================================================================
-- 1. cosmetics catalog
-- ============================================================================
CREATE TABLE IF NOT EXISTS cosmetics (
  id TEXT PRIMARY KEY,                       -- e.g. 'badge_rising_star'
  type TEXT NOT NULL CHECK (type IN ('badge','frame','theme','chat_title','coach_voice','stats_card')),
  display_name TEXT NOT NULL,
  description TEXT,
  emoji TEXT,                                -- badge or chat_title visual marker
  color_hex TEXT,                            -- primary color (e.g. '#FFD700')
  gradient_hex TEXT,                         -- optional secondary color for gradients
  tier TEXT,                                 -- 'bronze','silver','gold','holographic','iron','special'
  is_animated BOOLEAN NOT NULL DEFAULT false,
  unlock_level INT,                          -- auto-unlocked at this level (NULL = other source)
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);


-- ============================================================================
-- 2. user_cosmetics — ownership + equip state
-- ============================================================================
CREATE TABLE IF NOT EXISTS user_cosmetics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cosmetic_id TEXT NOT NULL REFERENCES cosmetics(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlocked_at_level INT,
  is_equipped BOOLEAN NOT NULL DEFAULT false,
  UNIQUE (user_id, cosmetic_id)
);

CREATE INDEX IF NOT EXISTS idx_user_cosmetics_user ON user_cosmetics(user_id);
CREATE INDEX IF NOT EXISTS idx_user_cosmetics_equipped
  ON user_cosmetics(user_id) WHERE is_equipped = true;

ALTER TABLE user_cosmetics ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS user_cosmetics_select_own ON user_cosmetics;
CREATE POLICY user_cosmetics_select_own ON user_cosmetics
  FOR SELECT USING ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS user_cosmetics_update_own ON user_cosmetics;
CREATE POLICY user_cosmetics_update_own ON user_cosmetics
  FOR UPDATE USING ((select auth.uid()) = user_id) WITH CHECK ((select auth.uid()) = user_id);
DROP POLICY IF EXISTS user_cosmetics_service_insert ON user_cosmetics;
CREATE POLICY user_cosmetics_service_insert ON user_cosmetics
  FOR INSERT TO service_role WITH CHECK (true);

GRANT SELECT, UPDATE ON user_cosmetics TO authenticated;
GRANT SELECT ON cosmetics TO authenticated;


-- ============================================================================
-- 3. Seed the catalog
-- ============================================================================
INSERT INTO cosmetics (id, type, display_name, description, emoji, color_hex, gradient_hex, tier, is_animated, unlock_level)
VALUES
  -- Badges (rendered as emoji pill with color background)
  ('badge_rising_star',    'badge', 'Rising Star',
   'First major milestone. Worn with pride.',  '⭐', '#FFD700', '#FF8C00', 'gold',         true, 5),
  ('badge_iron_will',      'badge', 'Iron Will',
   '10 levels of showing up.',                 '🏅', '#9E9E9E', '#616161', 'iron',         true, 10),
  ('badge_dedicated',      'badge', 'Dedicated',
   '25 levels. Not a phase.',                  '💫', '#8BC34A', '#558B2F', 'silver',       true, 25),
  ('badge_veteran',        'badge', 'Veteran',
   '50 levels. You earned this.',              '🎖️', '#2196F3', '#1565C0', 'silver',       true, 50),
  ('badge_elite',          'badge', 'Elite',
   '75 levels — Elite status.',                '👑', '#FF9800', '#E65100', 'gold',         true, 75),
  ('badge_legend',         'badge', 'Legend',
   '100 levels. Legendary.',                   '🏆', '#9C27B0', '#4A148C', 'holographic',  true, 100),
  ('badge_mythic',         'badge', 'Mythic',
   '200 levels. Mythical dedication.',         '✨', '#E040FB', '#AA00FF', 'holographic',  true, 200),
  ('badge_transcendent',   'badge', 'Transcendent',
   '250 levels. Transcended.',                 '🌟', '#FF1744', '#B71C1C', 'special',      true, 250),

  -- Frames (rendered as colored circular border)
  ('frame_bronze',         'frame', 'Bronze Frame',
   'A clean bronze border around your avatar.',   NULL, '#CD7F32', '#8B5A2B',   'bronze',       false, 25),
  ('frame_silver',         'frame', 'Silver Frame',
   'A polished silver border.',                   NULL, '#C0C0C0', '#A9A9A9',   'silver',       false, 50),
  ('frame_gold_holographic','frame','Gold Holographic Frame',
   'Shifting gold-holo border.',                  NULL, '#FFD700', '#FF00FF',   'holographic',  true,  75),
  ('frame_platinum',       'frame', 'Platinum Frame',
   'Platinum border for the committed.',          NULL, '#E5E4E2', '#BFC1C2',   'special',      false, 100),
  ('frame_mythic',         'frame', 'Mythic Frame',
   'Iridescent mythic border.',                   NULL, '#E040FB', '#00E5FF',   'holographic',  true,  200),

  -- Chat titles (stored; rendering in chat header is phase 2)
  ('title_dedicated',      'chat_title', 'Dedicated',
   'Shown next to your name in chat/feed.',       '💫', '#8BC34A', NULL, 'silver',   false, 25),
  ('title_veteran',        'chat_title', 'Veteran',
   'Shown next to your name in chat/feed.',       '🎖️', '#2196F3', NULL, 'silver',   false, 50),
  ('title_elite',          'chat_title', 'Elite',
   'Shown next to your name in chat/feed.',       '👑', '#FF9800', NULL, 'gold',     false, 75),
  ('title_legend',         'chat_title', 'Legend',
   'Shown next to your name in chat/feed.',       '🏆', '#9C27B0', NULL, 'holographic', false, 100),

  -- Themes (accent color pack — deferred rendering but unlocks are tracked)
  ('theme_iron',           'theme', 'Iron Theme',
   'Steel-gray accent pack.',                     NULL, '#616161', NULL, 'iron',     false, 10),
  ('theme_gold',           'theme', 'Gold Theme',
   'Gold accent pack.',                           NULL, '#FFD700', NULL, 'gold',     false, 75),

  -- Coach voices (deferred — needs TTS swap)
  ('coach_voice_chad',     'coach_voice', 'Coach Chad',
   'An alt coach voice. Energetic.',              NULL, NULL, NULL, 'special',  false, 50),
  ('coach_voice_serena',   'coach_voice', 'Coach Serena',
   'An alt coach voice. Calm, precise.',          NULL, NULL, NULL, 'special',  false, 50),

  -- Stats card (deferred — needs Share Gallery template)
  ('stats_card_elite',     'stats_card', 'Elite Stats Card',
   'Exclusive Share Gallery template.',           NULL, '#FF9800', NULL, 'gold',    false, 75)
ON CONFLICT (id) DO UPDATE
  SET type = EXCLUDED.type,
      display_name = EXCLUDED.display_name,
      description = EXCLUDED.description,
      emoji = EXCLUDED.emoji,
      color_hex = EXCLUDED.color_hex,
      gradient_hex = EXCLUDED.gradient_hex,
      tier = EXCLUDED.tier,
      is_animated = EXCLUDED.is_animated,
      unlock_level = EXCLUDED.unlock_level;


-- ============================================================================
-- 4. equip_cosmetic: equip one cosmetic; unequips any other of the same type
-- ============================================================================
CREATE OR REPLACE FUNCTION equip_cosmetic(p_user_id UUID, p_cosmetic_id TEXT)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_type TEXT;
BEGIN
  -- Must own the cosmetic
  IF NOT EXISTS (SELECT 1 FROM user_cosmetics WHERE user_id = p_user_id AND cosmetic_id = p_cosmetic_id) THEN
    RAISE EXCEPTION 'Cosmetic not owned by user';
  END IF;

  SELECT type INTO v_type FROM cosmetics WHERE id = p_cosmetic_id;

  -- Unequip any other cosmetic of the same type
  UPDATE user_cosmetics uc
  SET is_equipped = false
  FROM cosmetics c
  WHERE uc.user_id = p_user_id
    AND uc.cosmetic_id = c.id
    AND c.type = v_type
    AND uc.cosmetic_id <> p_cosmetic_id;

  -- Equip the chosen one
  UPDATE user_cosmetics
  SET is_equipped = true
  WHERE user_id = p_user_id AND cosmetic_id = p_cosmetic_id;

  RETURN jsonb_build_object(
    'cosmetic_id', p_cosmetic_id,
    'type', v_type,
    'is_equipped', true
  );
END;
$$;


-- ============================================================================
-- 5. unequip_cosmetic
-- ============================================================================
CREATE OR REPLACE FUNCTION unequip_cosmetic(p_user_id UUID, p_cosmetic_id TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE user_cosmetics
  SET is_equipped = false
  WHERE user_id = p_user_id AND cosmetic_id = p_cosmetic_id;
  RETURN FOUND;
END;
$$;


-- ============================================================================
-- 6. Patch distribute_level_rewards to auto-unlock cosmetics at their levels
-- ----------------------------------------------------------------------------
-- Wraps the existing function: after rewards are distributed, unlock any
-- cosmetic whose unlock_level is in the (old, new] range. Auto-equips the
-- first badge and first frame owned so the user sees something immediately.
-- ============================================================================

CREATE OR REPLACE FUNCTION grant_level_cosmetics(
  p_user_id UUID,
  p_old_level INT,
  p_new_level INT
) RETURNS SETOF TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_newly_unlocked TEXT[];
  v_cosmetic_id TEXT;
  v_first_badge TEXT;
  v_first_frame TEXT;
  v_has_equipped_badge BOOLEAN;
  v_has_equipped_frame BOOLEAN;
BEGIN
  -- Find eligible cosmetics
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
  ON CONFLICT (user_id, cosmetic_id) DO NOTHING
  RETURNING cosmetic_id INTO v_cosmetic_id;

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

GRANT EXECUTE ON FUNCTION grant_level_cosmetics(UUID, INT, INT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION equip_cosmetic(UUID, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION unequip_cosmetic(UUID, TEXT) TO authenticated, service_role;


-- ============================================================================
-- 7. Wrap distribute_level_rewards to call grant_level_cosmetics automatically
-- ----------------------------------------------------------------------------
-- Rather than copy the whole function body yet again, we add a tiny trigger-
-- style mechanism: when distribute_level_rewards runs, it inserts into
-- level_up_events (migration 1935). We add a trigger that, on level_up_events
-- insert, calls grant_level_cosmetics for that level range.
-- ============================================================================

CREATE OR REPLACE FUNCTION level_up_events_grant_cosmetics()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM grant_level_cosmetics(NEW.user_id, NEW.level_reached - 1, NEW.level_reached);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_level_up_events_grant_cosmetics ON level_up_events;
CREATE TRIGGER trg_level_up_events_grant_cosmetics
  AFTER INSERT ON level_up_events
  FOR EACH ROW EXECUTE FUNCTION level_up_events_grant_cosmetics();


-- ============================================================================
-- 8. Backfill cosmetics for existing users based on their current_level
-- ============================================================================
INSERT INTO user_cosmetics (user_id, cosmetic_id, unlocked_at_level)
SELECT u.user_id, c.id, c.unlock_level
FROM user_xp u
CROSS JOIN cosmetics c
WHERE c.is_active = true
  AND c.unlock_level IS NOT NULL
  AND c.unlock_level <= u.current_level
ON CONFLICT (user_id, cosmetic_id) DO NOTHING;

-- Auto-equip best badge/frame per user (only if they have nothing equipped)
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
