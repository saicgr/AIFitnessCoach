"""
Deterministic menstrual-cycle & fertility prediction engine.

No LLM, no RAG — plain, inspectable arithmetic over a user's period history
plus optional BBT / cervical-mucus / LH-test signals.

Evidence base (see docs/planning plan for citations):
  * Next-period prediction: recency-weighted average of the last up to 12
    cycle lengths (Clue uses the same 12-cycle window).
  * Fertile window: ovulation-based window (5 days before ovulation through
    1 day after) cross-checked against the Ogino-Knaus calendar method
    (first fertile day = shortest cycle - 18, last = longest cycle - 11).
  * Ovulation: counted back a luteal-phase length (default 14 days) from the
    predicted next period; refined/confirmed by the Marshall "three-over-six"
    BBT rule and the cervical-mucus peak-day rule (sympto-thermal method).

The same algorithm is mirrored in the Flutter app at
mobile/flutter/lib/services/cycle/cycle_predictor.dart for instant on-device
rendering — keep the two in sync when changing the math.
"""
from __future__ import annotations

import statistics
from datetime import date, timedelta
from typing import Dict, List, Optional, Tuple

# --- Tuning constants -------------------------------------------------------
DEFAULT_CYCLE_LENGTH = 28
DEFAULT_PERIOD_LENGTH = 5
DEFAULT_LUTEAL_LENGTH = 14          # luteal phase runs ~12-14 days
MIN_PLAUSIBLE_CYCLE = 15            # shorter gap => missed log / data error
MAX_PLAUSIBLE_CYCLE = 60            # longer gap  => missed log / data error
MAX_HISTORY_CYCLES = 12             # Clue-style recency window
REGULAR_STDDEV_THRESHOLD = 4.0      # stddev <= this => "regular"
MIN_PREDICTION_WINDOW = 1
MAX_PREDICTION_WINDOW = 5           # +/- days around the predicted period date

# Marshall three-over-six BBT rule. Stored temps are Celsius; the rule is
# stated in Fahrenheit, so the thresholds are converted: 0.2 F = 0.111 C,
# 0.4 F = 0.222 C.
BBT_SHIFT_C = 0.11
BBT_STRONG_C = 0.22
BBT_MIN_POINTS = 9                  # 6 baseline + 3 elevated

FERTILE_DAYS_BEFORE = 5             # sperm survive ~5 days
FERTILE_DAYS_AFTER = 1              # egg survives ~1 day
PEAK_DAYS_BEFORE = 2                # peak fertility = 2 days pre-ovulation + ovulation day

_FERTILE_MUCUS = ("egg_white", "watery")
_POSITIVE_LH = ("positive", "peak")


# ---------------------------------------------------------------------------
# Pure helpers
# ---------------------------------------------------------------------------
def _recency_weighted_mean(values: List[float]) -> float:
    """Mean weighted so recent values count more (linear weights 1..n)."""
    n = len(values)
    weights = list(range(1, n + 1))
    return sum(v * w for v, w in zip(values, weights)) / sum(weights)


def _cycle_lengths(period_starts: List[date]) -> List[int]:
    """Gaps (days) between consecutive period starts, oldest-first."""
    return [
        (period_starts[i + 1] - period_starts[i]).days
        for i in range(len(period_starts) - 1)
    ]


def _clamp(value: int, low: int, high: int) -> int:
    return max(low, min(high, value))


def compute_stats(
    period_starts: List[date],
    period_ends: Dict[date, date],
    has_pcos: bool,
) -> dict:
    """Cycle statistics over the recency window. Outlier cycles (implausible
    gaps from a missed log) are dropped from the averages but the raw period
    count is still reported."""
    periods_logged = len(period_starts)

    raw_lengths = _cycle_lengths(period_starts)
    plausible = [ln for ln in raw_lengths if MIN_PLAUSIBLE_CYCLE <= ln <= MAX_PLAUSIBLE_CYCLE]
    used = plausible[-MAX_HISTORY_CYCLES:]

    avg = min_len = max_len = stddev = None
    if used:
        avg = round(_recency_weighted_mean([float(x) for x in used]), 1)
        min_len = min(used)
        max_len = max(used)
        stddev = round(statistics.pstdev(used), 1) if len(used) > 1 else 0.0

    # Period length from rows that have an end date.
    period_lengths = [
        (period_ends[s] - s).days + 1
        for s in period_starts
        if s in period_ends and period_ends[s] >= s
    ]
    avg_period_length = (
        round(sum(period_lengths) / len(period_lengths), 1) if period_lengths else None
    )

    if has_pcos:
        regularity = "irregular"
    elif len(used) >= 2 and stddev is not None:
        regularity = "regular" if stddev <= REGULAR_STDDEV_THRESHOLD else "irregular"
    else:
        regularity = "unknown"

    return {
        "periods_logged": periods_logged,
        "cycles_tracked": len(used),
        "avg_cycle_length": avg,
        "min_cycle_length": min_len,
        "max_cycle_length": max_len,
        "cycle_length_stddev": stddev,
        "avg_period_length": avg_period_length,
        "regularity": regularity,
    }


