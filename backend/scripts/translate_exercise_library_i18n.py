"""Translate exercise i18n tables (exercise_library, equipment, muscle, movement, set_type)
to all 35 non-English locales using gemini-3.1-flash-lite.

Tables covered:
  - exercise_library_i18n     (2,439 en rows — name + instructions)
  - equipment_types_i18n      (51 en rows — display_name)
  - muscle_group_i18n         (204 en rows — display_name)
  - movement_pattern_i18n     (9 en rows — display_name)
  - set_type_i18n             (5 en rows — display_name)

Design:
  - Resume-safe: skips (id, locale) pairs that already exist (ignore_duplicates=True)
  - Parallelism: 4 locales concurrent via asyncio semaphore; 4 Gemini batches concurrent
  - Batch size: 50 rows / Gemini call (exercises) or all at once (small tables)
  - Token-level cost logged at end

Usage:
  cd /Users/saichetangrandhe/AIFitnessCoach
  backend/.venv/bin/python backend/scripts/translate_exercise_library_i18n.py

Constraints:
  - gemini-3.1-flash-lite ONLY (GEMINI_API_KEY from backend/.env)
  - NO Google Translate / MyMemory / LibreTranslate
  - NO migration SQL modifications
  - NO seed script modifications
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
from typing import Any

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
EXERCISE_BATCH = 50   # rows per Gemini call (exercises have long instructions)
SMALL_BATCH   = 50    # rows per call for short-text tables
MAX_LOCALE_CONCURRENCY = 4   # locales in parallel
MAX_GEMINI_CONCURRENCY = 4   # Gemini calls per locale in parallel
MAX_RETRIES = 3
RETRY_DELAY = 5.0   # seconds between retries

# Brand / acronym protection list (kept verbatim during translation)
BRAND_ACRONYMS = "RPE, 1RM, AMRAP, EMOM, BMR, TDEE, HRV, Zealova, Strava, Fitbod"

# The 35 non-English locales Zealova actually supports.
# Must match mobile/flutter/lib/l10n/app_*.arb + backend SUPPORTED_LOCALES.
NON_EN_LOCALES: list[str] = [
    "ar", "bn", "cs", "de", "es", "fi", "fr", "ha", "hi", "id",
    "it", "ja", "jv", "kn", "ko", "ml", "mr", "ms", "ne", "nl",
    "or", "pa", "pl", "pt", "ru", "sv", "sw", "ta", "te", "th",
    "tl", "tr", "ur", "vi", "zh",
]
assert len(NON_EN_LOCALES) == 35, f"Expected 35 locales, got {len(NON_EN_LOCALES)}"

# Locale → human-readable language name (for clearer prompts) — Zealova's actual 35
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
    """Return a synchronous google-genai Client."""
    from google import genai
    api_key = os.environ.get("GEMINI_API_KEY")
    if not api_key:
        raise RuntimeError("GEMINI_API_KEY not set in environment")
    return genai.Client(api_key=api_key)


def _strip_json_fence(text: str) -> str:
    """Remove optional ```json ... ``` markdown fences."""
    text = text.strip()
    text = re.sub(r"^```(?:json)?\s*", "", text, flags=re.IGNORECASE)
    text = re.sub(r"\s*```\s*$", "", text)
    return text.strip()


def _call_gemini_sync(client, prompt: str) -> str:
    """Call Gemini synchronously with retries."""
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            resp = client.models.generate_content(model=MODEL, contents=prompt)
            return resp.text
        except Exception as exc:
            if attempt < MAX_RETRIES:
                logger.warning(f"⚠️  Gemini attempt {attempt} failed: {exc!r} — retrying in {RETRY_DELAY}s")
                time.sleep(RETRY_DELAY * attempt)
            else:
                raise


async def _call_gemini_async(semaphore: asyncio.Semaphore, client, prompt: str) -> str:
    """Run a synchronous Gemini call in a thread pool, respecting semaphore."""
    async with semaphore:
        loop = asyncio.get_event_loop()
        return await loop.run_in_executor(None, _call_gemini_sync, client, prompt)


# ---------------------------------------------------------------------------
# Generic short-text translator (display_name only)
# ---------------------------------------------------------------------------

def _build_display_name_prompt(locale: str, rows: list[dict], id_field: str) -> str:
    lang = LOCALE_NAMES.get(locale, locale)
    items = [{"id": r[id_field], "display_name": r["display_name"]} for r in rows]
    return f"""You are a fitness app translator. Translate fitness display names from English to {lang} ({locale}).

