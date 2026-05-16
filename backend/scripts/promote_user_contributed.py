"""Daily cron job: promote convergent user-contributed dishes to canonical.

Per Phase 2 §2.10: dishes that ≥5 distinct users have logged AND whose
macros agree (CV < 20%) get auto-promoted from food_overrides_user_contributed
into food_nutrition_overrides with `nutrient_source='auto_promoted'` and
`auto_promoted_at=NOW()`. This warms the global canonical cache so all
new users benefit from convergent community data.

Idempotent: re-running won't double-promote (UPSERTs on canonical, marks
contributing rows as promoted_to_canonical=TRUE).

Excludes user_edited rows from cross-user averaging — one user's manual
correction must not propagate to everyone (per §C4 + §D5).

Cron schedule: daily at 03:00 UTC (low-traffic window).

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.promote_user_contributed

Backout (per §G3):
    UPDATE food_nutrition_overrides
    SET nutrient_source='gemini_estimate'
    WHERE auto_promoted_at IS NOT NULL;

Knobs (env):
    PROMOTION_MIN_USERS=5    — minimum distinct users for promotion
    PROMOTION_MAX_CV=0.20    — max coefficient of variation on calories
    PROMOTION_DRY_RUN=1      — log what would be promoted, don't write
"""
from __future__ import annotations

import asyncio
import logging
import os
import sys
import time
from pathlib import Path

import asyncpg
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("promote_user_contributed")

MIN_USERS = int(os.environ.get("PROMOTION_MIN_USERS", "5"))
MAX_CV = float(os.environ.get("PROMOTION_MAX_CV", "0.20"))
DRY_RUN = bool(int(os.environ.get("PROMOTION_DRY_RUN", "0")))


# Aggregation query — picks dishes where ≥MIN_USERS distinct users have
# entries AND calorie variance is bounded. Excludes user_edited rows.
AGGREGATE_SQL = """
WITH agg AS (
  SELECT
    food_name_normalized,
    COUNT(DISTINCT user_id)         AS n_users,
    -- Display name: take the most-used variant
    (ARRAY_AGG(display_name ORDER BY log_count DESC))[1] AS canonical_display,
    -- Average all macros + enrichment + micros
    AVG(calories_per_100g)          AS calories_per_100g,
    AVG(protein_per_100g)           AS protein_per_100g,
    AVG(carbs_per_100g)             AS carbs_per_100g,
    AVG(fat_per_100g)               AS fat_per_100g,
    AVG(fiber_per_100g)             AS fiber_per_100g,
    AVG(sugar_per_100g)             AS sugar_per_100g,
    AVG(default_serving_g)          AS default_serving_g,
    AVG(default_weight_per_piece_g) AS default_weight_per_piece_g,
    -- 9 enrichment fields
    ROUND(AVG(inflammation_score)::numeric, 0)::smallint AS inflammation_score,
    -- inflammation_triggers: array union of most-common
    (ARRAY_AGG(inflammation_triggers ORDER BY log_count DESC) FILTER (WHERE inflammation_triggers IS NOT NULL))[1] AS inflammation_triggers,
    ROUND(AVG(glycemic_load)::numeric, 0)::int AS glycemic_load,
    -- fodmap_rating: take the most common (mode)
    MODE() WITHIN GROUP (ORDER BY fodmap_rating) AS fodmap_rating,
    MODE() WITHIN GROUP (ORDER BY fodmap_reason) AS fodmap_reason,
    AVG(added_sugar_g)              AS added_sugar_g,
    BOOL_OR(is_ultra_processed)     AS is_ultra_processed,
    MODE() WITHIN GROUP (ORDER BY rating) AS rating,
    MODE() WITHIN GROUP (ORDER BY rating_reason) AS rating_reason,
    -- 29 micronutrients
    AVG(saturated_fat_g)  AS saturated_fat_g,  AVG(trans_fat_g)      AS trans_fat_g,
    AVG(cholesterol_mg)   AS cholesterol_mg,   AVG(sodium_mg)        AS sodium_mg,
    AVG(potassium_mg)     AS potassium_mg,     AVG(calcium_mg)       AS calcium_mg,
    AVG(iron_mg)          AS iron_mg,          AVG(magnesium_mg)     AS magnesium_mg,
    AVG(zinc_mg)          AS zinc_mg,          AVG(phosphorus_mg)    AS phosphorus_mg,
    AVG(selenium_ug)      AS selenium_ug,      AVG(copper_mg)        AS copper_mg,
    AVG(manganese_mg)     AS manganese_mg,     AVG(vitamin_a_ug)     AS vitamin_a_ug,
    AVG(vitamin_c_mg)     AS vitamin_c_mg,     AVG(vitamin_d_iu)     AS vitamin_d_iu,
    AVG(vitamin_e_mg)     AS vitamin_e_mg,     AVG(vitamin_k_ug)     AS vitamin_k_ug,
    AVG(vitamin_b1_mg)    AS vitamin_b1_mg,    AVG(vitamin_b2_mg)    AS vitamin_b2_mg,
    AVG(vitamin_b3_mg)    AS vitamin_b3_mg,    AVG(vitamin_b5_mg)    AS vitamin_b5_mg,
    AVG(vitamin_b6_mg)    AS vitamin_b6_mg,    AVG(vitamin_b7_ug)    AS vitamin_b7_ug,
    AVG(vitamin_b9_ug)    AS vitamin_b9_ug,    AVG(vitamin_b12_ug)   AS vitamin_b12_ug,
    AVG(choline_mg)       AS choline_mg,       AVG(omega3_g)         AS omega3_g,
    AVG(omega6_g)         AS omega6_g,
    -- Quality gate: coefficient of variation on calories
    STDDEV(calories_per_100g) AS std_cal,
    AVG(calories_per_100g)    AS mean_cal
  FROM food_overrides_user_contributed
  WHERE promoted_to_canonical = FALSE
    AND user_edited = FALSE                 -- exclude per-user manual corrections
    AND calories_per_100g IS NOT NULL
    AND calories_per_100g > 0
  GROUP BY food_name_normalized
  HAVING COUNT(DISTINCT user_id) >= $1
)
SELECT * FROM agg
WHERE std_cal IS NULL OR mean_cal IS NULL OR std_cal < $2 * mean_cal
"""

