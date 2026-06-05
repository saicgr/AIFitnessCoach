"""
Daily Coach Insight API.

Endpoint:
  GET /api/v1/coach/daily-insight
      ?date=YYYY-MM-DD&tz=America/Chicago
      &source=home|pillar_stat
      &context=<urlencoded stat label>     (required when source=pillar_stat)
      &refresh=false

Behaviour:
- Computes local_date in the USER'S timezone (header X-User-Timezone, or
  the ?tz= query, or the DB users.timezone column, in that order). All
  reasoning is user-local — never UTC. See feedback_user_local_time_only.md.
- Cache hit: returns the cached row from coach_daily_insights immediately.
- Cache miss: assembles a snapshot from existing Supabase tables, builds
  the prompt via services/gemini/daily_insight_prompt.py, calls Gemini
  with the global+per-user concurrency limiter + cost tracker, validates
  that any numbers cited in the body match the snapshot ground truth, then
  persists and returns the row.
- Cost cap: MAX_INSIGHT_USD_PER_USER_PER_DAY = 0.02. On cap, on Gemini
  failure, or on number-mismatch validation failure, returns a
  deterministic templated fallback with source="deterministic_fallback"
  so the client can render an indicator. No silent fallback to lies.

Per CLAUDE.md: NO mock data, NO silent fallbacks to wrong values, and the
fallback path is deterministic + flagged.
"""
from __future__ import annotations

import json
import logging
import re
from datetime import date, datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Set, Tuple

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from google.genai import types
from pydantic import BaseModel

from core.auth import get_current_user
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.config import get_settings
from core.timezone_utils import resolve_timezone, user_today_date

from services.gemini.constants import (
    cost_tracker,
    gemini_generate_with_retry,
)
from services.gemini.daily_insight_prompt import build_daily_insight_prompt

logger = logging.getLogger("coach_daily_insight")

router = APIRouter()


# ---------------------------------------------------------------------------
# Hard cost cap per user per day for this surface.
# Sized for ~25 calls/day at p99 (typical call ≈ $0.0004 — Flash-lite,
# short prompt + ≤200 output tokens).
# ---------------------------------------------------------------------------
MAX_INSIGHT_USD_PER_USER_PER_DAY = 0.02

# Route whitelist must match the prompt's whitelist; mirrored here so the
# fallback path stays in-contract.
_VALID_ROUTES = {
    "/chat", "/home",
    "/workouts", "/nutrition", "/neat", "/health/sleep", "/fasting",
    "/pillar/train", "/pillar/nourish", "/pillar/move",
}
_VALID_PILLARS = {"train", "nourish", "move", "sleep", "all_done"}

# Chip action kinds the client knows how to dispatch (mirror of the prompt's
# MORNING_ACTION_KINDS + evening kinds). A chip with an unknown action is
# downgraded to a label-only reply chip rather than dropped.
_VALID_CHIP_ACTIONS = {
    "log_water_now", "log_breakfast", "plan_tomorrow_meals",
    "start_wind_down", "start_workout_now",
    # WS-B injury recovery check-in chips. The client dispatches these through
    # the chat chip handler, which calls POST /coach/injury-action with the
    # chip's body_part / injury_id context.
    "injury_resolved", "injury_extend", "start_rehab",
}


def _greeting_word(bucket: str) -> str:
    if bucket == "morning":
        return "Good morning"
    if bucket in ("midday", "afternoon"):
        return "Good afternoon"
    if bucket in ("evening", "late"):
        return "Good evening"
    return "Hi"  # quiet hours / fallback


# Variant pools (>=4 each) so the open state reads human-written and rotates
# every open — per feedback_dynamic_copy_not_robotic.
_GREETING_TAILS = (
    "what's on your mind?",
    "what can I help with?",
    "where should we start?",
    "what are we working on?",
)
_GREETING_BODIES = (
    "This is your health and fitness journey, tailored to you. Ask me anything, or try one of these:",
    "I've got your training, nutrition, and recovery in one place. Pick a starting point:",
    "Your plan adapts to your life, not the other way around. Want to:",
    "Coaching that actually remembers you. Here's where we could go:",
)
# Data-lead-in tails — used when we have real numbers to recap (vs the generic
# "what are we working on"). Variant pool per feedback_dynamic_copy_not_robotic.
_GREETING_DATA_TAILS = (
    "here's where you stand.",
    "here's your day so far.",
    "I've been keeping track.",
    "here's the picture.",
)


def _fmt_sleep(minutes: int) -> str:
    h, m = minutes // 60, minutes % 60
    return f"{h}h {m}m" if m else f"{h}h"


def _grounded_greeting_lines(
    snapshot: Dict[str, Any], next_workout: Optional[Dict[str, Any]]
) -> List[str]:
    """Build 1-3 human-voice, snapshot-backed recap sentences (today + week +
    cycle/injury/streak). Only includes sub-facts that have real data — every
    number comes straight from the snapshot, so it can never fabricate."""
    lines: List[str] = []

    # --- Today: weave the logged facts into one natural sentence. ---
    nourish = snapshot.get("nourish") or {}
    move = snapshot.get("move") or {}
    sleep = snapshot.get("sleep") or {}
    today_bits: List[str] = []
    cal = nourish.get("calories_logged")
    if cal:
        cal_t = nourish.get("calorie_target")
        today_bits.append(f"logged {cal:,} kcal" + (f" of {cal_t:,}" if cal_t else ""))
    sleep_min = sleep.get("total_minutes")
    if sleep_min:
        today_bits.append(f"slept {_fmt_sleep(int(sleep_min))}")
    steps = move.get("steps")
    if steps:
        today_bits.append(f"hit {steps:,} steps")
    if today_bits:
        if len(today_bits) == 1:
            lines.append(f"Today you've {today_bits[0]}.")
        else:
            lines.append("Today you've " + ", ".join(today_bits[:-1]) + f" and {today_bits[-1]}.")

    # --- Today's workout. ---
    if next_workout:
        nm = next_workout.get("name") or "your session"
        if next_workout.get("completed"):
            lines.append(f"Nice work finishing {nm}.")
        else:
            lines.append(f"{nm} is on the plan today.")

    # --- This week. ---
    weekly = snapshot.get("weekly") or {}
    wk_bits: List[str] = []
    wc = weekly.get("workouts_completed")
    if wc:
        wk_bits.append(f"{wc} workout{'s' if wc != 1 else ''}")
    avg_sleep = weekly.get("avg_sleep_minutes")
    if avg_sleep:
        wk_bits.append(f"averaging {_fmt_sleep(int(avg_sleep))} sleep")
    if wk_bits:
        lines.append("This week: " + ", ".join(wk_bits) + ".")

    # --- Cycle / injury / streak (qualitative, no fabricated numbers). ---
    phase = snapshot.get("cycle_phase")
    if phase in ("menstrual", "follicular", "ovulation", "luteal"):
        lines.append(f"You're in your {phase} phase right now.")
    streak = snapshot.get("streak_days")
    if streak and streak >= 2:
        lines.append(f"{streak}-day streak going. 🔥")
    return lines


def _build_greeting(
    *, first_name: str, bucket: str, snapshot: Dict[str, Any],
    next_workout: Optional[Dict[str, Any]], local_date_iso: str, rotate: int,
) -> Dict[str, Any]:
    """Deterministic DATA-GROUNDED open state (no LLM, no cost). When the user
    has logged data it recaps today + this week across nutrition/sleep/steps/
    workout/cycle; otherwise it falls back to a friendly generic invite. `rotate`
    varies phrasing/chips per open without server randomness leaking into tests."""
    word = _greeting_word(bucket)
    grounded = _grounded_greeting_lines(snapshot, next_workout)

    if grounded:
        tail = _GREETING_DATA_TAILS[rotate % len(_GREETING_DATA_TAILS)]
        # Lead with the recap; cap at 3 sentences so the card stays scannable.
        body = " ".join(grounded[:3])
    else:
        tail = _GREETING_TAILS[rotate % len(_GREETING_TAILS)]
        body = _GREETING_BODIES[rotate % len(_GREETING_BODIES)]
    headline = f"{word}, {first_name}! {tail[0].upper()}{tail[1:]}"

    # --- Data-derived suggestion chips (label-only reply chips). ---
    injury = snapshot.get("injury") or {}
    nourish = snapshot.get("nourish") or {}
    sleep = snapshot.get("sleep") or {}
    pool: List[Dict[str, Any]] = []
    # Most-contextual chip first (pinned).
    if next_workout and next_workout.get("completed"):
        pool.append({"label": "🍎 What should I eat to recover?"})
    elif next_workout:
        pool.append({"label": "🏋️ What's my workout today?"})
    else:
        pool.append({"label": "🏋️ Build me a workout for today"})
    if injury.get("body_part"):
        pool.append({"label": f"🩹 How's my {injury['body_part']} feeling?"})
    if not nourish.get("calories_logged"):
        pool.append({"label": "🍽️ Log what I ate and break it down"})
    if sleep.get("applicable", True) and sleep.get("total_minutes"):
        pool.append({"label": "😴 How was my recovery last night?"})
    # Evergreen extras to round out / rotate.
    pool.append({"label": "🍎 What should I eat after my workout?"})
    pool.append({"label": "🎯 Set up a health goal that fits my life"})
    pool.append({"label": "💬 I have a question about my plan"})

    rest = pool[1:]
    if rest:
        off = rotate % len(rest)
        rest = rest[off:] + rest[:off]
    # Dedup by label, keep first 3.
    chips: List[Dict[str, Any]] = []
    seen = set()
    for c in [pool[0]] + rest:
        if c["label"] in seen:
            continue
        chips.append(c)
        seen.add(c["label"])
        if len(chips) >= 3:
            break

    return {
        "headline": headline[:90],
        "body": body,
        "chips": chips,
        "cta_primary": {"label": "Ask coach", "route": "/chat"},
        "leading_pillar": None,
    }


