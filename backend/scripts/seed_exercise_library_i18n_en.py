"""Seed English (locale='en') rows into exercise i18n tables.

Reads existing exercise_library, equipment_types, and distinct muscle/
movement-pattern/set-type codes, then inserts 'en' rows into:
  - exercise_library_i18n
  - equipment_types_i18n
  - muscle_group_i18n
  - movement_pattern_i18n
  - set_type_i18n  (set_type_i18n is pre-seeded in the migration; this
                    script treats it as idempotent too)

All inserts use ON CONFLICT DO NOTHING so the script is safe to re-run.

Usage:
  cd /Users/saichetangrandhe/AIFitnessCoach
  backend/.venv/bin/python -m backend.scripts.seed_exercise_library_i18n_en

Constraints:
  - NO Gemini / OpenAI calls. English text is copied verbatim from source rows.
  - Does NOT run migrations. Run 2104_exercise_library_i18n.sql first.
"""
from __future__ import annotations

import json
import logging
import sys
from pathlib import Path

# Ensure backend/ is importable whether run as __main__ or as a module.
BACKEND_DIR = Path(__file__).resolve().parent.parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from core.db import get_supabase_db  # noqa: E402

logger = logging.getLogger(__name__)
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
)

LOCALE = "en"

# Canonical set-type codes (mirrors gemini_schemas.py + 2104 migration).
SET_TYPE_LABELS: dict[str, str] = {
    "warmup":  "Warm-up",
    "working": "Working",
    "drop":    "Drop Set",
    "failure": "To Failure",
    "amrap":   "AMRAP",
}


def _batched(seq: list, size: int):
    """Yield consecutive slices of *seq* of length *size*."""
    for i in range(0, len(seq), size):
        yield seq[i : i + size]


# ---------------------------------------------------------------------------
# exercise_library_i18n
# ---------------------------------------------------------------------------

def seed_exercise_library(db) -> int:
    """Copy exercise_name + instructions + muscles from exercise_library → i18n table.

    exercise_library uses columns:
        id                (TEXT/UUID)
        exercise_name     (TEXT)
        instructions      (TEXT)
        target_muscle     (TEXT)  — maps to primary_muscle_localized
        secondary_muscles (TEXT)  — JSON array string, may be null/empty

    Returns number of rows inserted.
    """
    logger.info("🔍 [exercise_library_i18n] Fetching exercise_library rows …")

    # Fetch in pages to avoid loading ~3000 rows at once into Python RAM
    # (Supabase default page cap is 1000; PostgREST honours Range headers).
    PAGE = 1000
    offset = 0
    all_rows: list[dict] = []
    while True:
        res = (
            db.client
            .table("exercise_library")
            .select("id, exercise_name, instructions, target_muscle, secondary_muscles")
            .range(offset, offset + PAGE - 1)
            .execute()
        )
        batch = res.data or []
        all_rows.extend(batch)
        if len(batch) < PAGE:
            break
        offset += PAGE

    logger.info(f"✅ [exercise_library_i18n] Fetched {len(all_rows)} exercises")

    if not all_rows:
        logger.warning("⚠️  [exercise_library_i18n] No rows found in exercise_library — skipping")
        return 0

    payloads: list[dict] = []
    for row in all_rows:
        # secondary_muscles may be a JSON string '["glutes", "hamstrings"]' or None/empty
        sec_raw = row.get("secondary_muscles") or "[]"
        if isinstance(sec_raw, str):
            try:
                sec_json = json.loads(sec_raw)
            except (ValueError, TypeError):
                sec_json = []
        elif isinstance(sec_raw, list):
            sec_json = sec_raw
        else:
            sec_json = []

        payloads.append({
            "exercise_id": str(row["id"]),
            "locale": LOCALE,
            "name": row.get("exercise_name") or "",
            "instructions": row.get("instructions") or "",
            "primary_muscle_localized": row.get("target_muscle") or "",
            "secondary_muscles_localized": sec_json,
        })

    inserted = 0
    for batch in _batched(payloads, 200):
        res = (
            db.client
            .table("exercise_library_i18n")
            .upsert(batch, on_conflict="exercise_id,locale", ignore_duplicates=True)
            .execute()
        )
        inserted += len(res.data or [])

    logger.info(f"✅ [exercise_library_i18n] Inserted {inserted} / {len(payloads)} rows (others already existed)")
    return inserted


# ---------------------------------------------------------------------------
# equipment_types_i18n
# ---------------------------------------------------------------------------

def seed_equipment_types(db) -> int:
    """Copy display_name + aliases from equipment_types → i18n table.

    equipment_types columns used:
        id            (UUID)
        display_name  (TEXT)
        aliases       (TEXT[])  — Postgres array; Supabase returns as Python list
    """
    logger.info("🔍 [equipment_types_i18n] Fetching equipment_types rows …")
    res = db.client.table("equipment_types").select("id, display_name, aliases").execute()
    rows = res.data or []
    logger.info(f"✅ [equipment_types_i18n] Fetched {len(rows)} equipment types")

    if not rows:
        logger.warning("⚠️  [equipment_types_i18n] No rows in equipment_types — skipping")
        return 0

    payloads: list[dict] = []
    for row in rows:
        aliases_raw = row.get("aliases") or []
        if isinstance(aliases_raw, str):
            # Postgres array string "{a,b}" — shouldn't happen via Supabase client
            # but guard defensively.
            aliases_raw = [a.strip().strip('"') for a in aliases_raw.strip("{}").split(",") if a.strip()]

        payloads.append({
            "equipment_type_id": str(row["id"]),
            "locale": LOCALE,
            "display_name": row.get("display_name") or "",
            "aliases": aliases_raw if isinstance(aliases_raw, list) else list(aliases_raw),
        })

    inserted = 0
    for batch in _batched(payloads, 200):
        res = (
            db.client
            .table("equipment_types_i18n")
            .upsert(batch, on_conflict="equipment_type_id,locale", ignore_duplicates=True)
            .execute()
        )
        inserted += len(res.data or [])

    logger.info(f"✅ [equipment_types_i18n] Inserted {inserted} / {len(payloads)} rows")
    return inserted