# UPSERT into canonical with source='auto_promoted'
UPSERT_CANONICAL_SQL = """
INSERT INTO food_nutrition_overrides (
  food_name_normalized, display_name, source,
  calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g,
  fiber_per_100g, sugar_per_100g,
  default_weight_per_piece_g, default_serving_g,
  inflammation_score, inflammation_triggers, glycemic_load,
  fodmap_rating, fodmap_reason, added_sugar_g, is_ultra_processed,
  rating, rating_reason,
  saturated_fat_g, trans_fat_g, cholesterol_mg,
  sodium_mg, potassium_mg, calcium_mg, iron_mg, magnesium_mg,
  zinc_mg, phosphorus_mg, selenium_ug, copper_mg, manganese_mg,
  vitamin_a_ug, vitamin_c_mg, vitamin_d_iu,
  vitamin_e_mg, vitamin_k_ug,
  vitamin_b1_mg, vitamin_b2_mg, vitamin_b3_mg, vitamin_b5_mg,
  vitamin_b6_mg, vitamin_b7_ug, vitamin_b9_ug, vitamin_b12_ug,
  choline_mg, omega3_g, omega6_g,
  nutrient_source, auto_promoted_at,
  enrichment_backfilled_at, micronutrients_backfilled_at,
  is_active
)
VALUES (
  $1, $2, 'manual',
  $3, $4, $5, $6,
  $7, $8,
  $9, $10,
  $11, $12, $13,
  $14, $15, $16, $17,
  $18, $19,
  $20, $21, $22,
  $23, $24, $25, $26, $27,
  $28, $29, $30, $31, $32,
  $33, $34, $35,
  $36, $37,
  $38, $39, $40, $41,
  $42, $43, $44, $45,
  $46, $47, $48,
  'auto_promoted', NOW(),
  NOW(), NOW(),
  TRUE
)
ON CONFLICT (food_name_normalized) DO UPDATE SET
  -- Re-promotion: averages may have shifted as more users contribute.
  calories_per_100g = EXCLUDED.calories_per_100g,
  protein_per_100g  = EXCLUDED.protein_per_100g,
  carbs_per_100g    = EXCLUDED.carbs_per_100g,
  fat_per_100g      = EXCLUDED.fat_per_100g,
  fiber_per_100g    = EXCLUDED.fiber_per_100g,
  sugar_per_100g    = EXCLUDED.sugar_per_100g,
  -- Don't overwrite human-curated 9 enrichment / 29 micro values when
  -- the canonical row was sourced from USDA / manual / lab measurement.
  -- Only update when the existing row is itself an auto-promoted entry.
  inflammation_score = CASE WHEN food_nutrition_overrides.nutrient_source = 'auto_promoted'
                            THEN EXCLUDED.inflammation_score ELSE food_nutrition_overrides.inflammation_score END,
  fodmap_rating = CASE WHEN food_nutrition_overrides.nutrient_source = 'auto_promoted'
                       THEN EXCLUDED.fodmap_rating ELSE food_nutrition_overrides.fodmap_rating END,
  rating = CASE WHEN food_nutrition_overrides.nutrient_source = 'auto_promoted'
                THEN EXCLUDED.rating ELSE food_nutrition_overrides.rating END,
  sodium_mg = CASE WHEN food_nutrition_overrides.nutrient_source = 'auto_promoted'
                    THEN EXCLUDED.sodium_mg ELSE food_nutrition_overrides.sodium_mg END,
  auto_promoted_at = NOW()
"""

