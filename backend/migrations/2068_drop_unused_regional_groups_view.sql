-- 2068_drop_unused_regional_groups_view.sql
--
-- Supersedes 2066. Drops the food_overrides_regional_groups view because
-- it returned zero rows against the actual data.
--
-- Diagnostic finding (2026-05-13): food_name_normalized is structured as
-- `<dish description>_<region adjective>` SUFFIX (e.g. `beef_biryani_pakistani`,
-- `andhra_gongura_chicken_biryani_indian`, `bahraini_chicken_biryani_bahraini`).
-- The view in 2066 stripped PREFIXES, which never matched. Beyond that, the
-- entire 198,818-row table has 198,818 distinct food_name_normalized values
-- — there is nothing to "group" at the (name) level since every row is
-- already unique.
--
-- The Phase-2 frontend Region dropdown will instead use a runtime trigram
-- query against food_nutrition_overrides_canonical (e.g. WHERE
-- food_name_normalized % 'beef_biryani' ORDER BY similarity(...) LIMIT 10),
-- which surfaces the correct alternates from the existing trigram + GIN
-- indexes already on the canonical MV. No precomputed view needed.

DROP VIEW IF EXISTS food_overrides_regional_groups;
