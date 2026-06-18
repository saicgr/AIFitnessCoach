"""
Recovery Signal Service — close the recovery-aware import loop.
=============================================================

When a user imports an external cardio workout (a watch run/ride/walk synced
from Health Connect / Apple Health) and rates its effort on the "Rate your
Effort" step (Light / Moderate / Hard → 1 / 2 / 3 recovery days), that
effort/recovery signal used to land in a void — nothing downstream read it,
so the coach's Daily Outlook never said "you ran hard yesterday, take today
lighter." This service derives a deterministic, recency-sensitive recovery
signal from that imported cardio (+ any native ``cardio_logs`` rows) and
surfaces it into the coach's Today / Daily-Outlook context so the next day's
guidance reflects it.

Why a NEW signal when ``training_load_service`` already exists
-------------------------------------------------------------
``training_load_service.current_state`` gives an excellent CHRONIC view —
7-day acute vs 28-day chronic load (ACWR). But ACWR is deliberately slow: a
single Hard session yesterday barely nudges a 7-day sum, so the chronic view
can read "balanced" the morning after a hammering. The recovery-aware import
loop needs the opposite — an ACUTE, last-24-48h read keyed to the user's own
perceived effort. That is what this module adds, and it COMBINES the two: the
acute effort flag is the fast trigger, the chronic ACWR state is the
corroborating context.

Determinism + hot path
----------------------
This is pure arithmetic over a handful of recent rows — no LLM, no RAG, no
network beyond two indexed Supabase reads (run concurrently). It targets
<100ms and is meant to be called inside the coach snapshot assembly. Per
``feedback_prefer_local_algo_over_rag`` + ``feedback_no_llm_for_safety_classification``
the recovery recommendation is a deterministic table, never a model call.

Fail-open contract
------------------
Every read is wrapped so a missing table, empty history, or malformed
metadata yields ``None`` ("no signal — proceed exactly as before"). This
NEVER raises into the coach snapshot and NEVER feeds into workout generation,
so it cannot block or alter a generated plan (per
``feedback_workout_gen_zero_regression``). It is purely additive coach
CONTEXT: advice, not an automated plan mutation.

Where the data lives (verified against the live schema)
------------------------------------------------------
Imported external workouts are persisted by the Flutter
``HealthImportNotifier.importAsNewWorkout`` into the ``workouts`` table
(``type='cardio'``, ``generation_source='health_connect'`` /
``generation_method='health_connect_import'``) — NOT into ``cardio_logs``.
The chosen effort is stored two ways on that row:
  - ``difficulty``  : 'beginner' | 'intermediate' | 'advanced'
                      (legacy rows use 'easy'/'medium'/'hard' or 'medium').
  - ``generation_metadata`` (jsonb, sometimes a JSON-encoded string) carries
    ``training_load_trimp`` (float) and ``effort_score`` (0-100 int) when the
    newer "Rate your Effort" sheet stamped them.
Native cardio (manual entry / future direct OAuth) lands in ``cardio_logs``
with an ``rpe`` (0-10) + ``calories`` + ``avg_heart_rate``. We read both so
the signal is robust no matter which path produced the session.
"""
from __future__ import annotations

import json
import math
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Tuning constants — the deterministic recovery table.
# ---------------------------------------------------------------------------
#
# These map a user's perceived effort onto an "effort weight" (0..1) and a
# recovery-day count, matching the Flutter import sheet's own mapping
# (Light→1d, Moderate→2d, Hard→3d) so the backend signal and the UI caption
# the user already saw never disagree.

# Look-back window for the ACUTE effort signal. 48h captures "I ran hard
# yesterday evening" the next morning AND "I ran hard this morning" later the
# same day. Older sessions are handled by the chronic ACWR view instead.
_ACUTE_WINDOW_HOURS = 48

# Per-effort normalized weight (0..1) + the recovery-day count the UI shows.
# Keyed by a normalized effort label. Both the new ('beginner'/'intermediate'/
# 'advanced') and legacy ('easy'/'medium'/'hard') difficulty vocabularies map
# through ``_normalize_effort`` to one of these three buckets.
_EFFORT_TABLE: Dict[str, Dict[str, Any]] = {
    "light":    {"weight": 0.34, "recovery_days": 1},
    "moderate": {"weight": 0.67, "recovery_days": 2},
    "hard":     {"weight": 1.00, "recovery_days": 3},
}