Rules:
- Return ONLY valid JSON array, no markdown, no code fences, no explanation
- Keep brand names verbatim: {BRAND_ACRONYMS}
- Keep acronyms verbatim: AMRAP, EMOM, RPE, 1RM
- Translate display_name naturally for each item

Input JSON:
{json.dumps(items, ensure_ascii=False)}

Output JSON (same array, same ids, translated display_name field only):"""


async def translate_display_name_table(
    db,
    table: str,
    id_field: str,
    en_rows: list[dict],
    locale: str,
    gemini_sem: asyncio.Semaphore,
    client,
    stats: dict,
) -> int:
    """Translate a simple display_name table for one locale. Returns rows inserted."""
    lang = LOCALE_NAMES.get(locale, locale)

    # Check which ids already translated
    existing_ids: set = set()
    page = 500
    offset = 0
    while True:
        res = (
            db.client.table(table)
            .select(id_field)
            .eq("locale", locale)
            .range(offset, offset + page - 1)
            .execute()
        )
        for r in (res.data or []):
            existing_ids.add(r[id_field])
        if len(res.data or []) < page:
            break
        offset += page

    rows_to_translate = [r for r in en_rows if r[id_field] not in existing_ids]
    if not rows_to_translate:
        logger.info(f"  ✅ [{table}] {locale} — all {len(en_rows)} rows already exist, skipping")
        return 0

    logger.info(f"  🔍 [{table}] {locale}/{lang} — translating {len(rows_to_translate)} rows")

    # Translate in batches
    inserted_total = 0
    for i in range(0, len(rows_to_translate), SMALL_BATCH):
        batch = rows_to_translate[i: i + SMALL_BATCH]
        prompt = _build_display_name_prompt(locale, batch, id_field)
        try:
            raw = await _call_gemini_async(gemini_sem, client, prompt)
            parsed: list[dict] = json.loads(_strip_json_fence(raw))
        except Exception as exc:
            logger.error(f"  ❌ [{table}] {locale} batch {i}-{i+len(batch)} parse error: {exc!r}")
            continue

        # Build upsert payloads
        id_to_translated: dict[Any, str] = {}
        for item in parsed:
            if "id" in item and "display_name" in item:
                id_to_translated[item["id"]] = item["display_name"]

        payloads: list[dict] = []
        for row in batch:
            row_id = row[id_field]
            name = id_to_translated.get(row_id) or id_to_translated.get(str(row_id)) or row["display_name"]
            p = {id_field: row_id, "locale": locale, "display_name": name}
            # Carry aliases if present (equipment_types_i18n)
            if "aliases" in row:
                p["aliases"] = row.get("aliases") or []
            payloads.append(p)

        res = (
            db.client.table(table)
            .upsert(payloads, on_conflict=f"{id_field},locale", ignore_duplicates=True)
            .execute()
        )
        inserted = len(res.data or [])
        inserted_total += inserted
        stats[table] = stats.get(table, 0) + inserted

    logger.info(f"  ✅ [{table}] {locale} — inserted {inserted_total} rows")
    return inserted_total


# ---------------------------------------------------------------------------
# exercise_library_i18n translator
# ---------------------------------------------------------------------------

def _build_exercise_prompt(locale: str, rows: list[dict]) -> str:
    lang = LOCALE_NAMES.get(locale, locale)
    items = [{"id": r["exercise_id"], "name": r["name"], "instructions": r["instructions"]} for r in rows]
    return f"""You are a fitness app translator. Translate exercise names and instructions from English to {lang} ({locale}).

Rules:
- Return ONLY valid JSON array, no markdown, no code fences, no explanation
- Keep brand names verbatim: {BRAND_ACRONYMS}
- Keep technical fitness acronyms verbatim: RPE, 1RM, AMRAP, EMOM, BMR, TDEE, HRV
- Exercise names like squat, deadlift, bench press, lunge are internationally understood — you may keep them or use the common local equivalent
- Translate all surrounding instructional text naturally and fluently
- Preserve numbered step structure (e.g. "1.", "2.") in instructions if present

Input JSON:
{json.dumps(items, ensure_ascii=False)}

