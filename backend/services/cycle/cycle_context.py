"""
Cycle context assembler for the AI coach.

`build_cycle_context()` gathers a compact, agent-ready summary of a user's
menstrual-cycle situation: the current `CyclePrediction` (from the deterministic
predictor) plus a short digest of the last ~14-30 days of `hormone_logs`
(phase, cycle day, symptom / mood / energy / sleep / BBT trends, next-period &
fertile-window dates).

This is intentionally CHEAP — two DB reads (the predictor itself does its own
couple of reads, plus one `hormone_logs` window read here) and pure Python
afterwards. No LLM.

It feeds:
  * the dedicated cycle agent (Phase F) — full context block
  * the nutrition and workout agents — only the phase string + compact summary
    (never raw third-party / sensitive logs leave Zealova's own backend)

Privacy: the dict returned here stays inside the backend. The frontend never
receives `hormone_logs` rows verbatim; agents are handed a digest, not raw data.
"""
from __future__ import annotations

from datetime import date, timedelta
from typing import Any, Dict, List, Optional

from core.logger import get_logger
from services.cycle.cycle_predictor import predict_for_user

logger = get_logger(__name__)

# How many days of daily logs to digest. 30 covers roughly one full cycle of
# symptom/mood/energy context without pulling an unbounded history.
RECENT_LOG_WINDOW_DAYS = 30

# Red-flag thresholds (kept in sync with the cycle agent's guardrail prompt).
RED_FLAG_SHORT_CYCLE = 21      # avg cycle shorter than this => flag
RED_FLAG_LONG_CYCLE = 45       # avg cycle longer than this  => flag
RED_FLAG_LATE_DAYS = 7         # period this many days past the window => flag


def _fmt(d: Any) -> Optional[str]:
    """ISO-format a date-like value, tolerating None / already-strings."""
    if d is None:
        return None
    if isinstance(d, str):
        return d
    try:
        return d.isoformat()
    except Exception:
        return str(d)


def _avg(values: List[float]) -> Optional[float]:
    return round(sum(values) / len(values), 1) if values else None


def _summarize_recent_logs(rows: List[Dict[str, Any]]) -> Dict[str, Any]:
    """Digest the last ~30 days of hormone_logs into compact trend numbers.

    Returns counts + averages only — never the raw rows.
    """
    if not rows:
        return {
            "days_logged": 0,
            "avg_energy": None,
            "avg_sleep_quality": None,
            "avg_mood_score": None,
            "top_symptoms": [],
            "latest_bbt_celsius": None,
            "bbt_readings": 0,
            "period_flow_days": 0,
        }

    energy = [r["energy_level"] for r in rows if r.get("energy_level") is not None]
    sleep = [r["sleep_quality"] for r in rows if r.get("sleep_quality") is not None]

    # Map the mood enum onto a rough 1-5 score for a trend signal only.
    mood_scale = {
        "excellent": 5, "good": 4, "stable": 3,
        "low": 2, "irritable": 2, "anxious": 2, "depressed": 1,
    }
    mood_scores = [
        mood_scale[r["mood"]] for r in rows
        if r.get("mood") in mood_scale
    ]

    # Symptom frequency over the window.
    symptom_counts: Dict[str, int] = {}
    for r in rows:
        for s in (r.get("symptoms") or []):
            symptom_counts[s] = symptom_counts.get(s, 0) + 1
    top_symptoms = [
        {"symptom": s, "days": c}
        for s, c in sorted(symptom_counts.items(), key=lambda kv: kv[1], reverse=True)[:5]
    ]

    # BBT — newest reading + count. Rows are date-ascending from the caller.
    bbt_rows = [r for r in rows if r.get("basal_body_temperature") is not None]
    latest_bbt = bbt_rows[-1]["basal_body_temperature"] if bbt_rows else None

    flow_days = sum(
        1 for r in rows
        if r.get("period_flow") and r["period_flow"] not in ("none", None)
    )

    return {
        "days_logged": len(rows),
        "avg_energy": _avg([float(x) for x in energy]),
        "avg_sleep_quality": _avg([float(x) for x in sleep]),
        "avg_mood_score": _avg([float(x) for x in mood_scores]),
        "top_symptoms": top_symptoms,
        "latest_bbt_celsius": latest_bbt,
        "bbt_readings": len(bbt_rows),
        "period_flow_days": flow_days,
    }


