"""
Regression gate for the one-active-gym-per-user invariant.

THE BUG THIS LOCKS DOWN (Sentry PYTHON-FASTAPI-6V, 2026-07-23)
-------------------------------------------------------------
    duplicate key value violates unique constraint "idx_gym_profiles_active_per_user"
    in api.v1.users.profile.update_user

TWO independent code paths minted an `is_active=true` gym profile for the same
user and neither deactivated the other's:

  1. `create_gym_profiles_from_onboarding()` — fires when onboarding_completed
     flips true, and writes the user's REAL answers (environment, workout days,
     duration, equipment).
  2. `create_default_profile_if_needed()` — fires from GET /gym-profiles/active
     when the user has no live profile, and used to `.insert()` its OWN hardcoded
     "My Gym" / commercial_gym row built from whatever was in the users row at
     that instant.

The app fires both at the end of onboarding, so they raced. In production the
placeholder won: user 6bd62ca5 ended up with `workout_days = []` and 45 min while
their answers said `[0, 1, 2]` and 60 min, and the real builder died on the index.
A crash that silently discarded the user's onboarding answers and left their
active gym with no training days for the scheduler to place workouts on.

WHAT THE FIX IS
  * Both paths now go through the SAME builder, whose writes are UPSERTS keyed on
    (user_id, name) — either ordering converges on one correct profile.
  * Migration 2327 adds `trg_gym_profiles_single_active`, a BEFORE INSERT/UPDATE
    trigger that demotes the user's other live profiles whenever one is activated,
    so the invariant can never be violated by ANY writer.

The fake DB below deliberately enforces the partial unique index but NOT the
trigger: these tests prove the application layer alone stopped colliding, so the
trigger stays a backstop rather than the thing holding production together.

Run with: pytest backend/tests/test_gym_profile_single_active.py -v
"""
from __future__ import annotations

import asyncio
import uuid
from unittest.mock import MagicMock, patch

import pytest


USER_ID = "6bd62ca5-db9d-4a74-8090-98de22d60aac"


# ═══════════════════════════════════════════════════════════════════════════════
# FAKE SUPABASE — enough of postgrest's fluent builder to run both creators, with
# idx_gym_profiles_active_per_user enforced for real.
# ═══════════════════════════════════════════════════════════════════════════════

class UniqueViolation(Exception):
    """Stands in for postgrest's 23505 APIError."""


class _Query:
    def __init__(self, db, table):
        self._db = db
        self._table = table
        self._filters = []          # (op, column, value)
        self._payload = None
        self._op = None
        self._on_conflict = None

    # -- filters -------------------------------------------------------------
    def select(self, *_a, **_k):
        self._op = self._op or "select"
        return self

    def eq(self, column, value):
        self._filters.append(("eq", column, value))
        return self

    def neq(self, column, value):
        self._filters.append(("neq", column, value))
        return self

    def is_(self, column, value):
        assert value == "null"
        self._filters.append(("is_null", column, None))
        return self

    def order(self, *_a, **_k):
        return self

    def limit(self, *_a, **_k):
        return self

    def single(self):
        self._single = True
        return self

    # -- writes --------------------------------------------------------------
    def insert(self, payload):
        self._op, self._payload = "insert", payload
        return self

    def upsert(self, payload, on_conflict=None):
        self._op, self._payload, self._on_conflict = "upsert", payload, on_conflict
        return self

    def update(self, payload):
        self._op, self._payload = "update", payload
        return self

    # -- execution -----------------------------------------------------------
    def _matches(self, row):
        for op, column, value in self._filters:
            if op == "eq" and row.get(column) != value:
                return False
            if op == "neq" and row.get(column) == value:
                return False
            if op == "is_null" and row.get(column) is not None:
                return False
        return True

    def execute(self):
        rows = self._db.tables.setdefault(self._table, [])

        if self._op == "insert":
            new_row = {"id": str(uuid.uuid4()), **self._payload}
            self._db.assert_single_active(new_row)
            rows.append(new_row)
            self._db.writes.append(("insert", self._table, new_row))
            return MagicMock(data=[new_row])

        if self._op == "upsert":
            keys = [k.strip() for k in (self._on_conflict or "id").split(",")]
            existing = next(
                (r for r in rows if all(r.get(k) == self._payload.get(k) for k in keys)),
                None,
            )
            if existing is None:
                new_row = {"id": str(uuid.uuid4()), **self._payload}
                self._db.assert_single_active(new_row)
                rows.append(new_row)
                self._db.writes.append(("upsert-insert", self._table, new_row))
                return MagicMock(data=[new_row])
            merged = {**existing, **self._payload}
            self._db.assert_single_active(merged)
            existing.update(self._payload)
            self._db.writes.append(("upsert-update", self._table, existing))
            return MagicMock(data=[dict(existing)])

        if self._op == "update":
            touched = [r for r in rows if self._matches(r)]
            for row in touched:
                self._db.assert_single_active({**row, **self._payload})
                row.update(self._payload)
            self._db.writes.append(("update", self._table, self._payload))
            return MagicMock(data=[dict(r) for r in touched])

        matched = [dict(r) for r in rows if self._matches(r)]
        if getattr(self, "_single", False):
            return MagicMock(data=matched[0] if matched else None)
        return MagicMock(data=matched, count=len(matched))


