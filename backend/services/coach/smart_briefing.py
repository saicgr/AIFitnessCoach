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


# Minimum consecutive days of data before we may claim a multi-day PATTERN.
# Below this we fall back to single-day phrasing (never "the last 3 days" on
# one day of data) — guards the prompt's pattern-language rule with real data.
_MIN_PATTERN_DAYS = 3

# A resting-HR reading this far above the personal baseline counts as
# "elevated" for the multi-day trend (kept in lockstep with the cron's
# _ANOMALY_RHR_DELTA_BPM so the rhr_trend moment and its gate agree).
_RHR_TREND_DELTA_BPM = 5.0


def _recent_activity_rows(sb, user_id: str, limit: int = 14) -> List[Dict[str, Any]]:
    """Newest-first daily_activity rows for the multi-day pattern context.

    Reads steps / resting_heart_rate / sleep_minutes directly so the briefing
    can speak to a TREND, not just today's snapshot. Returns ``[]`` on any
    error (the briefing still sends, just without pattern language).
    """
    try:
        res = (
            sb.client.table("daily_activity")
            .select("activity_date, steps, resting_heart_rate, sleep_minutes")
            .eq("user_id", user_id)
            .order("activity_date", desc=True)
            .limit(limit)
            .execute()
        )
        return res.data or []
    except Exception as e:
        logger.debug(f"[smart_briefing] activity-trend fetch failed for {user_id}: {e}")
        return []


def _build_pattern_context(
    rows: List[Dict[str, Any]],
    steps_goal: Optional[int],
    rhr_baseline: Optional[float],
) -> Dict[str, Any]:
    """Derive honest multi-day trend facts from the activity rows.

    Every value here is REAL (a count of days, an averaged number, or a
    consecutive-streak length). Each ``*_days`` count is only emitted when it
    truly reflects ``>= _MIN_PATTERN_DAYS`` of consecutive data, so the model
    can never claim a span we did not observe. Returns a pruned dict; empty
    when there is not enough history for any pattern.
    """
    out: Dict[str, Any] = {}
    if not rows:
        return out

    # --- steps under goal, consecutive most-recent days -----------------
    if steps_goal and steps_goal > 0:
        streak = 0
        for r in rows:
            s = r.get("steps")
            if s is None:
                break
            try:
                if float(s) < float(steps_goal):
                    streak += 1
                else:
                    break
            except (TypeError, ValueError):
                break
        if streak >= _MIN_PATTERN_DAYS:
            out["steps_under_goal_days"] = streak

    # --- resting HR elevated vs baseline, consecutive most-recent days ---
    if rhr_baseline is not None:
        threshold = float(rhr_baseline) + _RHR_TREND_DELTA_BPM
        streak = 0
        elevated_vals: List[float] = []
        for r in rows:
            v = r.get("resting_heart_rate")
            if v is None:
                break
            try:
                fv = float(v)
            except (TypeError, ValueError):
                break
            if fv >= threshold:
                streak += 1
                elevated_vals.append(fv)
            else:
                break
        if streak >= _MIN_PATTERN_DAYS:
            out["rhr_elevated_days"] = streak
            out["rhr_recent_avg"] = round(sum(elevated_vals) / len(elevated_vals))

    # --- short sleep nights in a row (< 6h = 360 min) -------------------
    short_streak = 0
    short_vals: List[int] = []
    for r in rows:
        m = r.get("sleep_minutes")
        if m is None:
            break
        try:
            mi = int(m)
        except (TypeError, ValueError):
            break
        if mi <= 0:
            break
        if mi < 360:
            short_streak += 1
            short_vals.append(mi)
        else:
            break
    if short_streak >= _MIN_PATTERN_DAYS:
        out["short_sleep_nights"] = short_streak
        out["short_sleep_avg_minutes"] = round(sum(short_vals) / len(short_vals))

    return out


