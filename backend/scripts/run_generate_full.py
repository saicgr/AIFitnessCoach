"""100-scenario sweep for `/api/v1/workouts/generate` (RAG-FIRST endpoint).

This is the non-streaming endpoint used by `today.py` for background batch
backfill. Architecture: `generate_workout_from_library` pre-fetches library
exercises and passes them to Gemini, which only adds name + structure.
Implication: every output exercise should have a library-backed
`exercise_id`, with image_s3_path and video_url populated.

Returns a single JSON Workout (no SSE). Per-call latency ~10-15s.

Run:
    cd backend && .venv/bin/python scripts/run_generate_full.py
    .venv/bin/python scripts/run_generate_full.py --n 5     # smoke
    .venv/bin/python scripts/run_generate_full.py --resume auto
"""
from __future__ import annotations

import argparse
import asyncio
import json
import sys
import os
import time
from datetime import datetime as _dt
from pathlib import Path as _P
from typing import Any, Dict, List, Optional

import httpx

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from scripts._smoke_lib import (  # noqa: E402
    BACKEND, RENDER, USER_ID, ACTIVE_PROFILE,
    consolidate_and_cleanup, get_jwt, init_outputs,
    next_n_dates, resume_or_init_outputs,
    update_md_live_status, write_row,
)
from scripts._scenarios_500 import build_500  # noqa: E402

_MD_PATH = _P(
    "/Users/saichetangrandhe/AIFitnessCoach/backend/scripts/scenarios/"
    "generate_scenarios.md"
)


def build_500_for_generate() -> List[Dict[str, Any]]:
    """Use ALL 500 scenarios from the builder. Re-number 1..500."""
    pool = build_500()
    for i, s in enumerate(pool[:500], 1):
        s["idx"] = i
    return pool[:500]


# Backward-compat alias (kept so older invocations still work)
build_100_for_generate = build_500_for_generate


CSV_COLS = [
    "idx", "scenario_block", "label", "http_status", "latency_ms",
    "request_body_json",
    "workout_id", "workout_name", "workout_type", "workout_difficulty",
    "workout_notes", "n_exercises", "exercise_names_pipe",
    "n_exercises_with_library_id",  # RAG-first specific
    "n_exercises_with_video_url",   # RAG-first specific
    "n_exercises_with_image_s3",    # RAG-first specific
    "per_exercise_sets", "per_exercise_reps", "per_exercise_weight_kg",
    "per_exercise_rest_seconds", "per_exercise_muscle_group",
    "duration_minutes", "total_volume_kg", "error_message",
]


async def call_generate(
    client: httpx.AsyncClient,
    jwt: str,
    body: Dict[str, Any],
    max_retries: int = 2,
    backoff_s: float = 65.0,
) -> Dict[str, Any]:
    """POST /generate, retry on 429/5xx with backoff."""
    for attempt in range(max_retries + 1):
        t0 = time.time()
        try:
            r = await client.post(
                f"{RENDER}/api/v1/workouts/generate",
                json=body,
                headers={"Authorization": f"Bearer {jwt}"},
                timeout=120.0,
            )
            latency_ms = int((time.time() - t0) * 1000)
            try:
                payload = r.json()
            except Exception:
                payload = {"_raw_text": r.text[:500]}
            err = None
            if r.status_code != 200:
                err = f"HTTP {r.status_code}: {str(payload)[:300]}"
            elif isinstance(payload, dict) and "error" in payload:
                err = f"body_error: {payload.get('error')}"
            # Retry on transient failures
            if r.status_code in (429, 502, 503, 504) and attempt < max_retries:
                print(f"  [retry] {r.status_code} — sleeping {backoff_s}s "
                      f"(attempt {attempt + 1}/{max_retries})", flush=True)
                await asyncio.sleep(backoff_s)
                continue
            return {
                "status": r.status_code,
                "latency_ms": latency_ms,
                "body": payload,
                "request_body": body,
                "error": err,
            }
        except httpx.TimeoutException as e:
            if attempt < max_retries:
                print(f"  [retry] Timeout — sleeping {backoff_s}s", flush=True)
                await asyncio.sleep(backoff_s)
                continue
            return {
                "status": -1,
                "latency_ms": int((time.time() - t0) * 1000),
                "body": {"_error": str(e)},
                "request_body": body,
                "error": f"timeout: {e}",
            }
        except Exception as e:
            return {
                "status": -1,
                "latency_ms": int((time.time() - t0) * 1000),
                "body": {"_error": str(e)},
                "request_body": body,
                "error": f"{type(e).__name__}: {e}",
            }
    return {"status": -1, "latency_ms": 0, "body": {}, "request_body": body,
            "error": "unknown"}


