"""Self-tracked recent-habits/mood/measurements context for the AI Coach.

PURPOSE
-------
The user logs habits, mood, and body measurements (via the wellness/events
facade — see `backend/api/v1/wellness/events.py`), but on a READ the coach is
currently blind to them: it can *write* "Meditation — done" yet can't *see*
the user's 6-day meditation streak when answering a question. This module
assembles a compact, prompt-injectable block of the user's RECENT self-logged
signals so the coach can SEE and CITE them.

It runs on the per-message coach hot path, so it must be FAST and FAIL-SOFT:
a few light Supabase reads, executed off the event loop via
``asyncio.to_thread`` (the Supabase client is synchronous).

CONTRACT
--------
``build_self_tracking_context(user_id, user_tz="UTC") -> str``

- Returns a short multi-line string when there is data, e.g.::

      SELF-TRACKED (user-logged, recent):
      - Habits: Meditation — 6-day streak, done today; Vitamins — 3/7 this week, not yet today
      - Mood: today: good; past 7d: 4 good / 2 ok / 1 low
      - Measurements: waist 81 cm (down 2 vs ~30d ago); body fat 18.0% (down 1.0)

- Returns "" (empty string) when there is NO data in ANY category. The empty
  string is the explicit no-data signal — the coach must NEVER invent numbers,
  so "no data" is communicated by the ABSENCE of the block, not by a fabricated
  placeholder.

- NEVER raises. Any error (bad data, missing table, query failure, malformed
  rows) is caught and degrades to "" (or to dropping just the affected
  sub-line). It must never block or crash the coach turn.

GROUNDING
---------
Tables/columns are taken verbatim from the write paths and read endpoints — NOT
guessed:
- ``habits`` (id, name, is_active, habit_type) / ``habit_streaks`` (habit_id,
  current_streak) / ``habit_logs`` (habit_id, log_date, completed) —
  `api/v1/wellness/events.py::_write_habit`, `api/v1/habits.py::get_today_habits`,
  `api/v1/habits_endpoints.py::get_habit_streak`.
- ``mood_log`` (mood, occurred_at, deleted_at) — `api/v1/wellness/mood.py`.
- ``body_measurements`` (per-type ``*_cm`` columns, ``body_fat_percent`` %,
  ``weight_kg`` kg, ``measured_at``) — `api/v1/wellness/events.py::_write_measurement`,
  `api/v1/metrics.py::METRIC_TYPE_TO_COLUMN`.
"""
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

from core.logger import get_logger

logger = get_logger(__name__)

# Cap how much we read + how long each rendered line gets, so this stays a
# cheap hot-path call and the injected block stays compact.
_MAX_HABITS = 3            # top N active habits to surface
_HABIT_FETCH_LIMIT = 40    # active-habit rows scanned before ranking
_MOOD_LOOKBACK_DAYS = 7
_MEASUREMENT_LOOKBACK_DAYS = 60   # window to find a "~30d ago" comparison point
_MEASUREMENT_DELTA_TARGET_DAYS = 30
_MAX_MEASUREMENT_TYPES = 4
_LINE_MAX_CHARS = 240      # hard cap per rendered sub-line

# Tracked body_measurements columns → (human label, unit, rounding decimals).
# Mirrors api/v1/metrics.py::METRIC_TYPE_TO_COLUMN + _write_measurement; circumferences
# are centimetres, body fat is a percentage, weight is kilograms (the column the
# app stores — body weight is always persisted in kg per the write paths).
_MEASUREMENT_COLUMNS: List[tuple] = [
    ("weight_kg", "weight", "kg", 1),
    ("body_fat_percent", "body fat", "%", 1),
    ("waist_cm", "waist", "cm", 0),
    ("hip_cm", "hips", "cm", 0),
    ("chest_cm", "chest", "cm", 0),
    ("shoulder_cm", "shoulders", "cm", 0),
    ("neck_cm", "neck", "cm", 0),
    ("bicep_right_cm", "right arm", "cm", 0),
    ("bicep_left_cm", "left arm", "cm", 0),
    ("thigh_right_cm", "right thigh", "cm", 0),
    ("thigh_left_cm", "left thigh", "cm", 0),
    ("forearm_right_cm", "right forearm", "cm", 0),
    ("forearm_left_cm", "left forearm", "cm", 0),
    ("calf_right_cm", "right calf", "cm", 0),
    ("calf_left_cm", "left calf", "cm", 0),
]

