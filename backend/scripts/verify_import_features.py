#!/usr/bin/env python
"""
Live verification script for the AI import features.

Exercises the real Gemini API + real EquipmentResolver (loaded from Supabase)
to make sure the production path works end-to-end. Does NOT mock anything —
unlike the unit tests, this is a smoke test against real external services.

Run:
    cd backend && python scripts/verify_import_features.py

Env requirements (read from backend/.env via python-dotenv if present):
    - GEMINI_API_KEY
    - SUPABASE_URL + SUPABASE_SERVICE_KEY  (for EquipmentResolver to load)

Exits 0 on success, non-zero + prints "❌ FAILED: <reason>" on any assertion
failure. Prints "✅ All checks passed" on success.
"""
from __future__ import annotations

import asyncio
import os
import sys
import traceback
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO_ROOT))

# Best-effort load of backend/.env so the script works the same way as the
# running server (which reads .env via pydantic-settings).
try:
    from dotenv import load_dotenv
    load_dotenv(REPO_ROOT / ".env")
except Exception:
    # python-dotenv not installed — not fatal, just no env autoloading.
    pass


def _have_env(var: str) -> bool:
    return bool(os.environ.get(var))


def _fail(msg: str) -> None:
    print(f"❌ FAILED: {msg}")
    sys.exit(1)


# -------------- checks ----------------------------------------------------


async def verify_gym_equipment_extractor() -> None:
    print("🏋️  [verify] GymEquipmentExtractor — text source")
    from services.gym_equipment_extractor import GymEquipmentExtractor

    sample_text = (
        "Commercial gym with: treadmills x10, elliptical x5, squat rack x2, "
        "bench press x3, cable crossover, leg press, hack squat, dumbbells "
        "5-120lb, EZ bar, plate-loaded machines (chest, shoulder, row, lat pulldown)"
    )

    extractor = GymEquipmentExtractor()
    result = await extractor.extract(source="text", raw_text=sample_text)

    matched = result.get("matched") or []
    unmatched = result.get("unmatched") or []
    env = result.get("inferred_environment")

    print(f"    matched: {len(matched)}  unmatched: {len(unmatched)}  env: {env}")
    for m in matched:
        print(f"      ✓ {m['canonical']:<22} (raw='{m['raw']}', conf={m['confidence']:.2f})")
    for u in unmatched:
        print(f"      ? {u['raw']:<30} (conf={u['confidence']:.2f})")

    # Threshold: Gemini + taxonomy resolution is inherently stochastic; we only
    # fail if we see fewer than 6 — well above the "pipeline is broken" bar but
    # loose enough to tolerate small taxonomy gaps (e.g. squat_rack / hack_squat
    # sometimes surface in `unmatched`). If you hit this in prod, expand aliases
    # in equipment_types rather than lowering this.
    if len(matched) < 6:
        _fail(f"Expected >= 6 matched canonical equipment, got {len(matched)}")
    if env != "commercial_gym":
        _fail(f"Expected inferred_environment='commercial_gym', got {env!r}")

    print("    ✅ gym equipment extractor checks passed")


async def verify_ai_exercise_extractor() -> None:
    print("🤖 [verify] AiExerciseExtractor — text source")
    from services.ai_exercise_extractor import AiExerciseExtractor

    extractor = AiExerciseExtractor(vision_service=None)
    payload = await extractor.extract_from_text(
        "seated cable row neutral grip",
        user_hint=None,
    )

    print(f"    name: {payload.get('name')!r}")
    print(f"    equipment: {payload.get('equipment')!r}")
    print(f"    target_muscles: {payload.get('target_muscles')}")
    print(f"    default_reps: {payload.get('default_reps')}  "
          f"default_duration_seconds: {payload.get('default_duration_seconds')}")

    if not payload.get("target_muscles"):
        _fail("target_muscles is empty")
    if "cable" not in (payload.get("equipment") or "").lower():
        _fail(f"Expected equipment to contain 'cable', got {payload.get('equipment')!r}")
    if not payload.get("name"):
        _fail("name is empty")

    print("    ✅ ai exercise extractor checks passed")


# -------------- entrypoint ------------------------------------------------


async def main() -> None:
    print("🔍 Live verification: AI gym equipment + exercise importers\n")

    if not _have_env("GEMINI_API_KEY"):
        print("⚠️  GEMINI_API_KEY not set — skipping live Gemini calls.")
        print("   Set GEMINI_API_KEY in backend/.env and rerun to exercise "
              "the full Gemini path.")
        sys.exit(0)

    try:
        await verify_gym_equipment_extractor()
        print()
        await verify_ai_exercise_extractor()
    except AssertionError as e:
        _fail(f"assertion: {e}")
    except Exception as e:
        traceback.print_exc()
        _fail(f"unexpected exception: {e}")

    print("\n✅ All checks passed")


if __name__ == "__main__":
    asyncio.run(main())
