-- Migration 2433: Fix get_level_info() to use the migration-1901 XP curve
--
-- Migration 1901 rescaled calculate_level_from_xp (the function that
-- actually levels users up on award_xp) to make Level 2 cost 150 XP instead
-- of 30, but never updated get_level_info's copy of the xp_table -- it was
-- still returning migration-227's numbers (25, 30, 40, 50, ...). The two
-- curves diverged: get_level_info(50) claimed 32,960 total XP reaches level
-- 50, but calculate_level_from_xp(32,960) actually lands you on level 17.
--
-- api/v1/xp_endpoints.py's Python mirror (_XP_TABLE) was already corrected to
-- match calculate_level_from_xp; this migration brings the DB function
-- get_level_info() into agreement with it too, so nothing that calls the RPC
-- directly (see tests/test_xp_database_integration.py) gets the stale curve.
--
-- See tests/test_xp_database_integration.py::TestLevelProgression::
-- test_get_level_info_agrees_with_calculate_level_from_xp

CREATE OR REPLACE FUNCTION get_level_info(p_level INTEGER)
RETURNS JSONB
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  -- Same xp_table as calculate_level_from_xp (migration 1901).
  xp_table INT[] := ARRAY[
    150, 200, 300, 450, 650, 900, 1200, 1600, 2100, 2700,
    3000, 3300, 3600, 3900, 4200, 4500, 4800, 5100, 5400, 5700, 6000, 6300, 6600, 6900, 7500,
    8000, 8500, 9000, 9500, 10000, 10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 16000, 17000, 18000, 19000, 20000, 21000, 22000, 23000, 24000, 25000,
    26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 42000, 44000, 46000, 48000, 50000, 52000, 54000, 56000, 58000, 60000,
    62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000, 102000, 104000, 106000, 108000, 110000,
    112000, 114000, 116000, 118000, 120000, 122000, 124000, 126000, 128000, 130000, 132000, 134000, 136000, 138000, 140000, 142000, 144000, 146000, 148000, 150000, 152000, 154000, 156000, 158000, 160000,
    162000, 164000, 166000, 168000, 170000, 172000, 174000, 176000, 178000, 180000, 182000, 184000, 186000, 188000, 190000, 192000, 194000, 196000, 198000, 200000, 202000, 204000, 206000, 208000, 210000,
    212000, 214000, 216000, 218000, 220000, 222000, 224000, 226000, 228000, 230000, 232000, 234000, 236000, 238000, 240000, 242000, 244000, 246000, 248000, 250000, 252000, 254000, 256000, 258000, 260000
  ];
  v_xp_needed INT;
  v_title TEXT;
  v_total_xp_to_reach BIGINT := 0;
  v_i INT;
BEGIN
  -- Calculate XP needed for the given level
  IF p_level >= 250 THEN
    v_xp_needed := 0; -- Max level
  ELSIF p_level <= 175 THEN
    v_xp_needed := xp_table[p_level];
  ELSE
    v_xp_needed := 100000;
  END IF;

  -- Get title
  v_title := get_xp_title(p_level);

  -- Calculate total XP to reach this level
  FOR v_i IN 1..(p_level - 1) LOOP
    IF v_i <= 175 THEN
      v_total_xp_to_reach := v_total_xp_to_reach + xp_table[v_i];
    ELSE
      v_total_xp_to_reach := v_total_xp_to_reach + 100000;
    END IF;
  END LOOP;

  RETURN jsonb_build_object(
    'level', p_level,
    'title', v_title,
    'xp_to_next_level', v_xp_needed,
    'total_xp_to_reach', v_total_xp_to_reach
  );
END;
$$;

COMMENT ON FUNCTION get_level_info(INTEGER) IS
'Migration 2433: rescaled to the migration-1901 XP curve so it agrees with
calculate_level_from_xp again (was still on the migration-227 curve).';