class _FakeDB:
    """Holds the tables and enforces the partial unique index."""

    def __init__(self, user_row):
        self.tables = {"users": [user_row], "gym_profiles": [], "workouts": []}
        self.writes = []

    def table(self, name):
        return _Query(self, name)

    def assert_single_active(self, candidate):
        """idx_gym_profiles_active_per_user: UNIQUE(user_id) WHERE is_active AND archived_at IS NULL."""
        if not candidate.get("is_active") or candidate.get("archived_at") is not None:
            return
        for row in self.tables.get("gym_profiles", []):
            if row.get("id") == candidate.get("id"):
                continue
            if (
                row.get("user_id") == candidate.get("user_id")
                and row.get("is_active")
                and row.get("archived_at") is None
            ):
                raise UniqueViolation(
                    'duplicate key value violates unique constraint '
                    '"idx_gym_profiles_active_per_user"'
                )

    # -- assertions used by the tests ---------------------------------------
    def profiles(self):
        return list(self.tables["gym_profiles"])

    def active(self):
        return [
            p for p in self.tables["gym_profiles"]
            if p.get("is_active") and p.get("archived_at") is None
        ]


def _user_row(**overrides):
    """A user who finished onboarding: 3 training days, 60-minute commercial-gym sessions."""
    row = {
        "id": USER_ID,
        "onboarding_completed": True,
        "equipment": ["full_gym"],
        "equipment_details": [],
        "active_gym_profile_id": None,
        "preferences": {
            "workout_environment": "commercial_gym",
            "workout_days": [0, 1, 2],
            "workout_duration": 60,
            "training_split": "ai_decide",
            "coach_id": "coach_mike",
        },
    }
    row.update(overrides)
    return row


@pytest.fixture
def db():
    return _FakeDB(_user_row())


@pytest.fixture
def patched(db):
    """Point both creators at the fake DB."""
    supabase = MagicMock()
    supabase.client = db
    from api.v1 import gym_profiles as gym_profiles_mod
    from api.v1.users import onboarding as onboarding_mod

    with patch.object(gym_profiles_mod, "get_supabase", return_value=supabase), \
         patch.object(onboarding_mod, "get_supabase", return_value=supabase):
        yield gym_profiles_mod, onboarding_mod


# ═══════════════════════════════════════════════════════════════════════════════
# 1. THE INCIDENT — both creators run for one user
# ═══════════════════════════════════════════════════════════════════════════════