# A single Hard session inside the window is enough to recommend an easier day.
# A Moderate one only does so when it is very recent (< 24h) AND the chronic
# load already reads loading/overreaching — otherwise moderate cardio is just
# normal training and should not nag the user into backing off.
_HARD_WEIGHT_FLOOR = _EFFORT_TABLE["hard"]["weight"]        # 1.0
_MODERATE_WEIGHT_FLOOR = _EFFORT_TABLE["moderate"]["weight"]  # 0.67

# TRIMP above this in the acute window is itself a "high load" trigger even if
# the user rated effort generously low. ~150 TRIMP ≈ a solid 45-60min session.
_ACUTE_TRIMP_HIGH = 150.0

# Recency half-life (hours) for blending multiple recent sessions: a session
# 24h ago counts half as much as one just finished. Keeps "two easy jogs" from
# masquerading as one hard effort.
_RECENCY_HALFLIFE_H = 24.0


# ---------------------------------------------------------------------------
# Public result type
# ---------------------------------------------------------------------------


@dataclass
class RecoverySignal:
    """A deterministic acute-recovery read derived from recent cardio + effort.

    All fields are snapshot-groundable scalars/strings so they slot straight
    into the coach number guardrail.

    Attributes
    ----------
    recommendation:
        One of ``"go_lighter"`` | ``"active_recovery"`` | ``"as_planned"``.
        The coach turns this into copy; it is NOT a workout mutation.
    reason:
        Short human-readable justification (e.g. "Hard cardio 14h ago").
    peak_effort:
        The hardest effort label seen in the acute window
        (``"light"|"moderate"|"hard"``) or ``None`` if no rated cardio.
    recovery_days_suggested:
        The recovery-day count tied to ``peak_effort`` (1/2/3), surfaced so
        the coach can say "give it ~2 days".
    acute_trimp:
        Sum of TRIMP across the acute window (rounded), when computable.
    hours_since_peak:
        Hours since the hardest recent session ended (rounded), for "Xh ago".
    chronic_state:
        The corroborating ACWR state ("balanced"/"loading"/"overreaching"/…)
        or ``None`` when the chronic view is still calibrating.
    sessions_in_window:
        Count of cardio sessions found in the acute window.
    """

    recommendation: str
    reason: str
    peak_effort: Optional[str]
    recovery_days_suggested: Optional[int]
    acute_trimp: Optional[float]
    hours_since_peak: Optional[float]
    chronic_state: Optional[str]
    sessions_in_window: int

    def to_snapshot_dict(self) -> Dict[str, Any]:
        """Compact dict for embedding in the coach snapshot.

        Omits None values so the prompt never narrates an absent metric.
        """
        out: Dict[str, Any] = {
            "recommendation": self.recommendation,
            "reason": self.reason,
            "sessions_in_window": self.sessions_in_window,
        }
        if self.peak_effort is not None:
            out["peak_effort"] = self.peak_effort
        if self.recovery_days_suggested is not None:
            out["recovery_days_suggested"] = self.recovery_days_suggested
        if self.acute_trimp is not None:
            out["acute_trimp"] = round(self.acute_trimp)
        if self.hours_since_peak is not None:
            out["hours_since_peak"] = round(self.hours_since_peak)
        if self.chronic_state is not None:
            out["chronic_state"] = self.chronic_state
        return out


# ---------------------------------------------------------------------------
# Internal: a normalized recent cardio session
# ---------------------------------------------------------------------------


@dataclass
class _AcuteSession:
    when: datetime           # tz-aware, UTC
    effort_weight: float     # 0..1 (from rating or derived)
    effort_label: Optional[str]  # light|moderate|hard|None
    trimp: Optional[float]   # session TRIMP if computable
    source: str              # "import" | "cardio_log"


def _normalize_effort(value: Optional[str]) -> Optional[str]:
    """Map a difficulty/effort string onto light|moderate|hard, else None.

    Handles the new import vocabulary (beginner/intermediate/advanced), the
    legacy difficulty vocabulary (easy/medium/hard), and direct light/
    moderate/hard. Unknown / empty → None (treated as "unrated").
    """
    if not value:
        return None
    v = str(value).strip().lower()
    if v in ("light", "easy", "beginner", "low"):
        return "light"
    if v in ("moderate", "medium", "intermediate", "normal"):
        return "moderate"
    if v in ("hard", "advanced", "high", "intense", "max", "very_hard"):
        return "hard"
    return None


def _effort_from_score(effort_score: Optional[Any]) -> Optional[str]:
    """Map a 0-100 effort_score onto a label. None / non-numeric → None.

    Bands mirror the import sheet stamp (light=20, moderate=55, hard=85) with
    midpoints between them: <38 → light, <70 → moderate, else hard.
    """
    if effort_score is None:
        return None
    try:
        s = float(effort_score)
    except (TypeError, ValueError):
        return None
    if s <= 0:
        return None
    if s < 38:
        return "light"
    if s < 70:
        return "moderate"
    return "hard"


