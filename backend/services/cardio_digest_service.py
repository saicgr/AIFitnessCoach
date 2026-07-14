"""Weekly cardio digest service.

Pure rollup + copy generator for the weekly cardio digest (push +
the cardio section of the Monday weekly summary). Owns NO transport —
the cron jobs call into this module, then hand the resulting payload
to the existing mail and push layers.

Three public surfaces
---------------------
* `compute_weekly_cardio_summary` — the rollup (None on a zero-cardio week).
* `format_digest_copy` — push title/body (+ a standalone subject/body kept for
  callers that still want the whole-document form).
* `render_digest_section_html` — the EMBEDDABLE `<tr>`-rooted block spliced into
  the Monday weekly summary. This is what ships to inboxes now: one Monday
  recap that absorbs the cardio digest instead of two recaps 24h apart.

Design notes
------------
* All time math is done in the user's IANA timezone (per
  `feedback_user_local_time_only`). The window is the user-local last
  7 days, i.e. (today - 7d, today] inclusive of today.
* If the user logged zero cardio in the window, returns None — we
  do NOT shame (per `feedback_schedule_aware_notifications`).
* "Run" stats (longest_run, fastest_mile) only consider running-like
  activity types (run / trail_run / treadmill). All-cardio stats
  (km_this_week, total_hours, session_count) span every activity type
  except yoga/pilates which aren't distance/effort cardio.
* Copy variants pool follows `feedback_dynamic_copy_not_robotic`
  (>=4 per pattern per branch). Selection is salted by week-start so
  the same user sees a stable copy variant if the cron retries.
"""

from __future__ import annotations

import hashlib
import logging
import random
from dataclasses import dataclass, asdict
from datetime import date, datetime, timedelta
from typing import Any, Dict, List, Optional
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError

logger = logging.getLogger(__name__)

# Activity types that count as "running" — used for the longest-run
# and fastest-mile callouts. Treadmill is included because pace is
# captured the same way; trail_run obviously is too.
RUN_ACTIVITY_TYPES = {"run", "trail_run", "treadmill"}

# Activity types that count toward total cardio km / hours / sessions.
# Yoga + pilates are flexibility, not cardio distance work — exclude.
CARDIO_ACTIVITY_TYPES = {
    "run", "trail_run", "treadmill", "walk", "hike",
    "cycle", "indoor_cycle", "mountain_bike", "gravel_bike",
    "row", "erg",
    "swim", "open_water_swim",
    "elliptical", "stair", "stepmill",
    "ski_erg", "skate_ski", "nordic_ski", "downhill_ski", "snowboard",
    "hiit", "boxing", "kickboxing",
    "other",
}

# Distance threshold below which a "run" doesn't deserve a "longest"
# call-out (avoids "longest run: 0.2 km" warmups). Anything above 1 km
# is fair game.
MIN_RUN_DISTANCE_M_FOR_HIGHLIGHT = 1000.0

# A user with fewer than 14 days of cardio history gets the
# baseline-framing copy (no % delta vs last week).
NEW_USER_HISTORY_DAYS = 14


@dataclass
class WeeklyCardioSummary:
    """Pure data — rendered into copy by `format_digest_copy`."""

    km_this_week: float
    km_last_week: float
    delta_pct: Optional[float]            # None when last-week km is 0
    longest_run_km: Optional[float]
    longest_run_date: Optional[date]
    fastest_mile_sec: Optional[float]
    fastest_mile_date: Optional[date]
    total_hours: float
    session_count: int
    is_first_week: bool                   # < 14 days of cardio history

    def to_dict(self) -> Dict[str, Any]:
        d = asdict(self)
        for k in ("longest_run_date", "fastest_mile_date"):
            v = d.get(k)
            if isinstance(v, date):
                d[k] = v.isoformat()
        return d


# ────────────────────────────────────────────────────────────────────
# Timezone helpers
# ────────────────────────────────────────────────────────────────────

def _safe_zone(tz: Optional[str]) -> ZoneInfo:
    try:
        return ZoneInfo(tz or "UTC")
    except (ZoneInfoNotFoundError, KeyError, ValueError):
        return ZoneInfo("UTC")


def _local_week_bounds(tz: str) -> tuple[datetime, datetime]:
    """Return (start_utc, end_utc) for the last 7 user-local days."""
    zone = _safe_zone(tz)
    local_now = datetime.now(zone)
    end_local = local_now
    start_local = end_local - timedelta(days=7)
    return (
        start_local.astimezone(ZoneInfo("UTC")),
        end_local.astimezone(ZoneInfo("UTC")),
    )