def _sanitize_chips(raw: Any) -> Optional[List[Dict[str, Any]]]:
    """Validate Gemini-emitted chips. Each becomes {label, route?, action?}:
    a valid route, a known action, or label-only (a plain reply chip — used by
    memory check-ins like 'Back feels better'). Returns None when empty."""
    if not isinstance(raw, list):
        return None
    out: List[Dict[str, Any]] = []
    for c in raw[:4]:
        if not isinstance(c, dict):
            continue
        label = (c.get("label") or "").strip()
        if not label:
            continue
        chip: Dict[str, Any] = {"label": label[:40]}
        # Gemini sometimes packs the destination under a single "route_or_action"
        # key — disambiguate by shape: a leading "/" means a route, else an
        # action kind. Explicit route/action keys win when present.
        combo = c.get("route_or_action")
        route = c.get("route") or (combo if isinstance(combo, str) and combo.startswith("/") else None)
        action = c.get("action") or c.get("kind") or (
            combo if isinstance(combo, str) and not combo.startswith("/") else None
        )
        if isinstance(route, str) and route in _VALID_ROUTES:
            chip["route"] = route
        elif isinstance(action, str) and action in _VALID_CHIP_ACTIONS:
            chip["action"] = action
        # else: label-only reply chip (no route/action) — valid.
        out.append(chip)
    return out or None


# ---------------------------------------------------------------------------
# Response model
# ---------------------------------------------------------------------------
class CtaModel(BaseModel):
    label: str
    route: str


class ChipModel(BaseModel):
    """A quick-reply / action chip under a rich briefing. Exactly one of route
    or action is set; a label-only chip is a plain reply (sends label as a
    message — used for memory check-ins like "Back feels better")."""
    label: str
    route: Optional[str] = None
    action: Optional[str] = None


class DailyInsightResponse(BaseModel):
    insight_id: Optional[str] = None
    local_date: str
    source: str               # "home" or "pillar_stat"
    headline: str
    body: str
    cta_primary: Optional[CtaModel] = None
    cta_secondary: Optional[CtaModel] = None
    chips: Optional[List[ChipModel]] = None
    leading_pillar: Optional[str] = None
    generated_at: Optional[str] = None
    # "gemini" on the happy path, "deterministic_fallback" otherwise.
    delivery: str = "gemini"
    # Grounded inline graphs (sleep ring + recovery signals + steps) for the
    # rich morning/evening briefings — the GenericBlocksRenderer schema. None
    # for lightweight sources or when the user has no health data.
    blocks: Optional[List[Dict[str, Any]]] = None


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
def _time_of_day_bucket(now_local: datetime) -> str:
    """Map local hour-of-day into the prompt's branching buckets."""
    h = now_local.hour
    if 5 <= h <= 10:
        return "morning"
    if 11 <= h <= 13:
        return "midday"
    if 14 <= h <= 17:
        return "afternoon"
    if 18 <= h <= 21:
        return "evening"
    if 22 <= h <= 23:
        return "late"
    return "quiet"  # 00:00–04:59


# Sources whose COPY is time-of-day specific (greetings / daily briefings that
# open with "Start your day" / "Wind down" etc.). A cached row for one of these
# must be regenerated once the local clock crosses into a different coarse
# phase — otherwise the morning briefing is reused verbatim at 11pm. The
# pillar-stat / nutrition-card / workout-card sources are NOT time-of-day copy
# and are left cached for the whole day.
_TIME_SENSITIVE_SOURCES = frozenset({
    "home",
    "greeting",
    "morning_brief",
    "morning_brief_onboarding",
    "evening_recap",
})

# How many glance graphs the home coach card shows (lead pillar first, then
# priority). The client renders them stacked + compact.
_HOME_BLOCK_COUNT = 3


def _coarse_phase(bucket: str) -> str:
    """Collapse the fine time buckets into the 3 phases that change the copy's
    framing, so we regenerate at most ~twice a day (morning→day→evening) rather
    than on every fine bucket flip."""
    if bucket == "morning":
        return "morning"
    if bucket in ("midday", "afternoon"):
        return "day"
    # evening / late / quiet all read as "wind-down / late" framing.
    return "evening"


def _first_name(user_row: Dict[str, Any]) -> str:
    """Derive a clean first name with safe fallback to the email handle."""
    raw = (
        user_row.get("first_name")
        or (user_row.get("name") or "").split(" ")[0]
        or (user_row.get("email") or "").split("@")[0]
        or "there"
    )
    return raw.strip() or "there"


