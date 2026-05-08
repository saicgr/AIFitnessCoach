"""Render-deployment workout-generation validation harness.

Companion to `validate_workout_generation.py` (which calls Gemini in-process).
This one hits the LIVE Render endpoint so the FULL production code path is
exercised — gym profile resolution, RAG, performance history, safety
validate-and-repair, swap rounds, persistence, and the rate limiter.

Endpoint:
    POST {base_url}/api/v1/workouts/generate

Auth (in order):
    1. If $QA_JWT (override with --token-env) is set, use it.
    2. Otherwise mint a JWT via Supabase service-role admin API
       (scripts/_render_auth.py) — creates a synthetic auth.users row,
       links public.users.auth_id to it, signs in with password, returns
       the access_token. Idempotent.

Usage:
    cd backend && .venv/bin/python scripts/validate_workout_generation_render.py \\
        --n 100 --user-id 00000000-0000-0000-0000-0000000000aa

Pacing:
    The endpoint is rate-limited at 15/minute per user. We sleep 4.5s between
    calls (~13.3/min effective).

Artifacts (mirrors the local harness):
    backend/scripts/output/validate_workouts_render_<ts>/
        workouts.csv             — incremental
        workouts.md              — incremental
        workouts.summary.md      — final
        json/workout_NNN.json    — per-call dump

Notes vs the local harness:
- `prompt_text` is NOT capturable from the client side (the rendered Gemini
  prompt is logged on the server). We populate it with the JSON HTTP body we
  sent, so the CSV column is still useful.
- `intensity` from the sweep matrix has no direct field on
  `GenerateWorkoutRequest`. We pipe it into `workout_type` (the closest
  semantic match the schema accepts) so it influences generation; otherwise
  it's purely a sweep-coverage label.
- `scheduled_date` is offset by `idx` days into the future to avoid dedup
  collisions, and `force_non_preferred_day=True` bypasses the preferred-day
  gate so every sweep row actually generates.
- NO mock data, NO silent fallbacks. HTTP errors are captured into
  `result.error` and the sweep continues.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import logging
import os
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List

# backend/ on path so `scripts.*` and `models.*` resolve.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import httpx  # noqa: E402

from scripts._validation_helpers import (  # noqa: E402
    EQUIPMENT_SETS, GenerationResult, append_csv, append_json,
    append_markdown, build_sweep_matrix, compute_volume_and_duration,
    init_csv, init_markdown, write_summary,
)
from scripts._render_auth import obtain_jwt  # noqa: E402
from scripts.seed_qa_user import QA_USER_UUID  # noqa: E402

_log = logging.getLogger("validate_workout_generation_render")
logging.basicConfig(
    level=logging.WARNING,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
for _name in ("httpx", "httpcore", "supabase", "urllib3"):
    logging.getLogger(_name).setLevel(logging.WARNING)
_log.setLevel(logging.INFO)
logging.getLogger("_render_auth").setLevel(logging.INFO)

DEFAULT_BASE_URL = "https://aifitnesscoach-zqi3.onrender.com"
GENERATE_PATH = "/api/v1/workouts/generate"
PACE_SECONDS = 4.5  # 15/min limiter — stay safely under
HTTP_TIMEOUT = 180.0  # generation can take up to ~120s on Render


def _build_body(p: Dict[str, Any], user_id: str, idx: int) -> Dict[str, Any]:
    """Map a sweep param dict into a GenerateWorkoutRequest body.

    Edge-case mapping notes:
    - `intensity` (easy/medium/hard) — schema has no field for it; we route
      it into `workout_type` since downstream prompt logic does inspect that
      string. Sweep coverage label is preserved in the CSV regardless.
    - `comeback_offset_days` — server resolves comeback context from user's
      activity history, which our QA user has none of. We can't simulate it
      via the public API; the column will be set in CSV but won't influence
      the response. This is a known gap vs the in-process harness.
    - `scheduled_date` offset by `idx` days so each sweep row targets a
      unique future date — defeats dedup-by-(user, date).
    """
    eq_set_key = p["equipment_set"]
    equipment = EQUIPMENT_SETS[eq_set_key]
    duration = p["duration_minutes"]

    # Workout type carries the intensity hint (closest semantic field).
    intensity = p["intensity"]
    workout_type = f"{intensity}_{p['goal']}"

    # Future date offset — start +2 days so we never collide with TODAY.
    scheduled_date = (
        datetime.utcnow().date() + timedelta(days=2 + idx)
    ).strftime("%Y-%m-%d")

    body: Dict[str, Any] = {
        "user_id": user_id,
        "workout_type": workout_type,
        "duration_minutes": duration,
        "fitness_level": p["fitness_level"],
        "goals": [p["goal"]],
        "equipment": list(equipment) if equipment else [],
        "focus_areas": [p["focus"]],
        "scheduled_date": scheduled_date,
        "force_non_preferred_day": True,
        "skip_comeback": False,
    }
    return body


def _result_from_response(
    idx: int, params: Dict[str, Any], body: Dict[str, Any], data: Dict[str, Any]
) -> GenerationResult:
    """Convert a Workout JSON response into the shared GenerationResult."""
    r = GenerationResult(idx=idx, params=params, generation_path="render_api")
    r.exercises = data.get("exercises") or []
    r.ai_workout_name = data.get("name") or ""
    r.ai_workout_type = data.get("type") or data.get("workout_type") or ""
    r.ai_difficulty = data.get("difficulty") or ""
    r.ai_notes = data.get("notes") or ""
    vol, dur = compute_volume_and_duration(r.exercises)
    r.total_volume_kg = vol
    r.est_duration_min = dur
    # Render path: we can't read the rendered Gemini prompt, but stuff the
    # request body in `prompt_text` so the CSV column has something useful.
    r.prompt_text = json.dumps(body, indent=2)
    # Safety violations are already enforced server-side; we don't re-run
    # validate_and_repair here — count is unknown from the client.
    r.n_safety_violations = 0
    r.safety_log_lines = []
    return r


async def _gen_render(
    client: httpx.AsyncClient, base_url: str, headers: Dict[str, str],
    params: Dict[str, Any], user_id: str,
) -> GenerationResult:
    idx = params["__idx"]
    body = _build_body(params, user_id, idx)
    url = base_url.rstrip("/") + GENERATE_PATH
    try:
        resp = await client.post(url, json=body, headers=headers,
                                 timeout=HTTP_TIMEOUT)
    except httpx.RequestError as e:
        r = GenerationResult(idx=idx, params=params, generation_path="render_api")
        r.prompt_text = json.dumps(body, indent=2)
        r.error = f"http_request_error: {type(e).__name__}: {e}"
        return r

    if resp.status_code >= 400:
        # Capture body (truncated) so we can diagnose without re-running.
        snippet = resp.text[:1500].replace("\n", " ")
        r = GenerationResult(idx=idx, params=params, generation_path="render_api")
        r.prompt_text = json.dumps(body, indent=2)
        r.error = f"http_{resp.status_code}: {snippet}"
        return r

    try:
        data = resp.json()
    except Exception as e:
        r = GenerationResult(idx=idx, params=params, generation_path="render_api")
        r.prompt_text = json.dumps(body, indent=2)
        r.error = f"json_decode_error: {e}; body={resp.text[:500]}"
        return r

    return _result_from_response(idx, params, body, data)


async def run(args: argparse.Namespace) -> None:
    # Resolve auth.
    try:
        jwt, source = obtain_jwt(token_env=args.token_env)
    except Exception as e:
        print(
            f"\n[harness] ERROR obtaining JWT: {e}\n\n"
            f"To proceed, either:\n"
            f"  (a) Set ${args.token_env} to a valid Supabase access token, OR\n"
            f"  (b) Ensure backend/.env has SUPABASE_URL + SUPABASE_KEY "
            f"(service role) so the harness can mint one.\n"
        )
        sys.exit(2)
    print(f"[harness] auth source: {source}, jwt prefix: {jwt[:18]}...")

    matrix = build_sweep_matrix(n=args.n)
    for i, p in enumerate(matrix, 1):
        p["__idx"] = i

    out_root = Path(args.out)
    out_root.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out_dir = out_root / f"validate_workouts_render_{ts}"
    out_dir.mkdir(parents=True, exist_ok=True)
    print(f"[harness] Output → {out_dir}")
    print(f"[harness] Base URL → {args.base_url}")
    print(f"[harness] Pacing → {PACE_SECONDS}s between calls "
          f"(~{60 / PACE_SECONDS:.1f}/min)")

    csv_path = init_csv(out_dir)
    md_path = init_markdown(out_dir)

    headers = {
        "Authorization": f"Bearer {jwt}",
        "Content-Type": "application/json",
        "User-Agent": "zealova-validation-harness/1.0",
    }

    results: List[GenerationResult] = []
    async with httpx.AsyncClient() as client:
        for p in matrix:
            t0 = time.time()
            r = await _gen_render(client, args.base_url, headers, p, args.user_id)
            results.append(r)
            append_csv(csv_path, r)
            append_markdown(md_path, r)
            append_json(out_dir, r)
            elapsed = time.time() - t0
            err = f" ERROR={r.error[:120]}" if r.error else ""
            print(
                f"[{r.idx}/{len(matrix)}] {p['intensity']}/{p['fitness_level']}"
                f"/{p['duration_minutes']}min/{p['goal']}/{p['equipment_set']}"
                f"/{p['focus']} → {len(r.exercises)} ex, "
                f"name='{r.ai_workout_name}' ({elapsed:.1f}s){err}"
            )
            await asyncio.sleep(PACE_SECONDS)

    summary = write_summary(out_dir, results)
    print("\n--- Wrote artifacts ---")
    print(f"  {md_path}")
    print(f"  {csv_path}")
    print(f"  {summary}")
    print(f"  {out_dir / 'json'}/")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--n", type=int, default=100)
    parser.add_argument("--user-id", default=QA_USER_UUID)
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL)
    parser.add_argument("--out", default="scripts/output/")
    parser.add_argument("--token-env", default="QA_JWT",
                        help="Env var holding a JWT to use instead of minting.")
    args = parser.parse_args()
    t0 = time.time()
    asyncio.run(run(args))
    print(f"\n[harness] Done in {time.time() - t0:.1f}s")


if __name__ == "__main__":
    main()
