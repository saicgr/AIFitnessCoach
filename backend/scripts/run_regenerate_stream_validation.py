"""Regenerate-stream 150-scenario validation harness.

Endpoint  : POST https://aifitnesscoach-zqi3.onrender.com/api/v1/workouts/regenerate-stream
Scenarios : backend/scripts/scenarios/regenerate_stream_scenarios.md
Test user : 14c61bb0-3047-45b8-be8d-28246b587fb1 (hatlesscowboy90@gmail.com)

Auth (in order):
  1. Use $QA_JWT env var if set.
  2. Otherwise mint via Supabase service-role admin API (sign-in with password).
     The hatlesscowboy90 user must already exist in auth.users with a known
     password. If it doesn't, the harness will surface clear instructions.

Pre-step:
  - Query Supabase for user's is_current=true workouts.
  - If fewer than 20, call /generate-stream to seed up to 20, on Thu/Sat/Sun
    dates over the next 7 weeks.
  - Persist S1..S20 workout IDs for use in scenario bodies.

Pacing : 13 s between calls (~4.6/min), safely under 5/minute rate limit.

Output dir : backend/scripts/output/render_regenerate_stream_<YYYYMMDD_HHMMSS>/
CSV columns: idx, scenario_block, source_workout_id, source_workout_name,
             http_status, latency_ms, request_body_json, preview_id,
             ai_workout_name, ai_workout_type, ai_difficulty, ai_notes,
             n_exercises, exercise_names_pipe, per_exercise_sets,
             per_exercise_reps, per_exercise_weight_kg,
             per_exercise_rest_seconds, per_exercise_muscle_group,
             est_duration_min, total_volume_kg, error_message,
             sse_event_count, final_response_json

Usage:
    cd backend && .venv/bin/python scripts/run_regenerate_stream_validation.py
    cd backend && .venv/bin/python scripts/run_regenerate_stream_validation.py --n 5
    cd backend && .venv/bin/python scripts/run_regenerate_stream_validation.py --n 150
"""
from __future__ import annotations

import argparse
import asyncio
import csv
import json
import logging
import os
import sys
import time
from datetime import date, datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional, Tuple
import uuid as _uuid_module

# backend/ on path so scripts.* and models.* resolve.
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

try:
    from dotenv import load_dotenv
    load_dotenv(Path(__file__).resolve().parent.parent / ".env")
except ImportError:
    pass

import httpx  # noqa: E402

