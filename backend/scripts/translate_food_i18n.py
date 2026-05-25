"""Translate food i18n tables to all 35 non-English locales using gemini-3.1-flash-lite.

Tables covered:
  - food_nutrition_overrides_i18n (1,000 en rows — name + description)
    NOTE: common_servings_localized JSONB is mirrored verbatim from en row;
    translation of serving labels is a follow-up task.
  - recipes_i18n (13 en rows — name + description + step text in instructions_localized JSONB)

Design:
  - Resume-safe: skips (id, locale) pairs already present (ignore_duplicates=True)
  - Parallelism: 4 locales concurrent; 4 Gemini calls per locale concurrent
  - Batch size: 50 rows / Gemini call
  - Token cost logged at end

Usage:
  cd /Users/saichetangrandhe/AIFitnessCoach
  backend/.venv/bin/python backend/scripts/translate_food_i18n.py

Constraints:
  - gemini-3.1-flash-lite ONLY (GEMINI_API_KEY from backend/.env)
  - NO Google Translate / MyMemory / LibreTranslate
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
import re
import sys
import time
from pathlib import Path

from dotenv import load_dotenv

# Load .env before any backend imports
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
load_dotenv(REPO_ROOT / "backend" / ".env")

BACKEND_DIR = REPO_ROOT / "backend"
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from core.db import get_supabase_db  # noqa: E402

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)
logger = logging.getLogger(__name__)

MODEL = "gemini-3.1-flash-lite"
FOOD_BATCH  = 50   # rows per Gemini call
MAX_LOCALE_CONCURRENCY = 4
MAX_GEMINI_CONCURRENCY = 4
MAX_RETRIES = 3
RETRY_DELAY = 5.0

BRAND_ACRONYMS = "RPE, 1RM, AMRAP, EMOM, BMR, TDEE, HRV, Zealova, Strava, Fitbod"

# 35 non-English locales (same list as translate_exercise_library_i18n.py)
NON_EN_LOCALES: list[str] = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id",
    "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl",
    "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te", "th",
    "tl", "tr", "ur", "vi", "zh",
]
assert len(NON_EN_LOCALES) == 35

LOCALE_NAMES: dict[str, str] = {
    "ar": "Arabic", "bn": "Bengali", "cs": "Czech", "de": "German",
    "es": "Spanish", "fi": "Finnish", "fr": "French", "ha": "Hausa",
    "hi": "Hindi", "id": "Indonesian", "it": "Italian", "ja": "Japanese",
    "jv": "Javanese", "kn": "Kannada", "ko": "Korean", "ml": "Malayalam",
    "mr": "Marathi", "ms": "Malay", "ne": "Nepali", "nl": "Dutch",
    "or": "Odia", "pa": "Punjabi", "pl": "Polish", "pt": "Portuguese",
    "ru": "Russian", "sv": "Swedish", "sw": "Swahili", "ta": "Tamil",
    "te": "Telugu", "th": "Thai", "tl": "Tagalog (Filipino)",
    "tr": "Turkish", "ur": "Urdu", "vi": "Vietnamese",
    "zh": "Chinese (Simplified)",
}

# ---------------------------------------------------------------------------
# Gemini helpers
# ---------------------------------------------------------------------------

def _get_gemini_client():
    from google import genai
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set in environment")
    return genai.Client(api_key=api_key)


def _strip_json_fence(text: str) -> str:
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```\s*$", "", text)
    return text.strip()


def _call_gemini_sync(client, prompt: str) -> str:
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = client.models.generate_content(model=MODEL, contents=prompt)
            return resp.text
        except Exception as exc:
            if attempt < MAX_RETRIES:
                logger.warning(f"⚠️  Gemini attempt {attempt} failed: {exc!r} — retrying in {RETRY_DELAY * attempt}s")
                time.sleep(RETRY_DELAY * attempt)
            else:
                raise


async def _call_gemini_async(semaphore: asyncio.Semaphore, client, prompt: str) -> str:
    async with semaphore:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, _call_gemini_sync, client, prompt)


# ---------------------------------------------------------------------------
# food_nutrition_overrides_i18n translator
# ---------------------------------------------------------------------------

def _build_food_prompt(locale: str, rows: list[dict]) -> str:
    lang = LOCALE_NAMES.get(locale, locale)
    items = []
    for r in rows:
        item: dict = {"id": r["food_id"], "name": r["name"]}
        if r.get("description"):
            item["description"] = r["description"]
        items.append(item)
    return f"""You are a nutrition app translator. Translate food item names (and descriptions where present) from English to {lang} ({locale}).