def _respiratory_rate_if_present(snapshot: Dict[str, Any]) -> Optional[float]:
    """Avg respiratory rate ONLY when a recent synced workout actually carries it.

    The daily Health Connect / HealthKit respiratory-rate permission was
    removed, so it is NOT a standing daily metric. It does still ride along in
    per-workout synced metadata. We surface it to the grounding context only
    when a recent workout row genuinely has it, so the guardrail may cite it
    that one time and never promises it as a daily number (no-mock rule).
    """
    for w in (snapshot.get("recent_workouts") or [])[:5]:
        if not isinstance(w, dict):
            continue
        for key in ("avg_respiratory_rate", "respiratory_rate"):
            rr = w.get(key)
            if rr is None:
                continue
            try:
                val = float(rr)
            except (TypeError, ValueError):
                continue
            if val > 0:
                return round(val, 1)
    return None


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


def _acute_recovery_signal(sb, user_id: str) -> Optional[Dict[str, Any]]:
    """Acute recovery read from recently-imported cardio + effort rating.

    Thin, fail-open wrapper over ``recovery_signal_service`` so the briefing
    can lean on the import-loop signal. Returns the compact snapshot dict only
    when there is an ACTIONABLE recovery story (go_lighter / active_recovery);
    affirming "as_planned" light cardio is noise the briefing doesn't need.
    Any failure → None (briefing behaves exactly as before).
    """
    try:
        from services.recovery_signal_service import compute_recovery_signal

        sig = compute_recovery_signal(sb, user_id)
        if sig is not None and sig.recommendation in ("go_lighter", "active_recovery"):
            return sig.to_snapshot_dict()
    except Exception as e:
        logger.debug(f"[smart_briefing] recovery signal skipped for {user_id}: {e}")
    return None


