"""Phase-1 backfill of the 9 enrichment columns on food_nutrition_overrides.

Architecture (locked with user 2026-05-13):
- Sync Gemini 3.1 Flash Lite calls (NOT Batch API) so progress lands in the
  DB incrementally, the script is fully resumable, and there is no GCS /
  JSONL polling complexity.
- asyncio.Semaphore(20) caps concurrent in-flight calls.
- Each successful 50-row response triggers an immediate bulk
  UPDATE FROM VALUES via asyncpg; the row's enrichment_backfilled_at is
  stamped to NOW() in the same query.
- The partial index idx_food_overrides_enrichment_pending makes the
  resume-query (WHERE enrichment_backfilled_at IS NULL) O(remaining).

Cost: ~$60 against ~198k rows on Flash Lite list pricing (chosen explicitly
over ~$22 Batch API for operational simplicity).
Wall time: ~16-20 min on 20 concurrent calls.

Run:
    cd /Users/saichetangrandhe/AIFitnessCoach
    backend/.venv/bin/python -m backend.scripts.backfill_override_enrichment

Live progress (in another shell):
    SELECT
      COUNT(*) FILTER (WHERE enrichment_backfilled_at IS NOT NULL) AS done,
      COUNT(*) FILTER (WHERE enrichment_backfilled_at IS NULL)     AS remaining
    FROM food_nutrition_overrides;

Kill / restart:
    Ctrl-C is safe at any time. Re-running picks up exactly where you left
    off (the partial index makes the resume scan cheap).

Env (loaded from backend/.env):
    DATABASE_URL  — Postgres connection string (asyncpg-compatible OK)
    GEMINI_API_KEY — for the google-genai client
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
from typing import List, Sequence, Tuple

import asyncpg
from dotenv import load_dotenv
from google import genai
from google.genai import types
from pydantic import ValidationError

# Bootstrap sys.path so `from models.gemini_schemas import ...` works whether
# the script is invoked as a module or as a file path.
ROOT = Path(__file__).resolve().parents[2]
BACKEND = ROOT / "backend"
load_dotenv(BACKEND / ".env")
sys.path.insert(0, str(BACKEND))

from models.gemini_schemas import EnrichmentItem  # noqa: E402
from scripts._enrichment_validator import (  # noqa: E402
    Finding, Severity, validate, has_errors,
)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger("backfill_enrichment")

# ---------------------------------------------------------------------------
# Tunables
# ---------------------------------------------------------------------------

# Flash Lite is the locked model per user direction — supports response_schema
# + structured outputs at ~half the cost of full Flash. Override via env if
# needed for testing against a different model.
GEMINI_MODEL = os.environ.get(
    "GEMINI_BACKFILL_MODEL", "gemini-3.1-flash-lite"
)

ROWS_PER_BATCH = 50          # Number of dish rows per Gemini call
CONCURRENT_CALLS = 8         # Lowered from 20 — sustained 20-concurrent
                             # Flash-Lite calls hit 429 RESOURCE_EXHAUSTED
                             # at scale, dropped throughput from 420 rows/min
                             # (smoke) to ~21 rows/min (4hr / 5050 rows full).
MAX_RETRIES = 5              # Per-batch retry budget for transient failures
RETRY_BACKOFF = [2.0, 5.0, 15.0, 45.0, 90.0]  # Seconds; longer tail for 429s

DB_POOL_MIN = 4
DB_POOL_MAX = 10

# Testing knob: set LIMIT_ROWS=N in the env to process at most N rows in
# this run. Useful for smoke-testing the full pipeline (Gemini call → schema
# parse → bulk UPDATE → row stamping) at ~$0.02 before the $60 full run.
# The unset / 0 value means "process every pending row" (production mode).
LIMIT_ROWS = int(os.environ.get("LIMIT_ROWS", "0"))

# ---------------------------------------------------------------------------
# Prompt (cached via Gemini context cache when available — 90% input discount
# on the shared system block across 4,000 batches).
# ---------------------------------------------------------------------------

SYSTEM_PROMPT = """You are a nutrition-science classifier producing structured enrichment metadata for a food nutrition database. Your output is automatically validated against deterministic rules; items that fail validation are rejected and re-tried. Follow every rule exactly.

