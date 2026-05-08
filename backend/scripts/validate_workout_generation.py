"""100-workout generation validation harness (workout generation only).

Drives the library path (and optionally the streaming path) with the real
Gemini model and writes MD/CSV/JSON artifacts INCREMENTALLY — one row/section
flushed to disk after every API call so partial results are inspectable
during the run. Sequential calls with a 1.5s pacing gap to stay safely
under Gemini free-tier (15 RPM).

Usage:
    cd backend && .venv/bin/python scripts/validate_workout_generation.py \\
        --n 100 --user-id <uuid> --paths library --out scripts/output/

Artifacts:
    scripts/output/validate_workouts_<ts>/
        workouts.csv             — one row per call, appended live
        workouts.md              — verbose section per call (params, library
                                   input, prompt, AI response, exercises,
                                   safety), appended live
        workouts.summary.md      — written at the end
        json/workout_NNN.json    — full per-call dump

Notes:
- Run `seed_qa_user.py` first.
- NEVER falls back to mock data. On per-call exception, captures the error
  string and continues — does not crash the sweep.
"""
from __future__ import annotations

import argparse
import asyncio
import json as _json
import logging
import os
import re as _re
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Any, Dict, List

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts._validation_helpers import (  # noqa: E402
    EQUIPMENT_SETS, GenerationResult, append_csv, append_json,
    append_markdown, build_sweep_matrix, compute_volume_and_duration,
    init_csv, init_markdown, install_prompt_capture,
    run_safety_validator, select_library_exercises, streaming_subset,
    write_summary,
)

