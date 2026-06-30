"""
Program customization — applies the optional `customize` toggles to a cloned
program template's days BEFORE it is scheduled into concrete workouts.

Used by POST /api/v1/program-templates/assign (and the coach's assign tool).
Three independent, fail-open passes over the template's `days[]`:

  - swap_for_injuries: route every training day's exercises through the SAME
    terminal injury chokepoint the generators use
    (`exercise_rag.injury_guard.enforce_injury_safety`) so a contraindicated
    movement is dropped + replaced with a vetted-safe alternative. The guard
    operates on a flat exercise-dict list; we adapt the template's per-exercise
    shape to/from that list per day.
  - fit_equipment: drop exercises whose required equipment the user/active gym
    profile doesn't have, replacing them via the injury-safe candidate fetch so
    the day stays full. (Best-effort: if we can't resolve equipment we keep the
    exercise rather than thinning the plan.)
  - adapt_to_level: nudge set/rep volume toward the user's fitness level
    (beginner trims a set off high-set work; advanced adds one) — a light,
    deterministic tweak, never a full regeneration.

EVERY pass is wrapped so any failure leaves that day's exercises untouched —
customization must never block a user from starting a program (CLAUDE.md:
"DO NOT USE FALL BACK" refers to *mock data*; here fail-open = keep the real,
already-vetted library exercises).
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# User context resolution (level / equipment / injuries)
# ---------------------------------------------------------------------------
def resolve_user_context(user_id: str) -> Dict[str, Any]:
    """Best-effort read of the customization inputs from the user record +
    active gym profile. Always returns a dict (empty-ish on any failure)."""
    ctx: Dict[str, Any] = {
        "fitness_level": None,
        "injuries": [],
        "equipment": [],
        "gym_profile_id": None,
    }
    db = get_supabase()
    try:
        # Column names verified against the live schema (project Supabase
        # schema-drift gotcha): users carries `equipment` (varchar, single) +
        # `equipment_v2` (text[]) + `equipment_details` (jsonb). There is NO
        # `available_equipment` column — selecting it would 500.
        ures = (
            db.client.table("users")
            .select("fitness_level, active_injuries, equipment, equipment_v2, "
                    "active_gym_profile_id")
            .eq("id", user_id)
            .limit(1)
            .execute()
        )
        if ures.data:
            u = ures.data[0]
            ctx["fitness_level"] = u.get("fitness_level")
            ctx["injuries"] = _normalize_injuries(u.get("active_injuries"))
            # Prefer the structured array (equipment_v2); fall back to the
            # single varchar `equipment` value.
            ctx["equipment"] = _normalize_equipment(
                u.get("equipment_v2") or u.get("equipment")
            )
            ctx["gym_profile_id"] = u.get("active_gym_profile_id")
    except Exception as e:  # noqa: BLE001
        logger.warning("resolve_user_context: user read failed: %s", e)

    # Active gym profile equipment overrides the account-level list when present.
    # gym_profiles has `equipment` (jsonb) — no `available_equipment` column.
    try:
        gp = (
            db.client.table("gym_profiles")
            .select("id, equipment")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .limit(1)
            .execute()
        )
        if gp.data:
            ctx["gym_profile_id"] = ctx["gym_profile_id"] or gp.data[0].get("id")
            gp_equip = _normalize_equipment(gp.data[0].get("equipment"))
            if gp_equip:
                ctx["equipment"] = gp_equip
    except Exception as e:  # noqa: BLE001
        logger.debug("resolve_user_context: gym profile read failed: %s", e)

    return ctx


def _normalize_injuries(value: Any) -> List[str]:
    """Reuse the workouts util normalizer (lowercased body-part slugs)."""
    try:
        from api.v1.workouts.utils import _normalize_injury_body_parts
        return _normalize_injury_body_parts(value)
    except Exception:  # noqa: BLE001
        if isinstance(value, list):
            return [str(v).strip().lower() for v in value if v]
        return []


def _normalize_equipment(value: Any) -> List[str]:
    import json as _json
    if isinstance(value, str):
        try:
            value = _json.loads(value)
        except (ValueError, TypeError):
            value = [value] if value else []
    if not isinstance(value, list):
        return []
    return [str(v).strip().lower() for v in value if v]


# ---------------------------------------------------------------------------
# Template-day <-> flat exercise-dict adapters (for the injury guard)
# ---------------------------------------------------------------------------
def _day_ex_to_guard_ex(ex: Dict[str, Any]) -> Dict[str, Any]:
    """Adapt a template day-exercise into the flat shape the injury guard +
    candidate fetch expect (`name`, sets/reps/rest passthrough)."""
    return {
        "name": ex.get("name") or ex.get("original_name") or "",
        "exercise_name": ex.get("name") or ex.get("original_name") or "",
        "exercise_id": ex.get("exercise_id"),
        "sets": ex.get("sets", 3),
        "reps": ex.get("reps"),
        "rest_seconds": ex.get("rest_seconds", 60),
        # carry the original template fields so we can rebuild on the way back
        "_orig": ex,
    }


def _guard_ex_to_day_ex(g: Dict[str, Any]) -> Dict[str, Any]:
    """Rebuild a template day-exercise from a guard-shaped exercise. Survivors
    carry their `_orig`; replacements (no `_orig`) are reconstructed minimally
    so they flow through the expander unchanged."""
    orig = g.get("_orig")
    # Survivor: the guard kept this exercise verbatim — return the original
    # template dict untouched. Replacements built by the guard have no `_orig`.
    if isinstance(orig, dict) and orig.get("name") == (g.get("name") or ""):
        return orig
    name = (g.get("name") or g.get("exercise_name") or "").strip()
    return {
        "name": name,
        "original_name": name,
        "exercise_id": g.get("exercise_id") or g.get("library_id"),
        "sets": int(g.get("sets") or 3),
        "reps": str(g.get("reps")) if g.get("reps") is not None else "10",
        "reps_spec": None,
        "per_side": False,
        "target_rir": None,
        "target_weight_kg": None,
        "rest_seconds": int(g.get("rest_seconds") or 60),
        "notes": "Swapped for a safer / available alternative.",
        "set_type": "normal",
        "superset_group": None,
        "unresolved": g.get("exercise_id") is None and g.get("library_id") is None,
        "resolution_source": "injury_guard",
        "inferred": False,
    }


# ---------------------------------------------------------------------------
# Pass 1 — injury-safe swap (the chokepoint)
# ---------------------------------------------------------------------------
async def _apply_injury_safety(
    days: List[Dict[str, Any]],
    injuries: List[str],
    equipment: List[str],
    user_id: str,
) -> Dict[str, Any]:
    """Route each training day through `enforce_injury_safety`. Returns a small
    summary {dropped, added}. Mutates `days` in place. Fail-open per day."""
    if not injuries:
        return {"dropped": [], "added": []}
    from services.exercise_rag.injury_guard import enforce_injury_safety

    all_dropped: List[str] = []
    all_added: List[str] = []
    for day in days:
        if day.get("is_rest"):
            continue
        exercises = day.get("exercises") or []
        if not exercises:
            continue
        try:
            guard_list = [_day_ex_to_guard_ex(ex) for ex in exercises]
            focus = [day.get("workout_type")] if day.get("workout_type") else []
            safe, dropped, added = await enforce_injury_safety(
                guard_list,
                injuries,
                equipment=equipment or None,
                focus_areas=focus,
                difficulty_ceiling="beginner",
                user_id=user_id,
            )
            if dropped:
                day["exercises"] = [_guard_ex_to_day_ex(g) for g in safe]
                all_dropped.extend(dropped)
                all_added.extend(added)
        except Exception as e:  # noqa: BLE001
            logger.warning(
                "injury customize: day '%s' left untouched: %s",
                day.get("day_name"), e,
            )
    return {"dropped": all_dropped, "added": all_added}


# ---------------------------------------------------------------------------
# Pass 2 — equipment fit
# ---------------------------------------------------------------------------
# Bodyweight movements never require equipment — never drop them on equipment.
_BODYWEIGHT_HINTS = (
    "push up", "pushup", "pull up", "pullup", "chin up", "plank", "crunch",
    "sit up", "situp", "lunge", "air squat", "bodyweight", "dip", "burpee",
    "mountain climber", "jumping jack", "glute bridge", "superman", "bird dog",
)

# Equipment tokens we can confidently detect from a (library-qualified)
# exercise name. The cleaned library names are equipment-prefixed
# ("Barbell Bench Press", "Cable Row", "Smith Machine Squat"), so a name-token
# scan is a reliable, zero-DB way to know the REQUIRED equipment. Keyed by the
# canonical equipment slug -> the name substrings that imply it. Only a movement
# whose name carries one of these tokens is ever a drop candidate; anything
# else (no detectable equipment token) is KEPT (fail-open, never thin the plan).
_EQUIPMENT_NAME_TOKENS: Dict[str, tuple] = {
    "barbell": ("barbell", "ez bar", "ez-bar"),
    "dumbbell": ("dumbbell",),
    "kettlebell": ("kettlebell",),
    "cable": ("cable",),
    "machine": ("machine", "smith machine", "leg press", "hack squat",
                "pec deck", "lat pulldown", "leg extension", "leg curl"),
    "band": ("resistance band", "band ",),
    "trx": ("trx", "suspension"),
    "medicine ball": ("medicine ball", "med ball"),
    "barbell rack": ("rack",),
}

# Equipment a user may store under several names → canonical slug they cover.
# When a user "has" any of the aliases we treat the required slug as available.
_EQUIPMENT_ALIASES: Dict[str, tuple] = {
    "barbell": ("barbell", "olympic barbell", "ez bar", "ez curl bar"),
    "dumbbell": ("dumbbell", "dumbbells", "adjustable dumbbell"),
    "kettlebell": ("kettlebell", "kettlebells"),
    "cable": ("cable", "cable machine", "functional trainer", "cable crossover"),
    "machine": ("machine", "leg press", "smith machine", "lat pulldown",
                "leg extension", "leg curl", "pec deck", "hack squat"),
    "band": ("band", "resistance band", "bands"),
    "trx": ("trx", "suspension trainer"),
    "medicine ball": ("medicine ball", "med ball"),
}


def _detect_required_equipment(name_lc: str) -> Optional[str]:
    """Best-effort REQUIRED-equipment slug from an exercise name, or None when
    no equipment token is present (treated as unknown → keep)."""
    for slug, tokens in _EQUIPMENT_NAME_TOKENS.items():
        if any(tok in name_lc for tok in tokens):
            return slug
    return None


def _user_has_equipment(slug: str, have: set) -> bool:
    """True if the user's equipment set covers an equipment slug (via aliases)."""
    if slug in have:
        return True
    for alias in _EQUIPMENT_ALIASES.get(slug, ()):  # type: ignore[arg-type]
        if alias in have:
            return True
    return False


