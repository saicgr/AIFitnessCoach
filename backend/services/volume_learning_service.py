"""Earned per-user adaptive volume landmarks (Dr-Yaad audit #6).

The static MEV/MAV/MRV constants are population defaults. This service learns a
per-user, per-muscle adjustment from what the body actually did:

  • STRAIN signal — a strain logged for a muscle means the user found their real
    ceiling below the textbook one → pull MRV/MAV down, confidence up.
  • TOLERANCE signal — sustained weeks at/above MAV with NO strain → the user
    tolerates more than the default → nudge MAV/MRV up, confidence up.
  • Conservative where there's no data: confidence stays 0 and consumers fall
    back to the static landmark.

Reads `weekly_volume_tracking` + `strain_history` (migration 110); writes
`user_volume_landmarks` (migration 2292). `get_user_landmarks` is the read path
every consumer should use (it overlays learned values on the static defaults).
All best-effort — never raises into a generation/validation path.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, Optional

from core.db import get_supabase_db
from services.workout_validator_phase2 import VOLUME_LANDMARKS as _STATIC

logger = logging.getLogger("volume_learning")

# How far we ever stray from the population default, either way.
_MIN_FACTOR = 0.6
_MAX_FACTOR = 1.4
# A muscle is "trained hard" in a week when sets ≥ this fraction of MAV.
_HARD_FRACTION = 1.0
_TOLERANCE_WEEKS = 3   # consecutive hard weeks with no strain → raise
_LOOKBACK_WEEKS = 10


def _clamp_landmarks(base: Dict[str, int], mev: float, mav: float, mrv: float) -> Dict[str, int]:
    """Keep mev ≤ mav ≤ mrv and within ±factor of the static base."""
    lo = lambda k, v: max(base[k] * _MIN_FACTOR, min(base[k] * _MAX_FACTOR, v))
    mev = lo("mev", mev)
    mav = lo("mav", mav)
    mrv = lo("mrv", mrv)
    mav = max(mev, mav)
    mrv = max(mav, mrv)
    return {"mev": int(round(mev)), "mav": int(round(mav)), "mrv": int(round(mrv))}


def get_user_landmarks(user_id: str, db=None) -> Dict[str, Dict[str, int]]:
    """Effective landmarks per muscle = static defaults overlaid with any
    learned (confident) per-user values. Always returns the full muscle set."""
    out = {m: dict(v) for m, v in _STATIC.items()}
    if not user_id:
        return out
    db = db or get_supabase_db()
    try:
        rows = (
            db.client.table("user_volume_landmarks")
            .select("muscle, mev, mav, mrv, confidence")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[vol-learn] read failed: {e}")
        return out
    for r in rows:
        m = (r.get("muscle") or "").lower()
        # Only trust a learned landmark once it has SOME evidence behind it.
        if m in out and float(r.get("confidence") or 0) >= 0.3:
            for k in ("mev", "mav", "mrv"):
                if r.get(k) is not None:
                    out[m][k] = int(r[k])
    return out


def recompute_user_landmarks(user_id: str, db=None) -> None:
    """Re-learn the user's per-muscle landmarks from recent history. Best-effort."""
    if not user_id:
        return
    db = db or get_supabase_db()
    try:
        since = (datetime.now(timezone.utc) - timedelta(weeks=_LOOKBACK_WEEKS)).date()
        weekly = (
            db.client.table("weekly_volume_tracking")
            .select("muscle_group, total_sets, week_start")
            .eq("user_id", user_id)
            .gte("week_start", since.isoformat())
            .execute()
        ).data or []
        strains = (
            db.client.table("strain_history")
            .select("body_part")
            .eq("user_id", user_id)
            .execute()
        ).data or []
    except Exception as e:
        logger.warning(f"[vol-learn] history fetch failed: {e}")
        return

    # Sets per muscle per week, and a strained-muscle set.
    per_muscle_weeks: Dict[str, list] = {}
    for w in weekly:
        m = (w.get("muscle_group") or "").lower()
        if m:
            per_muscle_weeks.setdefault(m, []).append(int(w.get("total_sets") or 0))
    strained = {(s.get("body_part") or "").lower() for s in strains}

    now = datetime.now(timezone.utc).isoformat()
    for muscle, base in _STATIC.items():
        weeks = per_muscle_weeks.get(muscle, [])
        confidence = 0.0
        mev, mav, mrv = float(base["mev"]), float(base["mav"]), float(base["mrv"])

        # STRAIN: the user found their ceiling below the textbook → pull down.
        if muscle in strained:
            mav *= 0.85
            mrv *= 0.85
            confidence = max(confidence, 0.5)

        # TOLERANCE: enough recent hard weeks without a strain → raise.
        if weeks and muscle not in strained:
            hard_weeks = sum(1 for s in weeks if s >= base["mav"] * _HARD_FRACTION)
            if hard_weeks >= _TOLERANCE_WEEKS:
                mav *= 1.12
                mrv *= 1.12
                confidence = max(confidence, min(0.8, 0.3 + 0.1 * hard_weeks))
            elif hard_weeks >= 1:
                confidence = max(confidence, 0.3)  # some data, no change yet

        if confidence <= 0:
            continue  # no evidence — leave the user on the static default

        lm = _clamp_landmarks(base, mev, mav, mrv)
        try:
            db.client.table("user_volume_landmarks").upsert(
                {
                    "user_id": user_id,
                    "muscle": muscle,
                    "mev": lm["mev"],
                    "mav": lm["mav"],
                    "mrv": lm["mrv"],
                    "confidence": round(confidence, 2),
                    "updated_at": now,
                },
                on_conflict="user_id,muscle",
            ).execute()
        except Exception as e:
            logger.warning(f"[vol-learn] upsert {muscle} failed: {e}")