_log = logging.getLogger("validate_workout_generation")
logging.basicConfig(level=logging.WARNING,
                    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s")
# These chains are INFO-noisy and bury the harness progress output.
for _name in ("sqlalchemy.engine", "sqlalchemy.engine.Engine", "Engine",
              "workout_safety_validator", "gemini", "httpx"):
    logging.getLogger(_name).setLevel(logging.WARNING)
# But we DO need INFO from the gemini helpers logger so PromptCapture sees the
# rendered prompt. Set it explicitly.
logging.getLogger("services.gemini.workout_generation_helpers_part2").setLevel(
    logging.INFO
)


async def _gen_library(
    gemini, library_service, params: Dict[str, Any], user_id: str,
    prompt_capture,
) -> GenerationResult:
    idx = params["__idx"]
    result = GenerationResult(idx=idx, params=params, generation_path="library")

    eq_set_key = params["equipment_set"]
    equipment = EQUIPMENT_SETS[eq_set_key]
    duration = params["duration_minutes"]

    target_count = max(3, min(8, duration // 7 or 4))
    eq_for_library = equipment if equipment else ["body weight"]

    exercises = select_library_exercises(
        library_service=library_service, focus=params["focus"],
        equipment=eq_for_library, fitness_level=params["fitness_level"],
        count=target_count,
    )
    result.input_library_exercises = list(exercises) if exercises else []
    if not exercises:
        result.error = (
            f"no_exercises_from_library focus={params['focus']} "
            f"equipment_set={eq_set_key}"
        )
        return result

    n_scaled = sum(1 for ex in exercises if ex.get("sets") and ex.get("reps"))

    comeback_context = None
    if params.get("comeback_offset_days"):
        comeback_context = (
            f"User returning after {params['comeback_offset_days']} days off."
        )

    # Clear any stale prompt before this call.
    prompt_capture.consume()

    try:
        out = await gemini.generate_workout_from_library(
            exercises=exercises,
            fitness_level=params["fitness_level"],
            goals=[params["goal"]],
            duration_minutes=duration,
            focus_areas=[params["focus"]],
            intensity_preference=params["intensity"],
            comeback_context=comeback_context,
            injuries=params.get("injuries") or None,
        )
    except Exception as e:
        result.prompt_text = prompt_capture.consume() or ""
        result.error = f"gemini_error: {e}"
        return result

    result.prompt_text = prompt_capture.consume() or ""
    result.exercises = out.get("exercises") or []
    result.ai_workout_name = out.get("name") or ""
    result.ai_workout_type = out.get("type") or ""
    result.ai_difficulty = out.get("difficulty") or ""
    result.ai_notes = out.get("notes") or ""
    result.n_difficulty_scaled = n_scaled
    vol, dur = compute_volume_and_duration(result.exercises)
    result.total_volume_kg = vol
    result.est_duration_min = dur

    n_viol, log_lines = await run_safety_validator(
        exercises=result.exercises, user_id=user_id,
        fitness_level=params["fitness_level"], equipment=equipment,
        injuries=params.get("injuries") or [],
    )
    result.n_safety_violations = n_viol
    result.safety_log_lines = log_lines
    return result


async def _gen_streaming(gemini, params: Dict[str, Any]) -> GenerationResult:
    idx = params["__idx"]
    result = GenerationResult(idx=idx, params=params, generation_path="streaming")
    try:
        chunks: List[str] = []
        eq = EQUIPMENT_SETS[params["equipment_set"]] or ["bodyweight"]
        agen = gemini.generate_workout_plan_streaming(
            fitness_level=params["fitness_level"], goals=[params["goal"]],
            equipment=eq, duration_minutes=params["duration_minutes"],
            focus_areas=[params["focus"]],
            intensity_preference=params["intensity"],
            exercise_count=max(3, min(8, params["duration_minutes"] // 7 or 4)),
        )
        async for chunk in agen:
            if chunk:
                chunks.append(str(chunk))
        blob = "".join(chunks)
        m = _re.search(r"\{.*\}", blob, _re.DOTALL)
        parsed: Dict[str, Any] = {}
        if m:
            try:
                parsed = _json.loads(m.group(0))
            except Exception:
                parsed = {}
        result.exercises = parsed.get("exercises") or []
        result.ai_workout_name = parsed.get("name") or ""
        result.ai_workout_type = parsed.get("type") or ""
        result.ai_difficulty = parsed.get("difficulty") or ""
        result.ai_notes = parsed.get("notes") or ""
        vol, dur = compute_volume_and_duration(result.exercises)
        result.total_volume_kg = vol
        result.est_duration_min = dur
    except Exception as e:
        result.error = f"streaming_error: {e}"
    return result


async def run(args: argparse.Namespace) -> None:
    from services.gemini.service import GeminiService
    from services.exercise_library_service import get_exercise_library_service

    gemini = GeminiService()
    library = get_exercise_library_service()
    prompt_capture = install_prompt_capture()

    matrix = build_sweep_matrix(n=args.n)
    for i, p in enumerate(matrix, 1):
        p["__idx"] = i

    out_root = Path(args.out)
    out_root.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = out_root / f"validate_workouts_{ts}"
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"[harness] Output → {out_dir}")

    csv_path = init_csv(out_dir)
    md_path = init_markdown(out_dir)

    results: List[GenerationResult] = []

    def _flush(r: GenerationResult) -> None:
        append_csv(csv_path, r)
        append_markdown(md_path, r)
        append_json(out_dir, r)

    if args.paths in ("library", "both"):
        for p in matrix:
            r = await _gen_library(gemini, library, p, args.user_id,
                                   prompt_capture)
            results.append(r)
            _flush(r)
            err = f" ERROR={r.error}" if r.error else ""
            print(
                f"[{r.idx}/{len(matrix)}] {p['intensity']} / {p['fitness_level']}"
                f" / {p['duration_minutes']}min / {p['goal']} / "
                f"{p['equipment_set']} / {p['focus']} → "
                f"{len(r.exercises)} ex, {r.n_safety_violations} viol, "
                f"name='{r.ai_workout_name}'{err}"
            )
            await asyncio.sleep(1.5)

    if args.paths in ("streaming", "both"):
        subset = streaming_subset(matrix)
        offset = max((r.idx for r in results), default=0)
        for j, p in enumerate(subset, 1):
            p2 = dict(p)
            p2["__idx"] = offset + j
            r = await _gen_streaming(gemini, p2)
            results.append(r)
            _flush(r)
            err = f" ERROR={r.error}" if r.error else ""
            print(
                f"[stream {j}/{len(subset)}] {p['intensity']} / "
                f"{p['fitness_level']} / {p['duration_minutes']}min → "
                f"{len(r.exercises)} ex{err}"
            )
            await asyncio.sleep(1.5)

    summary = write_summary(out_dir, results)
    print("\n--- Wrote artifacts ---")
    print(f"  {md_path}")
    print(f"  {csv_path}")
    print(f"  {summary}")
    print(f"  {out_dir / 'json'}/")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n", type=int, default=100)
    parser.add_argument("--user-id", required=True)
    parser.add_argument(
        "--paths", choices=["library", "streaming", "both"], default="library"
    )
    parser.add_argument("--out", default="scripts/output/")
    args = parser.parse_args()
    t0 = time.time()
    asyncio.run(run(args))
    print(f"\n[harness] Done in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