# ---------------------------------------------------------------------------
# Equipment coverage (pre-flight fit-check, read-only)
# ---------------------------------------------------------------------------
def resolve_profile_equipment(
    user_id: str, gym_profile_id: Optional[str] = None
) -> Dict[str, Any]:
    """Resolve the equipment + environment for the fit-check.

    When `gym_profile_id` is given, reads THAT profile; otherwise the active
    profile (falling back to the account-level list via `resolve_user_context`).
    Returns {equipment:[...], environment:str|None, gym_profile_id:str|None}.
    Always returns a dict — any failure yields empty equipment (→ 'unknown').
    """
    db = get_supabase()
    if gym_profile_id:
        try:
            gp = (
                db.client.table("gym_profiles")
                .select("id, equipment, workout_environment")
                .eq("id", gym_profile_id)
                .eq("user_id", user_id)
                .limit(1)
                .execute()
            )
            if gp.data:
                row = gp.data[0]
                return {
                    "equipment": _normalize_equipment(row.get("equipment")),
                    "environment": row.get("workout_environment"),
                    "gym_profile_id": str(row.get("id")),
                }
        except Exception as e:  # noqa: BLE001
            logger.warning("resolve_profile_equipment: profile read failed: %s", e)
        # Fall through to active/account context if the named profile vanished.

    # Active profile (or account-level fallback) + its environment.
    ctx = resolve_user_context(user_id)
    environment: Optional[str] = None
    pid = ctx.get("gym_profile_id")
    if pid:
        try:
            gp = (
                db.client.table("gym_profiles")
                .select("workout_environment")
                .eq("id", pid)
                .limit(1)
                .execute()
            )
            if gp.data:
                environment = gp.data[0].get("workout_environment")
        except Exception as e:  # noqa: BLE001
            logger.debug("resolve_profile_equipment: env read failed: %s", e)
    return {
        "equipment": ctx.get("equipment") or [],
        "environment": environment,
        "gym_profile_id": pid,
    }


