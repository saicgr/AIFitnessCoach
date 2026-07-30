"""Single chokepoint for WRITING ``workouts.scheduled_date``.

``workouts.scheduled_date`` is a ``timestamptz`` whose convention is CLOSED
(CLAUDE.md): **every row is stored at NOON of the local day it belongs to.**
Noon — not midnight, not a bare ``YYYY-MM-DD`` — because a noon anchor lands
inside its own local-day window in every realistic timezone, so the day-window
reads in ``/today``, ``/schedule``, the carousel, the nudge cron and the
injury-invalidation sweep can never mis-day it.

Two ways writers used to break that convention, both of which shipped:

* ``"scheduled_date": body.scheduled_date`` where the body carries a bare
  ``"2026-07-28"``. Postgres casts that to ``2026-07-28 00:00:00+00``, which is
  ``19:00`` on **2026-07-27** for a CDT user — the row lands on the previous
  local day (E2E register rows #24 and #61).
* ``"scheduled_date": datetime.now().isoformat()`` — the server's *clock*
  instead of the *day*. On Render that is UTC, so a quick workout created at
  02:30 UTC is written onto the previous local day for every user west of UTC,
  and one created at 23:00 UTC lands on tomorrow for everyone east of it.

Every backend writer must therefore route its value through
[anchor_scheduled_date] (or [anchor_today] when the day is "now, where the user
is"). The only legitimate exception is carrying an already-stored value
forward unchanged (SCD2 supersede, versioning previews) — those read the value
back from the row and must NOT re-anchor it.

Run the regression gate from ``backend/`` with the repo's own interpreter::

    .venv/bin/python api/v1/workouts/scheduled_date_anchor.py --check

It fails on any new raw ``scheduled_date`` write into the ``workouts`` table.
(SCRIPT form, not ``python -m``: ``-m`` imports the whole ``api.v1`` package,
which needs 3.10+ union syntax the checked-in ``.venv`` — Python 3.9 — cannot
parse, so the gate was unrunnable locally. The script form bootstraps
``sys.path`` below and imports nothing but ``core``.)
"""
from __future__ import annotations

import re
import sys
from datetime import date as _date
from datetime import datetime as _datetime
from pathlib import Path
from typing import Optional, Union

if __package__ in (None, ""):  # executed as a script: put `backend/` on sys.path
    sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from core.logger import get_logger
from core.timezone_utils import get_user_today, target_date_to_utc_iso

logger = get_logger(__name__)

ScheduledDateInput = Union[str, _date, _datetime, None]


def _local_day_of(value: ScheduledDateInput, timezone_str: str) -> Optional[str]:
    """Return the LOCAL ``YYYY-MM-DD`` a stored/incoming value belongs to."""
    if value is None:
        return None
    from core.timezone_utils import utc_to_local_date

    if isinstance(value, _datetime):
        if value.tzinfo is None:
            # NAIVE — this is a wall-clock date the user picked (Pydantic
            # parses a client's "2026-07-29" into datetime(2026,7,29,0,0)).
            # Reading it as UTC would move it to the previous local day for
            # every western user, which is the very bug this module exists for.
            return value.date().isoformat()
        # A real instant — resolve it in the user's zone before taking the date,
        # otherwise a 02:00Z timestamp buckets onto tomorrow for a CDT user.
        # utc_to_local_date returns "" on unparseable input.
        return utc_to_local_date(value, timezone_str) or None
    if isinstance(value, _date):
        return value.isoformat()

    text = str(value).strip()
    if not text:
        return None
    if len(text) == 10:
        # Bare local date — already the day, nothing to resolve.
        return text
    # No offset / no Z after the date part means a naive wall-clock string:
    # same reasoning as the naive-datetime branch above.
    if "Z" not in text[10:].upper() and "+" not in text[10:] and "-" not in text[10:]:
        return text[:10]

    resolved = utc_to_local_date(text, timezone_str)
    # utc_to_local_date returns "" for unparseable input; fall back to the
    # date prefix rather than silently dropping the write.
    return resolved or text[:10]