def test_onboarding_then_default_creator_does_not_violate_the_index(db, patched):
    """The exact production ordering: the default creator runs while onboarding's
    profile already exists. It used to insert a SECOND active row and 23505."""
    gym_profiles_mod, onboarding_mod = patched

    asyncio.run(onboarding_mod.create_gym_profiles_from_onboarding(
        user_id=USER_ID,
        gym_name=None,
        workout_environment="commercial_gym",
        equipment=["full_gym"],
        equipment_details=[],
        preferences=_user_row()["preferences"],
    ))
    asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))

    assert len(db.active()) == 1
    assert len(db.profiles()) == 1


def test_default_creator_first_then_onboarding_keeps_the_real_answers(db, patched):
    """The reverse ordering — and the one that actually shipped the damage. The
    placeholder is written first; onboarding must land on the SAME row and keep the
    user's real answers rather than dying on the index."""
    gym_profiles_mod, onboarding_mod = patched

    asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))
    asyncio.run(onboarding_mod.create_gym_profiles_from_onboarding(
        user_id=USER_ID,
        gym_name=None,
        workout_environment="commercial_gym",
        equipment=["full_gym"],
        equipment_details=[],
        preferences=_user_row()["preferences"],
    ))

    assert len(db.active()) == 1
    assert len(db.profiles()) == 1
    profile = db.profiles()[0]
    # The regression that cost user 6bd62ca5 their schedule.
    assert profile["workout_days"] == [0, 1, 2]
    assert profile["duration_minutes"] == 60


def test_concurrent_creators_converge_on_one_profile(db, patched):
    """Both fired at once, as the app does at the end of onboarding."""
    gym_profiles_mod, onboarding_mod = patched

    async def race():
        await asyncio.gather(
            onboarding_mod.create_gym_profiles_from_onboarding(
                user_id=USER_ID,
                gym_name=None,
                workout_environment="commercial_gym",
                equipment=["full_gym"],
                equipment_details=[],
                preferences=_user_row()["preferences"],
            ),
            gym_profiles_mod.create_default_profile_if_needed(USER_ID),
        )

    asyncio.run(race())

    assert len(db.active()) == 1
    assert len(db.profiles()) == 1


def test_default_creator_no_longer_invents_its_own_my_gym_row(db, patched):
    """It used to hardcode name="My Gym" / commercial_gym regardless of the user's
    answers — a different (user_id, name) key from onboarding's, which is precisely
    why the two collided instead of upserting onto each other."""
    gym_profiles_mod, _ = patched
    db.tables["users"][0]["preferences"]["workout_environment"] = "home_gym"

    asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))

    profile = db.profiles()[0]
    assert profile["name"] == "Home Gym"
    assert profile["workout_environment"] == "home_gym"
    assert profile["workout_days"] == [0, 1, 2]


# ═══════════════════════════════════════════════════════════════════════════════
# 2. THE 'both' ENVIRONMENT — two profiles, exactly one active
# ═══════════════════════════════════════════════════════════════════════════════

def test_both_environment_creates_two_profiles_one_active(db, patched):
    _, onboarding_mod = patched
    prefs = {**_user_row()["preferences"], "workout_environment": "both"}

    asyncio.run(onboarding_mod.create_gym_profiles_from_onboarding(
        user_id=USER_ID,
        gym_name=None,
        workout_environment="both",
        equipment=["full_gym"],
        equipment_details=[],
        preferences=prefs,
    ))

    assert len(db.profiles()) == 2
    assert len(db.active()) == 1
    assert db.active()[0]["name"] == "Home Gym"


def test_rerunning_the_builder_is_idempotent(db, patched):
    """Onboarding-completed can be PATCHed more than once (retries, resumed
    onboarding). Re-running must update, not accumulate active duplicates."""
    _, onboarding_mod = patched
    prefs = {**_user_row()["preferences"], "workout_environment": "both"}

    for _ in range(3):
        asyncio.run(onboarding_mod.create_gym_profiles_from_onboarding(
            user_id=USER_ID,
            gym_name=None,
            workout_environment="both",
            equipment=["full_gym"],
            equipment_details=[],
            preferences=prefs,
        ))

    assert len(db.profiles()) == 2
    assert len(db.active()) == 1