def _build_context(
    sb,
    user_id: str,
    snapshot: Dict[str, Any],
    today_workout: Optional[Dict[str, Any]],
    moment: str,
    first_name: str,
    time_of_day: str,
    extra_facts: Optional[Dict[str, Any]] = None,
) -> Dict[str, Any]:
    """Assemble the JSON-able DATA block for the prompt.

    Pulls injuries + coach-memory open loops/facts on top of the health
    snapshot. Everything here is real; the grounding set is built from this
    exact dict so the model cannot cite anything we did not provide.

    ``extra_facts`` lets a caller inject already-computed, grounded aggregates
    for a specialised moment (e.g. weekly active minutes for ``weekly_recap``,
    protein-deficit days for ``protein_trend``, a volume swing for
    ``volume_balance``). Those numbers join the grounded set too.
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

    # Multi-day pattern facts (steps under goal streak, RHR elevated streak,
    # short-sleep streak) so the model can cite a PATTERN, not just today.
    pattern = _build_pattern_context(
        _recent_activity_rows(sb, user_id),
        steps.get("goal"),
        heart_rate.get("resting_baseline"),
    )

    # Respiratory rate ONLY when a recent synced workout carries it (the daily
    # permission was removed) — never promised as a standing daily metric.
    respiratory_rate = _respiratory_rate_if_present(snapshot)

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
        # Recovery-aware import loop: an ACUTE read of recently-imported cardio
        # + the user's "Rate your Effort" rating (last 48h). Closes the loop so
        # a Hard external session yesterday tilts today's briefing toward an
        # easier/active-recovery day. Deterministic + fail-open; _prune drops it
        # when None so the briefing behaves exactly as before with no signal.
        "recovery_signal": _acute_recovery_signal(sb, user_id),
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
        # Multi-day trend facts (only present when >= _MIN_PATTERN_DAYS real
        # consecutive days exist) so the model can lead with the PATTERN.
        "trend": pattern,
        # Opportunistic only — present when a recent workout carried it.
        "respiratory_rate": respiratory_rate,
    }
    # Moment-specific grounded aggregates injected by the caller (weekly active
    # minutes, protein-deficit days, volume swing). Merged so their numbers are
    # part of the grounded set and may be cited.
    if extra_facts:
        context.update(extra_facts)
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


def _fmt_hm(total_minutes: Optional[int]) -> Optional[str]:
    """Render minutes as "6h16m" / "45m". None passes through."""
    if total_minutes is None:
        return None
    try:
        m = int(total_minutes)
    except (TypeError, ValueError):
        return None
    if m <= 0:
        return None
    h, mm = divmod(m, 60)
    if h and mm:
        return f"{h}h{mm}m"
    if h:
        return f"{h}h"
    return f"{mm}m"


def build_deterministic_recap(
    snapshot: Dict[str, Any],
    first_name: str,
    today_workout_done: Optional[bool] = None,
) -> Optional[Dict[str, Any]]:
    """Number-safe EVENING recap built ONLY from real snapshot numbers.

    This is the no-silent-drop fallback for ``evening_recap``: when the LLM
    path returns None (Gemini down, or it cited an ungrounded number), we still
    send a grounded recap rather than going silent — but every number here is
    pulled straight from the snapshot, so there is no mock data. Returns
    ``None`` only when there is genuinely nothing real to say.

    The copy uses small variant pools (human voice, not a single robotic
    template) and contains NO em dashes.
    """
    import random

    name = (first_name or "there").strip() or "there"
    steps = snapshot.get("steps") or {}
    recovery = snapshot.get("recovery") or {}

    steps_today = steps.get("today")
    step_goal = steps.get("goal")
    recovery_score = recovery.get("score")

    facts_parts: List[str] = []
    # Steps line (only when we actually have a count).
    if isinstance(steps_today, (int, float)) and steps_today > 0:
        if step_goal and step_goal > 0 and steps_today >= step_goal:
            step_lines = [
                f"You cleared your step goal with {int(steps_today)} steps today.",
                f"{int(steps_today)} steps today, goal met. Nice work.",
            ]
        else:
            step_lines = [
                f"You logged {int(steps_today)} steps today.",
                f"Today's movement came in at {int(steps_today)} steps.",
            ]
        facts_parts.append(random.choice(step_lines))

    # Workout line (no numbers, so always safe to include when known).
    if today_workout_done is True:
        facts_parts.append(random.choice([
            "You got your session in too.",
            "And you closed out your workout. Solid.",
        ]))
    elif today_workout_done is False:
        facts_parts.append(random.choice([
            "No session today, and that is okay.",
            "The workout slipped today, no drama.",
        ]))

    if not facts_parts:
        return None  # Nothing real to recap — skip rather than fabricate.

    # Setup-tomorrow intention, anchored to tonight (evening time-of-day).
    if isinstance(recovery_score, (int, float)) and recovery_score > 0:
        setups = [
            f"With recovery at {int(recovery_score)}, an early night sets up a strong tomorrow.",
            f"Recovery sits at {int(recovery_score)} today, so protect tonight's sleep.",
        ]
    else:
        setups = [
            "An earlier lights-out tonight sets up a strong tomorrow.",
            "Wind down a little earlier tonight and tomorrow starts well.",
        ]
    setup = random.choice(setups)

    openers = [
        f"Here is your day, {name}.",
        f"Quick wrap on today, {name}.",
        f"{name}, that is a wrap on today.",
    ]
    body = f"{random.choice(openers)} " + " ".join(facts_parts)
    message = f"{body}\n• {setup}"
    titles = [
        "Your day, wrapped",
        "How today landed",
        "Today in review",
    ]
    return {
        "has_message": True,
        "type": "smart_evening_recap",
        "title": random.choice(titles),
        "message": message,
        "brief_message": body,
        "actions": [setup],
        "facts": {
            "moment": "evening_recap",
            "steps_today": steps_today,
            "recovery_score": recovery_score,
            "delivery": "deterministic",
        },
    }


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
    extra_facts: Optional[Dict[str, Any]] = None,
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
        sb, user_id, snapshot, today_workout, moment, first_name, time_of_day,
        extra_facts=extra_facts,
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