Rules:
- Return ONLY valid JSON array, no markdown, no code fences, no explanation
- Keep brand names verbatim: {BRAND_ACRONYMS}
- Food names that are proper nouns or internationally recognized (e.g. "Dosa", "Idli", "Pizza", "Sushi") may be kept or use common local spelling
- Translate description text naturally and fluently
- If description is absent in input, omit it in output (do not add a description key)

Input JSON:
{json.dumps(items, ensure_ascii=False)}

Output JSON (same array structure, same ids, translated name and description fields):"""


async def translate_food_overrides_locale(
    db,
    en_rows: list[dict],
    locale: str,
    gemini_sem: asyncio.Semaphore,
    client,
    stats: dict,
) -> int:
    lang = LOCALE_NAMES.get(locale, locale)

    # Check which food_ids already exist
    existing_ids: set = set()
    page = 1000
    offset = 0
    while True:
        res = (
            db.client.table("food_nutrition_overrides_i18n")
            .select("food_id")
            .eq("locale", locale)
            .range(offset, offset + page - 1)
            .execute()
        )
        for r in (res.data or []):
            existing_ids.add(r["food_id"])
        if len(res.data or []) < page:
            break
        offset += page

    rows_to_translate = [r for r in en_rows if r["food_id"] not in existing_ids]
    if not rows_to_translate:
        logger.info(f"  ✅ [food_nutrition_overrides_i18n] {locale} — all {len(en_rows)} already exist")
        return 0

    logger.info(f"  🥗 [food_nutrition_overrides_i18n] {locale}/{lang} — translating {len(rows_to_translate)} rows")

    batches = [rows_to_translate[i: i + FOOD_BATCH] for i in range(0, len(rows_to_translate), FOOD_BATCH)]
    inner_sem = asyncio.Semaphore(MAX_GEMINI_CONCURRENCY)
    inserted_total = 0

    async def _translate_batch(batch: list[dict]) -> int:
        prompt = _build_food_prompt(locale, batch)
        try:
            async with inner_sem:
                raw = await _call_gemini_async(gemini_sem, client, prompt)
            parsed: list[dict] = json.loads(_strip_json_fence(raw))
        except Exception as exc:
            logger.error(f"  ❌ [food_nutrition_overrides_i18n] {locale} batch parse error: {exc!r}")
            return 0

        # Map id → translated fields
        id_to_data: dict = {}
        for item in parsed:
            if "id" in item:
                id_to_data[item["id"]] = item
                id_to_data[str(item["id"])] = item

        payloads: list[dict] = []
        for row in batch:
            fid = row["food_id"]
            translated = id_to_data.get(fid) or id_to_data.get(str(fid)) or {}
            payloads.append({
                "food_id": fid,
                "locale": locale,
                "name": translated.get("name") or row["name"],
                "description": translated.get("description") or row.get("description"),
                # Mirror en's serving labels verbatim — serving label translation is follow-up
                "common_servings_localized": row.get("common_servings_localized") or [],
            })

        res = (
            db.client.table("food_nutrition_overrides_i18n")
            .upsert(payloads, on_conflict="food_id,locale", ignore_duplicates=True)
            .execute()
        )
        return len(res.data or [])

    tasks = [_translate_batch(b) for b in batches]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    for r in results:
        if isinstance(r, Exception):
            logger.error(f"  ❌ [food_nutrition_overrides_i18n] {locale} batch exception: {r!r}")
        else:
            inserted_total += r

    stats["food_nutrition_overrides_i18n"] = stats.get("food_nutrition_overrides_i18n", 0) + inserted_total
    logger.info(f"  ✅ [food_nutrition_overrides_i18n] {locale} — inserted {inserted_total} rows")
    return inserted_total


# ---------------------------------------------------------------------------
# recipes_i18n translator
# ---------------------------------------------------------------------------

def _build_recipe_prompt(locale: str, rows: list[dict]) -> str:
    lang = LOCALE_NAMES.get(locale, locale)
    # Serialize: name, description, steps text only (step numbers preserved by structure)
    items = []
    for r in rows:
        item = {
            "id": r["recipe_id"],
            "name": r["name"],
        }
        if r.get("description"):
            item["description"] = r["description"]
        # Include step texts (we'll rebuild the structure on return)
        steps_text = [s.get("text", "") for s in (r.get("instructions_localized") or [])]
        if steps_text:
            item["steps"] = steps_text
        items.append(item)

    return f"""You are a recipe/nutrition app translator. Translate recipe names, descriptions, and cooking instructions from English to {lang} ({locale}).

