"""
Cardio Activity Context for the AI Coach
========================================
Sibling to `health_activity.py` — pulls the user's recent cardio picture
(sessions / VO2max trend / training load / PRs) and formats it as a compact
prompt string the coach agent can cite.

Returns None cleanly when the user has zero cardio history (NORMAL state — no
fabrication, see CLAUDE.md). All numbers rounded to 1 decimal place. Output is
hard-capped at ~250 tokens (~1000 chars) so the coach prompt budget stays bounded.

Sources of truth (all existing tables / views — nothing new is created here):
  - `cardio_logs`            : imported sessions (Strava/Peloton/Garmin/...).
  - `cardio_sessions`        : manual in-app sessions.
  - `latest_cardio_metrics`  : VIEW — most recent row per user from
                               cardio_metrics (vo2_max_estimate, fitness_age).
  - `cardio_metric_snapshots`: derived daily metrics (training_load_acwr).
  - `personal_records`       : cardio PRs are rows WHERE sport IS NOT NULL
                               (migration 2094 extended this table).

Edge cases:
  - Zero cardio sessions AND zero cardio_sessions rows → return None.
  - focus_cardio_log_id that does not belong to the user → silently omit the
    "THIS session" line (the endpoint enforces ownership separately).
  - All token-cap truncation happens on the FINAL joined string so we never
    truncate mid-number and never lose the "THIS session" line (it is appended
    last and its presence is checked before / after truncation).
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional
from uuid import UUID

from core.db import get_supabase_db

logger = logging.getLogger(__name__)

# Token budget — naive 4-chars-per-token estimate so the cap is enforced on
# `len(string) // 4 <= MAX_TOKENS`. Sized to comfortably fit alongside the
# existing health_context block in the coach prompt.
_MAX_TOKENS = 250
_MAX_CHARS = _MAX_TOKENS * 4  # 1000 chars

_RECENT_WINDOW_DAYS = 14
_MAX_PRS = 3


def _round1(v: Any) -> Optional[float]:
    """Return v rounded to 1 decimal, or None if not coercible."""
    if v is None:
        return None
    try:
        return round(float(v), 1)
    except (TypeError, ValueError):
        return None


def _truncate(text: str, max_chars: int = _MAX_CHARS) -> str:
    """Truncate at a sentence boundary so we never cut a number in half."""
    if len(text) <= max_chars:
        return text
    cut = text[:max_chars]
    # Prefer the last sentence boundary, then last newline, then a hard cut.
    for sep in (". ", "\n", " "):
        idx = cut.rfind(sep)
        if idx >= max_chars * 0.6:  # don't truncate too aggressively
            return cut[: idx + 1].rstrip()
    return cut.rstrip()


def _sport_label_for(activity_type: Optional[str]) -> str:
    """Map cardio_logs.activity_type / cardio_sessions.cardio_type into a
    short user-facing label for the prompt."""
    if not activity_type:
        return "session"
    t = str(activity_type).lower()
    if "run" in t or t == "treadmill":
        return "run"
    if "cycl" in t or "bike" in t:
        return "bike"
    if "row" in t or "erg" in t:
        return "row"
    if "swim" in t:
        return "swim"
    if "walk" in t or "hike" in t:
        return "walk"
    if "ellip" in t or "stair" in t or "step" in t:
        return t
    return t


def _format_duration(seconds: Optional[float]) -> Optional[str]:
    """Format a duration in seconds as '32:15' or '1:05:22'."""
    if seconds is None:
        return None
    try:
        s = int(round(float(seconds)))
    except (TypeError, ValueError):
        return None
    if s <= 0:
        return None
    h, rem = divmod(s, 3600)
    m, sec = divmod(rem, 60)
    if h:
        return f"{h}:{m:02d}:{sec:02d}"
    return f"{m}:{sec:02d}"


def _format_pace(sec_per_km: Optional[float]) -> Optional[str]:
    """Format pace as 'M:SS/km'."""
    if sec_per_km is None or sec_per_km <= 0:
        return None
    s = int(round(float(sec_per_km)))
    m, sec = divmod(s, 60)
    return f"{m}:{sec:02d}/km"


async def get_cardio_context_for_ai(
    user_id: Any,
    focus_cardio_log_id: Optional[Any] = None,
    db: Any = None,
) -> Optional[str]:
    """Build a compact cardio-context block for the AI coach prompt.

    Args:
        user_id: User UUID (string or UUID).
        focus_cardio_log_id: Optional UUID of the cardio_logs row the caller
            wants the coach to comment on. When set, appends a "THIS session"
            line so the auto-insight prompt has something concrete to reason
            against. Silently omitted if the row does not belong to the user.
        db: Optional pre-resolved SupabaseDB (for tests). Defaults to the
            process-wide singleton.

    Returns:
        A compact multi-line string <=250 tokens, OR None when the user has
        no cardio history at all (NORMAL state — caller must not fabricate
        numbers).
    """
    uid = str(user_id)

    try:
        sb = db if db is not None else get_supabase_db()
    except Exception as e:
        logger.warning(f"[cardio_context] DB unavailable for {uid}: {e}")
        return None

    now = datetime.now(timezone.utc)
    window_start = now - timedelta(days=_RECENT_WINDOW_DAYS)
    window_start_iso = window_start.isoformat()

    # -----------------------------------------------------------------------
    # 1) Recent cardio_logs (imported sessions) in last 14 days
    # -----------------------------------------------------------------------
    cardio_logs_rows: List[Dict[str, Any]] = []
    try:
        resp = (
            sb.client.table("cardio_logs")
            .select(
                "id, performed_at, activity_type, duration_seconds, "
                "distance_m, avg_pace_seconds_per_km, avg_heart_rate, "
                "tags"
            )
            .eq("user_id", uid)
            .gte("performed_at", window_start_iso)
            .order("performed_at", desc=True)
            .limit(50)
            .execute()
        )
        cardio_logs_rows = list(resp.data or [])
    except Exception as e:
        logger.debug(f"[cardio_context] cardio_logs lookup failed: {e}")

    # -----------------------------------------------------------------------
    # 2) Recent cardio_sessions (manual in-app) in last 14 days
    # -----------------------------------------------------------------------
    cardio_sessions_rows: List[Dict[str, Any]] = []
    try:
        resp = (
            sb.client.table("cardio_sessions")
            .select(
                "id, created_at, started_at, cardio_type, "
                "duration_minutes, actual_duration_minutes, "
                "distance_km, avg_heart_rate, calories_burned"
            )
            .eq("user_id", uid)
            .gte("created_at", window_start_iso)
            .order("created_at", desc=True)
            .limit(50)
            .execute()
        )
        cardio_sessions_rows = list(resp.data or [])
    except Exception as e:
        logger.debug(f"[cardio_context] cardio_sessions lookup failed: {e}")

    # -----------------------------------------------------------------------
    # 3) Look up the focus session (if requested) — also serves as proof of
    #    existence so the prompt can mention THIS session honestly.
    # -----------------------------------------------------------------------
    focus_row: Optional[Dict[str, Any]] = None
    if focus_cardio_log_id is not None:
        try:
            resp = (
                sb.client.table("cardio_logs")
                .select(
                    "id, user_id, performed_at, activity_type, "
                    "duration_seconds, distance_m, "
                    "avg_pace_seconds_per_km, avg_heart_rate, tags, "
                    "elevation_gain_m"
                )
                .eq("id", str(focus_cardio_log_id))
                .limit(1)
                .execute()
            )
            if resp.data:
                row = resp.data[0]
                # Ownership check — the endpoint already does this, but
                # double-gate to avoid leaking THIS-session details across
                # users if a caller passes the wrong id.
                if str(row.get("user_id")) == uid:
                    focus_row = row
        except Exception as e:
            logger.debug(f"[cardio_context] focus row lookup failed: {e}")

    # -----------------------------------------------------------------------
    # Early exit: zero history AND no focus session → caller treats as "no
    # cardio context available" and the coach must not invent numbers.
    # -----------------------------------------------------------------------
    if not cardio_logs_rows and not cardio_sessions_rows and not focus_row:
        return None

    # -----------------------------------------------------------------------
    # 4) Latest VO2max from latest_cardio_metrics view (single-row).
    # -----------------------------------------------------------------------
    vo2max_value: Optional[float] = None
    vo2max_source: Optional[str] = None
    try:
        resp = (
            sb.client.table("latest_cardio_metrics")
            .select("vo2_max_estimate, source")
            .eq("user_id", uid)
            .limit(1)
            .execute()
        )
        if resp.data:
            vo2max_value = _round1(resp.data[0].get("vo2_max_estimate"))
            vo2max_source = resp.data[0].get("source")
    except Exception as e:
        logger.debug(f"[cardio_context] latest_cardio_metrics lookup failed: {e}")

    # -----------------------------------------------------------------------
    # 5) Most recent training-load ACWR snapshot
    # -----------------------------------------------------------------------
    acwr_value: Optional[float] = None
    try:
        resp = (
            sb.client.table("cardio_metric_snapshots")
            .select("metric_value, snapshot_date")
            .eq("user_id", uid)
            .eq("metric_key", "training_load_acwr")
            .order("snapshot_date", desc=True)
            .limit(1)
            .execute()
        )
        if resp.data:
            acwr_value = _round1(resp.data[0].get("metric_value"))
    except Exception as e:
        logger.debug(f"[cardio_context] ACWR lookup failed: {e}")

    # -----------------------------------------------------------------------
    # 6) Recent cardio PRs (personal_records where sport IS NOT NULL).
    # -----------------------------------------------------------------------
    pr_rows: List[Dict[str, Any]] = []
    try:
        resp = (
            sb.client.table("personal_records")
            .select("exercise_name, sport, achieved_at, weight_kg, reps")
            .eq("user_id", uid)
            .not_.is_("sport", "null")
            .order("achieved_at", desc=True)
            .limit(_MAX_PRS)
            .execute()
        )
        pr_rows = list(resp.data or [])[:_MAX_PRS]
    except Exception as e:
        logger.debug(f"[cardio_context] PR lookup failed: {e}")

    # -----------------------------------------------------------------------
    # Build the compact prompt string.
    # -----------------------------------------------------------------------
    lines: List[str] = []

    # --- Headline: count + total distance ---
    n_logs = len(cardio_logs_rows)
    n_sessions = len(cardio_sessions_rows)
    n_total = n_logs + n_sessions

    total_km = 0.0
    for r in cardio_logs_rows:
        dm = r.get("distance_m")
        if dm is not None:
            try:
                total_km += float(dm) / 1000.0
            except (TypeError, ValueError):
                pass
    for r in cardio_sessions_rows:
        dk = r.get("distance_km")
        if dk is not None:
            try:
                total_km += float(dk)
            except (TypeError, ValueError):
                pass

    if n_total > 0:
        if total_km > 0:
            lines.append(
                f"CARDIO (last {_RECENT_WINDOW_DAYS}d): {n_total} sessions, "
                f"{round(total_km, 1)} km total."
            )
        else:
            lines.append(
                f"CARDIO (last {_RECENT_WINDOW_DAYS}d): {n_total} sessions."
            )

    # --- Top sport summary (mode) ---
    sport_counts: Dict[str, int] = {}
    sport_distance: Dict[str, float] = {}
    for r in cardio_logs_rows:
        s = _sport_label_for(r.get("activity_type"))
        sport_counts[s] = sport_counts.get(s, 0) + 1
        try:
            sport_distance[s] = sport_distance.get(s, 0.0) + (
                float(r.get("distance_m") or 0) / 1000.0
            )
        except (TypeError, ValueError):
            pass
    for r in cardio_sessions_rows:
        s = _sport_label_for(r.get("cardio_type"))
        sport_counts[s] = sport_counts.get(s, 0) + 1
        try:
            sport_distance[s] = sport_distance.get(s, 0.0) + (
                float(r.get("distance_km") or 0)
            )
        except (TypeError, ValueError):
            pass

    if sport_counts:
        top_sport = max(sport_counts.items(), key=lambda kv: kv[1])
        top_name, top_n = top_sport
        top_km = round(sport_distance.get(top_name, 0.0), 1)
        if top_km > 0:
            lines.append(
                f"Top sport: {top_name} ({top_n} sessions, {top_km} km)."
            )
        else:
            lines.append(f"Top sport: {top_name} ({top_n} sessions).")

    # --- VO2max trend ---
    if vo2max_value is not None:
        src = f" ({vo2max_source})" if vo2max_source else ""
        lines.append(f"VO2max: {vo2max_value}{src}.")

    # --- Training-load state (ACWR) ---
    # ACWR sweet-spot is 0.8-1.3 (Gabbett 2016). >1.5 = elevated injury risk;
    # <0.8 = undertrained / detraining. State is deterministic, never an LLM.
    if acwr_value is not None:
        if acwr_value < 0.8:
            state = "undertrained"
        elif acwr_value <= 1.3:
            state = "balanced"
        elif acwr_value <= 1.5:
            state = "ramping"
        else:
            state = "overreaching"
        lines.append(f"Training load (ACWR): {acwr_value} ({state}).")

    # --- 3 most-recent PRs ---
    if pr_rows:
        pr_strs: List[str] = []
        for pr in pr_rows:
            name = pr.get("exercise_name") or pr.get("sport") or "PR"
            sport = pr.get("sport")
            # Pace PRs (weight_kg=0, reps=0) are stored on cardio sport rows;
            # we cite the exercise_name verbatim because that's where the
            # human-readable label lives (e.g. "5K personal best").
            label = str(name)
            if sport and sport not in label.lower():
                label = f"{label} ({sport})"
            pr_strs.append(label)
        lines.append(f"Recent PRs: {'; '.join(pr_strs)}.")

    # --- THIS session (focus) — appended LAST so it survives truncation ---
    if focus_row is not None:
        sport = _sport_label_for(focus_row.get("activity_type"))
        dist_m = focus_row.get("distance_m")
        dist_km: Optional[float] = None
        if dist_m is not None:
            try:
                dist_km = round(float(dist_m) / 1000.0, 1)
            except (TypeError, ValueError):
                dist_km = None
        dur = _format_duration(focus_row.get("duration_seconds"))
        pace = _format_pace(focus_row.get("avg_pace_seconds_per_km"))
        hr = focus_row.get("avg_heart_rate")
        elev = focus_row.get("elevation_gain_m")
        tags = focus_row.get("tags")

        parts: List[str] = [f"THIS session: {sport}"]
        if dist_km is not None:
            parts.append(f"{dist_km}km")
        if dur:
            parts.append(f"in {dur}")
        if pace:
            parts.append(f"({pace})")
        if hr:
            parts.append(f"avg HR {int(hr)}")
        try:
            if elev and float(elev) > 0:
                parts.append(f"{int(float(elev))}m elev")
        except (TypeError, ValueError):
            pass
        # Pull at most one notable tag so the line stays compact.
        if isinstance(tags, list) and tags:
            parts.append(f"tag: {tags[0]}")

        lines.append(" ".join(parts) + ".")

    if not lines:
        # Should not reach here given the early-exit above, but defensive.
        return None

    out = "\n".join(lines)
    out = _truncate(out, _MAX_CHARS)

    # If truncation lost the "THIS session" line, re-append it within budget
    # by trimming earlier lines instead (the focus line is the most valuable
    # signal for the cardio_auto_insight mode).
    if focus_row is not None and "THIS session" not in out:
        focus_line = lines[-1]
        budget = _MAX_CHARS - len(focus_line) - 1
        if budget > 0:
            head = "\n".join(lines[:-1])
            head = _truncate(head, budget)
            out = head + "\n" + focus_line

    return out
