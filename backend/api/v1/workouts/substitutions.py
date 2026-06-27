"""
Persistent exercise substitutions ("swap going forward").

One row per (user, original exercise A) in `user_exercise_substitutions` records
that the user prefers substitute B in place of A. Two consumers:

  * generation post-filter (generation_endpoints.py) — replace any generated A
    with B, so future AI workouts honor the swap instead of reverting.
  * weight suggestions (weight_suggestions.py) — when reading B's history, also
    read A's, so progressive overload follows the swap. The existing decay model
    in strength_recalc.py then carries the trajectory forward.

Everything here is fail-open: any DB hiccup returns empty / no-op so generation
and weight suggestions never break because of a substitution lookup.
"""
from datetime import datetime, timezone
from typing import Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

_LIB_COLS = (
    "id, name, target_muscle, body_part, equipment, gif_url, video_url, "
    "secondary_muscles, instructions, movement_pattern"
)


def norm_name(name: Optional[str]) -> str:
    """Match strength_recalc._norm_key: lower(trim())."""
    return (name or "").strip().lower()


def get_active_substitutions(db, user_id: str) -> List[dict]:
    """All active substitution rows for a user. [] on any error."""
    try:
        res = (
            db.client.table("user_exercise_substitutions")
            .select(
                "id, original_exercise_name, original_exercise_name_norm, "
                "substitute_exercise_name, substitute_exercise_name_norm, "
                "substitute_library_id, muscle_group, movement_pattern, reason, created_at"
            )
            .eq("user_id", user_id)
            .eq("is_active", True)
            .execute()
        )
        return res.data or []
    except Exception as e:
        logger.warning(f"[subs] load active substitutions failed: {e}")
        return []


def get_substitution_map(db, user_id: str) -> Dict[str, dict]:
    """norm(original A) -> substitution row. Used by generation to replace A→B."""
    out: Dict[str, dict] = {}
    for r in get_active_substitutions(db, user_id):
        key = r.get("original_exercise_name_norm") or norm_name(r.get("original_exercise_name"))
        sub = norm_name(r.get("substitute_exercise_name"))
        # Skip degenerate / self substitutions.
        if key and sub and key != sub:
            out[key] = r
    return out


def get_substitution_source_names(db, user_id: str, substitute_name: str) -> List[str]:
    """Original names (A) that the user has mapped TO `substitute_name` (B).

    Used by weight suggestions so B inherits A's logged history.
    """
    target = norm_name(substitute_name)
    if not target:
        return []
    try:
        res = (
            db.client.table("user_exercise_substitutions")
            .select("original_exercise_name")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .eq("substitute_exercise_name_norm", target)
            .execute()
        )
        return [
            r["original_exercise_name"]
            for r in (res.data or [])
            if r.get("original_exercise_name")
        ]
    except Exception as e:
        logger.warning(f"[subs] source-name lookup failed: {e}")
        return []


def upsert_substitution(
    db,
    user_id: str,
    original_name: str,
    substitute_name: str,
    *,
    muscle_group: Optional[str] = None,
    movement_pattern: Optional[str] = None,
    substitute_library_id: Optional[str] = None,
    reason: Optional[str] = None,
) -> None:
    """Create/update the active substitution A→B for a user. Fail-open (logs)."""
    if norm_name(original_name) == norm_name(substitute_name):
        return  # no-op: swapping an exercise for itself
    payload = {
        "user_id": user_id,
        "muscle_group": muscle_group or "",
        "movement_pattern": movement_pattern,
        "original_exercise_name": original_name,
        "original_exercise_name_norm": norm_name(original_name),
        "substitute_exercise_name": substitute_name,
        "substitute_exercise_name_norm": norm_name(substitute_name),
        "substitute_library_id": substitute_library_id,
        "reason": reason,
        "is_active": True,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    }
    try:
        db.client.table("user_exercise_substitutions").upsert(
            payload, on_conflict="user_id,original_exercise_name_norm"
        ).execute()
        logger.info(f"[subs] persisted substitution {original_name} -> {substitute_name}")
    except Exception as e:
        logger.warning(f"[subs] upsert failed (non-fatal): {e}")


def _lookup_exercise_row(db, library_id: Optional[str], name: Optional[str]) -> Optional[dict]:
    """Fetch the substitute's library row (by id first, then name). None on miss."""
    try:
        if library_id:
            res = (
                db.client.table("exercise_library_cleaned")
                .select(_LIB_COLS)
                .eq("id", library_id)
                .limit(1)
                .execute()
            )
            if res.data:
                return res.data[0]
        if name:
            res = (
                db.client.table("exercise_library_cleaned")
                .select(_LIB_COLS)
                .ilike("name", name)
                .limit(1)
                .execute()
            )
            if res.data:
                return res.data[0]
    except Exception as e:
        logger.warning(f"[subs] library lookup failed: {e}")
    return None


def apply_substitutions(db, exercises: List[dict], sub_map: Dict[str, dict]) -> int:
    """Replace any generated exercise matching an original A with its substitute B.

    Mutates `exercises` in place. Keeps the AI-prescribed sets/reps/weight (so the
    prescription and progression carry over) and only swaps the exercise identity
    + media + muscle metadata. Returns the count replaced.

    Name-keyed by design: the user objected to *this* exercise, so we replace it
    wherever it recurs. A different exercise the AI picks for the same slot is left
    untouched (that's variety, not the complaint).
    """
    if not sub_map or not exercises:
        return 0
    applied = 0
    for ex in exercises:
        key = norm_name(ex.get("name"))
        sub = sub_map.get(key)
        if not sub:
            continue
        details = _lookup_exercise_row(
            db, sub.get("substitute_library_id"), sub.get("substitute_exercise_name")
        )
        if details:
            ex.update(
                {
                    "name": details.get("name") or sub.get("substitute_exercise_name"),
                    "muscle_group": details.get("target_muscle")
                    or details.get("body_part")
                    or ex.get("muscle_group"),
                    "equipment": details.get("equipment") or ex.get("equipment"),
                    "library_id": details.get("id") or sub.get("substitute_library_id"),
                    "secondary_muscles": details.get("secondary_muscles")
                    or ex.get("secondary_muscles", []),
                    "gif_url": details.get("gif_url")
                    or details.get("video_url")
                    or ex.get("gif_url"),
                    "video_url": details.get("video_url")
                    or details.get("gif_url")
                    or ex.get("video_url"),
                }
            )
            if details.get("instructions"):
                ex["notes"] = details.get("instructions")
        else:
            # Minimal replacement when the library row can't be found.
            ex["name"] = sub.get("substitute_exercise_name")
            if sub.get("substitute_library_id"):
                ex["library_id"] = sub.get("substitute_library_id")
        ex["substitution_applied"] = True
        applied += 1
    return applied