For each input dish you receive its name, display name, region, and per-100 g macronutrients. You return exactly nine fields per dish, never null where the schema forbids it.

FIELD RULES — read carefully:

1. inflammation_score (0-10 integer, NEVER null)
   - 0-3 anti-inflammatory: leafy greens, fatty fish, berries, olive oil, turmeric, fermented foods
   - 4-6 neutral / mildly inflammatory: most cooked whole foods, lean meats, whole grains
   - 7-10 highly inflammatory: deep-fried foods, ultra-processed snacks, seed-oil-heavy fast food, processed meats, refined-flour pastries
   - HARD CAP: low-calorie beverages (≤25 kcal/100g, ≤0.5g fat) cap at inflammation 5 even if they contain added sugar — the absolute sugar load per serving is too low. Examples: Liquid IV (10 kcal), Powerade (19 kcal), sweet iced tea, Mimosa.
   - HARD CAP: light foods (<100 kcal/100g, <5g fat, <5g sugar) cap at inflammation 6 even if they contain refined flour. Plain noodle broths, ramen, instant soup are inflammation 5-6, not 7-8.

2. inflammation_triggers (array of 0-4 short tags, MAY be empty)
   - Return [] for foods with NO genuine inflammation drivers: plain water, plain seltzer, almond milk unsweetened, plain coffee, plain tea, plain hot tea, water-based herbal teas. DO NOT invent a tag just to fill the array.
   - Otherwise pick from this canonical vocabulary: deep_fried, seed_oil, refined_flour, added_sugar, processed_meat, saturated_fat, omega6_high, artificial_additives, omega3_rich, leafy_greens, olive_oil, turmeric, whole_grains, fermented, berries, fatty_fish
   - STRICT TAG RULES (validation will reject violations):
     * `whole_grains` — ONLY for cereals: rice, oats, wheat, barley, quinoa, millet, bulgur, farro, sorghum, rye, corn, polenta, semolina, bread, pasta, noodle, tortilla, chapati, roti, naan, pita, granola, muesli, porridge, dosa, idli, paratha. NEVER for legumes (chickpeas, lentils, dal, beans, soy, tofu, TVP), fruits (jackfruit, banana, apple), vegetables (parsnip, carrot, potato), condiments (mustard, ketchup, mayo, salsa), processed bars (Clif, KIND, Larabar), composed dishes (bowls, salads, stir-fries) — even if they contain a small grain component.
     * `saturated_fat` — ONLY when fat_per_100g ≥ 4g AND the food clearly contains animal fat (beef, pork, lamb, chicken skin, butter, ghee, lard, cheese, cream, whole milk, eggs, sausage, bacon) OR tropical oil (coconut, palm). NEVER on skim/1%/2% milk (≤2g fat), turkey breast, lean chicken breast, plain coffee with a splash of milk, protein shakes with whey + water.
     * `olive_oil` — ONLY for Mediterranean / Levantine / Maghreb cuisines where olive oil is a signature ingredient (Italian, Greek, Spanish, Portuguese, Lebanese, Israeli, Turkish, Moroccan, Tunisian, Egyptian — pasta, focaccia, pesto, hummus, tabbouleh, paella, gazpacho, ratatouille, tagine, falafel, tzatziki). NEVER on plain coffee, plain almond milk, Vietnamese coffee, Asian dishes, American chain food.
     * `processed_meat` — for cured/smoked/salted/fermented meats: hot dog, sausage, bacon, ham, salami, pepperoni, bologna, kielbasa, jerky, deli meats, Spam, corned beef, prosciutto, mortadella, chorizo, liverwurst, Canadian bacon, hot pockets with meat.
   - Even anti-inflammatory dishes get tags describing WHY they're low (e.g. ["omega3_rich", "leafy_greens"]) — but [] is correct when there's truly nothing to say.

