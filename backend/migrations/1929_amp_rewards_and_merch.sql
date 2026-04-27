-- ============================================================================
-- Migration 1929: Amp Level-Up Rewards + Physical Merch Claims
-- ============================================================================
-- Goals:
--   1. Every level (2+) grants at least one consumable (no more empty levels)
--   2. Amp milestone rewards — more 2x XP Tokens, more Premium Crates
--   3. Introduce physical merch rewards at L75 / L100 / L150 / L200 / L250
--   4. Merch requires user to submit a shipping address via new claim flow
--
-- Merch tiers:
--   L75  → Zealova Shaker Bottle
--   L100 → Zealova T-Shirt       (requires size)
--   L150 → Zealova Hoodie        (requires size)
--   L200 → Full Merch Kit       (tee + hoodie + shaker — requires sizes)
--   L250 → Signed Premium Kit   (everything signed by the team)
--
-- NOTE: No subscription rewards. No "X months free". Physical goods only.
-- ============================================================================


-- ============================================================================
-- 1. merch_claims table
-- ----------------------------------------------------------------------------
-- Note: a prior migration (163) created a merch_claims table with different
-- column names (reward_type, shipping_name, shipping_address JSONB). Rather
-- than drop and lose compatibility, we ADD the columns we need.
-- ============================================================================
CREATE TABLE IF NOT EXISTS merch_claims (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending_address',
  notes TEXT,
  tracking_number TEXT,
  carrier TEXT,
  shipped_at TIMESTAMPTZ,
  delivered_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ensure new columns exist (idempotent)
ALTER TABLE merch_claims
  ADD COLUMN IF NOT EXISTS merch_type TEXT,
  ADD COLUMN IF NOT EXISTS awarded_at_level INT,
  ADD COLUMN IF NOT EXISTS shipping_full_name TEXT,
  ADD COLUMN IF NOT EXISTS shipping_address_line1 TEXT,
  ADD COLUMN IF NOT EXISTS shipping_address_line2 TEXT,
  ADD COLUMN IF NOT EXISTS shipping_city TEXT,
  ADD COLUMN IF NOT EXISTS shipping_state TEXT,
  ADD COLUMN IF NOT EXISTS shipping_postal_code TEXT,
  ADD COLUMN IF NOT EXISTS shipping_country TEXT,
  ADD COLUMN IF NOT EXISTS shipping_phone TEXT,
  ADD COLUMN IF NOT EXISTS size TEXT,
  ADD COLUMN IF NOT EXISTS sizes JSONB,
  ADD COLUMN IF NOT EXISTS address_submitted_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ;

-- Backfill merch_type from legacy reward_type if present
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='merch_claims' AND column_name='reward_type'
  ) THEN
    UPDATE merch_claims SET merch_type = reward_type WHERE merch_type IS NULL AND reward_type IS NOT NULL;
  END IF;
END$$;

-- Constraints (drop then re-add so they match the new schema)
ALTER TABLE merch_claims DROP CONSTRAINT IF EXISTS merch_claims_merch_type_check;
ALTER TABLE merch_claims
  ADD CONSTRAINT merch_claims_merch_type_check
  CHECK (merch_type IS NULL OR merch_type IN ('shaker_bottle', 't_shirt', 'hoodie', 'full_merch_kit', 'signed_premium_kit'));

ALTER TABLE merch_claims DROP CONSTRAINT IF EXISTS merch_claims_status_check;
ALTER TABLE merch_claims
  ADD CONSTRAINT merch_claims_status_check
  CHECK (status IN ('pending_address', 'address_submitted', 'shipped', 'delivered', 'cancelled'));

ALTER TABLE merch_claims DROP CONSTRAINT IF EXISTS merch_claims_awarded_at_level_check;
ALTER TABLE merch_claims
  ADD CONSTRAINT merch_claims_awarded_at_level_check
  CHECK (awarded_at_level IS NULL OR awarded_at_level BETWEEN 1 AND 250);

