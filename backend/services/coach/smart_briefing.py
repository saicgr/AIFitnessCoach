"""Data-grounded coach notification engine (the "Google Health style" upgrade).

The proactive-coaching cron (``push_nudge_cron._job_daily_readiness`` /
``_job_evening_recap``) already owns the WHEN and the gating. This module owns
the WHAT: it turns the rich Phase-B1 health snapshot — plus active injuries and
coach memory — into a synthesized, number-grounded narrative with calibrated
action bullets, the way a coach who remembers you would write it.

Primary path: Gemini, with a hard number guardrail (every digit in the output
must trace to the data) and persona/tone from the user's coach settings.

Fallback: returns ``None`` so the caller uses the existing DETERMINISTIC
``health_coaching.build_daily_briefing`` — never a fabricated stat, never mock
data. No-wearable users have ``snapshot["has_data"] == False`` upstream and are
skipped before this runs, so the tiering is honest by construction.

Public entry point: ``await generate_smart_briefing(...)``.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from google.genai import types

from core.config import get_settings
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry
from services.gemini.coach_notification_prompt import build_briefing_prompt
from services.coach.grounding import number_set, numbers_grounded, parse_json_object

logger = get_logger(__name__)


def _fetch_active_injuries(sb, user_id: str) -> List[Dict[str, Any]]:
    """Active injuries with the fields needed for natural recall + caution.

    Reads ``injury_history`` (the coach-memory-linked structured table). Uses
    ``select("*")`` to be resilient to column drift, then reads defensively.
    Returns a compact list; ``[]`` on any error (briefing still sends).
    """
    try:
        res = (
            sb.client.table("injury_history")
            .select("*")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .limit(5)
            .execute()
        )
    except Exception as e:
        logger.debug(f"[smart_briefing] injury fetch failed for {user_id}: {e}")
        return []

    out: List[Dict[str, Any]] = []
    for r in (res.data or []):
        affects = r.get("affects_exercises")
        if isinstance(affects, str):
            affects = [affects]
        out.append(
            {
                "body_part": r.get("body_part"),
                "severity": r.get("severity"),
                "recovery_phase": r.get("recovery_phase"),
                "avoid_exercises": affects or [],
            }
        )
    return out


def _compact_recent_workouts(snapshot: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Trim the snapshot's recent_workouts to the fields the prompt needs."""
    rows = snapshot.get("recent_workouts") or []
    out: List[Dict[str, Any]] = []
    for w in rows[:4]:
        if not isinstance(w, dict):
            continue
        out.append(
            {
                "name": w.get("name"),
                "days_ago": w.get("days_ago"),
                "type": w.get("type"),
                "completed": w.get("is_completed", w.get("completed")),
            }
        )
    return out


def _build_context(
    sb,
    user_id: str,
    snapshot: Dict[str, Any],
    today_workout: Optional[Dict[str, Any]],
    moment: str,
    first_name: str,
    time_of_day: str,
) -> Dict[str, Any]:
    """Assemble the JSON-able DATA block for the prompt.

    Pulls injuries + coach-memory open loops/facts on top of the health
    snapshot. Everything here is real; the grounding set is built from this
    exact dict so the model cannot cite anything we did not provide.
    """
    sleep = snapshot.get("last_night_sleep") or {}
    recovery = snapshot.get("recovery") or {}
    heart_rate = snapshot.get("heart_rate") or {}
    steps = snapshot.get("steps") or {}

    # Coach memory (open loops + durable facts). Self-gating + error-safe.
    open_loops: List[Dict[str, Any]] = []
    facts: List[Dict[str, Any]] = []
    try:
        from services.coach.memory.injector import build_memory_block_for_briefing

        recall = build_memory_block_for_briefing(user_id)
        open_loops = recall.get("open_loops", []) or []
        facts = recall.get("facts", []) or []
    except Exception as e:
        logger.debug(f"[smart_briefing] memory recall failed for {user_id}: {e}")

    injuries = _fetch_active_injuries(sb, user_id)

    context: Dict[str, Any] = {
        "first_name": first_name,
        "time_of_day": time_of_day,
        "moment": moment,
        "sleep": {
            "total_minutes": sleep.get("total_minutes"),
            "deep_minutes": sleep.get("deep_minutes"),
            "rem_minutes": sleep.get("rem_minutes"),
            "light_minutes": sleep.get("light_minutes"),
            "awake_minutes": sleep.get("awake_minutes"),
            "efficiency": sleep.get("efficiency"),
        },
        "recovery": {
            "score": recovery.get("score"),
            "tier": recovery.get("tier"),
            "adjustment": recovery.get("adjustment"),
        },
        "heart_rate": {
            "resting": heart_rate.get("resting"),
            "resting_baseline": heart_rate.get("resting_baseline"),
            "resting_vs_baseline": heart_rate.get("resting_vs_baseline"),
        },
        "steps": {
            "today": steps.get("today"),
            "avg_7d": steps.get("avg_7d"),
            "goal": steps.get("goal"),
            "goal_pct": steps.get("goal_pct"),
        },
        "recent_training": _compact_recent_workouts(snapshot),
        "today_workout": (
            {"name": today_workout.get("name"), "type": today_workout.get("type")}
            if today_workout
            else None
        ),
        "injuries": injuries,
        "open_loops": [
            {"content": o.get("content"), "check_in": o.get("resolution_prompt")}
            for o in open_loops
        ],
        "facts": [f.get("content") for f in facts if f.get("content")],
        "goal": (snapshot.get("goals") or {}).get("primary_goal")
        if isinstance(snapshot.get("goals"), dict)
        else None,
    }
    # Drop empty sub-dicts/keys so the model never sees null noise (and so the
    # guardrail's grounded set is exactly the numbers we actually surfaced).
    return _prune(context)


