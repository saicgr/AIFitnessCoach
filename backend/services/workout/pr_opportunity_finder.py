"""
PR opportunity finder for the home workout card.

Plan: §1b.5.

For each primary exercise in today's workout, look up the user's best
recent top set in `personal_records` and propose a single target the user
could realistically hit today:

  - +5% weight @ (reps - 2)  OR
  - same weight @ (reps + 1)

We pick whichever yields the higher Epley e1RM. Confidence is bucketed
by how recent + how heavy the baseline is.

Returns the highest-confidence single opportunity across today's
exercises, or None when no exercise has enough history to ground a real
target. We NEVER fabricate when history is missing — per CLAUDE.md no
silent fallbacks.

Cache: `pr_opportunity_today` (migration 2097), keyed by
(user_id, workout_id, local_date). One row per day.
"""
from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

logger = logging.getLogger("pr_opportunity_finder")


def _epley(weight_kg: float, reps: int) -> float:
    return float(weight_kg) * (1.0 + int(reps) / 30.0)


def _fmt_weight(w: float) -> str:
    return f"{int(w)}" if float(w).is_integer() else f"{round(float(w), 1)}"


def _confidence(days_since_top: int, weight_kg: float) -> str:
    """Heuristic — recent + heavy → high; old or light → low."""
    if days_since_top <= 14 and weight_kg >= 40:
        return "high"
    if days_since_top <= 30:
        return "medium"
    return "low"


def _primary_exercise_names(today_workout: Dict[str, Any], cap: int = 8) -> List[str]:
    exs = today_workout.get("exercises_json") or today_workout.get("exercises") or []
    names: List[str] = []
    if isinstance(exs, list):
        for ex in exs:
            if not isinstance(ex, dict):
                continue
            name = ex.get("name")
            if name and isinstance(name, str):
                names.append(name)
            if len(names) >= cap:
                break
    return names


def find_pr_opportunity(user_id: str,
                        today_workout: Optional[Dict[str, Any]],
                        history_snapshot: Optional[Dict[str, Any]] = None,
                        sb: Any = None) -> Optional[Dict[str, Any]]:
    """Return `{exercise_name, current_top, target, confidence}` or None.

    `sb` is a `get_supabase_db()` handle; if omitted we acquire one. The
    `history_snapshot` arg is accepted (for callers that already have it)
    but currently we re-query `personal_records` directly — a future
    optimisation can read the snapshot's `pr_opportunity_today` field
    when both surfaces agree.
    """
    if not today_workout:
        return None
    names = _primary_exercise_names(today_workout)
    if not names:
        return None

    try:
        if sb is None:
            from core.db import get_supabase_db
            sb = get_supabase_db()

        pr = sb.client.table("personal_records").select(
            "exercise_name, weight_kg, reps, estimated_1rm_kg, achieved_at"
        ).eq("user_id", user_id).in_("exercise_name", names).order(
            "achieved_at", desc=True
        ).limit(100).execute()

        # Best-by-exercise: pick the heaviest e1RM in the most recent 60d.
        best_by_name: Dict[str, Dict[str, Any]] = {}
        cutoff = datetime.now(timezone.utc) - timedelta(days=60)
        for p in (pr.data or []):
            name = p.get("exercise_name")
            w = p.get("weight_kg")
            r = p.get("reps")
            ts_raw = p.get("achieved_at")
            if not (name and w and r and ts_raw):
                continue
            try:
                ts = datetime.fromisoformat(ts_raw.replace("Z", "+00:00"))
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
            except Exception:
                continue
            if ts < cutoff:
                continue
            e1rm = float(p.get("estimated_1rm_kg") or _epley(float(w), int(r)))
            cur = best_by_name.get(name)
            if not cur or e1rm > cur["e1rm"]:
                best_by_name[name] = {
                    "weight_kg": float(w),
                    "reps": int(r),
                    "e1rm": e1rm,
                    "achieved_at": ts,
                }

        if not best_by_name:
            return None

        # Rank candidates by projected new e1RM, then recency.
        candidates: List[Dict[str, Any]] = []
        now = datetime.now(timezone.utc)
        for name, top in best_by_name.items():
            w = top["weight_kg"]
            r = top["reps"]
            opt_a_w = round(w * 1.05 * 2) / 2.0   # +5% weight, nearest 0.5
            opt_a_r = max(1, r - 2)
            opt_a_e1rm = _epley(opt_a_w, opt_a_r)
            opt_b_w = w
            opt_b_r = r + 1
            opt_b_e1rm = _epley(opt_b_w, opt_b_r)
            if opt_a_e1rm >= opt_b_e1rm:
                tgt_w, tgt_r, tgt_e1rm = opt_a_w, opt_a_r, opt_a_e1rm
            else:
                tgt_w, tgt_r, tgt_e1rm = opt_b_w, opt_b_r, opt_b_e1rm

            # Skip degenerate targets that aren't progress.
            if tgt_e1rm <= top["e1rm"]:
                continue

            days_since = (now - top["achieved_at"]).days
            conf = _confidence(days_since, w)
            candidates.append({
                "exercise_name": name,
                "current_top": f"{_fmt_weight(w)}x{r}",
                "target": f"{_fmt_weight(tgt_w)}x{tgt_r}",
                "confidence": conf,
                "_e1rm": tgt_e1rm,
                "_days_since": days_since,
            })

        if not candidates:
            return None

        conf_rank = {"high": 3, "medium": 2, "low": 1}
        candidates.sort(key=lambda c: (
            conf_rank.get(c["confidence"], 0),
            -c["_days_since"],
            c["_e1rm"],
        ), reverse=True)

        pick = candidates[0]
        return {
            "exercise_name": pick["exercise_name"],
            "current_top": pick["current_top"],
            "target": pick["target"],
            "confidence": pick["confidence"],
        }
    except Exception as e:
        logger.warning(f"[pr_opportunity_finder] lookup failed: {e}")
        return None


# ---------------------------------------------------------------------------
# Cache helpers (migration 2097 — pr_opportunity_today)
# ---------------------------------------------------------------------------
def get_cached_pr_opportunity(sb, user_id: str, workout_id: str,
                              local_date: date) -> Optional[Dict[str, Any]]:
    try:
        cr = sb.client.table("pr_opportunity_today").select(
            "exercise_name, current_top, target, confidence, generated_at"
        ).eq("user_id", user_id).eq(
            "workout_id", workout_id
        ).eq("local_date", local_date.isoformat()).maybe_single().execute()
        if cr and cr.data:
            row = cr.data
            return {
                "exercise_name": row.get("exercise_name"),
                "current_top": row.get("current_top"),
                "target": row.get("target"),
                "confidence": row.get("confidence"),
            }
    except Exception as e:
        logger.warning(f"[pr_opportunity_finder] cache lookup failed: {e}")
    return None


def persist_pr_opportunity(sb, user_id: str, workout_id: str,
                           local_date: date,
                           opportunity: Dict[str, Any]) -> bool:
    """Upsert the day's PR opportunity. Returns True on success."""
    if not opportunity or not user_id or not workout_id:
        return False
    try:
        payload = {
            "user_id": user_id,
            "workout_id": workout_id,
            "local_date": local_date.isoformat(),
            "exercise_name": opportunity["exercise_name"],
            "current_top": opportunity["current_top"],
            "target": opportunity["target"],
            "confidence": opportunity["confidence"],
        }
        sb.client.table("pr_opportunity_today").upsert(
            payload, on_conflict="user_id,workout_id,local_date"
        ).execute()
        return True
    except Exception as e:
        logger.warning(f"[pr_opportunity_finder] persist failed: {e}")
        return False