-- Unique (user_id, awarded_at_level) — only when awarded_at_level is set
CREATE UNIQUE INDEX IF NOT EXISTS ux_merch_claims_user_level
  ON merch_claims(user_id, awarded_at_level)
  WHERE awarded_at_level IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_merch_claims_user_id ON merch_claims(user_id);
CREATE INDEX IF NOT EXISTS idx_merch_claims_status ON merch_claims(status);
CREATE INDEX IF NOT EXISTS idx_merch_claims_user_status ON merch_claims(user_id, status);

-- RLS
ALTER TABLE merch_claims ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "merch_claims_select_own" ON merch_claims;
CREATE POLICY "merch_claims_select_own" ON merch_claims
  FOR SELECT
  USING ((select auth.uid()) = user_id);

DROP POLICY IF EXISTS "merch_claims_update_own" ON merch_claims;
CREATE POLICY "merch_claims_update_own" ON merch_claims
  FOR UPDATE
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Only the system (via SECURITY DEFINER functions) inserts claims.
DROP POLICY IF EXISTS "merch_claims_service_insert" ON merch_claims;
CREATE POLICY "merch_claims_service_insert" ON merch_claims
  FOR INSERT
  TO service_role
  WITH CHECK (true);

-- updated_at trigger
CREATE OR REPLACE FUNCTION merch_claims_touch_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_merch_claims_touch ON merch_claims;
CREATE TRIGGER trg_merch_claims_touch
  BEFORE UPDATE ON merch_claims
  FOR EACH ROW EXECUTE FUNCTION merch_claims_touch_updated_at();

COMMENT ON TABLE merch_claims IS
'Physical merchandise rewards earned at milestone levels. User submits shipping address after award; ops team ships manually and updates tracking fields.';


-- ============================================================================
-- 2. Helper: Get merch type for a given level (returns NULL if not a merch level)
-- ============================================================================
CREATE OR REPLACE FUNCTION merch_type_for_level(p_level INT)
RETURNS TEXT
LANGUAGE plpgsql
IMMUTABLE
AS $$
BEGIN
  RETURN CASE p_level
    WHEN 75  THEN 'shaker_bottle'
    WHEN 100 THEN 't_shirt'
    WHEN 150 THEN 'hoodie'
    WHEN 200 THEN 'full_merch_kit'
    WHEN 250 THEN 'signed_premium_kit'
    ELSE NULL
  END;
END;
$$;