def anchor_scheduled_date(
    value: ScheduledDateInput,
    timezone_str: str,
    *,
    default_to_today: bool = True,
) -> Optional[str]:
    """Normalize any date-ish input to the noon-anchored UTC ISO string.

    Accepts a bare ``YYYY-MM-DD``, a ``date``, a ``datetime`` or a full ISO
    timestamp. The value is first resolved to the LOCAL day it belongs to (in
    ``timezone_str``), then re-emitted at noon local, converted to UTC.

    Idempotent for values this function produced: noon local resolves back to
    the same local day, which re-anchors to the same instant.

    ``default_to_today=False`` returns ``None`` for a ``None`` input instead of
    substituting the user's today — use it where "no date supplied" must stay
    absent rather than become an implicit today.
    """
    day = _local_day_of(value, timezone_str)
    if day is None:
        if not default_to_today:
            return None
        day = get_user_today(timezone_str)
    return target_date_to_utc_iso(day, timezone_str)


def anchor_today(timezone_str: str) -> str:
    """Noon-anchored UTC ISO for the user's CURRENT local day.

    The correct replacement for any server-clock or server-calendar expression
    (``datetime.now()``, the UTC calendar date) in a ``workouts.scheduled_date``
    write.
    """
    return target_date_to_utc_iso(get_user_today(timezone_str), timezone_str)


def scheduled_local_date(value: ScheduledDateInput, timezone_str: str) -> Optional[str]:
    """Read-side companion: the local ``YYYY-MM-DD`` a stored value belongs to.

    Replaces ``str(row["scheduled_date"])[:10]`` and
    ``date.fromisoformat(row["scheduled_date"])`` — the latter raises
    ``ValueError`` on every noon-anchored row (``date.fromisoformat`` rejects a
    full timestamp on 3.9 through 3.12), which silently turned whole
    reschedule loops into no-ops.
    """
    return _local_day_of(value, timezone_str)


# ---------------------------------------------------------------------------
# Regression gate
# ---------------------------------------------------------------------------
# Any expression assigned to a `scheduled_date` key that WRITES the `workouts`
# table must be recognisably day-anchored. These are the approved shapes:
# either an anchor call, or an already-anchored value carried forward off a row
# / off a local variable this gate has verified.
_APPROVED_VALUE_PATTERNS = (
    re.compile(r"anchor_scheduled_date\("),
    re.compile(r"anchor_today\("),
    re.compile(r"target_date_to_utc_iso\("),
    re.compile(r"scheduled_at_noon"),
    # Carrying an ALREADY-STORED value forward (SCD2 supersede, date swap,
    # preview payload): the row was anchored when it was first written, so
    # re-anchoring would be a no-op at best and a tz round-trip at worst.
    re.compile(r"^existing(_workout)?(\.get\(|\[)"),
    re.compile(r"^row\.get\("),
    re.compile(r"^w\.get\("),
    re.compile(r"^workout\.get\("),
    re.compile(r"^source_workout\.get\("),
    re.compile(r"^target_workout\["),
    re.compile(r"^str\(old_date\)$"),
    re.compile(r"^old_date$"),
    re.compile(r"^target_scheduled_date$"),
    re.compile(r"^_request_date$"),
    re.compile(r"^scheduled_date_str$"),
    # Locals proven anchored at their definition site (verified 2026-07-29).
    re.compile(r"^new_date_ts$"),        # api/v1/workouts_db.py
    re.compile(r"^_new_date_iso$"),      # mcp/tools/workouts.py
    re.compile(r"^_new_date_anchored$"), # api/v1/workouts/workout_operations.py
    re.compile(r"^scheduled_ts$"),       # api/v1/saved_workouts.py
    re.compile(r"^_sched_ts$"),          # api/v1/workouts/preference_engine_helpers.py
    # A real INSTANT, not a day: a logged-completed activity stores when it
    # actually happened, and local-day windows bucket it correctly by
    # construction. (api/v1/wellness/events.py)
    re.compile(r"^occurred_at$"),
)