def _detect_red_flags(prediction: Dict[str, Any]) -> List[str]:
    """Surface clinician-nudge-worthy patterns from the prediction.

    These are SIGNALS for the agent to gently raise — never a diagnosis.
    """
    flags: List[str] = []
    stats = prediction.get("stats") or {}

    avg_cycle = stats.get("avg_cycle_length")
    if avg_cycle is not None:
        if avg_cycle < RED_FLAG_SHORT_CYCLE:
            flags.append(
                f"average cycle length is short (~{avg_cycle} days, under "
                f"{RED_FLAG_SHORT_CYCLE})"
            )
        elif avg_cycle > RED_FLAG_LONG_CYCLE:
            flags.append(
                f"average cycle length is long (~{avg_cycle} days, over "
                f"{RED_FLAG_LONG_CYCLE})"
            )

    min_cycle = stats.get("min_cycle_length")
    max_cycle = stats.get("max_cycle_length")
    if min_cycle is not None and min_cycle < RED_FLAG_SHORT_CYCLE:
        flags.append(
            f"at least one recorded cycle was very short ({min_cycle} days)"
        )
    if max_cycle is not None and max_cycle > RED_FLAG_LONG_CYCLE:
        flags.append(
            f"at least one recorded cycle was very long ({max_cycle} days)"
        )

    late_by = prediction.get("period_late_by")
    if late_by is not None and late_by >= RED_FLAG_LATE_DAYS:
        flags.append(
            f"period is {late_by} days past the predicted window"
        )

    return flags


def build_cycle_context(client, user_id: str, today: date) -> Dict[str, Any]:
    """Assemble a compact cycle-context block for the AI agents.

    Args:
        client: a supabase-py PostgREST client (``get_supabase().client``).
        user_id: the user's UUID.
        today: the user's local calendar date (cycle day must not drift at
            midnight — pass the timezone-resolved date, never ``date.today()``
            on a UTC server).

    Returns a dict shaped as::

        {
          "available": bool,            # False => no cycle tracking / no data
          "phase": str | None,          # current phase string
          "cycle_day": int | None,
          "summary": str,               # 1-3 sentence human-readable digest
          "prediction": {...},          # the trimmed CyclePrediction dict
          "recent_logs": {...},         # digested 30-day trends
          "red_flags": [str, ...],      # clinician-nudge signals (may be empty)
          "tracking_mode": str,         # tracking | ttc | pregnancy
        }

    The function never raises for an absent profile or empty history — it
    returns ``available=False`` so callers can cleanly skip cycle context.
    """
    user_id = str(user_id)

    # --- Prediction (the predictor does its own couple of DB reads) ---------
    try:
        prediction = predict_for_user(client, user_id, today)
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[CycleContext] prediction failed for {user_id}: {e}")
        return {
            "available": False,
            "phase": None,
            "cycle_day": None,
            "summary": "",
            "prediction": None,
            "recent_logs": {},
            "red_flags": [],
            "tracking_mode": "tracking",
        }

    tracking_mode = prediction.get("tracking_mode") or "tracking"

    # --- Recent daily logs digest (one cheap window read) -------------------
    recent_logs: Dict[str, Any] = {}
    try:
        cutoff = (today - timedelta(days=RECENT_LOG_WINDOW_DAYS)).isoformat()
        logs_res = (
            client.table("hormone_logs")
            .select(
                "log_date,energy_level,sleep_quality,mood,symptoms,"
                "basal_body_temperature,period_flow"
            )
            .eq("user_id", user_id)
            .gte("log_date", cutoff)
            .order("log_date")
            .execute()
        )
        recent_logs = _summarize_recent_logs(logs_res.data or [])
    except Exception as e:
        logger.warning(f"[CycleContext] recent-logs read failed for {user_id}: {e}")
        recent_logs = _summarize_recent_logs([])

    red_flags = _detect_red_flags(prediction)

    # If the predictor says predictions are unavailable (no periods logged,
    # symptom-only profile, or pregnancy mode) the context is still useful for
    # symptom continuity, but there is no phase/forecast to surface.
    predictions_available = bool(prediction.get("predictions_available"))

    summary = _build_summary(
        prediction, recent_logs, red_flags, predictions_available
    )

    # Trim the prediction down to the fields agents actually cite, with dates
    # ISO-stringified so the dict is JSON-safe for prompt embedding.
    trimmed_prediction = {
        "predictions_available": predictions_available,
        "current_phase": prediction.get("current_phase"),
        "current_cycle_day": prediction.get("current_cycle_day"),
        "next_phase": prediction.get("next_phase"),
        "days_until_next_phase": prediction.get("days_until_next_phase"),
        "in_period": prediction.get("in_period"),
        "next_period_date": _fmt(prediction.get("next_period_date")),
        "next_period_window_start": _fmt(prediction.get("next_period_window_start")),
        "next_period_window_end": _fmt(prediction.get("next_period_window_end")),
        "days_until_next_period": prediction.get("days_until_next_period"),
        "period_late_by": prediction.get("period_late_by"),
        "confidence": prediction.get("confidence"),
        "ovulation_date": _fmt(prediction.get("ovulation_date")),
        "ovulation_status": prediction.get("ovulation_status"),
        "fertile_window_start": _fmt(prediction.get("fertile_window_start")),
        "fertile_window_end": _fmt(prediction.get("fertile_window_end")),
        "conception_chance": prediction.get("conception_chance"),
        "stats": prediction.get("stats") or {},
        "notes": prediction.get("notes") or [],
    }

    return {
        "available": predictions_available or recent_logs.get("days_logged", 0) > 0,
        "phase": prediction.get("current_phase"),
        "cycle_day": prediction.get("current_cycle_day"),
        "summary": summary,
        "prediction": trimmed_prediction,
        "recent_logs": recent_logs,
        "red_flags": red_flags,
        "tracking_mode": tracking_mode,
    }