# Mood values ranked best→worst so a 7-day rollup reads in a sensible order.
# Superset of ALLOWED_MOODS (api/v1/wellness/mood.py); any unranked value still
# renders, just sorted to the end alphabetically.
_MOOD_ORDER = [
    "great", "energized", "happy", "good", "focused", "ok",
    "tired", "low", "anxious", "stressed", "sad", "bad",
]


# ---------------------------------------------------------------------------
# Public entrypoint
# ---------------------------------------------------------------------------

async def build_self_tracking_context(user_id: str, user_tz: Optional[str] = None) -> str:
    """Build the SELF-TRACKED prompt block. Returns "" when no data / on error.

    See the module docstring for the exact contract. Fail-soft: every category
    is fetched independently and any failure drops only that sub-line (a total
    failure yields "").
    """
    try:
        tz = user_tz or "UTC"

        # Resolve the Supabase client ON the event loop. get_supabase() lazily
        # constructs the SupabaseManager (which builds an asyncio primitive),
        # and that lazy init must NOT happen inside a worker thread — there's no
        # running loop there. In the live coach process the manager is already
        # warm; resolving it here is just a cheap accessor in the warm path and
        # the safe path in a cold one. If even this fails, degrade to "".
        try:
            from core.supabase_client import get_supabase
            client = get_supabase().client
        except Exception as e:
            logger.warning(f"[self_tracking] supabase client unavailable for {user_id}: {e}")
            return ""

        # Run the (synchronous) Supabase reads off the event loop so the coach
        # hot path is never blocked. Each helper is independently fail-soft and
        # returns "" on any problem.
        lines: List[str] = []
        for builder in (_build_habits_line, _build_mood_line, _build_measurements_line):
            try:
                line = await _to_thread_safe(builder, client, user_id, tz)
            except Exception as e:  # pragma: no cover — builders already catch
                logger.warning(f"[self_tracking] {builder.__name__} failed for {user_id}: {e}")
                line = ""
            if line:
                lines.append(line)

        if not lines:
            return ""

        return "SELF-TRACKED (user-logged, recent):\n" + "\n".join(lines)
    except Exception as e:
        # Absolute backstop — the coach turn must never break on this block.
        logger.warning(f"[self_tracking] build failed for {user_id}: {e}")
        return ""


async def _to_thread_safe(fn, *args) -> str:
    """Run a sync builder in a worker thread; degrade to "" on any failure."""
    import asyncio
    try:
        return await asyncio.to_thread(fn, *args)
    except Exception as e:
        logger.warning(f"[self_tracking] thread for {getattr(fn, '__name__', fn)} failed: {e}")
        return ""


def _safe_user_today(tz: str) -> str:
    """Today's date ('YYYY-MM-DD') in the user's tz, falling back to UTC."""
    try:
        from core.timezone_utils import get_user_today
        return get_user_today(tz)
    except Exception:
        return datetime.now(timezone.utc).strftime("%Y-%m-%d")


# ---------------------------------------------------------------------------
# Category builders (SYNCHRONOUS — run inside asyncio.to_thread)
# ---------------------------------------------------------------------------