-- ============================================================================
-- 3. Rewrite distribute_level_rewards with amped rewards + merch
-- ============================================================================
DROP FUNCTION IF EXISTS distribute_level_rewards(UUID, INTEGER, INTEGER);

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

    -- Major milestones that get a richer, *overriding* reward bundle
    v_is_major := v_level IN (5, 10, 15, 20, 25, 30, 40, 50, 60, 75, 100, 125, 150, 175, 200, 225, 250);

    -- ================================================================
    -- MAJOR MILESTONE BUNDLES (override per-level tier rewards)
    -- ================================================================
    IF v_is_major THEN
      CASE v_level
        WHEN 5 THEN
          PERFORM add_consumable(p_user_id, 'streak_shield', 3);
          PERFORM add_consumable(p_user_id, 'fitness_crate', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',3),
            jsonb_build_object('type','fitness_crate','quantity',2)
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
          -- unreachable given v_is_major guard
          NULL;
      END CASE;

    ELSE
      -- ================================================================
      -- PER-LEVEL TIER REWARDS (every non-major level gets something)
      -- Based on the ones digit so users always see progress.
      -- ================================================================
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
          -- non-major levels ending in 0 (after level 60 where majors stop following the pattern)
          PERFORM add_consumable(p_user_id, 'fitness_crate', 3);
          PERFORM add_consumable(p_user_id, 'premium_crate', 1);
          v_items := jsonb_build_array(
            jsonb_build_object('type','fitness_crate','quantity',3),
            jsonb_build_object('type','premium_crate','quantity',1)
          );
        WHEN 5 THEN
          -- non-major levels ending in 5 (after level 75 where majors stop following the pattern)
          PERFORM add_consumable(p_user_id, 'streak_shield', 3);
          PERFORM add_consumable(p_user_id, 'xp_token_2x', 2);
          v_items := jsonb_build_array(
            jsonb_build_object('type','streak_shield','quantity',3),
            jsonb_build_object('type','xp_token_2x','quantity',2)
          );
      END CASE;
    END IF;

    -- ================================================================
    -- MERCH: insert pending claim for merch-tier levels
    -- ================================================================
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

    -- Record the per-level reward envelope
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
'Migration 1929: Amped reward schedule. Every level (2+) grants at least one consumable; major milestones (5,10,15,20,25,30,40,50,60,75,100,125,150,175,200,225,250) grant large bundles; merch levels (75,100,150,200,250) also insert a pending merch_claim.';


-- ============================================================================
-- 4. RPC: list a user's merch claims
-- ============================================================================
CREATE OR REPLACE FUNCTION get_user_merch_claims(p_user_id UUID)
RETURNS SETOF merch_claims
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM merch_claims
  WHERE user_id = p_user_id
  ORDER BY awarded_at_level ASC, created_at ASC;
$$;


-- ============================================================================
-- 5. RPC: submit shipping address for a pending claim
-- ============================================================================
CREATE OR REPLACE FUNCTION submit_merch_claim_address(
  p_claim_id UUID,
  p_user_id UUID,
  p_full_name TEXT,
  p_address_line1 TEXT,
  p_address_line2 TEXT,
  p_city TEXT,
  p_state TEXT,
  p_postal_code TEXT,
  p_country TEXT,
  p_phone TEXT,
  p_size TEXT DEFAULT NULL,
  p_sizes JSONB DEFAULT NULL,
  p_notes TEXT DEFAULT NULL
)
RETURNS merch_claims
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_claim merch_claims;
BEGIN
  SELECT * INTO v_claim FROM merch_claims
  WHERE id = p_claim_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Merch claim not found for user';
  END IF;

  IF v_claim.status NOT IN ('pending_address', 'address_submitted') THEN
    RAISE EXCEPTION 'Claim is % and cannot be edited', v_claim.status;
  END IF;

  UPDATE merch_claims
  SET shipping_full_name = p_full_name,
      shipping_address_line1 = p_address_line1,
      shipping_address_line2 = p_address_line2,
      shipping_city = p_city,
      shipping_state = p_state,
      shipping_postal_code = p_postal_code,
      shipping_country = p_country,
      shipping_phone = p_phone,
      size = p_size,
      sizes = p_sizes,
      notes = p_notes,
      status = 'address_submitted',
      address_submitted_at = NOW()
  WHERE id = p_claim_id
  RETURNING * INTO v_claim;

  RETURN v_claim;
END;
$$;


-- ============================================================================
-- 6. RPC: cancel a pending merch claim (user-initiated)
-- ============================================================================
CREATE OR REPLACE FUNCTION cancel_merch_claim(p_claim_id UUID, p_user_id UUID)
RETURNS merch_claims
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_claim merch_claims;
BEGIN
  SELECT * INTO v_claim FROM merch_claims
  WHERE id = p_claim_id AND user_id = p_user_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Merch claim not found for user';
  END IF;

  IF v_claim.status IN ('shipped', 'delivered', 'cancelled') THEN
    RAISE EXCEPTION 'Claim is % and cannot be cancelled', v_claim.status;
  END IF;

  UPDATE merch_claims
  SET status = 'cancelled',
      cancelled_at = NOW()
  WHERE id = p_claim_id
  RETURNING * INTO v_claim;

  RETURN v_claim;
END;
$$;


-- ============================================================================
-- 7. Grants
-- ============================================================================
GRANT SELECT, UPDATE ON merch_claims TO authenticated;
GRANT ALL ON merch_claims TO service_role;

GRANT EXECUTE ON FUNCTION merch_type_for_level(INT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION distribute_level_rewards(UUID, INTEGER, INTEGER) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION get_user_merch_claims(UUID) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION submit_merch_claim_address(UUID, UUID, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, JSONB, TEXT) TO authenticated, service_role;
GRANT EXECUTE ON FUNCTION cancel_merch_claim(UUID, UUID) TO authenticated, service_role;
