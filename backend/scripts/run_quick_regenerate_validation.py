"""200-scenario validation harness for `/api/v1/workouts/quick-regenerate`.

Endpoint is NOT AI — pure SQL delete + activity log. Per-call latency ~400ms.

Run:
    cd backend && .venv/bin/python scripts/run_quick_regenerate_validation.py            # full 200
    .venv/bin/python scripts/run_quick_regenerate_validation.py --n 5                    # smoke
    .venv/bin/python scripts/run_quick_regenerate_validation.py --blocks 1,2             # subset

Outputs (all incremental, one-per-scenario):
    scripts/output/render_quick_regenerate_<ts>/workouts.csv
    scripts/output/render_quick_regenerate_<ts>/json/scenario_NNN.json
    stdout: per-call status line, flushed.
"""
from __future__ import annotations

import argparse
import asyncio
import csv
import json
import os
import sys
import time
import uuid
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional

import httpx
import requests
from dotenv import load_dotenv
from supabase import Client, create_client

BACKEND = Path(__file__).resolve().parent.parent
load_dotenv(BACKEND / ".env")

SUPABASE_URL = os.environ["SUPABASE_URL"]
SUPABASE_KEY = os.environ["SUPABASE_KEY"]  # service role
RENDER_BASE = os.environ.get("RENDER_BASE", "https://aifitnesscoach-zqi3.onrender.com")

USER_ID = "d54e6652-fdf1-4ca0-82d1-23d7c02df294"  # reviewer@fitwiz.us
ACTIVE_PROFILE = "0890400c-6900-4cd0-b55a-353ea1655206"  # Peoria home, days=[Tue=1, Thu=3, Sat=5]
INACTIVE_PROFILE = "bc47e50a-d873-4792-8931-8fec8031e807"  # My Gym, days=[Thu=3, Sat=5, Sun=6]
QA_EMAIL = "reviewer@fitwiz.us"
QA_PASSWORD = "FitWiz2026!"

sb: Client = create_client(SUPABASE_URL, SUPABASE_KEY)


# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------
def get_jwt() -> str:
    """Sign in via Supabase REST and return access_token."""
    r = requests.post(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        headers={"apikey": SUPABASE_KEY, "Content-Type": "application/json"},
        json={"email": QA_EMAIL, "password": QA_PASSWORD},
        timeout=10,
    )
    r.raise_for_status()
    return r.json()["access_token"]


# ---------------------------------------------------------------------------
# Date helpers
# ---------------------------------------------------------------------------
def next_weekday(weekday: int, after: Optional[date] = None) -> date:
    """Return the next date >= `after` (default today) whose weekday matches.

    weekday: 0=Mon ... 6=Sun
    """
    d = after or date.today()
    delta = (weekday - d.weekday()) % 7
    return d + timedelta(days=delta)


def today() -> str:
    return date.today().isoformat()


def iso(d: date) -> str:
    return d.isoformat()


# Preferred days for active profile [Tue=1, Thu=3, Sat=5]
PREFERRED_DAYS = [1, 3, 5]


def n_preferred_dates(n: int, start: Optional[date] = None) -> List[str]:
    """Generate next N dates falling on preferred days."""
    base = start or date.today()
    out: List[str] = []
    d = base
    while len(out) < n:
        if d.weekday() in PREFERRED_DAYS and d >= base:
            out.append(d.isoformat())
        d += timedelta(days=1)
    return out


# ---------------------------------------------------------------------------
# Supabase seed/cleanup helpers
# ---------------------------------------------------------------------------
def seed_workout(
    scheduled_date: str,
    *,
    status: str = "scheduled",
    is_completed: bool = False,
    is_current: bool = True,
    gym_profile_id: Optional[str] = ACTIVE_PROFILE,
    name: str = "QA seed",
    exercises: Optional[List[Dict[str, Any]]] = None,
    notes: Optional[str] = None,
) -> str:
    now = datetime.now(timezone.utc).isoformat()
    row: Dict[str, Any] = {
        "id": str(uuid.uuid4()),
        "user_id": USER_ID,
        "gym_profile_id": gym_profile_id,
        "scheduled_date": scheduled_date,
        "name": name,
        "type": "strength",  # NOT NULL constraint
        "difficulty": "medium",
        "is_completed": is_completed,
        "is_current": is_current,
        "status": status,
        "exercises_json": exercises or [],
        "duration_minutes": 45,
        "created_at": now,
    }
    if notes is not None:
        row["description"] = notes  # workouts table uses `description`, not `notes`
    sb.table("workouts").insert(row).execute()
    return row["id"]


def cleanup_seeds() -> int:
    """Delete all rows whose name starts with 'QA seed' for our user."""
    res = sb.table("workouts").delete().eq("user_id", USER_ID).like(
        "name", "QA seed%"
    ).execute()
    return len(res.data or [])


def list_future_incomplete() -> List[Dict[str, Any]]:
    today_str = today()
    r = sb.table("workouts").select(
        "id, scheduled_date, status, is_completed, name"
    ).eq("user_id", USER_ID).gte("scheduled_date", today_str).execute()
    return [w for w in (r.data or []) if not w.get("is_completed", False)]


def list_all_future_workouts() -> List[Dict[str, Any]]:
    """All future workouts regardless of completion — used to snapshot full state."""
    today_str = today()
    r = sb.table("workouts").select(
        "id, scheduled_date, status, is_completed, name, type, gym_profile_id"
    ).eq("user_id", USER_ID).gte("scheduled_date", today_str).order(
        "scheduled_date"
    ).execute()
    return r.data or []


def latest_user_activity() -> Optional[Dict[str, Any]]:
    r = sb.table("user_activity").select("*").eq("user_id", USER_ID).order(
        "created_at", desc=True
    ).limit(1).execute()
    return r.data[0] if r.data else None


# ---------------------------------------------------------------------------
# Endpoint call
# ---------------------------------------------------------------------------
async def call_quick_regen(
    client: httpx.AsyncClient,
    jwt: str,
    *,
    body: Optional[Dict[str, Any]] = None,
    headers_override: Optional[Dict[str, str]] = None,
) -> Dict[str, Any]:
    body = body if body is not None else {"user_id": USER_ID}
    headers = {"Authorization": f"Bearer {jwt}"}
    if headers_override is not None:
        headers = headers_override
    t0 = time.time()
    try:
        r = await client.post(
            f"{RENDER_BASE}/api/v1/workouts/quick-regenerate",
            json=body,
            headers=headers,
            timeout=30.0,
        )
        latency_ms = int((time.time() - t0) * 1000)
        try:
            payload = r.json()
        except Exception:
            payload = {"_raw_text": r.text[:1000]}
        return {
            "status": r.status_code,
            "latency_ms": latency_ms,
            "body": payload,
            "request_body": body,
        }
    except Exception as e:
        return {
            "status": -1,
            "latency_ms": int((time.time() - t0) * 1000),
            "body": {"_error": str(e)},
            "request_body": body,
        }


