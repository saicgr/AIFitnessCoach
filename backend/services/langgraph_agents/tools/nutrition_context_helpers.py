"""
Context pre-fetch helpers for the nutrition agent.

These run BEFORE the LLM call (via `_build_agent_state`) so the agent has
the user's full day context as part of its system prompt — no tool round
trips needed for the common preset queries like "What can I eat now?".

Each function is independent and tolerates failure — if any helper raises,
`_build_agent_state` catches it via `asyncio.gather(return_exceptions=True)`
and marks `context_partial=True` without blocking the rest of the state.

The three public helpers return plain dicts / lists (no LangChain `@tool`
decoration). Thin `@tool`-wrapped versions live in `nutrition_tools.py` for
freeform agent queries that fall outside the preset pill flow.
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional

from core.db import get_supabase_db
from core.supabase_client import get_supabase
from core.timezone_utils import (
    get_user_today,
    local_date_to_utc_range,
    resolve_timezone,
    utc_to_local_date,
)

logger = logging.getLogger(__name__)


# ── Daily nutrition context ────────────────────────────────────────────────

async def fetch_daily_nutrition_context(
    user_id: str,
    timezone_str: str = "UTC",
) -> Dict[str, Any]:
    """Aggregate today's logged meals + targets + macro remainders.

    Returns a dict shaped to plug directly into the nutrition agent's system
    prompt and into the `/meal-context` endpoint response. All arithmetic is
    done in Python (not SQL) so we can be precise about which fields are
    truly known vs unknown (target missing ⇒ calorie_remainder=None).
    """
    db = get_supabase_db()
    today = get_user_today(timezone_str)

    # Daily summary (totals + meal list) — helper handles tz conversion.
    summary = db.get_daily_nutrition_summary(
        user_id, today, timezone_str=timezone_str
    )

    # User's targets (preferences-first, users-table fallback).
    targets = db.get_user_nutrition_targets(user_id)

    # Consumed totals from the summary (zero-safe).
    cal_consumed = int(summary.get("total_calories") or 0)
    p_consumed = float(summary.get("total_protein_g") or 0)
    c_consumed = float(summary.get("total_carbs_g") or 0)
    f_consumed = float(summary.get("total_fat_g") or 0)
    fib_consumed = float(summary.get("total_fiber_g") or 0)

    # Targets may be None when user hasn't set them.
    cal_target = targets.get("daily_calorie_target")
    p_target = targets.get("daily_protein_target_g")
    c_target = targets.get("daily_carbs_target_g")
    f_target = targets.get("daily_fat_target_g")

    def _remainder(consumed, target):
        if target is None:
            return None
        return max(-9999, target - consumed)  # allow negative when over

    cal_remainder = _remainder(cal_consumed, cal_target)
    over_budget = cal_remainder is not None and cal_remainder < 0

    # ── F4: exercise-burn-into-budget ─────────────────────────────────────
    # Fetch today's ACTIVE energy (exercise burn only — never total/basal,
    # because BMR is already baked into the calorie target/TDEE). Recomputed
    # live at every call (no stale cache for the burn term). When the user's
    # `adjust_calories_for_training` preference is ON and there is real burn,
    # the eatable budget grows additively on top of the existing target:
    #     net_remainder = target - consumed + active_calories
    # i.e. exercise "earns back" calories. When the pref is OFF or burn==0,
    # `burn_adjusted=False` and `net_calorie_remainder` simply mirrors
    # `calorie_remainder` (no behavioural change). The raw burn is always
    # surfaced (`calories_burned_today`) so the UI/coach can show it even when
    # the pref is off, but it only MOVES the budget when the pref is on.
    calories_burned_today, burn_pref_on = await _fetch_active_calories_and_pref(
        user_id, today, timezone_str
    )
    burn_adjusted = bool(burn_pref_on and calories_burned_today > 0)
    if burn_adjusted and cal_remainder is not None:
        net_calorie_remainder = cal_remainder + calories_burned_today
    else:
        net_calorie_remainder = cal_remainder  # mirrors (None if no target)

    # Meal-type coverage today (avoid proposing a 4th breakfast).
    meals = summary.get("meals") or []
    meal_types_logged = sorted({
        (m.get("meal_type") or "").lower()
        for m in meals
        if m.get("meal_type")
    })

    # Ultra-processed rows today.
    ultra_processed_count = sum(
        1 for m in meals if m.get("is_ultra_processed") is True
    )

    # ── Sleep-aware nutrition (Phase E1) ──────────────────────────────────
    # On a low-recovery day the macro EMPHASIS shifts toward protein and the
    # day's calories are nudged earlier. The adjustment is deterministic and
    # calorie-neutral (it never raises the total => the cutting deficit is
    # preserved); when there is no recovery data the targets are returned
    # unchanged (edge case G35). Best-effort: any failure leaves the base
    # targets untouched so the nutrition context still ships.
    recovery_adjustment = await _recovery_target_adjustment(
        user_id,
        {
            "daily_calorie_target": cal_target,
            "daily_protein_target_g": p_target,
            "daily_carbs_target_g": c_target,
            "daily_fat_target_g": f_target,
        },
    )

    return {
        "date": today,
        "timezone": timezone_str,
        "total_calories": cal_consumed,
        "total_protein_g": round(p_consumed, 1),
        "total_carbs_g": round(c_consumed, 1),
        "total_fat_g": round(f_consumed, 1),
        "total_fiber_g": round(fib_consumed, 1),
        "target_calories": cal_target,
        "target_protein_g": p_target,
        "target_carbs_g": c_target,
        "target_fat_g": f_target,
        "calorie_remainder": cal_remainder,
        # F4 — exercise burn surfaced additively (see contract).
        "calories_burned_today": calories_burned_today,
        "net_calorie_remainder": net_calorie_remainder,
        "burn_adjusted": burn_adjusted,
        "macros_remaining": {
            "protein_g": _remainder(p_consumed, p_target),
            "carbs_g": _remainder(c_consumed, c_target),
            "fat_g": _remainder(f_consumed, f_target),
        },
        "meal_count": len(meals),
        "meal_types_logged": meal_types_logged,
        "ultra_processed_count_today": ultra_processed_count,
        "over_budget": over_budget,
        # Phase E1 — present only on a low-recovery day; absent (None) when
        # recovery data is missing or recovery is fine, so downstream callers
        # can treat its presence as "the day's targets were recovery-adjusted".
        "recovery_adjusted_targets": recovery_adjustment,
    }


async def _fetch_active_calories_and_pref(
    user_id: str,
    local_date: str,
    timezone_str: str,
) -> "tuple[int, bool]":
    """F4 — return ``(active_calories_today, adjust_calories_for_training)``.

    ACTIVE energy ONLY — never ``calories_burned``/``basal_calories`` (basal is
    already inside the calorie target/TDEE). ``daily_activity`` is keyed by
    ``activity_date`` (the user's LOCAL calendar date), so we look up the row
    for ``local_date`` directly. If multiple rows exist for the same date
    (overlapping HealthKit / Google Fit / Health-Connect sources), we DE-DUPE
    by taking the single largest ``active_calories`` rather than summing — two
    sources reporting the same workout must not double-count. The value is
    sanity-capped to ``[0, 4000]`` so a garbage/negative reading can never
    inflate the eatable budget. Best-effort: any failure returns ``(0, pref)``
    so the burn term simply has no effect.

    Recomputed live on every call (no caching of the burn term).
    """
    active = 0
    pref_on = False
    db = get_supabase_db()

    # Preference: adjust_calories_for_training (default OFF when unset).
    try:
        client = get_supabase().client
        pref_resp = (
            client.table("nutrition_preferences")
            .select("adjust_calories_for_training")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        prefs = (pref_resp.data if pref_resp and pref_resp.data else {}) or {}
        pref_on = bool(prefs.get("adjust_calories_for_training"))
    except Exception as e:
        logger.warning(f"[F4] adjust_calories_for_training lookup failed for {user_id}: {e}")

    # Active energy for the user's local day.
    try:
        client = get_supabase().client
        resp = (
            client.table("daily_activity")
            .select("active_calories, source")
            .eq("user_id", user_id)
            .eq("activity_date", local_date)
            .execute()
        )
        rows = resp.data or []
        # De-dupe overlapping sources: largest single active_calories wins
        # (NOT a sum) so the same workout reported by two providers counts once.
        best = 0.0
        for row in rows:
            try:
                v = float(row.get("active_calories") or 0)
            except (TypeError, ValueError):
                v = 0.0
            if v > best:
                best = v
        # Sanity clamp — reject absurd/negative readings.
        active = int(max(0.0, min(best, 4000.0)))
    except Exception as e:
        logger.warning(f"[F4] active_calories lookup failed for {user_id}: {e}")
        active = 0

    return active, pref_on


async def _recovery_target_adjustment(
    user_id: str,
    base_targets: Dict[str, Any],
) -> Optional[Dict[str, Any]]:
    """Compute the sleep-aware (recovery-driven) macro-target adjustment.

    Reads Phase B1's recovery snapshot and the user's dietary restrictions,
    then delegates to the deterministic ``sleep_aware_nutrition`` engine.

    Returns the adjustment dict ONLY when the day's targets were actually
    shifted (a low-recovery day) or a craving heads-up applies; returns
    ``None`` when there is no recovery data or recovery is fine — so the
    field's presence cleanly signals "today is recovery-adjusted". Any error
    is swallowed (returns ``None``) — the nutrition context must still ship.
    """
    try:
        from services.user_context import user_context_service
        from services.sleep_aware_nutrition import adjust_targets_for_recovery

        snapshot = await user_context_service.get_health_activity_snapshot(
            user_id, days=7
        )
        if not snapshot or not snapshot.get("has_data"):
            return None  # edge case G35 — no recovery data => no adjustment
        recovery = snapshot.get("recovery")

        # Dietary restrictions gate the protein bump (renal / low-protein).
        dietary_restrictions: Optional[List[str]] = None
        try:
            db = get_supabase_db()
            prefs = db.get_nutrition_preferences(user_id) or {}
            raw = prefs.get("dietary_restrictions")
            if isinstance(raw, list):
                dietary_restrictions = [str(x) for x in raw if x]
            elif isinstance(raw, str) and raw.strip():
                dietary_restrictions = [raw.strip()]
        except Exception as e:
            logger.warning(
                f"recovery target adj: dietary restrictions lookup "
                f"failed for {user_id}: {e}"
            )

        # Gap 2 — fetch the training-load state so a high-load + low-recovery
        # day escalates the protein bump one notch (still calorie-neutral,
        # still dietary-gated). Best-effort: any failure leaves load_state None
        # and the adjustment behaves exactly as before.
        load_state: Optional[str] = None
        try:
            import asyncio as _asyncio
            from services.training_load_service import current_state
            db2 = get_supabase_db()
            _st = await _asyncio.to_thread(current_state, db2, user_id)
            if _st and _st.state and _st.state != "calibration":
                load_state = _st.state
        except Exception as e:
            logger.debug(f"recovery target adj: load state skipped for {user_id}: {e}")

        result = adjust_targets_for_recovery(
            base_targets, recovery, dietary_restrictions, load_state=load_state
        )
        # Only surface it when it actually changes something the caller acts
        # on — an adjusted target set or a craving heads-up.
        if result.get("adjusted") or result.get("craving_heads_up"):
            return result
        return None
    except Exception as e:
        logger.warning(
            f"recovery target adjustment skipped for {user_id}: {e}"
        )
        return None


# ── Patterns context (food↔feeling correlations + goal gaps) ────────────────

async def fetch_patterns_context(
    user_id: str,
    days: int = 90,
) -> Optional[str]:
    """Summarize the user's food↔feeling/tag/digestion patterns + goal gaps.

    Calls the same correlation engine that backs the Nutrition > Patterns tab —
    ``get_food_patterns`` (mood/energy + per-symptom counts), the symptom/tag
    correlation RPC, the digestion-pattern RPC — plus a 4wk-vs-9wk goal-vs-actual
    comparison, and renders a COMPACT prompt block so the nutrition coach can
    answer "why do I feel bloated after healthy meals?" with the user's real
    foods/tags. This is the only place the agent sees patterns; today's day-
    context (calories/macros) stays separate.

    Fail-open: returns ``None`` when there's no signal or on any error — the
    coach path is never blocked by patterns being absent. The returned string is
    short (top draining/energizing foods, dominant symptoms, tag→symptom links,
    gut links, notable goal gaps) with built-in reasoning guidance.
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Run the three correlation RPCs concurrently (all read food_logs /
        # digestion_logs over the same window). Goals come from a cheap select.
        def _rpc(name, params):
            return client.rpc(name, params).execute()

        import asyncio as _asyncio
        food_res, corr_res, dig_res = await _asyncio.gather(
            _asyncio.to_thread(
                _rpc, "get_food_patterns",
                {"p_user_id": user_id, "p_days": days, "p_min_logs": 3,
                 "p_include_inferred": True, "p_food_names": None},
            ),
            _asyncio.to_thread(
                _rpc, "get_symptom_tag_correlations",
                {"p_user_id": user_id, "p_days": days, "p_min_logs": 2},
            ),
            _asyncio.to_thread(
                _rpc, "get_digestion_patterns",
                {"p_user_id": user_id, "p_days": days, "p_lag_min_hours": 6,
                 "p_lag_max_hours": 72, "p_min_logs": 2},
            ),
            return_exceptions=True,
        )

        food_rows = _safe_rows(food_res)
        corr_rows = _safe_rows(corr_res)
        dig_rows = _safe_rows(dig_res)

        lines: List[str] = []

        # Top draining / energizing foods (by score).
        draining = sorted(
            (r for r in food_rows if float(r.get("negative_score") or 0) >= 0.5),
            key=lambda r: float(r.get("negative_score") or 0), reverse=True,
        )[:3]
        energizing = sorted(
            (r for r in food_rows
             if float(r.get("positive_score") or 0) >= 0.5
             and float(r.get("positive_score") or 0) >= float(r.get("negative_score") or 0)),
            key=lambda r: float(r.get("positive_score") or 0), reverse=True,
        )[:3]
        if draining:
            parts = []
            for r in draining:
                sym = r.get("dominant_symptom")
                parts.append(f"{r.get('food_name')}" + (f" → often {sym}" if sym else ""))
            lines.append("• Foods that seem to DRAIN you: " + "; ".join(parts))
        if energizing:
            lines.append(
                "• Foods that seem to ENERGIZE you: "
                + ", ".join(r.get("food_name") for r in energizing)
            )

        # Tag → symptom correlations (the "dairy → bloated 75%" insight).
        tag_links = [c for c in corr_rows if c.get("bucket_kind") == "tag"]
        tag_links.sort(key=lambda c: (int(c.get("occurrences") or 0), float(c.get("pct") or 0)), reverse=True)
        for c in tag_links[:3]:
            lines.append(
                f"• When you eat {c.get('tag')}: '{c.get('symptom')}' "
                f"{c.get('occurrences')}/{c.get('total_with_signal')} times "
                f"({c.get('pct')}%)"
            )

        # Digestion: tags preceding irregular days.
        dig_tags = [d for d in dig_rows if d.get("result_kind") == "tag_correlation"]
        dig_tags.sort(key=lambda d: float(d.get("irregular_pct") or 0), reverse=True)
        for d in dig_tags[:2]:
            if int(d.get("irregular_count") or 0) > 0:
                lines.append(
                    f"• Gut: {d.get('tag')} preceded an irregular day "
                    f"{d.get('irregular_count')}/{d.get('total_count')} times "
                    f"({d.get('irregular_pct')}%)"
                )

        # Goal-vs-actual averages (4wk current vs 9wk baseline-ish). Light:
        # compare a 28-day intake average to the user's goals.
        # The per-day averaging below buckets a UTC `logged_at` into calendar
        # days, so it needs the user's tz. There's no Request here (this runs
        # from the agent's context pre-fetch), so users.timezone is the source.
        tz = resolve_timezone(None, db, user_id)
        goal_gap = await _asyncio.to_thread(
            _fetch_goal_gap_summary, client, user_id, tz
        )
        if goal_gap:
            lines.append(goal_gap)

        if not lines:
            return None

        header = (
            "FOOD↔FEELING PATTERNS (last "
            f"{days} days — use ONLY to explain how foods make THIS user feel; "
            "do not narrate as a data dump):"
        )
        guidance = (
            "Guidance: when the user asks why they feel a certain way after "
            "eating, ground the answer in these real foods/tags. Suggest "
            "realistic swaps, not rigid plans. Never calorie-shame; frame goal "
            "gaps as gentle nudges. Correlation ≠ causation — say 'seems to' / "
            "'often', not 'X causes Y'."
        )
        return header + "\n" + "\n".join(lines) + "\n" + guidance
    except Exception as e:
        logger.warning(f"fetch_patterns_context skipped for {user_id}: {e}")
        return None


def _safe_rows(res) -> List[Dict[str, Any]]:
    """Extract .data rows from a possibly-Exception gather result."""
    if isinstance(res, Exception) or res is None:
        return []
    return getattr(res, "data", None) or []


def _fetch_goal_gap_summary(client, user_id: str, timezone_str: str) -> Optional[str]:
    """Compare ~28-day avg intake (fiber/protein) to goals → one gentle line.

    Sync (runs off the event loop via to_thread). Returns None on no data.
    `timezone_str` buckets each log into the user's own calendar day — the
    per-day average is only meaningful against local days."""
    try:
        from datetime import datetime as _dt, timedelta as _td, timezone as _tz
        start = (_dt.now(_tz.utc) - _td(days=28)).isoformat()
        resp = (
            client.table("food_logs")
            .select("logged_at,protein_g,fiber_g")
            .eq("user_id", user_id)
            .is_("deleted_at", "null")
            .gte("logged_at", start)
            .execute()
        )
        rows = resp.data or []
        if not rows:
            return None
        # Bucket by the user's LOCAL day for a per-day average — slicing the raw
        # UTC string rolls a 9pm-local log onto the next day, inflating the day
        # count and diluting the average (the sibling of the window bug).
        per_day: Dict[str, Dict[str, float]] = {}
        for r in rows:
            d = utc_to_local_date(r.get("logged_at"), timezone_str)
            if not d:
                continue
            b = per_day.setdefault(d, {"protein": 0.0, "fiber": 0.0})
            b["protein"] += float(r.get("protein_g") or 0)
            b["fiber"] += float(r.get("fiber_g") or 0)
        n = len(per_day) or 1
        avg_protein = round(sum(v["protein"] for v in per_day.values()) / n)
        avg_fiber = round(sum(v["fiber"] for v in per_day.values()) / n)

        goals_resp = (
            client.table("nutrition_preferences")
            .select("target_protein_g,target_fiber_g")
            .eq("user_id", user_id)
            .maybe_single()
            .execute()
        )
        goals = (goals_resp.data if goals_resp else None) or {}
        gaps = []
        fiber_goal = goals.get("target_fiber_g") or 25
        if avg_fiber < fiber_goal - 3:
            gaps.append(f"fiber {avg_fiber}g/day vs {fiber_goal}g goal")
        protein_goal = goals.get("target_protein_g")
        if protein_goal and avg_protein < protein_goal - 10:
            gaps.append(f"protein {avg_protein}g/day vs {protein_goal}g goal")
        if not gaps:
            return None
        return "• Goal gaps (28-day avg): " + "; ".join(gaps)
    except Exception as e:
        logger.debug(f"goal gap summary skipped for {user_id}: {e}")
        return None


# ── Recent favorites ───────────────────────────────────────────────────────

async def fetch_recent_favorites(
    user_id: str,
    limit: int = 5,
    exclude_days: int = 0,
) -> List[Dict[str, Any]]:
    """Return the user's most-logged saved foods.

    If `exclude_days > 0`, skip saved foods whose `last_logged_at` falls
    within the last N days — useful for the "show me a favorite I haven't
    had recently" pill.

    Returns an empty list when the user has no saved_foods rows.
    """
    client = get_supabase().client
    query = (
        client.table("saved_foods")
        .select(
            "id, name, total_calories, total_protein_g, total_carbs_g, "
            "total_fat_g, times_logged, last_logged_at"
        )
        .eq("user_id", user_id)
        .order("times_logged", desc=True)
        .limit(limit * 3 if exclude_days > 0 else limit)
    )
    resp = query.execute()
    rows = resp.data or []

    if exclude_days > 0:
        cutoff = datetime.utcnow() - timedelta(days=exclude_days)
        filtered: List[Dict[str, Any]] = []
        for row in rows:
            last = row.get("last_logged_at")
            if not last:
                filtered.append(row)
                continue
            try:
                last_dt = datetime.fromisoformat(last.replace("Z", "+00:00"))
                if last_dt.replace(tzinfo=None) < cutoff:
                    filtered.append(row)
            except Exception:
                # Bad timestamp — keep the row rather than silently dropping
                filtered.append(row)
            if len(filtered) >= limit:
                break
        rows = filtered[:limit]
    else:
        rows = rows[:limit]

    # Shape down to what the agent / frontend actually needs.
    out: List[Dict[str, Any]] = []
    for row in rows:
        last = row.get("last_logged_at")
        days_ago: Optional[int] = None
        if last:
            try:
                last_dt = datetime.fromisoformat(last.replace("Z", "+00:00"))
                delta = datetime.utcnow() - last_dt.replace(tzinfo=None)
                days_ago = max(0, delta.days)
            except Exception:
                days_ago = None
        out.append({
            "id": row.get("id"),
            "name": row.get("name"),
            "total_calories": row.get("total_calories"),
            "total_protein_g": float(row.get("total_protein_g") or 0),
            "total_carbs_g": float(row.get("total_carbs_g") or 0),
            "total_fat_g": float(row.get("total_fat_g") or 0),
            "times_logged": row.get("times_logged") or 0,
            "last_logged_days_ago": days_ago,
        })
    return out


# ── Today's workout ────────────────────────────────────────────────────────

async def fetch_todays_workout(
    user_id: str,
    timezone_str: str = "UTC",
) -> Optional[Dict[str, Any]]:
    """Today's scheduled workout in the user's timezone.

    Returns a compact dict suitable for injection into the system prompt, or
    `None` if no workout is scheduled today (rest day).

    Uses the existing `db.list_workouts` helper (applies `is_current=True`
    and status!='generating' filters automatically).
    """
    db = get_supabase_db()
    today = get_user_today(timezone_str)
    utc_start, utc_end = local_date_to_utc_range(today, timezone_str)

    workouts = db.list_workouts(
        user_id,
        from_date=utc_start,
        to_date=utc_end,
        order_asc=True,
        limit=1,
    )
    if not workouts:
        return None

    w = workouts[0]
    # Extract scheduled time-of-day from the scheduled_date (which is a tz-aware ts).
    sched_time: Optional[str] = None
    sched_raw = w.get("scheduled_date")
    if sched_raw:
        try:
            # Normalize to ISO + strip microseconds
            if isinstance(sched_raw, str):
                dt = datetime.fromisoformat(sched_raw.replace("Z", "+00:00"))
            else:
                dt = sched_raw
            sched_time = dt.strftime("%H:%M")
        except Exception:
            sched_time = None

    # Derive primary muscle groups from exercises_json if present.
    primary_muscles: List[str] = []
    try:
        exs = w.get("exercises_json") or []
        seen = set()
        for ex in exs:
            muscle = (ex.get("primary_muscle") or ex.get("muscle_group") or "").strip().lower()
            if muscle and muscle not in seen:
                seen.add(muscle)
                primary_muscles.append(muscle)
        primary_muscles = primary_muscles[:4]  # cap for prompt brevity
    except Exception:
        primary_muscles = []

    return {
        "id": w.get("id"),
        "name": w.get("name"),
        "type": w.get("type"),
        "is_completed": bool(w.get("is_completed")),
        "duration_minutes": w.get("duration_minutes"),
        "scheduled_date": sched_raw if isinstance(sched_raw, str) else None,
        "scheduled_time_local": sched_time,
        "primary_muscles": primary_muscles,
        "exercise_count": len(w.get("exercises_json") or []),
    }