def _collect_snapshot(sb, user_id: str, local_date_iso: str) -> Dict[str, Any]:
    """Assemble the today snapshot the prompt + validator both consume.

    Lightweight queries — we deliberately don't reach into the full score
    pipeline here. The home daily-score card already computes the full
    snapshot client-side; this endpoint only needs enough ground truth to
    write a single sentence and validate the numbers it contains.
    Every block is wrapped so a single failing table doesn't 500 the
    whole insight (we just omit that pillar).
    """
    snapshot: Dict[str, Any] = {
        "local_date": local_date_iso,
        "train": {"applicable": True, "completion": 0, "reach_met": False},
        "nourish": {"applicable": True, "completion": 0, "reach_met": False},
        "move": {"applicable": True, "completion": 0, "reach_met": False},
        "sleep": {"applicable": True, "completion": 0, "reach_met": False},
    }

    # --- Today's scheduled workout (Train pillar) -----------------------
    # Schema reality: workouts has no `scheduled_time` column. Drop it.
    next_workout: Optional[Dict[str, Any]] = None
    try:
        tw = sb.client.table("workouts").select(
            "id, name, scheduled_date, completed_at, duration_minutes"
        ).eq("user_id", user_id).eq(
            "scheduled_date", local_date_iso
        ).limit(1).execute()
        if tw.data:
            row = tw.data[0]
            next_workout = {
                "name": row.get("name"),
                "completed": row.get("completed_at") is not None,
            }
            snapshot["train"]["reach_met"] = next_workout["completed"]
            snapshot["train"]["completion"] = 100 if next_workout["completed"] else 0
        else:
            # No scheduled workout today → pillar is a rest day, not unmet.
            snapshot["train"]["applicable"] = False
    except Exception as e:
        logger.warning(f"[daily_insight] workouts lookup failed: {e}")

    # --- Nourish (food log totals) --------------------------------------
    # Schema reality: table is `food_logs` (plural), no `logged_local_date`
    # column — log timestamp is `logged_at` (UTC timestamptz). Calorie field
    # is `total_calories`. Derive the local-day window from local_date_iso
    # against the user's tz at query time.
    try:
        # ISO-format local date → UTC bounds. Without the user's tz here we
        # fall back to a generous ±18h window around the local-date midnight
        # in UTC, then group by logged_at::date in the user's tz on the
        # client side (the totals are an approximation either way for the
        # prompt; the validator only needs honest ground truth).
        day_start_iso = f"{local_date_iso}T00:00:00+00:00"
        day_end_iso = f"{local_date_iso}T23:59:59+00:00"
        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, logged_at, deleted_at"
        ).eq("user_id", user_id).gte(
            "logged_at", day_start_iso
        ).lte(
            "logged_at", day_end_iso
        ).is_("deleted_at", "null").execute()
        rows = fl.data or []
        cal = sum((r.get("total_calories") or 0) for r in rows)
        protein = sum(float(r.get("protein_g") or 0) for r in rows)
        snapshot["nourish"]["calories_logged"] = round(cal)
        snapshot["nourish"]["protein_logged_g"] = round(protein)
    except Exception as e:
        logger.warning(f"[daily_insight] food_logs lookup failed: {e}")

    # --- Move + Sleep (both live in daily_activity, single query) -------
    # Schema reality: date column is `activity_date` (not `local_date`).
    # No separate `sleep` table — sleep is `daily_activity.sleep_minutes`.
    try:
        da = sb.client.table("daily_activity").select(
            "steps, active_minutes, activity_date, sleep_minutes"
        ).eq("user_id", user_id).eq(
            "activity_date", local_date_iso
        ).maybe_single().execute()
        if da and da.data:
            snapshot["move"]["steps"] = int(da.data.get("steps") or 0)
            snapshot["move"]["active_minutes"] = int(da.data.get("active_minutes") or 0)
            sleep_min = int(da.data.get("sleep_minutes") or 0)
            if sleep_min > 0:
                snapshot["sleep"]["total_minutes"] = sleep_min
                snapshot["sleep"]["total_hours"] = round(sleep_min / 60.0, 1)
            else:
                # No sleep recorded today → not applicable so the prompt /
                # leverage picker skips it. Matches the client-side
                # sleepScoreProvider returning null on disconnected health.
                snapshot["sleep"]["applicable"] = False
    except Exception as e:
        logger.warning(f"[daily_insight] daily_activity lookup failed: {e}")

    # --- User goal --------------------------------------------------------
    # Schema reality: users.daily_calorie_target / daily_protein_target_g
    # (not the non-prefixed versions). No step_goal or sleep_goal_hours
    # columns — those defaults are baked in client-side via healthGoalsProvider
    # (10k steps / 480 min sleep) so we hard-code matching defaults here.
    try:
        u = sb.client.table("users").select(
            "primary_goal, daily_protein_target_g, daily_calorie_target, "
            "created_at, onboarding_completed"
        ).eq("id", user_id).maybe_single().execute()
        if u and u.data:
            snapshot["goal"] = u.data.get("primary_goal")
            snapshot["nourish"]["calorie_target"] = u.data.get("daily_calorie_target")
            snapshot["nourish"]["protein_target_g"] = u.data.get("daily_protein_target_g")
            # Lifecycle signals (home welcome / welcome-back states).
            snapshot["onboarding_completed"] = u.data.get("onboarding_completed")
            created = u.data.get("created_at")
            if created:
                try:
                    cdt = datetime.fromisoformat(str(created).replace("Z", "+00:00"))
                    snapshot["account_age_days"] = max(
                        0, (datetime.now(timezone.utc) - cdt).days
                    )
                except Exception:
                    pass
        # Defaults matched to the client (lib/data/services/health_goals_service.dart).
        snapshot["move"]["step_target"] = 10000
        snapshot["sleep"]["target_hours"] = 8.0
    except Exception as e:
        logger.warning(f"[daily_insight] users lookup failed: {e}")

    # --- Cycle phase (plan §10) ---------------------------------------
    # Source of truth: the `user_current_cycle_phase` VIEW
    # (backend/migrations/121_hormonal_health_kegel.sql:587). It exposes
    # `current_phase` ∈ {menstrual, follicular, ovulation, luteal, NULL}.
    # NULL means the user does not have menstrual tracking enabled or
    # hasn't logged a period start — treat as no signal and omit the field.
    # Wrapped so a missing/empty view never 500s the insight.
    try:
        cp = sb.client.table("user_current_cycle_phase").select(
            "current_phase"
        ).eq("user_id", user_id).maybe_single().execute()
        if cp and cp.data:
            phase = cp.data.get("current_phase")
            if phase in ("menstrual", "follicular", "ovulation", "luteal"):
                snapshot["cycle_phase"] = phase
    except Exception as e:
        # Phantom view / RLS / table-missing on a non-female-tracking user
        # all funnel here — silent skip is correct.
        logger.debug(f"[daily_insight] cycle phase lookup skipped: {e}")

    # --- Training load / ACWR (Gap 1) ---------------------------------------
    # The Stats-tab insight already cites ACWR, but the HOME card + morning/
    # evening briefs (this snapshot) never did — so the coach couldn't deliver
    # the video's signature "your load is high + you slept short → go lighter
    # and lean on recovery food" line on the surface users actually see. Attach
    # the state + acute/acwr ints (they auto-join the number guardrail). Mirror
    # the cycle block: best-effort, omit on calibration/no-data so the prompt
    # never narrates a metric the user can't see.
    try:
        from services.training_load_service import current_state
        st = current_state(sb, user_id)
        if st and st.state and st.state != "calibration":
            snapshot["training_load_state"] = st.state
            if st.acwr is not None:
                # 1-decimal ACWR is the human-facing form; store the rounded int
                # of acute load so any number the coach cites is snapshot-backed.
                snapshot["acwr"] = round(float(st.acwr), 2)
            snapshot["acute_load"] = int(round(st.acute_load))
            snapshot["chronic_load"] = int(round(st.chronic_load))
    except Exception as e:
        logger.debug(f"[daily_insight] training load lookup skipped: {e}")

    # --- This week (last 7 days) — so the coach opening references recent
    # history, not just today. Each sub-block best-effort. -------------------
    weekly: Dict[str, Any] = {}
    try:
        from datetime import date as _date, timedelta as _td
        base = _date.fromisoformat(local_date_iso)
        wk_start_iso = (base - _td(days=6)).isoformat()
        wk_start_utc = f"{wk_start_iso}T00:00:00+00:00"
        # Workouts completed this week.
        try:
            wkw = sb.client.table("workouts").select("id", count="exact").eq(
                "user_id", user_id
            ).eq("is_completed", True).gte("completed_at", wk_start_utc).execute()
            weekly["workouts_completed"] = int(wkw.count or 0) if wkw.count is not None else len(wkw.data or [])
        except Exception as e:
            logger.debug(f"[daily_insight] weekly workouts skipped: {e}")
        # daily_activity: avg steps + avg sleep across the week.
        try:
            wda = sb.client.table("daily_activity").select(
                "steps, sleep_minutes, activity_date"
            ).eq("user_id", user_id).gte("activity_date", wk_start_iso).execute()
            rows = wda.data or []
            steps = [int(r.get("steps") or 0) for r in rows if (r.get("steps") or 0) > 0]
            sleeps = [int(r.get("sleep_minutes") or 0) for r in rows if (r.get("sleep_minutes") or 0) > 0]
            if steps:
                weekly["avg_steps"] = int(round(sum(steps) / len(steps)))
            if sleeps:
                weekly["avg_sleep_minutes"] = int(round(sum(sleeps) / len(sleeps)))
        except Exception as e:
            logger.debug(f"[daily_insight] weekly activity skipped: {e}")
        # Days with a food log this week.
        try:
            wfl = sb.client.table("food_logs").select("logged_at").eq(
                "user_id", user_id
            ).gte("logged_at", wk_start_utc).is_("deleted_at", "null").execute()
            days_logged = {str(r.get("logged_at"))[:10] for r in (wfl.data or []) if r.get("logged_at")}
            if days_logged:
                weekly["nutrition_days_logged"] = len(days_logged)
        except Exception as e:
            logger.debug(f"[daily_insight] weekly nutrition skipped: {e}")
        if weekly:
            snapshot["weekly"] = weekly
    except Exception as e:
        logger.debug(f"[daily_insight] weekly block skipped: {e}")

    # --- Active injury (phase) — so the opening can ask a check-in ----------
    try:
        from services.coach.injury_directives import resolve_injury_directives
        u = sb.client.table("users").select("active_injuries").eq(
            "id", user_id
        ).maybe_single().execute()
        raw_inj = (u.data or {}).get("active_injuries") if u and u.data else None
        if raw_inj:
            d = resolve_injury_directives(raw_inj)
            active = d.get("active") or []
            if active:
                a0 = active[0]
                snapshot["injury"] = {
                    "body_part": a0.get("body_part"),
                    "phase": a0.get("phase"),
                }
    except Exception as e:
        logger.debug(f"[daily_insight] injury block skipped: {e}")

    # --- Current workout streak --------------------------------------------
    try:
        us = sb.client.table("user_streaks").select(
            "current_streak, last_activity_date"
        ).eq("user_id", user_id).eq("streak_type", "workout").maybe_single().execute()
        if us and us.data:
            from datetime import date as _date2
            last = us.data.get("last_activity_date")
            stored = int(us.data.get("current_streak") or 0)
            # A streak is only "current" if the last activity was within ~1 day.
            if last and stored > 0:
                try:
                    last_d = _date2.fromisoformat(str(last)[:10])
                    if (_date2.fromisoformat(local_date_iso) - last_d).days <= 1:
                        snapshot["streak_days"] = stored
                except Exception:
                    pass
    except Exception as e:
        logger.debug(f"[daily_insight] streak block skipped: {e}")

    # --- Recent PRs (last 30 days) — lets the coach anchor a training nudge in
    # real progress ("3 PRs this month, go for one more") instead of a generic
    # line. Mirrors the workout_stats PR block; best-effort, omit on none. ------
    try:
        cutoff_30 = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        pr = sb.client.table("personal_records").select(
            "id", count="exact"
        ).eq("user_id", user_id).gte("achieved_at", cutoff_30).execute()
        n_pr = int(pr.count or 0) if pr.count is not None else len(pr.data or [])
        if n_pr > 0:
            snapshot["pr_count_30d"] = n_pr
    except Exception as e:
        logger.debug(f"[daily_insight] PR-count block skipped: {e}")

    # --- Readiness / recovery (today, else yesterday) — a SUBJECTIVE recovery
    # signal beyond raw sleep duration, so the coach can say "you slept 7h but
    # reported high soreness, keep today easy". readiness_score is 0-100 (higher
    # = better, a safe groundable number); the raw 1-7 Hooper inputs are exposed
    # as QUALITATIVE strings (low/moderate/high) so the number guardrail never
    # rejects an "N/7" the body might print. (migration 057_scores_system) ------
    try:
        _yest_iso = (date.fromisoformat(local_date_iso) - timedelta(days=1)).isoformat()
        rs = sb.client.table("readiness_scores").select(
            "score_date, readiness_score, sleep_quality, muscle_soreness"
        ).eq("user_id", user_id).in_(
            "score_date", [local_date_iso, _yest_iso]
        ).order("score_date", desc=True).limit(1).execute()
        if rs.data:
            r0 = rs.data[0]
            rec: Dict[str, Any] = {}
            if r0.get("readiness_score") is not None:
                rec["readiness_score_0to100"] = int(r0["readiness_score"])

            def _band(v, low_hi, mid_hi):  # 1-7 Hooper → qualitative
                if v is None:
                    return None
                v = int(v)
                return "low" if v <= low_hi else ("moderate" if v <= mid_hi else "high")

            sleep_q = r0.get("sleep_quality")  # 1 poor .. 7 great
            if sleep_q is not None:
                rec["sleep_quality"] = (
                    "poor" if int(sleep_q) <= 2 else ("fair" if int(sleep_q) <= 4 else "good")
                )
            soreness = _band(r0.get("muscle_soreness"), 2, 4)  # 1 none .. 7 very sore
            if soreness is not None:
                rec["muscle_soreness"] = soreness
            if rec:
                snapshot["readiness"] = rec
    except Exception as e:
        logger.debug(f"[daily_insight] readiness block skipped: {e}")

    # --- Weight vs goal — grounds a nutrition / progress nudge in the user's
    # own trajectory ("1.4 kg from your goal"). Body weight is tracked in kg
    # (separate from workout lbs). Only emitted when BOTH a recent log and a
    # target exist. (weight_logs migration 054; users.target_weight_kg) --------
    try:
        wl = sb.client.table("weight_logs").select(
            "weight_kg, logged_at"
        ).eq("user_id", user_id).order("logged_at", desc=True).limit(1).execute()
        target_w = None
        try:
            uw = sb.client.table("users").select("target_weight_kg").eq(
                "id", user_id
            ).maybe_single().execute()
            target_w = (uw.data or {}).get("target_weight_kg") if uw and uw.data else None
        except Exception:
            target_w = None
        if wl.data and wl.data[0].get("weight_kg") is not None and target_w:
            cur_w = round(float(wl.data[0]["weight_kg"]), 1)
            tgt_w = round(float(target_w), 1)
            snapshot["weight"] = {
                "current_kg": cur_w,
                "target_kg": tgt_w,
                "to_goal_kg": round(abs(cur_w - tgt_w), 1),
            }
    except Exception as e:
        logger.debug(f"[daily_insight] weight block skipped: {e}")

    # --- Lifecycle (new / returning / active) — drives the home welcome states.
    # Cheap: reuses the already-collected onboarding flag, account age, this
    # week's aggregates, and today's pillar data. No extra queries.
    try:
        onboarded = snapshot.get("onboarding_completed")
        age = snapshot.get("account_age_days")  # may be None
        weekly = snapshot.get("weekly") or {}
        recently_active = bool(
            (weekly.get("workouts_completed") or 0) > 0
            or (weekly.get("nutrition_days_logged") or 0) > 0
            or weekly.get("avg_steps")
            or weekly.get("avg_sleep_minutes")
        )
        today_active = bool(
            (snapshot["nourish"].get("calories_logged") or 0) > 0
            or (snapshot["move"].get("steps") or 0) > 0
            or snapshot["train"].get("reach_met")
        )
        if onboarded is False:
            lifecycle = "new"
        elif not recently_active and not today_active:
            # Onboarded but silent across the whole 7-day window. A young account
            # is still "new" (never really started); an older one is "returning".
            lifecycle = "new" if (age is not None and age < 3) else "returning"
        else:
            lifecycle = "active"
        snapshot["lifecycle"] = lifecycle
    except Exception as e:
        logger.debug(f"[daily_insight] lifecycle calc skipped: {e}")
        snapshot["lifecycle"] = "active"

    return snapshot, next_workout