3. glycemic_load (integer per 100 g, OR -1 sentinel)
   - GL = GI × carbs_per_100g / 100
   - Use -1 (the N/A sentinel) ONLY when carbs_per_100g < 2 (zero-carb foods like meat, fish, oil, butter, hard cheese, eggs). Validation REJECTS -1 when carbs ≥ 2g.
   - Otherwise return the integer estimate. Refined sugar / white flour ≈ GI 70-90; whole grains / legumes ≈ GI 30-55; fruit ≈ GI 35-60.

4. fodmap_rating (low | medium | high, NEVER null — every dish classifies per Monash)
   - Common high-FODMAP triggers: onion, garlic, wheat, legumes, dairy lactose, apples, pears, mango, honey, high-fructose corn syrup
   - Plain meats, eggs, leafy greens, rice, oats, most fish, hard cheeses → low

5. fodmap_reason (≤ 6 words; empty string ONLY when fodmap_rating = "low")
   - Examples: "contains onion, garlic", "wheat-based pasta", "high lactose dairy"
   - REQUIRED non-empty when rating is medium or high.

6. added_sugar_g (float per 100 g, NEVER null, NEVER greater than total sugar)
   - 0.0 when no added sugar (most savory dishes, meats, vegetables, plain dairy, plain fruit)
   - Excludes naturally-occurring sugar in whole fruit and plain dairy
   - Sodas, candy, frosted cereals, sweetened yogurts, BBQ sauce → meaningful values
   - Validation REJECTS added_sugar > total sugar_per_100g (impossible).

7. is_ultra_processed (boolean, NEVER null)
   - True iff NOVA Group 4: industrial formulations with ingredients you wouldn't have in a home kitchen (high-fructose corn syrup, hydrogenated oils, modified starches, flavor enhancers, isolated proteins, artificial colors)
   - False for single-ingredient whole foods, home-cooked meals, basic restaurant fare from whole ingredients

8. rating (green | yellow | red, NEVER null — traffic-light overall health rating)
   - green: anti-inflammatory + low/medium-low GL + not ultra-processed + low/no added sugar
   - yellow: balanced or mixed signals (most cooked dishes land here)
   - red: ultra-processed + inflammatory + high GL + added sugar — fast food, sugary desserts, deep-fried snacks
   - HARD RULE: if is_ultra_processed=True AND `processed_meat` is in inflammation_triggers, rating MUST be 'red' — no exceptions for "lean" deli or "premium" chain sandwiches. Subway Spicy Italian, Arby's Roast Beef, Jimmy John's, Firehouse Subs, Bob Evans BLT, Tim Hortons Chili, Disney Pulled Pork are all RED, never yellow.

9. rating_reason (≤ 8 words, NEVER null — the badge-tooltip explanation)
   - Examples: "high omega-3, anti-inflammatory", "balanced macros, watch the oil", "deep-fried, refined flour, sugary"

CRITICAL: row_id in your output MUST echo the input id EXACTLY. The script maps responses back to database rows by id, not by position.

Return one EnrichmentItem per input dish, in the SAME ORDER as the input. Top-level response is a JSON array.
"""

USER_PROMPT_TEMPLATE = """Enrich the following {n} dishes. Echo each id exactly in row_id.

INPUT (JSON list):
{input_json}
"""

# ---------------------------------------------------------------------------
# Database helpers
# ---------------------------------------------------------------------------

MAX_ATTEMPTS = 3  # hard cap on Gemini retries per row (mig 2070)

FETCH_PENDING_BATCH = """
SELECT id, food_name_normalized, display_name,
       COALESCE(region, country_name)         AS region,
       calories_per_100g, protein_per_100g,
       carbs_per_100g, fat_per_100g,
       fiber_per_100g, sugar_per_100g,
       source
FROM food_nutrition_overrides
WHERE enrichment_backfilled_at IS NULL
  AND enrichment_attempts < $3