def extract_summary(result: Dict[str, Any]) -> Dict[str, Any]:
    """Pull workout fields + RAG-specific provenance counts."""
    body = result.get("body") or {}
    if not isinstance(body, dict):
        body = {}
    workout = body  # /generate returns the Workout directly (not wrapped)

    # Exercises: try exercises_json (string or list) or exercises (list)
    raw = workout.get("exercises_json") or workout.get("exercises") or []
    if isinstance(raw, str):
        try:
            exs = json.loads(raw)
        except Exception:
            exs = []
    else:
        exs = raw if isinstance(raw, list) else []

    names = [(e.get("name") or e.get("exercise_name") or "") for e in exs]
    sets = [str(e.get("sets") or "") for e in exs]
    reps = [str(e.get("reps") or "") for e in exs]
    weights = [str(e.get("weight_kg") or e.get("weight") or "") for e in exs]
    rests = [str(e.get("rest_seconds") or "") for e in exs]
    muscles: List[str] = []
    for e in exs:
        m = e.get("muscle_group") or e.get("target_muscle") or ""
        if isinstance(m, list):
            m = ",".join(m)
        muscles.append(str(m))

    # RAG-first provenance counts (the whole point of testing this endpoint)
    n_with_id = sum(1 for e in exs if e.get("exercise_id"))
    n_with_video = sum(1 for e in exs if e.get("video_url"))
    n_with_image = sum(1 for e in exs
                       if e.get("image_s3_path") or e.get("image_url"))

    total_vol = 0.0
    for e in exs:
        try:
            si = int(e.get("sets") or 0)
            ri = int(e.get("reps") or 0) if str(e.get("reps") or "").isdigit() else 10
            wf = float(e.get("weight_kg") or e.get("weight") or 0)
            total_vol += si * ri * wf
        except Exception:
            pass

    return {
        "workout_id": workout.get("id", ""),
        "workout_name": workout.get("name", ""),
        "workout_type": workout.get("type", ""),
        "workout_difficulty": workout.get("difficulty", ""),
        "workout_notes": (workout.get("notes") or workout.get("description") or "")[:500],
        "n_exercises": len(exs),
        "exercise_names_pipe": "|".join(names),
        "n_exercises_with_library_id": n_with_id,
        "n_exercises_with_video_url": n_with_video,
        "n_exercises_with_image_s3": n_with_image,
        "per_exercise_sets": "|".join(sets),
        "per_exercise_reps": "|".join(reps),
        "per_exercise_weight_kg": "|".join(weights),
        "per_exercise_rest_seconds": "|".join(rests),
        "per_exercise_muscle_group": "|".join(muscles),
        "duration_minutes": workout.get("duration_minutes", ""),
        "total_volume_kg": f"{total_vol:.1f}",
    }


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=500)
    parser.add_argument("--pacing", type=float, default=5.0,
                        help="Seconds between calls (15/min limit allows 4s)")
    parser.add_argument("--resume", default=None,
                        help="Path to existing run dir OR 'auto'.")
    args = parser.parse_args()

    print("[harness] auth...", flush=True)
    jwt = get_jwt()
    print("[harness] JWT ok", flush=True)

    scenarios = build_500_for_generate()[: args.n]
    print(f"[harness] {len(scenarios)} scenarios queued", flush=True)

    out_dir, completed_idx, md_entries = resume_or_init_outputs(
        "render_generate_full", CSV_COLS, args.resume,
    )
    started = _dt.now().isoformat(timespec="seconds")
    url = f"{RENDER}/api/v1/workouts/generate"

    async with httpx.AsyncClient() as client:
        for sc in scenarios:
            if sc["idx"] in completed_idx:
                print(f"[{sc['idx']}/{len(scenarios)}] SKIP (already done)",
                      flush=True)
                continue

            res = await call_generate(client, jwt, sc["body"])
            ws = extract_summary(res)
            row = {
                "idx": sc["idx"], "scenario_block": sc["block"],
                "label": sc["label"],
                "http_status": res["status"], "latency_ms": res["latency_ms"],
                "request_body_json": json.dumps(sc["body"], default=str),
                "error_message": res.get("error") or "",
                **ws,
            }
            full = {"scenario": sc, "result": res, "csv_row": row, "idx": sc["idx"]}
            write_row(out_dir, row, CSV_COLS, full)

            valid = (
                row["http_status"] == 200
                and ws["n_exercises"] > 0
                and not row["error_message"]
            )
            md_entries.append({
                "idx": sc["idx"], "label": sc["label"],
                "name": ws["workout_name"], "n_exercises": ws["n_exercises"],
                "latency_ms": row["latency_ms"],
                "error": row["error_message"], "valid": valid,
            })
            update_md_live_status(_MD_PATH, md_entries, started)

            # RAG-first specific log: did we get library-backed exercises?
            rag_quality = (
                f"lib_id={ws['n_exercises_with_library_id']}/{ws['n_exercises']} "
                f"video={ws['n_exercises_with_video_url']}/{ws['n_exercises']} "
                f"img={ws['n_exercises_with_image_s3']}/{ws['n_exercises']}"
            )
            print(
                f"[{sc['idx']}/{len(scenarios)}] block={sc['block']} "
                f"status={row['http_status']} "
                f"latency={row['latency_ms']}ms "
                f'name="{ws["workout_name"]}" '
                f"n_ex={ws['n_exercises']} "
                f"valid={'✅' if valid else '❌'} "
                f"RAG[{rag_quality}] "
                f"err={row['error_message'] or 'OK'} | {sc['label']}",
                flush=True,
            )
            await asyncio.sleep(args.pacing)

    print("[harness] consolidating jsons → csv...", flush=True)
    consolidate_and_cleanup(out_dir, CSV_COLS)
    print(f"[harness] DONE → {out_dir}", flush=True)


if __name__ == "__main__":
    asyncio.run(main())
