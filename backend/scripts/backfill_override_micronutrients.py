"""USDA → Gemini hybrid backfill for the 15 micronutrient columns on
food_nutrition_overrides.

PARALLEL-SAFE with backfill_override_enrichment.py:
  * Different columns (saturated_fat_g / sodium_mg / vitamin_a_ug / ... vs
    inflammation_score / fodmap_rating / ...).
  * Different attempt counter (micronutrients_attempts vs enrichment_attempts).
  * Different timestamp (micronutrients_backfilled_at vs enrichment_backfilled_at).
  * Both scripts can update the same row concurrently — Postgres handles
    multi-column UPDATE WHERE id=X cleanly under MVCC.

Pipeline per row:
  1. USDA pass: search USDA FoodData Central by display_name. If a Foundation
     or SR Legacy match has populated nutrient values → write USDA values
     with nutrient_source='usda_fdc'. Validator runs as a sanity check;
     USDA data should pass cleanly but rejects bad matches.
  2. Gemini fallback: any row not satisfied by USDA goes to a batched Gemini
     call (same write-then-validate-cleanup pattern as the enrichment script).
     Writes with nutrient_source='gemini_estimate'.

Resumable + retry-capped:
  * micronutrients_attempts increments on EVERY Gemini write; capped at 3.
  * USDA attempts NOT counted (free, deterministic — re-running just hits
    cache or re-queries).
  * Failed Gemini items get NULLed and re-tried until cap.

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.backfill_override_micronutrients

Live progress (other terminal):
    SELECT
      nutrient_source,
      COUNT(*) FILTER (WHERE nutrient_source IS NOT NULL)        AS done,
      COUNT(*) FILTER (WHERE nutrient_source IS NULL
                        AND micronutrients_attempts < 3)         AS retryable,
      COUNT(*) FILTER (WHERE nutrient_source IS NULL
                        AND micronutrients_attempts >= 3)        AS parked
    FROM food_nutrition_overrides
    GROUP BY nutrient_source;

Knobs (env):
    LIMIT_ROWS=N          — process at most N rows this run (smoke testing)
    SKIP_USDA=1           — skip USDA pass entirely (Gemini-only mode)
    SKIP_GEMINI=1         — skip Gemini fallback (USDA-only mode)
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import random
import sys
import time
from pathlib import Path
from typing import Dict, List, Optional, Sequence, Tuple

import asyncpg
from dotenv import load_dotenv
from google import genai
from google.genai import types

ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from models.gemini_schemas import MicronutrientItem  # noqa: E402
from scripts._micronutrients_validator import (  # noqa: E402
    MICRONUTRIENT_COLUMNS, Severity, validate, has_errors, Finding,
)
from services.usda_food_service import (  # noqa: E402
    get_usda_food_service, FoodDataType,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("backfill_micronutrients")

# Suppress the verbose `thought_signature` warning the google-genai SDK emits
# on every non-text response part. It floods our logs (~3 lines per Gemini
# call) and is harmless — we extract text-only content anyway.
logging.getLogger("google_genai.types").setLevel(logging.ERROR)
logging.getLogger("google.genai.types").setLevel(logging.ERROR)


# ---------------------------------------------------------------------------
# Pooler-resilient DB execution
# ---------------------------------------------------------------------------

# Errors that mean "Supabase pooler killed our query" but the underlying data
# state is consistent. Retrying with a fresh connection is safe and usually
# succeeds because the pooler frees up slots quickly.
_TRANSIENT_DB_ERRORS = (
    asyncpg.exceptions.QueryCanceledError,
    asyncpg.exceptions.ConnectionDoesNotExistError,
    asyncpg.exceptions.ConnectionFailureError,
    asyncpg.exceptions.InterfaceError,
    asyncio.TimeoutError,
    OSError,  # 'connection was closed in the middle of operation'
)
_DB_RETRY_BACKOFF = (5.0, 15.0, 30.0, 60.0)


async def _resilient_execute(
    pool: asyncpg.Pool, op_name: str, fn,
):
    """Run an async DB operation with retry on transient pooler errors.

    fn is an async callable taking a connection. We retry the WHOLE
    operation (acquire + execute) on transient errors so a dead connection
    isn't reused. Returns whatever fn returns.
    """
    last_err: Exception | None = None
    for attempt in range(len(_DB_RETRY_BACKOFF) + 1):
        try:
            async with pool.acquire() as conn:
                return await fn(conn)
        except _TRANSIENT_DB_ERRORS as e:
            last_err = e
            if attempt < len(_DB_RETRY_BACKOFF):
                delay = _DB_RETRY_BACKOFF[attempt]
                logger.warning(
                    "[db:%s] attempt %d failed (%s: %s) — retry in %.0fs",
                    op_name, attempt + 1, type(e).__name__,
                    str(e)[:100], delay,
                )
                await asyncio.sleep(delay)
                continue
            break
    logger.error(
        "[db:%s] PERMANENT FAILURE after %d attempts: %s",
        op_name, len(_DB_RETRY_BACKOFF) + 1, last_err,
    )
    raise last_err

GEMINI_MODEL = os.environ.get("GEMINI_BACKFILL_MODEL", "gemini-3.1-flash-lite")

ROWS_PER_GEMINI_BATCH = 50
GEMINI_CONCURRENT_CALLS = 8  # Same as enrichment — avoids 429 cascades
USDA_CONCURRENT_CALLS = 2    # Tightened from 5 — FDC's 1000/hr cap is real,
                             # 5-concurrent ran us into constant rate limiting.
USDA_COOLDOWN_SECONDS = 300  # When USDA returns 429, pause ALL USDA calls for
                             # 5 min. Within the window, the script skips
                             # USDA entirely and routes everything to Gemini.
MAX_ATTEMPTS = 3
RETRY_BACKOFF = [2.0, 5.0, 15.0, 45.0, 90.0]
DB_POOL_MIN = 4
DB_POOL_MAX = 12

LIMIT_ROWS = int(os.environ.get("LIMIT_ROWS", "0"))
SKIP_USDA = bool(int(os.environ.get("SKIP_USDA", "0")))
SKIP_GEMINI = bool(int(os.environ.get("SKIP_GEMINI", "0")))

# ---------------------------------------------------------------------------
# Gemini system prompt (text-only — no images, just dish info + macros)
# ---------------------------------------------------------------------------

GEMINI_SYSTEM_PROMPT = """You estimate per-100 g micronutrient values for foods. Your output is validated against deterministic ranges; rejected items are re-tried.