def _build_summary(
    prediction: Dict[str, Any],
    recent_logs: Dict[str, Any],
    red_flags: List[str],
    predictions_available: bool,
) -> str:
    """Compose a short, human-readable digest sentence(s) for prompt context.

    All dates are framed as estimates per the project's safety guidance.
    """
    parts: List[str] = []
    mode = prediction.get("tracking_mode") or "tracking"

    if mode == "pregnancy":
        parts.append("Cycle predictions are paused (pregnancy mode is on).")
    elif not predictions_available:
        parts.append(
            "No cycle predictions yet — period history is too thin or this "
            "profile tracks symptoms only."
        )
    else:
        phase = prediction.get("current_phase")
        day = prediction.get("current_cycle_day")
        conf = prediction.get("confidence") or "low"
        if phase and day:
            parts.append(
                f"She is on cycle day {day}, estimated to be in the {phase} "
                f"phase ({conf}-confidence estimate)."
            )

        late_by = prediction.get("period_late_by")
        days_until = prediction.get("days_until_next_period")
        if late_by is not None:
            parts.append(
                f"Her period is an estimated {late_by} days later than predicted."
            )
        elif days_until is not None:
            nxt = _fmt(prediction.get("next_period_date"))
            parts.append(
                f"Her next period is estimated in ~{days_until} days "
                f"(around {nxt})."
            )

        if mode == "ttc":
            fw_start = _fmt(prediction.get("fertile_window_start"))
            fw_end = _fmt(prediction.get("fertile_window_end"))
            chance = prediction.get("conception_chance")
            if fw_start and fw_end:
                parts.append(
                    f"Estimated fertile window: {fw_start} to {fw_end} "
                    f"(conception chance today: {chance})."
                )

    # Recent-log trend digest.
    days_logged = recent_logs.get("days_logged", 0)
    if days_logged:
        trend_bits: List[str] = []
        if recent_logs.get("avg_energy") is not None:
            trend_bits.append(f"avg energy {recent_logs['avg_energy']}/10")
        if recent_logs.get("avg_sleep_quality") is not None:
            trend_bits.append(f"avg sleep quality {recent_logs['avg_sleep_quality']}/10")
        top = recent_logs.get("top_symptoms") or []
        if top:
            sym = ", ".join(f"{t['symptom']} ({t['days']}d)" for t in top[:3])
            trend_bits.append(f"most-logged symptoms: {sym}")
        if trend_bits:
            parts.append(
                f"Over the last {days_logged} logged days — " + "; ".join(trend_bits) + "."
            )

    if red_flags:
        parts.append(
            "Patterns worth a clinician's eye (not a diagnosis): "
            + "; ".join(red_flags) + "."
        )

    return " ".join(parts).strip()


def format_cycle_context_for_prompt(ctx: Optional[Dict[str, Any]]) -> str:
    """Render a cycle-context dict into a compact prompt block.

    Used by the nutrition / workout agents, which receive ONLY the phase
    string and this compact summary — never the raw `hormone_logs` rows.
    Returns "" when there is no usable context so callers can skip it.
    """
    if not ctx or not ctx.get("available"):
        return ""
    phase = ctx.get("phase")
    summary = ctx.get("summary") or ""
    lines = ["MENSTRUAL CYCLE CONTEXT (estimates — never a contraceptive method):"]
    if phase:
        lines.append(f"- Current estimated phase: {phase}")
    if ctx.get("cycle_day"):
        lines.append(f"- Cycle day: {ctx['cycle_day']}")
    if summary:
        lines.append(f"- Summary: {summary}")
    lines.append(
        "- Use this to make advice cycle-aware (energy, hunger, recovery). "
        "Do not give contraceptive or medical advice."
    )
    return "\n".join(lines)
