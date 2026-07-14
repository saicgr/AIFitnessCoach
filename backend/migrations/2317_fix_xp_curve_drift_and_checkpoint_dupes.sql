-- ============================================================================
-- Migration 2317: Fix XP level-curve drift + de-duplicate checkpoint_rewards
-- ============================================================================
-- Found by tests/test_xp_database_integration.py (which had been --ignore'd, so
-- these sat dark). Two independent production bugs:
--
-- BUG 1 — Two different XP curves are live at once.
--   Migration 1901 ("D. Rescale level thresholds so Level 2 = 150 XP",
--   "E. Recalculate all existing users' levels under new curve") rescaled
--   calculate_level_from_xp -> 150, 200, 300, 450, 650, ...
--   It did NOT update get_level_info, which still holds the pre-1901 curve
--   -> 25, 30, 40, 50, 65, ...  (nor its Python twin `_XP_TABLE` in
--   api/v1/xp_endpoints.py, fixed in the same commit as this migration).
--
--   calculate_level_from_xp is the operative truth: award_xp / revoke_xp /
--   get_all_level_xp_thresholds all call it, and every user's stored level was
--   recomputed with it by 1901. get_level_info is called by NO other SQL — it
--   is a pure display path. So get_level_info is the side that is wrong.
--
--   Impact: we under-report the cost of a level by up to ~13x.
--     get_level_info(50).total_xp_to_reach  = 32,960
--     calculate_level_from_xp(32,960)       = level 17   <-- not 50
--     get_level_info(2).total_xp_to_reach   = 25
--     calculate_level_from_xp(25)           = level 1    <-- not 2
--   Users are told a level costs a fraction of what the DB actually charges,
--   so the "XP to next level" bar can never fill at the advertised rate.
--
--   Root cause is duplication: the curve was copy-pasted into 3 places, and
--   1901 only updated one. Fix = introduce ONE canonical source,
--   `xp_level_cost(level)`, and rebuild get_level_info on top of it.
--   calculate_level_from_xp is deliberately left byte-identical here — it is
--   correct, it is on the hot XP-award path, and re-deriving it buys nothing.
--   A regression gate (test_python_xp_table_matches_db_curve /
--   test_xp_level_cost_matches_calculate_level_from_xp) now pins all three
--   representations together so this cannot silently drift again.
--
-- BUG 2 — checkpoint_rewards rows are TRIPLICATED (78 physical / 26 logical).
--   Migration 222 seeds with `ON CONFLICT DO NOTHING`, but the only unique
--   index on the table is the PRIMARY KEY on `id UUID DEFAULT gen_random_uuid()`
--   — which can never collide. The guard is a placebo: every re-run inserts a
--   fresh copy of every row. Migration 223 has no ON CONFLICT clause at all.
--   The seeds were re-applied twice on 2026-02-17 (three distinct created_at
--   batches), giving exactly 3 copies of all 26 rows:
--     SUM(xp_reward) WHERE checkpoint_type='weekly' = 4725  (should be 1,575)
--     SUM(xp_reward) WHERE period_type='monthly'    = 15750 (should be 5,250)
--   Nothing reads the table today (no SQL function, view, or backend query),
--   so no user has been awarded 3x XP — this is latent, not yet-exploited: the
--   first consumer that SUMs or JOINs it inherits a silent 3x.
--   Fix = collapse to the earliest row per natural key, then add the unique
--   index the ON CONFLICT clause always assumed existed.
-- ============================================================================


