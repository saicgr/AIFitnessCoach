"""
Novel-exercise workout authoring — the "no restrictions" path.
==============================================================
The Exercise Library can't cover every implement a user might own. When someone
asks for a workout using something the library has no exercises for ("hay bale",
"tire", "sandbag", "water jugs", a made-up implement), the library path would
silently SUBSTITUTE generic moves (kettlebell swings for a "hay bale" request) —
which is wrong. Google Health handles this by *inventing* the exercises on the
fly (Hay Bale Swing / Squat / Press / Clean). This module does the same:

  1. ``_extract_implement`` pulls the named implement out of the request.
  2. ``_library_covers`` checks whether the library actually has exercises for
     it (a data-driven COVERAGE GATE — not a hardcoded whitelist, per
     feedback_no_hardcoded_enumerations).
  3. When coverage is insufficient, ``_author`` has the LLM compose a real,
     structured, sectioned workout that genuinely uses that implement, persists
     it like any other workout (so the same chat card → preview → save → start
     flow works), and returns the standard ``generate_quick_workout`` dict.

Safety stays DETERMINISTIC (feedback_no_llm_for_safety_classification): user
injuries are passed as HARD avoidances in the prompt, loading cues stay
conservative, and every authored workout carries the same "general guidance,
not medical advice" disclaimer. Any failure returns ``None`` so the caller falls
back to the standard library path — novel authoring never BLOCKS generation.
"""

from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from typing import Any, Callable, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

# Equipment terms the library already covers well — if the request only names
# these, there is nothing "novel" to author, so we skip straight to the standard
# path WITHOUT even a DB round-trip. This is an optimization, NOT the gate: the
# authoritative gate is `_library_covers` (data-driven). Keep this conservative.
_STANDARD_EQUIPMENT = {
    "bodyweight", "body weight", "no equipment", "dumbbell", "dumbbells",
    "barbell", "kettlebell", "kettlebells", "band", "bands", "resistance band",
    "resistance bands", "cable", "machine", "machines", "bench", "pull up bar",
    "pull-up bar", "pullup bar", "smith machine", "ez bar", "trx", "medicine ball",
    "bosu", "foam roller", "jump rope", "treadmill", "bike", "rower", "weights",
    "gym", "full gym", "plates", "plate",
}

# Pull the implement out of phrasings like "using hay bale", "with a tire",
# "sandbag only", "workout using water jugs".
_IMPLEMENT_PATTERNS = [
    re.compile(r"\b(?:using|with|use)\s+(?:a |an |my |some |the )?([a-z][a-z \-]{2,28}?)(?:\s+(?:only|workout|workouts|exercises?|movements?|moves|circuit|routine|for|to|at|in|on|over|during|today|now|please)\b|\s+\d|[.,!?]|$)", re.I),
    re.compile(r"\b([a-z][a-z\-]{2,20}(?:\s+[a-z][a-z\-]{2,20})?)\s+only\b", re.I),
]

# Filler / prepositions / focus words that may ride along after the captured
# implement — everything from the first of these onward is trimmed off.
_TRAIL_CUT_RE = re.compile(
    r"\b(?:for|to|at|in|on|over|during|please|today|now|and|that|workout|"
    r"workouts|exercises?|circuit|routine|session)\b.*$",
    re.I,
)
_LEAD_CUT_RE = re.compile(r"^(?:with|using|use|a|an|the|my|some)\s+", re.I)

# Words that are never an implement (strip false matches from the patterns).
_NON_IMPLEMENT = {
    "minute", "minutes", "min", "mins", "second", "seconds", "sec", "hour",
    "hours", "quick", "short", "long", "easy", "hard", "intense", "light",
    "today", "now", "later", "morning", "evening", "warmup", "warm up",
    "cooldown", "cool down", "full body", "upper", "lower", "core", "cardio",
    "legs", "arms", "chest", "back", "shoulders", "glutes", "abs",
}