For each input dish you receive its name, display name, region, and per-100 g macronutrients (protein/carbs/fat/fiber/sugar). You return 15 micronutrient fields per dish, all per 100 g of food.

ESTIMATION GUIDELINES — base your numbers on USDA-style reference values for similar foods:

* saturated_fat_g — subset of total fat. NEVER exceeds total fat. For animal foods + tropical oils, typically 30-60% of total fat. Plant oils (olive, canola, sunflower) <15% of fat.
* trans_fat_g — 0 for whole foods. Only meaningful (>0) for hydrogenated margarines, deep-fried fast food, partially-hydrogenated commercial baked goods.
* cholesterol_mg — 0 for plant foods (always). Animal foods: muscle meat 50-90, organ meats 200-500, brain ~3000, egg yolk ~1085, cheese 50-100, butter ~215.
* sodium_mg — varies hugely by preparation. Plain whole foods <100. Canned/processed 300-1000. Fast food 400-1500. Salt itself 38758.
* potassium_mg — leafy greens / banana / potato 300-500. Most foods <300. Dried herbs up to 3700.
* calcium_mg — dairy 100-200, hard cheeses 700-1200, leafy greens 100-300, fortified plant milks ~120.
* iron_mg — heme iron in meat 1-3, organ meats 5-25, legumes 3-7, leafy greens 2-7, dried herbs/spices up to 100.
* magnesium_mg — nuts/seeds 200-400, dark chocolate ~228, leafy greens 70-100, whole grains 50-150.
* zinc_mg — oysters ~78, beef 4-7, pumpkin seeds ~7, nuts/legumes 2-4.
* phosphorus_mg — meat/fish 200-400, dairy 90-700, nuts/seeds 300-700, whole grains 200-400.
* selenium_ug — brazil nuts ~1900, fish/seafood 30-90, meat 10-40, whole grains 10-30. Most foods <50.
* vitamin_a_ug — RAE μg. Beef liver ~9442, sweet potato ~709, carrots ~835, leafy greens 100-500, eggs ~140.
* vitamin_c_mg — citrus 30-60, peppers 80-200, broccoli ~89, leafy greens 30-50, acerola ~1677. 0 for meat/grains/fats.
* vitamin_d_iu — fortified milk ~40, fatty fish 200-1000, egg yolk ~37. 0 for plants and most meats.
* omega3_g — flaxseed/chia 17-22, walnuts ~9, fatty fish 1-3, plant oils <0.1, animal fats trace.

CRITICAL RULES (validation will reject violations):
1. row_id MUST echo the input id exactly.
2. saturated_fat_g must NOT exceed the input total fat_per_100g.
3. omega3_g + (estimated omega6_g) must NOT exceed total fat.
4. All values are per 100 g of food (not per serving, not per piece).
5. For values you genuinely don't know, return 0.0 — DO NOT fabricate. The validator's "all zeros for a non-trivial calorie food" warning is preferred over hallucinated values.
6. Return one MicronutrientItem per input dish, in the same order.

Top-level response is a JSON array of MicronutrientItems.
"""

USER_PROMPT_TEMPLATE = """Estimate per-100g micronutrients for these {n} dishes. Echo each id exactly.