# ---------------------------------------------------------------------------
# Number-mismatch validator (server-side ground truth guardrail, plan §6f)
# ---------------------------------------------------------------------------
# We extract every standalone integer (and a few simple "Ng" / "Nh" forms)
# from the Gemini body and verify each one appears as some real value in
# the snapshot. If even one cited number isn't backed by ground truth we
# reject the response and fall back to deterministic copy — better a
# templated message than a hallucinated stat shown to the user.
_NUMBER_RE = re.compile(r"\b(\d{1,5}(?:,\d{3})*)(?:\.\d+)?\b")


def _snapshot_number_set(snapshot: Dict[str, Any]) -> set:
    """Flatten every numeric value from the snapshot into a string set."""
    out: set = set()

    def _walk(v):
        if isinstance(v, dict):
            for vv in v.values():
                _walk(vv)
        elif isinstance(v, list):
            for vv in v:
                _walk(vv)
        elif isinstance(v, bool):
            return  # bools are ints in Python; skip
        elif isinstance(v, (int, float)):
            out.add(str(int(v)))
            # Also accept the rounded-hours rendering for sleep (e.g. 6.5).
            if isinstance(v, float) and not v.is_integer():
                out.add(f"{v:.1f}")

    _walk(snapshot)
    # Trivially safe constants — never reject these.
    out.update({"0", "1", "2", "3"})
    return out


def _validate_insight_numbers(body: str, snapshot: Dict[str, Any]) -> bool:
    """Return True iff every number cited in `body` is grounded in snapshot.

    Edge cases handled:
      - Comma-thousands ("4,200") normalised to "4200".
      - Trivial small ints (0-3) are always allowed (sentence counters).
      - Empty body → True (nothing to validate against).
    """
    if not body:
        return True
    grounded = _snapshot_number_set(snapshot)
    for match in _NUMBER_RE.finditer(body):
        token = match.group(1).replace(",", "")
        if token not in grounded:
            logger.warning(
                f"[daily_insight] number guardrail rejected '{token}' "
                f"(grounded={sorted(grounded)[:10]}...)"
            )
            return False
    return True


# ---------------------------------------------------------------------------
# Deterministic fallback templates (mirrors score_coach_line.dart pool logic)
# ---------------------------------------------------------------------------
# Per feedback_dynamic_copy_not_robotic.md: ≥4 variants per pattern, and
# substitute real data. Per feedback_no_em_dashes_marketing.md / the prompt
# rules: zero em/en dashes — graps for "—" / "–" before shipping.
_FALLBACK_TEMPLATES: Dict[str, Dict[str, list]] = {
    "train": {
        "headline": [
            "Today's lift is ready",
            "Your workout is queued",
            "One session stands between today and done",
            "Time to move the needle",
        ],
        "body": [
            "{first_name}, {workout} is on the plan for today. Knock it out and you'll close the Train ring.",
            "{first_name}, you have {workout} scheduled. Even a short version counts toward the streak.",
            "{first_name}, the plan calls for {workout}. Open it and the first set is the hardest part.",
            "{first_name}, {workout} is waiting. Start it now and momentum does the rest.",
        ],
        "cta_primary": {"label": "Start workout", "route": "/workouts/today"},
    },
    "nourish": {
        "headline": [
            "Protein is the lever today",
            "Lock in the fuel",
            "Food log is your edge",
            "Eat the work in",
        ],
        "body": [
            "{first_name}, log what you've eaten so far and we'll show what's left for the day.",
            "{first_name}, a quick log keeps the calorie picture honest. Snap or type one entry.",
            "{first_name}, today's nutrition target is in reach with one solid meal logged.",
            "{first_name}, the food log takes ten seconds and saves a lot of guessing later.",
        ],
        "cta_primary": {"label": "Log food", "route": "/log/food"},
    },
    "move": {
        "headline": [
            "Stack a few more steps",
            "Move minutes are the gap",
            "A short walk closes the ring",
            "Move pillar needs a nudge",
        ],
        "body": [
            "{first_name}, a ten minute walk now puts the Move ring in reach.",
            "{first_name}, the daily steps total is short. One block around the building helps.",
            "{first_name}, active minutes are the weakest signal today. Get up and stretch the legs.",
            "{first_name}, momentum on Move is one short walk away.",
        ],
        "cta_primary": {"label": "View Move", "route": "/move"},
    },
    "sleep": {
        "headline": [
            "Last night was light",
            "Recovery is the priority",
            "Sleep is the weakest link",
            "Wind down a little earlier",
        ],
        "body": [
            "{first_name}, last night ran short. Aim for an earlier wind down tonight.",
            "{first_name}, sleep is the gap to close. Tonight's bedtime matters more than today's gym.",
            "{first_name}, recovery is the lever. Plan for a longer night and the rest of the plan flows.",
            "{first_name}, an extra forty minutes tonight beats an extra rep today.",
        ],
        "cta_primary": {"label": "View sleep", "route": "/sleep"},
    },
    "all_done": {
        "headline": [
            "Every ring closed today",
            "Clean sweep on the plan",
            "You hit the brief",
            "Day delivered",
        ],
        "body": [
            "{first_name}, every pillar is in the green for today. Coast and let recovery work.",
            "{first_name}, the full plan is done. Hydrate, eat well tonight, sleep early.",
            "{first_name}, that's a complete day. The streak just got a little longer.",
            "{first_name}, nothing left on the board. Bank the recovery for tomorrow.",
        ],
        "cta_primary": {"label": "Open home", "route": "/home"},
    },
}


def _pick_fallback_pillar(snapshot: Dict[str, Any]) -> str:
    """Choose the leading pillar for the deterministic fallback.

    Priority order matches the prompt's LEADING_PILLAR RULES so the
    fallback feels coherent with happy-path output.
    """
    train = snapshot.get("train", {})
    nourish = snapshot.get("nourish", {})
    move = snapshot.get("move", {})
    sleep = snapshot.get("sleep", {})

    train_open = train.get("applicable") and not train.get("reach_met")
    nourish_open = (nourish.get("calorie_target") or 0) > 0 and (
        (nourish.get("calories_logged") or 0) < (nourish.get("calorie_target") or 0) * 0.5
    )
    move_open = (move.get("step_target") or 0) > 0 and (
        (move.get("steps") or 0) < (move.get("step_target") or 0) * 0.5
    )
    sleep_open = (sleep.get("target_hours") or 0) > 0 and (
        (sleep.get("total_hours") or 0) < (sleep.get("target_hours") or 0) - 0.5
    )

    if train_open:
        return "train"
    if nourish_open:
        return "nourish"
    if move_open:
        return "move"
    if sleep_open:
        return "sleep"
    # Never celebrate "all done" for a user who has nothing set up — that reads
    # as "Every ring closed today" to someone who has done nothing (the home
    # new-user case is short-circuited to a welcome upstream; this guards the
    # other sources). Only claim all-done when a pillar was actually configured.
    configured = bool(
        train.get("applicable")
        or (nourish.get("calorie_target") or 0) > 0
        or move.get("steps") is not None
        or sleep.get("total_minutes") is not None
    )
    return "all_done" if configured else "nourish"


def _deterministic_fallback(
    snapshot: Dict[str, Any],
    next_workout: Optional[Dict[str, Any]],
    first_name: str,
    local_date_iso: str,
    source: str,
) -> Dict[str, Any]:
    """Build the fallback insight payload. Always returns valid output."""
    # Stable per-day variant selection so the user sees the same fallback
    # all day instead of flip-flopping on re-open.
    seed = abs(hash((first_name, local_date_iso))) % 4
    pillar = _pick_fallback_pillar(snapshot)
    tmpl = _FALLBACK_TEMPLATES[pillar]

    workout_name = (next_workout or {}).get("name") or "today's session"
    body = tmpl["body"][seed % len(tmpl["body"])].format(
        first_name=first_name, workout=workout_name,
    )
    headline = tmpl["headline"][seed % len(tmpl["headline"])]
    cta_primary = dict(tmpl["cta_primary"])
    cta_secondary = {"label": "Ask coach", "route": "/chat"}

    return {
        "headline": headline,
        "body": body,
        "cta_primary": cta_primary,
        "cta_secondary": cta_secondary,
        "leading_pillar": pillar,
    }


def _welcome_payload(
    first_name: str, lifecycle: str, local_date_iso: str,
) -> Dict[str, Any]:
    """Warm, deterministic home coach copy for a new (welcome) or returning
    (welcome-back) user. Time-agnostic; tolerates a missing name (drops the
    vocative). ≥4 variants per pool; stable per day. No em/en dashes."""
    name = first_name if (first_name and first_name != "there") else None
    vocative = f", {name}" if name else ""
    seed = abs(hash((first_name, local_date_iso, lifecycle))) % 4
    if lifecycle == "returning":
        headlines = [
            f"Welcome back{vocative}!",
            f"Good to see you{vocative}.",
            f"You're back{vocative}!",
            f"Let's pick it up{vocative}.",
        ]
        bodies = [
            "It's been a minute. Pick one thing today, a workout or a logged meal, and we're rolling again.",
            "No pressure on the gap. Log a meal or start a workout and your plan springs back to life.",
            "Ease back in with one session or one logged meal, and I'll re-tune everything to you.",
            "Glad you're here again. One small action today restarts the momentum, your call which.",
        ]
        primary = {"label": "Pick today's workout", "route": "/workouts"}
    else:  # new
        headlines = [
            f"Welcome to Zealova{vocative}!",
            f"Let's get you started{vocative}.",
            f"Glad you're here{vocative}.",
            f"Your coaching starts now{vocative}.",
        ]
        bodies = [
            "I'm your AI coach. Generate today's workout or log a meal, and I'll start tailoring everything to you.",
            "Start with one thing, a workout or a logged meal, and your daily plan comes to life.",
            "Build your first workout or snap a meal to log it, and real, personalized coaching kicks in.",
            "Lay the first brick today: a workout or a logged meal. The rest of your plan follows.",
        ]
        primary = {"label": "Start a workout", "route": "/workouts"}
    return {
        "headline": headlines[seed % len(headlines)],
        "body": bodies[seed % len(bodies)],
        "cta_primary": primary,
        "cta_secondary": {"label": "Chat with coach", "route": "/chat"},
        "leading_pillar": None,
    }