# ────────────────────────────────────────────────────────────────────
# Rollup logic
# ────────────────────────────────────────────────────────────────────

def _parse_dt(value: Any) -> Optional[datetime]:
    if value is None:
        return None
    if isinstance(value, datetime):
        return value
    try:
        # Supabase returns isoformat strings; handle trailing Z too.
        s = str(value).replace("Z", "+00:00")
        return datetime.fromisoformat(s)
    except (ValueError, TypeError):
        return None


def _sum_distance_km(rows: List[Dict[str, Any]]) -> float:
    total_m = sum(float(r.get("distance_m") or 0) for r in rows)
    return round(total_m / 1000.0, 2)


def _sum_hours(rows: List[Dict[str, Any]]) -> float:
    total_s = sum(int(r.get("duration_seconds") or 0) for r in rows)
    return round(total_s / 3600.0, 2)


def _find_longest_run(rows: List[Dict[str, Any]]) -> tuple[Optional[float], Optional[date]]:
    runs = [
        r for r in rows
        if (r.get("activity_type") in RUN_ACTIVITY_TYPES)
        and float(r.get("distance_m") or 0) >= MIN_RUN_DISTANCE_M_FOR_HIGHLIGHT
    ]
    if not runs:
        return None, None
    best = max(runs, key=lambda r: float(r.get("distance_m") or 0))
    dt = _parse_dt(best.get("performed_at"))
    return round(float(best["distance_m"]) / 1000.0, 2), (dt.date() if dt else None)


def _find_fastest_mile_sec(rows: List[Dict[str, Any]]) -> tuple[Optional[float], Optional[date]]:
    """Convert avg_pace_seconds_per_km → seconds/mile for runs.

    1 mile = 1.609344 km. We use the avg pace as a proxy for "fastest
    mile" (legit when split-level data isn't logged). Only runs with
    distance >= 1 mile (1609.344 m) count — a 200m sprint pace would
    misrepresent a real mile time.
    """
    candidates = [
        r for r in rows
        if (r.get("activity_type") in RUN_ACTIVITY_TYPES)
        and float(r.get("distance_m") or 0) >= 1609.344
        and r.get("avg_pace_seconds_per_km")
    ]
    if not candidates:
        return None, None
    best = min(candidates, key=lambda r: float(r["avg_pace_seconds_per_km"]))
    pace_per_km = float(best["avg_pace_seconds_per_km"])
    pace_per_mile = pace_per_km * 1.609344
    dt = _parse_dt(best.get("performed_at"))
    return round(pace_per_mile, 1), (dt.date() if dt else None)


def _fetch_cardio_window(
    db: Any, user_id: str, start_utc: datetime, end_utc: datetime
) -> List[Dict[str, Any]]:
    """Pull cardio_logs in [start, end]. cardio_sessions is the legacy
    in-app cardio session table — if present it's merged in. Missing
    table is silently skipped."""
    rows: List[Dict[str, Any]] = []
    try:
        resp = db.client.table("cardio_logs").select(
            "performed_at, activity_type, duration_seconds, distance_m, "
            "avg_pace_seconds_per_km"
        ).eq("user_id", user_id).gte(
            "performed_at", start_utc.isoformat()
        ).lte("performed_at", end_utc.isoformat()).execute()
        rows.extend(resp.data or [])
    except Exception as e:
        logger.warning("[CardioDigest] cardio_logs fetch failed for %s: %s", user_id, e)

    try:
        resp2 = db.client.table("cardio_sessions").select(
            "created_at, activity_type, duration_minutes, distance_km, "
            "avg_pace_min_per_km"
        ).eq("user_id", user_id).gte(
            "created_at", start_utc.isoformat()
        ).lte("created_at", end_utc.isoformat()).execute()
        for r in (resp2.data or []):
            # Normalize to cardio_logs shape. cardio_sessions stores minutes/km;
            # convert to the seconds/meters units the digest expects.
            dur_min = r.get("duration_minutes")
            dist_km = r.get("distance_km")
            pace_min = r.get("avg_pace_min_per_km")
            rows.append({
                "performed_at": r.get("created_at"),
                "activity_type": r.get("activity_type"),
                "duration_seconds": dur_min * 60 if dur_min is not None else None,
                "distance_m": dist_km * 1000 if dist_km is not None else None,
                "avg_pace_seconds_per_km": pace_min * 60 if pace_min is not None else None,
            })
    except Exception as e:
        # cardio_sessions may not exist in all envs — debug-level only.
        logger.debug("[CardioDigest] cardio_sessions fetch skipped for %s: %s", user_id, e)

    # Only count cardio types we summarize.
    return [r for r in rows if r.get("activity_type") in CARDIO_ACTIVITY_TYPES]


