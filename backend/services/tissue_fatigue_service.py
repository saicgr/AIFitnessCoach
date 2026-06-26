"""Per-joint/tissue fatigue ledger (Dr-Yaad audit #4).

Accumulates the per-exercise `tissue_stress` (migration 2290) into a per-user,
per-tissue running load (table `tissue_fatigue`, migration 2291) with an
exponential half-life decay, so the engine can SEE tissue load building across
exercises that share a stress profile — elbows/wrists/tendons getting hot before
they flare — not just per-muscle volume.

Load model: one logged set of an exercise adds `tissue_stress[tissue]` points to
that tissue. A 4-set movement at shoulder-stress 3 adds 12 to the shoulder. Old
load decays with a 3-day half-life, so a hard week shows up and a rest week cools
down. `get_tissue_fatigue` returns BOTH the raw decayed load and a 0–100
normalized "heat" for display (soft cap below).

Fail-open everywhere: a missing profile or a DB hiccup never blocks a workout.
"""
from __future__ import annotations

import logging
import math
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db

logger = logging.getLogger("tissue_fatigue")

_HALF_LIFE_DAYS = 3.0
# Raw load that reads as "100% hot". Tuned so a heavy week of pressing
# (~4 sessions × 4 sets × stress 3, decayed) lands near the top of the band.
_HEAT_SOFT_CAP = 60.0
_VALID_TISSUES = {
    "shoulder", "elbow", "wrist", "knee", "hip", "lumbar", "ankle",
    "achilles", "neck",
}


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _decay(load: float, updated_at: Any, now: Optional[datetime] = None) -> float:
    """Exponential half-life decay of a stored load to `now`."""
    now = now or _now()
    if not updated_at:
        return load
    try:
        if isinstance(updated_at, str):
            ts = datetime.fromisoformat(updated_at.replace("Z", "+00:00"))
        else:
            ts = updated_at
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        days = max(0.0, (now - ts).total_seconds() / 86400.0)
        return load * (0.5 ** (days / _HALF_LIFE_DAYS))
    except Exception:
        return load


def _tissue_stress_for_names(db, names: List[str]) -> Dict[str, Dict[str, int]]:
    """Batch-fetch tissue_stress for exercise names (lower-cased exact match)."""
    if not names:
        return {}
    lowered = list({(n or "").strip().lower() for n in names if n})
    try:
        rows = (
            db.client.table("exercise_library")
            .select("name, tissue_stress")
            .in_("name", [n for n in names if n])
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[tissue] stress lookup failed: {e}")
        return {}
    out: Dict[str, Dict[str, int]] = {}
    for r in rows:
        nm = (r.get("name") or "").strip().lower()
        ts = r.get("tissue_stress")
        if nm in lowered and isinstance(ts, dict):
            out[nm] = {k: int(v) for k, v in ts.items()
                       if k in _VALID_TISSUES and isinstance(v, (int, float))}
    return out


def record_workout_tissue_load(
    user_id: str,
    exercises: List[Dict[str, Any]],
    db=None,
) -> None:
    """Accumulate one completed workout's tissue load into the ledger.

    [exercises] are the workout's exercise dicts ({name, sets, tissue_stress?}).
    Prefers an inline `tissue_stress` (e.g. already enriched) and falls back to a
    batch library lookup. Best-effort; never raises."""
    if not user_id or not exercises:
        return
    db = db or get_supabase_db()
    try:
        # Resolve tissue_stress per exercise (inline first, else library).
        need_lookup = [e.get("name") for e in exercises
                       if isinstance(e, dict) and not e.get("tissue_stress")]
        looked = _tissue_stress_for_names(db, need_lookup) if need_lookup else {}

        # Sum per-tissue load = stress × sets across the workout.
        delta: Dict[str, float] = {}
        for ex in exercises:
            if not isinstance(ex, dict):
                continue
            ts = ex.get("tissue_stress")
            if not isinstance(ts, dict):
                ts = looked.get((ex.get("name") or "").strip().lower(), {})
            if not ts:
                continue
            try:
                sets = int(ex.get("sets") or 3)
            except (TypeError, ValueError):
                sets = 3
            for tissue, stress in ts.items():
                if tissue in _VALID_TISSUES:
                    delta[tissue] = delta.get(tissue, 0.0) + float(stress) * sets
        if not delta:
            return

        now = _now()
        existing = (
            db.client.table("tissue_fatigue")
            .select("tissue, accumulated_load, updated_at")
            .eq("user_id", user_id)
            .execute()
        ).data or []
        cur = {r["tissue"]: r for r in existing}

        for tissue, add in delta.items():
            prior = cur.get(tissue)
            base = _decay(float(prior["accumulated_load"]), prior["updated_at"], now) \
                if prior else 0.0
            db.client.table("tissue_fatigue").upsert(
                {
                    "user_id": user_id,
                    "tissue": tissue,
                    "accumulated_load": round(base + add, 2),
                    "updated_at": now.isoformat(),
                },
                on_conflict="user_id,tissue",
            ).execute()
    except Exception as e:
        logger.warning(f"[tissue] record failed for user={user_id}: {e}")


def get_tissue_fatigue(user_id: str, db=None) -> Dict[str, Dict[str, float]]:
    """Return {tissue: {"load": decayed_raw, "heat": 0-100}} for the user."""
    if not user_id:
        return {}
    db = db or get_supabase_db()
    try:
        rows = (
            db.client.table("tissue_fatigue")
            .select("tissue, accumulated_load, updated_at")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[tissue] read failed for user={user_id}: {e}")
        return {}
    now = _now()
    out: Dict[str, Dict[str, float]] = {}
    for r in rows:
        load = _decay(float(r["accumulated_load"]), r["updated_at"], now)
        if load < 0.5:
            continue  # cooled down — don't surface noise
        out[r["tissue"]] = {
            "load": round(load, 1),
            "heat": round(min(100.0, load / _HEAT_SOFT_CAP * 100.0), 0),
        }
    return out


def hottest_tissues(user_id: str, threshold_heat: float = 70.0, db=None) -> List[str]:
    """Tissues currently above [threshold_heat] (0–100) — the swap/penalty set."""
    fatigue = get_tissue_fatigue(user_id, db=db)
    return sorted(
        (t for t, v in fatigue.items() if v.get("heat", 0) >= threshold_heat),
        key=lambda t: fatigue[t]["heat"],
        reverse=True,
    )