def _detect_bbt_shift(
    points: List[Tuple[date, float]]
) -> Tuple[Optional[date], Optional[float]]:
    """Marshall three-over-six rule on Celsius BBT readings (date-ascending).

    Returns (ovulation_date, cover_line_celsius) when a sustained thermal
    shift is found — 3 consecutive readings at least BBT_SHIFT_C above the
    highest of the prior 6, with at least one BBT_STRONG_C higher. Ovulation
    is placed on the day before the first elevated reading.
    """
    temps = [t for _, t in points]
    dates = [d for d, _ in points]
    n = len(temps)
    if n < BBT_MIN_POINTS:
        return None, None
    for j in range(6, n - 2):
        prior6 = temps[j - 6:j]
        next3 = temps[j:j + 3]
        baseline = max(prior6)
        cover = baseline + BBT_SHIFT_C
        if all(t >= cover for t in next3) and any(t >= baseline + BBT_STRONG_C for t in next3):
            return dates[j] - timedelta(days=1), round(cover, 2)
    return None, None


def _phase_for(
    today: date,
    period_start: date,
    period_end_day: date,
    fertile_start: date,
    fertile_end: date,
) -> str:
    """Map today onto a cycle phase using the predicted ovulation, not
    hardcoded day numbers."""
    if period_start <= today <= period_end_day:
        return "menstrual"
    if fertile_start <= today <= fertile_end:
        return "ovulation"
    if today < fertile_start:
        return "follicular"
    return "luteal"


def phase_on_date(
    target: date,
    period_starts: List[date],
    *,
    period_ends: Optional[Dict[date, date]] = None,
    cycle_length_default: int = DEFAULT_CYCLE_LENGTH,
    period_length_default: int = DEFAULT_PERIOD_LENGTH,
    luteal_length_override: Optional[int] = None,
) -> Optional[str]:
    """Pure helper: return the cycle phase ("menstrual" / "follicular" /
    "ovulation" / "luteal") that `target` fell in, given a user's period
    history — used to tag arbitrary *past* dates (e.g. weigh-ins) rather than
    only "today".

    This complements predict(), which only reports the *current* phase. The
    math is deliberately a thin, deterministic mirror of predict()'s
    phase logic, applied to whichever logged cycle `target` belongs to:

      1. Find the period start that bounds `target` — the latest start on or
         before `target`. (If `target` predates all logged periods we cannot
         place it → return None.)
      2. Derive the period end (logged end date if present, else the average /
         default period length) and the predicted next period for that cycle
         (anchor_start + the recency-weighted average cycle length).
      3. Estimate ovulation back-counting the luteal length from that next
         period, build the ovulation-based fertile window, then map `target`
         onto a phase exactly as predict()'s `_phase_for` does.

    Returns None when `target` cannot be placed (no history, or `target`
    before the first logged period). Callers treat None as "phase unknown"
    and must not down-weight or otherwise special-case the point.
    """
    period_ends = period_ends or {}
    period_starts = sorted(set(period_starts))
    if not period_starts:
        return None

    # The cycle `target` belongs to is anchored by the latest period start
    # on or before it. A target before all history is unplaceable.
    anchor: Optional[date] = None
    for s in period_starts:
        if s <= target:
            anchor = s
        else:
            break
    if anchor is None:
        return None

    # Average cycle length from the plausible, recency-windowed gaps —
    # mirrors compute_stats() without needing the full stats dict.
    raw_lengths = _cycle_lengths(period_starts)
    plausible = [ln for ln in raw_lengths if MIN_PLAUSIBLE_CYCLE <= ln <= MAX_PLAUSIBLE_CYCLE]
    used = plausible[-MAX_HISTORY_CYCLES:]
    if used:
        avg_cycle = _recency_weighted_mean([float(x) for x in used])
    else:
        avg_cycle = float(cycle_length_default)

    # If there is a *logged* next period start after the anchor, prefer it as
    # the real cycle boundary; otherwise project one from the average.
    next_start: Optional[date] = None
    for s in period_starts:
        if s > anchor:
            next_start = s
            break
    next_period_date = next_start or (anchor + timedelta(days=int(round(avg_cycle))))

    # Period end for the anchor cycle.
    if anchor in period_ends and period_ends[anchor] >= anchor:
        period_len = (period_ends[anchor] - anchor).days + 1
    else:
        observed = [
            (period_ends[s] - s).days + 1
            for s in period_starts
            if s in period_ends and period_ends[s] >= s
        ]
        if observed:
            period_len = int(round(sum(observed) / len(observed)))
        else:
            period_len = period_length_default
    period_end_day = anchor + timedelta(days=max(period_len, 1) - 1)

    # Ovulation + fertile window for this cycle, same as predict().
    luteal = luteal_length_override or DEFAULT_LUTEAL_LENGTH
    ovulation = next_period_date - timedelta(days=luteal)
    fertile_start = ovulation - timedelta(days=FERTILE_DAYS_BEFORE)
    fertile_end = ovulation + timedelta(days=FERTILE_DAYS_AFTER)

    return _phase_for(target, anchor, period_end_day, fertile_start, fertile_end)


