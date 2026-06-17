"""Standalone unit test for compute_weekly_progress (no real DB, no pytest).

Uses a small fake Supabase client that honours eq/gte/lte/lt filters so the
service's date-windowing + aggregation are exercised for real. Run:
    python scripts/test_weekly_progress.py
"""
import os
import sys
from datetime import timedelta

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

import services.weekly_progress_service as W  # noqa: E402


# ── faithful-enough fake client ──
class _Resp:
    def __init__(self, data, count=None):
        self.data = data
        self.count = count


class _Query:
    def __init__(self, rows):
        self.rows = list(rows)
        self.filters = []
        self._count = False
        self._limit = None

    def select(self, *a, **k):
        if k.get("count"):
            self._count = True
        return self

    def eq(self, c, v):
        self.filters.append(("eq", c, v)); return self

    def gte(self, c, v):
        self.filters.append(("gte", c, v)); return self

    def lte(self, c, v):
        self.filters.append(("lte", c, v)); return self

    def lt(self, c, v):
        self.filters.append(("lt", c, v)); return self

    def order(self, *a, **k):
        return self

    def limit(self, n):
        self._limit = n; return self

    def _match(self, row):
        for op, c, v in self.filters:
            rv = row.get(c)
            if rv is None:
                return False
            rv, v = str(rv), str(v)
            if op == "eq" and rv != v:
                return False
            if op == "gte" and not rv >= v:
                return False
            if op == "lte" and not rv <= v:
                return False
            if op == "lt" and not rv < v:
                return False
        return True

    def execute(self):
        rows = [r for r in self.rows if self._match(r)]
        if self._limit:
            rows = rows[: self._limit]
        return _Resp(rows, count=len(rows) if self._count else None)


class _Client:
    def __init__(self, tables):
        self.tables = tables

    def table(self, name):
        return _Query(self.tables.get(name, []))


class _DB:
    def __init__(self, tables):
        self.client = _Client(tables)


def _iso_d(d):
    return d.isoformat()


def _iso_dt(d, h=12):
    return f"{d.isoformat()}T{h:02d}:00:00+00:00"


TZ = "America/Chicago"
WS, WE, prev_start_dt, ws_dt, we_dt = W._week_bounds(TZ)
prev_start = prev_start_dt.date()


def _daily_rows():
    rows = []
    this_steps = [1800, 2100, 2400, 1500, 900, 1534, 5734]  # Sun..Sat = 15,968
    for i, s in enumerate(this_steps):
        d = WS + timedelta(days=i)
        rows.append(dict(activity_date=_iso_d(d), steps=s, distance_meters=1672,
                         calories_burned=2729, active_minutes=53,
                         sleep_minutes=401, resting_heart_rate=69))
    for i in range(7):  # prior week, lower
        d = prev_start + timedelta(days=i)
        rows.append(dict(activity_date=_iso_d(d), steps=1200, distance_meters=1400,
                         calories_burned=2527, active_minutes=32,
                         sleep_minutes=390, resting_heart_rate=73))
    return rows


def _tables(daily=True, with_history=True):
    t = {
        "daily_activity": _daily_rows() if daily else [],
        "body_measurements": [
            dict(weight_kg=98.3, measured_at=_iso_dt(WS + timedelta(days=2))),
            dict(weight_kg=98.3, measured_at=_iso_dt(prev_start + timedelta(days=2))),
        ],
        "workout_logs": [
            dict(id="w1", completed_at=_iso_dt(WS + timedelta(days=1)), duration_minutes=62),
            dict(id="w2", completed_at=_iso_dt(WS + timedelta(days=3)), duration_minutes=58),
            dict(id="w3", completed_at=_iso_dt(WS + timedelta(days=5)), duration_minutes=60),
            dict(id="wp", completed_at=_iso_dt(prev_start + timedelta(days=2)), duration_minutes=55),
        ],
        "performance_logs": [
            dict(weight_kg=80, reps_completed=5, recorded_at=_iso_dt(WS + timedelta(days=1))),
            dict(weight_kg=60, reps_completed=8, recorded_at=_iso_dt(WS + timedelta(days=3))),
        ],
        "food_logs": [
            dict(logged_at=_iso_dt(WS + timedelta(days=i)), total_calories=1900)
            for i in range(5)
        ],
        "mindfulness_sessions": [
            dict(duration_seconds=1260, local_date=_iso_d(WS + timedelta(days=1))),
            dict(duration_seconds=1260, local_date=_iso_d(WS + timedelta(days=4))),
        ],
        "user_streaks": [dict(current_streak=12)],
        "users": [dict(daily_calorie_target=1950)],
        "personal_records": [],
        "user_achievements": [],
    }
    if not with_history:
        # remove prior-week daily rows so first-week framing kicks in
        t["daily_activity"] = [r for r in t["daily_activity"]
                               if r["activity_date"] >= WS.isoformat()]
    # Stamp identity columns the real queries filter on (single test user).
    for name, rows in t.items():
        for r in rows:
            r.setdefault("user_id", "u1")
            if name == "users":
                r.setdefault("id", "u1")
            if name == "user_streaks":
                r.setdefault("streak_type", "workout")
    return t