def _extract_implement(text: str) -> Optional[str]:
    """Best-effort: the named implement in a workout request, or None.

    The FIRST pattern that yields a clean candidate decides the outcome — if
    that candidate is standard equipment / a non-implement word, we return None
    rather than falling through to looser patterns that would capture sentence
    fragments ("min workout with kettlebell").
    """
    if not text:
        return None
    low = text.lower()
    for pat in _IMPLEMENT_PATTERNS:
        m = pat.search(low)
        if not m:
            continue
        cand = (m.group(1) or "").strip(" -")
        cand = _LEAD_CUT_RE.sub("", cand)            # drop a leading "with "/"a "
        cand = _TRAIL_CUT_RE.sub("", cand)           # drop trailing "for 20 min" etc.
        cand = re.sub(r"\d.*$", "", cand).strip(" -")  # drop any trailing numbers
        cand = re.sub(r"\s{2,}", " ", cand).strip()
        if not cand or len(cand) < 3 or re.fullmatch(r"[\d ]+", cand):
            continue
        # First clean candidate is authoritative. Standard / non-implement →
        # there's nothing novel to author.
        if cand in _NON_IMPLEMENT or cand in _STANDARD_EQUIPMENT:
            return None
        return cand
    return None


def _library_covers(db: Any, implement: str, threshold: int = 2) -> bool:
    """True when the exercise library already has >= `threshold` exercises for
    this implement (by exercise_name or equipment).

    NOTE: the column is ``exercise_name`` (NOT ``name``) — referencing a phantom
    column makes the query throw and (previously) wrongly skip authoring. On a
    DB error we now return False (NOT covered) so the request still gets
    authored: we only reach this check for a NON-standard implement
    (``_STANDARD_EQUIPMENT`` short-circuits earlier), so authoring is the correct
    fail-safe — never silently substituting a generic library workout.
    """
    try:
        like = f"%{implement}%"
        by_name = (
            db.client.table("exercise_library")
            .select("id")
            .ilike("exercise_name", like)
            .limit(threshold)
            .execute()
        )
        count = len(by_name.data or [])
        if count >= threshold:
            return True
        by_equip = (
            db.client.table("exercise_library")
            .select("id")
            .ilike("equipment", like)
            .limit(threshold)
            .execute()
        )
        return (count + len(by_equip.data or [])) >= threshold
    except Exception as e:
        logger.debug(
            f"[NovelAuthoring] coverage check failed ({e}); authoring (non-standard implement)"
        )
        return False


def _injury_clause(user: Optional[Dict[str, Any]]) -> str:
    """A hard-avoidance clause built from the user's active injuries."""
    if not user:
        return ""
    raw = user.get("active_injuries") or user.get("injuries") or []
    parts: List[str] = []
    if isinstance(raw, str):
        try:
            raw = json.loads(raw)
        except Exception:
            raw = []
    for inj in raw or []:
        if isinstance(inj, dict):
            bp = inj.get("body_part") or inj.get("name")
            if bp:
                parts.append(str(bp))
        elif isinstance(inj, str):
            parts.append(inj)
    if not parts:
        return ""
    return (
        f"HARD SAFETY CONSTRAINT: the user has these active injuries/areas to "
        f"protect: {', '.join(parts)}. Do NOT include any movement that loads or "
        f"strains them; choose alternatives. This overrides everything else."
    )


def _exercise_count_for(duration_minutes: int) -> int:
    if duration_minutes <= 10:
        return 5
    if duration_minutes <= 20:
        return 7
    if duration_minutes <= 30:
        return 9
    if duration_minutes <= 45:
        return 11
    return 13


def _strip_json(text: str) -> str:
    """Strip ```json fences / surrounding prose to the outermost JSON object."""
    t = text.strip()
    if "```" in t:
        t = re.sub(r"```(?:json)?", "", t).strip("` \n")
    start = t.find("{")
    end = t.rfind("}")
    if start != -1 and end != -1 and end > start:
        return t[start:end + 1]
    return t


def _clean_emoji(raw: Any) -> str:
    """Accept a real emoji, reject plain-text. Emojis are non-ASCII, so an
    ASCII string ('dumbbell') is rejected in favour of the deterministic
    fallback."""
    if not raw or not isinstance(raw, str):
        return ""
    s = raw.strip()
    if not s or s.isascii():
        return ""
    return s[:4]


def _fallback_emoji(section: str, muscle: str) -> str:
    """Deterministic emoji when the LLM doesn't supply one — keyed on section,
    then muscle group, so a novel exercise always shows a sensible thumbnail."""
    if section == "warmup":
        return "\U0001F525"   # 🔥
    if section == "cooldown":
        return "\U0001F9D8"   # 🧘
    m = (muscle or "").lower()
    if any(k in m for k in ("leg", "quad", "glute", "calf", "hamstring")):
        return "\U0001F9B5"   # 🦵
    if any(k in m for k in ("back", "lat", "pull")):
        return "\U0001F3CB️"  # 🏋️
    if any(k in m for k in ("core", "ab", "oblique")):
        return "\U0001F300"   # 🌀
    if any(k in m for k in ("cardio", "condition", "full")):
        return "⚡"        # ⚡
    return "\U0001F4AA"        # 💪 (chest/shoulder/arms/default)