def _parse_dt(value: Any) -> Optional[datetime]:
    """Best-effort parse to a tz-aware UTC datetime; None on failure."""
    if value is None:
        return None
    if isinstance(value, datetime):
        return value if value.tzinfo else value.replace(tzinfo=timezone.utc)
    if isinstance(value, str):
        try:
            dt = datetime.fromisoformat(value.replace("Z", "+00:00"))
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        except Exception:
            return None
    return None


def _coerce_metadata(raw: Any) -> Dict[str, Any]:
    """generation_metadata is jsonb but historically written as a JSON STRING.

    Accept a dict (already decoded) or a JSON string; anything else → {}.
    """
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str) and raw.strip():
        try:
            decoded = json.loads(raw)
            return decoded if isinstance(decoded, dict) else {}
        except Exception:
            return {}
    return {}


def _session_trimp_from_import(
    meta: Dict[str, Any],
    duration_minutes: Optional[Any],
    effort_label: Optional[str],
) -> Optional[float]:
    """Derive a TRIMP estimate for an imported workout row.

    Prefers the stamped ``training_load_trimp``; otherwise approximates from
    duration × an effort-weighted per-minute factor (loose Foster sRPE-style
    proxy, NOT a safety classification). Returns None when neither is usable.
    """
    raw_trimp = meta.get("training_load_trimp")
    if raw_trimp is not None:
        try:
            t = float(raw_trimp)
            if t > 0:
                return t
        except (TypeError, ValueError):
            pass

    # Fallback: duration × effort-weighted rate. Mirrors the spirit of
    # training_load_service's RPE fallback (duration_min * rpe) using the
    # effort weight as a coarse 0..1 stand-in scaled to a ~Z2-to-hard range.
    try:
        dur = float(duration_minutes) if duration_minutes is not None else 0.0
    except (TypeError, ValueError):
        dur = 0.0
    if dur <= 0:
        return None
    weight = _EFFORT_TABLE.get(effort_label or "", {}).get("weight", 0.5)
    # 4.0/min at light .. ~9.0/min at hard — same ballpark as the
    # training_load_service activity fallbacks, so the two views stay close.
    per_min = 4.0 + 5.0 * weight
    return dur * per_min


# ---------------------------------------------------------------------------
# Data loaders (each fail-open, return [] on any error)
# ---------------------------------------------------------------------------


def _load_imported_cardio(db, user_id: str, since: datetime) -> List[_AcuteSession]:
    """Recently-completed imported external cardio from the ``workouts`` table.

    These are the rows the "Rate your Effort" sheet produces. We key effort
    off ``generation_metadata.effort_score`` first (most precise), then the
    row's ``difficulty``, so a rated session always contributes a real effort
    label and recovery-day suggestion.
    """
    sessions: List[_AcuteSession] = []
    try:
        res = (
            db.client.table("workouts")
            .select(
                "completed_at, scheduled_date, difficulty, duration_minutes, "
                "generation_metadata, generation_source, generation_method, type"
            )
            .eq("user_id", user_id)
            .eq("is_completed", True)
            .gte("completed_at", since.isoformat())
            .order("completed_at", desc=True)
            .limit(20)
            .execute()
        )
        rows = res.data or []
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[Recovery] imported-cardio query failed: {e}")
        return []

    for row in rows:
        # Only count health-imported cardio — a generated strength workout the
        # user completed is NOT an external-cardio recovery cost we should
        # nag about here (the chronic ACWR view covers overall load).
        src = (row.get("generation_source") or "").lower()
        method = (row.get("generation_method") or "").lower()
        is_import = src == "health_connect" or method == "health_connect_import"
        if not is_import:
            continue

        when = _parse_dt(row.get("completed_at")) or _parse_dt(row.get("scheduled_date"))
        if when is None or when < since:
            continue

        meta = _coerce_metadata(row.get("generation_metadata"))
        # effort_score (precise) → difficulty (coarse) → None (unrated).
        label = _effort_from_score(meta.get("effort_score")) or _normalize_effort(
            row.get("difficulty")
        )
        weight = _EFFORT_TABLE.get(label or "", {}).get("weight")
        if weight is None:
            # Unrated import — still a session, treat as moderate weight so a
            # long unrated ride isn't invisible, but it can't trigger
            # "go_lighter" on its own (only Hard / high-TRIMP does that).
            weight = 0.5
        trimp = _session_trimp_from_import(meta, row.get("duration_minutes"), label)
        sessions.append(
            _AcuteSession(
                when=when,
                effort_weight=weight,
                effort_label=label,
                trimp=trimp,
                source="import",
            )
        )
    return sessions