# ---------------------------------------------------------------------------
# Workout-stats snapshot (source=workout_stats) — training-trend ground truth
# ---------------------------------------------------------------------------
# Deterministic push/pull classifier. The DB's exercise_library.force_type is
# the preferred signal, but many logged exercises are stored under canonical
# slug ids that don't join by name, so we keep a keyword fallback. This is
# DETERMINISTIC classification, not LLM safety classification — allowed per
# feedback_no_llm_for_safety_classification (that rule bans LLM SAFETY tagging,
# not deterministic movement bucketing).
_PUSH_KEYWORDS = (
    "bench", "press", "push", "dip", "fly", "flye", "pushdown", "extension",
    "tricep", "crossover", "raise",  # lateral/front raises are press-pattern delts
    "squat", "leg press", "lunge", "calf", "thruster",
)
_PULL_KEYWORDS = (
    "row", "pull", "pulldown", "pullup", "pull-up", "chin", "curl", "deadlift",
    "rdl", "romanian", "face pull", "pullover", "shrug", "leg curl",
)


def _classify_push_pull(name: str, force_type: Optional[str]) -> Optional[str]:
    """Return "push" | "pull" | None for one exercise.

    force_type from the DB wins when present (push/pull/static). Otherwise a
    keyword scan on the name. Returns None for unclassifiable / static moves
    so they don't pollute the ratio.
    """
    ft = (force_type or "").strip().lower()
    if ft in ("push", "pull"):
        return ft
    if ft == "static":
        return None
    low = (name or "").lower()
    # Pull keywords first — "leg curl" / "face pull" must not match push "raise".
    for kw in _PULL_KEYWORDS:
        if kw in low:
            return "pull"
    for kw in _PUSH_KEYWORDS:
        if kw in low:
            return "push"
    return None


def _collect_workout_stats_snapshot(
    sb, user_id: str, today_local: date
) -> Dict[str, Any]:
    """Assemble the training-trend snapshot for source=workout_stats.

    All values are REAL aggregates. Fields:
      volume_4wk_kg, volume_prev_4wk_kg, volume_delta_pct,
      push_sets, pull_sets, push_pull_ratio,
      acwr, acwr_state, pr_count_30d, current_streak.

    Every block is wrapped so one failing table omits its field rather than
    500ing the insight. NO fabrication — empty history yields zeros/nulls.
    """
    snap: Dict[str, Any] = {
        "volume_4wk_kg": 0.0,
        "volume_prev_4wk_kg": 0.0,
        "volume_delta_pct": None,
        "push_sets": 0,
        "pull_sets": 0,
        "push_pull_ratio": None,
        "acwr": None,
        "acwr_state": "calibration",
        "pr_count_30d": 0,
        "current_streak": 0,
    }

    # --- Volume: this 4wk vs prior 4wk + push/pull split over last 4wk -----
    # Window in user-local dates. recorded_at is UTC; we compare on date only,
    # which is adequate at the 4-week granularity (a handful of boundary sets
    # never move the aggregate meaningfully).
    try:
        cur_start = today_local - timedelta(days=27)        # last 28 days incl today
        prev_start = today_local - timedelta(days=55)        # 28 days before that
        prev_end = today_local - timedelta(days=28)
        pull_cutoff = datetime.combine(
            prev_start, datetime.min.time(), tzinfo=timezone.utc
        )

        rows = sb.client.table("performance_logs").select(
            "exercise_name, reps_completed, weight_kg, recorded_at, is_completed"
        ).eq("user_id", user_id).gte(
            "recorded_at", pull_cutoff.isoformat()
        ).execute()

        # Preload force_type for the distinct exercise names in one query.
        names = sorted({
            (r.get("exercise_name") or "").strip()
            for r in (rows.data or [])
            if r.get("exercise_name")
        })
        force_by_name: Dict[str, str] = {}
        if names:
            try:
                # Case-insensitive match is not available via in_(); fetch the
                # whole small set by name and key case-insensitively.
                fl = sb.client.table("exercise_library").select(
                    "exercise_name, force_type"
                ).in_("exercise_name", names).execute()
                for r in (fl.data or []):
                    nm = (r.get("exercise_name") or "").strip().lower()
                    if nm and r.get("force_type"):
                        force_by_name[nm] = r["force_type"]
            except Exception as e:
                logger.debug(f"[workout_stats] force_type lookup skipped: {e}")

        cur_vol = prev_vol = 0.0
        push_sets = pull_sets = 0
        for r in (rows.data or []):
            if r.get("is_completed") is False:
                continue
            reps = r.get("reps_completed")
            if not isinstance(reps, (int, float)) or reps <= 0:
                continue
            ra = r.get("recorded_at")
            if not ra:
                continue
            try:
                ts = datetime.fromisoformat(str(ra).replace("Z", "+00:00"))
                if ts.tzinfo is None:
                    ts = ts.replace(tzinfo=timezone.utc)
                d = ts.astimezone(timezone.utc).date()
            except Exception:
                continue

            w = r.get("weight_kg")
            wkg = float(w) if isinstance(w, (int, float)) and w > 0 else 0.0
            vol = wkg * float(reps)

            if cur_start <= d <= today_local:
                cur_vol += vol
                bucket = _classify_push_pull(
                    r.get("exercise_name") or "",
                    force_by_name.get((r.get("exercise_name") or "").strip().lower()),
                )
                if bucket == "push":
                    push_sets += 1
                elif bucket == "pull":
                    pull_sets += 1
            elif prev_start <= d <= prev_end:
                prev_vol += vol

        snap["volume_4wk_kg"] = round(cur_vol, 1)
        snap["volume_prev_4wk_kg"] = round(prev_vol, 1)
        if prev_vol > 0:
            snap["volume_delta_pct"] = round((cur_vol - prev_vol) / prev_vol * 100.0, 1)
        snap["push_sets"] = push_sets
        snap["pull_sets"] = pull_sets
        if pull_sets > 0:
            snap["push_pull_ratio"] = round(push_sets / pull_sets, 2)
    except Exception as e:
        logger.warning(f"[workout_stats] volume/split block failed: {e}")

    # --- ACWR state (training_load_service) -------------------------------
    try:
        from services.training_load_service import current_state
        st = current_state(sb, user_id)
        snap["acwr"] = st.acwr
        snap["acwr_state"] = st.state
    except Exception as e:
        logger.warning(f"[workout_stats] ACWR block failed: {e}")

    # --- PR count last 30 days --------------------------------------------
    try:
        cutoff_30 = (datetime.now(timezone.utc) - timedelta(days=30)).isoformat()
        # personal_records is the curated PR table the Stats tab reads.
        pr = sb.client.table("personal_records").select(
            "id", count="exact"
        ).eq("user_id", user_id).gte("achieved_at", cutoff_30).execute()
        snap["pr_count_30d"] = int(pr.count or 0) if pr.count is not None else len(pr.data or [])
    except Exception as e:
        logger.warning(f"[workout_stats] PR-count block failed: {e}")

    # --- Current workout streak -------------------------------------------
    # user_streaks holds the stored streak, but it is only "current" if the
    # last activity was within 1 day of today. A stale streak (last activity
    # weeks ago) is BROKEN — reporting the stored number would be a lie.
    try:
        us = sb.client.table("user_streaks").select(
            "current_streak, last_activity_date"
        ).eq("user_id", user_id).eq("streak_type", "workout").maybe_single().execute()
        if us and us.data:
            last = us.data.get("last_activity_date")
            stored = int(us.data.get("current_streak") or 0)
            if last:
                try:
                    last_d = date.fromisoformat(str(last)[:10])
                    if (today_local - last_d).days <= 1:
                        snap["current_streak"] = stored
                    else:
                        snap["current_streak"] = 0  # streak broken
                except Exception:
                    snap["current_streak"] = 0
    except Exception as e:
        logger.debug(f"[workout_stats] streak block skipped: {e}")

    return snap


def _workout_stats_fallback(
    snapshot: Dict[str, Any],
    first_name: str,
    local_date_iso: str,
) -> Dict[str, Any]:
    """Deterministic fallback for source=workout_stats.

    Headline + body are derived from the REAL snapshot — no fabricated
    numbers. Picks the single most notable signal in priority order. Stable
    per-day variant selection so the line doesn't flip-flop on re-open.
    """
    seed = abs(hash((first_name, local_date_iso))) % 4

    vol = snapshot.get("volume_4wk_kg") or 0.0
    prev = snapshot.get("volume_prev_4wk_kg") or 0.0
    delta = snapshot.get("volume_delta_pct")
    push = int(snapshot.get("push_sets") or 0)
    pull = int(snapshot.get("pull_sets") or 0)
    ratio = snapshot.get("push_pull_ratio")
    acwr_state = snapshot.get("acwr_state") or "calibration"
    prs = int(snapshot.get("pr_count_30d") or 0)
    streak = int(snapshot.get("current_streak") or 0)

    headline = "Your training trend"
    body = ""

    # Priority 1: overreaching / detraining ACWR.
    if acwr_state == "overreaching":
        headline = "Load is running hot"
        body = (
            f"{first_name}, your recent training load is well above baseline. "
            f"Take an easy day or a full rest day to let it settle."
        )
    elif acwr_state == "detraining":
        headline = "Load has dropped off"
        body = (
            f"{first_name}, your recent load is below your baseline. "
            f"A moderate session this week keeps your fitness from slipping."
        )
    # Priority 2: lopsided push/pull.
    elif ratio is not None and (ratio > 1.5 or ratio < 0.67) and (push + pull) >= 6:
        if ratio > 1.5:
            headline = "Push is outpacing pull"
            body = (
                f"{first_name}, last 4 weeks ran {push} push sets to {pull} pull sets. "
                f"Add a row or pulldown to balance your shoulders."
            )
        else:
            headline = "Pull is outpacing push"
            body = (
                f"{first_name}, last 4 weeks ran {pull} pull sets to {push} push sets. "
                f"Add a press to even out the ratio."
            )
    # Priority 3: notable volume swing.
    elif delta is not None and delta >= 10:
        headline = "Volume is trending up"
        body = (
            f"{first_name}, your 4-week volume rose {abs(delta):.0f} percent. "
            f"Keep progressing while recovery holds up."
        )
    elif delta is not None and delta <= -10:
        headline = "Volume is trending down"
        body = (
            f"{first_name}, your 4-week volume fell {abs(delta):.0f} percent. "
            f"One extra set per lift this week nudges it back up."
        )
    # Priority 4: fresh PRs.
    elif prs > 0:
        headline = "New ground this month"
        body = (
            f"{first_name}, you set {prs} personal "
            f"record{'s' if prs != 1 else ''} in the last 30 days. "
            f"Strong work, keep the bar moving."
        )
    # Priority 5: streak signal.
    elif streak >= 2:
        headline = "Streak is alive"
        body = (
            f"{first_name}, you are on a {streak}-day training streak. "
            f"Get one more session in to extend it."
        )
    elif streak == 0 and vol == 0 and prev == 0:
        headline = "Let's start building data"
        body = (
            f"{first_name}, log a few sessions and your training trends will "
            f"start to show here. The first workout is the hardest to start."
        )
    else:
        # Neutral, honest default — references real volume if present.
        pools = [
            f"{first_name}, your last 4 weeks totalled {vol:.0f} kg of volume. "
            f"Steady work builds the base.",
            f"{first_name}, training is ticking along. Pick one lift to push a "
            f"little harder this week.",
            f"{first_name}, your volume is holding steady. Consistency is the "
            f"engine here.",
            f"{first_name}, nothing alarming in the trend. Keep showing up and "
            f"the numbers follow.",
        ]
        body = pools[seed % len(pools)]

    return {
        "headline": headline,
        "body": body,
        "cta_primary": {"label": "Open workouts", "route": "/workouts"},
        "cta_secondary": {"label": "Ask coach", "route": "/chat"},
        "leading_pillar": "train",
    }


