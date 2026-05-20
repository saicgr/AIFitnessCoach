"""Pure-Python timezone helper invariants.

Runs in <1s. No DB, no HTTP. Asserts that every helper in
`core/timezone_utils.py` behaves correctly across DST transitions, the full
UTC offset range (UTC-12…UTC+14), and the abbreviation map.

Each scenario from the plan's Track F edge case matrix has one assertion.

Usage:
    backend/.venv/bin/python backend/scripts/_test_tz_helpers.py
"""

from __future__ import annotations

import sys
from datetime import datetime, date
from pathlib import Path
from zoneinfo import ZoneInfo

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from core.timezone_utils import (  # noqa: E402
    target_date_to_utc_iso,
    local_date_to_utc_range,
    get_user_today,
    _is_valid_tz,
    _TZ_ABBREVIATION_MAP,
)


pass_count = 0
fail_count = 0


def check(label: str, got, want):
    global pass_count, fail_count
    ok = got == want
    if ok:
        pass_count += 1
        print(f"  ✅ {label}")
    else:
        fail_count += 1
        print(f"  ❌ {label}\n     got={got!r}\n     want={want!r}")


def in_window(ts_iso: str, start_iso: str, end_iso: str) -> bool:
    ts = datetime.fromisoformat(ts_iso.replace("Z", "+00:00"))
    s = datetime.fromisoformat(start_iso.replace("Z", "+00:00"))
    e = datetime.fromisoformat(end_iso.replace("Z", "+00:00"))
    return s <= ts <= e


# ── Section 1: target_date_to_utc_iso across the offset spectrum ─────────
print("\n[1] target_date_to_utc_iso anchors at noon-local across all offsets")

cases = [
    # (tz, date_str, expected_utc)
    ("UTC", "2026-05-21", "2026-05-21T12:00:00+00:00"),
    ("America/Chicago", "2026-05-21", "2026-05-21T17:00:00+00:00"),  # CDT = UTC-5
    ("America/Los_Angeles", "2026-05-21", "2026-05-21T19:00:00+00:00"),  # PDT = UTC-7
    ("Europe/London", "2026-05-21", "2026-05-21T11:00:00+00:00"),  # BST = UTC+1
    ("Asia/Tokyo", "2026-05-21", "2026-05-21T03:00:00+00:00"),  # JST = UTC+9
    ("Asia/Kolkata", "2026-05-21", "2026-05-21T06:30:00+00:00"),  # IST = UTC+5:30
    ("Pacific/Auckland", "2026-05-21", "2026-05-21T00:00:00+00:00"),  # NZST = UTC+12 in May
    ("Pacific/Kiritimati", "2026-05-21", "2026-05-20T22:00:00+00:00"),  # UTC+14
    ("Pacific/Pago_Pago", "2026-05-21", "2026-05-21T23:00:00+00:00"),  # UTC-11
]
for tz, d, expected in cases:
    check(f"{tz} {d}", target_date_to_utc_iso(d, tz), expected)


# ── Section 2: DST transitions ──────────────────────────────────────────
print("\n[2] DST transitions handled by ZoneInfo")
# US DST springs forward 2026-03-08 (CST -> CDT)
# CST = UTC-6, CDT = UTC-5
check(
    "America/Chicago 2026-03-07 (CST, pre-DST)",
    target_date_to_utc_iso("2026-03-07", "America/Chicago"),
    "2026-03-07T18:00:00+00:00",  # noon CST = 18:00 UTC
)
check(
    "America/Chicago 2026-03-09 (CDT, post-DST)",
    target_date_to_utc_iso("2026-03-09", "America/Chicago"),
    "2026-03-09T17:00:00+00:00",  # noon CDT = 17:00 UTC
)
# US DST fall back 2026-11-01 (CDT -> CST)
check(
    "America/Chicago 2026-10-31 (CDT, pre-fallback)",
    target_date_to_utc_iso("2026-10-31", "America/Chicago"),
    "2026-10-31T17:00:00+00:00",
)
check(
    "America/Chicago 2026-11-02 (CST, post-fallback)",
    target_date_to_utc_iso("2026-11-02", "America/Chicago"),
    "2026-11-02T18:00:00+00:00",
)
# NZ DST flips opposite direction
check(
    "Pacific/Auckland 2026-04-04 (NZDT, pre-fallback)",
    target_date_to_utc_iso("2026-04-04", "Pacific/Auckland"),
    "2026-04-03T23:00:00+00:00",
)
check(
    "Pacific/Auckland 2026-04-06 (NZST, post-fallback)",
    target_date_to_utc_iso("2026-04-06", "Pacific/Auckland"),
    "2026-04-06T00:00:00+00:00",
)


# ── Section 3: local_date_to_utc_range correctness ─────────────────────
print("\n[3] local_date_to_utc_range produces windows that catch the stored row")
# A workout stored at noon-CDT on May 21 must fall inside CDT's May 21
# window AND must NOT fall inside CDT's May 20 window.
stored = target_date_to_utc_iso("2026-05-21", "America/Chicago")
wed_start, wed_end = local_date_to_utc_range("2026-05-20", "America/Chicago")
thu_start, thu_end = local_date_to_utc_range("2026-05-21", "America/Chicago")
check("CDT noon-21 in Thu window", in_window(stored, thu_start, thu_end), True)
check("CDT noon-21 NOT in Wed window", in_window(stored, wed_start, wed_end), False)