def _empty_stats() -> dict:
    return {
        "periods_logged": 0,
        "cycles_tracked": 0,
        "avg_cycle_length": None,
        "min_cycle_length": None,
        "max_cycle_length": None,
        "cycle_length_stddev": None,
        "avg_period_length": None,
        "regularity": "unknown",
    }


def _unavailable(today: date, tracking_mode: str, stats: dict, notes: List[str]) -> dict:
    """A prediction object with everything blank — used for symptom-only
    profiles, pregnancy mode, and the zero-history case."""
    return {
        "predictions_available": False,
        "tracking_mode": tracking_mode,
        "today": today,
        "current_cycle_day": None,
        "current_phase": None,
        "days_until_next_phase": None,
        "next_phase": None,
        "last_period_start": None,
        "in_period": False,
        "next_period_date": None,
        "next_period_window_start": None,
        "next_period_window_end": None,
        "days_until_next_period": None,
        "period_late_by": None,
        "confidence": "low",
        "ovulation_date": None,
        "ovulation_status": "estimated",
        "fertile_window_start": None,
        "fertile_window_end": None,
        "peak_fertility_start": None,
        "peak_fertility_end": None,
        "conception_chance": None,
        "cover_line_celsius": None,
        "stats": stats,
        "notes": notes,
    }