def _build_habits_line(client, user_id: str, tz: str) -> str:
    """Top active habits with current streak + done-today / week-progress.

    e.g. ``Habits: Meditation — 6-day streak, done today; Vitamins — 3/7 this
    week, not yet today``. Returns "" if the user has no active habits.
    """
    try:
        today_str = _safe_user_today(tz)
        today_date = datetime.strptime(today_str, "%Y-%m-%d").date()
        week_ago_str = (today_date - timedelta(days=6)).isoformat()

        habits_res = (
            client.table("habits")
            .select("id, name, is_active, habit_type")
            .eq("user_id", user_id)
            .eq("is_active", True)
            .limit(_HABIT_FETCH_LIMIT)
            .execute()
        )
        habits = habits_res.data or []
        if not habits:
            return ""

        habit_ids = [h["id"] for h in habits if h.get("id")]
        if not habit_ids:
            return ""

        # Current streaks (precomputed table — same source get_habit_streak reads).
        streak_by_habit: Dict[str, int] = {}
        try:
            streak_res = (
                client.table("habit_streaks")
                .select("habit_id, current_streak")
                .eq("user_id", user_id)
                .in_("habit_id", habit_ids)
                .execute()
            )
            for s in (streak_res.data or []):
                hid = s.get("habit_id")
                if hid is not None:
                    streak_by_habit[str(hid)] = int(s.get("current_streak") or 0)
        except Exception as e:
            logger.debug(f"[self_tracking] habit_streaks read skipped for {user_id}: {e}")

        # Last-7-days logs (done-today + this-week count). Same query shape as
        # get_today_habits: filter log_date within [week_ago, today].
        done_today: Dict[str, bool] = {}
        week_completed: Dict[str, int] = {}
        try:
            logs_res = (
                client.table("habit_logs")
                .select("habit_id, log_date, completed")
                .eq("user_id", user_id)
                .in_("habit_id", habit_ids)
                .gte("log_date", week_ago_str)
                .lte("log_date", today_str)
                .execute()
            )
            for log in (logs_res.data or []):
                hid = str(log.get("habit_id"))
                if not log.get("completed"):
                    continue
                week_completed[hid] = week_completed.get(hid, 0) + 1
                if str(log.get("log_date")) == today_str:
                    done_today[hid] = True
        except Exception as e:
            logger.debug(f"[self_tracking] habit_logs read skipped for {user_id}: {e}")

        # Rank: highest current streak first, then most completions this week.
        def _rank(h: Dict[str, Any]):
            hid = str(h.get("id"))
            return (streak_by_habit.get(hid, 0), week_completed.get(hid, 0))

        ranked = sorted(habits, key=_rank, reverse=True)

        parts: List[str] = []
        for h in ranked[:_MAX_HABITS]:
            hid = str(h.get("id"))
            name = (h.get("name") or "Habit").strip()
            streak = streak_by_habit.get(hid, 0)
            wk = week_completed.get(hid, 0)
            is_done = done_today.get(hid, False)

            if streak >= 1:
                progress = f"{streak}-day streak"
            elif wk > 0:
                progress = f"{wk}/7 this week"
            else:
                progress = "tracking"

            status = "done today" if is_done else "not yet today"
            parts.append(f"{name} — {progress}, {status}")

        if not parts:
            return ""
        return _cap_line("- Habits: " + "; ".join(parts))
    except Exception as e:
        logger.warning(f"[self_tracking] habits line failed for {user_id}: {e}")
        return ""


def _build_mood_line(client, user_id: str, tz: str) -> str:
    """Most recent mood + a 7-day rollup.

    e.g. ``Mood: today: good; past 7d: 4 good / 2 ok / 1 low``. Returns "" if
    no mood was logged in the lookback window.
    """
    try:
        today_str = _safe_user_today(tz)
        # 7-day window in UTC (mood_log.occurred_at is a UTC timestamp). A small
        # cushion past midnight is fine for a rollup count.
        since = (datetime.now(timezone.utc) - timedelta(days=_MOOD_LOOKBACK_DAYS)).isoformat()

        res = (
            client.table("mood_log")
            .select("mood, occurred_at")
            .eq("user_id", user_id)
            .gte("occurred_at", since)
            .is_("deleted_at", "null")
            .order("occurred_at", desc=True)
            .execute()
        )
        rows = res.data or []
        if not rows:
            return ""

        # Most recent entry (rows are already desc by occurred_at).
        latest = rows[0]
        latest_mood = (latest.get("mood") or "").strip().lower()
        latest_at = str(latest.get("occurred_at") or "")
        is_today = latest_at[:10] == today_str

        # 7-day rollup counts.
        counts: Dict[str, int] = {}
        for r in rows:
            m = (r.get("mood") or "").strip().lower()
            if m:
                counts[m] = counts.get(m, 0) + 1

        def _mood_sort_key(item):
            mood = item[0]
            idx = _MOOD_ORDER.index(mood) if mood in _MOOD_ORDER else len(_MOOD_ORDER)
            return (idx, mood)

        rollup = " / ".join(
            f"{n} {mood}" for mood, n in sorted(counts.items(), key=_mood_sort_key)
        )

        segments: List[str] = []
        if latest_mood:
            label = "today" if is_today else "latest"
            segments.append(f"{label}: {latest_mood}")
        if rollup:
            segments.append(f"past {_MOOD_LOOKBACK_DAYS}d: {rollup}")
        if not segments:
            return ""
        return _cap_line("- Mood: " + "; ".join(segments))
    except Exception as e:
        logger.warning(f"[self_tracking] mood line failed for {user_id}: {e}")
        return ""