# ---------------------------------------------------------------------------
# Gemini call
# ---------------------------------------------------------------------------
def _robust_parse_json_object(text: str) -> Optional[Dict[str, Any]]:
    """Parse Gemini JSON output that may carry trailing tokens, leading
    whitespace, or markdown fences.

    Handles three failure modes observed in production:
      * Markdown fence wrapping (```json ... ```)
      * Leading/trailing whitespace
      * "Extra data" — trailing prose after a valid JSON object
    Returns None on unrecoverable failure (caller logs and falls back).
    """
    if not text:
        return None
    s = text.strip()
    # Strip ```json ... ``` fence if present.
    if s.startswith("```"):
        s = re.sub(r"^```(?:json)?\s*", "", s)
        s = re.sub(r"\s*```$", "", s).strip()
    # Fast path.
    try:
        return json.loads(s)
    except json.JSONDecodeError:
        pass
    # Recover from trailing junk via raw_decode at the first '{'.
    first = s.find("{")
    if first < 0:
        return None
    try:
        obj, _end = json.JSONDecoder().raw_decode(s[first:])
        if isinstance(obj, dict):
            return obj
    except json.JSONDecodeError as e:
        logger.error(f"[daily_insight] robust parse gave up: {e} — text head: {s[:200]!r}")
    return None


async def _call_gemini_for_insight(
    *, context: Dict[str, Any], source: str, user_id: str,
) -> Optional[Dict[str, Any]]:
    """Run Gemini with the daily-insight prompt. Return parsed dict or None on failure."""
    settings = get_settings()
    system_instruction, user_message = build_daily_insight_prompt(context, source)
    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=user_message,
            config=types.GenerateContentConfig(
                system_instruction=system_instruction,
                response_mime_type="application/json",
                # 320 -> 420: room for the user's name + one richer data
                # reference (coach-memory fact / PR / sleep-quality / weight)
                # now that the home insight grounds in more signals, while
                # keeping the body to 2-3 sentences. Cached 12h, so the marginal
                # token cost is once/user/day.
                max_output_tokens=420,
                temperature=0.5,
            ),
            user_id=user_id,
            # The insight is cached (12h) and rendered async, so it's
            # latency-tolerant — give Gemini a wider timeout + an extra retry so
            # a transient blip recovers to a real, personalized insight instead
            # of dropping to the generic deterministic fallback (issue #8). The
            # fallback is still never persisted, so this never traps a user on
            # generic copy: the next open re-attempts generation.
            timeout=20.0,
            max_retries=4,
            method_name="daily_insight",
        )
        text = getattr(response, "text", None)
        if not text:
            return None
        parsed = _robust_parse_json_object(text)
        if parsed is None:
            return None
        # Light shape validation — drop unknown routes/pillars before persisting.
        if parsed.get("leading_pillar") not in _VALID_PILLARS:
            parsed["leading_pillar"] = None
        for k in ("cta_primary", "cta_secondary"):
            cta = parsed.get(k)
            if isinstance(cta, dict) and cta.get("route") not in _VALID_ROUTES:
                # Reject silently — fallback CTA gets stamped in by caller.
                parsed[k] = None
        # Quick-reply / action chips (morning_brief / evening_recap).
        parsed["chips"] = _sanitize_chips(parsed.get("chips"))
        return parsed
    except Exception as e:
        logger.warning(f"[daily_insight] Gemini call failed: {e}")
        return None


def _user_cost_today_usd(user_id: str) -> float:
    """Read this-user-today cost from the in-process tracker."""
    try:
        snap = cost_tracker.snapshot()
        return float((snap.get("by_user", {}).get(user_id) or {}).get("cost_usd", 0.0))
    except Exception:
        return 0.0


