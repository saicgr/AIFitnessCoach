"""5-scenario smoke test for `/api/v1/workouts/generate-stream` (home carousel).

Each scenario: builds varied body, opens SSE stream, captures all events,
extracts the final workout. Writes incremental CSV + per-scenario JSON.

Run from backend/:
    .venv/bin/python scripts/run_generate_stream_smoke.py
"""
from __future__ import annotations

import asyncio
import csv
import json
import os
import time
import uuid
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
import requests
from dotenv import load_dotenv

BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
RENDER = "https://aifitnesscoach-zqi3.onrender.com"

USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"
ACTIVE_PROFILE = "0890400c-6900-4cd0-b55a-353ea1655206"
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"


def get_jwt() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def next_preferred_dates(n: int) -> List[str]:
    # Reviewer's gym profile workout_days = [Tue=1, Thu=3, Sat=5]
    out: List[str] = []
    d = date.today() + timedelta(days=1)
    while len(out) < n:
        if d.weekday() in (1, 3, 5):
            out.append(d.isoformat())
        d += timedelta(days=1)
    return out


def build_scenarios() -> List[Dict[str, Any]]:
    dates = next_preferred_dates(5)
    return [
        {
            "label": "easy / beginner / 30min / strength / push / dumbbells",
            "body": {
                "user_id": USER_ID,
                "gym_profile_id": ACTIVE_PROFILE,
                "fitness_level": "beginner",
                "goals": ["strength"],
                "duration_minutes": 30,
                "focus_areas": ["push"],
                # equipment omitted to dodge body-only fast-path bug
                "scheduled_date": dates[0],
                "force_non_preferred_day": True,
            },
        },
        {
            "label": "medium / intermediate / 45min / hypertrophy / legs / full_gym",
            "body": {
                "user_id": USER_ID,
                "gym_profile_id": ACTIVE_PROFILE,
                "fitness_level": "intermediate",
                "goals": ["hypertrophy"],
                "duration_minutes": 45,
                "focus_areas": ["legs"],
                # equipment omitted to dodge body-only fast-path bug
                "scheduled_date": dates[1],
                "force_non_preferred_day": True,
            },
        },
        {
            "label": "hard / advanced / 60min / endurance / full_body / cardio_machines",
            "body": {
                "user_id": USER_ID,
                "gym_profile_id": ACTIVE_PROFILE,
                "fitness_level": "advanced",
                "goals": ["endurance"],
                "duration_minutes": 60,
                "focus_areas": ["full_body"],
                # equipment omitted to dodge body-only fast-path bug
                "scheduled_date": dates[2],
                "force_non_preferred_day": True,
            },
        },
        {
            "label": "easy / beginner / 30min / mobility / core / bodyweight",
            "body": {
                "user_id": USER_ID,
                "gym_profile_id": ACTIVE_PROFILE,
                "fitness_level": "beginner",
                "goals": ["mobility"],
                "duration_minutes": 30,
                "focus_areas": ["core"],
                # equipment omitted to dodge body-only fast-path bug
                "scheduled_date": dates[3],
                "force_non_preferred_day": True,
            },
        },
        {
            "label": "medium / intermediate / 45min / fat_loss / pull / no_barbell + knee injury",
            "body": {
                "user_id": USER_ID,
                "gym_profile_id": ACTIVE_PROFILE,
                "fitness_level": "intermediate",
                "goals": ["fat_loss"],
                "duration_minutes": 45,
                "focus_areas": ["pull"],
                # equipment omitted to dodge body-only fast-path bug
                "scheduled_date": dates[4],
                "force_non_preferred_day": True,
            },
        },
    ]


CSV_COLS = [
    "idx", "label", "http_status", "latency_ms",
    "request_body_json", "sse_event_count",
    "response_workout_id", "ai_workout_name", "ai_workout_type",
    "ai_difficulty", "ai_notes", "n_exercises", "exercise_names_pipe",
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "duration_minutes", "total_volume_kg",
    "error_message", "final_workout_json",
]


async def call_sse(client: httpx.AsyncClient, jwt: str, body: Dict[str, Any]) -> Dict[str, Any]:
    """POST to /generate-stream, parse SSE events, return final workout + meta."""
    t0 = time.time()
    events: List[Dict[str, Any]] = []
    final_workout: Optional[Dict[str, Any]] = None
    err: Optional[str] = None
    status = -1

    try:
        async with client.stream(
            "POST",
            f"{RENDER}/api/v1/workouts/generate-stream",
            json=body,
            headers={
                "Authorization": f"Bearer {jwt}",
                "Accept": "text/event-stream",
            },
            timeout=60.0,
        ) as resp:
            status = resp.status_code
            if resp.status_code != 200:
                txt = await resp.aread()
                err = f"HTTP {resp.status_code}: {txt[:300]!r}"
                return {
                    "status": status,
                    "latency_ms": int((time.time() - t0) * 1000),
                    "events": [],
                    "final_workout": None,
                    "error": err,
                }
            async for line in resp.aiter_lines():
                if not line:
                    continue
                if line.startswith("data: "):
                    raw = line[6:].strip()
                    if not raw:
                        continue
                    try:
                        ev = json.loads(raw)
                    except Exception:
                        events.append({"_raw": raw[:300]})
                        continue
                    events.append(ev)
                    if isinstance(ev, dict):
                        # SSE-level error events — surface them to error_message.
                        if "error" in ev and "id" not in ev:
                            err = f"sse_error: {str(ev['error'])[:300]}"
                        # Final event IS the workout (top-level id + exercises_json).
                        if "id" in ev and ("exercises_json" in ev or "exercises" in ev):
                            final_workout = ev
                        elif "workout" in ev and isinstance(ev["workout"], dict):
                            final_workout = ev["workout"]
    except Exception as e:
        err = f"{type(e).__name__}: {e}"

    return {
        "status": status,
        "latency_ms": int((time.time() - t0) * 1000),
        "events": events,
        "final_workout": final_workout,
        "error": err,
    }