# Tables OTHER than `workouts` that legitimately carry a `scheduled_date`
# column. `schedule_items.scheduled_date` and `scheduled_workouts.scheduled_date`
# are real DATE columns where a bare YYYY-MM-DD is CORRECT (CLAUDE.md).
_NON_WORKOUT_TABLES = {
    "schedule_items",
    "scheduled_workouts",
    "saved_workouts",
    "workout_logs",
    "program_variant_weeks",
}

# KNOWN-OUTSTANDING baseline (E2E register rows #24 / #61, 2026-07-29). Each is
# a genuine unanchored write into `workouts` that lives OUTSIDE the be-workout-
# today domain and is tracked as a cross-domain fix. The gate reports them but
# does not fail on them, so it fails only on NEW findings — same design as
# scripts/audit_timezone_usage.py's baseline diff. DELETE an entry the moment
# its site is fixed; the gate then guarantees it cannot come back.
_KNOWN_OUTSTANDING = {
    ("api/v1/watch_sync.py", "datetime.utcnow().date().isoformat()"),  # tz-allowlist: baseline STRING naming the offending expression, not a call
    ("api/v1/coach/daily_insight.py", "today_utc"),
}

# Calls that persist a dict. `.update(` is also a plain dict method, so the
# table check below is what keeps the noise down.
_WRITE_CALLS = {"insert", "upsert", "update", "create_workout", "update_workout"}


def _call_name(node) -> Optional[str]:
    import ast

    func = getattr(node, "func", None)
    if isinstance(func, ast.Attribute):
        return func.attr
    if isinstance(func, ast.Name):
        return func.id
    return None


def _table_of(node, source: str, consts: dict) -> Optional[str]:
    """Best-effort: the ``.table(...)`` this write call chains off.

    Handles both a string literal and a module-level constant
    (``TABLE = "schedule_items"``; ``db.client.table(TABLE)``).
    """
    import ast

    seg = ast.get_source_segment(source, node) or ""
    m = re.search(r"""\.table\(\s*["\'](?P<t>[a-z_]+)["\']""", seg)
    if m:
        return m.group("t")
    m = re.search(r"\.table\(\s*(?P<n>[A-Za-z_][A-Za-z0-9_]*)\s*\)", seg)
    if m:
        return consts.get(m.group("n"))
    return None