def _has_history_older_than(
    db: Any, user_id: str, cutoff_utc: datetime
) -> bool:
    """True iff the user has any cardio_log dated before `cutoff_utc`."""
    try:
        resp = db.client.table("cardio_logs").select("id").eq(
            "user_id", user_id
        ).lt("performed_at", cutoff_utc.isoformat()).limit(1).execute()
        return bool(resp.data)
    except Exception:
        return False


def compute_weekly_cardio_summary(
    db: Any, user_id: str, tz: str
) -> Optional[WeeklyCardioSummary]:
    """Roll up the user's last 7 user-local days of cardio.

    Returns None when the user logged 0 cardio sessions in the window
    (we skip — never shame an empty week).
    """
    start_utc, end_utc = _local_week_bounds(tz)
    prev_start_utc = start_utc - timedelta(days=7)

    this_week = _fetch_cardio_window(db, user_id, start_utc, end_utc)
    if not this_week:
        return None

    last_week = _fetch_cardio_window(db, user_id, prev_start_utc, start_utc)

    km_this = _sum_distance_km(this_week)
    km_last = _sum_distance_km(last_week)
    if km_last > 0:
        delta_pct = round(((km_this - km_last) / km_last) * 100.0, 1)
    else:
        delta_pct = None

    longest_km, longest_date = _find_longest_run(this_week)
    mile_sec, mile_date = _find_fastest_mile_sec(this_week)
    total_hours = _sum_hours(this_week)

    # First-week framing: user joined < 14 days ago (no cardio_logs
    # before the cutoff). Use baseline copy + suppress delta.
    cutoff = end_utc - timedelta(days=NEW_USER_HISTORY_DAYS)
    is_first_week = not _has_history_older_than(db, user_id, cutoff)
    if is_first_week:
        delta_pct = None

    return WeeklyCardioSummary(
        km_this_week=km_this,
        km_last_week=km_last,
        delta_pct=delta_pct,
        longest_run_km=longest_km,
        longest_run_date=longest_date,
        fastest_mile_sec=mile_sec,
        fastest_mile_date=mile_date,
        total_hours=total_hours,
        session_count=len(this_week),
        is_first_week=is_first_week,
    )


# ────────────────────────────────────────────────────────────────────
# Copy generation
# ────────────────────────────────────────────────────────────────────

# Variant pools — at least 4 per branch per feedback_dynamic_copy_not_robotic.
_PUSH_TITLE_POSITIVE = [
    "{name}, your week stacked up",
    "{name}, you ran the week",
    "Solid week, {name}",
    "{name}, that was a strong 7 days",
    "Week wrapped, {name}",
]

_PUSH_TITLE_NEUTRAL = [
    "{name}, here's your cardio week",
    "Your week in cardio, {name}",
    "{name}, the recap is in",
    "Weekly cardio for {name}",
    "{name}, your 7-day cardio snapshot",
]

_PUSH_TITLE_NEGATIVE = [
    "{name}, the week was lighter",
    "{name}, every kilometer counts",
    "Quieter week, {name}",
    "{name}, here's where we landed",
    "Your week, {name}",
]

_PUSH_TITLE_BASELINE = [
    "{name}, your first cardio week",
    "Welcome, {name} — week one is in",
    "{name}, baseline locked in",
    "First week down, {name}",
    "Here's your starting line, {name}",
]

_EMAIL_SUBJECT_POSITIVE = [
    "{name}, +{delta}% on cardio this week",
    "{name}, {km} km logged — up vs last week",
    "Strong week, {name} — {km} km",
    "{name}, your cardio leveled up ({km} km)",
]

_EMAIL_SUBJECT_NEUTRAL = [
    "{name}, your cardio week ({km} km)",
    "{km} km this week, {name}",
    "Your weekly cardio digest, {name}",
    "{name} — {km} km in 7 days",
]

_EMAIL_SUBJECT_NEGATIVE = [
    "{name}, a lighter cardio week ({km} km)",
    "Quieter week, {name} — {km} km",
    "{name}, recap inside ({km} km)",
    "Your week in cardio, {name} — {km} km",
]