# ---------------------------------------------------------------------------
# Main entry point — pure
# ---------------------------------------------------------------------------
def predict(
    *,
    today: date,
    period_starts: List[date],
    period_ends: Optional[Dict[date, date]] = None,
    cycle_length_default: int = DEFAULT_CYCLE_LENGTH,
    period_length_default: int = DEFAULT_PERIOD_LENGTH,
    luteal_length_override: Optional[int] = None,
    has_menstrual_periods: bool = True,
    tracking_mode: str = "tracking",
    has_pcos: bool = False,
    bbt_points: Optional[List[Tuple[date, float]]] = None,
    mucus_points: Optional[List[Tuple[date, str]]] = None,
    lh_points: Optional[List[Tuple[date, str]]] = None,
) -> dict:
    """Compute a full CyclePrediction-shaped dict. See module docstring."""
    period_ends = period_ends or {}
    bbt_points = bbt_points or []
    mucus_points = mucus_points or []
    lh_points = lh_points or []

    period_starts = sorted(set(period_starts))

    # Symptom-only profile or pregnancy mode: no period/fertility prediction.
    if not has_menstrual_periods:
        return _unavailable(
            today, tracking_mode, _empty_stats(),
            ["Period prediction is off for this profile — symptom and "
             "temperature tracking still work."],
        )
    if tracking_mode == "pregnancy":
        stats = compute_stats(period_starts, period_ends, has_pcos) if period_starts else _empty_stats()
        return _unavailable(
            today, tracking_mode, stats,
            ["Cycle predictions are paused while pregnancy mode is on."],
        )
    if not period_starts:
        return _unavailable(
            today, tracking_mode, _empty_stats(),
            ["Log your first period to start predictions."],
        )

    stats = compute_stats(period_starts, period_ends, has_pcos)
    notes: List[str] = []

    last_period_start = period_starts[-1]

    # --- Average cycle length & next-period prediction ----------------------
    avg_cycle = stats["avg_cycle_length"] or float(cycle_length_default)
    cycles_tracked = stats["cycles_tracked"]
    stddev = stats["cycle_length_stddev"] or 0.0
    regularity = stats["regularity"]

    next_period_date = last_period_start + timedelta(days=int(round(avg_cycle)))
    window = _clamp(int(round(stddev)), MIN_PREDICTION_WINDOW, MAX_PREDICTION_WINDOW)
    if cycles_tracked < 2:
        window = max(window, 2)  # little history => never claim pinpoint accuracy
    next_period_window_start = next_period_date - timedelta(days=window)
    next_period_window_end = next_period_date + timedelta(days=window)

    if cycles_tracked >= 6:
        confidence = "high"
    elif cycles_tracked >= 3:
        confidence = "medium"
    else:
        confidence = "low"

    if cycles_tracked < 2:
        notes.append(
            "Based on limited history — predictions use a default "
            f"{cycle_length_default}-day cycle and will sharpen as you log more periods."
        )
    if regularity == "irregular":
        notes.append("Your cycles are irregular, so the fertile window is shown wider.")

    # --- Ovulation estimate -------------------------------------------------
    luteal = luteal_length_override or DEFAULT_LUTEAL_LENGTH
    ovulation_estimate = next_period_date - timedelta(days=luteal)

    # --- Sympto-thermal refinement (current cycle only) ---------------------
    cycle_bbt = sorted((d, t) for d, t in bbt_points if d >= last_period_start)
    ovu_from_bbt, cover_line = _detect_bbt_shift(cycle_bbt)

    ovulation_status = "estimated"
    if ovu_from_bbt is not None:
        ovulation = ovu_from_bbt
        ovulation_status = "confirmed"
        notes.append("Ovulation confirmed by a sustained basal temperature rise.")
    else:
        cycle_lh = sorted(d for d, r in lh_points if d >= last_period_start and r in _POSITIVE_LH)
        cycle_mucus = sorted(d for d, m in mucus_points if d >= last_period_start and m in _FERTILE_MUCUS)
        if cycle_lh:
            ovulation = cycle_lh[-1] + timedelta(days=1)
            notes.append("Ovulation estimate refined by a positive LH test.")
        elif cycle_mucus:
            ovulation = cycle_mucus[-1]
            notes.append("Ovulation estimate refined by cervical-mucus peak day.")
        else:
            ovulation = ovulation_estimate

    # --- Fertile window -----------------------------------------------------
    ovu_fertile_start = ovulation - timedelta(days=FERTILE_DAYS_BEFORE)
    ovu_fertile_end = ovulation + timedelta(days=FERTILE_DAYS_AFTER)

    fertile_start, fertile_end = ovu_fertile_start, ovu_fertile_end
    if regularity == "irregular" and stats["min_cycle_length"] and stats["max_cycle_length"]:
        # Ogino-Knaus calendar cross-check; take the union (wider) for safety.
        cal_first_daynum = max(1, stats["min_cycle_length"] - 18)
        cal_last_daynum = max(cal_first_daynum, stats["max_cycle_length"] - 11)
        cal_start = last_period_start + timedelta(days=cal_first_daynum - 1)
        cal_end = last_period_start + timedelta(days=cal_last_daynum - 1)
        fertile_start = min(fertile_start, cal_start)
        fertile_end = max(fertile_end, cal_end)

    peak_start = ovulation - timedelta(days=PEAK_DAYS_BEFORE)
    peak_end = ovulation

    # --- Current period membership & cycle day ------------------------------
    if last_period_start in period_ends and period_ends[last_period_start] >= last_period_start:
        period_len = (period_ends[last_period_start] - last_period_start).days + 1
    else:
        period_len = int(round(stats["avg_period_length"] or period_length_default))
    period_end_day = last_period_start + timedelta(days=max(period_len, 1) - 1)
    in_period = last_period_start <= today <= period_end_day

    cycle_day = max(1, (today - last_period_start).days + 1)

    # --- Late-period state --------------------------------------------------
    days_until_next_period = None
    period_late_by = None
    if today < next_period_date:
        days_until_next_period = (next_period_date - today).days
    elif today > next_period_window_end:
        period_late_by = (today - next_period_date).days
        notes.append(f"Your period is {period_late_by} day(s) later than predicted.")

    # --- Phase + next transition -------------------------------------------
    phase = _phase_for(today, last_period_start, period_end_day, fertile_start, fertile_end)

    transitions = [
        (period_end_day + timedelta(days=1), "follicular"),
        (fertile_start, "ovulation"),
        (fertile_end + timedelta(days=1), "luteal"),
        (next_period_date, "menstrual"),
    ]
    upcoming = sorted(t for t in transitions if t[0] > today)
    if upcoming:
        next_transition_date, next_phase = upcoming[0]
        days_until_next_phase = (next_transition_date - today).days
    else:
        next_phase, days_until_next_phase = "menstrual", None

    conception_chance = "high" if fertile_start <= today <= fertile_end else "low"

    return {
        "predictions_available": True,
        "tracking_mode": tracking_mode,
        "today": today,
        "current_cycle_day": cycle_day,
        "current_phase": phase,
        "days_until_next_phase": days_until_next_phase,
        "next_phase": next_phase,
        "last_period_start": last_period_start,
        "in_period": in_period,
        "next_period_date": next_period_date,
        "next_period_window_start": next_period_window_start,
        "next_period_window_end": next_period_window_end,
        "days_until_next_period": days_until_next_period,
        "period_late_by": period_late_by,
        "confidence": confidence,
        "ovulation_date": ovulation,
        "ovulation_status": ovulation_status,
        "fertile_window_start": fertile_start,
        "fertile_window_end": fertile_end,
        "peak_fertility_start": peak_start,
        "peak_fertility_end": peak_end,
        "conception_chance": conception_chance,
        "cover_line_celsius": cover_line,
        "stats": stats,
        "notes": notes,
    }