def extract_exercises(workout: Optional[Dict[str, Any]]) -> List[Dict[str, Any]]:
    if not workout:
        return []
    raw = workout.get("exercises_json") or workout.get("exercises") or []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except Exception:
            return []
    return raw if isinstance(raw, list) else []


def write_outputs(out_dir: Path, idx: int, sc: Dict[str, Any], result: Dict[str, Any]) -> None:
    workout = result.get("final_workout") or {}
    exs = extract_exercises(workout)
    names = [(e.get("name") or e.get("exercise_name") or "") for e in exs]
    sets = [str(e.get("sets") or "") for e in exs]
    reps = [str(e.get("reps") or "") for e in exs]
    weights = [str(e.get("weight_kg") or e.get("weight") or "") for e in exs]
    rests = [str(e.get("rest_seconds") or "") for e in exs]
    muscles = []
    for e in exs:
        m = e.get("muscle_group") or e.get("target_muscle") or ""
        if isinstance(m, list):
            m = ",".join(m)
        muscles.append(str(m))
    total_vol = 0.0
    for e in exs:
        try:
            si = int(e.get("sets") or 0)
            ri = int(e.get("reps") or 0) if str(e.get("reps") or "").isdigit() else 10
            wf = float(e.get("weight_kg") or e.get("weight") or 0)
            total_vol += si * ri * wf
        except Exception:
            pass

    row = {
        "idx": idx,
        "label": sc["label"],
        "http_status": result["status"],
        "latency_ms": result["latency_ms"],
        "request_body_json": json.dumps(sc["body"], default=str),
        "sse_event_count": len(result.get("events") or []),
        "response_workout_id": workout.get("id", ""),
        "ai_workout_name": workout.get("name", ""),
        "ai_workout_type": workout.get("type", ""),
        "ai_difficulty": workout.get("difficulty", ""),
        "ai_notes": (workout.get("notes") or workout.get("description") or "")[:500],
        "n_exercises": len(exs),
        "exercise_names_pipe": "|".join(names),
        "per_exercise_sets": "|".join(sets),
        "per_exercise_reps": "|".join(reps),
        "per_exercise_weight_kg": "|".join(weights),
        "per_exercise_rest_seconds": "|".join(rests),
        "per_exercise_muscle_group": "|".join(muscles),
        "duration_minutes": workout.get("duration_minutes", ""),
        "total_volume_kg": f"{total_vol:.1f}",
        "error_message": result.get("error") or "",
        "final_workout_json": json.dumps(workout, separators=(",", ":"))[:8000],
    }

    csv_path = out_dir / "workouts.csv"
    with csv_path.open("a", newline="") as fh:
        csv.writer(fh).writerow([row.get(c, "") for c in CSV_COLS])

    # Per-scenario JSON dump (full event log + final workout).
    jpath = out_dir / "json" / f"scenario_{idx:03d}.json"
    jpath.write_text(json.dumps({
        "scenario": sc,
        "result": result,
        "csv_row": row,
    }, indent=2, default=str))

    print(
        f"[{idx}/5] status={row['http_status']} "
        f"latency={row['latency_ms']}ms "
        f"events={row['sse_event_count']} "
        f"name=\"{row['ai_workout_name']}\" "
        f"n_ex={row['n_exercises']} "
        f"err={row['error_message'] or 'OK'} "
        f"| {sc['label']}",
        flush=True,
    )


async def main() -> None:
    jwt = get_jwt()
    print("[smoke] JWT ok", flush=True)
    scenarios = build_scenarios()

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = BACKEND / "scripts" / "output" / f"render_generate_stream_smoke_{ts}"
    (out_dir / "json").mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "workouts.csv"
    with csv_path.open("w", newline="") as fh:
        csv.writer(fh).writerow(CSV_COLS)
    print(f"[smoke] output → {out_dir}", flush=True)

    async with httpx.AsyncClient() as client:
        for idx, sc in enumerate(scenarios, start=1):
            res = await call_sse(client, jwt, sc["body"])
            write_outputs(out_dir, idx, sc, res)
            await asyncio.sleep(13.0)  # under 5/min IP limit

    print(f"\n[smoke] done → {out_dir}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