_EMAIL_SUBJECT_BASELINE = [
    "{name}, your first cardio week ({km} km)",
    "Welcome to week one, {name} — {km} km",
    "Baseline week, {name} — {km} km",
    "{name}, here's your starting cardio week",
]


def _first_name_for_copy(first_name: Optional[str], email: Optional[str] = None) -> str:
    """Per `feedback_name_personalization_required`: first-name only, with
    email-prefix fallback. NEVER 'there' — that reads as spam."""
    name = (first_name or "").strip().split()[0] if first_name else ""
    if name:
        return name
    if email and "@" in email:
        prefix = email.split("@", 1)[0]
        clean = "".join(c for c in prefix if c.isalpha())
        if clean:
            return clean[:1].upper() + clean[1:].lower()
    return "Athlete"


def _stable_variant(pool: List[str], salt: str) -> str:
    """Deterministic per-salt variant pick. Lets cron retries pick the
    same copy and lets tests assert variant coverage by varying salt."""
    h = hashlib.md5(salt.encode("utf-8")).digest()
    idx = h[0] % len(pool)
    return pool[idx]


def _fmt_pace_sec(sec: float) -> str:
    m, s = divmod(int(round(sec)), 60)
    return f"{m}:{s:02d}/mi"


def _fmt_date(d: Optional[date]) -> str:
    if not d:
        return ""
    return d.strftime("%a")  # Mon / Tue / Wed …


def _classify_tone(summary: WeeklyCardioSummary) -> str:
    """Returns one of: 'baseline' | 'positive' | 'neutral' | 'negative'."""
    if summary.is_first_week:
        return "baseline"
    if summary.delta_pct is None:
        return "neutral"
    if summary.delta_pct >= 3.0:
        return "positive"
    if summary.delta_pct <= -3.0:
        return "negative"
    return "neutral"


def format_digest_copy(
    summary: WeeklyCardioSummary,
    user_first_name: Optional[str],
    user_email: Optional[str] = None,
    variant_salt: Optional[str] = None,
) -> Dict[str, str]:
    """Render push title/body + email subject/html for the digest.

    `variant_salt` lets the caller stabilize variant selection
    (recommended: f"{user_id}:{week_start_iso}"). Without it the
    variant rotates per call which is fine for tests.
    """
    name = _first_name_for_copy(user_first_name, user_email)
    tone = _classify_tone(summary)
    salt = variant_salt or f"{name}:{datetime.utcnow().isoformat()}:{random.random()}"

    # Title pool selection.
    title_pool = {
        "positive": _PUSH_TITLE_POSITIVE,
        "neutral": _PUSH_TITLE_NEUTRAL,
        "negative": _PUSH_TITLE_NEGATIVE,
        "baseline": _PUSH_TITLE_BASELINE,
    }[tone]
    subject_pool = {
        "positive": _EMAIL_SUBJECT_POSITIVE,
        "neutral": _EMAIL_SUBJECT_NEUTRAL,
        "negative": _EMAIL_SUBJECT_NEGATIVE,
        "baseline": _EMAIL_SUBJECT_BASELINE,
    }[tone]

    push_title = _stable_variant(title_pool, salt + ":title").format(name=name)

    # Push body — concise (<=120 chars), data-substituted.
    km = summary.km_this_week
    parts: List[str] = [f"{km:g} km logged this week"]
    if summary.delta_pct is not None:
        sign = "+" if summary.delta_pct >= 0 else ""
        parts[-1] += f" ({sign}{summary.delta_pct:g}% vs last)"
    if summary.longest_run_km:
        day_str = _fmt_date(summary.longest_run_date)
        suffix = f" {day_str}" if day_str else ""
        parts.append(f"Longest: {summary.longest_run_km:g} km{suffix}.")
    push_body = " · ".join(parts)
    if len(push_body) > 120:
        # Hard trim with ellipsis so we never exceed APNs alert preview.
        push_body = push_body[:117].rstrip() + "…"

    # Email subject.
    subject_template = _stable_variant(subject_pool, salt + ":subject")
    subject = subject_template.format(
        name=name,
        km=f"{km:g}",
        delta=f"{abs(summary.delta_pct):g}" if summary.delta_pct is not None else "",
    )

    # Email body HTML — simple template, one hero stat + 3 sub-stats.
    email_body_html = _render_email_html(name, summary, tone)

    return {
        "push_title": push_title,
        "push_body": push_body,
        "email_subject": subject,
        "email_body_html": email_body_html,
    }


