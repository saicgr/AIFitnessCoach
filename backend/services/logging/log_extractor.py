"""Universal natural-language log extractor (Phase 6).

Turns a single chat message into a structured list of loggable wellness
events. This is the brain behind the AI Coach "universal logger":

    "I did 30 min yoga and drank 500ml water yesterday"
        → [ {workout, yoga, 30min, hint='yesterday'},
            {water, 500ml,    hint='yesterday'} ]

Design decisions:
- A Gemini structured-output call does the hard NLU (multi-action,
  done-vs-future, units). `LogExtractionResponse` pins the JSON shape.
- The catalog (`catalog.py`) does the deterministic post-processing —
  canonicalising the activity, MET lookup, unit conversion — so the LLM
  never has to be trusted with taxonomy or arithmetic.
- This module returns plain dicts ready to hand to the events endpoint;
  it performs NO DB writes itself.

X-matrix coverage handled here:
  X1  occurred_at_hint passthrough          X10 is_log gate (done vs future)
  X3  needs_clarification / one question    X12 unit parsing (LLM + catalog)
  X4  intensity word capture                X13 negation → is_log=False
  X6  implausible-value sanity clamp         X19 domain disambiguation
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional, Tuple

from google.genai import types

from core.logger import get_logger
from models.gemini_schemas import LogExtractionResponse
from services.gemini.constants import gemini_generate_with_retry
from services.gemini.utils import _sanitize_for_prompt
from services.logging.catalog import (
    get_activity,
    resolve_activity,
)

logger = get_logger(__name__)


_EXTRACTION_PROMPT = '''You are the logging brain of a fitness app. The user is \
chatting with their AI coach. Decide whether the message reports something the \
user ALREADY DID that should be logged, and if so extract every discrete action.

Return ONLY JSON matching the schema.

RULES — what counts as a log (is_log = true):
- Past tense / completed: "I did 30 min yoga", "ran 5k", "slept 7 hours",
  "weighed 70kg this morning", "meditated 10 min", "drank 500ml water",
  "20 min sauna", "my waist is 32 inches".
- Generic completed-workout reports: "did my workout", "did legs today",
  "trained chest", "crushed leg day" — these ARE logs (set is_log=true).
- Present-continuous reporting of a just-finished thing counts too.
- If ANY clause in the message is a completed report, is_log=true and you
  extract every such clause — even when other clauses are not logs.

RULES — what is NOT a log (is_log = false):
- Questions: "should I do yoga?", "how many calories in a run?", "what workout?"
- Future / intention: "I'm going to run later", "I'll do yoga tomorrow",
  "planning to lift".
- Negation: "I didn't work out", "skipped my run", "no exercise today".
- Pure greetings, thanks, or generic chat.
- Medical / medication ("took my insulin", "took my blood pressure pill") —
  do NOT log; set is_log=false.

MULTI-ACTION: one message can contain several actions — emit one entry each.
  "did 30 min yoga and drank 500ml water" → 2 actions.
  A generic "did my workout" / "did legs today" clause IS a loggable action
  (it refers to the scheduled plan) — when it appears alongside another
  report, emit BOTH. "did my workout and drank 500ml water" → is_log=true,
  2 actions (a workout with refers_to_scheduled_workout=true, plus water).

DOMAINS (pick the single best per action):
- workout   : any physical activity / exercise / sport. Set activity_type to a
              short lowercase noun ("yoga","run","basketball","hiking",
              "rock climbing","pushups"). Set duration_minutes and, if a
              distance was given, distance_km. Set intensity (easy|medium|hard)
              ONLY if the user signalled it ("hot yoga"→hard, "easy walk"→easy,
              "intense hike"→hard).
              MICRO-WORKOUT: if the user lists individual exercises with reps
              or holds ("did 20 pushups, 30 squats, 1-min plank"), set
              activity_type="calisthenics" and fill `exercises` with one entry
              per move: name + reps (count) and/or duration_seconds (holds:
              "1-min plank"→duration_seconds=60). "3x10 lunges"→sets=3,reps=10.
              SCHEDULED WORKOUT: set refers_to_scheduled_workout=true when the
              user reports doing their PLANNED session in generic terms
              ("did my workout","finished my workout","did legs today",
              "trained chest","crushed leg day","completed today's session").
              Keep it FALSE for distinct standalone activities (yoga, a run,
              basketball) even when a plan also exists.
- water     : drinking water / fluids. Set volume_ml (convert: 1 glass≈250ml,
              1 cup≈240ml, 1 bottle≈500ml, 1 L=1000ml, 1 oz≈30ml).
- weight    : body weight. Set weight_kg (convert lb→kg: kg = lb × 0.4536).
- sleep     : sleeping. Set duration_minutes (hours×60).
- mood      : feelings/energy. Set mood to great|good|okay|tired|stressed|sad.
- measurement: body measurement. Set measurement_type
              (waist|hips|chest|arms|thighs|body_fat) and measurement_value
              (centimetres; convert inches→cm = in × 2.54; body_fat stays %).
- habit     : a checkable habit like meditation, vitamins, reading,
              journaling, stretching done as a habit. Set habit_name.
- sauna     : sauna, ice bath, cold plunge, contrast therapy. Set
              duration_minutes and activity_type ("sauna" or "ice bath").
- fasting   : starting or ending an intermittent fast. Set fasting_action to
              "start" ("started my fast","I'm fasting now","begin my 16:8") or
              "end" ("broke my fast","ended my fast","done fasting","stopped
              fasting"). For a start, set fasting_protocol if stated
              ("16:8","18:6","20:4","OMAD","24h"). occurred_at_hint still
              applies ("started my fast at 8pm").

FOOD: if the user is reporting EATING food, set is_log=false — a separate food
agent handles meals. (Drinking plain water IS handled here as domain=water.)

occurred_at_hint: copy the user's time phrase verbatim if present
  ("yesterday","this morning","last night","2 hours ago"). Null = now.

CLARIFICATION: if the user clearly logged a workout but gave NO activity AND
NO duration ("I worked out today", "I exercised"), set is_log=true,
needs_clarification=true, actions=[], and clarification_question to ONE short
question ("Nice — what did you do, and for how long?").
EXCEPTION: "did my workout"/"did legs today"/"finished my workout" are NOT
vague — they refer to the scheduled plan. Emit a workout action with
refers_to_scheduled_workout=true (NOT needs_clarification).

Examples:
- "I did 30 min yoga" → is_log=true, [{domain:workout, activity_type:yoga,
  duration_minutes:30, name:"30 min yoga"}]
- "ran 5k in 28 min" → [{domain:workout, activity_type:run, distance_km:5,
  duration_minutes:28, name:"5k run"}]
- "did 20 pushups, 30 squats and a 1-min plank" → [{domain:workout,
  activity_type:calisthenics, name:"bodyweight circuit", exercises:[
  {name:"pushups",reps:20},{name:"squats",reps:30},
  {name:"plank",duration_seconds:60}]}]
- "did legs today" → [{domain:workout, refers_to_scheduled_workout:true,
  name:"leg day"}]
- "finished my workout" → [{domain:workout, refers_to_scheduled_workout:true,
  name:"my workout"}]
- "started my 16:8 fast" → [{domain:fasting, fasting_action:"start",
  fasting_protocol:"16:8", name:"16:8 fast"}]
- "broke my fast" → [{domain:fasting, fasting_action:"end", name:"fast"}]
- "weighed 154 lbs this morning" → [{domain:weight, weight_kg:69.9,
  occurred_at_hint:"this morning", name:"154 lb"}]
- "should I do legs today?" → is_log=false
- "I didn't work out" → is_log=false
- "I worked out today" → is_log=true, needs_clarification=true,
  clarification_question:"Awesome — what did you do, and for how long?"

User message: "'''


# Domains whose chat-extracted payloads are routed to the events endpoint.
_EVENTS_DOMAINS = {"workout", "water", "weight", "sleep", "mood"}


def _clamp(value: float, lo: float, hi: float) -> Tuple[float, bool]:
    """Clamp value into [lo, hi]; return (clamped, was_clamped)."""
    if value < lo:
        return lo, True
    if value > hi:
        return hi, True
    return value, False


def _normalize_exercises(raw_exercises: Any) -> List[Dict[str, Any]]:
    """Normalize extracted micro-workout exercises (A4) into clean dicts.

    Drops empties, sanity-clamps reps (≤2000) and holds (≤3600s). Each item:
        {name, reps?, sets?, duration_seconds?}
    """
    if not raw_exercises:
        return []
    out: List[Dict[str, Any]] = []
    for ex in raw_exercises:
        name = (getattr(ex, "name", None) or "").strip()
        if not name:
            continue
        entry: Dict[str, Any] = {"name": name.lower()}
        reps = getattr(ex, "reps", None)
        sets = getattr(ex, "sets", None)
        dur = getattr(ex, "duration_seconds", None)
        if reps and reps > 0:
            entry["reps"] = min(int(reps), 2000)
        if sets and sets > 0:
            entry["sets"] = min(int(sets), 100)
        if dur and dur > 0:
            entry["duration_seconds"] = min(int(dur), 3600)
        out.append(entry)
    return out


def _post_process_action(item: Any) -> Optional[Dict[str, Any]]:
    """Convert one LogActionItem into an events-endpoint-ready dict.

    Returns a dict {domain, payload, occurred_at_hint, display, warning} or
    None when the action is unusable (e.g. workout with no duration AND no
    distance — caller asks for clarification instead).
    """
    domain = (item.domain or "").lower().strip()
    occurred_at_hint = item.occurred_at_hint
    warning: Optional[str] = None

    if domain == "workout":
        raw = item.activity_type or item.name or ""
        activity = get_activity(raw) or resolve_activity(raw)
        canonical = activity.canonical_id if activity else "other"
        duration = item.duration_minutes
        distance = item.distance_km

        # A4 — itemized micro-workout. Normalize each listed exercise.
        exercises = _normalize_exercises(getattr(item, "exercises", None))

        # X6 sanity clamps — implausible distances/durations.
        if distance is not None:
            distance, clamped = _clamp(float(distance), 0.01, 300.0)
            if clamped:
                warning = "That distance looked off — capped it to a sane value."
        if duration is not None:
            duration, clamped = _clamp(float(duration), 1.0, 1440.0)
            if clamped:
                warning = "That duration looked off — capped it to a sane value."

        # X11 — duration missing but distance present: estimate from a
        # moderate pace (run ~10 km/h, walk ~5 km/h, cycle ~22 km/h).
        if (not duration) and distance:
            pace_kmh = {"run": 10.0, "walk": 5.0, "hike": 4.5,
                        "cycling": 22.0, "swim": 3.0}.get(canonical, 8.0)
            duration = round((distance / pace_kmh) * 60.0)

        # A4 — micro-workout with listed exercises but no stated duration:
        # estimate ~2 min per exercise (a circuit of 3 moves ≈ 6 min) so the
        # session still logs without forcing a clarifying question.
        if (not duration) and exercises:
            duration = max(3, len(exercises) * 2)

        scheduled = bool(getattr(item, "refers_to_scheduled_workout", False))

        if (not duration) and not scheduled:
            # Cannot log a freeform workout with no duration / distance /
            # exercise list. (A scheduled-workout reference needs no
            # duration — it just completes the planned session.)
            return None

        metadata: Dict[str, Any] = {}
        if distance:
            metadata["distance_km"] = distance
        if exercises:
            metadata["exercises"] = exercises
        payload: Dict[str, Any] = {"activity_type": canonical}
        if duration:
            payload["duration_minutes"] = int(round(duration))
        if item.intensity:
            payload["intensity"] = item.intensity.lower().strip()
        if metadata:
            payload["metadata"] = metadata
        if duration:
            display = item.name or (
                f"{int(round(duration))} min "
                f"{activity.display_name if activity else raw}"
            )
        else:
            display = item.name or "my workout"
        return {"domain": "workout", "payload": payload,
                "occurred_at_hint": occurred_at_hint,
                "display": display, "warning": warning,
                "refers_to_scheduled_workout": scheduled}

    if domain == "fasting":
        action = (getattr(item, "fasting_action", None) or "").lower().strip()
        if action not in ("start", "end"):
            return None
        payload = {"fasting_action": action}
        if action == "start":
            proto = (getattr(item, "fasting_protocol", None) or "").strip()
            if proto:
                payload["protocol"] = proto
        return {"domain": "fasting", "payload": payload,
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or ("fast" if action == "end" else "fast"),
                "warning": warning}

    if domain == "water":
        volume = item.volume_ml
        if not volume or volume <= 0:
            return None
        volume, clamped = _clamp(float(volume), 10.0, 6000.0)
        if clamped:
            warning = "That volume looked off — capped it to a sane value."
        return {"domain": "water",
                "payload": {"volume_ml": int(round(volume))},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"{int(round(volume))} ml water",
                "warning": warning}

    if domain == "weight":
        wkg = item.weight_kg
        if not wkg or wkg <= 0:
            return None
        wkg, clamped = _clamp(float(wkg), 20.0, 350.0)
        if clamped:
            warning = "That weight looked off — please double-check it."
        return {"domain": "weight",
                "payload": {"weight_kg": round(wkg, 2)},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"{wkg:.1f} kg",
                "warning": warning}

    if domain == "sleep":
        duration = item.duration_minutes
        if not duration or duration <= 0:
            return None
        duration, clamped = _clamp(float(duration), 10.0, 960.0)
        if clamped:
            warning = "That sleep duration looked off — capped it."
        return {"domain": "sleep",
                "payload": {"duration_minutes": int(round(duration))},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"{duration / 60.0:.1f} h sleep",
                "warning": warning}

    if domain == "mood":
        mood = (item.mood or "").lower().strip()
        if not mood:
            return None
        return {"domain": "mood",
                "payload": {"mood": mood},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"Mood: {mood}",
                "warning": warning}

    if domain == "measurement":
        mtype = (item.measurement_type or "").lower().strip()
        mval = item.measurement_value
        if not mtype or not mval or mval <= 0:
            return None
        # body_fat is a %, others are cm. Different sane bands.
        if mtype in ("body_fat", "bodyfat", "body fat"):
            mval, clamped = _clamp(float(mval), 2.0, 70.0)
            mtype = "body_fat"
        else:
            mval, clamped = _clamp(float(mval), 5.0, 250.0)
        if clamped:
            warning = "That measurement looked off — please double-check it."
        return {"domain": "measurement",
                "payload": {"measurement_type": mtype, "value": round(mval, 2)},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"{mtype.replace('_', ' ').title()}: {mval}",
                "warning": warning}

    if domain == "sauna":
        duration = item.duration_minutes
        if not duration or duration <= 0:
            return None
        duration, clamped = _clamp(float(duration), 1.0, 180.0)
        if clamped:
            warning = "That sauna duration looked off — capped it."
        kind = (item.activity_type or "sauna").lower().strip()
        return {"domain": "sauna",
                "payload": {"duration_minutes": int(round(duration)),
                            "session_type": kind},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or f"{int(round(duration))} min {kind}",
                "warning": warning}

    if domain == "habit":
        hname = (item.habit_name or item.name or "").strip()
        if not hname:
            return None
        return {"domain": "habit",
                "payload": {"habit_name": hname,
                            "duration_minutes": item.duration_minutes},
                "occurred_at_hint": occurred_at_hint,
                "display": item.name or hname.title(),
                "warning": warning}

    logger.warning(f"[LogExtractor] unknown domain from LLM: {domain!r}")
    return None


async def extract_log_actions(
    message: str, user_id: Optional[str] = None,
) -> Dict[str, Any]:
    """Parse a chat message into structured loggable actions.

    Returns:
        {
          "is_log": bool,
          "actions": [ {domain, payload, occurred_at_hint, display, warning}, ... ],
          "needs_clarification": bool,
          "clarification_question": str | None,
        }

    On any extraction failure returns is_log=False so the caller falls
    back to a normal coaching reply (never logs garbage).
    """
    prompt = _EXTRACTION_PROMPT + _sanitize_for_prompt(message) + '"'
    try:
        from services.gemini.constants import client as _client, settings as _s
        response = await gemini_generate_with_retry(
            model=_s.gemini_model,
            contents=prompt,
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                response_schema=LogExtractionResponse,
                max_output_tokens=1500,
                temperature=0.1,
            ),
            user_id=user_id,
            method_name="extract_log_actions",
            timeout=15,
        )
        data = response.parsed
        if not data:
            return {"is_log": False, "actions": [],
                    "needs_clarification": False, "clarification_question": None}
    except Exception as e:
        logger.error(f"[LogExtractor] extraction failed: {e}", exc_info=True)
        return {"is_log": False, "actions": [],
                "needs_clarification": False, "clarification_question": None}

    if not data.is_log:
        return {"is_log": False, "actions": [],
                "needs_clarification": False, "clarification_question": None}

    processed: List[Dict[str, Any]] = []
    for item in (data.actions or []):
        out = _post_process_action(item)
        if out is not None:
            processed.append(out)

    # X3 — the LLM flagged a clear-but-vague log, OR every action was
    # unusable (e.g. workout with no duration). Ask exactly one question.
    needs_clarification = bool(data.needs_clarification) or (
        bool(data.actions) and not processed
    )
    clar = data.clarification_question
    if needs_clarification and not clar:
        clar = "Got it — what exactly did you do, and for how long?"

    return {
        "is_log": bool(processed) or needs_clarification,
        "actions": processed,
        "needs_clarification": needs_clarification and not processed,
        "clarification_question": clar if (needs_clarification and not processed) else None,
    }