def _prune(obj: Any) -> Any:
    """Recursively drop None / empty values so the prompt is clean."""
    if isinstance(obj, dict):
        pruned = {k: _prune(v) for k, v in obj.items()}
        return {k: v for k, v in pruned.items() if v not in (None, {}, [], "")}
    if isinstance(obj, list):
        return [_prune(v) for v in obj if v not in (None, {}, "")]
    return obj


def _assemble_message(body: str, actions: List[str]) -> str:
    """Combine the narrative body and action bullets into one push message."""
    clean_actions = [a.strip() for a in (actions or []) if a and a.strip()][:2]
    if not clean_actions:
        return body.strip()
    bullets = "\n".join(f"• {a}" for a in clean_actions)
    return f"{body.strip()}\n{bullets}"


async def generate_smart_briefing(
    sb,
    user_id: str,
    snapshot: Dict[str, Any],
    today_workout: Optional[Dict[str, Any]],
    moment: str,
    first_name: str,
    time_of_day: str,
    coach_name: str = "Coach",
    coaching_style: str = "motivational",
    communication_tone: str = "encouraging",
) -> Optional[Dict[str, Any]]:
    """Generate the grounded coach briefing, or None to fall back.

    Returns ``{"has_message": True, "title": str, "message": str,
    "brief_message": str, "actions": [str], "facts": {...}}`` on success.

    Returns ``None`` when Gemini is unavailable, the response is unparseable,
    or ANY cited number is ungrounded — the caller then uses the deterministic
    ``build_daily_briefing`` (honest, number-safe). Never fabricates data.
    """
    if not snapshot or not snapshot.get("has_data"):
        return None

    context = _build_context(
        sb, user_id, snapshot, today_workout, moment, first_name, time_of_day
    )

    try:
        settings = get_settings()
        system_instruction, user_message = build_briefing_prompt(
            context,
            moment,
            coach_name=coach_name,
            style=coaching_style,
            tone=communication_tone,
        )
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                max_output_tokens=420,
                temperature=0.6,
            ),
            user_id=user_id,
            timeout=12.0,
            method_name="smart_briefing",
        )
    except Exception as e:
        logger.warning(f"[smart_briefing] Gemini call failed for {user_id}: {e}")
        return None

    parsed = parse_json_object(getattr(response, "text", None) or "")
    if not parsed:
        return None

    title = (parsed.get("title") or "").strip()
    body = (parsed.get("body") or "").strip()
    actions = parsed.get("actions") or []
    if not isinstance(actions, list):
        actions = [str(actions)]
    if not title or not body:
        return None

    # GROUNDING GATE — reject if the model cited any number not in the data.
    grounded = number_set(context)
    check_text = " ".join([title, body, " ".join(str(a) for a in actions)])
    if not numbers_grounded(check_text, grounded):
        logger.info(
            f"[smart_briefing] ungrounded numbers for {user_id} — falling back "
            f"to deterministic briefing"
        )
        return None

    message = _assemble_message(body, [str(a) for a in actions])
    return {
        "has_message": True,
        "type": f"smart_{moment}",
        "title": title,
        "message": message,
        # The push banner shows the title + first line; the full message (with
        # bullets) expands via BigText (Android) / long-body (iOS).
        "brief_message": body,
        "actions": [str(a).strip() for a in actions if str(a).strip()][:2],
        "facts": {
            "moment": moment,
            "recovery_score": context.get("recovery", {}).get("score"),
            "sleep_minutes": context.get("sleep", {}).get("total_minutes"),
            "delivery": "gemini",
        },
    }