def _render_email_html(name: str, s: WeeklyCardioSummary, tone: str) -> str:
    delta_block = ""
    if s.delta_pct is not None:
        sign = "+" if s.delta_pct >= 0 else ""
        color = "#10B981" if s.delta_pct >= 0 else "#F97316"
        delta_block = (
            f'<div style="font-size:14px;color:{color};font-weight:600">'
            f'{sign}{s.delta_pct:g}% vs last week'
            f"</div>"
        )
    elif s.is_first_week:
        delta_block = (
            '<div style="font-size:14px;color:#6B7280">'
            "First week — this is your baseline."
            "</div>"
        )

    longest_block = ""
    if s.longest_run_km:
        day_str = _fmt_date(s.longest_run_date)
        longest_block = (
            f'<div style="padding:12px;background:#F9FAFB;border-radius:8px;'
            f'margin-bottom:8px"><div style="font-size:12px;color:#6B7280">'
            f"Longest run</div>"
            f'<div style="font-size:18px;font-weight:700">'
            f"{s.longest_run_km:g} km"
            + (f" · {day_str}" if day_str else "")
            + "</div></div>"
        )

    fastest_block = ""
    if s.fastest_mile_sec:
        day_str = _fmt_date(s.fastest_mile_date)
        fastest_block = (
            '<div style="padding:12px;background:#F9FAFB;border-radius:8px;'
            'margin-bottom:8px"><div style="font-size:12px;color:#6B7280">'
            "Fastest mile pace</div>"
            f'<div style="font-size:18px;font-weight:700">'
            f"{_fmt_pace_sec(s.fastest_mile_sec)}"
            + (f" · {day_str}" if day_str else "")
            + "</div></div>"
        )

    hours_block = (
        '<div style="padding:12px;background:#F9FAFB;border-radius:8px">'
        '<div style="font-size:12px;color:#6B7280">Total time</div>'
        f'<div style="font-size:18px;font-weight:700">'
        f"{s.total_hours:g} hrs · {s.session_count} session"
        f"{'s' if s.session_count != 1 else ''}</div></div>"
    )

    intro = {
        "positive": f"Hi {name}, your cardio stacked up this week. Here are the highlights.",
        "neutral": f"Hi {name}, here's your weekly cardio snapshot.",
        "negative": f"Hi {name}, a lighter week — and that's fine. Here's where you landed.",
        "baseline": f"Hi {name}, your first cardio week is on the books. This becomes your baseline.",
    }[tone]

    return f"""\
<!doctype html>
<html><body style="font-family:-apple-system,Segoe UI,sans-serif;background:#fff;color:#111;padding:24px;max-width:520px;margin:0 auto">
  <p style="font-size:15px;line-height:1.5">{intro}</p>
  <div style="padding:24px;background:linear-gradient(135deg,#06B6D4,#F97316);border-radius:12px;color:#fff;text-align:center;margin:16px 0">
    <div style="font-size:13px;opacity:0.9">This week</div>
    <div style="font-size:42px;font-weight:800;line-height:1.1">{s.km_this_week:g} km</div>
    {delta_block.replace('color:#10B981', 'color:#fff').replace('color:#F97316', 'color:#fff') if delta_block else ''}
  </div>
  {longest_block}
  {fastest_block}
  {hours_block}
  <p style="font-size:12px;color:#9CA3AF;margin-top:20px">Open the app to see the full breakdown.</p>
</body></html>
"""


# ────────────────────────────────────────────────────────────────────
# Embeddable section (the Monday weekly-summary merge)
# ────────────────────────────────────────────────────────────────────
#
# `render_digest_section_html` returns <tr>-rooted rows built from the shared
# signature builders, to be spliced into the weekly summary's 600px table. It is
# a SECTION, not a document: no <html>/<body>, no greeting, no footer, no
# unsubscribe, no "open the app" line — that chrome belongs to the envelope and
# duplicating it would nest a second document inside the first.
#
# Copy logic is REUSED, not forked: `_classify_tone`, `_fmt_pace_sec`,
# `_fmt_date`, `_first_name_for_copy`, `_stable_variant` are the same functions
# the push path uses.

_SECTION_LEDE_POSITIVE = [
    "Your cardio stacked up this week, {name}.",
    "{name}, the cardio volume went the right way this week.",
    "Cardio trended up this week, {name}.",
    "Strong cardio week, {name} — you added distance.",
]