def _scan(root: Path) -> list:
    import ast

    findings = []
    for path in sorted(root.rglob("*.py")):
        rel = path.relative_to(root).as_posix()
        if rel.startswith(("tests/", "scripts/", "migrations/", ".venv/")):
            continue
        if rel == "api/v1/workouts/scheduled_date_anchor.py":
            continue
        try:
            source = path.read_text(encoding="utf-8")
            tree = ast.parse(source)
        except (OSError, UnicodeDecodeError, SyntaxError):
            continue

        # Module-level string constants, so `.table(TABLE)` resolves.
        consts = {}
        for node in tree.body:
            if isinstance(node, ast.Assign) and isinstance(node.value, ast.Constant):
                if isinstance(node.value.value, str):
                    for target in node.targets:
                        if isinstance(target, ast.Name):
                            consts[target.id] = node.value.value

        # Dict literals carrying a scheduled_date key -> the value node.
        dict_values = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.Dict):
                for k, v in zip(node.keys, node.values):
                    if isinstance(k, ast.Constant) and k.value == "scheduled_date":
                        dict_values[id(node)] = v
        # SUBSCRIPT form: `update_data["scheduled_date"] = <value>`, built up
        # field-by-field on a dict that is later handed to a write. This is the
        # shape crud.py / workouts_db.py actually use for PUT, and a dict-literal
        # -only scan is blind to it — api/v1/workouts_db.py:196 wrote
        # `str(workout.scheduled_date)` (naive midnight → midnight UTC) right
        # through the first version of this gate.
        subscript_assigns = []  # (name, value_node)
        for node in ast.walk(tree):
            if not isinstance(node, ast.Assign):
                continue
            for target in node.targets:
                if not isinstance(target, ast.Subscript):
                    continue
                if not isinstance(target.value, ast.Name):
                    continue
                key = target.slice
                # py3.8 wraps the slice in ast.Index; 3.9+ does not.
                key = getattr(key, "value", key)
                if isinstance(key, ast.Constant) and key.value == "scheduled_date":
                    subscript_assigns.append((target.value.id, node.value))

        if not dict_values and not subscript_assigns:
            continue

        # name -> dict node, for dicts that are built then passed to a write.
        name_to_dict = {}
        for node in ast.walk(tree):
            if isinstance(node, ast.Assign) and isinstance(node.value, ast.Dict):
                if id(node.value) in dict_values:
                    for target in node.targets:
                        if isinstance(target, ast.Name):
                            name_to_dict[target.id] = node.value

        # Write calls: (table, dict node) pairs, plus name -> table for any
        # NAME handed to a write (that is what makes the subscript form
        # attributable to a table).
        written = {}
        written_names = {}
        for node in ast.walk(tree):
            if not isinstance(node, ast.Call):
                continue
            if _call_name(node) not in _WRITE_CALLS:
                continue
            table = _table_of(node, source, consts)
            for arg in node.args:
                target_dict = None
                if isinstance(arg, ast.Dict) and id(arg) in dict_values:
                    target_dict = arg
                elif isinstance(arg, ast.Name) and arg.id in name_to_dict:
                    target_dict = name_to_dict[arg.id]
                if isinstance(arg, ast.Name):
                    written_names.setdefault(arg.id, table)
                if target_dict is not None:
                    # A `.table("X")` on the same expression wins; a bare
                    # db.create_workout()/update_workout() is always `workouts`.
                    written.setdefault(id(target_dict), table)

        def _flag(value_node):
            value = (ast.get_source_segment(source, value_node) or "").strip()
            if any(p.search(value) for p in _APPROVED_VALUE_PATTERNS):
                return
            findings.append((rel, value_node.lineno, value))

        for node_id, table in written.items():
            if table in _NON_WORKOUT_TABLES:
                continue
            _flag(dict_values[node_id])

        for name, value_node in subscript_assigns:
            if name not in written_names:
                continue  # dict is never persisted (response/preview payload)
            if written_names[name] in _NON_WORKOUT_TABLES:
                continue
            _flag(value_node)
    return sorted(findings)


def _main(argv) -> int:
    if "--check" not in argv:
        print(__doc__)
        return 0
    root = Path(__file__).resolve().parents[3]
    findings = _scan(root)
    outstanding = [f for f in findings if (f[0], f[2]) in _KNOWN_OUTSTANDING]
    new_findings = [f for f in findings if (f[0], f[2]) not in _KNOWN_OUTSTANDING]

    if outstanding:
        print("known-outstanding unanchored writes (tracked, cross-domain):")
        for rel, line_no, value in outstanding:
            print(f"   {rel}:{line_no}  scheduled_date = {value}")

    if not new_findings:
        print(
            "\u2705 scheduled_date anchor gate: no NEW raw workouts.scheduled_date "
            f"writes ({len(outstanding)} known-outstanding)"
        )
        return 0

    print("\u274c scheduled_date anchor gate: NEW unanchored writes found")
    for rel, line_no, value in new_findings:
        print(f"   {rel}:{line_no}  scheduled_date = {value}")
    print(
        "\nRoute the value through api.v1.workouts.scheduled_date_anchor."
        "anchor_scheduled_date(value, tz) / anchor_today(tz). If the site writes a"
        " DIFFERENT table whose scheduled_date is a real DATE column, add that"
        " table to _NON_WORKOUT_TABLES."
    )
    return 1


if __name__ == "__main__":  # pragma: no cover
    sys.exit(_main(sys.argv[1:]))