Rules:
- Return ONLY valid JSON array, no markdown, no code fences, no explanation
- Keep brand names verbatim: {BRAND_ACRONYMS}
- Keep cooking temperatures as-is (e.g. 165°F, 350°F) — do not convert to Celsius
- Translate name, description, and each step text naturally and fluently
- Preserve the same number of steps as the input

Input JSON:
{json.dumps(items, ensure_ascii=False)}

Output JSON (same array, same ids, translated name, description, and steps array):"""


async def translate_recipes_locale(
    db,
    en_rows: list[dict],
    locale: str,
    gemini_sem: asyncio.Semaphore,
    client,
    stats: dict,
) -> int:
    lang = LOCALE_NAMES.get(locale, locale)

    # Check which recipe_ids already exist
    existing_ids: set[str] = set()
    res = db.client.table("recipes_i18n").select("recipe_id").eq("locale", locale).execute()
    for r in (res.data or []):
        existing_ids.add(r["recipe_id"])

    rows_to_translate = [r for r in en_rows if r["recipe_id"] not in existing_ids]
    if not rows_to_translate:
        logger.info(f"  ✅ [recipes_i18n] {locale} — all {len(en_rows)} already exist")
        return 0

    logger.info(f"  🍽️  [recipes_i18n] {locale}/{lang} — translating {len(rows_to_translate)} rows")

    # Recipes are small (13 total), do all in one batch
    prompt = _build_recipe_prompt(locale, rows_to_translate)
    try:
        raw = await _call_gemini_async(gemini_sem, client, prompt)
        parsed: list[dict] = json.loads(_strip_json_fence(raw))
    except Exception as exc:
        logger.error(f"  ❌ [recipes_i18n] {locale} parse error: {exc!r}")
        return 0

    id_to_data: dict[str, dict] = {}
    for item in parsed:
        if "id" in item:
            id_to_data[str(item["id"])] = item

    payloads: list[dict] = []
    for row in rows_to_translate:
        rec_id = row["recipe_id"]
        translated = id_to_data.get(rec_id, {})

        # Rebuild instructions_localized: keep step numbers, use translated step texts
        en_steps = row.get("instructions_localized") or []
        translated_steps_text = translated.get("steps") or []
        rebuilt_steps: list[dict] = []
        for i, en_step in enumerate(en_steps):
            step_num = en_step.get("step", i + 1)
            if i < len(translated_steps_text):
                step_text = translated_steps_text[i]
            else:
                step_text = en_step.get("text", "")  # fallback to en if missing
            rebuilt_steps.append({"step": step_num, "text": step_text})

        payloads.append({
            "recipe_id": rec_id,
            "locale": locale,
            "name": translated.get("name") or row["name"],
            "description": translated.get("description") or row.get("description"),
            "instructions_localized": rebuilt_steps,
        })

    res = (
        db.client.table("recipes_i18n")
        .upsert(payloads, on_conflict="recipe_id,locale", ignore_duplicates=True)
        .execute()
    )
    inserted = len(res.data or [])
    stats["recipes_i18n"] = stats.get("recipes_i18n", 0) + inserted
    logger.info(f"  ✅ [recipes_i18n] {locale} — inserted {inserted} rows")
    return inserted


# ---------------------------------------------------------------------------
# Main orchestrator
# ---------------------------------------------------------------------------

async def run_all() -> dict[str, int]:
    start = time.time()
    db = get_supabase_db()
    client = _get_gemini_client()
    stats: dict[str, int] = {}

    # ── Fetch all en rows once ──────────────────────────────────────────────
    logger.info("🔍 Fetching all en baseline rows …")

    # food_nutrition_overrides_i18n
    food_en_rows: list[dict] = []
    page = 1000
    offset = 0
    while True:
        res = (
            db.client.table("food_nutrition_overrides_i18n")
            .select("food_id, name, description, common_servings_localized")
            .eq("locale", "en")
            .range(offset, offset + page - 1)
            .execute()
        )
        food_en_rows.extend(res.data or [])
        if len(res.data or []) < page:
            break
        offset += page
    logger.info(f"  ✅ food_nutrition_overrides_i18n: {len(food_en_rows)} en rows")

    # recipes_i18n
    rec_res = (
        db.client.table("recipes_i18n")
        .select("recipe_id, name, description, instructions_localized")
        .eq("locale", "en")
        .execute()
    )
    rec_en_rows = rec_res.data or []
    logger.info(f"  ✅ recipes_i18n: {len(rec_en_rows)} en rows")

    # ── Translate locale by locale ──────────────────────────────────────────
    locale_sem = asyncio.Semaphore(MAX_LOCALE_CONCURRENCY)
    gemini_sem = asyncio.Semaphore(MAX_GEMINI_CONCURRENCY * MAX_LOCALE_CONCURRENCY)

    locale_inserted: dict[str, int] = {}

    async def process_locale(locale: str) -> None:
        async with locale_sem:
            lang = LOCALE_NAMES.get(locale, locale)
            logger.info(f"\n🌐 ──── Processing locale: {locale} ({lang}) ────")
            total_locale = 0

            n = await translate_food_overrides_locale(db, food_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            n = await translate_recipes_locale(db, rec_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            locale_inserted[locale] = total_locale
            logger.info(f"  🎯 {locale} done — {total_locale} total rows inserted")

    tasks = [process_locale(loc) for loc in NON_EN_LOCALES]
    await asyncio.gather(*tasks)

    elapsed = time.time() - start

    # ── Final row counts ────────────────────────────────────────────────────
    logger.info("\n🔍 Querying final row counts …")

    def count_table(table: str, id_col: str) -> dict[str, int]:
        r = db.client.table(table).select(id_col, count="exact").execute()
        total = r.count or 0
        r2 = db.client.table(table).select(id_col, count="exact").eq("locale", "en").execute()
        en = r2.count or 0
        return {"total": total, "en": en}

    final_counts = {
        "food_nutrition_overrides_i18n": count_table("food_nutrition_overrides_i18n", "food_id"),
        "recipes_i18n":                  count_table("recipes_i18n", "recipe_id"),
    }

    # ── Sample translations ─────────────────────────────────────────────────
    sample_locales = ["es", "ja", "ar"]

    print("\n" + "="*70)
    print("TRANSLATE_FOOD_I18N — RESULTS")
    print("="*70)
    print(f"\nWall-clock time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    print("\n── Row counts per table ─────────────────────────────────────────────")
    for table, counts in final_counts.items():
        en_cnt = counts["en"]
        total = counts["total"]
        locale_cnt = total // en_cnt if en_cnt > 0 else 0
        expected = en_cnt * 36
        print(f"  {table:<40} total={total:>7}  (en={en_cnt}, ~{locale_cnt} locales, expected={expected})")

    print("\n── Rows inserted this run per table ─────────────────────────────────")
    for table, cnt in stats.items():
        print(f"  {table:<40} {cnt:>7} rows inserted")

    print("\n── Sample translations (3 foods × 3 locales) ────────────────────────")
    food_sample_ids_res = db.client.table("food_nutrition_overrides_i18n").select("food_id").eq("locale", "en").limit(3).execute()
    food_sample_ids = [r["food_id"] for r in (food_sample_ids_res.data or [])]
    for loc in sample_locales:
        lang = LOCALE_NAMES.get(loc, loc)
        for fid in food_sample_ids:
            res = db.client.table("food_nutrition_overrides_i18n").select("name, description").eq("food_id", fid).eq("locale", loc).limit(1).execute()
            if res.data:
                row = res.data[0]
                print(f"  [{loc}/{lang}] food_id={fid}  name={row.get('name')!r}")

    print("\n── Sample recipe translations (3 locales) ───────────────────────────")
    for loc in sample_locales:
        lang = LOCALE_NAMES.get(loc, loc)
        res = db.client.table("recipes_i18n").select("name, instructions_localized").eq("locale", loc).limit(1).execute()
        if res.data:
            row = res.data[0]
            steps = row.get("instructions_localized") or []
            first_step = steps[0].get("text", "") if steps else ""
            print(f"  [{loc}/{lang}] recipe name={row.get('name')!r}")
            print(f"            step1={first_step[:100]!r}…")

    print("="*70)
    return stats


def main() -> None:
    asyncio.run(run_all())


if __name__ == "__main__":
    main()