ORDER BY enrichment_attempts, id
LIMIT $1
OFFSET $2
"""

# Write-then-validate flow (per migration 2070):
#
# 1. WRITE_BATCH_SQL writes EVERY parsed item to DB with timestamp and
#    increments enrichment_attempts. enrichment_last_violation is set to NULL
#    optimistically (will be re-set in step 3 if validator finds errors).
#
# 2. Validator runs in Python on the just-parsed items.
#
# 3. CLEAR_INVALID_SQL is run for any item with ERROR-severity findings:
#    NULLs the enrichment fields + timestamp, but KEEPS enrichment_attempts
#    and stamps enrichment_last_violation with the failure reasons. Row
#    re-emerges in the pending pool until attempts hits MAX_ATTEMPTS.
#
# Both queries use jsonb_to_recordset to sidestep asyncpg's text[][] /
# variable-inner-length array marshalling pain.

WRITE_BATCH_SQL = """
UPDATE food_nutrition_overrides AS f SET
  inflammation_score        = v.inflammation_score,
  inflammation_triggers     = v.inflammation_triggers,
  glycemic_load             = v.glycemic_load,
  fodmap_rating             = v.fodmap_rating,
  fodmap_reason             = v.fodmap_reason,
  added_sugar_g             = v.added_sugar_g,
  is_ultra_processed        = v.is_ultra_processed,
  rating                    = v.rating,
  rating_reason             = v.rating_reason,
  enrichment_backfilled_at  = NOW(),
  enrichment_attempts       = f.enrichment_attempts + 1,
  enrichment_last_violation = NULL
FROM jsonb_to_recordset($1::jsonb) AS v(
  row_id INTEGER,
  inflammation_score SMALLINT,
  inflammation_triggers TEXT[],
  glycemic_load INTEGER,
  fodmap_rating TEXT,
  fodmap_reason TEXT,
  added_sugar_g REAL,
  is_ultra_processed BOOLEAN,
  rating TEXT,
  rating_reason TEXT
)
WHERE f.id = v.row_id;
"""

# Cleanup query for invalid rows: NULLs the enrichment payload + timestamp,
# but stamps the violation reason. enrichment_attempts stays incremented from
# WRITE_BATCH_SQL — that's how the retry cap works.
CLEAR_INVALID_SQL = """
UPDATE food_nutrition_overrides AS f SET
  inflammation_score        = NULL,
  inflammation_triggers     = NULL,
  glycemic_load             = NULL,
  fodmap_rating             = NULL,
  fodmap_reason             = NULL,
  added_sugar_g             = NULL,
  is_ultra_processed        = NULL,
  rating                    = NULL,
  rating_reason             = NULL,
  enrichment_backfilled_at  = NULL,
  enrichment_last_violation = v.violation