# Environments where an empty equipment list means "assume a fully-stocked gym"
# rather than "we don't know" — a commercial gym has everything by default.
_FULL_GYM_ENVIRONMENTS = ("commercial_gym",)


def compute_equipment_coverage(
    exercise_names: List[str],
    equipment: List[str],
    *,
    environment: Optional[str] = None,
) -> Dict[str, Any]:
    """Pure pre-flight coverage of a program's exercises against the user's
    available equipment, using the SAME detection the assign-time equipment-fit
    pass uses (`_BODYWEIGHT_HINTS` + `_detect_required_equipment` +
    `_user_has_equipment`) so the warning never disagrees with what assign does.

    Returns:
      {status: 'covered'|'gaps'|'unknown',
       coverage_pct: 0-100, total_exercises: int,
       required_equipment: [...], missing_equipment: [...],
       swappable_count: int, unswappable_count: int, fully_coverable: bool}

    status='unknown' when we can't tell (no equipment list AND not a full-gym
    environment) — the client shows a soft "set your equipment" nudge, never a
    false warning. Mirrors the customizer's fail-open contract.
    """
    names = [n.strip() for n in exercise_names if n and n.strip()]
    total = len(names)

    have = {e.lower() for e in (equipment or [])}
    env = (environment or "").strip().lower()
    full_gym_assumed = not have and env in _FULL_GYM_ENVIRONMENTS
    # We can only judge "available vs missing" when we know the user's gear (a
    # non-empty list) or can assume a fully-stocked commercial gym.
    known = bool(have) or full_gym_assumed
    have.update(("bodyweight", "none"))

    required: set = set()
    missing: set = set()
    mismatch_count = 0
    for name in names:
        name_lc = name.lower()
        if any(h in name_lc for h in _BODYWEIGHT_HINTS):
            continue
        req = _detect_required_equipment(name_lc)
        if req is None:
            continue  # unknown equipment → treated as available (fail-open)
        required.add(req)
        if not known or full_gym_assumed or _user_has_equipment(req, have):
            continue
        missing.add(req)
        mismatch_count += 1

    # Can't verify the user's gear: only nag ('unknown') when the program
    # actually prescribes detectable equipment — a bodyweight/cardio program
    # needs nothing, so it's 'covered' regardless.
    if not known:
        return {
            "status": "unknown" if required else "covered",
            "coverage_pct": 100,
            "total_exercises": total,
            "required_equipment": sorted(required),
            "missing_equipment": [],
            "swappable_count": 0,
            "unswappable_count": 0,
            "fully_coverable": True,
        }

    covered = total - mismatch_count
    coverage_pct = round(100 * covered / total) if total else 100
    # The assign-time pass backfills every dropped exercise from the injury-safe
    # candidate fetch, so detected mismatches are treated as swappable here.
    return {
        "status": "gaps" if missing else "covered",
        "coverage_pct": coverage_pct,
        "total_exercises": total,
        "required_equipment": sorted(required),
        "missing_equipment": sorted(missing),
        "swappable_count": mismatch_count,
        "unswappable_count": 0,
        "fully_coverable": True,
    }