_log = logging.getLogger("run_regenerate_stream_validation")
logging.basicConfig(
    level=logging.WARNING,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
_log.setLevel(logging.INFO)
for _n in ("httpx", "httpcore", "supabase", "urllib3"):
    logging.getLogger(_n).setLevel(logging.WARNING)

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

BASE_URL = "https://aifitnesscoach-zqi3.onrender.com"
REGEN_STREAM_PATH = "/api/v1/workouts/regenerate-stream"
GENERATE_STREAM_PATH = "/api/v1/workouts/generate-stream"

TEST_USER_ID = "14c61bb0-3047-45b8-be8d-28246b587fb1"
TEST_GYM_PROFILE_ID = "3ed17504-113a-4be4-88d0-67b4c70ca57c"
TEST_USER_EMAIL = "hatlesscowboy90@gmail.com"
# Used ONLY if we need to mint a JWT — caller must set env QA_JWT or this password.
TEST_USER_PASSWORD_ENV = "HATLESSCOWBOY_PASSWORD"

PACE_SECONDS = 13.0       # 4.6/min — safely under 5/min rate limit
HTTP_TIMEOUT = 180.0      # regeneration can take up to ~120 s on Render

# Preferred days for seeding: Thu=3, Sat=5, Sun=6
PREFERRED_WEEKDAYS = {3, 5, 6}

# Equipment sets matching the scenarios MD
EQUIPMENT_SETS: Dict[str, List[str]] = {
    "E1_full": [
        "barbell", "dumbbells", "cable_machine", "squat_rack", "bench",
        "pull_up_bar", "kettlebell", "leg_press_machine", "lat_pulldown",
        "smith_machine", "ez_bar", "preacher_curl", "dip_station",
        "cable_crossover", "hack_squat", "seated_calf_raise",
        "standing_calf_raise", "glute_ham_raise", "hyperextension_bench",
        "leg_extension", "leg_curl", "seated_row", "chest_fly_machine",
        "incline_bench", "decline_bench", "flat_bench", "adjustable_bench",
        "power_rack", "trap_bar", "landmine", "resistance_bands",
        "foam_roller", "yoga_mat", "pull_up_assist_band",
        "ab_roller", "battle_ropes", "medicine_ball", "slam_ball",
        "plyo_box", "jump_rope", "sandbag", "treadmill",
        "rowing_machine", "stationary_bike", "elliptical", "stair_climber",
        "assault_bike", "ski_erg", "versa_climber",
        "trx", "suspension_trainer", "gymnastics_rings",
        "dumbbell_rack", "weight_plates", "weight_belt",
        "wrist_straps", "lifting_belt", "knee_sleeves",
        "chalk", "hand_grips", "parallettes",
        "agility_ladder", "cones", "speed_ladder",
        "bosu_ball", "stability_ball", "balance_board",
        "cable_attachment_rope", "cable_attachment_bar",
        "cable_attachment_ankle", "cable_attachment_v_bar",
        "dip_belt", "pull_up_bar_doorframe", "arm_blaster",
        "ab_bench", "roman_chair", "back_extension_bench",
        "glute_bridge_machine", "hip_thrust_pad",
        "ankle_weights", "wrist_weights",
    ],
    "E2_bw": [],
    "E3_db": ["dumbbells", "bench", "resistance_bands"],
    "E4_kb": ["kettlebell"],
    "E5_mach": ["cable_machine", "leg_press_machine", "lat_pulldown", "smith_machine"],
    "E6_bands": ["resistance_bands"],
    "E7_no_bb": [
        "dumbbells", "cable_machine", "bench", "pull_up_bar", "kettlebell",
        "leg_press_machine", "lat_pulldown", "resistance_bands",
        "dip_station", "leg_extension", "leg_curl", "seated_row",
        "chest_fly_machine",
    ],
    "E8_fw": ["barbell", "dumbbells", "kettlebell", "bench", "pull_up_bar"],
    "E9_db1": ["dumbbells"],
    "E10_home": ["dumbbells", "resistance_bands", "pull_up_bar"],
    "E11_cardio": ["treadmill", "rowing_machine", "stationary_bike", "elliptical"],
    "E12_bw_bands": ["resistance_bands"],
}

CSV_COLUMNS = [
    "idx", "scenario_block", "source_workout_id", "source_workout_name",
    "http_status", "latency_ms", "request_body_json", "preview_id",
    "ai_workout_name", "ai_workout_type", "ai_difficulty", "ai_notes",
    "n_exercises", "exercise_names_pipe", "per_exercise_sets",
    "per_exercise_reps", "per_exercise_weight_kg", "per_exercise_rest_seconds",
    "per_exercise_muscle_group", "est_duration_min", "total_volume_kg",
    "error_message", "sse_event_count", "final_response_json",
]


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

def obtain_jwt() -> Tuple[str, str]:
    """Return (jwt, source). Source is 'env' or 'minted'."""
    env_token = os.getenv("QA_JWT", "").strip()
    if env_token:
        _log.info("[auth] Using JWT from $QA_JWT")
        return env_token, "env"

    _log.info("[auth] $QA_JWT not set — attempting to mint via Supabase service-role")
    return _mint_jwt_for_hatlesscowboy()


def _mint_jwt_for_hatlesscowboy() -> Tuple[str, str]:
    """Mint a JWT for hatlesscowboy90@gmail.com using the service-role client.

    Strategy:
      1. Try sign_in_with_password using $HATLESSCOWBOY_PASSWORD if set.
      2. Otherwise check if the user exists in auth.users and try a password
         reset (admin set_user_password) then sign in.
      3. If still failing, raise with clear instructions.
    """
    from supabase import create_client

    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    if not url or not key:
        raise RuntimeError(
            "SUPABASE_URL / SUPABASE_KEY not set in backend/.env. "
            "Cannot mint JWT."
        )

    admin = create_client(url, key)

    # Try with known password from env first
    password = os.getenv(TEST_USER_PASSWORD_ENV, "").strip()

    if password:
        _log.info(f"[auth] Trying sign_in_with_password for {TEST_USER_EMAIL}")
        try:
            session = admin.auth.sign_in_with_password({
                "email": TEST_USER_EMAIL,
                "password": password,
            })
            token = session.session.access_token
            _log.info("[auth] JWT minted via sign_in_with_password (minted)")
            return token, "minted"
        except Exception as e:
            _log.warning(f"[auth] sign_in_with_password failed: {e}")

    # Try finding the auth.users row and resetting the password
    try:
        users = admin.auth.admin.list_users()
        auth_user_id = None
        for u in users:
            if (getattr(u, "email", None) or "").lower() == TEST_USER_EMAIL.lower():
                auth_user_id = str(u.id)
                break

        if auth_user_id:
            _log.info(f"[auth] Found auth.users row {auth_user_id} — setting temp password")
            temp_password = f"QaRegen!{int(time.time())}"
            admin.auth.admin.update_user_by_id(auth_user_id, {"password": temp_password})
            session = admin.auth.sign_in_with_password({
                "email": TEST_USER_EMAIL,
                "password": temp_password,
            })
            token = session.session.access_token
            _log.info("[auth] JWT minted via admin password reset + sign_in (minted)")
            return token, "minted"
    except Exception as e:
        _log.error(f"[auth] Admin JWT mint failed: {e}")

    raise RuntimeError(
        f"Cannot obtain a JWT for {TEST_USER_EMAIL}.\n"
        f"Fastest fix: set QA_JWT env var to a valid Supabase session token "
        f"for {TEST_USER_EMAIL}. You can get one from the app's debug menu "
        f"or by calling Supabase Auth sign_in_with_password manually.\n"
        f"Alternatively, set {TEST_USER_PASSWORD_ENV}=<password> in backend/.env."
    )


# ---------------------------------------------------------------------------
# Pre-step: seed source workouts
# ---------------------------------------------------------------------------

def _get_existing_workouts(supabase_client) -> List[Dict[str, Any]]:
    """Fetch user's current workouts from Supabase (service-role, bypasses RLS)."""
    res = (
        supabase_client.table("workouts")
        .select("id, scheduled_date, name, status, is_current")
        .eq("user_id", TEST_USER_ID)
        .eq("is_current", True)
        .not_.in_("status", ["cancelled"])
        .order("scheduled_date")
        .limit(50)
        .execute()
    )
    return res.data or []


def _next_preferred_dates(n: int) -> List[date]:
    """Generate the next n dates that fall on Thu/Sat/Sun."""
    result: List[date] = []
    d = date.today() + timedelta(days=1)
    while len(result) < n:
        if d.weekday() in PREFERRED_WEEKDAYS:
            result.append(d)
        d += timedelta(days=1)
    return result


async def _call_generate_stream(
    client: httpx.AsyncClient,
    headers: Dict[str, str],
    scheduled_date: date,
) -> Optional[str]:
    """Call /generate-stream for one date. Returns workout_id or None."""
    body = {
        "user_id": TEST_USER_ID,
        "gym_profile_id": TEST_GYM_PROFILE_ID,
        "scheduled_date": scheduled_date.isoformat(),
        "force_non_preferred_day": False,
        "fitness_level": "intermediate",
        "difficulty": "medium",
        "duration_minutes": 45,
        "equipment": EQUIPMENT_SETS["E1_full"],
    }
    try:
        workout_id = None
        event_count = 0
        async with client.stream(
            "POST",
            BASE_URL + GENERATE_STREAM_PATH,
            json=body,
            headers=headers,
            timeout=HTTP_TIMEOUT,
        ) as resp:
            if resp.status_code != 200:
                content = await resp.aread()
                _log.warning(
                    f"[pre-step] generate-stream HTTP {resp.status_code} "
                    f"for {scheduled_date}: {content[:200]}"
                )
                return None
            async for line in resp.aiter_lines():
                if not line:
                    continue
                if line.startswith("data:"):
                    event_count += 1
                    raw = line[5:].strip()
                    try:
                        payload = json.loads(raw)
                        # Capture workout_id from final done event
                        if payload.get("type") == "complete" or payload.get("workout_id"):
                            workout_id = payload.get("workout_id") or payload.get("id")
                        if "workout" in payload:
                            w = payload["workout"]
                            if isinstance(w, dict):
                                workout_id = w.get("id") or w.get("workout_id") or workout_id
                        # done event on generate-stream
                        if payload.get("type") == "done" or payload.get("status") == "done":
                            workout_id = (
                                payload.get("workout_id")
                                or payload.get("id")
                                or workout_id
                            )
                    except (json.JSONDecodeError, ValueError):
                        pass
        _log.info(
            f"[pre-step] generate-stream {scheduled_date} -> "
            f"workout_id={workout_id} events={event_count}"
        )
        return workout_id
    except Exception as e:
        _log.warning(f"[pre-step] generate-stream exception {scheduled_date}: {e}")
        return None


async def ensure_source_workouts(
    client: httpx.AsyncClient, headers: Dict[str, str]
) -> List[Dict[str, Any]]:
    """Ensure >=20 source workouts exist. Returns list of workout dicts (up to 20)."""
    from supabase import create_client

    url = os.getenv("SUPABASE_URL")
    key = os.getenv("SUPABASE_KEY")
    sb = create_client(url, key)

    existing = _get_existing_workouts(sb)
    _log.info(f"[pre-step] Found {len(existing)} existing is_current workouts")

    if len(existing) >= 20:
        return existing[:20]

    needed = 20 - len(existing)
    _log.info(f"[pre-step] Seeding {needed} more workouts via /generate-stream")

    # Get future preferred-day dates that are not already seeded
    existing_dates = {w["scheduled_date"] for w in existing}
    candidates = _next_preferred_dates(needed + 10)
    dates_to_seed = [d for d in candidates if d.isoformat() not in existing_dates][:needed]

    seeded = 0
    for d in dates_to_seed:
        _log.info(f"[pre-step] Seeding {d} ({seeded+1}/{needed})")
        wid = await _call_generate_stream(client, headers, d)
        if wid:
            # Fetch the full workout row for name
            res = sb.table("workouts").select("id, scheduled_date, name").eq("id", wid).execute()
            if res.data:
                existing.append(res.data[0])
            else:
                existing.append({"id": wid, "scheduled_date": d.isoformat(), "name": "Generated Workout"})
            seeded += 1
        await asyncio.sleep(13.0)  # pace between seeds too

    # Re-query to get fresh list in date order
    fresh = _get_existing_workouts(sb)
    if not fresh:
        # Fallback to what we built locally
        fresh = existing
    _log.info(f"[pre-step] Final source workout count: {len(fresh)}")
    return fresh[:20]


# ---------------------------------------------------------------------------
# SSE parsing
# ---------------------------------------------------------------------------

def parse_sse_stream(raw_text: str) -> Tuple[Dict[str, Any], int, Optional[str]]:
    """Parse raw SSE bytes into (final_payload, event_count, error_message).

    Event types: progress, safety_check, safety_done, error, done.
    Final payload is from the 'done' event.
    """
    final_payload: Dict[str, Any] = {}
    event_count = 0
    error_message: Optional[str] = None

    current_event_type: Optional[str] = None
    current_data_lines: List[str] = []

    def flush_event():
        nonlocal current_event_type, current_data_lines, final_payload, error_message, event_count
        if not current_data_lines:
            current_event_type = None
            current_data_lines = []
            return

        data_str = "\n".join(current_data_lines).strip()
        if not data_str:
            current_event_type = None
            current_data_lines = []
            return

        event_count += 1
        try:
            payload = json.loads(data_str)
        except (json.JSONDecodeError, ValueError):
            current_event_type = None
            current_data_lines = []
            return

        ev = current_event_type or payload.get("type", "")

        if ev == "error" or payload.get("type") == "error":
            error_message = payload.get("error") or payload.get("detail") or str(payload)
        elif ev == "done" or payload.get("preview_id"):
            final_payload = payload
        # progress, safety_check, safety_done — just count them

        current_event_type = None
        current_data_lines = []

    for line in raw_text.splitlines():
        if line.startswith("event:"):
            # If we have accumulated data for a prior event, flush first
            if current_data_lines:
                flush_event()
            current_event_type = line[len("event:"):].strip()
        elif line.startswith("data:"):
            current_data_lines.append(line[len("data:"):].strip())
        elif line == "" and current_data_lines:
            flush_event()

    # Final flush if stream ended without blank line
    if current_data_lines:
        flush_event()

    return final_payload, event_count, error_message


# ---------------------------------------------------------------------------
# Extract workout fields from final SSE payload
# ---------------------------------------------------------------------------

def _pipe(lst: List[Any]) -> str:
    return "|".join(str(x) for x in lst)


def extract_workout_fields(
    final_payload: Dict[str, Any],
) -> Dict[str, Any]:
    """Extract CSV-relevant fields from the 'done' SSE payload."""
    result: Dict[str, Any] = {
        "preview_id": "",
        "ai_workout_name": "",
        "ai_workout_type": "",
        "ai_difficulty": "",
        "ai_notes": "",
        "n_exercises": 0,
        "exercise_names_pipe": "",
        "per_exercise_sets": "",
        "per_exercise_reps": "",
        "per_exercise_weight_kg": "",
        "per_exercise_rest_seconds": "",
        "per_exercise_muscle_group": "",
        "est_duration_min": "",
        "total_volume_kg": 0.0,
    }

    if not final_payload:
        return result

    result["preview_id"] = str(final_payload.get("preview_id") or "")

    workout = final_payload.get("workout") or final_payload
    if isinstance(workout, dict):
        result["ai_workout_name"] = str(workout.get("name") or "")
        result["ai_workout_type"] = str(workout.get("type") or "")
        result["ai_difficulty"] = str(workout.get("difficulty") or "")
        result["ai_notes"] = str(workout.get("notes") or workout.get("ai_notes") or "")
        result["est_duration_min"] = str(workout.get("duration_minutes") or "")

        exercises = workout.get("exercises_json") or workout.get("exercises") or []
        if isinstance(exercises, str):
            try:
                exercises = json.loads(exercises)
            except (json.JSONDecodeError, ValueError):
                exercises = []

        if isinstance(exercises, list):
            result["n_exercises"] = len(exercises)
            names, sets_list, reps_list, weights, rests, muscles = [], [], [], [], [], []
            total_vol = 0.0
            for ex in exercises:
                if not isinstance(ex, dict):
                    continue
                name = ex.get("name") or ex.get("exercise_name") or ""
                names.append(name)

                s = ex.get("sets") or ex.get("num_sets") or 0
                r = ex.get("reps") or ex.get("num_reps") or 0
                w = ex.get("weight_kg") or ex.get("weight") or 0.0
                rest = ex.get("rest_seconds") or ex.get("rest") or 0
                muscle = ex.get("muscle_group") or ex.get("target_muscle") or ""
                if isinstance(muscle, list):
                    muscle = ",".join(muscle)

                sets_list.append(str(s))
                reps_list.append(str(r))
                weights.append(str(w))
                rests.append(str(rest))
                muscles.append(str(muscle))

                try:
                    total_vol += float(s) * float(r) * float(w)
                except (TypeError, ValueError):
                    pass

            result["exercise_names_pipe"] = _pipe(names)
            result["per_exercise_sets"] = _pipe(sets_list)
            result["per_exercise_reps"] = _pipe(reps_list)
            result["per_exercise_weight_kg"] = _pipe(weights)
            result["per_exercise_rest_seconds"] = _pipe(rests)
            result["per_exercise_muscle_group"] = _pipe(muscles)
            result["total_volume_kg"] = round(total_vol, 2)

    return result


# ---------------------------------------------------------------------------
# Single SSE call
# ---------------------------------------------------------------------------

async def call_regen_stream(
    client: httpx.AsyncClient,
    headers: Dict[str, str],
    body: Dict[str, Any],
    timeout: float = HTTP_TIMEOUT,
) -> Tuple[int, float, str, Dict[str, Any], int, Optional[str]]:
    """Make one /regenerate-stream call.

    Returns:
        (http_status, latency_ms, raw_sse_text, final_payload, event_count, error_message)
    """
    t0 = time.time()
    http_status = 0
    raw_text = ""

    try:
        async with client.stream(
            "POST",
            BASE_URL + REGEN_STREAM_PATH,
            json=body,
            headers=headers,
            timeout=timeout,
        ) as resp:
            http_status = resp.status_code
            chunks = []
            async for chunk in resp.aiter_text():
                chunks.append(chunk)
            raw_text = "".join(chunks)
    except httpx.TimeoutException:
        latency_ms = (time.time() - t0) * 1000
        return 0, latency_ms, "", {}, 0, "timeout"
    except Exception as e:
        latency_ms = (time.time() - t0) * 1000
        return 0, latency_ms, "", {}, 0, str(e)

    latency_ms = (time.time() - t0) * 1000

    if http_status != 200:
        # Try parsing as JSON error
        err_msg = f"http_{http_status}"
        try:
            err_data = json.loads(raw_text)
            err_msg = str(err_data.get("detail") or raw_text[:200])
        except (json.JSONDecodeError, ValueError):
            err_msg = raw_text[:200] or err_msg
        return http_status, latency_ms, raw_text, {}, 0, err_msg

    final_payload, event_count, error_message = parse_sse_stream(raw_text)
    return http_status, latency_ms, raw_text, final_payload, event_count, error_message


# ---------------------------------------------------------------------------
# CSV helpers
# ---------------------------------------------------------------------------

def init_csv(path: Path) -> None:
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS)
        writer.writeheader()