MARK_PROMOTED_SQL = """
UPDATE food_overrides_user_contributed
SET promoted_to_canonical = TRUE
WHERE food_name_normalized = ANY($1::text[]) AND user_edited = FALSE
"""


async def main() -> int:
    db_url = os.environ["DATABASE_URL"].replace(
        "postgresql+asyncpg://", "postgresql://"
    )
    conn = await asyncpg.connect(db_url, statement_cache_size=0, timeout=30)
    try:
        t0 = time.time()
        logger.info(
            f"[start] min_users={MIN_USERS} max_cv={MAX_CV} dry_run={DRY_RUN}"
        )

        # Step 1: aggregate eligible dishes
        candidates = await conn.fetch(AGGREGATE_SQL, MIN_USERS, MAX_CV, timeout=120)
        logger.info(f"[aggregate] {len(candidates)} dishes meet promotion criteria")
        if not candidates:
            logger.info("[done] nothing to promote")
            return 0

        if DRY_RUN:
            logger.info("[DRY RUN] would promote:")
            for r in candidates[:30]:
                logger.info(
                    f"  {r['food_name_normalized']:<40} "
                    f"users={r['n_users']:>3} mean_kcal={r['mean_cal']:.0f} "
                    f"std={r['std_cal']:.0f}"
                )
            return 0

        # Step 2: upsert each into canonical
        promoted_names: list = []
        n_ok = 0
        n_fail = 0
        for r in candidates:
            try:
                await conn.execute(
                    UPSERT_CANONICAL_SQL,
                    r["food_name_normalized"],
                    r["canonical_display"] or r["food_name_normalized"],
                    r["calories_per_100g"], r["protein_per_100g"],
                    r["carbs_per_100g"], r["fat_per_100g"],
                    r["fiber_per_100g"], r["sugar_per_100g"],
                    r["default_weight_per_piece_g"], r["default_serving_g"],
                    r["inflammation_score"], r["inflammation_triggers"],
                    r["glycemic_load"], r["fodmap_rating"], r["fodmap_reason"],
                    r["added_sugar_g"], r["is_ultra_processed"],
                    r["rating"], r["rating_reason"],
                    r["saturated_fat_g"], r["trans_fat_g"], r["cholesterol_mg"],
                    r["sodium_mg"], r["potassium_mg"], r["calcium_mg"],
                    r["iron_mg"], r["magnesium_mg"], r["zinc_mg"],
                    r["phosphorus_mg"], r["selenium_ug"], r["copper_mg"],
                    r["manganese_mg"], r["vitamin_a_ug"], r["vitamin_c_mg"],
                    r["vitamin_d_iu"], r["vitamin_e_mg"], r["vitamin_k_ug"],
                    r["vitamin_b1_mg"], r["vitamin_b2_mg"], r["vitamin_b3_mg"],
                    r["vitamin_b5_mg"], r["vitamin_b6_mg"], r["vitamin_b7_ug"],
                    r["vitamin_b9_ug"], r["vitamin_b12_ug"], r["choline_mg"],
                    r["omega3_g"], r["omega6_g"],
                    timeout=15,
                )
                promoted_names.append(r["food_name_normalized"])
                n_ok += 1
            except Exception as e:  # noqa: BLE001
                n_fail += 1
                logger.warning(
                    f"[upsert] failed for {r['food_name_normalized']!r}: {e}"
                )

        # Step 3: mark contributing rows as promoted (skip user_edited via WHERE)
        if promoted_names:
            await conn.execute(MARK_PROMOTED_SQL, promoted_names, timeout=60)

        elapsed = time.time() - t0
        logger.info(
            f"[done] promoted={n_ok} failed={n_fail} in {elapsed:.1f}s"
        )
        return 0 if n_fail == 0 else 1
    finally:
        await conn.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