# Auckland (UTC+12) — the UTC+11 boundary that broke under noon-UTC anchor
stored = target_date_to_utc_iso("2026-05-21", "Pacific/Auckland")
ak_wed_start, ak_wed_end = local_date_to_utc_range("2026-05-20", "Pacific/Auckland")
ak_thu_start, ak_thu_end = local_date_to_utc_range("2026-05-21", "Pacific/Auckland")
check("NZST noon-21 in Auckland Thu window", in_window(stored, ak_thu_start, ak_thu_end), True)
check("NZST noon-21 NOT in Auckland Wed window", in_window(stored, ak_wed_start, ak_wed_end), False)
# Regression baseline: noon-UTC anchor for Auckland NZDT (Jan, UTC+13).
# In Jan Auckland is on NZDT, so a workout intended for Jan 21 stored at
# noon-UTC lands in Jan 22 local — proves why per-user noon-local is needed.
nzdt_noon_utc = "2026-01-21T12:00:00+00:00"
ak_jan21_start, ak_jan21_end = local_date_to_utc_range("2026-01-21", "Pacific/Auckland")
ak_jan22_start, ak_jan22_end = local_date_to_utc_range("2026-01-22", "Pacific/Auckland")
check(
    "Noon-UTC Jan 21 NOT in Auckland NZDT Jan 21 window (Phase-1 limit demonstrated)",
    in_window(nzdt_noon_utc, ak_jan21_start, ak_jan21_end),
    False,
)
check(
    "Noon-UTC Jan 21 LANDS IN Auckland NZDT Jan 22 window (the Phase-1 bug)",
    in_window(nzdt_noon_utc, ak_jan22_start, ak_jan22_end),
    True,
)

# Kiritimati UTC+14 — most extreme
stored = target_date_to_utc_iso("2026-05-21", "Pacific/Kiritimati")
ki_thu_start, ki_thu_end = local_date_to_utc_range("2026-05-21", "Pacific/Kiritimati")
check("UTC+14 noon-21 in Kiritimati Thu window", in_window(stored, ki_thu_start, ki_thu_end), True)


# ── Section 4: regression baseline — bare midnight UTC was the bug ──────
print("\n[4] Bare midnight-UTC storage WOULD have polluted CDT Wed window")
legacy_midnight = "2026-05-21T00:00:00+00:00"
check(
    "midnight-UTC May 21 in CDT Wed (May 20) window — pre-fix bug",
    in_window(legacy_midnight, wed_start, wed_end),
    True,
)
check(
    "midnight-UTC May 21 NOT in CDT Thu window (it's the day BEFORE in CDT)",
    in_window(legacy_midnight, thu_start, thu_end),
    False,
)  # Pure midnight-UTC sits at 19:00 CDT May 20 → only matches Wed window.


# ── Section 5: abbreviation map ─────────────────────────────────────────
print("\n[5] Abbreviation map resolves correctly (CST → Chicago, not Shanghai)")
check("CST", _TZ_ABBREVIATION_MAP["CST"], "America/Chicago")
check("CDT", _TZ_ABBREVIATION_MAP["CDT"], "America/Chicago")
check("PST", _TZ_ABBREVIATION_MAP["PST"], "America/Los_Angeles")
check("EST", _TZ_ABBREVIATION_MAP["EST"], "America/New_York")
check("IST → Kolkata (not Israel/Ireland)", _TZ_ABBREVIATION_MAP["IST"], "Asia/Kolkata")
check("JST", _TZ_ABBREVIATION_MAP.get("JST"), "Asia/Tokyo")


# ── Section 6: _is_valid_tz ─────────────────────────────────────────────
print("\n[6] _is_valid_tz accepts IANA, rejects garbage")
check("America/Chicago valid", _is_valid_tz("America/Chicago"), True)
check("Asia/Kolkata valid", _is_valid_tz("Asia/Kolkata"), True)
check("NotARealZone invalid", _is_valid_tz("NotARealZone"), False)
check("CST (abbreviation, not IANA)", _is_valid_tz("CST"), False)
check("empty invalid", _is_valid_tz(""), False)


# ── Section 7: get_user_today round-trips with the user's tz ────────────
print("\n[7] get_user_today returns user-local calendar day")
# Can't compare to a fixed value (depends on current time) but we can sanity
# check the type/format.
import re
for tz in ("UTC", "America/Chicago", "Asia/Tokyo", "Pacific/Auckland"):
    val = get_user_today(tz)
    check(f"{tz} returns YYYY-MM-DD", bool(re.fullmatch(r"\d{4}-\d{2}-\d{2}", val)), True)


# ── Section 8: half-hour and quarter-hour offset zones (Iran, India, Newfoundland, Nepal) ──
print("\n[8] Non-aligned offsets handled correctly")
check(
    "India IST (UTC+5:30)",
    target_date_to_utc_iso("2026-05-21", "Asia/Kolkata"),
    "2026-05-21T06:30:00+00:00",  # noon IST = 06:30 UTC
)
check(
    "Nepal NPT (UTC+5:45)",
    target_date_to_utc_iso("2026-05-21", "Asia/Kathmandu"),
    "2026-05-21T06:15:00+00:00",
)
check(
    "Newfoundland NDT (UTC-2:30 in summer)",
    target_date_to_utc_iso("2026-05-21", "America/St_Johns"),
    "2026-05-21T14:30:00+00:00",
)


# ── Summary ─────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print(f"  PASS: {pass_count}   FAIL: {fail_count}")
print(f"{'='*60}")
sys.exit(0 if fail_count == 0 else 2)
