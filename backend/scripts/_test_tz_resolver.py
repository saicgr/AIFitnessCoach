"""resolve_timezone() priority chain + write-through invariants.

Doesn't need the live DB — uses a tiny fake `db` shim with an in-memory
user record + an UPDATE-tracking client. Asserts:

  1. Header (valid IANA) wins over DB
  2. Header abbreviation (e.g. 'CST') maps via _TZ_ABBREVIATION_MAP
  3. Invalid header falls through to DB
  4. Empty / missing header falls through to DB
  5. DB UTC fallback when both header and DB are unset/invalid
  6. Write-through fires when header ≠ DB
  7. Write-through DOES NOT fire when header == DB (no-op)
  8. Write-through is throttled per user (≤1 / 24h)

Usage:
    backend/.venv/bin/python backend/scripts/_test_tz_resolver.py
"""

from __future__ import annotations

import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

# Reset throttle state between tests so we can exercise the gate
import core.timezone_utils as tzu  # noqa: E402


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


class FakeRequest:
    def __init__(self, headers: Optional[Dict[str, str]] = None):
        self.headers = headers or {}


class FakeUpdateChain:
    def __init__(self, sink: List[Dict[str, Any]], user_id: str):
        self._sink = sink
        self._user_id = user_id
        self._payload: Dict[str, Any] = {}

    def eq(self, col: str, val: str) -> "FakeUpdateChain":
        return self

    def execute(self):
        self._sink.append({"user_id": self._user_id, "payload": dict(self._payload)})
        return None


class FakeTable:
    def __init__(self, db: "FakeDB", name: str):
        self._db = db
        self._name = name
        self._last_user_id: Optional[str] = None

    def update(self, payload: Dict[str, Any]) -> FakeUpdateChain:
        chain = FakeUpdateChain(self._db._updates, self._last_user_id or "?")
        chain._payload = payload
        return _ChainedEq(chain, self)


class _ChainedEq:
    """Wrap an `update().eq(col,val)` to capture the user_id."""

    def __init__(self, chain: FakeUpdateChain, table: FakeTable):
        self._chain = chain
        self._table = table

    def eq(self, col: str, val: str):
        if col == "id":
            self._chain._user_id = val
        return self._chain


class FakeClient:
    def __init__(self, db: "FakeDB"):
        self._db = db

    def table(self, name: str) -> FakeTable:
        return FakeTable(self._db, name)


class FakeDB:
    def __init__(self, user_row: Dict[str, Any]):
        self.user_row = user_row
        self._updates: List[Dict[str, Any]] = []
        self.client = FakeClient(self)

    def get_user(self, user_id: str) -> Dict[str, Any]:
        return dict(self.user_row)


def reset_throttle():
    tzu._timezone_writethrough_last_ts.clear()


# ── 1. Header (valid IANA) wins ─────────────────────────────────────────
print("\n[1] Header (valid IANA) wins over DB")
db = FakeDB({"id": "u1", "timezone": "UTC"})
req = FakeRequest({"x-user-timezone": "America/Chicago"})
reset_throttle()
got = tzu.resolve_timezone(req, db, "u1")
check("header=America/Chicago", got, "America/Chicago")
check("write-through fired", len(db._updates), 1)
check("write-through value", db._updates[0]["payload"], {"timezone": "America/Chicago"})


# ── 2. Header abbreviation maps ─────────────────────────────────────────
print("\n[2] Header abbreviation maps via _TZ_ABBREVIATION_MAP")
db = FakeDB({"id": "u2", "timezone": "UTC"})
req = FakeRequest({"x-user-timezone": "CST"})
reset_throttle()
got = tzu.resolve_timezone(req, db, "u2")
check("header=CST → America/Chicago", got, "America/Chicago")


# ── 3. Invalid header falls through to DB ───────────────────────────────
print("\n[3] Invalid header falls through to DB")
db = FakeDB({"id": "u3", "timezone": "Asia/Tokyo"})
req = FakeRequest({"x-user-timezone": "NotARealZone"})
reset_throttle()
got = tzu.resolve_timezone(req, db, "u3")
check("invalid header → DB value", got, "Asia/Tokyo")
check("no write-through (header invalid)", len(db._updates), 0)


# ── 4. Empty / missing header ───────────────────────────────────────────
print("\n[4] Empty / missing header falls through to DB")
db = FakeDB({"id": "u4", "timezone": "Europe/London"})
reset_throttle()
got = tzu.resolve_timezone(FakeRequest({}), db, "u4")
check("missing header → DB value", got, "Europe/London")
db = FakeDB({"id": "u4b", "timezone": "Europe/London"})
reset_throttle()
got = tzu.resolve_timezone(FakeRequest({"x-user-timezone": ""}), db, "u4b")
check("empty header → DB value", got, "Europe/London")


# ── 5. UTC fallback ─────────────────────────────────────────────────────
print("\n[5] UTC last-resort fallback")
db = FakeDB({"id": "u5", "timezone": None})
reset_throttle()
got = tzu.resolve_timezone(FakeRequest({}), db, "u5")
check("both missing → UTC", got, "UTC")


# ── 6. Write-through fires when header differs from DB ──────────────────
print("\n[6] Write-through fires on header ≠ DB")
db = FakeDB({"id": "u6", "timezone": "UTC"})
req = FakeRequest({"x-user-timezone": "Asia/Tokyo"})
reset_throttle()
tzu.resolve_timezone(req, db, "u6")
check("write happened", len(db._updates), 1)
check("updated to Tokyo", db._updates[0]["payload"]["timezone"], "Asia/Tokyo")


# ── 7. Write-through NO-OP when header == DB ────────────────────────────
print("\n[7] Write-through is no-op when header matches DB")
db = FakeDB({"id": "u7", "timezone": "America/Chicago"})
req = FakeRequest({"x-user-timezone": "America/Chicago"})
reset_throttle()
tzu.resolve_timezone(req, db, "u7")
check("no UPDATE issued", len(db._updates), 0)


# ── 8. Throttle: only one write per user per 24h ────────────────────────
print("\n[8] Throttle blocks a second write inside 24h")
db = FakeDB({"id": "u8", "timezone": "UTC"})
req1 = FakeRequest({"x-user-timezone": "Asia/Tokyo"})
reset_throttle()
tzu.resolve_timezone(req1, db, "u8")
check("first call writes", len(db._updates), 1)
# Even though the DB value didn't actually change (FakeDB.get_user returns
# the original record), the throttle should still skip work.
req2 = FakeRequest({"x-user-timezone": "Europe/London"})
tzu.resolve_timezone(req2, db, "u8")
check("second call within throttle does not write", len(db._updates), 1)


# ── Summary ─────────────────────────────────────────────────────────────
print(f"\n{'='*60}")
print(f"  PASS: {pass_count}   FAIL: {fail_count}")
print(f"{'='*60}")
sys.exit(0 if fail_count == 0 else 2)