def append_csv(path: Path, row: Dict[str, Any]) -> None:
    with open(path, "a", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=CSV_COLUMNS, extrasaction="ignore")
        writer.writerow(row)


# ---------------------------------------------------------------------------
# Scenario builders
# ---------------------------------------------------------------------------

def _s(sources: List[Dict], idx_1based: int) -> Dict[str, Any]:
    """Return the source workout at 1-based S-index (cycles if index > len)."""
    if not sources:
        return {"id": "", "name": ""}
    i = (idx_1based - 1) % len(sources)
    return sources[i]


def _eq(code: str) -> List[str]:
    return EQUIPMENT_SETS.get(code, [])


def _today_iso() -> str:
    return date.today().isoformat()


def _next_weekday(weekday: int, offset_weeks: int = 0) -> str:
    """Return ISO date of the next occurrence of weekday (0=Mon, 6=Sun)."""
    today = date.today()
    days_ahead = (weekday - today.weekday()) % 7
    if days_ahead == 0:
        days_ahead = 7
    d = today + timedelta(days=days_ahead + offset_weeks * 7)
    return d.isoformat()


def _days_from_today(n: int) -> str:
    return (date.today() + timedelta(days=n)).isoformat()


def build_scenarios(sources: List[Dict]) -> List[Dict[str, Any]]:
    """Return list of dicts with keys: block, idx, source_key (S1..S20), body."""

    scenarios: List[Dict[str, Any]] = []

    def add(block: int, idx: int, source_key: int, body: Dict[str, Any]):
        src = _s(sources, source_key)
        full_body = {"workout_id": src["id"], "user_id": TEST_USER_ID, **body}
        scenarios.append({
            "block": block,
            "idx": idx,
            "source_workout_id": src["id"],
            "source_workout_name": src.get("name", ""),
            "body": full_body,
        })

    # ------------------------------------------------------------------
    # Block 1: Difficulty intent (calls 1–20)
    # ------------------------------------------------------------------
    b = 1
    add(b, 1,  1,  {"difficulty": "easy",   "duration_minutes": 30, "fitness_level": "beginner",     "equipment": _eq("E1_full"), "focus_areas": ["push"]})
    add(b, 2,  2,  {"difficulty": "easy",   "duration_minutes": 45, "fitness_level": "intermediate", "equipment": _eq("E3_db"),   "focus_areas": ["legs"]})
    add(b, 3,  3,  {"difficulty": "easy",   "duration_minutes": 60, "fitness_level": "advanced",     "equipment": _eq("E2_bw"),   "focus_areas": ["full_body"]})
    add(b, 4,  4,  {"difficulty": "medium", "duration_minutes": 30, "fitness_level": "intermediate", "equipment": _eq("E1_full"), "focus_areas": ["pull"]})
    add(b, 5,  5,  {"difficulty": "medium", "duration_minutes": 45, "fitness_level": "intermediate", "equipment": _eq("E5_mach"), "focus_areas": ["upper"]})
    add(b, 6,  6,  {"difficulty": "hard",   "duration_minutes": 30, "fitness_level": "intermediate", "equipment": _eq("E4_kb"),   "focus_areas": ["full_body"]})
    add(b, 7,  7,  {"difficulty": "hard",   "duration_minutes": 45, "fitness_level": "advanced",     "equipment": _eq("E1_full"), "focus_areas": ["legs"]})
    add(b, 8,  8,  {"difficulty": "hard",   "duration_minutes": 60, "fitness_level": "advanced",     "equipment": _eq("E8_fw"),   "focus_areas": ["full_body"]})
    add(b, 9,  9,  {"difficulty": "hell",   "duration_minutes": 30, "fitness_level": "advanced",     "equipment": _eq("E2_bw"),   "focus_areas": ["core"]})
    add(b, 10, 10, {"difficulty": "hell",   "duration_minutes": 45, "fitness_level": "advanced",     "equipment": _eq("E1_full"), "focus_areas": ["push"]})
    add(b, 11, 11, {"difficulty": "hell",   "duration_minutes": 60, "fitness_level": "advanced",     "equipment": _eq("E8_fw"),   "focus_areas": ["full_body"]})
    add(b, 12, 12, {"difficulty": "hell",   "duration_minutes": 90, "fitness_level": "advanced",     "equipment": _eq("E1_full"), "focus_areas": ["full_body"]})
    add(b, 13, 1,  {"difficulty": "easy",   "duration_minutes": 30, "fitness_level": "advanced",     "equipment": _eq("E1_full"), "focus_areas": ["mobility"]})
    add(b, 14, 2,  {"difficulty": "hell",   "duration_minutes": 30, "fitness_level": "beginner",     "equipment": _eq("E1_full"), "focus_areas": ["legs"]})
    add(b, 15, 3,  {"difficulty": "hard",   "duration_minutes": 90, "fitness_level": "beginner",     "equipment": _eq("E1_full"), "focus_areas": ["full_body"]})
    add(b, 16, 4,  {"difficulty": "easy",   "duration_minutes": 15, "fitness_level": "advanced",     "equipment": _eq("E11_cardio"), "focus_areas": ["cardio"]})
    add(b, 17, 5,  {"difficulty": "medium", "duration_minutes": 75, "fitness_level": "beginner",     "equipment": _eq("E10_home"), "focus_areas": ["upper"]})
    add(b, 18, 6,  {"difficulty": "hard",   "duration_minutes": 45, "fitness_level": "intermediate", "equipment": _eq("E7_no_bb"), "focus_areas": ["push"]})
    add(b, 19, 7,  {"difficulty": "medium", "duration_minutes": 45, "fitness_level": "intermediate", "equipment": _eq("E12_bw_bands"), "focus_areas": ["core"]})
    add(b, 20, 8,  {"difficulty": "hell",   "duration_minutes": 60, "fitness_level": "advanced",     "equipment": _eq("E5_mach"), "focus_areas": ["legs"]})

    # ------------------------------------------------------------------
    # Block 2: Duration adjustment (calls 21–35)
    # ------------------------------------------------------------------
    b = 2
    add(b, 21, 9,  {"duration_minutes": 15, "difficulty": "medium", "equipment": _eq("E3_db"),      "focus_areas": ["push"]})
    add(b, 22, 10, {"duration_minutes": 20, "difficulty": "medium", "equipment": _eq("E2_bw"),      "focus_areas": ["full_body"]})
    add(b, 23, 11, {"duration_minutes": 25, "difficulty": "hard",   "equipment": _eq("E4_kb"),      "focus_areas": ["full_body"]})
    add(b, 24, 12, {"duration_minutes_min": 15, "duration_minutes_max": 30, "difficulty": "medium", "equipment": _eq("E2_bw"),   "focus_areas": ["core"]})
    add(b, 25, 13, {"duration_minutes_min": 30, "duration_minutes_max": 45, "difficulty": "medium", "equipment": _eq("E1_full"), "focus_areas": ["pull"]})
    add(b, 26, 14, {"duration_minutes_min": 45, "duration_minutes_max": 60, "difficulty": "hard",   "equipment": _eq("E1_full"), "focus_areas": ["legs"]})
    add(b, 27, 15, {"duration_minutes_min": 60, "duration_minutes_max": 90, "difficulty": "hard",   "equipment": _eq("E8_fw"),   "focus_areas": ["upper"]})
    add(b, 28, 16, {"duration_minutes": 75, "difficulty": "medium", "equipment": _eq("E1_full"),    "focus_areas": ["full_body"]})
    add(b, 29, 17, {"duration_minutes": 90, "difficulty": "hard",   "equipment": _eq("E1_full"),    "focus_areas": ["full_body"]})
    add(b, 30, 18, {"duration_minutes": 90, "difficulty": "hell",   "equipment": _eq("E1_full"),    "focus_areas": ["legs"]})
    add(b, 31, 19, {"duration_minutes": 15, "difficulty": "hell",   "equipment": _eq("E2_bw"),      "focus_areas": ["core"]})
    add(b, 32, 20, {"duration_minutes": 90, "difficulty": "easy",   "equipment": _eq("E6_bands"),   "focus_areas": ["mobility"]})
    add(b, 33, 1,  {"duration_minutes": 30, "difficulty": "medium", "equipment": _eq("E11_cardio"), "focus_areas": ["cardio"]})
    add(b, 34, 2,  {"duration_minutes": 60, "difficulty": "medium", "equipment": _eq("E10_home"),   "focus_areas": ["full_body"]})
    add(b, 35, 3,  {"duration_minutes": 45, "difficulty": "hard",   "equipment": _eq("E5_mach"),    "focus_areas": ["upper"]})

    # ------------------------------------------------------------------
    # Block 3: Equipment swap (calls 36–50)
    # ------------------------------------------------------------------
    b = 3
    add(b, 36, 4,  {"equipment": _eq("E2_bw"),      "duration_minutes": 30, "difficulty": "medium", "focus_areas": ["full_body"]})
    add(b, 37, 5,  {"equipment": _eq("E2_bw"),      "duration_minutes": 45, "difficulty": "hard",   "focus_areas": ["legs"]})
    add(b, 38, 6,  {"equipment": _eq("E3_db"),      "duration_minutes": 45, "difficulty": "medium", "focus_areas": ["push"],      "dumbbell_count": 2})
    add(b, 39, 7,  {"equipment": _eq("E9_db1"),     "duration_minutes": 30, "difficulty": "medium", "focus_areas": ["upper"],     "dumbbell_count": 1})
    add(b, 40, 8,  {"equipment": _eq("E4_kb"),      "duration_minutes": 30, "difficulty": "hard",   "focus_areas": ["full_body"], "kettlebell_count": 1})
    add(b, 41, 9,  {"equipment": _eq("E4_kb"),      "duration_minutes": 45, "difficulty": "hard",   "focus_areas": ["full_body"], "kettlebell_count": 2})
    add(b, 42, 10, {"equipment": _eq("E5_mach"),    "duration_minutes": 60, "difficulty": "medium", "focus_areas": ["legs"]})
    add(b, 43, 11, {"equipment": _eq("E6_bands"),   "duration_minutes": 20, "difficulty": "easy",   "focus_areas": ["mobility"]})
    add(b, 44, 12, {"equipment": _eq("E11_cardio"), "duration_minutes": 30, "difficulty": "medium", "focus_areas": ["cardio"]})
    add(b, 45, 13, {"equipment": _eq("E7_no_bb"),   "duration_minutes": 45, "difficulty": "hard",   "focus_areas": ["push"]})
    add(b, 46, 14, {"equipment": _eq("E10_home"),   "duration_minutes": 45, "difficulty": "medium", "focus_areas": ["full_body"]})
    add(b, 47, 15, {"equipment": _eq("E12_bw_bands"), "duration_minutes": 30, "difficulty": "medium", "focus_areas": ["core"]})
    add(b, 48, 16, {"equipment": _eq("E8_fw"),      "duration_minutes": 60, "difficulty": "hard",   "focus_areas": ["full_body"]})
    add(b, 49, 17, {"equipment": _eq("E1_full"),    "duration_minutes": 45, "difficulty": "hell",   "focus_areas": ["legs"]})
    add(b, 50, 18, {"equipment": _eq("E1_full"),    "duration_minutes": 60, "difficulty": "hard",   "focus_areas": ["arms"]})

    # ------------------------------------------------------------------
    # Block 4: Focus pivot (calls 51–65)
    # ------------------------------------------------------------------
    b = 4
    add(b, 51, 19, {"focus_areas": ["pull"],              "duration_minutes": 45, "difficulty": "medium", "equipment": _eq("E1_full")})
    add(b, 52, 20, {"focus_areas": ["upper"],             "duration_minutes": 45, "difficulty": "medium", "equipment": _eq("E1_full")})
    add(b, 53, 1,  {"focus_areas": ["cardio"],            "duration_minutes": 30, "difficulty": "medium", "equipment": _eq("E11_cardio")})
    add(b, 54, 2,  {"focus_areas": ["mobility"],          "duration_minutes": 30, "difficulty": "easy",   "equipment": _eq("E6_bands")})
    add(b, 55, 3,  {"focus_areas": ["full_body"],         "duration_minutes": 30, "difficulty": "hell",   "equipment": _eq("E2_bw"),    "workout_type": "HIIT"})
    add(b, 56, 4,  {"focus_areas": ["push", "pull"],      "duration_minutes": 60, "difficulty": "medium", "equipment": _eq("E1_full")})
    add(b, 57, 5,  {"focus_areas": ["legs", "glutes"],    "duration_minutes": 60, "difficulty": "hard",   "equipment": _eq("E1_full")})
    add(b, 58, 6,  {"focus_areas": ["core"],              "duration_minutes": 20, "difficulty": "medium", "equipment": _eq("E2_bw")})
    add(b, 59, 7,  {"focus_areas": ["arms"],              "duration_minutes": 30, "difficulty": "medium", "equipment": _eq("E3_db")})
    add(b, 60, 8,  {"focus_areas": ["shoulders"],         "duration_minutes": 30, "difficulty": "medium", "equipment": _eq("E3_db")})
    add(b, 61, 9,  {"focus_areas": ["cardio", "full_body"], "duration_minutes": 45, "difficulty": "hard", "equipment": _eq("E11_cardio")})
    add(b, 62, 10, {"focus_areas": ["mobility", "core"],  "duration_minutes": 30, "difficulty": "easy",   "equipment": _eq("E12_bw_bands")})
    add(b, 63, 11, {"focus_areas": ["glutes"],            "duration_minutes": 30, "difficulty": "hard",   "equipment": _eq("E5_mach")})
    add(b, 64, 12, {"focus_areas": ["upper", "lower"],    "duration_minutes": 60, "difficulty": "medium", "equipment": _eq("E1_full")})
    add(b, 65, 13, {"focus_areas": ["push", "pull", "legs"], "duration_minutes": 90, "difficulty": "hard","equipment": _eq("E1_full")})

    # ------------------------------------------------------------------
    # Block 5: AI prompt overrides (calls 66–80)
    # ------------------------------------------------------------------
    b = 5
    add(b, 66, 14, {"ai_prompt": "make it more compound-focused, fewer isolation exercises",           "duration_minutes": 45, "equipment": _eq("E1_full")})
    add(b, 67, 15, {"ai_prompt": "no jumping or impact today, my knees hurt",                          "duration_minutes": 30, "equipment": _eq("E5_mach")})
    add(b, 68, 16, {"ai_prompt": "more cardio please, I want to sweat",                               "duration_minutes": 45, "equipment": _eq("E11_cardio")})
    add(b, 69, 17, {"ai_prompt": "shorter rest periods between sets, like 30s",                       "duration_minutes": 30, "equipment": _eq("E1_full")})
    add(b, 70, 18, {"ai_prompt": "longer rest, 2-3 min, I'm trying to lift heavier",                  "duration_minutes": 60, "equipment": _eq("E8_fw")})
    add(b, 71, 19, {"ai_prompt": "include 5 minutes of warmup specific to shoulders",                  "duration_minutes": 45, "equipment": _eq("E3_db")})
    add(b, 72, 20, {"ai_prompt": "no barbell exercises today",                                         "duration_minutes": 45, "equipment": _eq("E7_no_bb")})
    add(b, 73, 1,  {"ai_prompt": "make it a pyramid set structure (10-8-6-4)",                         "duration_minutes": 60, "equipment": _eq("E1_full")})
    add(b, 74, 2,  {"ai_prompt": "I want supersets and giant sets, push intensity",                    "duration_minutes": 60, "equipment": _eq("E1_full")})
    add(b, 75, 3,  {"ai_prompt": "easy day, foam rolling and stretching only",                         "duration_minutes": 30, "equipment": _eq("E6_bands")})
    add(b, 76, 4,  {"ai_prompt": "I'm pregnant, second trimester — adjust accordingly",               "duration_minutes": 30, "equipment": _eq("E10_home")})
    add(b, 77, 5,  {"ai_prompt": "post-injury return-to-running phase 2",                              "duration_minutes": 30, "equipment": _eq("E11_cardio")})
    add(b, 78, 6,  {"ai_prompt": "12 weeks out from a powerlifting meet — accumulation block",         "duration_minutes": 90, "equipment": _eq("E1_full")})
    add(b, 79, 7,  {"ai_prompt": "menstrual cycle day 2, please de-escalate intensity",               "duration_minutes": 30, "equipment": _eq("E10_home")})
    add(b, 80, 8,  {"ai_prompt": "fasted training, low energy, keep it under 30 min",                 "duration_minutes": 25, "equipment": _eq("E2_bw")})

    # ------------------------------------------------------------------
    # Block 6: Reschedule with new_scheduled_date (calls 81–90)
    # ------------------------------------------------------------------
    b = 6
    add(b, 81, 9,  {"new_scheduled_date": _today_iso(),         "force_non_preferred_day": True,  "duration_minutes": 45, "equipment": _eq("E1_full")})
    add(b, 82, 10, {"new_scheduled_date": _next_weekday(3),     "force_non_preferred_day": False, "duration_minutes": 45, "equipment": _eq("E1_full")})
    add(b, 83, 11, {"new_scheduled_date": _next_weekday(5),     "force_non_preferred_day": False, "duration_minutes": 60, "equipment": _eq("E1_full")})
    add(b, 84, 12, {"new_scheduled_date": _next_weekday(6),     "force_non_preferred_day": False, "duration_minutes": 30, "equipment": _eq("E2_bw")})
    add(b, 85, 13, {"new_scheduled_date": _next_weekday(0),     "force_non_preferred_day": True,  "duration_minutes": 45, "equipment": _eq("E5_mach")})
    add(b, 86, 14, {"new_scheduled_date": _next_weekday(2),     "force_non_preferred_day": True,  "duration_minutes": 60, "equipment": _eq("E3_db")})
    add(b, 87, 15, {"new_scheduled_date": _next_weekday(4),     "force_non_preferred_day": True,  "duration_minutes": 75, "equipment": _eq("E11_cardio")})
    add(b, 88, 16, {"new_scheduled_date": _next_weekday(0),     "force_non_preferred_day": False, "duration_minutes": 45, "equipment": _eq("E1_full")})
    add(b, 89, 17, {"new_scheduled_date": _next_weekday(1),     "force_non_preferred_day": False, "duration_minutes": 30, "equipment": _eq("E1_full")})
    add(b, 90, 18, {"new_scheduled_date": _days_from_today(30), "force_non_preferred_day": False, "duration_minutes": 60, "equipment": _eq("E1_full")})

    # ------------------------------------------------------------------
    # Block 7: Injury injection (calls 91–95)
    # ------------------------------------------------------------------
    b = 7
    add(b, 91, 19, {"injuries": ["knee"],                                                               "duration_minutes": 45, "difficulty": "hard",   "focus_areas": ["legs"],      "equipment": _eq("E1_full")})
    add(b, 92, 20, {"injuries": ["shoulder"],                                                            "duration_minutes": 45, "difficulty": "hard",   "focus_areas": ["push"],      "equipment": _eq("E1_full")})
    add(b, 93, 1,  {"injuries": ["lower_back"],                                                          "duration_minutes": 60, "difficulty": "medium", "focus_areas": ["pull"],      "equipment": _eq("E1_full")})
    add(b, 94, 2,  {"injuries": ["knee", "shoulder", "wrist"],                                           "duration_minutes": 45, "difficulty": "medium", "focus_areas": ["full_body"], "equipment": _eq("E1_full")})
    add(b, 95, 3,  {"injuries": ["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"],   "duration_minutes": 30, "difficulty": "easy",   "focus_areas": ["core"],      "equipment": _eq("E12_bw_bands")})

    # ------------------------------------------------------------------
    # Block 8: Same-source 3x + composite + minimal (calls 96–100)
    # ------------------------------------------------------------------
    b = 8
    _b8_params = {"difficulty": "medium", "duration_minutes": 45, "equipment": _eq("E1_full"), "focus_areas": ["full_body"]}
    add(b, 96,  5, _b8_params)
    add(b, 97,  5, _b8_params)
    add(b, 98,  5, _b8_params)
    # Call 99: Maximal payload
    add(b, 99, 6, {
        "fitness_level": "advanced",
        "difficulty": "hell",
        "equipment": _eq("E1_full"),
        "focus_areas": ["push", "pull", "legs", "full_body", "core", "upper"],
        "injuries": ["knee", "shoulder", "lower_back"],
        "ai_prompt": ("This is a phoenix-themed inferno session. Push every limit. "
                      "Compound movements only. No machines. Barbells and dumbbells. "
                      "Superset every exercise. Rest no more than 45 seconds. "
                      "Make it the hardest workout I have ever done in my entire life. "
                      "Include deadlifts, squats, bench, rows, and overhead press. "
                      "I am a competitive powerlifter peaking for a meet in 4 weeks."),
        "workout_name": "Phoenix Inferno",
        "new_scheduled_date": _today_iso(),
        "force_non_preferred_day": True,
        "dumbbell_count": 2,
        "kettlebell_count": 2,
    })
    # Call 100: Minimal payload — only workout_id + user_id
    add(b, 100, 7, {})

    # ------------------------------------------------------------------
    # Block 9: Source workout state edges (calls 101–115)
    # Note: Some of these reference specific states that we can't fully control
    # from the client side. We use available workouts from the sources list and
    # document expected outcomes.
    # ------------------------------------------------------------------
    b = 9
    # 101: Non-existent workout_id
    scenarios.append({
        "block": b, "idx": 101,
        "source_workout_id": "00000000-0000-0000-0000-000000000000",
        "source_workout_name": "(non-existent)",
        "body": {
            "workout_id": "00000000-0000-0000-0000-000000000000",
            "user_id": TEST_USER_ID,
            "duration_minutes": 45,
            "equipment": _eq("E1_full"),
        },
    })
    # 102: IDOR — workout belonging to a different user (random UUID)
    scenarios.append({
        "block": b, "idx": 102,
        "source_workout_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
        "source_workout_name": "(different user workout)",
        "body": {
            "workout_id": "ffffffff-ffff-ffff-ffff-ffffffffffff",
            "user_id": TEST_USER_ID,
            "duration_minutes": 45,
            "equipment": _eq("E1_full"),
        },
    })
    # 103–115: use real source workouts and document states
    state_edge_cases = [
        (103, 4,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # completed source
        (104, 5,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # source with logs
        (105, 6,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # source with prior previews
        (106, 7,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # soft-deleted source (expect error)
        (107, 8,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # old source
        (108, 9,  {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # inactive gym profile
        (109, 10, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # generating status
        (110, 11, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # empty exercises
        (111, 12, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # 30 exercises
        (112, 13, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # profile mismatch
        (113, 14, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # past scheduled_date
        (114, 15, {"duration_minutes": 45, "equipment": _eq("E1_full"), "workout_name": "تمرين 🏋️ workout"}),  # emoji+RTL name
        (115, 16, {"duration_minutes": 45, "equipment": _eq("E1_full")}),  # regen-of-regen
    ]
    for idx, s_key, extra_body in state_edge_cases:
        src = _s(sources, s_key)
        scenarios.append({
            "block": b, "idx": idx,
            "source_workout_id": src["id"],
            "source_workout_name": src.get("name", ""),
            "body": {"workout_id": src["id"], "user_id": TEST_USER_ID, **extra_body},
        })

    # ------------------------------------------------------------------
    # Block 10: Body validation & errors (calls 116–125)
    # ------------------------------------------------------------------
    b = 10
    src_valid = _s(sources, 1)
    # 116: missing workout_id
    scenarios.append({
        "block": b, "idx": 116,
        "source_workout_id": "", "source_workout_name": "(validation: missing workout_id)",
        "body": {"user_id": TEST_USER_ID, "duration_minutes": 45},
    })
    # 117: missing user_id
    scenarios.append({
        "block": b, "idx": 117,
        "source_workout_id": src_valid["id"], "source_workout_name": "(validation: missing user_id)",
        "body": {"workout_id": src_valid["id"], "duration_minutes": 45},
    })
    # 118: invalid UUID workout_id
    scenarios.append({
        "block": b, "idx": 118,
        "source_workout_id": "not-a-uuid", "source_workout_name": "(validation: invalid UUID)",
        "body": {"workout_id": "not-a-uuid", "user_id": TEST_USER_ID},
    })
    # 119: duration_minutes=0
    scenarios.append({
        "block": b, "idx": 119,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID, "duration_minutes": 0},
    })
    # 120: duration_minutes=481
    scenarios.append({
        "block": b, "idx": 120,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID, "duration_minutes": 481},
    })
    # 121: inverted min/max
    scenarios.append({
        "block": b, "idx": 121,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID,
                 "duration_minutes_min": 60, "duration_minutes_max": 30},
    })
    # 122: equipment array length 300 (no upper bound — expect 200)
    scenarios.append({
        "block": b, "idx": 122,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID,
                 "equipment": [f"item_{i}" for i in range(300)], "duration_minutes": 30},
    })
    # 123: injuries length 21 (max=20)
    scenarios.append({
        "block": b, "idx": 123,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID,
                 "injuries": [f"injury_{i}" for i in range(21)], "duration_minutes": 30},
    })
    # 124: ai_prompt 2001 chars
    scenarios.append({
        "block": b, "idx": 124,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID,
                 "ai_prompt": "a" * 2001, "duration_minutes": 30},
    })
    # 125: workout_name 201 chars
    scenarios.append({
        "block": b, "idx": 125,
        "source_workout_id": src_valid["id"], "source_workout_name": src_valid.get("name", ""),
        "body": {"workout_id": src_valid["id"], "user_id": TEST_USER_ID,
                 "workout_name": "x" * 201, "duration_minutes": 30},
    })

    # ------------------------------------------------------------------
    # Block 11: Concurrency, preview accumulation, stream behavior (126–135)
    # ------------------------------------------------------------------
    b = 11
    # 126, 127 and 128 are concurrent — they are handled specially in run loop
    src_b11 = _s(sources, 3)
    for idx in [126, 127, 128]:
        scenarios.append({
            "block": b, "idx": idx,
            "source_workout_id": src_b11["id"],
            "source_workout_name": src_b11.get("name", ""),
            "body": {"workout_id": src_b11["id"], "user_id": TEST_USER_ID,
                     "duration_minutes": 30, "equipment": _eq("E1_full"),
                     "_concurrent_group": "b11_conc2" if idx in (126, 127) else "b11_single128"},
        })
    # 129: 6 rapid calls to test rate-limit 429
    src_b11_129 = _s(sources, 4)
    for sub in range(6):
        scenarios.append({
            "block": b, "idx": 129,
            "source_workout_id": src_b11_129["id"],
            "source_workout_name": src_b11_129.get("name", "") + f"_ratelimit_{sub}",
            "body": {"workout_id": src_b11_129["id"], "user_id": TEST_USER_ID,
                     "duration_minutes": 30, "equipment": _eq("E1_full"),
                     "_rate_limit_burst": True},
        })
    # 130: 10 sequential regens, same source, no commit
    src_b11_130 = _s(sources, 5)
    for sub in range(10):
        scenarios.append({
            "block": b, "idx": 130,
            "source_workout_id": src_b11_130["id"],
            "source_workout_name": src_b11_130.get("name", "") + f"_nocommit_{sub}",
            "body": {"workout_id": src_b11_130["id"], "user_id": TEST_USER_ID,
                     "duration_minutes": 30, "equipment": _eq("E1_full")},
        })
    # 131: Regen during generate-stream for same date (sequential approximation)
    add(b, 131, 6, {"duration_minutes": 45, "equipment": _eq("E1_full")})
    # 132: Quick-regen concurrency simulation
    add(b, 132, 7, {"duration_minutes": 30, "equipment": _eq("E2_bw")})
    # 133: Slow client — just a normal call (timeout behavior)
    add(b, 133, 8, {"duration_minutes": 45, "equipment": _eq("E1_full")})
    # 134: Gemini timeout simulation (long hell prompt)
    add(b, 134, 9, {
        "difficulty": "hell",
        "duration_minutes": 120,
        "equipment": _eq("E1_full"),
        "focus_areas": ["push", "pull", "legs", "core"],
        "ai_prompt": "This is a Gemini stress test. Generate a 2-hour hell workout. " * 20,
    })
    # 135: Error event test
    add(b, 135, 10, {"duration_minutes": 45, "equipment": _eq("E1_full")})

    # ------------------------------------------------------------------
    # Block 12: Conflicting body params (calls 136–145)
    # ------------------------------------------------------------------
    b = 12
    add(b, 136, 11, {
        "fitness_level": "beginner",
        "difficulty": "hell",
        "injuries": ["knee", "shoulder", "lower_back", "wrist", "ankle", "hip", "elbow"],
        "duration_minutes": 30,
        "equipment": _eq("E1_full"),
    })
    add(b, 137, 12, {
        "equipment": [],
        "focus_areas": ["legs"],
        "difficulty": "hell",
        "duration_minutes": 45,
    })
    add(b, 138, 13, {
        "duration_minutes": 15,
        "ai_prompt": "60 min session please, take your time",
        "equipment": _eq("E1_full"),
    })
    add(b, 139, 14, {
        "new_scheduled_date": _days_from_today(-1),
        "force_non_preferred_day": True,
        "duration_minutes": 30,
        "equipment": _eq("E1_full"),
    })
    add(b, 140, 15, {
        "new_scheduled_date": _days_from_today(-30),
        "force_non_preferred_day": True,
        "duration_minutes": 30,
        "equipment": _eq("E1_full"),
    })
    # 141: empty workout_name
    src_141 = _s(sources, 16)
    scenarios.append({
        "block": b, "idx": 141,
        "source_workout_id": src_141["id"], "source_workout_name": src_141.get("name", ""),
        "body": {"workout_id": src_141["id"], "user_id": TEST_USER_ID,
                 "workout_name": "", "duration_minutes": 30, "equipment": _eq("E1_full")},
    })
    # 142: whitespace workout_name
    src_142 = _s(sources, 17)
    scenarios.append({
        "block": b, "idx": 142,
        "source_workout_id": src_142["id"], "source_workout_name": src_142.get("name", ""),
        "body": {"workout_id": src_142["id"], "user_id": TEST_USER_ID,
                 "workout_name": "   ", "duration_minutes": 30, "equipment": _eq("E1_full")},
    })
    # 143: dumbbell_count=0 (expect 422)
    src_143 = _s(sources, 18)
    scenarios.append({
        "block": b, "idx": 143,
        "source_workout_id": src_143["id"], "source_workout_name": src_143.get("name", ""),
        "body": {"workout_id": src_143["id"], "user_id": TEST_USER_ID,
                 "dumbbell_count": 0, "duration_minutes": 30},
    })
    # 144: dumbbell_count=11 (expect 422)
    src_144 = _s(sources, 19)
    scenarios.append({
        "block": b, "idx": 144,
        "source_workout_id": src_144["id"], "source_workout_name": src_144.get("name", ""),
        "body": {"workout_id": src_144["id"], "user_id": TEST_USER_ID,
                 "dumbbell_count": 11, "duration_minutes": 30},
    })
    # 145: unknown injury
    add(b, 145, 20, {
        "injuries": ["fake_injury_xyz"],
        "duration_minutes": 30,
        "equipment": _eq("E1_full"),
    })

    # ------------------------------------------------------------------
    # Block 13: Multi-language ai_prompt (calls 146–150)
    # ------------------------------------------------------------------
    b = 13
    add(b, 146, 1, {
        "ai_prompt": "Hazlo más cardio y menos pesas, por favor",
        "duration_minutes": 45,
        "equipment": _eq("E1_full"),
    })
    add(b, 147, 2, {
        "ai_prompt": "今天我膝盖疼，请避免跳跃",
        "duration_minutes": 30,
        "injuries": ["knee"],
        "equipment": _eq("E2_bw"),
    })
    add(b, 148, 3, {
        "ai_prompt": "أريد جلسة قصيرة ومكثفة لمدة 30 دقيقة",
        "duration_minutes": 30,
        "equipment": _eq("E1_full"),
    })
    add(b, 149, 4, {
        "ai_prompt": "I want supersets 🏋️ comme dans CrossFit, no барbell",
        "duration_minutes": 45,
        "equipment": _eq("E7_no_bb"),
    })
    # 150: minimal body
    src_150 = _s(sources, 5)
    scenarios.append({
        "block": b, "idx": 150,
        "source_workout_id": src_150["id"], "source_workout_name": src_150.get("name", ""),
        "body": {"workout_id": src_150["id"], "user_id": TEST_USER_ID},
    })

    return scenarios


# ---------------------------------------------------------------------------
# Concurrent call helpers (Block 11)
# ---------------------------------------------------------------------------

async def run_concurrent_calls(
    client: httpx.AsyncClient,
    headers: Dict[str, str],
    n: int,
    body: Dict[str, Any],
) -> List[Tuple]:
    """Run n simultaneous regen calls and return list of result tuples."""
    tasks = [call_regen_stream(client, headers, body) for _ in range(n)]
    return await asyncio.gather(*tasks, return_exceptions=False)


# ---------------------------------------------------------------------------
# Main run loop
# ---------------------------------------------------------------------------

async def run(
    n_limit: int,
    output_dir: Path,
    jwt: str,
    auth_source: str,
) -> None:
    headers = {
        "Authorization": f"Bearer {jwt}",
        "Content-Type": "application/json",
        "Accept": "text/event-stream",
    }

    csv_path = output_dir / "results.csv"
    init_csv(csv_path)

    async with httpx.AsyncClient(timeout=HTTP_TIMEOUT) as client:
        # ---- Pre-step ----
        _log.info("[pre-step] Ensuring >=20 source workouts exist...")
        sources = await ensure_source_workouts(client, headers)
        if not sources:
            _log.error("[pre-step] No source workouts available — aborting")
            return
        _log.info(f"[pre-step] Using {len(sources)} source workouts: S1..S{len(sources)}")
        for i, s in enumerate(sources[:20], 1):
            _log.info(f"  S{i}: {s['id']} | {s.get('name', '')} | {s.get('scheduled_date', '')}")

        # ---- Build scenarios ----
        all_scenarios = build_scenarios(sources)
        run_scenarios = all_scenarios[:n_limit]

        _log.info(f"[run] Running {len(run_scenarios)} scenarios (limit={n_limit})")

        total_successes = 0
        total_errors = 0
        call_number = 0

        i = 0
        while i < len(run_scenarios):
            sc = run_scenarios[i]
            idx = sc["idx"]
            block = sc["block"]
            body = {k: v for k, v in sc["body"].items() if not k.startswith("_")}

            # ---- Block 11 concurrency: calls 126+127 (2 simultaneous) ----
            if sc["body"].get("_concurrent_group") == "b11_conc2":
                # Gather the next scenario too if it's also b11_conc2
                concurrent_scs = [sc]
                while (i + 1 < len(run_scenarios) and
                       run_scenarios[i + 1]["body"].get("_concurrent_group") == "b11_conc2"):
                    i += 1
                    concurrent_scs.append(run_scenarios[i])
                _log.info(f"[block11] Running {len(concurrent_scs)} concurrent calls (idx={[s['idx'] for s in concurrent_scs]})")
                conc_bodies = [{k: v for k, v in s["body"].items() if not k.startswith("_")}
                               for s in concurrent_scs]
                conc_tasks = [call_regen_stream(client, headers, b_) for b_ in conc_bodies]
                conc_results = await asyncio.gather(*conc_tasks)
                for sc_c, res in zip(concurrent_scs, conc_results):
                    call_number += 1
                    _write_result(csv_path, sc_c, res, call_number)
                    if res[4] > 0 and not res[5]:
                        total_successes += 1
                    else:
                        total_errors += 1
                    _log.info(
                        f"[{call_number}/{len(run_scenarios)}] "
                        f"block={sc_c['block']} idx={sc_c['idx']} "
                        f"http={res[0]} latency={res[1]:.0f}ms "
                        f"events={res[4]} preview={res[3].get('preview_id', '')[:8]} "
                        f"err={res[5] or ''}"
                    )
                i += 1
                await asyncio.sleep(PACE_SECONDS)
                continue

            # ---- Block 11: 5 simultaneous (call 127 batch) ----
            if block == 11 and idx == 127 and i > 0:
                # Already handled above; skip if somehow encountered alone
                i += 1
                continue

            # ---- Block 11: rate-limit burst (call 129) ----
            if sc["body"].get("_rate_limit_burst"):
                # Collect all rate-limit burst rows
                burst_scs = [sc]
                burst_bodies = [body]
                while (i + 1 < len(run_scenarios) and
                       run_scenarios[i + 1]["body"].get("_rate_limit_burst")):
                    i += 1
                    burst_scs.append(run_scenarios[i])
                    burst_bodies.append({k: v for k, v in run_scenarios[i]["body"].items()
                                         if not k.startswith("_")})

                _log.info(f"[block11] Rate-limit burst: {len(burst_scs)} rapid calls without pacing")
                # Fire all 6 as fast as possible (no sleep between them)
                burst_tasks = [call_regen_stream(client, headers, b_, timeout=30.0)
                                for b_ in burst_bodies]
                burst_results = await asyncio.gather(*burst_tasks, return_exceptions=True)
                for sc_b, res in zip(burst_scs, burst_results):
                    call_number += 1
                    if isinstance(res, Exception):
                        res = (0, 0.0, "", {}, 0, str(res))
                    _write_result(csv_path, sc_b, res, call_number)
                    if res[4] > 0 and not res[5]:
                        total_successes += 1
                    else:
                        total_errors += 1
                    _log.info(
                        f"[{call_number}/{len(run_scenarios)}] "
                        f"block={sc_b['block']} idx={sc_b['idx']} "
                        f"http={res[0]} latency={res[1]:.0f}ms "
                        f"err={res[5] or ''}"
                    )
                i += 1
                await asyncio.sleep(PACE_SECONDS)
                continue

            # ---- Normal sequential call ----
            call_number += 1
            _log.info(
                f"[{call_number}/{len(run_scenarios)}] "
                f"block={block} idx={idx} "
                f"source={sc['source_workout_id'][:8] if sc['source_workout_id'] else 'N/A'}..."
            )

            res = await call_regen_stream(client, headers, body)
            http_status, latency_ms, raw_sse, final_payload, event_count, error_message = res

            _write_result(csv_path, sc, res, call_number)

            if http_status == 200 and not error_message:
                total_successes += 1
            else:
                total_errors += 1

            preview_id = final_payload.get("preview_id", "") if final_payload else ""
            _log.info(
                f"  -> http={http_status} latency={latency_ms:.0f}ms "
                f"events={event_count} preview_id={str(preview_id)[:8]} "
                f"err={error_message or ''}"
            )

            i += 1
            # Pace between calls — but not after the last one
            if i < len(run_scenarios):
                await asyncio.sleep(PACE_SECONDS)

    print(f"\n{'='*60}")
    print(f"Run complete. Total calls: {call_number}")
    print(f"Successes: {total_successes}  Errors/non-2xx: {total_errors}")
    print(f"Output: {csv_path}")
    print(f"{'='*60}\n")


def _write_result(
    csv_path: Path,
    sc: Dict[str, Any],
    res: Tuple,
    call_number: int,
) -> None:
    """Write one result row to the CSV."""
    http_status, latency_ms, raw_sse, final_payload, event_count, error_message = res

    fields = extract_workout_fields(final_payload or {})

    body_for_csv = {k: v for k, v in sc["body"].items() if not k.startswith("_")}

    row: Dict[str, Any] = {
        "idx": sc["idx"],
        "scenario_block": sc["block"],
        "source_workout_id": sc["source_workout_id"],
        "source_workout_name": sc["source_workout_name"],
        "http_status": http_status,
        "latency_ms": round(latency_ms, 1),
        "request_body_json": json.dumps(body_for_csv, ensure_ascii=False),
        "preview_id": fields["preview_id"],
        "ai_workout_name": fields["ai_workout_name"],
        "ai_workout_type": fields["ai_workout_type"],
        "ai_difficulty": fields["ai_difficulty"],
        "ai_notes": fields["ai_notes"],
        "n_exercises": fields["n_exercises"],
        "exercise_names_pipe": fields["exercise_names_pipe"],
        "per_exercise_sets": fields["per_exercise_sets"],
        "per_exercise_reps": fields["per_exercise_reps"],
        "per_exercise_weight_kg": fields["per_exercise_weight_kg"],
        "per_exercise_rest_seconds": fields["per_exercise_rest_seconds"],
        "per_exercise_muscle_group": fields["per_exercise_muscle_group"],
        "est_duration_min": fields["est_duration_min"],
        "total_volume_kg": fields["total_volume_kg"],
        "error_message": error_message or "",
        "sse_event_count": event_count,
        "final_response_json": json.dumps(final_payload, ensure_ascii=False, default=str) if final_payload else "",
    }
    append_csv(csv_path, row)


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Regenerate-stream 150-scenario harness")
    parser.add_argument(
        "--n", type=int, default=150,
        help="Number of scenarios to run (default: 150). Use 5 for smoke test."
    )
    parser.add_argument(
        "--token-env", default="QA_JWT",
        help="Env var name holding a pre-minted JWT (default: QA_JWT)"
    )
    parser.add_argument(
        "--output-dir", default=None,
        help="Override output directory path"
    )
    args = parser.parse_args()

    # Auth
    os.environ["QA_JWT"] = os.environ.get(args.token_env, os.environ.get("QA_JWT", ""))
    jwt, auth_source = obtain_jwt()
    _log.info(f"[auth] JWT source: {auth_source} prefix={jwt[:24]}...")

    # Output dir
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    if args.output_dir:
        output_dir = Path(args.output_dir)
    else:
        output_dir = (
            Path(__file__).resolve().parent / "output" / f"render_regenerate_stream_{ts}"
        )
    output_dir.mkdir(parents=True, exist_ok=True)
    _log.info(f"[run] Output dir: {output_dir}")

    print(f"\nZealova Regenerate-Stream Validation Harness")
    print(f"  JWT source  : {auth_source}")
    print(f"  Scenarios   : {args.n}")
    print(f"  Pace        : {PACE_SECONDS}s between calls")
    print(f"  Output      : {output_dir}")
    print(f"  Est. time   : ~{int(args.n * PACE_SECONDS / 60)} min\n")

    t0 = time.time()
    asyncio.run(run(args.n, output_dir, jwt, auth_source))
    elapsed = time.time() - t0
    print(f"Total elapsed: {elapsed:.0f}s ({elapsed/60:.1f} min)")
    print(f"Results CSV  : {output_dir / 'results.csv'}")


if __name__ == "__main__":
    main()