# ═══════════════════════════════════════════════════════════════════════════════
# 3. ARCHIVED PROFILES — must never be resurrected as a hidden active row
# ═══════════════════════════════════════════════════════════════════════════════

def test_builder_unarchives_the_profile_it_writes(db, patched):
    """The upsert is keyed on (user_id, name), so it can land on an archived row.
    Leaving archived_at set would mark a profile active that no picker can see —
    the user would have zero reachable gyms."""
    _, onboarding_mod = patched
    db.tables["gym_profiles"].append({
        "id": "archived-1",
        "user_id": USER_ID,
        "name": "Commercial Gym",
        "is_active": False,
        "archived_at": "2026-07-01T00:00:00",
        "workout_days": [],
    })

    asyncio.run(onboarding_mod.create_gym_profiles_from_onboarding(
        user_id=USER_ID,
        gym_name=None,
        workout_environment="commercial_gym",
        equipment=["full_gym"],
        equipment_details=[],
        preferences=_user_row()["preferences"],
    ))

    assert len(db.profiles()) == 1
    revived = db.profiles()[0]
    assert revived["archived_at"] is None
    assert revived["is_active"] is True


def test_default_creator_runs_for_a_user_whose_only_gym_is_archived(db, patched):
    """An archived-only user has no live profile, so they must get one — and it must
    not collide with the archived row's active flag."""
    gym_profiles_mod, _ = patched
    db.tables["gym_profiles"].append({
        "id": "archived-1",
        "user_id": USER_ID,
        "name": "Old Gym",
        "is_active": False,
        "archived_at": "2026-07-01T00:00:00",
        "workout_days": [],
    })

    asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))

    assert len(db.active()) == 1
    assert db.active()[0]["name"] == "Commercial Gym"


# ═══════════════════════════════════════════════════════════════════════════════
# 4. GUARDS THAT STILL HOLD
# ═══════════════════════════════════════════════════════════════════════════════

def test_no_profile_created_before_onboarding_completes(db, patched):
    gym_profiles_mod, _ = patched
    db.tables["users"][0]["onboarding_completed"] = False

    result = asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))

    assert result is None
    assert db.profiles() == []


def test_existing_live_profile_is_left_alone(db, patched):
    """The self-heal path must never overwrite a gym the user already has."""
    gym_profiles_mod, _ = patched
    db.tables["gym_profiles"].append({
        "id": "live-1",
        "user_id": USER_ID,
        "name": "Peoria home",
        "is_active": True,
        "archived_at": None,
        "workout_days": [2, 4, 6],
    })

    result = asyncio.run(gym_profiles_mod.create_default_profile_if_needed(USER_ID))

    assert result is None
    assert len(db.profiles()) == 1
    assert db.profiles()[0]["workout_days"] == [2, 4, 6]


# ═══════════════════════════════════════════════════════════════════════════════
# 5. THE DB BACKSTOP — migration 2327's trigger
# ═══════════════════════════════════════════════════════════════════════════════

def test_migration_2327_installs_the_single_active_trigger():
    """The application fix above is what these tests exercise; the trigger is the
    invariant that survives a future writer that forgets all of this."""
    from pathlib import Path

    sql = (
        Path(__file__).resolve().parent.parent
        / "migrations" / "2327_gym_profiles_single_active_trigger.sql"
    ).read_text()

    assert "CREATE TRIGGER trg_gym_profiles_single_active" in sql
    assert "BEFORE INSERT OR UPDATE ON gym_profiles" in sql
    assert "WHEN (NEW.is_active IS TRUE)" in sql
    # Demotes the user's OTHER live profiles, never the row being written.
    assert "id IS DISTINCT FROM NEW.id" in sql
    # Archived rows can never be the active one.
    assert "NEW.is_active := false" in sql