# ---------------------------------------------------------------------------
# Orchestrator — impure: loads a user's data and runs predict()
# ---------------------------------------------------------------------------
def predict_for_user(client, user_id: str, today: date) -> dict:
    """Load a user's profile, period history and recent fertility-signal logs
    from Supabase, then run predict(). `client` is a supabase-py PostgREST
    client (get_supabase().client). Used by the API and workout generation so
    there is a single prediction path.
    """
    user_id = str(user_id)

    profile_res = client.table("hormonal_profiles").select("*").eq("user_id", user_id).execute()
    profile = profile_res.data[0] if profile_res.data else {}

    periods_res = (
        client.table("cycle_periods")
        .select("start_date,end_date")
        .eq("user_id", user_id)
        .order("start_date")
        .execute()
    )
    period_rows = periods_res.data or []
    period_starts = [date.fromisoformat(r["start_date"]) for r in period_rows if r.get("start_date")]
    period_ends = {
        date.fromisoformat(r["start_date"]): date.fromisoformat(r["end_date"])
        for r in period_rows
        if r.get("start_date") and r.get("end_date")
    }

    # Recent fertility-signal logs (120 days covers ~4 cycles of BBT context).
    cutoff = (today - timedelta(days=120)).isoformat()
    logs_res = (
        client.table("hormone_logs")
        .select("log_date,basal_body_temperature,cervical_mucus,lh_test_result")
        .eq("user_id", user_id)
        .gte("log_date", cutoff)
        .execute()
    )
    bbt_points: List[Tuple[date, float]] = []
    mucus_points: List[Tuple[date, str]] = []
    lh_points: List[Tuple[date, str]] = []
    for log in logs_res.data or []:
        raw = log.get("log_date")
        if not raw:
            continue
        d = date.fromisoformat(raw)
        if log.get("basal_body_temperature") is not None:
            bbt_points.append((d, float(log["basal_body_temperature"])))
        if log.get("cervical_mucus"):
            mucus_points.append((d, log["cervical_mucus"]))
        if log.get("lh_test_result"):
            lh_points.append((d, log["lh_test_result"]))

    has_periods = profile.get("has_menstrual_periods")
    return predict(
        today=today,
        period_starts=period_starts,
        period_ends=period_ends,
        cycle_length_default=profile.get("cycle_length_days") or DEFAULT_CYCLE_LENGTH,
        period_length_default=profile.get("typical_period_duration_days") or DEFAULT_PERIOD_LENGTH,
        luteal_length_override=profile.get("luteal_length_days"),
        has_menstrual_periods=True if has_periods is None else bool(has_periods),
        tracking_mode=profile.get("tracking_mode") or "tracking",
        has_pcos=bool(profile.get("has_pcos", False)),
        bbt_points=bbt_points,
        mucus_points=mucus_points,
        lh_points=lh_points,
    )