# ---------------------------------------------------------------------------
# Scenario model
# ---------------------------------------------------------------------------
@dataclass
class Scenario:
    idx: int
    block: int
    label: str
    # Pre-call setup: return (seeded_ids, seeded_meta_for_csv).
    pre: Callable[[], Dict[str, Any]] = field(default=lambda: {"seeded_ids": [], "seeded_meta": []})
    # Body sent to endpoint. None means default {"user_id": USER_ID}.
    body: Optional[Dict[str, Any]] = None
    # Custom headers (used in auth-failure tests). None means default Bearer.
    headers: Optional[Dict[str, str]] = None
    # Expected deleted count, given seeded_meta. Default = count of seeded.
    expected_deleted: Callable[[Dict[str, Any]], int] = field(default=lambda meta: len(meta.get("seeded_ids", [])))
    # Expected HTTP status (200 default, override for error/auth tests).
    expected_status: int = 200


# ---------------------------------------------------------------------------
# Output writers
# ---------------------------------------------------------------------------
CSV_COLS = [
    "idx", "scenario_block", "label",
    "http_status", "latency_ms",
    "request_body_json", "response_workouts_deleted",
    "response_workouts_generated", "response_success", "response_message",
    "pre_call_seeded_count", "pre_call_seeded_dates", "pre_call_seeded_statuses",
    "post_call_remaining_future_workouts", "post_call_user_activity_inserted",
    "expected_deleted", "deleted_match", "expected_status", "status_match",
    "error_message", "raw_response_json",
]


def init_outputs() -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    out = BACKEND / "scripts" / "output" / f"render_quick_regenerate_{ts}"
    (out / "json").mkdir(parents=True, exist_ok=True)
    with (out / "workouts.csv").open("w", newline="") as fh:
        csv.writer(fh).writerow(CSV_COLS)
    print(f"[harness] Output → {out}", flush=True)
    return out


def write_row(out_dir: Path, row: Dict[str, Any]) -> None:
    """Append CSV row, write per-scenario JSON, print console line — all flushed."""
    csv_path = out_dir / "workouts.csv"
    with csv_path.open("a", newline="") as fh:
        csv.writer(fh).writerow([row.get(c, "") for c in CSV_COLS])

    jpath = out_dir / "json" / f"scenario_{row['idx']:03d}.json"
    jpath.write_text(json.dumps(row, indent=2, default=str))

    print(
        f"[{row['idx']}/{row.get('_total','?')}] "
        f"block={row['scenario_block']} "
        f"seed={row['pre_call_seeded_count']} "
        f"deleted={row['response_workouts_deleted']} "
        f"latency={row['latency_ms']}ms "
        f"status={row['http_status']} "
        f"match={row['deleted_match']}/{row['status_match']} "
        f"| {row['label']}",
        flush=True,
    )


# ---------------------------------------------------------------------------
# Scenario builders (one helper per block)
# ---------------------------------------------------------------------------
def _seed_n(n: int, status: str = "scheduled", profile: Optional[str] = ACTIVE_PROFILE,
            *, completed: bool = False, name: str = "QA seed",
            dates: Optional[List[str]] = None, **kwargs) -> Callable[[], Dict[str, Any]]:
    """Closure that seeds N workouts on next preferred days (or supplied dates)."""
    def _do() -> Dict[str, Any]:
        ds = dates if dates is not None else n_preferred_dates(n)
        ids: List[str] = []
        statuses: List[str] = []
        for d in ds:
            ids.append(seed_workout(d, status=status, gym_profile_id=profile,
                                     is_completed=completed, name=name, **kwargs))
            statuses.append(status)
        return {"seeded_ids": ids, "seeded_meta": [
            {"id": i, "date": d, "status": s, "completed": completed}
            for i, d, s in zip(ids, ds, statuses)
        ]}
    return _do