async def _apply_equipment_fit(
    days: List[Dict[str, Any]],
    equipment: List[str],
    injuries: List[str],
    user_id: str,
) -> Dict[str, Any]:
    """Drop exercises whose required equipment the user lacks, replacing via the
    injury-safe candidate fetch (which already filters by equipment). Fail-open:
    unknown equipment keeps the exercise. No-op when we have no equipment list
    (we can't tell what's missing → never thin the plan)."""
    if not equipment:
        return {"dropped": [], "added": []}

    have = {e.lower() for e in equipment}
    have.update(("bodyweight", "none"))

    all_dropped: List[str] = []
    all_added: List[str] = []
    for day in days:
        if day.get("is_rest"):
            continue
        exercises = day.get("exercises") or []
        if not exercises:
            continue
        kept: List[Dict[str, Any]] = []
        missing_names: List[str] = []
        for ex in exercises:
            name = (ex.get("name") or ex.get("original_name") or "").strip()
            name_lc = name.lower()
            if any(h in name_lc for h in _BODYWEIGHT_HINTS):
                kept.append(ex)
                continue
            req = _detect_required_equipment(name_lc)
            if req is None or _user_has_equipment(req, have):
                kept.append(ex)  # unknown or available → keep
            else:
                missing_names.append(name)
        if not missing_names:
            continue
        # Backfill replacements equal to the number dropped, equipment-filtered
        # via the same safe-candidate fetch (with no injuries it still respects
        # equipment + difficulty). Reuse the guard's replacement assembly by
        # running enforce_injury_safety on the KEPT list with a phantom drop is
        # overkill — instead fetch candidates directly.
        try:
            from services.exercise_rag.service import fetch_safe_candidates
            cands = await fetch_safe_candidates(
                injuries=injuries or [],
                focus_areas=[day.get("workout_type")] if day.get("workout_type") else [],
                equipment=equipment,
                difficulty_ceiling="beginner",
                k=len(missing_names) + 15,
            )
            present = {(e.get("name") or "").lower() for e in kept}
            template = kept[0] if kept else exercises[0]
            added_here = 0
            for cand in cands:
                if added_here >= len(missing_names):
                    break
                cn = (cand.get("name") or "").strip()
                if not cn or cn.lower() in present:
                    continue
                present.add(cn.lower())
                kept.append({
                    "name": cn,
                    "original_name": cn,
                    "exercise_id": (
                        str(cand["exercise_id"])
                        if cand.get("exercise_id") is not None else None
                    ),
                    "sets": int(template.get("sets") or 3),
                    "reps": str(template.get("reps") or "10"),
                    "reps_spec": None,
                    "per_side": False,
                    "target_rir": None,
                    "target_weight_kg": None,
                    "rest_seconds": int(template.get("rest_seconds") or 60),
                    "notes": "Swapped for available equipment.",
                    "set_type": "normal",
                    "superset_group": None,
                    "unresolved": cand.get("exercise_id") is None,
                    "resolution_source": "equipment_fit",
                    "inferred": False,
                })
                added_here += 1
                all_added.append(cn)
            day["exercises"] = kept
            all_dropped.extend(missing_names)
        except Exception as e:  # noqa: BLE001
            logger.warning(
                "equipment customize: day '%s' left untouched: %s",
                day.get("day_name"), e,
            )
    return {"dropped": all_dropped, "added": all_added}


