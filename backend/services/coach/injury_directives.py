"""
Injury directives — turn `users.active_injuries` into PHASE-AWARE workout
directives so injuries DECAY instead of blocking a body part forever.

The recovery framework already exists in `services/injury_service.py`
(SEVERITY_DURATION, RECOVERY_PHASES, CONTRAINDICATIONS, REHAB_EXERCISES). This
module is the thin, deterministic bridge that every generation path
(library / constraint-aware / novel) calls to decide, per active injury:

  acute / subacute  -> HARD avoid the body part (mobility/rehab only)
  recovery          -> REDUCE (gentle strengthening allowed)
  healed / reintro  -> REDUCE, easing the part back in (post-recovery ramp)
  past reintro grace -> EXPIRED (caller resolves + drops it)

Phase is severity-scaled (a `severe` injury decays slower than a `mild` one),
computed from `reported_at` + `severity` — unlike injury_service.get_injury_phase
which uses fixed 21-day bands. Pain/injury avoidance is NEVER classified by an
LLM (feedback_no_llm_for_safety_classification): everything here is deterministic
keyword/date math citing the same maps the rest of the app uses.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger
from services.injury_service import InjuryService

logger = get_logger(__name__)

# Grace window after the expected recovery date during which the body part is
# EASED back in (reduced load) before the injury is fully dropped.
REINTRO_GRACE_DAYS = 7

# Body part -> muscles to avoid. Mirrors workout_builder.SORE_TO_MUSCLES (kept
# here to avoid an import cycle: workout_builder imports THIS module). Keep in
# sync; both are small + stable.
BODY_PART_MUSCLES: Dict[str, List[str]] = {
    "back": ["back", "lower_back", "spine", "erectors"],
    "lower_back": ["lower_back", "back", "erectors"],
    "neck": ["neck", "traps"],
    "shoulder": ["shoulders", "delts"], "shoulders": ["shoulders", "delts"],
    "knee": ["quads", "hamstrings", "legs"], "knees": ["quads", "hamstrings", "legs"],
    "hip": ["glutes", "hip_flexors"], "hips": ["glutes", "hip_flexors"],
    "wrist": ["forearms", "wrist"], "wrists": ["forearms", "wrist"],
    "elbow": ["biceps", "triceps", "forearms"],
    "ankle": ["calves", "legs"], "ankles": ["calves", "legs"],
    "chest": ["chest", "pecs"],
    "core": ["core", "abs"], "abs": ["core", "abs"],
    "glute": ["glutes"], "glutes": ["glutes"],
    "hamstring": ["hamstrings"], "hamstrings": ["hamstrings"],
    "quad": ["quads"], "quads": ["quads"],
}

_injury_service = InjuryService()


def _now(now: Optional[datetime]) -> datetime:
    return now or datetime.now(timezone.utc)


def _parse_dt(raw: Any) -> Optional[datetime]:
    if not raw:
        return None
    if isinstance(raw, datetime):
        return raw if raw.tzinfo else raw.replace(tzinfo=timezone.utc)
    try:
        d = datetime.fromisoformat(str(raw).replace("Z", "+00:00"))
        return d if d.tzinfo else d.replace(tzinfo=timezone.utc)
    except (ValueError, TypeError):
        return None


def compute_phase(
    *,
    reported_at: Any,
    severity: str,
    reintroduction_until: Any = None,
    now: Optional[datetime] = None,
) -> str:
    """Severity-scaled recovery phase. Returns one of:
    acute | subacute | recovery | reintroduction | expired.
    Missing reported_at is treated as acute (conservative hard-avoid)."""
    now = _now(now)
    reintro = _parse_dt(reintroduction_until)
    if reintro is not None:
        return "reintroduction" if now < reintro else "expired"

    rep = _parse_dt(reported_at)
    if rep is None:
        return "acute"  # unknown age -> protect it

    weeks = _injury_service.SEVERITY_DURATION.get((severity or "moderate").lower(), 3)
    total_days = max(1, weeks * 7)
    days = max(0, (now - rep).days)
    frac = days / total_days
    if frac < 0.34:
        return "acute"
    if frac < 0.67:
        return "subacute"
    if frac < 1.0:
        return "recovery"
    # Past the expected recovery date: ease back in for a grace window. The cron
    # stamps reintroduction_until; until then, generation treats it as reintro.
    if days < total_days + REINTRO_GRACE_DAYS:
        return "reintroduction"
    return "expired"


# Phase -> how to treat the body part in generation.
_HARD_AVOID_PHASES = {"acute", "subacute"}
_REDUCE_PHASES = {"recovery", "reintroduction"}


def resolve_injury_directives(
    active_injuries: Any,
    *,
    now: Optional[datetime] = None,
) -> Dict[str, Any]:
    """Turn the `active_injuries` JSONB into phase-aware generation directives.

    Returns:
        {
          "hard_avoid_muscles": [...],   # acute/subacute
          "reduce_muscles": [...],       # recovery/reintroduction
          "hard_avoid_parts": [...],     # body parts (for RAG injuries= filter)
          "active": [ {body_part, severity, phase, allowed_intensity} ],
          "ease_in": [ {body_part, phase, rehab_exercises:[...]} ],
          "expired_ids": [...],          # caller resolves + drops these
        }
    Empty/healthy -> all-empty dict. Never raises.
    """
    out = {
        "hard_avoid_muscles": [],
        "reduce_muscles": [],
        "hard_avoid_parts": [],
        "active": [],
        "ease_in": [],
        "expired_ids": [],
    }
    if not active_injuries:
        return out

    items = active_injuries
    if isinstance(items, dict):  # tolerate a single dict
        items = [items]
    if not isinstance(items, list):
        return out

    hard, reduce_, parts = [], [], []
    for inj in items:
        if not isinstance(inj, dict):
            continue
        body_part = str(inj.get("body_part") or "").lower().strip()
        if not body_part:
            continue
        severity = str(inj.get("severity") or "moderate").lower()
        phase = compute_phase(
            reported_at=inj.get("reported_at"),
            severity=severity,
            reintroduction_until=inj.get("reintroduction_until"),
            now=now,
        )
        if phase == "expired":
            if inj.get("id"):
                out["expired_ids"].append(inj.get("id"))
            continue

        muscles = BODY_PART_MUSCLES.get(body_part, [body_part])
        if phase in _HARD_AVOID_PHASES:
            hard.extend(muscles)
            parts.append(body_part)
        elif phase in _REDUCE_PHASES:
            reduce_.extend(muscles)

        allowed = _injury_service.RECOVERY_PHASES.get(
            "recovery" if phase == "reintroduction" else phase, {}
        ).get("intensity", "light")
        out["active"].append({
            "body_part": body_part,
            "severity": severity,
            "phase": phase,
            "allowed_intensity": allowed,
        })

        # Ease-in / rehab exercises for the current phase (F1 + reintroduction).
        rehab_phase = "recovery" if phase == "reintroduction" else phase
        rehab = _injury_service.REHAB_EXERCISES.get(body_part, {}).get(rehab_phase, [])
        if rehab:
            out["ease_in"].append({
                "body_part": body_part,
                "phase": phase,
                "rehab_exercises": rehab,
            })

    # Dedup, preserve order.
    out["hard_avoid_muscles"] = list(dict.fromkeys(hard))
    out["reduce_muscles"] = [m for m in dict.fromkeys(reduce_) if m not in out["hard_avoid_muscles"]]
    out["hard_avoid_parts"] = list(dict.fromkeys(parts))
    return out


def contraindicated_for(exercise_name: str, active_directives: Dict[str, Any]) -> Optional[str]:
    """Deterministic safety check for the NOVEL backstop. Returns the matched
    contraindication term if `exercise_name` loads an actively-protected body
    part (acute/subacute hard-avoid, or a heavy-load match during recovery),
    else None. Reuses injury_service.CONTRAINDICATIONS — no LLM."""
    if not exercise_name or not active_directives:
        return None
    name = exercise_name.lower()
    for inj in active_directives.get("active", []):
        phase = inj.get("phase")
        terms = _injury_service.CONTRAINDICATIONS.get(inj.get("body_part", ""), [])
        for term in terms:
            if term in name:
                # During recovery/reintroduction only block the heavier loads;
                # acute/subacute block everything contraindicated.
                if phase in _HARD_AVOID_PHASES or term in _HEAVY_LOAD_TERMS:
                    return term
    return None


# Heavier-load contraindication terms that stay blocked even during the gentler
# recovery / reintroduction phases (the rest are allowed back as "ease-in").
_HEAVY_LOAD_TERMS = {
    "deadlift", "barbell row", "good morning", "squat", "romanian", "hack squat",
    "overhead press", "military press", "bench press", "box jump", "jump",
    "plyometric", "snatch", "clean", "sprint", "running",
}