# ---------------------------------------------------------------------------
# Endpoint
# ---------------------------------------------------------------------------
@router.get("/daily-insight", response_model=DailyInsightResponse)
async def daily_insight(
    request: Request,
    date_str: Optional[str] = Query(None, alias="date", description="YYYY-MM-DD; user-local"),
    tz: Optional[str] = Query(None, description="IANA tz override; header wins if both present"),
    source: str = Query("home", description="home | pillar_stat"),
    context: Optional[str] = Query(None, description="Pillar stat label (source=pillar_stat only)"),
    refresh: bool = Query(False, description="Force regenerate, bypassing cache"),
    current_user: dict = Depends(get_current_user),
):
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]

        # ---- Resolve user-local date (header > query > DB > UTC) ----------
        # resolve_timezone reads X-User-Timezone first. If neither header
        # nor DB has a tz, but the caller passed ?tz=, prefer that over UTC.
        tz_resolved = resolve_timezone(request, sb, user_id)
        if tz_resolved == "UTC" and tz:
            tz_resolved = tz
        if date_str:
            try:
                local_date = date.fromisoformat(date_str)
            except ValueError:
                raise HTTPException(400, "date must be YYYY-MM-DD")
        else:
            local_date = user_today_date(request, sb, user_id)
        local_date_iso = local_date.isoformat()

        # ---- Validate source + stat_context --------------------------------
        # Plan P3e expanded the surface vocabulary. Each one routes to a
        # different branch in daily_insight_prompt.py. All share the same
        # cost cap + cache row shape; only `pillar_stat` carries a
        # stat_context, the others use stat_context=NULL as the cache key.
        _ALLOWED_SOURCES = {
            "home",
            "pillar_stat",
            "morning_brief",
            "evening_recap",
            "greeting",
            "morning_brief_onboarding",
            "nutrition_card_morning",
            # Phase 2 of the contextual-nudge merge: lunch + dinner each get
            # a dedicated prompt branch in daily_insight_prompt.py so the
            # body line can RAG the user's typical lunch / dinner pattern
            # and hit slot-specific macro targets.
            "nutrition_card_lunch",
            "nutrition_card_dinner",
            "workout_card",
            # Stats-tab training-trend insight: volume deltas, push/pull split,
            # ACWR state, recent PR count, current streak. Same Gemini +
            # number-guardrail + deterministic-fallback path; dedicated snapshot.
            "workout_stats",
        }
        if source not in _ALLOWED_SOURCES:
            raise HTTPException(
                400,
                f"source must be one of {sorted(_ALLOWED_SOURCES)}",
            )
        stat_context = context if source == "pillar_stat" else None

        # Grounded inline graphs for the rich daily briefings (sleep ring +
        # recovery signals + steps), built FRESH from the user's real data so a
        # cached briefing's graph still reflects today. Best-effort: None on no
        # data, never fatal. Computed once, attached to every return path.
        # Fix 3: the light `greeting` (shown the rest of the day, incl. the
        # user's late-night open) now also carries grounded graphs so the coach
        # opening always shows real data, not a canned prompt.
        briefing_blocks: Optional[List[Dict[str, Any]]] = None
        if source in ("morning_brief", "evening_recap", "morning_brief_onboarding", "greeting"):
            try:
                from services.coach.chat_blocks import build_briefing_blocks
                briefing_blocks = build_briefing_blocks(user_id) or None
            except Exception as e:
                logger.warning(f"[daily_insight] briefing blocks build failed: {e}")
                briefing_blocks = None
        # NOTE: home blocks are built LATER (in each return path) via
        # `_home_blocks(pillar)` — they lead with the tip's leading_pillar, which
        # isn't known until the cached row is read / the insight is generated.

        def _home_blocks(pillar: Optional[str]) -> Optional[List[Dict[str, Any]]]:
            """Up to _HOME_BLOCK_COUNT glance graphs for the home card, led by the
            tip's pillar. Best-effort — never fatal."""
            try:
                from services.coach.chat_blocks import build_briefing_blocks
                return build_briefing_blocks(
                    user_id, leading_pillar=pillar, max_blocks=_HOME_BLOCK_COUNT
                ) or None
            except Exception as e:
                logger.warning(f"[daily_insight] home block build failed: {e}")
                return None

        if source == "pillar_stat" and not stat_context:
            raise HTTPException(400, "context query param required for source=pillar_stat")

        # ---- Cache hit? ----------------------------------------------------
        if not refresh:
            try:
                q = sb.client.table("coach_daily_insights").select("*").eq(
                    "user_id", user_id
                ).eq("local_date", local_date_iso).eq("source", source)
                if stat_context is not None:
                    q = q.eq("stat_context", stat_context)
                else:
                    q = q.is_("stat_context", "null")
                # ORDER BY generated_at DESC: a NULL stat_context (home / briefings)
                # can have multiple rows for the same day (see persist note below),
                # so without an order the limit(1) returned the OLDEST row — i.e. a
                # stale "this morning" tip shown all day. Always serve the newest.
                existing = q.order("generated_at", desc=True).limit(1).execute()
                if existing and existing.data:
                    row = existing.data[0]
                    # Time-of-day staleness: a greeting/briefing generated this
                    # morning must NOT be replayed at night ("Start your day" at
                    # 11pm). If the row's generated_at lands in a different
                    # coarse phase than now (both in the user's tz), skip the
                    # cache and regenerate — the upsert below overwrites the row.
                    _phase_stale = False
                    if source in _TIME_SENSITIVE_SOURCES and row.get("generated_at"):
                        try:
                            from zoneinfo import ZoneInfo
                            _zone = ZoneInfo(tz_resolved if tz_resolved else "UTC")
                            _gen_local = datetime.fromisoformat(
                                row["generated_at"]
                            ).astimezone(_zone)
                            _now_local = datetime.now(_zone)
                            _phase_stale = _coarse_phase(
                                _time_of_day_bucket(_gen_local)
                            ) != _coarse_phase(_time_of_day_bucket(_now_local))
                        except Exception as e:
                            # Parse/tz error → safe to serve the cached row.
                            logger.warning(
                                f"[daily_insight] phase-staleness check skipped: {e}"
                            )
                    if not _phase_stale:
                        return DailyInsightResponse(
                            insight_id=row.get("id"),
                            local_date=row["local_date"],
                            source=row["source"],
                            headline=row["headline"],
                            body=row["body"],
                            cta_primary=row.get("cta_primary"),
                            cta_secondary=row.get("cta_secondary"),
                            chips=row.get("chips"),
                            leading_pillar=row.get("leading_pillar"),
                            generated_at=row.get("generated_at"),
                            delivery="gemini",  # cached rows stored only on success
                            blocks=(
                                _home_blocks(row.get("leading_pillar"))
                                if source == "home" else briefing_blocks
                            ),
                        )
            except HTTPException:
                raise
            except Exception as e:
                logger.warning(f"[daily_insight] cache read failed (continuing): {e}")

        # ---- Historical-date guard ----------------------------------------
        # For a PAST date with no stored row, do NOT generate a fresh insight:
        # generation runs against the user's *current* snapshot, which would
        # fabricate a "that day's tip" from today's data — a lie when replayed
        # in the timeline. Only today (and future, for previews) may compute on
        # a cache miss. Past days simply have no recorded tip → 404, which the
        # client renders as "no tip for that day" (graphs still show).
        if not refresh:
            try:
                today_local = user_today_date(request, sb, user_id)
            except Exception:
                today_local = local_date
            if local_date < today_local:
                raise HTTPException(
                    status_code=404,
                    detail="No coach insight was recorded for this date.",
                )

        # ---- Assemble snapshot + context ----------------------------------
        # Schema reality: users.first_name doesn't exist. Just `name` (full).
        # _first_name() already handles the split — it prefers first_name if
        # present, then splits `name`, then falls back to email-prefix.
        try:
            user_row_resp = sb.client.table("users").select(
                "name, email"
            ).eq("id", user_id).maybe_single().execute()
            user_row = (user_row_resp.data if user_row_resp else {}) or {}
        except Exception:
            user_row = {}
        first_name = _first_name(user_row)

        # source=workout_stats uses a dedicated TRAINING-TREND snapshot instead
        # of the daily-pillar snapshot. It carries no next_workout / cycle /
        # goal blocks — the prompt branch + fallback read its own field set.
        if source == "workout_stats":
            snapshot = _collect_workout_stats_snapshot(sb, user_id, local_date)
            next_workout = None
        else:
            snapshot, next_workout = _collect_snapshot(sb, user_id, local_date_iso)

        from zoneinfo import ZoneInfo
        now_local = datetime.now(ZoneInfo(tz_resolved if tz_resolved else "UTC"))
        ctx: Dict[str, Any] = {
            "first_name": first_name,
            "today_score_snapshot": snapshot,
            "next_workout": next_workout,
            "goals": snapshot.get("goal"),
            "user_local_tz": tz_resolved,
            "time_of_day_bucket": _time_of_day_bucket(now_local),
            # Plan §10 — null when the user has no cycle tracking enabled.
            "cycle_phase": snapshot.get("cycle_phase"),
        }
        if source == "pillar_stat":
            ctx["pillar_stat_context"] = stat_context

        # Long-term coach memory (migration 2217). The rich daily briefings
        # weave it in (durable facts + open loops -> tailored plan + check-in
        # question); the home card also taps it now so a durable fact the user
        # told the coach (e.g. "vegetarian", "recovering back", "training for a
        # 5K") personalizes the daily insight instead of a generic pillar line.
        # Best-effort: empty/absent on any failure. (Home doesn't surface open
        # loops as a check-in question — that stays a briefing behaviour — so it
        # does not mark loops surfaced; see the _surfaced_loop_ids guard below.)
        _surfaced_loop_ids: list = []
        if source in ("morning_brief", "evening_recap", "home"):
            try:
                from services.coach.memory.injector import build_memory_block_for_briefing
                ctx["coach_memory"] = build_memory_block_for_briefing(user_id)
                # Only the briefings ASK an open-loop check-in question, so only
                # they spend the loop's nag budget. Home weaves a durable fact
                # for personalization without surfacing/advancing open loops.
                if source in ("morning_brief", "evening_recap"):
                    _surfaced_loop_ids = [
                        l.get("id")
                        for l in (ctx["coach_memory"].get("open_loops") or [])
                        if l.get("id")
                    ]
            except Exception as e:
                logger.warning(f"[daily_insight] memory block failed: {e}")

        # ---- Light greeting (deterministic, no LLM, no cost) --------------
        # The Ask-Coach open state when there's no heavy briefing to show.
        # Returns immediately — never persisted, never cached, rotates per open.
        if source == "greeting":
            g = _build_greeting(
                first_name=first_name,
                bucket=_time_of_day_bucket(now_local),
                snapshot=snapshot,
                next_workout=next_workout,
                local_date_iso=local_date_iso,
                rotate=now_local.hour * 60 + now_local.minute,
            )
            return DailyInsightResponse(
                insight_id=None,
                local_date=local_date_iso,
                source=source,
                headline=g["headline"],
                body=g["body"],
                cta_primary=g.get("cta_primary"),
                cta_secondary=None,
                chips=g.get("chips"),
                leading_pillar=None,
                generated_at=datetime.now(timezone.utc).isoformat(),
                delivery="deterministic",
                blocks=briefing_blocks,
            )

        # ---- Home welcome / welcome-back (deterministic, no LLM) -----------
        # A brand-new user has no data to ground a Gemini tip, and the old
        # fallback misfired to "Every ring closed today" (all pillars read
        # "not open" when nothing is set up). A returning-after-a-gap user
        # should be greeted, not handed a cold leverage line. Short-circuit
        # both to a warm deterministic welcome. ("active" falls through to the
        # normal Gemini path below, unchanged.)
        if source == "home" and snapshot.get("lifecycle") in ("new", "returning"):
            w = _welcome_payload(
                first_name, snapshot.get("lifecycle"), local_date_iso,
            )
            return DailyInsightResponse(
                insight_id=None,
                local_date=local_date_iso,
                source=source,
                headline=w["headline"],
                body=w["body"],
                cta_primary=w.get("cta_primary"),
                cta_secondary=w.get("cta_secondary"),
                chips=None,
                leading_pillar=None,
                generated_at=datetime.now(timezone.utc).isoformat(),
                delivery="deterministic",
                blocks=_home_blocks(None),  # empty for a no-data user → text-only
            )

        # ---- Cost cap check -----------------------------------------------
        delivery = "gemini"
        gemini_payload: Optional[Dict[str, Any]] = None
        if _user_cost_today_usd(user_id) >= MAX_INSIGHT_USD_PER_USER_PER_DAY:
            logger.info(f"[daily_insight] user={user_id} cost cap hit, using fallback")
            delivery = "deterministic_fallback"
        else:
            gemini_payload = await _call_gemini_for_insight(
                context=ctx, source=source, user_id=user_id,
            )
            if gemini_payload is None:
                delivery = "deterministic_fallback"
            else:
                # Ground-truth number guardrail (plan §6f).
                if not _validate_insight_numbers(gemini_payload.get("body", ""), snapshot):
                    logger.warning(f"[daily_insight] user={user_id} number guardrail rejected payload")
                    delivery = "deterministic_fallback"
                    gemini_payload = None

        # ---- Build final payload ------------------------------------------
        if delivery == "deterministic_fallback":
            if source == "workout_stats":
                payload = _workout_stats_fallback(
                    snapshot=snapshot,
                    first_name=first_name,
                    local_date_iso=local_date_iso,
                )
            else:
                payload = _deterministic_fallback(
                    snapshot=snapshot,
                    next_workout=next_workout,
                    first_name=first_name,
                    local_date_iso=local_date_iso,
                    source=source,
                )
        else:
            payload = gemini_payload or {}
            # Stamp safe defaults for any missing CTA so the client never NPEs.
            if not payload.get("cta_primary"):
                payload["cta_primary"] = {"label": "Open home", "route": "/home"}
            if not payload.get("cta_secondary"):
                payload["cta_secondary"] = {"label": "Ask coach", "route": "/chat"}

        # ---- Persist ONLY when Gemini succeeded and passed validation -----
        insight_id: Optional[str] = None
        generated_at_iso = datetime.now(timezone.utc).isoformat()
        if delivery == "gemini":
            try:
                insert_payload = {
                    "user_id": user_id,
                    "local_date": local_date_iso,
                    "headline": payload["headline"],
                    "body": payload["body"],
                    "cta_primary": payload.get("cta_primary"),
                    "cta_secondary": payload.get("cta_secondary"),
                    "leading_pillar": payload.get("leading_pillar"),
                    "chips": payload.get("chips"),
                    "source": source,
                    "stat_context": stat_context,
                    "generated_at": generated_at_iso,
                }
                # Delete-then-insert (not upsert): the on_conflict target
                # `user_id,local_date,source,stat_context` does NOT dedupe when
                # stat_context is NULL (home / briefings) because Postgres treats
                # NULLs as DISTINCT in a unique index — so the old upsert inserted
                # a brand-new row on every regeneration, piling up same-day
                # duplicates. Clearing the matching key first guarantees exactly
                # one current row per (user, date, source, stat_context).
                delq = sb.client.table("coach_daily_insights").delete().eq(
                    "user_id", user_id
                ).eq("local_date", local_date_iso).eq("source", source)
                if stat_context is not None:
                    delq = delq.eq("stat_context", stat_context)
                else:
                    delq = delq.is_("stat_context", "null")
                delq.execute()
                ins = sb.client.table("coach_daily_insights").insert(
                    insert_payload,
                ).execute()
                if ins and ins.data:
                    insight_id = ins.data[0].get("id")
                    generated_at_iso = ins.data[0].get("generated_at", generated_at_iso)
            except Exception as e:
                # Persist failure is non-fatal — still return the payload.
                logger.warning(f"[daily_insight] persist failed: {e}")

        # Advance the open-loop nag budget for any loops this fresh briefing
        # surfaced (migration 2217). Cache hits + the greeting path return
        # earlier, so this fires at most once/day per source: it bumps
        # follow_up_count + pushes follow_up_after out, and auto-retires a loop
        # once it's been surfaced its budget (so the coach never nags forever).
        if _surfaced_loop_ids:
            try:
                from services.coach.memory.pipeline import mark_loops_surfaced
                mark_loops_surfaced(user_id, _surfaced_loop_ids)
            except Exception as e:
                logger.warning(f"[daily_insight] mark_loops_surfaced failed: {e}")

        return DailyInsightResponse(
            insight_id=insight_id,
            local_date=local_date_iso,
            source=source,
            headline=payload["headline"],
            body=payload["body"],
            cta_primary=payload.get("cta_primary"),
            cta_secondary=payload.get("cta_secondary"),
            chips=payload.get("chips"),
            leading_pillar=payload.get("leading_pillar"),
            generated_at=generated_at_iso,
            delivery=delivery,
            blocks=(
                _home_blocks(payload.get("leading_pillar"))
                if source == "home" else briefing_blocks
            ),
        )
    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "coach_daily_insight")