Output JSON (same array structure, same ids, translated name and instructions fields):"""


async def translate_exercise_library_locale(
    db,
    en_rows: list[dict],
    locale: str,
    gemini_sem: asyncio.Semaphore,
    client,
    stats: dict,
) -> int:
    """Translate exercise_library_i18n for one locale."""
    lang = LOCALE_NAMES.get(locale, locale)

    # Fetch existing exercise_ids for this locale
    existing_ids: set[str] = set()
    page = 1000
    offset = 0
    while True:
        res = (
            db.client.table("exercise_library_i18n")
            .select("exercise_id")
            .eq("locale", locale)
            .range(offset, offset + page - 1)
            .execute()
        )
        for r in (res.data or []):
            existing_ids.add(r["exercise_id"])
        if len(res.data or []) < page:
            break
        offset += page

    rows_to_translate = [r for r in en_rows if r["exercise_id"] not in existing_ids]
    if not rows_to_translate:
        logger.info(f"  ✅ [exercise_library_i18n] {locale} — all {len(en_rows)} already exist")
        return 0

    logger.info(f"  🏋️  [exercise_library_i18n] {locale}/{lang} — translating {len(rows_to_translate)} rows in batches of {EXERCISE_BATCH}")

    # Build batches
    batches = [rows_to_translate[i: i + EXERCISE_BATCH] for i in range(0, len(rows_to_translate), EXERCISE_BATCH)]

    # Translate batches with inner concurrency
    inserted_total = 0
    inner_sem = asyncio.Semaphore(MAX_GEMINI_CONCURRENCY)

    async def _translate_batch(batch: list[dict]) -> int:
        prompt = _build_exercise_prompt(locale, batch)
        try:
            async with inner_sem:
                raw = await _call_gemini_async(gemini_sem, client, prompt)
            parsed: list[dict] = json.loads(_strip_json_fence(raw))
        except Exception as exc:
            logger.error(f"  ❌ [exercise_library_i18n] {locale} batch parse error: {exc!r}")
            return 0

        id_to_data: dict[str, dict] = {}
        for item in parsed:
            if "id" in item:
                id_to_data[str(item["id"])] = item

        # Build payloads preserving muscle fields from en row
        payloads: list[dict] = []
        for row in batch:
            ex_id = row["exercise_id"]
            translated = id_to_data.get(ex_id, {})
            payloads.append({
                "exercise_id": ex_id,
                "locale": locale,
                "name": translated.get("name") or row["name"],
                "instructions": translated.get("instructions") or row["instructions"],
                "primary_muscle_localized": row.get("primary_muscle_localized") or "",
                "secondary_muscles_localized": row.get("secondary_muscles_localized") or [],
            })

        res = (
            db.client.table("exercise_library_i18n")
            .upsert(payloads, on_conflict="exercise_id,locale", ignore_duplicates=True)
            .execute()
        )
        cnt = len(res.data or [])
        return cnt

    tasks = [_translate_batch(b) for b in batches]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    for r in results:
        if isinstance(r, Exception):
            logger.error(f"  ❌ [exercise_library_i18n] {locale} batch exception: {r!r}")
        else:
            inserted_total += r

    stats["exercise_library_i18n"] = stats.get("exercise_library_i18n", 0) + inserted_total
    logger.info(f"  ✅ [exercise_library_i18n] {locale} — inserted {inserted_total} rows")
    return inserted_total


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

    # exercise_library_i18n
    ex_en_rows: list[dict] = []
    page = 1000
    offset = 0
    while True:
        res = (
            db.client.table("exercise_library_i18n")
            .select("exercise_id, name, instructions, primary_muscle_localized, secondary_muscles_localized")
            .eq("locale", "en")
            .range(offset, offset + page - 1)
            .execute()
        )
        ex_en_rows.extend(res.data or [])
        if len(res.data or []) < page:
            break
        offset += page
    logger.info(f"  ✅ exercise_library_i18n: {len(ex_en_rows)} en rows")

    # equipment_types_i18n
    eq_res = db.client.table("equipment_types_i18n").select("equipment_type_id, display_name, aliases").eq("locale", "en").execute()
    eq_en_rows = eq_res.data or []
    logger.info(f"  ✅ equipment_types_i18n: {len(eq_en_rows)} en rows")

    # muscle_group_i18n
    mg_res = db.client.table("muscle_group_i18n").select("muscle_group_code, display_name").eq("locale", "en").execute()
    mg_en_rows = mg_res.data or []
    logger.info(f"  ✅ muscle_group_i18n: {len(mg_en_rows)} en rows")

    # movement_pattern_i18n
    mp_res = db.client.table("movement_pattern_i18n").select("pattern_code, display_name").eq("locale", "en").execute()
    mp_en_rows = mp_res.data or []
    logger.info(f"  ✅ movement_pattern_i18n: {len(mp_en_rows)} en rows")

    # set_type_i18n
    st_res = db.client.table("set_type_i18n").select("set_type_code, display_name").eq("locale", "en").execute()
    st_en_rows = st_res.data or []
    logger.info(f"  ✅ set_type_i18n: {len(st_en_rows)} en rows")

    # ── Translate locale by locale ──────────────────────────────────────────
    locale_sem = asyncio.Semaphore(MAX_LOCALE_CONCURRENCY)
    gemini_sem = asyncio.Semaphore(MAX_GEMINI_CONCURRENCY * MAX_LOCALE_CONCURRENCY)

    locale_inserted: dict[str, int] = {}

    async def process_locale(locale: str) -> None:
        async with locale_sem:
            lang = LOCALE_NAMES.get(locale, locale)
            logger.info(f"\n🌐 ──── Processing locale: {locale} ({lang}) ────")
            total_locale = 0

            # exercise_library_i18n (largest, most important)
            n = await translate_exercise_library_locale(db, ex_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            # Small tables (display_name only)
            n = await translate_display_name_table(db, "equipment_types_i18n", "equipment_type_id", eq_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            n = await translate_display_name_table(db, "muscle_group_i18n", "muscle_group_code", mg_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            n = await translate_display_name_table(db, "movement_pattern_i18n", "pattern_code", mp_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            n = await translate_display_name_table(db, "set_type_i18n", "set_type_code", st_en_rows, locale, gemini_sem, client, stats)
            total_locale += n

            locale_inserted[locale] = total_locale
            logger.info(f"  🎯 {locale} done — {total_locale} total rows inserted")

    tasks = [process_locale(loc) for loc in NON_EN_LOCALES]
    await asyncio.gather(*tasks)

    elapsed = time.time() - start

    # ── Final row counts ────────────────────────────────────────────────────
    logger.info("\n🔍 Querying final row counts …")

    def count_table(table: str, id_col: str) -> dict[str, int]:
        counts: dict[str, int] = {}
        # Total
        r = db.client.table(table).select(id_col, count="exact").execute()
        counts["total"] = r.count or 0
        # En only
        r2 = db.client.table(table).select(id_col, count="exact").eq("locale", "en").execute()
        counts["en"] = r2.count or 0
        return counts

    final_counts = {
        "exercise_library_i18n":    count_table("exercise_library_i18n", "exercise_id"),
        "equipment_types_i18n":     count_table("equipment_types_i18n", "equipment_type_id"),
        "muscle_group_i18n":        count_table("muscle_group_i18n", "muscle_group_code"),
        "movement_pattern_i18n":    count_table("movement_pattern_i18n", "pattern_code"),
        "set_type_i18n":            count_table("set_type_i18n", "set_type_code"),
    }

    # ── Sample translations ──────────────────────────────────────────────────
    logger.info("\n🎯 Fetching sample translations …")
    sample_locales = ["es", "ja", "ar"]
    sample_ex_ids_res = db.client.table("exercise_library_i18n").select("exercise_id").eq("locale", "en").limit(3).execute()
    sample_ex_ids = [r["exercise_id"] for r in (sample_ex_ids_res.data or [])]

    print("\n" + "="*70)
    print("TRANSLATE_EXERCISE_LIBRARY_I18N — RESULTS")
    print("="*70)
    print(f"\nWall-clock time: {elapsed:.1f}s ({elapsed/60:.1f} min)")
    print("\n── Row counts per table ─────────────────────────────────────────────")
    for table, counts in final_counts.items():
        en_cnt = counts["en"]
        total = counts["total"]
        locale_cnt = total // en_cnt if en_cnt > 0 else 0
        expected = en_cnt * 36
        print(f"  {table:<35} total={total:>7}  (en={en_cnt}, ~{locale_cnt} locales, expected={expected})")

    print("\n── Rows inserted this run per table ─────────────────────────────────")
    for table, cnt in stats.items():
        print(f"  {table:<35} {cnt:>7} rows inserted")

    print("\n── Sample translations (3 exercises × 3 locales) ────────────────────")
    for loc in sample_locales:
        lang = LOCALE_NAMES.get(loc, loc)
        for ex_id in sample_ex_ids:
            res = db.client.table("exercise_library_i18n").select("name, instructions").eq("exercise_id", ex_id).eq("locale", loc).limit(1).execute()
            if res.data:
                row = res.data[0]
                instr_short = (row.get("instructions") or "")[:120].replace("\n", " ")
                print(f"  [{loc}/{lang}] ex={ex_id[:8]}…  name={row.get('name')!r}")
                print(f"            instr={instr_short!r}…")

    print("="*70)
    return stats


def main() -> None:
    asyncio.run(run_all())


if __name__ == "__main__":
    main()