# ---------------------------------------------------------------------------
# Pass 3 — level adaptation (light deterministic volume tweak)
# ---------------------------------------------------------------------------
# Intensity techniques a beginner shouldn't run unsupervised — training to
# failure / drop sets / rest-pause with unrefined form is an injury risk. We
# detune these to a normal set with 2 reps in reserve.
_RISKY_SET_TYPES = {
    "failure", "to_failure", "tofailure", "amrap",
    "drop", "dropset", "drop_set", "myo", "myo_reps",
    "rest_pause", "rest-pause", "restpause", "cluster",
}


def _is_rep_based(ex: Dict[str, Any]) -> bool:
    """True when an exercise's target is a plain rep COUNT we can safely rewrite.

    False for distance/time/calorie specs (e.g. '1000 m', '8 minutes', '30 sec')
    — rewriting those to a bare rep number destroys the unit (see the expander's
    reps_spec note). Conservative: anything we can't read as pure reps is treated
    as NOT rep-based and left untouched."""
    import re
    spec = ex.get("reps_spec")
    if isinstance(spec, dict):
        unit = str(spec.get("unit") or "").strip().lower()
        return unit in ("", "reps", "rep", "count")
    spec_txt = spec if isinstance(spec, str) else ""
    blob = f"{ex.get('reps') or ''} {spec_txt}".lower()
    # Strip everything that legitimately appears in a REP scheme; if any letters
    # survive (m, min, sec, cal, km …) it carries a non-rep unit → not rep-based.
    cleaned = re.sub(
        r"[0-9\s\-,/x×+]|amrap|failure|fail|max|each|side|per|rep[s]?|to",
        "", blob,
    )
    return cleaned == ""