FROM jsonb_to_recordset($1::jsonb) AS v(row_id INTEGER, violation TEXT)
WHERE f.id = v.row_id;
"""


async def fetch_total_pending(conn: asyncpg.Connection) -> int:
    row = await conn.fetchval(
        "SELECT COUNT(*) FROM food_nutrition_overrides "
        "WHERE enrichment_backfilled_at IS NULL "
        "AND enrichment_attempts < $1",
        MAX_ATTEMPTS,
    )
    return int(row or 0)


async def fetch_exhausted_count(conn: asyncpg.Connection) -> int:
    """Rows that have hit the retry cap (parked for human/rule review)."""
    row = await conn.fetchval(
        "SELECT COUNT(*) FROM food_nutrition_overrides "
        "WHERE enrichment_backfilled_at IS NULL "
        "AND enrichment_attempts >= $1",
        MAX_ATTEMPTS,
    )
    return int(row or 0)


async def fetch_batch(
    conn: asyncpg.Connection, limit: int, offset: int
) -> List[asyncpg.Record]:
    """Fetch the next batch of pending rows under the retry cap.

    Ordered by enrichment_attempts so first-time rows process before retries.
    OFFSET is safe because successful writes flip enrichment_backfilled_at
    non-null and rows fall out of the WHERE clause; failed writes increment
    attempts and stay in (until they hit the cap).
    """
    return await conn.fetch(FETCH_PENDING_BATCH, limit, offset, MAX_ATTEMPTS)


async def write_batch(
    pool: asyncpg.Pool, items: Sequence[EnrichmentItem]
) -> None:
    """Bulk UPDATE FROM unnest — one query for the whole 50-row batch."""
    if not items:
        return

    # Sentinel translation: glycemic_load -1 → NULL (zero-carb dishes),
    # fodmap_reason "" → NULL (low-FODMAP dishes). See EnrichmentItem field
    # docstrings — sentinels exist because Gemini's response_schema doesn't
    # support anyOf: [type, null] for nullable fields.
    payload = json.dumps([
        {
            "row_id":                it.row_id,
            "inflammation_score":    it.inflammation_score,
            "inflammation_triggers": list(it.inflammation_triggers),
            "glycemic_load":
                None if it.glycemic_load < 0 else it.glycemic_load,
            "fodmap_rating":         it.fodmap_rating,
            "fodmap_reason":
                None if not it.fodmap_reason.strip() else it.fodmap_reason,
            "added_sugar_g":         float(it.added_sugar_g),
            "is_ultra_processed":    bool(it.is_ultra_processed),
            "rating":                it.rating,
            "rating_reason":         it.rating_reason,
        }
        for it in items
    ])

    async with pool.acquire() as conn:
        await conn.execute(WRITE_BATCH_SQL, payload)


async def clear_invalid_rows(
    pool: asyncpg.Pool,
    invalid: List[Tuple[int, str]],
) -> None:
    """Step 3 of write-then-validate: NULL the enrichment payload on rows
    the validator rejected, stamp enrichment_last_violation with the
    reasons. Keeps enrichment_attempts incremented (set in WRITE_BATCH_SQL)
    so the row eventually hits MAX_ATTEMPTS if it keeps failing.
    """
    if not invalid:
        return
    payload = json.dumps([
        {"row_id": rid, "violation": reason}
        for rid, reason in invalid
    ])
    async with pool.acquire() as conn:
        await conn.execute(CLEAR_INVALID_SQL, payload)


# ---------------------------------------------------------------------------
# Gemini call
# ---------------------------------------------------------------------------

def _build_input_json(rows: Sequence[asyncpg.Record]) -> str:
    """Serialize a batch of DB rows to the JSON list the prompt expects.

    Uses the canonical key order Gemini will see — tighter token usage than
    a verbose key-per-line encoding.
    """
    return json.dumps(
        [
            {
                "id":               r["id"],
                "name":             r["food_name_normalized"],
                "display_name":     r["display_name"],
                "region":           r["region"],
                "kcal_per_100g":    r["calories_per_100g"],
                "protein_g":        r["protein_per_100g"],
                "carbs_g":          r["carbs_per_100g"],
                "fat_g":            r["fat_per_100g"],
                "fiber_g":          r["fiber_per_100g"],
                "sugar_g":          r["sugar_per_100g"],
                "source":           r["source"],
            }
            for r in rows
        ],
        separators=(",", ":"),
    )


async def call_gemini(
    client: genai.Client,
    rows: Sequence[asyncpg.Record],
) -> List[EnrichmentItem]:
    """Single Gemini Flash Lite call returning structured enrichment.

    Uses `response_schema=list[EnrichmentItem]` (top-level array). A
    BaseModel wrapper would generate `$ref` / `$defs` in the JSON Schema,
    which Gemini's structured-output parser rejects with a generic 400
    INVALID_ARGUMENT. The list form inlines EnrichmentItem and works.
    """
    user_prompt = USER_PROMPT_TEMPLATE.format(
        n=len(rows), input_json=_build_input_json(rows)
    )
    config = types.GenerateContentConfig(
        system_instruction=SYSTEM_PROMPT,
        response_mime_type="application/json",
        response_schema=list[EnrichmentItem],
        temperature=0.1,
        max_output_tokens=8000,  # ~150 tok/item × 50 items + slack
    )

    response = await client.aio.models.generate_content(
        model=GEMINI_MODEL,
        contents=[user_prompt],
        config=config,
    )

    raw = response.text.strip() if response and response.text else ""
    if not raw:
        raise RuntimeError("Empty response from Gemini")

    raw_list = json.loads(raw)
    if not isinstance(raw_list, list):
        raise RuntimeError(
            f"Expected JSON array from Gemini, got {type(raw_list).__name__}"
        )
    return [EnrichmentItem.model_validate(it) for it in raw_list]


def _validate_id_alignment(
    expected_ids: Sequence[int], items: Sequence[EnrichmentItem]
) -> List[EnrichmentItem]:
    """Reject any items whose row_id was not in the input batch.

    Gemini occasionally returns extra or hallucinated ids. We trust the
    schema-level row_id field but cross-check; mismatches are dropped with a
    warning rather than corrupting the DB. Anything dropped naturally retries
    on the next pass because its enrichment_backfilled_at stays NULL.
    """
    expected = set(expected_ids)
    aligned: List[EnrichmentItem] = []
    dropped = 0
    for it in items:
        if it.row_id in expected:
            aligned.append(it)
        else:
            dropped += 1
    if dropped:
        logger.warning(
            "[align] dropped %d enrichment item(s) with unknown row_id", dropped
        )
    return aligned


def _validate_quality(
    items: Sequence[EnrichmentItem],
    rows_by_id: dict,
    validation_stats: dict,
) -> Tuple[List[EnrichmentItem], List[Tuple[int, str]]]:
    """Run the deterministic quality validator on each item.

    Returns (accepted_items, invalid_pairs) where:
      * accepted_items — items that passed all ERROR rules (warnings OK).
        Already in DB via WRITE_BATCH_SQL; no further action needed.
      * invalid_pairs — list of (row_id, violation_text) for items with
        ERROR findings. Caller passes these to clear_invalid_rows() which
        NULLs the payload + stamps enrichment_last_violation.

    Mutates `validation_stats` to track per-rule finding counts (across
    both severities) for the end-of-run summary.
    """
    accepted: List[EnrichmentItem] = []
    invalid: List[Tuple[int, str]] = []
    for it in items:
        source = rows_by_id.get(it.row_id)
        if source is None:
            continue  # already filtered by _validate_id_alignment
        item_dict = it.model_dump()
        findings = validate(item_dict, source)
        for f in findings:
            validation_stats[f.rule] = validation_stats.get(f.rule, 0) + 1
        if has_errors(findings):
            error_msgs = [
                f"{f.rule}: {f.message}"
                for f in findings if f.severity == Severity.ERROR
            ]
            joined = " | ".join(error_msgs)
            logger.warning(
                "[validator] CLEAR row_id=%d (%s) — %s",
                it.row_id, source.get("display_name", ""), joined,
            )
            invalid.append((it.row_id, joined))
            continue
        accepted.append(it)
    return accepted, invalid


def _is_rate_limit_error(e: Exception) -> bool:
    """Detect Gemini 429 / RESOURCE_EXHAUSTED for adaptive backoff."""
    msg = str(e).lower()
    return (
        "429" in msg or "resource_exhausted" in msg or
        "rate limit" in msg or "quota" in msg
    )


# ---------------------------------------------------------------------------
# Worker
# ---------------------------------------------------------------------------

class Progress:
    """Tiny shared counter for end-of-run summary + periodic logging."""

    def __init__(self, total: int):
        self.total = total
        self.done = 0
        self.rejected_validator = 0  # rejected by quality validator
        self.failed = 0  # Gemini call failed entirely
        self.validation_stats: dict = {}  # rule_name -> count
        self.started_at = time.time()
        self._lock = asyncio.Lock()

    async def add(self, ok: int, rejected: int, fail: int) -> None:
        async with self._lock:
            self.done += ok
            self.rejected_validator += rejected
            self.failed += fail
            elapsed = time.time() - self.started_at
            rate = self.done / elapsed if elapsed > 0 else 0
            remaining = max(self.total - self.done, 0)
            eta = remaining / rate if rate > 0 else 0
            logger.info(
                "[progress] %d / %d enriched (%.1f%%) | %d rejected by "
                "validator | %d Gemini-failed | %.0f rows/min | ETA %.1f min",
                self.done, self.total,
                100 * self.done / self.total if self.total else 0,
                self.rejected_validator, self.failed,
                rate * 60, eta / 60,
            )


async def process_batch(
    sem: asyncio.Semaphore,
    client: genai.Client,
    pool: asyncpg.Pool,
    rows: List[asyncpg.Record],
    progress: Progress,
) -> None:
    """One Gemini call + one DB write for a batch of rows.

    Failure isolation: any error here logs + marks rows as failed for THIS
    pass. Because we never stamp enrichment_backfilled_at on failure, a
    follow-up run automatically retries the same rows.
    """
    async with sem:
        expected_ids = [r["id"] for r in rows]
        rows_by_id = {r["id"]: dict(r) for r in rows}
        last_err: Exception | None = None
        for attempt in range(MAX_RETRIES + 1):
            try:
                items = await call_gemini(client, rows)
                aligned = _validate_id_alignment(expected_ids, items)
                if not aligned:
                    raise RuntimeError(
                        "All returned items had row_id mismatches"
                    )
                # WRITE-THEN-VALIDATE-THEN-CLEANUP (mig 2070):
                # 1. Write everything to DB and increment attempts.
                # 2. Run validator on the just-parsed items.
                # 3. NULL the rows that failed validation; they re-emerge
                #    in the pending pool until they hit MAX_ATTEMPTS.
                await write_batch(pool, aligned)
                accepted, invalid = _validate_quality(
                    aligned, rows_by_id, progress.validation_stats
                )
                if invalid:
                    await clear_invalid_rows(pool, invalid)
                ok = len(accepted)
                cleared_by_validator = len(invalid)
                gemini_dropped = len(rows) - len(aligned)
                await progress.add(
                    ok, cleared_by_validator, gemini_dropped
                )
                return
            except Exception as e:  # noqa: BLE001
                last_err = e
                if attempt < MAX_RETRIES:
                    base = RETRY_BACKOFF[
                        min(attempt, len(RETRY_BACKOFF) - 1)
                    ]
                    # Rate-limit errors get the long tail of the backoff schedule
                    # immediately — no point retrying in 2s when quota refills
                    # on a per-minute window.
                    if _is_rate_limit_error(e):
                        base = max(base, 60.0)
                    delay = base + random.uniform(0, 2)
                    kind = "429" if _is_rate_limit_error(e) else "transient"
                    logger.warning(
                        "[batch] attempt %d/%d failed (%s): %s — retry in %.1fs",
                        attempt + 1, MAX_RETRIES + 1, kind,
                        str(e)[:140], delay,
                    )
                    await asyncio.sleep(delay)
                    continue
                break
        logger.error(
            "[batch] PERMANENT FAILURE after %d attempts: %s — %d rows will "
            "retry on the next script run", MAX_RETRIES + 1, last_err, len(rows),
        )
        await progress.add(0, 0, len(rows))


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

async def main() -> int:
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        logger.error("GEMINI_API_KEY not set in backend/.env")
        return 2
    db_url = os.environ.get("DATABASE_URL")
    if not db_url:
        logger.error("DATABASE_URL not set in backend/.env")
        return 2
    # asyncpg doesn't accept the `postgresql+asyncpg://` SQLAlchemy prefix.
    asyncpg_url = db_url.replace("postgresql+asyncpg://", "postgresql://")

    client = genai.Client(api_key=api_key)
    # Supabase fronts Postgres with PgBouncer in transaction mode, which
    # rejects asyncpg's prepared-statement cache. Disabling the cache makes
    # every query a one-shot, which is fine for this script (each query
    # runs at most a few thousand times and Postgres auto-prepares server-
    # side anyway).
    pool = await asyncpg.create_pool(
        asyncpg_url,
        min_size=DB_POOL_MIN,
        max_size=DB_POOL_MAX,
        statement_cache_size=0,
    )

    try:
        async with pool.acquire() as conn:
            pending = await fetch_total_pending(conn)
        if LIMIT_ROWS > 0:
            total = min(pending, LIMIT_ROWS)
            logger.info(
                "[start] LIMIT_ROWS=%d | processing %d of %d pending rows | "
                "model=%s | concurrency=%d",
                LIMIT_ROWS, total, pending, GEMINI_MODEL, CONCURRENT_CALLS,
            )
        else:
            total = pending
            logger.info(
                "[start] %d rows pending enrichment | model=%s | concurrency=%d",
                total, GEMINI_MODEL, CONCURRENT_CALLS,
            )
        if total == 0:
            logger.info("[start] nothing to do — all rows already backfilled")
            return 0

        progress = Progress(total)
        sem = asyncio.Semaphore(CONCURRENT_CALLS)

        # We feed batches off a single fetch loop. Because UPDATE flips rows
        # out of the pending pool as we go, we always re-fetch with OFFSET=0.
        # Pending rows we've already kicked into Gemini calls (but not yet
        # written) would otherwise be re-fetched — guard with a seen-set.
        in_flight_ids: set[int] = set()
        tasks: list[asyncio.Task] = []

        scheduled_count = 0
        while True:
            # Stop scheduling once we've kicked off enough work for LIMIT_ROWS.
            if LIMIT_ROWS > 0 and scheduled_count >= LIMIT_ROWS:
                break
            async with pool.acquire() as conn:
                rows = await fetch_batch(conn, ROWS_PER_BATCH * 4, 0)
            # Filter out rows already kicked into a running task.
            rows = [r for r in rows if r["id"] not in in_flight_ids]
            if LIMIT_ROWS > 0:
                rows = rows[: max(LIMIT_ROWS - scheduled_count, 0)]
            if not rows:
                # Nothing more to schedule right now. If tasks are running,
                # wait for at least one to complete (releases ids back to the
                # pending pool via the cleanup callback), then re-fetch. If
                # no tasks are left either, we're done.
                if not tasks:
                    break
                done, tasks_pending = await asyncio.wait(
                    tasks, return_when=asyncio.FIRST_COMPLETED
                )
                tasks = list(tasks_pending)
                continue
            # Chunk into ROWS_PER_BATCH-size batches.
            for i in range(0, len(rows), ROWS_PER_BATCH):
                chunk = rows[i:i + ROWS_PER_BATCH]
                ids = [r["id"] for r in chunk]
                in_flight_ids.update(ids)
                scheduled_count += len(chunk)
                task = asyncio.create_task(
                    process_batch(sem, client, pool, chunk, progress)
                )
                # Remove ids from in_flight when task completes (success OR
                # failure — if failure, rows stay pending and re-emerge on
                # the next outer fetch loop iteration).
                def _cleanup(_t, _ids=ids):
                    in_flight_ids.difference_update(_ids)
                task.add_done_callback(_cleanup)
                tasks.append(task)
            # Don't busy-loop — let some tasks complete before fetching more.
            if len(tasks) >= CONCURRENT_CALLS * 2:
                done, tasks_pending = await asyncio.wait(
                    tasks, return_when=asyncio.FIRST_COMPLETED
                )
                tasks = list(tasks_pending)

        # Drain any still-running tasks before reporting + refresh. Without
        # this, the script would exit while Gemini calls are mid-flight and
        # report "0 rows enriched" because the writes haven't happened yet.
        if tasks:
            await asyncio.gather(*tasks)

        elapsed = time.time() - progress.started_at
        logger.info(
            "[done] %d / %d enriched | %d rejected by validator | "
            "%d Gemini-failed | %.1f min wall time",
            progress.done, progress.total,
            progress.rejected_validator, progress.failed, elapsed / 60,
        )
        if progress.validation_stats:
            logger.info("[done] validator findings (rule -> count):")
            for rule, n in sorted(
                progress.validation_stats.items(), key=lambda kv: -kv[1]
            ):
                logger.info("    %-40s %d", rule, n)

        # food_nutrition_overrides_canonical is now a regular VIEW (mig 2071)
        # that resolves at query time — no refresh needed. The function call
        # below is a no-op kept for backwards compatibility with any caller.
        logger.info("[done] canonical view is live — no MV refresh needed")

        if progress.failed > 0:
            logger.warning(
                "[done] %d rows failed — re-run the script to retry "
                "(they're still WHERE enrichment_backfilled_at IS NULL)",
                progress.failed,
            )
            return 1
        return 0
    finally:
        await pool.close()


if __name__ == "__main__":
    sys.exit(asyncio.run(main()))
