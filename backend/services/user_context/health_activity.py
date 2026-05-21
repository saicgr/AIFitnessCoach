"""
Health & Activity Snapshot Mixin (Phase B1)
===========================================
Gives the AI coach read access to the *full* `daily_activity` health picture —
sleep + stages, an objective recovery score + training tier, steps + 7-day
average, active calories, resting/avg/max heart rate vs a personal baseline,
water, recent workouts, weight trend, goal progress, and data staleness.

Two public methods:
  - ``get_health_activity_snapshot`` — a structured dict for programmatic use.
  - ``get_health_context_for_ai``    — a compact <150-token LLM prompt string.

Hard rules (per CLAUDE.md + the approved plan):
  * No mock / fabricated data. The "no wearable" state is NORMAL and returns
    ``{"has_data": False, "reason": ...}`` cleanly — callers must not invent
    numbers downstream.
  * Health data is Art. 9 sensitive — every read is gated by
    ``consent_guard.has_health_data_consent``. No consent => no data, cleanly.
  * The recovery score and its tier mapping are deterministic — never an LLM.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
import logging

from core.db import get_supabase_db
from services.consent_guard import has_health_data_consent
from services.readiness_service import map_recovery_to_tier

logger = logging.getLogger(__name__)


# -----------------------------------------------------------------------------
# Tuning constants — all deterministic, all documented inline.
# -----------------------------------------------------------------------------

# A sleep row older than this (in hours, measured from its wake/activity date)
# is "stale": we still report it, but flag staleness so the coach can say
# "no sleep tracked last night" honestly instead of citing an old number.
_SLEEP_STALENESS_HOURS = 36

# Implausible sleep durations are excluded from "last night" and averages
# (edge case A9). A nap-length blip or a forgotten tracker running for days.
_MIN_PLAUSIBLE_SLEEP_MIN = 30
_MAX_PLAUSIBLE_SLEEP_MIN = 16 * 60  # 16h

# Recovery score weighting (objective, sleep-derived). Sums to 1.0.
#   - duration : how close last night's asleep time is to a 480-min (8h) target
#   - efficiency: asleep / time-in-bed (already a 0-1 fraction in the DB)
#   - stages   : restorative-stage share (deep + REM) of total asleep time
# Each sub-score is 0-100; the weighted sum is the 0-100 recovery score.
_RECOVERY_W_DURATION = 0.50
_RECOVERY_W_EFFICIENCY = 0.25
_RECOVERY_W_STAGES = 0.25
_RECOVERY_SLEEP_TARGET_MIN = 480  # 8h — the duration sub-score's 100% anchor
# Healthy adults spend ~13-23% in deep and ~20-25% in REM sleep; ~40% combined
# restorative share is treated as the 100% anchor for the stage sub-score.
_RECOVERY_RESTORATIVE_TARGET_FRAC = 0.40

# Recent-workout window for the snapshot's "recent workouts" list.
_RECENT_WORKOUT_LIMIT = 5


def _utc_now() -> datetime:
    """Timezone-aware UTC now — keeps all datetime math instant-based (no
    wall-clock subtraction), matching edge case A5 (DST safety)."""
    return datetime.now(timezone.utc)


def _safe_num(value: Any) -> Optional[float]:
    """Coerce a DB value to a float, returning None for null / unparseable.
    Used so a missing column never raises and never becomes a fake 0."""
    if value is None:
        return None
    try:
        return float(value)
    except (TypeError, ValueError):
        return None


class HealthActivityMixin:
    """Mixin exposing the user's wearable health picture to the AI coach.

    Mixed into ``UserContextService`` in Phase B2 — NOT registered here.
    """

    # -------------------------------------------------------------------------
    # Recovery score (deterministic, sleep-derived)
    # -------------------------------------------------------------------------

    def _compute_recovery_score(
        self, sleep_row: Optional[Dict[str, Any]]
    ) -> Optional[int]:
        """Derive an objective 0-100 recovery score from one night's sleep row.

        `daily_activity` has no wearable-provided recovery field, so we compute
        one deterministically from the sleep columns it DOES have. Returns
        ``None`` when there is not enough sleep data to score (which the tier
        mapper then reads as "no adaptation").

        Sub-scores (each 0-100):
          duration   — asleep minutes vs an 8h target (capped at 100).
          efficiency — sleep_efficiency fraction * 100 (only if present).
          stages     — (deep + REM) / total asleep vs a 40% restorative target
                       (only if at least one stage column is present).

        Missing inputs are dropped and the remaining weights are renormalised
        so a partial-data night (edge case A7 / C19) still yields a score
        rather than nothing — but a row with NO usable sleep total returns
        ``None`` (never a fabricated number).
        """
        if not sleep_row:
            return None

        asleep_min = _safe_num(sleep_row.get("sleep_minutes"))
        if asleep_min is None or asleep_min <= 0:
            return None
        # Implausible nights are not scored (edge case A9).
        if asleep_min < _MIN_PLAUSIBLE_SLEEP_MIN or asleep_min > _MAX_PLAUSIBLE_SLEEP_MIN:
            return None

        components: List[tuple] = []  # (weight, sub_score 0-100)

        # --- duration sub-score (always available once we have asleep_min) ---
        duration_sub = min(100.0, (asleep_min / _RECOVERY_SLEEP_TARGET_MIN) * 100.0)
        components.append((_RECOVERY_W_DURATION, duration_sub))

        # --- efficiency sub-score (only when sleep_efficiency is present) ----
        efficiency = _safe_num(sleep_row.get("sleep_efficiency"))
        if efficiency is not None and efficiency > 0:
            # Stored as a 0.0-1.0 fraction; clamp defensively.
            efficiency_sub = max(0.0, min(1.0, efficiency)) * 100.0
            components.append((_RECOVERY_W_EFFICIENCY, efficiency_sub))

        # --- stages sub-score (only when deep/REM columns are present) -------
        deep = _safe_num(sleep_row.get("deep_sleep_minutes"))
        rem = _safe_num(sleep_row.get("rem_sleep_minutes"))
        if deep is not None or rem is not None:
            restorative = (deep or 0.0) + (rem or 0.0)
            restorative_frac = restorative / asleep_min if asleep_min > 0 else 0.0
            stages_sub = min(
                100.0,
                (restorative_frac / _RECOVERY_RESTORATIVE_TARGET_FRAC) * 100.0,
            )
            components.append((_RECOVERY_W_STAGES, stages_sub))

        # Renormalise across whatever sub-scores we actually have.
        total_weight = sum(w for w, _ in components)
        if total_weight <= 0:
            return None
        score = sum(w * s for w, s in components) / total_weight
        return int(round(max(0.0, min(100.0, score))))

    # -------------------------------------------------------------------------
    # Snapshot
    # -------------------------------------------------------------------------

    async def get_health_activity_snapshot(
        self,
        user_id: str,
        days: int = 7,
    ) -> Dict[str, Any]:
        """Build the full health & activity snapshot for ``user_id``.

        Args:
            user_id: User's UUID.
            days: Trailing window for steps/calories/HR averages (default 7).

        Returns:
            On success, a dict with ``has_data: True`` and:
              last_night_sleep  — {date, total_minutes, deep/light/rem/awake,
                                   efficiency, latency_minutes, in_bed_minutes,
                                   bedtime, wake_time, is_stale}
              recovery          — {score, tier, volume_multiplier, adjustment}
                                   (score/tier None when sleep can't be scored)
              steps             — {today, avg_7d, goal, goal_pct}
              active_calories   — {today, avg_7d}
              heart_rate        — {resting, avg, max, resting_baseline,
                                   resting_vs_baseline}
              water_ml          — last recorded water intake
              recent_workouts   — up to 5 recent completed workouts
              weight            — {latest_kg, trend_kg, direction}
              goals             — raw health_goals row (or None)
              staleness         — {latest_activity_date, days_old, is_stale}

            When the user has not consented OR has no wearable data at all:
              ``{"has_data": False, "reason": <str>}`` — a NORMAL state, not an
              error. ``reason`` is one of: "no_consent", "no_activity_data".
        """
        # --- consent gate (Art. 9) -------------------------------------------
        try:
            if not has_health_data_consent(user_id):
                return {"has_data": False, "reason": "no_consent"}
        except Exception as e:
            # consent_guard already fails closed; treat any error as no-consent.
            logger.error(
                f"health_activity: consent check failed for {user_id}: {e}",
                exc_info=True,
            )
            return {"has_data": False, "reason": "no_consent"}

        try:
            db = get_supabase_db()
        except Exception as e:
            logger.error(
                f"health_activity: DB unavailable for {user_id}: {e}",
                exc_info=True,
            )
            return {"has_data": False, "reason": "no_activity_data"}

        # --- pull the activity window ----------------------------------------
        # Pull a slightly wider window than `days` so the resting-HR baseline
        # and weight trend have enough history; the averages still use `days`.
        window_days = max(days, 30)
        to_date = _utc_now().date()
        from_date = to_date - timedelta(days=window_days)

        try:
            activities = db.list_daily_activity(
                user_id=user_id,
                from_date=from_date.isoformat(),
                to_date=to_date.isoformat(),
                limit=window_days + 1,
            )
        except Exception as e:
            logger.error(
                f"health_activity: list_daily_activity failed for {user_id}: {e}",
                exc_info=True,
            )
            return {"has_data": False, "reason": "no_activity_data"}

        if not activities:
            # No wearable data at all — a normal state for non-wearable users.
            return {"has_data": False, "reason": "no_activity_data"}

        # `list_daily_activity` returns newest-first (ORDER BY activity_date DESC).
        activities_desc = list(activities)
        newest = activities_desc[0]

        # --- staleness -------------------------------------------------------
        latest_date_str = newest.get("activity_date")
        days_old: Optional[int] = None
        if latest_date_str:
            try:
                latest_date = datetime.fromisoformat(
                    str(latest_date_str)[:10]
                ).date()
                days_old = (to_date - latest_date).days
            except (ValueError, TypeError):
                days_old = None
        staleness = {
            "latest_activity_date": latest_date_str,
            "days_old": days_old,
            "is_stale": days_old is not None and days_old >= 1,
        }

        # --- last night's sleep ----------------------------------------------
        # The most recent row that carries a plausible sleep total. Rows with
        # no/implausible sleep are skipped (edge cases A8/A9) — the user may
        # have synced steps today but not yet synced last night's sleep.
        sleep_row: Optional[Dict[str, Any]] = None
        for row in activities_desc:
            total = _safe_num(row.get("sleep_minutes"))
            if total is None or total <= 0:
                continue
            if total < _MIN_PLAUSIBLE_SLEEP_MIN or total > _MAX_PLAUSIBLE_SLEEP_MIN:
                continue
            sleep_row = row
            break

        last_night_sleep: Optional[Dict[str, Any]] = None
        sleep_is_stale = True
        if sleep_row is not None:
            sleep_date_str = sleep_row.get("activity_date")
            sleep_days_old: Optional[int] = None
            if sleep_date_str:
                try:
                    sleep_date = datetime.fromisoformat(
                        str(sleep_date_str)[:10]
                    ).date()
                    sleep_days_old = (to_date - sleep_date).days
                except (ValueError, TypeError):
                    sleep_days_old = None
            # Stale if the sleep night is more than ~36h behind "now".
            sleep_is_stale = (
                sleep_days_old is not None and sleep_days_old * 24 > _SLEEP_STALENESS_HOURS
            )
            last_night_sleep = {
                "date": sleep_date_str,
                "total_minutes": int(_safe_num(sleep_row.get("sleep_minutes")) or 0),
                "deep_minutes": _opt_int(sleep_row.get("deep_sleep_minutes")),
                "light_minutes": _opt_int(sleep_row.get("light_sleep_minutes")),
                "rem_minutes": _opt_int(sleep_row.get("rem_sleep_minutes")),
                "awake_minutes": _opt_int(sleep_row.get("awake_sleep_minutes")),
                "efficiency": _safe_num(sleep_row.get("sleep_efficiency")),
                "latency_minutes": _opt_int(sleep_row.get("sleep_latency_minutes")),
                "bedtime": sleep_row.get("sleep_start"),
                "wake_time": sleep_row.get("sleep_end"),
                "is_stale": sleep_is_stale,
            }

        # --- recovery score + tier (deterministic) ---------------------------
        # Stale sleep does NOT drive recovery adaptation (edge case D21).
        recovery_score = (
            self._compute_recovery_score(sleep_row)
            if (sleep_row is not None and not sleep_is_stale)
            else None
        )
        tier = map_recovery_to_tier(recovery_score)
        recovery = {
            "score": recovery_score,
            "tier": tier["tier"] if tier else None,
            "volume_multiplier": tier["volume_multiplier"] if tier else None,
            "adjustment": tier["adjustment"] if tier else None,
        }

        # --- steps / active calories (today + trailing average) --------------
        window = activities_desc[:days]  # newest `days` rows for the averages

        step_values = [
            int(s) for s in (_safe_num(a.get("steps")) for a in window) if s is not None
        ]
        steps_today = _opt_int(newest.get("steps"))
        steps_avg_7d = (
            int(round(sum(step_values) / len(step_values))) if step_values else None
        )

        cal_values = [
            c for c in (_safe_num(a.get("active_calories")) for a in window) if c is not None
        ]
        active_calories = {
            "today": _safe_num(newest.get("active_calories")),
            "avg_7d": (
                round(sum(cal_values) / len(cal_values), 1) if cal_values else None
            ),
        }

        # --- goal progress ---------------------------------------------------
        try:
            goals = db.get_health_goals(user_id)
        except Exception as e:
            logger.error(
                f"health_activity: get_health_goals failed for {user_id}: {e}",
                exc_info=True,
            )
            goals = None

        step_goal = None
        step_goal_pct = None
        if goals:
            step_goal = _opt_int(goals.get("step_goal"))
        if step_goal and step_goal > 0 and steps_today is not None:
            step_goal_pct = round((steps_today / step_goal) * 100)

        steps = {
            "today": steps_today,
            "avg_7d": steps_avg_7d,
            "goal": step_goal,
            "goal_pct": step_goal_pct,
        }

        # --- heart rate + resting-HR baseline --------------------------------
        # The resting-HR baseline uses the wider window (>= 14 days where it
        # exists) so a one-off elevated day is visible against a real average.
        resting_history = [
            r
            for r in (_safe_num(a.get("resting_heart_rate")) for a in activities_desc)
            if r is not None
        ]
        resting_today = _safe_num(newest.get("resting_heart_rate"))
        resting_baseline = (
            round(sum(resting_history) / len(resting_history), 1)
            if len(resting_history) >= 14
            else None
        )
        resting_vs_baseline = None
        if resting_today is not None and resting_baseline is not None:
            resting_vs_baseline = round(resting_today - resting_baseline, 1)
        heart_rate = {
            "resting": resting_today,
            "avg": _safe_num(newest.get("avg_heart_rate")),
            "max": _safe_num(newest.get("max_heart_rate")),
            "resting_baseline": resting_baseline,
            "resting_vs_baseline": resting_vs_baseline,
        }

        # --- water -----------------------------------------------------------
        water_ml = _opt_int(newest.get("water_ml"))

        # --- recent workouts -------------------------------------------------
        recent_workouts = self._recent_workouts(db, user_id)

        # --- weight trend ----------------------------------------------------
        weight = self._weight_trend(db, user_id)

        return {
            "has_data": True,
            "window_days": days,
            "last_night_sleep": last_night_sleep,
            "recovery": recovery,
            "steps": steps,
            "active_calories": active_calories,
            "heart_rate": heart_rate,
            "water_ml": water_ml,
            "recent_workouts": recent_workouts,
            "weight": weight,
            "goals": goals,
            "staleness": staleness,
        }

    def _recent_workouts(self, db: Any, user_id: str) -> List[Dict[str, Any]]:
        """Up to 5 recent completed workouts (id, date, type, name).

        Filters server-side on ``is_completed=True``; `list_workouts` returns
        newest-first, so the first few rows are the freshest completed sessions.
        """
        try:
            rows = (
                db.list_workouts(
                    user_id=user_id,
                    is_completed=True,
                    limit=_RECENT_WORKOUT_LIMIT,
                )
                or []
            )
        except Exception as e:
            logger.error(
                f"health_activity: list_workouts failed for {user_id}: {e}",
                exc_info=True,
            )
            return []

        out: List[Dict[str, Any]] = []
        for r in rows[:_RECENT_WORKOUT_LIMIT]:
            out.append(
                {
                    "id": r.get("id"),
                    "date": r.get("scheduled_date"),
                    "type": r.get("type"),
                    "name": r.get("name"),
                }
            )
        return out

    def _weight_trend(self, db: Any, user_id: str) -> Optional[Dict[str, Any]]:
        """Latest body weight + a 30-day trend from `user_metrics`.

        Returns ``None`` when the user has logged no body-weight metrics —
        weight is independent of wearable sync, so absence here is normal.
        """
        try:
            metrics = db.list_user_metrics(user_id=user_id, limit=30) or []
        except Exception as e:
            logger.error(
                f"health_activity: list_user_metrics failed for {user_id}: {e}",
                exc_info=True,
            )
            return None

        weights = [
            (m.get("recorded_at"), _safe_num(m.get("weight_kg")))
            for m in metrics
            if _safe_num(m.get("weight_kg")) is not None
        ]
        if not weights:
            return None

        # `list_user_metrics` orders recorded_at DESC: index 0 newest.
        latest_kg = weights[0][1]
        oldest_kg = weights[-1][1]
        trend_kg = round(latest_kg - oldest_kg, 1)
        if len(weights) < 2 or abs(trend_kg) < 0.3:
            direction = "stable"
        elif trend_kg < 0:
            direction = "down"
        else:
            direction = "up"

        return {
            "latest_kg": round(latest_kg, 1),
            "trend_kg": trend_kg,
            "direction": direction,
            "data_points": len(weights),
        }

    # -------------------------------------------------------------------------
    # Compact AI-prompt string (<150 tokens)
    # -------------------------------------------------------------------------

    async def get_health_context_for_ai(
        self,
        user_id: str,
        days: int = 7,
    ) -> str:
        """Format the snapshot into a compact health block for the coach prompt.

        Returns ``""`` (empty string) when the user has no consent or no
        wearable data — the coach must then answer generally and never
        fabricate numbers (edge cases D20 / D23). The string is kept well
        under ~150 tokens so the coach-prompt token budget stays bounded.

        Args:
            user_id: User's UUID.
            days: Trailing window for averages (default 7).

        Returns:
            A short multi-line context string, or "" when there is no data.
        """
        snapshot = await self.get_health_activity_snapshot(user_id, days)
        if not snapshot.get("has_data"):
            return ""

        lines: List[str] = ["User wearable health data (cite only these numbers):"]

        # --- sleep -----------------------------------------------------------
        sleep = snapshot.get("last_night_sleep")
        if sleep and not sleep.get("is_stale"):
            total = sleep["total_minutes"]
            hrs, mins = divmod(total, 60)
            sleep_part = f"- Last night: {hrs}h{mins:02d}m sleep"
            stages = []
            if sleep.get("deep_minutes") is not None:
                stages.append(f"deep {sleep['deep_minutes']}m")
            if sleep.get("rem_minutes") is not None:
                stages.append(f"REM {sleep['rem_minutes']}m")
            if stages:
                sleep_part += f" ({', '.join(stages)})"
            eff = sleep.get("efficiency")
            if eff is not None:
                sleep_part += f", efficiency {round(eff * 100)}%"
            lines.append(sleep_part)
        elif sleep and sleep.get("is_stale"):
            lines.append("- No sleep tracked last night (data is stale).")
        else:
            lines.append("- No sleep tracked last night.")

        # --- recovery --------------------------------------------------------
        recovery = snapshot.get("recovery") or {}
        if recovery.get("score") is not None:
            lines.append(
                f"- Recovery {recovery['score']}/100 ({recovery['tier']}); "
                f"training guidance: {recovery['adjustment']}."
            )

        # --- steps -----------------------------------------------------------
        steps = snapshot.get("steps") or {}
        if steps.get("today") is not None:
            step_part = f"- Steps today: {steps['today']:,}"
            if steps.get("avg_7d") is not None:
                step_part += f" ({days}-day avg {steps['avg_7d']:,})"
            if steps.get("goal"):
                step_part += f", goal {steps['goal']:,} ({steps.get('goal_pct', 0)}%)"
            lines.append(step_part)

        # --- active calories -------------------------------------------------
        cals = snapshot.get("active_calories") or {}
        if cals.get("today") is not None:
            lines.append(f"- Active calories today: {round(cals['today'])} kcal.")

        # --- heart rate ------------------------------------------------------
        hr = snapshot.get("heart_rate") or {}
        if hr.get("resting") is not None:
            hr_part = f"- Resting HR: {round(hr['resting'])} bpm"
            if hr.get("resting_vs_baseline") is not None:
                delta = hr["resting_vs_baseline"]
                if delta > 0:
                    hr_part += f" (+{delta} vs baseline)"
                elif delta < 0:
                    hr_part += f" ({delta} vs baseline)"
                else:
                    hr_part += " (at baseline)"
            lines.append(hr_part)

        # --- water -----------------------------------------------------------
        water = snapshot.get("water_ml")
        if water:
            lines.append(f"- Water today: {water} ml.")

        # --- recent workouts -------------------------------------------------
        workouts = snapshot.get("recent_workouts") or []
        if workouts:
            lines.append(
                f"- Completed {len(workouts)} workout(s) recently."
            )

        # --- weight ----------------------------------------------------------
        weight = snapshot.get("weight")
        if weight and weight.get("direction") != "stable":
            lines.append(
                f"- Weight trending {weight['direction']} "
                f"({weight['latest_kg']} kg, {weight['trend_kg']:+} kg)."
            )
        elif weight:
            lines.append(f"- Weight stable at {weight['latest_kg']} kg.")

        # --- staleness note --------------------------------------------------
        staleness = snapshot.get("staleness") or {}
        if staleness.get("is_stale") and staleness.get("days_old"):
            lines.append(
                f"- Note: latest sync is {staleness['days_old']} day(s) old."
            )

        # --- top cross-metric smart insight (Phase D1) -----------------------
        # Append at most ONE correlation insight so the coach can mention an
        # observed pattern in the user's own data. Best-effort and bounded:
        # any failure is swallowed (the health block must still ship) and the
        # engine itself returns nothing below 14 paired days, so this line is
        # simply absent for users without enough history.
        try:
            insight_line = await self._top_smart_insight(user_id)
            if insight_line:
                lines.append(f"- Pattern: {insight_line}")
        except Exception as e:  # never let an insight failure drop the block
            logger.warning(
                f"health_activity: smart-insight append skipped for {user_id}: {e}"
            )

        return "\n".join(lines)

    async def _top_smart_insight(self, user_id: str) -> str:
        """Return the single best cross-metric correlation insight sentence for
        the coach prompt, or "" when there is not enough data (Phase D1).

        Reuses ``health_insights_engine`` over the same ``daily_activity``
        history. Body weight (stored in ``user_metrics``) is merged onto the
        matching activity dates so the weight metric has data to correlate.
        Returns "" cleanly on <14 paired days or any error — never a fabricated
        pattern.
        """
        from services.health_insights_engine import (
            compute_smart_insights,
            top_insight_sentence,
        )

        try:
            db = get_supabase_db()
        except Exception:
            return ""

        to_date = _utc_now().date()
        from_date = to_date - timedelta(days=90)
        try:
            activities = db.list_daily_activity(
                user_id=user_id,
                from_date=from_date.isoformat(),
                to_date=to_date.isoformat(),
                limit=91,
            )
        except Exception:
            return ""
        if not activities:
            return ""

        # Merge body weight onto matching activity dates (latest per day).
        try:
            metrics = db.list_user_metrics(user_id=user_id, limit=120) or []
            by_date: Dict[str, float] = {}
            for m in metrics:
                recorded = m.get("recorded_at")
                wkg = _safe_num(m.get("weight_kg"))
                if not recorded or wkg is None:
                    continue
                day_key = str(recorded)[:10]
                by_date.setdefault(day_key, wkg)
            for row in activities:
                day_key = str(row.get("activity_date"))[:10]
                if day_key in by_date:
                    row["weight_kg"] = by_date[day_key]
        except Exception:
            # Weight merge is optional — proceed without it.
            pass

        insights = compute_smart_insights(activities, window_days=60)
        return top_insight_sentence(insights)


def _opt_int(value: Any) -> Optional[int]:
    """Coerce a DB value to int, returning None for null / unparseable."""
    num = _safe_num(value)
    return int(num) if num is not None else None