def _rep_target_ceiling(reps: Any) -> Optional[int]:
    """Top of a numeric rep target ('8-12'→12, '10'→10). None when no concrete
    number is present (e.g. 'AMRAP')."""
    if isinstance(reps, bool):
        return None
    if isinstance(reps, int):
        return reps
    import re
    nums = re.findall(r"\d+", str(reps or ""))
    return max(int(n) for n in nums) if nums else None


def _apply_level_adaptation(
    days: List[Dict[str, Any]], fitness_level: Optional[str]
) -> int:
    """Right-size each exercise toward the user's level. Returns the number of
    EXERCISES changed (any field) — a light, deterministic tweak, never a regen.

    Beginner — keep volume + intensity learnable:
      • cap working sets at 3,
      • detune failure/AMRAP/drop-set/rest-pause intensity to a normal set
        leaving 2 reps in reserve (failure with unrefined form is an injury
        risk),
      • pull sky-high rep targets (>20) down to a hypertrophy-range 15,
      • guarantee >=60s rest so form holds between sets.
    Advanced/Elite — add one working set to sub-5-set work.

    Rep/intensity rewrites are skipped for distance/time/calorie exercises
    (see [_is_rep_based]) so a cardio or timed move never loses its unit."""
    level = (fitness_level or "").strip().lower()
    if level not in ("beginner", "advanced", "elite"):
        return 0
    is_beginner = level == "beginner"
    tweaked = 0
    for day in days:
        if day.get("is_rest"):
            continue
        for ex in day.get("exercises") or []:
            changed = False

            # --- working sets ---
            try:
                sets = int(ex.get("sets") or 3)
            except (TypeError, ValueError):
                sets = None
            if sets is not None:
                if is_beginner and sets > 3:
                    ex["sets"] = 3
                    changed = True
                elif not is_beginner and sets < 5:
                    ex["sets"] = sets + 1
                    changed = True

            if is_beginner:
                rep_based = _is_rep_based(ex)
                set_type = str(ex.get("set_type") or "normal").strip().lower()
                reps_txt = str(ex.get("reps") or "").lower()
                risky = set_type in _RISKY_SET_TYPES or any(
                    k in reps_txt for k in ("amrap", "fail", "max")
                )

                # --- detune risky intensity techniques ---
                if risky:
                    ex["set_type"] = "normal"
                    ex["target_rir"] = 2  # leave 2 in the tank, not failure
                    if rep_based:
                        ex["reps"] = "10"
                        ex["reps_spec"] = None
                    changed = True
                # --- cap sky-high rep targets (rep-based only) ---
                elif rep_based:
                    ceil = _rep_target_ceiling(ex.get("reps"))
                    if ceil is not None and ceil > 20:
                        ex["reps"] = "15"
                        ex["reps_spec"] = None
                        changed = True

                # --- guarantee adequate inter-set rest ---
                try:
                    rest = int(ex.get("rest_seconds") or 0)
                except (TypeError, ValueError):
                    rest = 0
                if 0 < rest < 60:
                    ex["rest_seconds"] = 60
                    changed = True

            if changed:
                tweaked += 1
    return tweaked


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------
def customize_status(summary: Dict[str, Any]) -> str:
    """Classify a customize summary so the client can be honest about whether
    the tailoring DID anything: 'applied' when at least one exercise was
    swapped/dropped/added or a set count was tweaked, else 'noop'. The route
    layer stamps 'failed' separately when a pass raises. Pure — no side effects.
    """
    if not isinstance(summary, dict):
        return "noop"
    changed = (
        bool(summary.get("dropped_for_injury"))
        or bool(summary.get("added_for_injury"))
        or bool(summary.get("dropped_for_equipment"))
        or bool(summary.get("added_for_equipment"))
        or int(summary.get("level_tweaks") or 0) > 0
    )
    return "applied" if changed else "noop"