def _load_native_cardio(db, user_id: str, since: datetime) -> List[_AcuteSession]:
    """Recent native cardio from ``cardio_logs`` (rpe / calories / HR present).

    Reuses ``training_load_service.compute_session_trimp`` so a session's load
    here matches what the training-load timeline shows for the same row.
    """
    sessions: List[_AcuteSession] = []
    try:
        res = (
            db.client.table("cardio_logs")
            .select(
                "performed_at, duration_seconds, avg_heart_rate, rpe, calories, "
                "activity_type"
            )
            .eq("user_id", user_id)
            .gte("performed_at", since.isoformat())
            .order("performed_at", desc=True)
            .limit(20)
            .execute()
        )
        rows = res.data or []
    except Exception as e:  # pragma: no cover - defensive
        logger.warning(f"[Recovery] cardio_logs query failed: {e}")
        return []

    try:
        from services.training_load_service import compute_session_trimp
    except Exception:  # pragma: no cover - defensive
        compute_session_trimp = None  # type: ignore

    for row in rows:
        when = _parse_dt(row.get("performed_at"))
        if when is None or when < since:
            continue
        rpe = row.get("rpe")
        # RPE (0-10) → effort label: ≤4 light, ≤7 moderate, else hard.
        label: Optional[str] = None
        if rpe is not None:
            try:
                r = float(rpe)
                label = "light" if r <= 4 else ("moderate" if r <= 7 else "hard")
            except (TypeError, ValueError):
                label = None
        weight = _EFFORT_TABLE.get(label or "", {}).get("weight", 0.5)

        trimp: Optional[float] = None
        if compute_session_trimp is not None:
            try:
                dur_min = float(row.get("duration_seconds") or 0) / 60.0
                trimp = compute_session_trimp(
                    duration_minutes=dur_min,
                    avg_hr=row.get("avg_heart_rate"),
                    rpe=rpe,
                    calories=row.get("calories"),
                    activity_type=row.get("activity_type"),
                ) or None
            except Exception:
                trimp = None
        sessions.append(
            _AcuteSession(
                when=when,
                effort_weight=weight,
                effort_label=label,
                trimp=trimp,
                source="cardio_log",
            )
        )
    return sessions


# ---------------------------------------------------------------------------
# The deterministic decision
# ---------------------------------------------------------------------------


def _decide(
    sessions: List[_AcuteSession],
    chronic_state: Optional[str],
    now: datetime,
) -> Optional[RecoverySignal]:
    """Turn recent sessions + chronic state into a recovery recommendation.

    Returns None when there is simply nothing to say (no recent cardio) so the
    caller omits the block entirely rather than narrating "as planned" noise.
    """
    if not sessions:
        return None

    # Identify the hardest recent session (peak effort) and its recency.
    def _rank(s: _AcuteSession) -> float:
        return s.effort_weight

    peak = max(sessions, key=_rank)
    hours_since_peak = max(0.0, (now - peak.when).total_seconds() / 3600.0)

    # Recency-weighted acute TRIMP (half-life decay) — keeps several easy
    # sessions from summing into a false "high load".
    acute_trimp = 0.0
    have_trimp = False
    for s in sessions:
        if s.trimp is None:
            continue
        have_trimp = True
        age_h = max(0.0, (now - s.when).total_seconds() / 3600.0)
        decay = math.pow(0.5, age_h / _RECENCY_HALFLIFE_H)
        acute_trimp += s.trimp * decay
    acute_trimp_val: Optional[float] = round(acute_trimp, 1) if have_trimp else None

    peak_label = peak.effort_label
    peak_recovery_days = (
        _EFFORT_TABLE.get(peak_label or "", {}).get("recovery_days")
        if peak_label
        else None
    )

    high_trimp = acute_trimp_val is not None and acute_trimp_val >= _ACUTE_TRIMP_HIGH
    chronic_elevated = chronic_state in ("loading", "overreaching")

    # ----- Decision table (deterministic, ordered most→least severe) -------
    #
    # 1. Hard session in the window, OR a very high acute TRIMP while the
    #    chronic load is already elevated → recommend an easier day. If the
    #    hard session is very recent (<24h) AND chronic is overreaching, push
    #    to active recovery instead of just "lighter".
    if peak.effort_weight >= _HARD_WEIGHT_FLOOR or (high_trimp and chronic_elevated):
        if (
            chronic_state == "overreaching"
            and hours_since_peak < 24
        ):
            rec = "active_recovery"
        else:
            rec = "go_lighter"
        reason = _build_reason(peak_label, hours_since_peak, acute_trimp_val, chronic_state)
        return RecoverySignal(
            recommendation=rec,
            reason=reason,
            peak_effort=peak_label,
            recovery_days_suggested=peak_recovery_days,
            acute_trimp=acute_trimp_val,
            hours_since_peak=hours_since_peak,
            chronic_state=chronic_state,
            sessions_in_window=len(sessions),
        )

    # 2. A recent Moderate session that ALSO coincides with elevated chronic
    #    load → a gentle "ease off" nudge (but only when recent + corroborated;
    #    moderate cardio alone is normal training).
    if (
        peak.effort_weight >= _MODERATE_WEIGHT_FLOOR
        and hours_since_peak < 24
        and chronic_elevated
    ):
        reason = _build_reason(peak_label, hours_since_peak, acute_trimp_val, chronic_state)
        return RecoverySignal(
            recommendation="go_lighter",
            reason=reason,
            peak_effort=peak_label,
            recovery_days_suggested=peak_recovery_days,
            acute_trimp=acute_trimp_val,
            hours_since_peak=hours_since_peak,
            chronic_state=chronic_state,
            sessions_in_window=len(sessions),
        )

    # 3. Otherwise: recent cardio exists but it's light/moderate and load is
    #    sustainable → train as planned. We still return the signal (not None)
    #    so the coach can affirm "you got cardio in, you're good to train".
    reason = _build_reason(peak_label, hours_since_peak, acute_trimp_val, chronic_state)
    return RecoverySignal(
        recommendation="as_planned",
        reason=reason,
        peak_effort=peak_label,
        recovery_days_suggested=peak_recovery_days,
        acute_trimp=acute_trimp_val,
        hours_since_peak=hours_since_peak,
        chronic_state=chronic_state,
        sessions_in_window=len(sessions),
    )


