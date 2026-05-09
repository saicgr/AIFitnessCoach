"""5-scenario smoke test for `/api/v1/workouts/regenerate-stream`.

Each scenario regenerates an existing user workout. If the user has
fewer than 5 source workouts, falls back to whatever exists. Captures
SSE events + final preview workout. Writes CSV + per-scenario JSON.

Run from backend/:
    .venv/bin/python scripts/run_regenerate_stream_smoke.py
"""
from __future__ import annotations

import asyncio
import csv
import json
import os
import time
from datetime import date, datetime
from pathlib import Path
from typing import Any, Dict, List, Optional

import httpx
import requests
from dotenv import load_dotenv
from supabase import create_client

BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]
RENDER = "https://aifitnesscoach-zqi3.onrender.com"

USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"

sb = create_client(SUPABASE_URL, SUPABASE_KEY)


def get_jwt() -> str:
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


def list_user_workouts(min_count: int = 5) -> List[Dict[str, Any]]:
    """List the user's existing future-or-past workouts to use as regen sources."""
    today_str = date.today().isoformat()
    # Prefer future workouts; fall back to recent past if not enough.
    fut = sb.table("workouts").select(
        "id, name, type, scheduled_date, difficulty, duration_minutes"
    ).eq("user_id", USER_ID).gte("scheduled_date", today_str).order(
        "scheduled_date"
    ).limit(20).execute()
    workouts = list(fut.data or [])
    if len(workouts) < min_count:
        past = sb.table("workouts").select(
            "id, name, type, scheduled_date, difficulty, duration_minutes"
        ).eq("user_id", USER_ID).lt("scheduled_date", today_str).order(
            "scheduled_date", desc=True
        ).limit(min_count - len(workouts)).execute()
        workouts.extend(past.data or [])
    return workouts[:min_count]


def build_scenarios(sources: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """5 varied regen scenarios — different source workout + different overrides each."""
    if not sources:
        return []
    # Cycle through sources if fewer than 5.
    src = lambda i: sources[i % len(sources)]
    return [
        {
            "label": f"override difficulty=easy + duration=30 (source: {src(0)['name'][:30]})",
            "body": {
                "workout_id": src(0)["id"],
                "user_id": USER_ID,
                "duration_minutes": 30,
                "difficulty": "easy",
                "fitness_level": "intermediate",
            },
        },
        {
            "label": f"override difficulty=hard + 45min (source: {src(1)['name'][:30]})",
            "body": {
                "workout_id": src(1)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "difficulty": "hard",
                "fitness_level": "intermediate",
            },
        },
        {
            "label": f"equipment swap → bodyweight (source: {src(2)['name'][:30]})",
            "body": {
                "workout_id": src(2)["id"],
                "user_id": USER_ID,
                "duration_minutes": 30,
                "equipment": [],
                "fitness_level": "intermediate",
            },
        },
        {
            "label": f"focus pivot → cardio (source: {src(3)['name'][:30]})",
            "body": {
                "workout_id": src(3)["id"],
                "user_id": USER_ID,
                "duration_minutes": 45,
                "focus_areas": ["cardio"],
                "workout_type": "cardio",
            },
        },
        {
            "label": f"ai_prompt='no jumping, knee pain' (source: {src(4)['name'][:30]})",
            "body": {
                "workout_id": src(4)["id"],
                "user_id": USER_ID,
                "duration_minutes": 30,
                "ai_prompt": "no jumping or impact today, my knees hurt",
                "injuries": ["knee"],
            },
        },
    ]


CSV_COLS = [
    "idx", "label", "source_workout_id", "source_workout_name",
    "http_status", "latency_ms", "request_body_json", "sse_event_count",
    "preview_id", "ai_workout_name", "ai_workout_type", "ai_difficulty",
    "ai_notes", "n_exercises", "exercise_names_pipe",
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "duration_minutes", "total_volume_kg",
    "error_message", "final_workout_json",
]


async def call_sse(client: httpx.AsyncClient, jwt: str, body: Dict[str, Any]) -> Dict[str, Any]:
    t0 = time.time()
    events: List[Dict[str, Any]] = []
    final_workout: Optional[Dict[str, Any]] = None
    preview_id: Optional[str] = None
    err: Optional[str] = None
    status = -1

    try:
        async with client.stream(
            "POST",
            f"{RENDER}/api/v1/workouts/regenerate-stream",
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
                    "preview_id": None,
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
                        if "preview_id" in ev:
                            preview_id = ev.get("preview_id")
                        if "error" in ev and "id" not in ev:
                            err = f"sse_error: {str(ev['error'])[:300]}"
                        # Final event IS the workout (top-level id + exercises).
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
        "preview_id": preview_id,
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


def write_outputs(out_dir: Path, idx: int, sc: Dict[str, Any], src: Dict[str, Any], result: Dict[str, Any]) -> None:
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
        "source_workout_id": src.get("id", ""),
        "source_workout_name": src.get("name", ""),
        "http_status": result["status"],
        "latency_ms": result["latency_ms"],
        "request_body_json": json.dumps(sc["body"], default=str),
        "sse_event_count": len(result.get("events") or []),
        "preview_id": result.get("preview_id") or "",
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

    jpath = out_dir / "json" / f"scenario_{idx:03d}.json"
    jpath.write_text(json.dumps({
        "scenario": sc,
        "source_workout_meta": src,
        "result": result,
        "csv_row": row,
    }, indent=2, default=str))

    print(
        f"[{idx}/5] status={row['http_status']} "
        f"latency={row['latency_ms']}ms "
        f"events={row['sse_event_count']} "
        f"preview={row['preview_id'][:8] if row['preview_id'] else '-'} "
        f"name=\"{row['ai_workout_name']}\" "
        f"n_ex={row['n_exercises']} "
        f"err={row['error_message'] or 'OK'} "
        f"| {sc['label']}",
        flush=True,
    )


async def main() -> None:
    print("[smoke] auth...", flush=True)
    jwt = get_jwt()
    print("[smoke] JWT ok", flush=True)

    print("[smoke] listing source workouts...", flush=True)
    sources = list_user_workouts(min_count=5)
    if not sources:
        print("[smoke] ERROR: user has 0 workouts to regenerate. "
              "Run /generate-stream first to seed some.", flush=True)
        return
    print(f"[smoke] found {len(sources)} source workouts", flush=True)

    scenarios = build_scenarios(sources)

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = BACKEND / "scripts" / "output" / f"render_regenerate_stream_smoke_{ts}"
    (out_dir / "json").mkdir(parents=True, exist_ok=True)
    csv_path = out_dir / "workouts.csv"
    with csv_path.open("w", newline="") as fh:
        csv.writer(fh).writerow(CSV_COLS)
    print(f"[smoke] output → {out_dir}", flush=True)

    async with httpx.AsyncClient() as client:
        for idx, sc in enumerate(scenarios, start=1):
            src = sources[(idx - 1) % len(sources)]
            res = await call_sse(client, jwt, sc["body"])
            write_outputs(out_dir, idx, sc, src, res)
            await asyncio.sleep(13.0)  # 5/min IP limit

    print(f"\n[smoke] done → {out_dir}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