async def customize_template_days(
    days: List[Dict[str, Any]],
    *,
    user_id: str,
    adapt_to_level: bool = True,
    swap_for_injuries: bool = True,
    fit_equipment: bool = True,
    context: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Apply the requested customization passes to `days` (mutated in place).

    Returns a summary dict:
      {injuries:[...], dropped_for_injury:[...], added_for_injury:[...],
       dropped_for_equipment:[...], added_for_equipment:[...],
       level_tweaks:int, fitness_level:str}
    Order matters: injuries first (safety is non-negotiable), then equipment
    fit (don't reintroduce an unavailable movement), then a light level tweak.
    """
    ctx = context or resolve_user_context(user_id)
    summary: Dict[str, Any] = {
        "injuries": ctx.get("injuries") or [],
        "fitness_level": ctx.get("fitness_level"),
        "dropped_for_injury": [],
        "added_for_injury": [],
        "dropped_for_equipment": [],
        "added_for_equipment": [],
        "level_tweaks": 0,
    }

    if swap_for_injuries:
        r = await _apply_injury_safety(
            days, ctx.get("injuries") or [], ctx.get("equipment") or [], user_id
        )
        summary["dropped_for_injury"] = r["dropped"]
        summary["added_for_injury"] = r["added"]

    if fit_equipment:
        r = await _apply_equipment_fit(
            days, ctx.get("equipment") or [], ctx.get("injuries") or [], user_id
        )
        summary["dropped_for_equipment"] = r["dropped"]
        summary["added_for_equipment"] = r["added"]

    if adapt_to_level:
        summary["level_tweaks"] = _apply_level_adaptation(
            days, ctx.get("fitness_level")
        )

    logger.info(
        "🎯 [ProgramCustomizer] user=%s injuries=%s -inj=%d +inj=%d "
        "-eq=%d +eq=%d level_tweaks=%d",
        user_id, summary["injuries"], len(summary["dropped_for_injury"]),
        len(summary["added_for_injury"]), len(summary["dropped_for_equipment"]),
        len(summary["added_for_equipment"]), summary["level_tweaks"],
    )
    return summary
