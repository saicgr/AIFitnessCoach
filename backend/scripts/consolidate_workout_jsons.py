"""Consolidate per-call workout-validation JSON dumps into a single CSV.

Walks every `scripts/output/validate_workouts*/json/workout_NNN.json`,
flattens each into one CSV row, writes
`scripts/output/<run_dir>/workouts_consolidated.csv`, and then deletes
the `json/` directories.

Run:
    cd backend && .venv/bin/python scripts/consolidate_workout_jsons.py
"""
from __future__ import annotations

import csv
import json
import shutil
import sys
from pathlib import Path
from typing import Any, Dict, List

ROOT = Path(__file__).resolve().parent.parent / "scripts" / "output"

# Flatten an exercise dict into pipe-joinable strings.
def _ex_field(exs: List[Dict[str, Any]], key: str, alt: str = "") -> str:
    out: List[str] = []
    for e in exs or []:
        v = e.get(key)
        if v in (None, "") and alt:
            v = e.get(alt)
        if isinstance(v, list):
            v = ",".join(str(x) for x in v)
        out.append(str(v) if v is not None else "")
    return "|".join(out)


def _ex_name(e: Dict[str, Any]) -> str:
    return e.get("name") or e.get("exercise_name") or ""


def _flatten(payload: Dict[str, Any]) -> Dict[str, Any]:
    p = payload.get("params") or {}
    exs = payload.get("exercises") or []
    inp = payload.get("input_library_exercises") or []
    return {
        "idx": payload.get("idx"),
        "generation_path": payload.get("generation_path", ""),
        "round": p.get("round", ""),
        "intensity": p.get("intensity", ""),
        "fitness_level": p.get("fitness_level", ""),
        "duration_target_min": p.get("duration_minutes", ""),
        "goal": p.get("goal", ""),
        "equipment_set": p.get("equipment_set", ""),
        "focus": p.get("focus", ""),
        "injuries": ",".join(p.get("injuries") or []),
        "comeback_offset_days": p.get("comeback_offset_days", ""),
        "n_input_library_exercises": len(inp),
        "input_library_names": "|".join(_ex_name(e) for e in inp),
        "n_exercises": len(exs),
        "ai_workout_name": payload.get("ai_workout_name", ""),
        "ai_workout_type": payload.get("ai_workout_type", ""),
        "ai_difficulty": payload.get("ai_difficulty", ""),
        "ai_notes": payload.get("ai_notes", ""),
        "exercise_names_pipe_separated": "|".join(_ex_name(e) for e in exs),
        "per_exercise_sets": _ex_field(exs, "sets"),
        "per_exercise_reps": _ex_field(exs, "reps"),
        "per_exercise_weight_kg": _ex_field(exs, "weight_kg", "weight"),
        "per_exercise_rest_seconds": _ex_field(exs, "rest_seconds"),
        "per_exercise_muscle_group": _ex_field(exs, "muscle_group", "body_part"),
        "est_duration_min": f"{payload.get('est_duration_min') or 0:.1f}",
        "total_volume_kg": f"{payload.get('total_volume_kg') or 0:.1f}",
        "n_safety_violations": payload.get("n_safety_violations", 0),
        "safety_violation_summary": " | ".join(
            (payload.get("safety_log_lines") or [])[:5]
        ),
        "n_difficulty_scaled": payload.get("n_difficulty_scaled", 0),
        "tokens_in": payload.get("tokens_in", 0),
        "tokens_out": payload.get("tokens_out", 0),
        "error": payload.get("error", "") or "",
        "prompt_char_count": len(payload.get("prompt_text") or ""),
        "prompt_text": payload.get("prompt_text") or "",
    }


COLS = list(_flatten({"params": {}, "exercises": []}).keys())


def consolidate_run(run_dir: Path) -> int:
    json_dir = run_dir / "json"
    if not json_dir.is_dir():
        return 0
    rows: List[Dict[str, Any]] = []
    for jf in sorted(json_dir.glob("workout_*.json")):
        try:
            payload = json.loads(jf.read_text())
        except Exception as e:
            print(f"  ⚠️  skipping {jf.name}: {e}")
            continue
        rows.append(_flatten(payload))
    if not rows:
        return 0
    rows.sort(key=lambda r: r.get("idx") or 0)
    out = run_dir / "workouts_consolidated.csv"
    with out.open("w", newline="") as fh:
        w = csv.DictWriter(fh, fieldnames=COLS)
        w.writeheader()
        w.writerows(rows)
    return len(rows)


def main() -> None:
    if not ROOT.is_dir():
        print(f"Output dir not found: {ROOT}")
        sys.exit(1)
    total_rows = 0
    deleted_dirs = 0
    for run_dir in sorted(ROOT.iterdir()):
        if not run_dir.is_dir():
            continue
        n = consolidate_run(run_dir)
        if n:
            print(f"✅ {run_dir.name}: {n} rows → {run_dir / 'workouts_consolidated.csv'}")
            total_rows += n
            json_dir = run_dir / "json"
            if json_dir.is_dir():
                shutil.rmtree(json_dir)
                print(f"   🗑️  removed {json_dir}")
                deleted_dirs += 1
        else:
            print(f"·  {run_dir.name}: no JSON to consolidate")
    print(f"\nTotal: {total_rows} rows across {deleted_dirs} run(s)")


if __name__ == "__main__":
    main()