_SECTION_LEDE_NEUTRAL = [
    "Here's how your cardio week landed, {name}.",
    "{name}, your cardio week in numbers.",
    "Cardio held steady this week, {name}.",
    "{name}, this is the cardio side of your week.",
]

_SECTION_LEDE_NEGATIVE = [
    "A lighter cardio week, {name} — and that's fine.",
    "{name}, cardio was quieter this week. It still counts.",
    "Cardio volume dipped this week, {name}. Easy to rebuild.",
    "{name}, the cardio week was light. No drama, just data.",
]

_SECTION_LEDE_BASELINE = [
    "First cardio week — this is your baseline, {name}.",
    "{name}, week one of cardio is on the books. Everything measures against this.",
    "This is your cardio starting line, {name}.",
    "{name}, baseline locked in. Next week we compare.",
]

_SECTION_LEDE_POOLS = {
    "positive": _SECTION_LEDE_POSITIVE,
    "neutral": _SECTION_LEDE_NEUTRAL,
    "negative": _SECTION_LEDE_NEGATIVE,
    "baseline": _SECTION_LEDE_BASELINE,
}


@dataclass
class _SectionTile:
    """Duck-types the weekly report's Tile (.icon .value .label .delta .dir)
    so `metric_grid` renders it identically to the Activity / Zealova grids."""

    icon: str
    value: str
    label: str
    delta: str
    dir: str        # 'up' (orange) | 'flat' (grey) — a bad week never reads red.


def _plural_sessions(n: int) -> str:
    return f"{n} session{'s' if n != 1 else ''}"


def _section_tiles(s: WeeklyCardioSummary) -> List[_SectionTile]:
    """2–4 tiles, ordered lede-first. Every tile is conditional on real data —
    we never render a placeholder metric."""
    tiles: List[_SectionTile] = []

    delta_text, delta_dir = "", "flat"
    if s.delta_pct is not None:
        sign = "+" if s.delta_pct >= 0 else ""
        delta_text = f"{sign}{s.delta_pct:g}% vs last week"
        delta_dir = "up" if s.delta_pct >= 0 else "flat"

    if s.km_this_week > 0:
        tiles.append(_SectionTile(
            icon="activity", value=f"{s.km_this_week:g} km", label="Distance",
            delta=delta_text, dir=delta_dir,
        ))

    if s.total_hours > 0:
        # On a time-only week (hiit/boxing/elliptical logged with duration and no
        # distance) this is the LEAD tile — we never headline a "0 km".
        tiles.append(_SectionTile(
            icon="clock", value=f"{s.total_hours:g} hrs", label="Cardio time",
            delta=_plural_sessions(s.session_count), dir="flat",
        ))
    elif s.km_this_week <= 0:
        # Neither distance nor duration on any row — the session count is the
        # only number we actually have.
        tiles.append(_SectionTile(
            icon="activity", value=str(s.session_count), label="Cardio sessions",
            delta="", dir="flat",
        ))

    if s.longest_run_km:
        tiles.append(_SectionTile(
            icon="foot", value=f"{s.longest_run_km:g} km", label="Longest run",
            delta=_fmt_date(s.longest_run_date), dir="flat",
        ))

    if s.fastest_mile_sec:
        tiles.append(_SectionTile(
            icon="timer", value=_fmt_pace_sec(s.fastest_mile_sec), label="Fastest mile",
            delta=_fmt_date(s.fastest_mile_date), dir="flat",
        ))

    return tiles


def render_digest_section_html(
    summary: Optional[WeeklyCardioSummary], first_name: str
) -> str:
    """Embeddable `<tr>` rows for the Monday weekly summary's cardio band.

    Returns "" for a falsy summary (zero-cardio week) so the caller can splice
    unconditionally and the no-cardio user's email is byte-for-byte unchanged.
    """
    if not summary:
        return ""

    from services import email_signature_template as sig

    tiles = _section_tiles(summary)
    if not tiles:
        return ""

    name = _first_name_for_copy(first_name)
    tone = _classify_tone(summary)
    # Salted by the week's own numbers → stable across cron retries, varied
    # week to week (feedback_dynamic_copy_not_robotic).
    salt = f"{name}:{summary.km_this_week:g}:{summary.session_count}:cardio-section"
    lede = _stable_variant(_SECTION_LEDE_POOLS[tone], salt).format(name=name)

    return (
        sig.section_label("Your cardio week")
        + sig.metric_grid(tiles)
        + sig.callout(lede)
    )