# ---------------------------------------------------------------------------
# muscle_group_i18n
# ---------------------------------------------------------------------------

def seed_muscle_groups(db) -> int:
    """Derive distinct muscle codes from exercise_library and seed en rows.

    Sources:
        exercise_library.target_muscle   (primary muscle)
        exercise_library.body_part       (body region label)

    Both are lowercased and de-duped. The English display_name is a
    title-cased version of the code (e.g. 'quads' → 'Quads').
    """
    logger.info("🔍 [muscle_group_i18n] Deriving distinct muscle codes …")
    res = (
        db.client
        .table("exercise_library")
        .select("target_muscle, body_part")
        .execute()
    )
    rows = res.data or []

    codes: set[str] = set()
    for row in rows:
        for field in ("target_muscle", "body_part"):
            val = (row.get(field) or "").strip().lower()
            if val:
                codes.add(val)

    if not codes:
        logger.warning("⚠️  [muscle_group_i18n] No muscle codes found — skipping")
        return 0

    logger.info(f"✅ [muscle_group_i18n] Found {len(codes)} distinct muscle/body-part codes")

    payloads = [
        {
            "muscle_group_code": code,
            "locale": LOCALE,
            # English display: title-case with spaces for underscores
            "display_name": code.replace("_", " ").title(),
        }
        for code in sorted(codes)
    ]

    inserted = 0
    for batch in _batched(payloads, 200):
        res = (
            db.client
            .table("muscle_group_i18n")
            .upsert(batch, on_conflict="muscle_group_code,locale", ignore_duplicates=True)
            .execute()
        )
        inserted += len(res.data or [])

    logger.info(f"✅ [muscle_group_i18n] Inserted {inserted} / {len(payloads)} rows")
    return inserted


# ---------------------------------------------------------------------------
# movement_pattern_i18n
# ---------------------------------------------------------------------------

def seed_movement_patterns(db) -> int:
    """Derive distinct category codes from exercise_library and seed en rows.

    exercise_library.category holds values like 'strength', 'cardio',
    'flexibility', 'olympic', etc.
    English display_name is title-cased from the code.
    """
    logger.info("🔍 [movement_pattern_i18n] Deriving distinct category codes …")
    res = (
        db.client
        .table("exercise_library")
        .select("category")
        .execute()
    )
    rows = res.data or []

    codes: set[str] = set()
    for row in rows:
        val = (row.get("category") or "").strip().lower()
        if val:
            codes.add(val)

    if not codes:
        logger.warning("⚠️  [movement_pattern_i18n] No category codes found — skipping")
        return 0

    logger.info(f"✅ [movement_pattern_i18n] Found {len(codes)} distinct category codes")

    payloads = [
        {
            "pattern_code": code,
            "locale": LOCALE,
            "display_name": code.replace("_", " ").title(),
        }
        for code in sorted(codes)
    ]

    inserted = 0
    for batch in _batched(payloads, 200):
        res = (
            db.client
            .table("movement_pattern_i18n")
            .upsert(batch, on_conflict="pattern_code,locale", ignore_duplicates=True)
            .execute()
        )
        inserted += len(res.data or [])

    logger.info(f"✅ [movement_pattern_i18n] Inserted {inserted} / {len(payloads)} rows")
    return inserted


# ---------------------------------------------------------------------------
# set_type_i18n
# ---------------------------------------------------------------------------

def seed_set_types(db) -> int:
    """Ensure all canonical set-type en rows exist (idempotent top-up)."""
    logger.info("🔍 [set_type_i18n] Seeding canonical set-type en rows …")

    payloads = [
        {"set_type_code": code, "locale": LOCALE, "display_name": label}
        for code, label in SET_TYPE_LABELS.items()
    ]

    inserted = 0
    for batch in _batched(payloads, 50):
        res = (
            db.client
            .table("set_type_i18n")
            .upsert(batch, on_conflict="set_type_code,locale", ignore_duplicates=True)
            .execute()
        )
        inserted += len(res.data or [])

    logger.info(f"✅ [set_type_i18n] Inserted {inserted} / {len(payloads)} rows")
    return inserted


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    db = get_supabase_db()

    results: dict[str, int] = {}
    results["exercise_library_i18n"]  = seed_exercise_library(db)
    results["equipment_types_i18n"]   = seed_equipment_types(db)
    results["muscle_group_i18n"]      = seed_muscle_groups(db)
    results["movement_pattern_i18n"]  = seed_movement_patterns(db)
    results["set_type_i18n"]          = seed_set_types(db)

    print("\n── Seed summary (locale='en') ──────────────────────────────")
    total = 0
    for table, count in results.items():
        print(f"  {table:<35} {count:>6} rows inserted")
        total += count
    print(f"  {'TOTAL':<35} {total:>6} rows")
    print("────────────────────────────────────────────────────────────")


if __name__ == "__main__":
    main()