# ---------------------------------------------------------------------------
# WS-B: Injury recovery check-in chip actions
# ---------------------------------------------------------------------------
# The recovery check-in push (_job_injury_recovery in push_nudge_cron.py) carries
# action chips. When the user taps one in the coach chat, the Flutter chip
# handler calls this endpoint with the chip's body_part / injury_id context.
# Everything here is DETERMINISTIC (no LLM) — eligibility and the chosen action
# are decided by the chip the user tapped, not by inference.
#
#   injury_resolved → clear_injury (enters reintroduction / ease-in)
#   injury_extend   → push expected_recovery_date out a week + clear any
#                     reintroduction_until so the part keeps being protected
#   start_rehab     → persist a rehab workout from injury_service.REHAB_EXERCISES
#                     for the body part's current phase, return its id so the
#                     client routes to the existing workout card / start flow

_INJURY_ACTIONS = {"injury_resolved", "injury_extend", "start_rehab", "report_pain"}
_INJURY_EXTEND_DAYS = 7


class InjuryActionRequest(BaseModel):
    action: str
    body_part: Optional[str] = None
    injury_id: Optional[str] = None
    severity: Optional[str] = "moderate"


class InjuryActionResponse(BaseModel):
    success: bool
    action: str
    message: str
    body_part: Optional[str] = None
    workout_id: Optional[str] = None


def _find_active_injury(active: list, *, body_part: Optional[str], injury_id: Optional[str]) -> Optional[dict]:
    """Match an active_injuries entry by injury_id first, then body_part."""
    if not isinstance(active, list):
        return None
    if injury_id:
        for inj in active:
            if isinstance(inj, dict) and str(inj.get("id")) == str(injury_id):
                return inj
    if body_part:
        bp = body_part.lower().strip()
        for inj in active:
            if isinstance(inj, dict) and (inj.get("body_part") or "").lower() == bp:
                return inj
    return None


@router.post("/injury-action", response_model=InjuryActionResponse)
async def injury_action(
    payload: InjuryActionRequest,
    current_user: dict = Depends(get_current_user),
):
    """Execute a recovery check-in chip action (All better / Still sore / Do a
    rehab session). Deterministic — the tapped chip selects the action."""
    try:
        sb = get_supabase_db()
        user_id = current_user["id"]
        action = (payload.action or "").strip()
        body_part = (payload.body_part or "").lower().strip() or None
        injury_id = payload.injury_id or None

        if action not in _INJURY_ACTIONS:
            raise HTTPException(400, f"Unsupported injury action: {action}")
        if not body_part and not injury_id:
            raise HTTPException(400, "body_part or injury_id is required")

        # ── report_pain (F4) → file a provisional body-part injury into the
        # phase-aware system (active_injuries) when the user flags pain on an
        # exercise mid-workout. Deduped + phase-managed by report_injury. ──
        if action == "report_pain":
            if not body_part:
                raise HTTPException(400, "body_part is required for report_pain")
            from services.langgraph_agents.tools.injury_tools import report_injury
            sev = (payload.severity or "moderate").lower()
            if sev not in ("mild", "moderate", "severe"):
                sev = "moderate"
            result = report_injury.invoke({
                "user_id": user_id, "body_part": body_part, "severity": sev,
                "notes": "Reported during a workout (this hurts)",
            })
            return InjuryActionResponse(
                success=bool(result.get("success", True)),
                action=action,
                message=result.get("message", f"Got it — I'll protect your {body_part} and ease it back in as it recovers."),
                body_part=body_part,
            )

        # ── injury_resolved → clear (reuses the tool's reintroduction logic) ──
        if action == "injury_resolved":
            from services.langgraph_agents.tools.injury_tools import clear_injury

            result = clear_injury.invoke({
                "user_id": user_id,
                "body_part": body_part,
                "injury_id": injury_id,
                "user_feedback": "Resolved via recovery check-in (All better)",
            })
            if not result.get("success"):
                # No active injury to clear (already auto-expired) is not an
                # error from the user's perspective — confirm gracefully.
                return InjuryActionResponse(
                    success=True,
                    action=action,
                    body_part=body_part,
                    message="Glad to hear it. I've already cleared that one.",
                )
            return InjuryActionResponse(
                success=True,
                action=action,
                body_part=result.get("body_part") or body_part,
                message=result.get("message")
                or "Great. I'll ease that area back in over the next few sessions.",
            )

        # ── injury_extend → keep protecting it; push the window out a week ────
        if action == "injury_extend":
            user = sb.get_user(user_id) or {}
            active = user.get("active_injuries") or []
            if isinstance(active, str):
                try:
                    active = json.loads(active)
                except json.JSONDecodeError:
                    active = []
            inj = _find_active_injury(active, body_part=body_part, injury_id=injury_id)
            if not inj:
                return InjuryActionResponse(
                    success=True,
                    action=action,
                    body_part=body_part,
                    message="No problem, I'll keep an eye on it. Tell me anytime it changes.",
                )
            new_recovery = datetime.now(timezone.utc) + timedelta(days=_INJURY_EXTEND_DAYS)
            updated = []
            target_id = inj.get("id")
            target_bp = (inj.get("body_part") or "").lower()
            cleared_part = inj.get("body_part") or body_part
            for entry in active:
                if not isinstance(entry, dict):
                    continue
                same = (target_id and entry.get("id") == target_id) or (
                    not target_id and (entry.get("body_part") or "").lower() == target_bp
                )
                if same:
                    entry["expected_recovery_date"] = new_recovery.isoformat()
                    # Stay protected: drop any reintroduction stamp so generation
                    # keeps avoiding (not easing in) the part.
                    entry.pop("reintroduction_until", None)
                updated.append(entry)
            sb.update_user(user_id, {"active_injuries": updated})

            # Keep the injury_history row open + reflect the extended window.
            if target_id:
                try:
                    sb.client.table("injury_history").update({
                        "is_active": True,
                        "expected_recovery_date": new_recovery.isoformat(),
                    }).eq("id", target_id).execute()
                except Exception as e:
                    logger.warning(f"[injury_action] history extend failed: {e}")

            part_label = (cleared_part or "that area").replace("_", " ")
            return InjuryActionResponse(
                success=True,
                action=action,
                body_part=cleared_part,
                message=f"Got it, I'll keep training around your {part_label} and "
                        f"check back in about a week.",
            )

        # ── start_rehab → persist a rehab workout for the current phase (F1) ──
        # (action == "start_rehab")
        from services.coach.injury_directives import compute_phase
        from services import injury_service as _injury_service_mod

        injury_service = (
            _injury_service_mod.get_injury_service()
            if hasattr(_injury_service_mod, "get_injury_service")
            else _injury_service_mod
        )

        user = sb.get_user(user_id) or {}
        active = user.get("active_injuries") or []
        if isinstance(active, str):
            try:
                active = json.loads(active)
            except json.JSONDecodeError:
                active = []
        inj = _find_active_injury(active, body_part=body_part, injury_id=injury_id)
        if not inj:
            raise HTTPException(404, "No active injury found for a rehab session")

        bp = (inj.get("body_part") or body_part or "").lower().strip()
        phase = compute_phase(
            reported_at=inj.get("reported_at"),
            severity=str(inj.get("severity") or "moderate").lower(),
            reintroduction_until=inj.get("reintroduction_until"),
        )
        # Reintroduction reuses the recovery rehab block (mirrors the resolver).
        rehab_phase = "recovery" if phase == "reintroduction" else phase
        rehab = (injury_service.REHAB_EXERCISES.get(bp, {}) or {}).get(rehab_phase, [])
        if not rehab:
            # Acute back (rest only) or a body part with no rehab entry for this
            # phase — never fabricate exercises; tell the user honestly.
            raise HTTPException(
                422,
                f"No rehab session is available for your {bp.replace('_', ' ')} "
                f"in the {rehab_phase} phase yet.",
            )

        # Mirror generate_quick_workout's persisted exercise shape so the
        # existing /workout/{id} card + start flow render it unchanged.
        exercises = []
        for ex in rehab:
            if not isinstance(ex, dict):
                continue
            exercises.append({
                "name": ex.get("name", "Rehab Exercise"),
                "sets": ex.get("sets", 2),
                "reps": ex.get("reps", "10"),
                "rest_seconds": 45,
                "duration_seconds": None,
                "muscle_group": bp,
                "equipment": "Bodyweight",
                "notes": ex.get("notes", ""),
                "gif_url": "",
                "video_url": "",
                "image_url": "",
                "library_id": "",
            })

        part_label = bp.replace("_", " ")
        workout_name = f"{part_label.title()} Rehab ({rehab_phase})"
        today_utc = datetime.now(timezone.utc).date().isoformat()
        created = sb.create_workout({
            "user_id": user_id,
            "name": workout_name,
            "type": "rehab",
            "difficulty": "light",
            "scheduled_date": today_utc,
            "exercises_json": exercises,
            "duration_minutes": 12,
            "is_completed": False,
            "generation_method": "injury_rehab",
            "generation_source": "injury_checkin",
        })
        if not created or not created.get("id"):
            raise HTTPException(500, "Failed to create rehab workout")

        return InjuryActionResponse(
            success=True,
            action=action,
            body_part=bp,
            workout_id=str(created["id"]),
            message=f"Here's a gentle {part_label} rehab block for your "
                    f"{rehab_phase} phase. Take it slow.",
        )

    except HTTPException:
        raise
    except Exception as e:
        raise safe_internal_error(e, "coach_injury_action")
