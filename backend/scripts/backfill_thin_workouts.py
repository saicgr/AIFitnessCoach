"""Remediate existing thin / malformed workouts (one-off, idempotent).

Three independent fixes:
  1. THIN: current/future generated workouts whose distinct exercise count is
     below their duration/type floor. Backfilled via the SAME completeness
     terminal stage (`services.workout_completeness.ensure_complete_workout`,
     real RAG) and UPDATEd in place — no full regeneration, no Gemini cost,
     ids/dates preserved.
  2. STRING: rows whose `exercises_json` is double-encoded as a JSON string;
     re-parsed to a real array (handled by the companion SQL, see module docs).
  3. DUPS: handled by the companion SQL.

Usage (read-only diagnostics OK without flags):
    .venv/bin/python scripts/backfill_thin_workouts.py --check          # dry run
    .venv/bin/python scripts/backfill_thin_workouts.py --apply          # write
    .venv/bin/python scripts/backfill_thin_workouts.py --apply --email reviewer@zealova.com

Idempotent: re-running after a successful pass finds nothing to do.
"""

from __future__ import annotations

import argparse
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from dotenv import load_dotenv  # noqa: E402

load_dotenv(Path(__file__).resolve().parent.parent / ".env")

from core.db import get_supabase_db  # noqa: E402
from api.v1.workouts.exercise_target import (  # noqa: E402
    target_exercise_count,
    min_exercise_floor,
)
from services.workout_completeness import (  # noqa: E402
    ensure_complete_workout,
    distinct_count,
)
from services.exercise_rag.service import get_exercise_rag_service  # noqa: E402

_BW = {"bodyweight", "body weight", "none", "no_equipment", ""}


def _distinct(exs) -> int:
    if not isinstance(exs, list):
        return -1
    return len({
        (e.get("name") or "").strip().lower()
        for e in exs
        if isinstance(e, dict) and (e.get("name") or "").strip()
    })


async def main(apply: bool, email_filter: str | None) -> None:
    db = get_supabase_db()
    rag = get_exercise_rag_service()

    # --- target users -------------------------------------------------------
    users_resp = db.client.table("users").select("id, email, fitness_level, goals").execute()
    users = {u["id"]: u for u in (users_resp.data or [])}

    # --- candidate workouts: current, future, non-terminal ------------------
    from datetime import date
    today = date.today().isoformat()
    wresp = (
        db.client.table("workouts")
        .select("id, user_id, name, type, duration_minutes, exercises_json, gym_profile_id, scheduled_date, status, is_current")
        .eq("is_current", True)
        .gte("scheduled_date", today)
        .execute()
    )
    rows = [
        r for r in (wresp.data or [])
        if (r.get("status") or "") not in ("completed", "skipped", "archived", "cancelled")
    ]

    # gym profile equipment cache
    gp_cache: dict = {}

    def _equipment_for(gid):
        if not gid:
            return []
        if gid in gp_cache:
            return gp_cache[gid]
        try:
            gp = db.client.table("gym_profiles").select("equipment").eq("id", gid).maybe_single().execute()
            eq = (gp.data or {}).get("equipment") if gp and gp.data else []
            gp_cache[gid] = eq if isinstance(eq, list) else []
        except Exception:
            gp_cache[gid] = []
        return gp_cache[gid]

    n_thin = 0
    n_fixed = 0
    for r in rows:
        user = users.get(r["user_id"]) or {}
        if email_filter and (user.get("email") or "").lower() != email_filter.lower():
            continue
        exs = r.get("exercises_json")
        if not isinstance(exs, list):
            continue  # string/scalar rows handled by SQL companion
        level = (user.get("fitness_level") or "intermediate")
        wtype = "strength"  # these generated splits are strength sessions
        focus = (r.get("type") or "full_body")
        dur = r.get("duration_minutes") or 45
        floor = min_exercise_floor(dur, level, wtype)
        have = _distinct(exs)
        if have < 0 or have >= floor:
            continue
        n_thin += 1
        target = target_exercise_count(dur, level, wtype)
        equip = _equipment_for(r.get("gym_profile_id"))
        goals = user.get("goals")
        if isinstance(goals, str):
            import json as _json
            try:
                goals = _json.loads(goals)
            except Exception:
                goals = []
        print(
            f"  THIN {user.get('email','?'):24s} {str(r.get('scheduled_date'))[:10]} "
            f"{dur}m {focus:10s} have={have} floor={floor} target={target} | {r.get('name')}"
        )
        if not apply:
            continue
        new_exs, reason = await ensure_complete_workout(
            exs,
            target=target,
            floor=floor,
            focus_area=focus,
            equipment=equip if isinstance(equip, list) else [],
            fitness_level=level,
            goals=goals if isinstance(goals, list) else [],
            workout_type=wtype,
            reserve_pool=None,
            candidate_pool_size=have,
            user_id=str(r["user_id"]),
            rag_service=rag,
        )
        new_have = distinct_count(new_exs)
        db.client.table("workouts").update({
            "exercises_json": new_exs,
            "is_degraded": bool(reason),
            "degraded_reason": reason,
        }).eq("id", r["id"]).execute()
        n_fixed += 1
        print(f"      -> fixed to {new_have} exercise(s) (is_degraded={bool(reason)}, reason={reason})")

    print(f"\nSummary: {n_thin} thin workout(s) found, {n_fixed} updated "
          f"({'APPLIED' if apply else 'dry-run'}).")


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="write changes (default: dry run)")
    ap.add_argument("--email", default=None, help="limit to one user email")
    args = ap.parse_args()
    asyncio.run(main(apply=args.apply, email_filter=args.email))