def _build_reason(
    peak_label: Optional[str],
    hours_since_peak: float,
    acute_trimp: Optional[float],
    chronic_state: Optional[str],
) -> str:
    """Short, deterministic justification string (no LLM)."""
    when_str = (
        "just now"
        if hours_since_peak < 1
        else f"{round(hours_since_peak)}h ago"
    )
    effort_str = (peak_label or "recent").capitalize()
    parts = [f"{effort_str} cardio {when_str}"]
    if acute_trimp is not None and acute_trimp >= _ACUTE_TRIMP_HIGH:
        parts.append(f"acute load {round(acute_trimp)}")
    if chronic_state in ("loading", "overreaching"):
        parts.append(f"chronic load {chronic_state}")
    return ", ".join(parts)


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------


def compute_recovery_signal(
    db,
    user_id: str,
    now: Optional[datetime] = None,
) -> Optional[RecoverySignal]:
    """Compute the acute recovery signal for ``user_id``.

    Reads recent imported cardio (``workouts``) + native cardio
    (``cardio_logs``) inside the last ``_ACUTE_WINDOW_HOURS`` and the chronic
    ACWR state, then applies the deterministic decision table.

    Returns
    -------
    RecoverySignal | None
        ``None`` means "no recent cardio / nothing to say" — callers MUST
        treat that identically to the pre-existing behaviour (no recovery
        block, plan as-is). This function never raises; any internal failure
        also yields ``None`` (fail-open).

    Performance
    -----------
    Two indexed Supabase reads (both on user_id + a timestamp gte) plus the
    chronic state read. Synchronous Supabase client; the async caller should
    run this in a thread (``asyncio.to_thread``) alongside its other snapshot
    reads — it is pure arithmetic after the rows land.
    """
    try:
        now = now or datetime.now(timezone.utc)
        since = now - timedelta(hours=_ACUTE_WINDOW_HOURS)

        imported = _load_imported_cardio(db, user_id, since)
        native = _load_native_cardio(db, user_id, since)
        sessions = imported + native

        # Chronic corroboration — best-effort, None on calibration / failure.
        chronic_state: Optional[str] = None
        try:
            from services.training_load_service import current_state

            st = current_state(db, user_id)
            if st and st.state and st.state != "calibration":
                chronic_state = st.state
        except Exception as e:  # pragma: no cover - defensive
            logger.debug(f"[Recovery] chronic state lookup skipped: {e}")

        return _decide(sessions, chronic_state, now)
    except Exception as e:  # pragma: no cover - fail open, never raise
        logger.warning(f"[Recovery] compute_recovery_signal failed (fail-open): {e}")
        return None