def _build_measurements_line(client, user_id: str, tz: str) -> str:
    """Latest value per tracked measurement type + delta vs ~30 days ago.

    e.g. ``Measurements: waist 81 cm (down 2 vs ~30d ago); body fat 18.0% (down
    1.0)``. Returns "" if the user has logged no measurements in the window.
    """
    try:
        now = datetime.now(timezone.utc)
        since = (now - timedelta(days=_MEASUREMENT_LOOKBACK_DAYS)).isoformat()
        target_old = now - timedelta(days=_MEASUREMENT_DELTA_TARGET_DAYS)

        # Pull the recent measurement rows once; each row may carry several
        # columns (most logs touch only one), so we scan column-by-column.
        # NOTE: body_measurements has NO `deleted_at` column (unlike mood_log),
        # so we do NOT filter on it here — doing so would 42703-error the query.
        select_cols = "measured_at," + ",".join(c[0] for c in _MEASUREMENT_COLUMNS)
        res = (
            client.table("body_measurements")
            .select(select_cols)
            .eq("user_id", user_id)
            .gte("measured_at", since)
            .order("measured_at", desc=True)
            .execute()
        )
        rows = res.data or []
        if not rows:
            return ""

        parts: List[str] = []
        for column, label, unit, decimals in _MEASUREMENT_COLUMNS:
            # Rows with a non-null value for THIS column, newest first.
            series = [
                r for r in rows
                if r.get(column) is not None and _parse_at(r.get("measured_at")) is not None
            ]
            if not series:
                continue

            latest_row = series[0]
            try:
                latest_val = float(latest_row[column])
            except (TypeError, ValueError):
                continue
            latest_at = _parse_at(latest_row.get("measured_at"))

            value_str = _fmt_value(latest_val, decimals)
            unit_str = "" if unit == "%" else f" {unit}"
            suffix = "%" if unit == "%" else ""
            piece = f"{label} {value_str}{suffix}{unit_str}".rstrip()

            # Delta vs the reading closest to ~30 days before the latest (only
            # if a genuine prior reading exists — never invent a baseline).
            baseline = _closest_baseline(series[1:], latest_at, target_old)
            if baseline is not None:
                try:
                    base_val = float(baseline[column])
                    delta = latest_val - base_val
                    if abs(delta) >= (0.5 if decimals == 0 else 0.1):
                        direction = "down" if delta < 0 else "up"
                        delta_str = _fmt_value(abs(delta), decimals)
                        piece += f" ({direction} {delta_str} vs ~30d ago)"
                except (TypeError, ValueError):
                    pass

            parts.append(piece)
            if len(parts) >= _MAX_MEASUREMENT_TYPES:
                break

        if not parts:
            return ""
        return _cap_line("- Measurements: " + "; ".join(parts))
    except Exception as e:
        logger.warning(f"[self_tracking] measurements line failed for {user_id}: {e}")
        return ""


# ---------------------------------------------------------------------------
# Small helpers
# ---------------------------------------------------------------------------

def _parse_at(value: Any) -> Optional[datetime]:
    """Parse a measured_at timestamp string into an aware UTC datetime."""
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(str(value).replace("Z", "+00:00"))
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt
    except Exception:
        return None


def _closest_baseline(
    older_rows: List[Dict[str, Any]],
    latest_at: Optional[datetime],
    target_old: datetime,
) -> Optional[Dict[str, Any]]:
    """Pick the prior reading whose timestamp is closest to ``target_old``.

    Only considers readings strictly OLDER than the latest one so we always
    compute a real change between two genuine logs (never a synthetic point).
    """
    candidates = []
    for r in older_rows:
        at = _parse_at(r.get("measured_at"))
        if at is None:
            continue
        if latest_at is not None and at >= latest_at:
            continue
        candidates.append((abs((at - target_old).total_seconds()), r))
    if not candidates:
        return None
    candidates.sort(key=lambda c: c[0])
    return candidates[0][1]


def _fmt_value(value: float, decimals: int) -> str:
    """Format a numeric value to the configured precision, trimming '.0'."""
    if decimals <= 0:
        return str(int(round(value)))
    s = f"{value:.{decimals}f}"
    return s


def _cap_line(line: str) -> str:
    """Truncate an over-long rendered line so the block stays compact."""
    if len(line) <= _LINE_MAX_CHARS:
        return line
    return line[: _LINE_MAX_CHARS - 1].rstrip() + "…"