def check(label, cond):
    print(("  ✅ " if cond else "  ❌ ") + label)
    assert cond, label


print(f"week = {WS} .. {WE}  (prev starts {prev_start})\n")

# ── 1. full data ──
print("[1] full data (wearable + app-native)")
p = W.compute_weekly_progress(_DB(_tables()), "u1", TZ)
check(f"has_wearable=True ({p.has_wearable})", p.has_wearable is True)
check(f"total_steps=15968 ({p.total_steps})", p.total_steps == 15968)
check(f"best=Sat 5734 ({p.best_label} {p.best_steps})", p.best_label == "Sat" and p.best_steps == 5734)
check(f"avg_steps=2281 ({p.avg_steps})", p.avg_steps == 2281)
check(f"steps delta up ({p.steps_delta!r} {p.steps_dir})", p.steps_dir == "up" and p.steps_delta.startswith("↑"))
check(f"day_steps 7 entries Sun-first ({p.day_steps[0][0]})", len(p.day_steps) == 7 and p.day_steps[0][0] == "Sun")
labels = [t.label for t in p.activity_tiles]
check(f"activity tiles incl miles/sleep/bpm/weight ({labels})",
      {"Total miles", "Restful sleep", "Resting bpm", "Weight (kg)"} <= set(labels))
rhr = next(t for t in p.activity_tiles if t.label == "Resting bpm")
check(f"resting bpm down=good→up chip ({rhr.delta!r} {rhr.dir})", rhr.dir == "up" and rhr.delta.startswith("↓"))
zlabels = [t.label for t in p.zealova_tiles]
check(f"zealova tiles incl workouts/lbs/days/mind/streak ({zlabels})",
      {"Workouts", "Lbs lifted", "Days logged", "Mindfulness", "Day streak"} <= set(zlabels))
wk = next(t for t in p.zealova_tiles if t.label == "Workouts")
check(f"workouts=3, delta up ({wk.value} {wk.delta!r})", wk.value == "3" and wk.dir == "up")
check(f"not empty / not first-week ({p.empty_week},{p.is_first_week})",
      not p.empty_week and not p.is_first_week)

# ── 2. no wearable ──
print("\n[2] no wearable")
p2 = W.compute_weekly_progress(_DB(_tables(daily=False)), "u1", TZ)
check(f"has_wearable=False ({p2.has_wearable})", p2.has_wearable is False)
check(f"no activity tiles except maybe weight ({[t.label for t in p2.activity_tiles]})",
      all(t.label == "Weight (kg)" for t in p2.activity_tiles))
check(f"workouts hero populated ({p2.workouts_this_week})", p2.workouts_this_week == 3)
check(f"subline has training/lbs ({p2.workouts_subline!r})",
      "training" in p2.workouts_subline and "lbs" in p2.workouts_subline)

# ── 3. first week (no prior history) ──
print("\n[3] first week")
p3 = W.compute_weekly_progress(_DB(_tables(with_history=False)), "u1", TZ)
check(f"is_first_week=True ({p3.is_first_week})", p3.is_first_week is True)
check(f"steps delta = Baseline ({p3.steps_delta!r})", p3.steps_delta == "Baseline")
check("all activity deltas Baseline",
      all(t.delta == "Baseline" for t in p3.activity_tiles))

# ── 4. empty / quiet week ──
print("\n[4] quiet week")
empty_tables = {k: [] for k in _tables()}
empty_tables["users"] = [dict(daily_calorie_target=1950)]
p4 = W.compute_weekly_progress(_DB(empty_tables), "u1", TZ)
check(f"empty_week=True ({p4.empty_week})", p4.empty_week is True)
check(f"quiet_line set ({bool(p4.quiet_line)})", bool(p4.quiet_line))

print("\n✅ ALL WEEKLY-PROGRESS ASSERTIONS PASSED")