INPUT (JSON list):
{input_json}
"""

# ---------------------------------------------------------------------------
# DB queries
# ---------------------------------------------------------------------------

FETCH_PENDING_BATCH = """
SELECT id, food_name_normalized, display_name,
       COALESCE(region, country_name)         AS region,
       calories_per_100g, protein_per_100g,
       carbs_per_100g, fat_per_100g,
       fiber_per_100g, sugar_per_100g,
       source
FROM food_nutrition_overrides
WHERE nutrient_source IS NULL
  AND micronutrients_attempts < $3
ORDER BY micronutrients_attempts, id
LIMIT $1
OFFSET $2
"""

# Two write paths — USDA writes a fixed source, Gemini writes a different one.
# Both bump micronutrients_attempts so the cap applies uniformly. The Gemini
# attempts counter alone wouldn't suffice for the cap on rows that have USDA
# match but no fields populated; we increment for both to keep accounting
# simple.
# All 29 micronutrient columns on food_nutrition_overrides. The order here
# is the canonical order used by every WRITE/CLEAR query and the JSONB
# payload builders. Keep in sync with mig 324 + mig 2073 + the validator's
# RANGES dict.
ALL_MICRONUTRIENT_COLS = (
    "saturated_fat_g", "trans_fat_g", "cholesterol_mg",
    "sodium_mg", "potassium_mg", "calcium_mg", "iron_mg", "magnesium_mg",
    "zinc_mg", "phosphorus_mg", "selenium_ug", "copper_mg", "manganese_mg",
    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
    "vitamin_e_mg", "vitamin_k_ug",
    "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b5_mg",
    "vitamin_b6_mg", "vitamin_b7_ug", "vitamin_b9_ug", "vitamin_b12_ug",
    "choline_mg",
    "omega3_g", "omega6_g",
)

_SET_CLAUSES = ",\n  ".join(f"{c} = v.{c}" for c in ALL_MICRONUTRIENT_COLS)
_RECORDSET_COLS = ", ".join(f"{c} REAL" for c in ALL_MICRONUTRIENT_COLS)
_NULL_CLAUSES = ",\n  ".join(f"{c} = NULL" for c in ALL_MICRONUTRIENT_COLS)

WRITE_USDA_SQL = f"""
UPDATE food_nutrition_overrides AS f SET
  {_SET_CLAUSES},
  nutrient_source = 'usda_fdc',
  micronutrients_backfilled_at = NOW(),
  micronutrients_attempts = f.micronutrients_attempts + 1,
  micronutrients_last_violation = NULL
FROM jsonb_to_recordset($1::jsonb) AS v(
  row_id INTEGER, {_RECORDSET_COLS}
)
WHERE f.id = v.row_id;
"""

WRITE_GEMINI_SQL = WRITE_USDA_SQL.replace(
    "nutrient_source = 'usda_fdc'",
    "nutrient_source = 'gemini_estimate'",
)

CLEAR_INVALID_SQL = f"""
UPDATE food_nutrition_overrides AS f SET
  {_NULL_CLAUSES},
  nutrient_source = NULL,
  micronutrients_backfilled_at = NULL,
  micronutrients_last_violation = v.violation
