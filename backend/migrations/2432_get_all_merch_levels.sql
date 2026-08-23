-- ============================================================================
-- Migration 2432: Single-RPC read path for the merch unlock ladder (E2E #371)
-- ============================================================================
-- Migration 2424 rescaled the merch unlock ladder via merch_type_for_level()
-- (20/40/60/80/100) but nothing called that function from the app layer:
--   - backend/api/v1/xp_endpoints.py kept a separate Python
--     MERCH_TYPE_FOR_LEVEL dict at the OLD thresholds (50/100/150/200/250),
--     feeding both /xp/all-levels' merch_type field and its own
--     retroactive merch_claims backfill loop.
--   - mobile/flutter/lib/data/models/level_reward.dart hardcoded the same
--     old ladder client-side (Level 5/10/25/50/100/150/200/250), driving
--     every level-up celebration dialog.
-- Three disagreeing copies of one ruleset. This migration gives the Python
-- backend a single cheap RPC to read the SQL function's ladder in bulk
-- (mirrors get_all_level_xp_thresholds's existing pattern) instead of
-- calling merch_type_for_level() once per level or hand-maintaining a
-- second Python copy. xp_endpoints.py now calls this RPC; the Flutter
-- client now reads merch_type off /xp/all-levels instead of hardcoding its
-- own ladder (see level_reward.dart).
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_all_merch_levels()
RETURNS TABLE(lvl INT, merch_type TEXT)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path TO 'public'
AS $$
  SELECT g.lvl, merch_type_for_level(g.lvl)
  FROM generate_series(1, 250) AS g(lvl)
  WHERE merch_type_for_level(g.lvl) IS NOT NULL;
$$;

-- VERIFY: select * from get_all_merch_levels();
-- expect exactly 5 rows: (20,'sticker_pack'), (40,'t_shirt'), (60,'hoodie'),
-- (80,'full_merch_kit'), (100,'signed_premium_kit')