def _author(
    db: Any,
    user_id: str,
    implement: str,
    request_text: str,
    duration_minutes: int,
    focus: Optional[str],
    intensity: str,
    workout_id: Optional[str],
) -> Optional[Dict[str, Any]]:
    """Compose + persist a novel workout for `implement`. None on any failure."""
    try:
        from core.gemini_client import get_langchain_llm
    except Exception as e:
        logger.warning(f"[NovelAuthoring] LLM unavailable: {e}")
        return None

    user = None
    try:
        user = db.get_user(user_id) if user_id else None
    except Exception:
        user = None

    n = _exercise_count_for(duration_minutes)
    focus_clause = f" The session should bias toward: {focus}." if focus else ""
    injury_clause = _injury_clause(user)
    intensity_key = (intensity or "moderate").lower()
    if intensity_key not in ("light", "moderate", "intense"):
        intensity_key = "moderate"

    prompt = f"""You are an expert strength + conditioning coach. Design a {duration_minutes}-minute workout that uses ONLY "{implement}" as the equipment (no other gear).{focus_clause}
The user asked: "{request_text}".
{injury_clause}

Every exercise MUST genuinely use the {implement}. Invent legitimate, safe movements if needed (like a coach would improvise with an odd object). Keep loading conservative and the technique cues specific to handling a {implement}.

Return STRICT JSON only (no markdown, no prose) with this exact shape:
{{"name": "<short catchy workout name that includes '{implement}'>",
  "exercises": [
    {{"name": "<exercise name including the implement>",
      "section": "warmup" | "main" | "cooldown",
      "sets": <int 1-5>,
      "reps": "<reps as a number string, or a time like '45 sec'>",
      "rest_seconds": <int 0-90>,
      "muscle_group": "<primary muscle/area>",
      "emoji": "<a single emoji that best represents this movement, e.g. a body part or activity emoji>",
      "instructions": "<2-3 sentence technique cue specific to this {implement} movement>"}}
  ]}}

Rules:
- About {n} exercises total: 2 warmup, the rest main, 1-2 cooldown/mobility.
- Order them warmup first, then main, then cooldown.
- Calibrate volume to roughly {duration_minutes} minutes at {intensity_key} intensity.
- No medical claims. Conservative, beginner-safe progressions."""

    try:
        llm = get_langchain_llm(temperature=0.6)
        resp = llm.invoke(prompt)
        raw = resp.content if hasattr(resp, "content") else str(resp)
        if isinstance(raw, list):  # some providers return content blocks
            raw = "".join(
                b.get("text", "") if isinstance(b, dict) else str(b) for b in raw
            )
        data = json.loads(_strip_json(raw))
    except Exception as e:
        logger.warning(f"[NovelAuthoring] generation/parse failed for '{implement}': {e}")
        return None

    raw_exercises = data.get("exercises") if isinstance(data, dict) else None
    if not isinstance(raw_exercises, list) or not raw_exercises:
        logger.warning(f"[NovelAuthoring] LLM returned no exercises for '{implement}'")
        return None

    _SECTION_ORDER = {"warmup": 0, "main": 1, "cooldown": 2}
    exercises: List[Dict[str, Any]] = []
    for ex in raw_exercises:
        if not isinstance(ex, dict):
            continue
        name = str(ex.get("name") or "").strip()
        if not name:
            continue
        section = str(ex.get("section") or "main").lower()
        if section not in _SECTION_ORDER:
            section = "main"
        try:
            sets = int(ex.get("sets") or 3)
        except (TypeError, ValueError):
            sets = 3
        try:
            rest = int(ex.get("rest_seconds") or 45)
        except (TypeError, ValueError):
            rest = 45
        instructions = str(ex.get("instructions") or "").strip()
        # Novel exercises have no library illustration, so the LLM supplies a
        # representative emoji (Google-Health style). Fall back to a section /
        # muscle-based emoji so a thumbnail always shows, never a broken image.
        emoji = _clean_emoji(ex.get("emoji"))
        if not emoji:
            emoji = _fallback_emoji(section, str(ex.get("muscle_group") or ""))
        exercises.append({
            "name": name,
            "section": section,
            "sets": max(1, min(sets, 6)),
            "reps": str(ex.get("reps") or "10"),
            "rest_seconds": max(0, min(rest, 120)),
            "duration_seconds": None,
            "muscle_group": str(ex.get("muscle_group") or (focus or "full body")),
            "equipment": implement,
            "notes": instructions,
            "instructions": instructions,
            "emoji": emoji,
            "gif_url": "",
            "video_url": "",
            "image_url": "",
            "library_id": "",
            "is_ai_authored": True,
        })

    if not exercises:
        return None
    # Stable sort into warmup → main → cooldown without reordering within a band.
    exercises.sort(key=lambda e: _SECTION_ORDER.get(e.get("section", "main"), 1))

    name = str((data.get("name") if isinstance(data, dict) else "") or "").strip()
    if not name:
        name = f"{implement.title()} Workout"

    # If no explicit target was given, look for an existing incomplete CURRENT
    # workout for today and UPDATE it. The partial unique index
    # `workouts_one_current_per_user_day` allows only one is_current row per
    # user/day, so a fresh insert would raise 23505 and the handler refetches +
    # returns the OLD workout — silently dropping our authored content. (This is
    # exactly what the live test caught.) Matching the legacy quick-workout path.
    if not workout_id:
        try:
            today = datetime.now(timezone.utc).date().isoformat()
            existing = (
                db.client.table("workouts")
                .select("id")
                .eq("user_id", user_id)
                .eq("is_completed", False)
                .eq("is_current", True)
                .gte("scheduled_date", today)
                .lte("scheduled_date", today + "T23:59:59Z")
                .order("created_at", desc=True)
                .limit(1)
                .execute()
            )
            if existing.data:
                workout_id = existing.data[0]["id"]
        except Exception as e:
            logger.debug(f"[NovelAuthoring] today-workout lookup failed: {e}")

    is_new_workout = not workout_id
    final_id = workout_id
    try:
        if is_new_workout:
            today_utc = datetime.now(timezone.utc).date().isoformat()
            created = db.create_workout({
                "user_id": user_id,
                "name": name,
                "type": (focus or "custom").replace("_", " "),
                "difficulty": intensity_key,
                "scheduled_date": today_utc,
                "exercises_json": exercises,
                "duration_minutes": min(max(duration_minutes, 5), 90),
                "is_completed": False,
                "generation_method": "ai_novel_authored",
                "generation_source": "chat",
            })
            if not created:
                logger.warning("[NovelAuthoring] create_workout returned nothing")
                return None
            final_id = created.get("id")
        else:
            db.update_workout(workout_id, {
                "exercises_json": exercises,
                "name": name,
                "duration_minutes": min(max(duration_minutes, 5), 90),
                "difficulty": intensity_key,
                "generation_method": "ai_novel_authored",
            })
            final_id = workout_id
    except Exception as e:
        logger.warning(f"[NovelAuthoring] persist failed for '{implement}': {e}")
        return None

    logger.info(
        f"[NovelAuthoring] authored '{name}' ({len(exercises)} {implement} exercises) "
        f"-> workout {final_id}"
    )
    return {
        "success": True,
        "action": "generate_quick_workout",
        "workout_id": final_id,
        "workout_name": name,
        "duration_minutes": min(max(duration_minutes, 5), 90),
        "workout_type": (focus or "custom"),
        "intensity": intensity_key,
        "exercises_removed": [],
        "exercises_added": [e["name"] for e in exercises],
        "exercise_count": len(exercises),
        "is_new_workout": is_new_workout,
        "ai_authored": True,
        "message": f"Created '{name}' - {len(exercises)} exercises",
    }


def maybe_author_novel_workout(
    *,
    db_getter: Callable[[], Any],
    user_id: str,
    request_text: str,
    duration_minutes: int,
    focus: Optional[str],
    intensity: str,
    workout_id: Optional[str],
) -> Optional[Dict[str, Any]]:
    """Entry point: author a novel workout ONLY when the request names an
    implement the library can't cover. Returns the standard response dict, or
    None to signal "use the standard library path". NEVER raises."""
    try:
        implement = _extract_implement(request_text or "")
        if not implement:
            return None
        if implement in _STANDARD_EQUIPMENT:
            return None
        db = db_getter()
        if _library_covers(db, implement):
            return None  # library can handle it — standard path is better
        logger.info(f"[NovelAuthoring] '{implement}' not in library — authoring novel workout")
        return _author(
            db, user_id, implement, request_text, duration_minutes,
            focus, intensity, workout_id,
        )
    except Exception as e:
        logger.warning(f"[NovelAuthoring] gate failed ({e}); using standard path")
        return None