FROM jsonb_to_recordset($1::jsonb) AS v(row_id INTEGER, violation TEXT)
WHERE f.id = v.row_id;
"""


# ---------------------------------------------------------------------------
# USDA pass
# ---------------------------------------------------------------------------

def _usda_food_to_item(usda_food, row: dict) -> dict:
    """Convert a USDAFood (with USDANutrients) to the JSONB write payload.

    NULL semantics: when USDA's response for this food did NOT include a
    given nutrient ID, the column is written as NULL — NOT as 0.0. This
    distinguishes "measured zero" (e.g. cholesterol on plant foods, real)
    from "no data" (e.g. omega-3 on most non-fish branded foods, fake zero).
    Per user direction (2026-05-14): NULL > wrong data.

    The mapping below is (column, list-of-valid-USDA-IDs). For omega-3 and
    omega-6 we sum multiple fatty-acid IDs — present iff ANY of them was
    present.
    """
    from services.usda_food_service import NUTRIENT_IDS
    n = usda_food.nutrients
    present = usda_food.nutrients.present_nutrient_ids

    def _v(col_field: str, *nutrient_keys: str, transform=lambda x: x):
        """Return the dataclass field value if any of the named nutrient_keys
        was actually present in the USDA response, else None."""
        ids_for_keys = {NUTRIENT_IDS[k] for k in nutrient_keys}
        if not (ids_for_keys & present):
            return None
        raw = getattr(n, col_field, 0.0) or 0.0
        return transform(float(raw))

    return {
        "row_id":           row["id"],
        "saturated_fat_g":  _v("saturated_fat_per_100g", "saturated_fat"),
        "trans_fat_g":      _v("trans_fat_per_100g",     "trans_fat"),
        "cholesterol_mg":   _v("cholesterol_mg_per_100g", "cholesterol"),
        "sodium_mg":        _v("sodium_mg_per_100g",     "sodium"),
        "potassium_mg":     _v("potassium_mg_per_100g",  "potassium"),
        "calcium_mg":       _v("calcium_mg_per_100g",    "calcium"),
        "iron_mg":          _v("iron_mg_per_100g",       "iron"),
        "magnesium_mg":     _v("magnesium_mg_per_100g",  "magnesium"),
        "zinc_mg":          _v("zinc_mg_per_100g",       "zinc"),
        "phosphorus_mg":    _v("phosphorus_mg_per_100g", "phosphorus"),
        "selenium_ug":      _v("selenium_ug_per_100g",   "selenium"),
        "copper_mg":        _v("copper_mg_per_100g",     "copper"),
        "manganese_mg":     _v("manganese_mg_per_100g",  "manganese"),
        "vitamin_a_ug":     _v("vitamin_a_mcg_per_100g", "vitamin_a"),
        "vitamin_c_mg":     _v("vitamin_c_mg_per_100g",  "vitamin_c"),
        # Vitamin D: USDA reports μg; food_nutrition_overrides stores IU. 1μg=40IU.
        "vitamin_d_iu":     _v("vitamin_d_mcg_per_100g", "vitamin_d",
                               transform=lambda x: x * 40),
        "vitamin_e_mg":     _v("vitamin_e_mg_per_100g",  "vitamin_e"),
        "vitamin_k_ug":     _v("vitamin_k_ug_per_100g",  "vitamin_k"),
        "vitamin_b1_mg":    _v("vitamin_b1_mg_per_100g", "vitamin_b1"),
        "vitamin_b2_mg":    _v("vitamin_b2_mg_per_100g", "vitamin_b2"),
        "vitamin_b3_mg":    _v("vitamin_b3_mg_per_100g", "vitamin_b3"),
        "vitamin_b5_mg":    _v("vitamin_b5_mg_per_100g", "vitamin_b5"),
        "vitamin_b6_mg":    _v("vitamin_b6_mg_per_100g", "vitamin_b6"),
        "vitamin_b7_ug":    _v("vitamin_b7_ug_per_100g", "vitamin_b7"),
        "vitamin_b9_ug":    _v("folate_mcg_per_100g",    "folate"),  # folate = B9
        "vitamin_b12_ug":   _v("vitamin_b12_mcg_per_100g", "vitamin_b12"),
        "choline_mg":       _v("choline_mg_per_100g",    "choline"),
        # Omega-3 sum: present iff ANY of the four constituent fatty acids
        # was reported by USDA.
        "omega3_g":         _v("omega3_g_per_100g",
                               "omega3_ala", "omega3_epa",
                               "omega3_dha", "omega3_dpa"),
        "omega6_g":         _v("omega6_g_per_100g",
                               "omega6_la", "omega6_ara"),
    }


def _usda_match_is_useful(usda_food) -> bool:
    """Reject USDA matches that returned essentially empty nutrient data.
    Some Branded foods only ship with macros + sodium; minerals/vitamins NULL.
    We require at least 5 micronutrients with non-zero values to consider
    the match worth writing."""
    n = usda_food.nutrients
    candidates = (
        n.sodium_mg_per_100g, n.potassium_mg_per_100g, n.calcium_mg_per_100g,
        n.iron_mg_per_100g, n.magnesium_mg_per_100g, n.zinc_mg_per_100g,
        n.cholesterol_mg_per_100g, n.saturated_fat_per_100g,
        getattr(n, "vitamin_a_mcg_per_100g", 0),
        getattr(n, "vitamin_c_mg_per_100g", 0),
        getattr(n, "phosphorus_mg_per_100g", 0),
        getattr(n, "vitamin_b9_ug_per_100g", 0),
        getattr(n, "folate_mcg_per_100g", 0),
        getattr(n, "vitamin_b12_mcg_per_100g", 0),
    )
    populated = sum(1 for v in candidates if v and v > 0)
    return populated >= 5


# Global USDA cooldown state. When _usda_cooldown_until is in the future,
# usda_lookup_one short-circuits — no API call attempted, immediate fallback
# to Gemini. Updated by any task that hits a rate-limit error.
_usda_cooldown_until = 0.0
_usda_rate_limit_hits = 0


def _is_usda_rate_limit(e: Exception) -> bool:
    msg = str(e).lower()
    return any(s in msg for s in (
        "rate limit", "rate_limit", "rate-limit", "429",
        "too many requests", "quota", "exceeded",
    ))


def _trip_usda_cooldown() -> float:
    """Set a global cooldown window. Returns the cooldown end time."""
    global _usda_cooldown_until, _usda_rate_limit_hits
    _usda_rate_limit_hits += 1
    # Exponential cooldown if we keep hitting it: 5min, 10min, 20min, capped 30min
    multiplier = min(2 ** (_usda_rate_limit_hits - 1), 6)
    duration = USDA_COOLDOWN_SECONDS * multiplier
    new_until = time.time() + duration
    if new_until > _usda_cooldown_until:
        _usda_cooldown_until = new_until
        logger.warning(
            "[usda] rate limit hit (#%d) — cooling down for %.0fs (until %s)",
            _usda_rate_limit_hits, duration,
            time.strftime("%H:%M:%S", time.localtime(new_until)),
        )
    return _usda_cooldown_until


def _is_usda_cooled_down() -> bool:
    """True if the cooldown window has expired and we should resume USDA."""
    return time.time() >= _usda_cooldown_until


async def usda_lookup_one(
    sem: asyncio.Semaphore, usda_service, row: dict,
) -> Optional[dict]:
    """Try to find a useful USDA match for a single row. Returns a write-ready
    dict or None (None → falls through to Gemini fallback).

    Cooldown-aware: if a previous task tripped the USDA cooldown, this
    function returns None immediately without hitting the API. That way the
    script keeps making forward progress on Gemini fallback while USDA's
    quota window resets.
    """
    if not _is_usda_cooled_down():
        return None  # in cooldown, skip USDA entirely
    async with sem:
        # Re-check cooldown after acquiring the semaphore (another task may
        # have tripped it while we were waiting).
        if not _is_usda_cooled_down():
            return None
        # Search by display_name first (more natural language); fall back to
        # food_name_normalized if display has no hits.
        for query in (row.get("display_name"), row.get("food_name_normalized")):
            if not query:
                continue
            try:
                result = await usda_service.search_foods(
                    query=query,
                    page_size=5,
                    data_types=[
                        FoodDataType.FOUNDATION.value,
                        FoodDataType.SR_LEGACY.value,
                        FoodDataType.SURVEY_FNDDS.value,
                    ],
                )
            except Exception as e:  # noqa: BLE001
                if _is_usda_rate_limit(e):
                    _trip_usda_cooldown()
                    return None
                logger.warning(
                    "[usda] %r search failed: %s — falling through to Gemini",
                    query, str(e)[:120],
                )
                return None
            if not result.foods:
                continue
            top = result.foods[0]
            try:
                full = await usda_service.get_food(top.fdc_id)
            except Exception as e:  # noqa: BLE001
                if _is_usda_rate_limit(e):
                    _trip_usda_cooldown()
                    return None
                logger.warning(
                    "[usda] get_food(%d) failed: %s",
                    top.fdc_id, str(e)[:120],
                )
                return None
            if full and _usda_match_is_useful(full):
                return _usda_food_to_item(full, row)
        return None


async def usda_pass(
    pool: asyncpg.Pool,
    usda_service,
    rows: List[asyncpg.Record],
    progress: "Progress",
) -> Tuple[int, List[dict]]:
    """Try USDA on every row. Writes successful matches in one bulk UPDATE.
    Returns (n_usda_hits, rows_for_gemini_fallback).

    USDA writes are NOW validated (mig 2070-style write-then-validate-cleanup).
    Bad USDA matches (e.g. wrong food entirely, or impossible-range values)
    get their fields NULLed and routed to Gemini fallback. This catches the
    'Amul Ghee → Vitamin C 10.4' style mismatch the smoke test surfaced.
    """
    sem = asyncio.Semaphore(USDA_CONCURRENT_CALLS)
    tasks = [
        asyncio.create_task(usda_lookup_one(sem, usda_service, dict(r)))
        for r in rows
    ]
    results = await asyncio.gather(*tasks)

    usda_candidates: List[Tuple[dict, dict]] = []  # (write_item, source_row)
    fallback_rows: List[dict] = []
    for row, result in zip(rows, results):
        source = dict(row)
        if result is None:
            fallback_rows.append(source)
        else:
            usda_candidates.append((result, source))

    # Validate USDA writes BEFORE persisting. Failed validation → route the
    # row to Gemini fallback instead of writing bad data.
    valid_usda_writes: List[dict] = []
    for item, source in usda_candidates:
        findings = validate(item, source)
        for f in findings:
            progress.validation_stats[f"usda:{f.rule}"] = (
                progress.validation_stats.get(f"usda:{f.rule}", 0) + 1
            )
        if has_errors(findings):
            err_msgs = " | ".join(
                f"{f.rule}: {f.message}"
                for f in findings if f.severity == Severity.ERROR
            )
            logger.warning(
                "[validator] USDA REJECT row_id=%d (%s) — %s — falling to Gemini",
                source["id"], source.get("display_name", ""), err_msgs,
            )
            fallback_rows.append(source)
            continue
        valid_usda_writes.append(item)

    if valid_usda_writes:
        payload = json.dumps(valid_usda_writes)
        await _resilient_execute(
            pool, "write_usda",
            lambda conn: conn.execute(WRITE_USDA_SQL, payload),
        )

    return len(valid_usda_writes), fallback_rows


# ---------------------------------------------------------------------------
# Gemini fallback
# ---------------------------------------------------------------------------

def _build_input_json(rows: Sequence[dict]) -> str:
    return json.dumps(
        [
            {
                "id":            r["id"],
                "name":          r["food_name_normalized"],
                "display_name":  r["display_name"],
                "region":        r["region"],
                "kcal_per_100g": r["calories_per_100g"],
                "protein_g":     r["protein_per_100g"],
                "carbs_g":       r["carbs_per_100g"],
                "fat_g":         r["fat_per_100g"],
                "fiber_g":       r["fiber_per_100g"],
                "sugar_g":       r["sugar_per_100g"],
            }
            for r in rows
        ],
        separators=(",", ":"),
    )


async def call_gemini(
    client: genai.Client, rows: Sequence[dict],
) -> List[MicronutrientItem]:
    user_prompt = USER_PROMPT_TEMPLATE.format(
        n=len(rows), input_json=_build_input_json(rows)
    )
    config = types.GenerateContentConfig(
        system_instruction=GEMINI_SYSTEM_PROMPT,
        response_mime_type="application/json",
        response_schema=list[MicronutrientItem],
        temperature=0.1,
        # 29 fields × ~15 tokens × 50 rows = ~22k tokens needed minimum.
        # Set 32k to leave headroom for verbose decimal formatting.
        max_output_tokens=32000,
    )
    response = await client.aio.models.generate_content(
        model=GEMINI_MODEL, contents=[user_prompt], config=config,
    )
    raw = response.text.strip() if response and response.text else ""
    if not raw:
        raise RuntimeError("Empty response from Gemini")
    raw_list = json.loads(raw)
    if not isinstance(raw_list, list):
        raise RuntimeError(
            f"Expected JSON array from Gemini, got {type(raw_list).__name__}"
        )
    return [MicronutrientItem.model_validate(it) for it in raw_list]


def _validate_id_alignment(
    expected_ids: Sequence[int], items: Sequence[MicronutrientItem],
) -> List[MicronutrientItem]:
    expected = set(expected_ids)
    return [it for it in items if it.row_id in expected]


def _validate_quality(
    items: Sequence[MicronutrientItem],
    rows_by_id: dict,
    validation_stats: dict,
) -> Tuple[List[MicronutrientItem], List[Tuple[int, str]]]:
    accepted: List[MicronutrientItem] = []
    invalid: List[Tuple[int, str]] = []
    for it in items:
        source = rows_by_id.get(it.row_id)
        if source is None:
            continue
        item_dict = it.model_dump()
        findings = validate(item_dict, source)
        for f in findings:
            validation_stats[f.rule] = validation_stats.get(f.rule, 0) + 1
        if has_errors(findings):
            joined = " | ".join(
                f"{f.rule}: {f.message}"
                for f in findings if f.severity == Severity.ERROR
            )
            logger.warning(
                "[validator] CLEAR row_id=%d (%s) — %s",
                it.row_id, source.get("display_name", ""), joined,
            )
            invalid.append((it.row_id, joined))
            continue
        accepted.append(it)
    return accepted, invalid


def _is_rate_limit_error(e: Exception) -> bool:
    msg = str(e).lower()
    return any(s in msg for s in ("429", "resource_exhausted", "rate limit", "quota"))


async def gemini_write_batch(
    pool: asyncpg.Pool, items: Sequence[MicronutrientItem],
) -> None:
    """Bulk-write Gemini-estimated micronutrients to DB. Builds the JSONB
    payload from each MicronutrientItem field, in the same column order as
    ALL_MICRONUTRIENT_COLS so WRITE_GEMINI_SQL can unpack it cleanly.
    """
    if not items:
        return
    payload = json.dumps([
        {"row_id": it.row_id, **{
            col: float(getattr(it, col)) for col in ALL_MICRONUTRIENT_COLS
        }}
        for it in items
    ])
    await _resilient_execute(
        pool, "write_gemini",
        lambda conn: conn.execute(WRITE_GEMINI_SQL, payload),
    )


async def clear_invalid(
    pool: asyncpg.Pool, invalid: List[Tuple[int, str]],
) -> None:
    if not invalid:
        return
    payload = json.dumps([
        {"row_id": rid, "violation": viol} for rid, viol in invalid
    ])
    await _resilient_execute(
        pool, "clear_invalid",
        lambda conn: conn.execute(CLEAR_INVALID_SQL, payload),
    )


async def gemini_process_batch(
    sem: asyncio.Semaphore,
    client: genai.Client,
    pool: asyncpg.Pool,
    rows: List[dict],
    progress: "Progress",
) -> None:
    async with sem:
        # Bump attempts UP FRONT, even before Gemini call — so an exception
        # mid-call still consumes an attempt and the row eventually parks.
        # We do this by writing a no-op (just attempts++) on entry. Cheaper:
        # we let the WRITE_GEMINI_SQL below do it on success, and rely on
        # the script log + Gemini retries within MAX_RETRIES for failures.
        expected_ids = [r["id"] for r in rows]
        rows_by_id = {r["id"]: r for r in rows}
        last_err: Exception | None = None
        for attempt in range(len(RETRY_BACKOFF) + 1):
            try:
                items = await call_gemini(client, rows)
                aligned = _validate_id_alignment(expected_ids, items)
                if not aligned:
                    raise RuntimeError("All returned items had row_id mismatches")
                # Step 1 (write everything) + Step 2 (validate) + Step 3 (clear bad)
                await gemini_write_batch(pool, aligned)
                accepted, invalid = _validate_quality(
                    aligned, rows_by_id, progress.validation_stats,
                )
                if invalid:
                    await clear_invalid(pool, invalid)
                ok = len(accepted)
                cleared = len(invalid)
                gemini_dropped = len(rows) - len(aligned)
                await progress.add_gemini(ok, cleared, gemini_dropped)
                return
            except Exception as e:  # noqa: BLE001
                last_err = e
                if attempt < len(RETRY_BACKOFF):
                    base = RETRY_BACKOFF[attempt]
                    if _is_rate_limit_error(e):
                        base = max(base, 60.0)
                    delay = base + random.uniform(0, 2)
                    kind = "429" if _is_rate_limit_error(e) else "transient"
                    logger.warning(
                        "[gemini] attempt %d failed (%s): %s — retry in %.1fs",
                        attempt + 1, kind, str(e)[:140], delay,
                    )
                    await asyncio.sleep(delay)
                    continue
                break
        logger.error(
            "[gemini] PERMANENT FAILURE after %d attempts: %s — %d rows will "
            "retry on the next script run",
            len(RETRY_BACKOFF) + 1, last_err, len(rows),
        )
        await progress.add_gemini(0, 0, len(rows))


# ---------------------------------------------------------------------------
# Progress + main
# ---------------------------------------------------------------------------

class Progress:
    def __init__(self, total: int):
        self.total = total
        self.usda_done = 0
        self.gemini_done = 0
        self.cleared_validator = 0
        self.gemini_failed = 0
        self.validation_stats: dict = {}
        self.started_at = time.time()
        self._lock = asyncio.Lock()

    async def add_usda(self, n_hits: int) -> None:
        async with self._lock:
            self.usda_done += n_hits
            self._log()

    async def add_gemini(self, ok: int, cleared: int, fail: int) -> None:
        async with self._lock:
            self.gemini_done += ok
            self.cleared_validator += cleared
            self.gemini_failed += fail
            self._log()

    def _log(self) -> None:
        done = self.usda_done + self.gemini_done
        elapsed = time.time() - self.started_at
        rate = done / elapsed if elapsed > 0 else 0
        eta = max(self.total - done, 0) / rate if rate > 0 else 0
        cooldown_msg = ""
        if not _is_usda_cooled_down():
            cooldown_left = _usda_cooldown_until - time.time()
            cooldown_msg = f" | USDA cooldown {cooldown_left:.0f}s left"
        # Surface validator warning + error totals so "validator-cleared=0"
        # isn't misleading. cleared = errors that NULLed the row; warnings
        # are flagged-but-accepted findings.
        n_warnings = sum(
            v for k, v in self.validation_stats.items() if not k.startswith("usda:")
        ) - self.cleared_validator
        n_usda_findings = sum(
            v for k, v in self.validation_stats.items() if k.startswith("usda:")
        )
        logger.info(
            "[progress] %d/%d (%.1f%%) | usda=%d gemini=%d | "
            "cleared=%d warn=%d usda-findings=%d gemini-failed=%d | "
            "%.0f rows/min | ETA %.1f min%s",
            done, self.total, 100 * done / max(self.total, 1),
            self.usda_done, self.gemini_done,
            self.cleared_validator, max(n_warnings, 0), n_usda_findings,
            self.gemini_failed, rate * 60, eta / 60,
            cooldown_msg,
        )


FETCH_TOTAL_SQL = """
SELECT COUNT(*) FROM food_nutrition_overrides
WHERE nutrient_source IS NULL AND micronutrients_attempts < $1
"""


async def main() -> int:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key and not SKIP_GEMINI:
        logger.error("GEMINI_API_KEY not set in backend/.env")
        return 2
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        logger.error("DATABASE_URL not set in backend/.env")
        return 2
    asyncpg_url = db_url.replace("postgresql+asyncpg://", "postgresql://")

    client = genai.Client(api_key=api_key) if not SKIP_GEMINI else None
    usda_service = get_usda_food_service() if not SKIP_USDA else None
    pool = await asyncpg.create_pool(
        asyncpg_url, min_size=DB_POOL_MIN, max_size=DB_POOL_MAX,
        statement_cache_size=0,
    )

    try:
        async with pool.acquire() as conn:
            pending = await conn.fetchval(FETCH_TOTAL_SQL, MAX_ATTEMPTS)
        total = min(pending, LIMIT_ROWS) if LIMIT_ROWS > 0 else pending
        logger.info(
            "[start] %d rows pending | LIMIT_ROWS=%s | model=%s | "
            "USDA conc=%d Gemini conc=%d | SKIP_USDA=%s SKIP_GEMINI=%s",
            total, LIMIT_ROWS or "none", GEMINI_MODEL,
            USDA_CONCURRENT_CALLS, GEMINI_CONCURRENT_CALLS,
            SKIP_USDA, SKIP_GEMINI,
        )
        if total == 0:
            logger.info("[start] nothing to do")
            return 0

        progress = Progress(total)
        gemini_sem = asyncio.Semaphore(GEMINI_CONCURRENT_CALLS)
        in_flight_ids: set = set()
        gemini_tasks: list = []
        scheduled = 0
        # Outer fetch loop. Each fetch returns up to FETCH_PAGE rows; we route
        # them through USDA pass (parallel within the fetch), then dispatch
        # Gemini fallback batches concurrently.
        FETCH_PAGE = ROWS_PER_GEMINI_BATCH * 4

        while True:
            if LIMIT_ROWS > 0 and scheduled >= LIMIT_ROWS:
                break
            rows = await _resilient_execute(
                pool, "fetch_batch",
                lambda conn: conn.fetch(
                    FETCH_PENDING_BATCH, FETCH_PAGE, 0, MAX_ATTEMPTS,
                ),
            )
            rows = [r for r in rows if r["id"] not in in_flight_ids]
            if LIMIT_ROWS > 0:
                rows = rows[: max(LIMIT_ROWS - scheduled, 0)]
            if not rows:
                if not gemini_tasks:
                    break
                done, gemini_tasks_pending = await asyncio.wait(
                    gemini_tasks, return_when=asyncio.FIRST_COMPLETED,
                )
                gemini_tasks = list(gemini_tasks_pending)
                continue

            # USDA pass (synchronous within the fetch — finishes before
            # we hand the misses to Gemini).
            fallback_rows = [dict(r) for r in rows]
            if not SKIP_USDA:
                in_flight_ids.update(r["id"] for r in rows)
                n_usda, fallback_rows = await usda_pass(
                    pool, usda_service, rows, progress,
                )
                # Successful USDA writes are done — release their ids.
                usda_ids = {r["id"] for r in rows} - {fr["id"] for fr in fallback_rows}
                in_flight_ids.difference_update(usda_ids)
                await progress.add_usda(n_usda)
                scheduled += n_usda
            else:
                in_flight_ids.update(r["id"] for r in fallback_rows)

            # Gemini fallback for USDA misses
            if SKIP_GEMINI:
                # Park the fallback rows by writing the violation
                if fallback_rows:
                    payload = json.dumps([
                        {"row_id": r["id"], "violation": "skipped (SKIP_GEMINI=1)"}
                        for r in fallback_rows
                    ])
                    await _resilient_execute(
                        pool, "skip_gemini_park",
                        lambda conn: conn.execute(CLEAR_INVALID_SQL, payload),
                    )
                    in_flight_ids.difference_update(r["id"] for r in fallback_rows)
                continue

            for i in range(0, len(fallback_rows), ROWS_PER_GEMINI_BATCH):
                chunk = fallback_rows[i:i + ROWS_PER_GEMINI_BATCH]
                ids = [r["id"] for r in chunk]
                scheduled += len(chunk)
                task = asyncio.create_task(
                    gemini_process_batch(
                        gemini_sem, client, pool, chunk, progress,
                    )
                )

                def _cleanup(_t, _ids=ids):
                    in_flight_ids.difference_update(_ids)
                task.add_done_callback(_cleanup)
                gemini_tasks.append(task)

            if len(gemini_tasks) >= GEMINI_CONCURRENT_CALLS * 2:
                done, gemini_tasks_pending = await asyncio.wait(
                    gemini_tasks, return_when=asyncio.FIRST_COMPLETED,
                )
                gemini_tasks = list(gemini_tasks_pending)

        if gemini_tasks:
            await asyncio.gather(*gemini_tasks)

        elapsed = time.time() - progress.started_at
        logger.info(
            "[done] %d/%d done | usda=%d gemini=%d | cleared=%d failed=%d | "
            "%.1f min wall time",
            progress.usda_done + progress.gemini_done, progress.total,
            progress.usda_done, progress.gemini_done,
            progress.cleared_validator, progress.gemini_failed, elapsed / 60,
        )
        if progress.validation_stats:
            logger.info("[done] validator findings (rule -> count):")
            for rule, n in sorted(
                progress.validation_stats.items(), key=lambda kv: -kv[1]
            ):
                logger.info("    %-40s %d", rule, n)

        return 0 if progress.gemini_failed == 0 else 1
    finally:
        if usda_service is not None:
            await usda_service.close()
        await pool.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