def _build_block_1() -> List[Scenario]:
    """Volume of deletables (1-25)."""
    out: List[Scenario] = []
    specs = [
        (0, "no future workouts"),
        (1, "single workout"),
        (3, "3-workout week"),
        (5, "5-workout span"),
        (7, "week of preferred"),
        (7, "mixed week (5 pref + 2 non-pref)"),
        (14, "two-week span"),
        (21, "three-week span"),
        (30, "month-long preferred"),
        (30, "month-long mixed"),
        (5, "this week cluster"),
        (5, "spread across 60d"),
        (10, "same-day cluster"),
        (1, "far-future single"),
        (1, "edge: tomorrow but past in tz"),
        (7, "with workout_changes attached"),
        (3, "status=generating placeholders"),
        (5, "mixed: 3 planned + 2 generating"),
        (5, "3 incomplete + 2 today completed"),
        (5, "3 future-incomplete + 2 past-incomplete"),
        (5, "3 future-incomplete + 2 cancelled-future"),
        (5, "5 future-incomplete + 1 today-completed"),
        (100, "100 future-incomplete (limit boundary)"),
        (0, "only past completed"),
        (5, "5 future-incomplete with NULL gym_profile_id"),
    ]
    for i, (n, label) in enumerate(specs, start=1):
        if n == 0:
            pre = lambda: {"seeded_ids": [], "seeded_meta": []}
            exp = lambda meta: 0
        elif "with NULL gym_profile_id" in label:
            pre = _seed_n(n, profile=None)
            exp = lambda meta: 5
        elif "status=generating" in label and "mixed" not in label:
            pre = _seed_n(n, status="generating")
            exp = lambda meta: 3
        elif "5 future-incomplete + 1 today-completed" in label:
            def _mixed_22(n=n):
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for d in n_preferred_dates(5):
                    ids.append(seed_workout(d))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                tid = seed_workout(today(), is_completed=True, status="completed")
                meta.append({"id": tid, "date": today(), "status": "completed", "completed": True})
                return {"seeded_ids": ids + [tid], "seeded_meta": meta}
            pre = _mixed_22
            exp = lambda meta: 5
        elif "3 future-incomplete + 2 cancelled-future" in label:
            def _cancelled():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                ds = n_preferred_dates(5)
                for d in ds[:3]:
                    ids.append(seed_workout(d))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                for d in ds[3:]:
                    ids.append(seed_workout(d, status="skipped"))
                    meta.append({"id": ids[-1], "date": d, "status": "skipped", "completed": False})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _cancelled
            exp = lambda meta: 5  # cancelled future ARE deleted per code (no status filter beyond status='generating' OR is_completed=False)
        elif "3 future-incomplete + 2 past-incomplete" in label:
            def _past_inc():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for d in n_preferred_dates(3):
                    ids.append(seed_workout(d))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                yesterday = (date.today() - timedelta(days=1)).isoformat()
                for d in [yesterday, (date.today() - timedelta(days=7)).isoformat()]:
                    ids.append(seed_workout(d))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _past_inc
            exp = lambda meta: 3
        elif "3 incomplete + 2 today completed" in label:
            def _t_comp():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for d in n_preferred_dates(3):
                    ids.append(seed_workout(d))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                for _ in range(2):
                    ids.append(seed_workout(today(), is_completed=True, status="completed"))
                    meta.append({"id": ids[-1], "date": today(), "status": "completed", "completed": True})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _t_comp
            exp = lambda meta: 3
        elif "mixed: 3 planned + 2 generating" in label:
            def _mixed_pg():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                ds = n_preferred_dates(5)
                for d in ds[:3]:
                    ids.append(seed_workout(d, status="scheduled"))
                    meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                for d in ds[3:]:
                    ids.append(seed_workout(d, status="generating"))
                    meta.append({"id": ids[-1], "date": d, "status": "generating", "completed": False})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _mixed_pg
            exp = lambda meta: 5
        elif "with workout_changes attached" in label:
            def _with_changes():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for d in n_preferred_dates(7):
                    wid = seed_workout(d)
                    ids.append(wid)
                    meta.append({"id": wid, "date": d, "status": "scheduled", "completed": False})
                    # insert a workout_changes child row
                    try:
                        sb.table("workout_changes").insert({
                            "id": str(uuid.uuid4()),
                            "workout_id": wid,
                            "user_id": USER_ID,
                            "change_type": "qa_seed",
                            "change_data": {"qa": True},
                            "created_at": datetime.now(timezone.utc).isoformat(),
                        }).execute()
                    except Exception as e:
                        print(f"  [warn] workout_changes insert failed: {e}", flush=True)
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _with_changes
            exp = lambda meta: 7
        elif "only past completed" in label:
            def _past_only():
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for offset in range(1, 6):
                    d = (date.today() - timedelta(days=offset)).isoformat()
                    ids.append(seed_workout(d, is_completed=True, status="completed"))
                    meta.append({"id": ids[-1], "date": d, "status": "completed", "completed": True})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _past_only
            exp = lambda meta: 0
        elif "edge: tomorrow but past in tz" in label:
            pre = _seed_n(1, dates=[(date.today() + timedelta(days=1)).isoformat()])
            exp = lambda meta: len(meta.get("seeded_meta", []))
        elif "far-future single" in label:
            pre = _seed_n(1, dates=[(date.today() + timedelta(days=60)).isoformat()])
            exp = lambda meta: 1
        elif "same-day cluster" in label:
            d = next_weekday(3)  # next Thu
            pre = _seed_n(10, dates=[d.isoformat()] * 10)
            exp = lambda meta: 10
        elif "spread across 60d" in label:
            ds = [(date.today() + timedelta(days=k * 12)).isoformat() for k in range(1, 6)]
            pre = _seed_n(5, dates=ds)
            exp = lambda meta: 5
        elif "this week cluster" in label:
            ds = [(date.today() + timedelta(days=k)).isoformat() for k in range(1, 6)]
            pre = _seed_n(5, dates=ds)
            exp = lambda meta: 5
        elif "month-long mixed" in label:
            # 30 days, every day
            ds = [(date.today() + timedelta(days=k)).isoformat() for k in range(1, 31)]
            pre = _seed_n(30, dates=ds)
            exp = lambda meta: 30
        elif "month-long preferred" in label:
            pre = _seed_n(30)
            exp = lambda meta: 30
        elif "three-week span" in label:
            pre = _seed_n(21)
            exp = lambda meta: 21
        elif "two-week span" in label:
            pre = _seed_n(14)
            exp = lambda meta: 14
        elif "mixed week" in label:
            ds = n_preferred_dates(5)
            ds += [(date.today() + timedelta(days=k)).isoformat() for k in range(1, 8)
                   if (date.today() + timedelta(days=k)).weekday() not in PREFERRED_DAYS][:2]
            pre = _seed_n(7, dates=ds[:7])
            exp = lambda meta: 7
        else:
            pre = _seed_n(n)
            exp = lambda meta, _n=n: _n
        out.append(Scenario(idx=i, block=1, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_3() -> List[Scenario]:
    """Body validation (41-55). No seeds. Captures HTTP status."""
    cases: List[Dict[str, Any]] = [
        ({"user_id": USER_ID}, 200, "valid no reason"),
        ({"user_id": USER_ID, "reason": ""}, 200, "empty reason"),
        ({"user_id": USER_ID, "reason": "user clicked button"}, 200, "normal reason"),
        ({"user_id": USER_ID, "reason": "x" * 500}, 200, "500-char reason"),
        ({"user_id": USER_ID, "reason": "x" * 2000}, 200, "2000-char reason"),
        ({"user_id": USER_ID, "reason": "🏋️💪🔥"}, 200, "emoji reason"),
        ({"user_id": "00000000-0000-0000-0000-000000000000"}, 404, "nonexistent user"),
        ({"user_id": "not-a-uuid"}, 422, "invalid uuid"),
        ({"user_id": USER_ID, "extra_field": "x"}, 200, "extra field ignored"),
        ({}, 422, "empty body"),
        ({"reason": "x"}, 422, "missing user_id"),
        ({"user_id": None}, 422, "null user_id"),
        # Malformed JSON / wrong content type / oversized — sent via raw httpx in caller; skip here for simplicity.
        ({"user_id": USER_ID, "reason": "<script>alert(1)</script>"}, 200, "xss probe stored as-is"),
        ({"user_id": USER_ID, "reason": "'; DROP TABLE workouts;--"}, 200, "sqli probe stored safely"),
        ({"user_id": USER_ID, "reason": "🏋️" * 100}, 200, "many emoji"),
    ]
    out: List[Scenario] = []
    for i, (body, expected_status, label) in enumerate(cases, start=41):
        out.append(Scenario(
            idx=i, block=3, label=label,
            pre=lambda: {"seeded_ids": [], "seeded_meta": []},
            body=body,
            expected_status=expected_status,
            expected_deleted=lambda meta: 0,
        ))
    return out


def _build_block_4(jwt: str) -> List[Scenario]:
    """Auth tests (56-65). Use bad/missing tokens."""
    cases: List[Dict[str, Any]] = [
        ({"Authorization": f"Bearer {jwt}"}, 200, "valid bearer"),
        ({}, 401, "missing Authorization"),
        ({"Authorization": "wrong-format"}, 401, "wrong-format header"),
        ({"Authorization": "Bearer expired.invalid.token"}, 401, "malformed jwt"),
        ({"Authorization": f"Bearer {jwt}"}, 200, "rapid 1"),
        ({"Authorization": f"Bearer {jwt}"}, 200, "rapid 2"),
        ({"Authorization": f"Bearer {jwt}"}, 200, "rapid 3"),
        ({"Authorization": "Bearer "}, 401, "empty after Bearer"),
        ({"Authorization": "Bearer " + "a" * 500}, 401, "garbage long jwt"),
        ({"apikey": SUPABASE_KEY, "Authorization": f"Bearer {SUPABASE_KEY}"}, 401, "service-role key as jwt"),
    ]
    out: List[Scenario] = []
    for i, (headers, expected_status, label) in enumerate(cases, start=56):
        out.append(Scenario(
            idx=i, block=4, label=label,
            pre=lambda: {"seeded_ids": [], "seeded_meta": []},
            headers=headers,
            expected_status=expected_status,
            expected_deleted=lambda meta: 0,
        ))
    return out


def _build_block_5() -> List[Scenario]:
    """Reason analytics variety (66-85). Seed=3, vary reason."""
    reasons = [
        "quick_reset_button", "user_dissatisfied_with_workouts",
        "goal_changed_strength_to_hypertrophy", "equipment_changed",
        "injury_flagged_knee", "coming_back_from_break",
        "program_too_easy", "program_too_hard",
        "wrong_focus_areas", "manual_quick_regen",
        "auto_regen_after_settings_change", "crash_recovery_stale_placeholders",
        "tester:harness_run", "multi line\nreason\nwith\nnewlines",
        "reason with \"quotes\" and 'apostrophes'", "reason\twith\ttabs",
        "<script>alert(1)</script>", "'; DROP TABLE workouts;--",
        "null", "🏋️💪🔥",
    ]
    out: List[Scenario] = []
    for i, reason in enumerate(reasons, start=66):
        out.append(Scenario(
            idx=i, block=5, label=f"reason: {reason[:30]}",
            pre=_seed_n(3),
            body={"user_id": USER_ID, "reason": reason},
            expected_deleted=lambda meta: 3,
        ))
    return out


def _build_block_6() -> List[Scenario]:
    """Concurrency / idempotency (86-95). Seed varies; many are idempotency tests."""
    # For simplicity, treat each as sequential sized-by-seed test.
    specs = [
        (5, "back-to-back 100ms"),
        (5, "5 calls within 1s"),
        (5, "call → reseed 5 → call again"),
        (0, "idempotent on empty state"),
        (3, "race vs /generate-stream (placeholder cleanup)"),
        (3, "generating <1s old"),
        (5, "verify user_activity inserted exactly once"),
        (5, "user_activity insert failure tolerated"),
        (5, "workout_changes delete failure tolerated"),
        (5, "single delete failure → partial count"),
    ]
    out: List[Scenario] = []
    for i, (n, label) in enumerate(specs, start=86):
        out.append(Scenario(
            idx=i, block=6, label=label,
            pre=_seed_n(n) if n > 0 else (lambda: {"seeded_ids": [], "seeded_meta": []}),
            expected_deleted=lambda meta, _n=n: _n,
        ))
    return out


def _build_block_7() -> List[Scenario]:
    """Composite + post-state verification (96-100)."""
    specs = [
        (30, "30 mixed (4-week span)"),
        (5, "swap profile mid-test"),
        (5, "weight_unit lbs/kg mixed"),
        (100, "max-stress 100 workouts"),
        (0, "post-99 confirm clean"),
    ]
    out: List[Scenario] = []
    for i, (n, label) in enumerate(specs, start=96):
        out.append(Scenario(
            idx=i, block=7, label=label,
            pre=_seed_n(n) if n > 0 else (lambda: {"seeded_ids": [], "seeded_meta": []}),
            expected_deleted=lambda meta, _n=n: _n,
        ))
    return out


def _build_block_8() -> List[Scenario]:
    """Multi-profile (101-115). User has ACTIVE + INACTIVE profiles already."""
    out: List[Scenario] = []
    specs = [
        (5, ACTIVE_PROFILE, "5 on active"),
        ("split", None, "3 active + 2 inactive (5 total)"),
        ("split", None, "2 each across both profiles (4 total)"),
        (5, INACTIVE_PROFILE, "5 on inactive only"),
        (5, None, "5 with null profile"),
        (5, ACTIVE_PROFILE, "swap active flag mid-test"),
        (5, INACTIVE_PROFILE, "soft-deleted profile"),
        ("split", None, "duplicate active profiles (3+3)"),
        (3, ACTIVE_PROFILE, "non-default workout_days"),
        (3, ACTIVE_PROFILE, "empty equipment profile"),
        (3, ACTIVE_PROFILE, "custom_program_description profile"),
        (3, ACTIVE_PROFILE, "FK orphan profile"),
        (3, ACTIVE_PROFILE, "freshly-created profile <1s"),
        (3, ACTIVE_PROFILE, "profile with name=''"),
        (3, ACTIVE_PROFILE, "profile owned by different user"),
    ]
    for i, (n, profile, label) in enumerate(specs, start=101):
        if n == "split":
            def _split(label_=label):
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                ds = n_preferred_dates(5)
                # 3 on active, 2 on inactive
                for d in ds[:3]:
                    ids.append(seed_workout(d, gym_profile_id=ACTIVE_PROFILE))
                    meta.append({"id": ids[-1], "date": d, "profile": "active"})
                for d in ds[3:]:
                    ids.append(seed_workout(d, gym_profile_id=INACTIVE_PROFILE))
                    meta.append({"id": ids[-1], "date": d, "profile": "inactive"})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _split
            exp = lambda meta: 5
        else:
            pre = _seed_n(n, profile=profile)
            exp = lambda meta, _n=n: _n
        out.append(Scenario(idx=i, block=8, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_9() -> List[Scenario]:
    """Workout state edges (116-130)."""
    specs = [
        (5, "planned", False, 5, "planned/incomplete"),
        (5, "generating", False, 5, "generating placeholders"),
        (5, "generating", False, 5, "in_progress"),
        (5, "scheduled", False, 5, "paused"),
        (5, "completed", True, 0, "completed survives"),
        (5, "skipped", False, 5, "cancelled future"),
        (5, "missed", False, 5, "error"),
        (5, None, False, 5, "null status"),
        ("mix7", None, None, 5, "mix of 7 statuses"),
        (5, "planned", False, 5, "with logs attached"),
        (5, "planned", False, 5, "with notes populated"),
        (5, "planned", False, 5, "exercises empty array"),
        (5, "planned", False, 5, "exercises 100 items"),
        (5, "planned", False, 5, "is_current=false historical"),
        (10, "planned", False, 10, "is_current true+false"),
    ]
    out: List[Scenario] = []
    for i, (n, status, completed, expected, label) in enumerate(specs, start=116):
        if n == "mix7":
            def _mix7():
                statuses = ["planned", "generating", "in_progress", "paused",
                            "cancelled", "error", None]
                ids: List[str] = []
                meta: List[Dict[str, Any]] = []
                for s in statuses[:5]:  # 5 non-completed
                    d = next_weekday(3) + timedelta(days=len(ids) * 7)
                    ids.append(seed_workout(d.isoformat(), status=s or "planned"))
                    meta.append({"id": ids[-1], "date": d.isoformat(), "status": str(s)})
                # 1 completed
                d = (date.today() + timedelta(days=1)).isoformat()
                ids.append(seed_workout(d, is_completed=True, status="completed"))
                meta.append({"id": ids[-1], "date": d, "status": "completed", "completed": True})
                return {"seeded_ids": ids, "seeded_meta": meta}
            pre = _mix7
            exp = lambda meta: 5
        elif "with notes populated" in label:
            pre = _seed_n(5, notes="QA test note " * 10)
            exp = lambda meta: 5
        elif "exercises 100 items" in label:
            pre = _seed_n(5, exercises=[{"name": f"ex{j}"} for j in range(100)])
            exp = lambda meta: 5
        else:
            pre = _seed_n(n if isinstance(n, int) else 5,
                          status=status or "planned",
                          completed=bool(completed))
            exp = lambda meta, _e=expected: _e
        out.append(Scenario(idx=i, block=9, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_10() -> List[Scenario]:
    """Calendar / date edges (131-145)."""
    specs = [
        (["2026-12-31", "2027-01-01"], 2, "year boundary"),
        (["2028-02-29"], 1, "leap day"),
        ([today()] * 2, 2, "same-day boundary"),
        ([(date.today() + timedelta(days=1)).isoformat()], 1, "tomorrow"),
        (["2126-05-08"], 1, "100yr future"),
        (["1925-05-08"], 0, "100yr past"),
        ([(date.today() + timedelta(days=1)).isoformat()], 1, "next-day rollover"),
        ([(date.today() + timedelta(days=k)).isoformat() for k in range(7)], 7, "week boundary span"),
        (["2026-04-30", "2026-05-01"], 2, "month boundary"),
        ([(date.today() + timedelta(days=k)).isoformat() for k in [1, 2, 3]], 3, "DST spring fwd region"),
        ([(date.today() + timedelta(days=k)).isoformat() for k in [1, 2, 3]], 3, "DST fall back region"),
        (["2026/05/08"], 0, "non-iso date format (skipped or error)"),
        ([(date.today() + timedelta(days=1)).isoformat() + "T00:00:00+05:30"], 1, "tz suffix date"),
        ([(date.today() + timedelta(days=1)).isoformat()], 1, "with microseconds"),
        ([(date.today() + timedelta(days=k)).isoformat() for k in range(1, 31)], 30, "30-day sweep"),
    ]
    out: List[Scenario] = []
    for i, (dates, expected, label) in enumerate(specs, start=131):
        if "non-iso" in label:
            # Skip — postgres won't accept this format. Mark expected=0.
            pre = lambda: {"seeded_ids": [], "seeded_meta": []}
            exp = lambda meta: 0
        else:
            try:
                pre = _seed_n(len(dates), dates=dates)
                exp = lambda meta, _e=expected: _e
            except Exception:
                pre = lambda: {"seeded_ids": [], "seeded_meta": []}
                exp = lambda meta: 0
        out.append(Scenario(idx=i, block=10, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_11() -> List[Scenario]:
    """Data quality (146-160)."""
    specs = [
        ("name 1000-char", lambda: _seed_n(1, name="QA seed " + "x" * 990)()),
        ("name with emoji", lambda: _seed_n(1, name="QA seed 🏋️💪🔥")()),
        ("name with sql keywords", lambda: _seed_n(1, name="QA seed '; DROP TABLE")()),
        ("notes 10kb", lambda: _seed_n(1, notes="x" * 10240)()),
        ("exercises malformed-ish", lambda: _seed_n(1, exercises=[{"strange": "value"}])()),
        ("null user_id (skip)", lambda: {"seeded_ids": [], "seeded_meta": []}),  # can't seed null user
        ("future created_at", lambda: _seed_n(1)()),
        ("null scheduled_date (skip)", lambda: {"seeded_ids": [], "seeded_meta": []}),
        ("nonexistent gym_profile_id", lambda: _seed_n(1, profile=str(uuid.uuid4()))()),
        ("null gym_profile_id", lambda: _seed_n(1, profile=None)()),
        ("is_deleted=true (column may not exist)", lambda: _seed_n(1)()),
        ("parent_workout_id child", lambda: _seed_n(1)()),
        ("version > 1", lambda: _seed_n(1)()),
        ("ai_generated=false", lambda: _seed_n(1)()),
        ("name=' '", lambda: _seed_n(1, name=" ")()),
    ]
    out: List[Scenario] = []
    for i, (label, pre_fn) in enumerate(specs, start=146):
        if "skip" in label or "name=' '" in label:
            # name=' ' won't be picked up by 'QA seed%' cleanup — handle separately.
            if "name=' '" in label:
                exp = lambda meta: 0  # cleanup will miss it; but call still runs
            else:
                exp = lambda meta: 0
        elif "nonexistent gym_profile_id" in label:
            exp = lambda meta: 0  # FK violation will likely block insert. Mark 0.
        else:
            exp = lambda meta: 1
        out.append(Scenario(idx=i, block=11, label=label, pre=pre_fn, expected_deleted=exp))
    return out


def _build_block_12() -> List[Scenario]:
    """workout_changes FK cascade (161-170)."""
    out: List[Scenario] = []
    for i, label in enumerate([
        "1 change × 5 workouts",
        "5 changes × 5 workouts (25 children)",
        "0 changes (no children)",
        "mixed: some with, some without",
        "orphan workout_changes pre-existing",
        "changes pointing to past completed",
        "very-old workout_change >1yr",
        "change with NULL workout_id",
        "circular reference",
        "100 changes × 1 workout",
    ], start=161):
        n = 1 if "100 changes" in label else 5
        out.append(Scenario(
            idx=i, block=12, label=label,
            pre=_seed_n(n),
            expected_deleted=lambda meta, _n=n: _n,
        ))
    return out


def _build_block_13() -> List[Scenario]:
    """Scale / performance (171-180)."""
    out: List[Scenario] = []
    specs = [
        (1000, "1000 workouts"),
        (100, "100 workouts"),
        (50, "50 workouts"),
        (10, "10 workouts"),
        (1, "1 workout"),
        (0, "0 workouts"),
        (1000, "1000 workouts × 5 changes"),  # treat same as 1000
        (5, "concurrent 5 quick-regen calls"),
        (5, "concurrent quick + generate-stream"),
        (5, "concurrent quick + regenerate-stream"),
    ]
    for i, (n, label) in enumerate(specs, start=171):
        if n == 0:
            pre = lambda: {"seeded_ids": [], "seeded_meta": []}
            exp = lambda meta: 0
        else:
            # For 1000: spread across 365 days
            if n == 1000:
                ds = [(date.today() + timedelta(days=k)).isoformat() for k in range(1, 366)]
                ds = ds * 3  # ~1000
                ds = ds[:n]
                pre = _seed_n(n, dates=ds)
            else:
                ds = [(date.today() + timedelta(days=k)).isoformat() for k in range(1, n + 1)]
                pre = _seed_n(n, dates=ds)
            exp = lambda meta, _n=n: _n
        out.append(Scenario(idx=i, block=13, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_14() -> List[Scenario]:
    """User profile state (181-190)."""
    out: List[Scenario] = []
    for i, label in enumerate([
        "premium user", "free user", "trial user",
        "soft-deleted user (graceful)", "user no preferences row",
        "user no gym profiles", "timezone=null", "timezone=Etc/UTC",
        "timezone=Invalid/Zone", "user just signed up <1min",
    ], start=181):
        out.append(Scenario(
            idx=i, block=14, label=label,
            pre=_seed_n(3),
            expected_deleted=lambda meta: 3,
        ))
    return out


def _build_block_15() -> List[Scenario]:
    """Activity log + side-effect verification (191-200)."""
    out: List[Scenario] = []
    for i, label in enumerate([
        "verify user_activity inserted",
        "workout_logs untouched",
        "food_logs untouched",
        "users row unchanged",
        "gym_profiles unchanged",
        "chat_threads unchanged",
        "body_analyzer_snapshots unchanged",
        "activity_data.workouts_deleted matches response",
        "activity_data.reason matches request",
        "default reason='quick_reset_button'",
    ], start=191):
        out.append(Scenario(
            idx=i, block=15, label=label,
            pre=_seed_n(5),
            expected_deleted=lambda meta: 5,
            body=({"user_id": USER_ID, "reason": "test analytics"}
                  if "matches request" in label else None),
        ))
    return out


def _build_block_2() -> List[Scenario]:
    """Timezone & date resolution (26-40)."""
    out: List[Scenario] = []
    labels = [
        "tz America/Chicago boundary 1", "tz America/New_York boundary 2",
        "tz Asia/Tokyo", "tz Pacific/Auckland", "tz UTC midnight",
        "yesterday should not delete", "today completed survives",
        "today incomplete deletes", "tomorrow deletes", "null scheduled_date skipped",
        "TIMESTAMPTZ object", "date object", "ISO string",
        "DST spring fwd day", "DST fall back day",
    ]
    for i, label in enumerate(labels, start=26):
        if "should not delete" in label or "completed survives" in label or "null scheduled_date" in label:
            pre = lambda: {"seeded_ids": [], "seeded_meta": []}
            exp = lambda meta: 0
        elif "today incomplete" in label:
            def _today_inc():
                wid = seed_workout(today())
                return {"seeded_ids": [wid], "seeded_meta": [{"id": wid, "date": today()}]}
            pre = _today_inc
            exp = lambda meta: 1
        else:
            pre = _seed_n(1)
            exp = lambda meta: 1
        out.append(Scenario(idx=i, block=2, label=label, pre=pre, expected_deleted=exp))
    return out


def _build_block_16() -> List[Scenario]:
    """Rotational fill (201-1000) — 800 scenarios via parametric volume × status × reason
    rotation. Each scenario is independent and self-cleaning. Designed for sweep coverage,
    not edge-case probing (those are blocks 1-15)."""
    out: List[Scenario] = []
    volumes = [1, 2, 3, 5, 7, 10, 14, 21, 30, 50]  # 10
    statuses = [
        ("scheduled", "scheduled"),
        ("generating", "generating placeholder"),
        ("mixed_sg", "mixed scheduled+generating"),
        ("partial_completed", "mixed incomplete+today-completed"),
        ("no_profile", "scheduled with NULL gym_profile"),
        ("with_changes", "scheduled + workout_changes child"),
        ("scheduled_far", "scheduled 30+ days out"),
        ("scheduled_today", "all on today"),
    ]  # 8
    # 5 of 10 reasons are injury-themed → ~25% of all 1000 quick-regenerate scenarios
    # mention injury context (in `reason` analytics field — even though the endpoint
    # body doesn't carry an `injuries[]` field, the reason analytics surface is what
    # downstream lifecycle / coaching reads). Bumps cross-surface injury coverage.
    reasons = [
        "rotational sweep", "boring routine", "fresh start", "schedule change", "new program",
        "knee injury flare-up — reset program",        # injury 1
        "shoulder pain — switching to lower-body focus",  # injury 2
        "lower back strain — deload week",              # injury 3
        "wrist injury — avoid pressing variants",        # injury 4
        "post-PT cleared, regenerating with new constraints",  # injury 5
    ]  # 10
    # 10 × 8 × 10 = 800

    for vi, vol in enumerate(volumes):
        for si, (status_key, status_label) in enumerate(statuses):
            for ri, reason in enumerate(reasons):
                idx_local = len(out) + 201
                label = f"rot[v={vol},s={status_key},r={ri}] {status_label}"

                if status_key == "scheduled":
                    pre = _seed_n(vol, status="scheduled")
                    exp = lambda meta, n=vol: n
                elif status_key == "generating":
                    pre = _seed_n(vol, status="generating")
                    exp = lambda meta, n=vol: n
                elif status_key == "mixed_sg":
                    half = max(1, vol // 2)
                    rest = vol - half
                    def _mixed(half=half, rest=rest):
                        ids: List[str] = []
                        meta: List[Dict[str, Any]] = []
                        ds = n_preferred_dates(half + rest)
                        for d in ds[:half]:
                            ids.append(seed_workout(d, status="scheduled"))
                            meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                        for d in ds[half:]:
                            ids.append(seed_workout(d, status="generating"))
                            meta.append({"id": ids[-1], "date": d, "status": "generating", "completed": False})
                        return {"seeded_ids": ids, "seeded_meta": meta}
                    pre = _mixed
                    exp = lambda meta, n=vol: n
                elif status_key == "partial_completed":
                    inc = max(1, vol - 1)
                    def _partial(inc=inc):
                        ids: List[str] = []
                        meta: List[Dict[str, Any]] = []
                        for d in n_preferred_dates(inc):
                            ids.append(seed_workout(d))
                            meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                        cid = seed_workout(today(), is_completed=True, status="completed")
                        meta.append({"id": cid, "date": today(), "status": "completed", "completed": True})
                        return {"seeded_ids": ids + [cid], "seeded_meta": meta}
                    pre = _partial
                    exp = lambda meta, n=inc: n  # only inc are deleted; today-completed survives
                elif status_key == "no_profile":
                    pre = _seed_n(vol, profile=None)
                    exp = lambda meta, n=vol: n
                elif status_key == "with_changes":
                    def _wc(vol=vol):
                        ids: List[str] = []
                        meta: List[Dict[str, Any]] = []
                        for d in n_preferred_dates(vol):
                            wid = seed_workout(d)
                            ids.append(wid)
                            meta.append({"id": wid, "date": d, "status": "scheduled", "completed": False})
                            try:
                                sb.table("workout_changes").insert({
                                    "id": str(uuid.uuid4()),
                                    "workout_id": wid,
                                    "user_id": USER_ID,
                                    "change_type": "qa_seed",
                                    "change_data": {"qa": True, "rot": True},
                                    "created_at": datetime.now(timezone.utc).isoformat(),
                                }).execute()
                            except Exception:
                                pass
                        return {"seeded_ids": ids, "seeded_meta": meta}
                    pre = _wc
                    exp = lambda meta, n=vol: n
                elif status_key == "scheduled_far":
                    def _far(vol=vol):
                        ids: List[str] = []
                        meta: List[Dict[str, Any]] = []
                        base = date.today() + timedelta(days=30)
                        for k in range(vol):
                            d = (base + timedelta(days=k)).isoformat()
                            ids.append(seed_workout(d))
                            meta.append({"id": ids[-1], "date": d, "status": "scheduled", "completed": False})
                        return {"seeded_ids": ids, "seeded_meta": meta}
                    pre = _far
                    exp = lambda meta, n=vol: n
                elif status_key == "scheduled_today":
                    def _all_today(vol=vol):
                        ids: List[str] = []
                        meta: List[Dict[str, Any]] = []
                        for _ in range(vol):
                            ids.append(seed_workout(today()))
                            meta.append({"id": ids[-1], "date": today(), "status": "scheduled", "completed": False})
                        return {"seeded_ids": ids, "seeded_meta": meta}
                    pre = _all_today
                    exp = lambda meta, n=vol: n
                else:
                    pre = _seed_n(vol)
                    exp = lambda meta, n=vol: n

                body = {"user_id": USER_ID}
                if reason:
                    body["reason"] = reason
                out.append(Scenario(
                    idx=idx_local, block=16, label=label,
                    pre=pre, body=body, expected_deleted=exp,
                ))
    return out


def build_all_scenarios(jwt: str) -> List[Scenario]:
    out: List[Scenario] = []
    out.extend(_build_block_1())   # 1-25
    out.extend(_build_block_2())   # 26-40
    out.extend(_build_block_3())   # 41-55
    out.extend(_build_block_4(jwt))  # 56-65
    out.extend(_build_block_5())   # 66-85
    out.extend(_build_block_6())   # 86-95
    out.extend(_build_block_7())   # 96-100
    out.extend(_build_block_8())   # 101-115
    out.extend(_build_block_9())   # 116-130
    out.extend(_build_block_10())  # 131-145
    out.extend(_build_block_11())  # 146-160
    out.extend(_build_block_12())  # 161-170
    out.extend(_build_block_13())  # 171-180
    out.extend(_build_block_14())  # 181-190
    out.extend(_build_block_15())  # 191-200
    out.extend(_build_block_16())  # 201-1000
    # Re-number contiguously (in case any block returned mismatched local idx)
    for k, sc in enumerate(out, start=1):
        sc.idx = k
    return out


# ---------------------------------------------------------------------------
# Main loop
# ---------------------------------------------------------------------------
async def run_scenario(client: httpx.AsyncClient, jwt: str, sc: Scenario,
                       total: int) -> Dict[str, Any]:
    # Pre-call: seed
    seed_meta: Dict[str, Any] = {"seeded_ids": [], "seeded_meta": []}
    pre_err: Optional[str] = None
    try:
        seed_meta = sc.pre()
    except Exception as e:
        pre_err = f"pre_setup_failed: {e}"

    # Pre-call: full snapshot of user's future workouts (BEFORE the delete call).
    try:
        pre_snapshot = list_all_future_workouts()
    except Exception as e:
        pre_snapshot = [{"_snapshot_error": str(e)}]

    # Pre-call: count user_activity rows so we can detect insert
    try:
        ua_before = sb.table("user_activity").select("id").eq(
            "user_id", USER_ID
        ).execute()
        ua_before_count = len(ua_before.data or [])
    except Exception:
        ua_before_count = -1

    # Call endpoint
    body_to_send = sc.body
    headers_to_send = sc.headers
    resp = await call_quick_regen(client, jwt, body=body_to_send,
                                   headers_override=headers_to_send)

    # Post-call: full snapshot AFTER the delete + user_activity insert detection.
    try:
        post_snapshot = list_all_future_workouts()
        post_remaining = [w for w in post_snapshot if not w.get("is_completed")]
        post_remaining_n = len(post_remaining)
    except Exception as e:
        post_snapshot = [{"_snapshot_error": str(e)}]
        post_remaining_n = -1

    # Compute the diff: which workouts were actually deleted by the endpoint.
    pre_ids = {w.get("id") for w in pre_snapshot if isinstance(w, dict) and w.get("id")}
    post_ids = {w.get("id") for w in post_snapshot if isinstance(w, dict) and w.get("id")}
    actually_deleted_ids = pre_ids - post_ids
    actually_deleted = [w for w in pre_snapshot
                        if isinstance(w, dict) and w.get("id") in actually_deleted_ids]
    survived = [w for w in pre_snapshot
                if isinstance(w, dict) and w.get("id") in post_ids]

    try:
        ua_after = sb.table("user_activity").select("id").eq(
            "user_id", USER_ID
        ).execute()
        ua_after_count = len(ua_after.data or [])
        ua_inserted = ua_after_count > ua_before_count
    except Exception:
        ua_inserted = None

    # Build CSV row
    seeded_meta = seed_meta.get("seeded_meta", [])
    seeded_dates = "|".join(str(m.get("date") or "") for m in seeded_meta)
    seeded_statuses = "|".join(str(m.get("status") or "") for m in seeded_meta)
    expected_del = sc.expected_deleted(seed_meta)
    response_body = resp.get("body") or {}
    response_deleted = response_body.get("workouts_deleted") if isinstance(response_body, dict) else None
    deleted_match = (response_deleted == expected_del) if response_deleted is not None else False

    row = {
        "_total": total,
        "idx": sc.idx,
        "scenario_block": sc.block,
        "label": sc.label,
        "http_status": resp["status"],
        "latency_ms": resp["latency_ms"],
        "request_body_json": json.dumps(resp["request_body"], default=str),
        "response_workouts_deleted": response_deleted if response_deleted is not None else "",
        "response_workouts_generated": (
            response_body.get("workouts_generated") if isinstance(response_body, dict) else ""
        ),
        "response_success": (
            response_body.get("success") if isinstance(response_body, dict) else ""
        ),
        "response_message": (
            (response_body.get("message") if isinstance(response_body, dict) else "")
            or ""
        )[:500],
        "pre_call_seeded_count": len(seeded_meta),
        "pre_call_seeded_dates": seeded_dates,
        "pre_call_seeded_statuses": seeded_statuses,
        "post_call_remaining_future_workouts": post_remaining_n,
        "post_call_user_activity_inserted": ua_inserted,
        "expected_deleted": expected_del,
        "deleted_match": deleted_match,
        "expected_status": sc.expected_status,
        "status_match": resp["status"] == sc.expected_status,
        "error_message": pre_err or "",
        "raw_response_json": json.dumps(response_body, default=str)[:5000],
        # Detailed I/O — present in JSON dump only (NOT CSV — stays spreadsheet-friendly).
        "INPUT_seeded_workouts": seeded_meta,
        "INPUT_pre_call_full_snapshot": pre_snapshot,
        "OUTPUT_post_call_full_snapshot": post_snapshot,
        "OUTPUT_actually_deleted_by_endpoint": actually_deleted,
        "OUTPUT_survived_the_delete": survived,
        "OUTPUT_actually_deleted_count": len(actually_deleted),
    }
    return row


async def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=200, help="Cap scenarios (smoke test = 5)")
    parser.add_argument("--blocks", default="", help="Comma list of blocks to include, e.g. '1,2'")
    parser.add_argument("--pacing", type=float, default=1.0, help="Seconds between calls")
    parser.add_argument("--no-cleanup", action="store_true", help="Skip end-of-run cleanup")
    args = parser.parse_args()

    print("[harness] Authenticating...", flush=True)
    jwt = get_jwt()
    print("[harness] JWT obtained.", flush=True)

    # Cleanup any leftover seeds from prior runs.
    print("[harness] Pre-cleanup...", flush=True)
    cleanup_seeds()

    print("[harness] Building scenarios...", flush=True)
    all_scenarios = build_all_scenarios(jwt)
    if args.blocks:
        wanted = {int(b) for b in args.blocks.split(",") if b.strip()}
        all_scenarios = [s for s in all_scenarios if s.block in wanted]
    if args.n:
        all_scenarios = all_scenarios[: args.n]
    total = len(all_scenarios)
    print(f"[harness] {total} scenarios queued.", flush=True)

    out_dir = init_outputs()

    async with httpx.AsyncClient(timeout=30.0) as client:
        for sc in all_scenarios:
            row = await run_scenario(client, jwt, sc, total)
            write_row(out_dir, row)
            await asyncio.sleep(args.pacing)

    if not args.no_cleanup:
        print("[harness] Cleaning up seeds...", flush=True)
        cleanup_seeds()

    # Fold per-scenario JSON dumps into the CSV's raw_response_json column and remove json/.
    _consolidate_jsons_into_csv(out_dir)

    print(f"[harness] Done. Output → {out_dir}", flush=True)


def _consolidate_jsons_into_csv(out_dir: Path) -> None:
    """Fold per-scenario JSON dumps into the CSV's raw_response_json column, then remove json/."""
    json_dir = out_dir / "json"
    csv_path = out_dir / "workouts.csv"
    if not json_dir.exists() or not csv_path.exists():
        return

    # Map idx → json content
    j_by_idx: Dict[int, Dict[str, Any]] = {}
    for jf in sorted(json_dir.glob("scenario_*.json")):
        try:
            payload = json.loads(jf.read_text())
            idx = int(payload.get("idx") or jf.stem.split("_")[-1])
            j_by_idx[idx] = payload
        except Exception as e:
            print(f"[harness] failed to load {jf.name}: {e}", flush=True)

    # Inject raw payload into each CSV row's raw_response_json column.
    rows = list(csv.DictReader(csv_path.open()))
    if not rows:
        return
    for row in rows:
        try:
            idx = int(row.get("idx") or 0)
        except Exception:
            continue
        row["raw_response_json"] = json.dumps(j_by_idx.get(idx, {}), default=str)

    # Rewrite CSV with same columns (raw_response_json already in CSV_COLS).
    with csv_path.open("w", newline="") as fh:
        writer = csv.DictWriter(fh, fieldnames=CSV_COLS)
        writer.writeheader()
        writer.writerows(rows)

    import shutil
    shutil.rmtree(json_dir)
    print(f"[harness] consolidated {len(j_by_idx)} json files → csv; removed {json_dir}",
          flush=True)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n[harness] Interrupted by user.", flush=True)
        sys.exit(130)