-- ============================================================================
-- 1. Canonical XP curve — the ONE source of truth for "what does level N cost"
-- ============================================================================
-- Values are copied verbatim from calculate_level_from_xp (post-1901).
CREATE OR REPLACE FUNCTION public.xp_level_cost(p_level INT)
RETURNS INT
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $function$
DECLARE
  xp_table INT[] := ARRAY[
    -- Levels 1-10 (Beginner): Meaningful early progression
    150, 200, 300, 450, 650, 900, 1200, 1600, 2100, 2700,
    -- Levels 11-25 (Novice): Steady growth
    3000, 3300, 3600, 3900, 4200, 4500, 4800, 5100, 5400, 5700, 6000, 6300, 6600, 6900, 7500,
    -- Levels 26-50 (Apprentice): Consistent effort required
    8000, 8500, 9000, 9500, 10000, 10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 16000, 17000, 18000, 19000, 20000, 21000, 22000, 23000, 24000, 25000,
    -- Levels 51-75 (Athlete): Dedicated training
    26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 42000, 44000, 46000, 48000, 50000, 52000, 54000, 56000, 58000, 60000,
    -- Levels 76-100 (Elite): Long-term commitment
    62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000, 102000, 104000, 106000, 108000, 110000,
    -- Levels 101-125 (Master)
    112000, 114000, 116000, 118000, 120000, 122000, 124000, 126000, 128000, 130000, 132000, 134000, 136000, 138000, 140000, 142000, 144000, 146000, 148000, 150000, 152000, 154000, 156000, 158000, 160000,
    -- Levels 126-150 (Champion)
    162000, 164000, 166000, 168000, 170000, 172000, 174000, 176000, 178000, 180000, 182000, 184000, 186000, 188000, 190000, 192000, 194000, 196000, 198000, 200000, 202000, 204000, 206000, 208000, 210000,
    -- Levels 151-175 (Legend)
    212000, 214000, 216000, 218000, 220000, 222000, 224000, 226000, 228000, 230000, 232000, 234000, 236000, 238000, 240000, 242000, 244000, 246000, 248000, 250000, 252000, 254000, 256000, 258000, 260000
  ];
BEGIN
  IF p_level >= 250 THEN
    RETURN 0;                       -- max level: nothing left to earn
  ELSIF p_level <= 175 THEN
    RETURN xp_table[p_level];
  ELSE
    RETURN 100000;                  -- 176-249: flat prestige tier
  END IF;
END;
$function$;

COMMENT ON FUNCTION public.xp_level_cost(INT) IS
  'Canonical XP cost of level N (post-migration-1901 curve). Single source of '
  'truth: get_level_info builds on this, calculate_level_from_xp holds the same '
  'numbers, and the Python _XP_TABLE is pinned to it by a test. Change here only.';


-- ============================================================================
-- 2. BUG 1 FIX: rebuild get_level_info on the canonical curve
-- ============================================================================
-- Only the XP numbers change. Return shape, titles (get_xp_title — already
-- verified to agree with calculate_level_from_xp at every level 1-250) and the
-- prestige handling are all preserved.
CREATE OR REPLACE FUNCTION public.get_level_info(p_level integer)
RETURNS jsonb
LANGUAGE plpgsql
IMMUTABLE
SET search_path TO 'public'
AS $function$
DECLARE
  v_xp_needed INT;
  v_title TEXT;
  v_total_xp_to_reach BIGINT := 0;
  v_i INT;
BEGIN
  -- XP to go from p_level -> p_level + 1
  v_xp_needed := xp_level_cost(p_level);

  v_title := get_xp_title(p_level);

  -- Total XP that must be banked to REACH p_level = sum of every level below it.
  FOR v_i IN 1..(p_level - 1) LOOP
    v_total_xp_to_reach := v_total_xp_to_reach + xp_level_cost(v_i);
  END LOOP;

  RETURN jsonb_build_object(
    'level', p_level,
    'title', v_title,
    'xp_to_next_level', v_xp_needed,
    'total_xp_to_reach', v_total_xp_to_reach
  );
END;
$function$;


-- ============================================================================
-- 3. BUG 2 FIX: collapse checkpoint_rewards duplicates, then make the seed's
--    `ON CONFLICT DO NOTHING` actually mean something.
-- ============================================================================
-- Keep the earliest row of each natural-key group. Every copy within a group is
-- byte-identical on (xp_reward, description), so which one survives is
-- immaterial — verified: 26 distinct logical rows across 78 physical.
DELETE FROM public.checkpoint_rewards a
USING public.checkpoint_rewards b
WHERE a.checkpoint_type = b.checkpoint_type
  AND COALESCE(a.metric_name, '') = COALESCE(b.metric_name, '')
  AND COALESCE(a.period_type, '') = COALESCE(b.period_type, '')
  AND (
        a.created_at > b.created_at
     OR (a.created_at = b.created_at AND a.id > b.id)
  );

-- The unique index migration 222's ON CONFLICT always assumed was there.
-- NULLS NOT DISTINCT (PG15+) so a future NULL metric_name/period_type can't
-- sneak a duplicate past it the way it would under default NULLS DISTINCT.
CREATE UNIQUE INDEX IF NOT EXISTS checkpoint_rewards_natural_key
  ON public.checkpoint_rewards (checkpoint_type, metric_name, period_type)
  NULLS NOT DISTINCT;
