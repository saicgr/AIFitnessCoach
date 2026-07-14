"""
Tests for PR Detection Integration in Workout Completion.

Tests cover:
- PR detection during workout completion
- AI celebration message generation
- Strength score recalculation background task
- Edge cases (no PRs, empty exercises, etc.)
"""
import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime, date, timedelta
from decimal import Decimal
from types import SimpleNamespace

from services.personal_records_service import (
    PersonalRecordsService,
    PersonalRecord,
    PRComparison,
)


# ============================================================================
# Fake Supabase client
# ============================================================================
# The completion / recalc code paths fan out over MANY different tables with
# different filter chains. A bare MagicMock returns the same stub for every
# `.table(name)` call, so a test could not say "users returns X but
# workout_logs returns Y" — which is exactly what these tests need to assert
# real behaviour. This fake routes by table name, records writes, and returns
# postgrest-shaped responses (`.data`, `.count`).
class _FakeQuery:
    def __init__(self, table_name: str, rows: list, writes: dict):
        self._table = table_name
        self._rows = rows
        self._writes = writes
        self._single = False
        self._is_write = False

    # --- chainable filters / modifiers (all no-ops for our purposes) ---
    def select(self, *a, **k):
        return self

    def eq(self, *a, **k):
        return self

    def neq(self, *a, **k):
        return self

    def gt(self, *a, **k):
        return self

    def gte(self, *a, **k):
        return self

    def lt(self, *a, **k):
        return self

    def lte(self, *a, **k):
        return self

    def in_(self, *a, **k):
        return self

    def is_(self, *a, **k):
        return self

    def order(self, *a, **k):
        return self

    def limit(self, *a, **k):
        return self

    @property
    def not_(self):
        return self

    def maybe_single(self):
        self._single = True
        return self

    def single(self):
        self._single = True
        return self

    # --- writes ---
    def _record(self, op, payload):
        self._writes.setdefault(self._table, {"insert": [], "upsert": [], "update": [], "delete": 0})
        if op == "delete":
            self._writes[self._table]["delete"] += 1
        else:
            self._writes[self._table][op].append(payload)
        self._is_write = True
        return self

    def insert(self, payload, *a, **k):
        return self._record("insert", payload)

    def upsert(self, payload, *a, **k):
        return self._record("upsert", payload)

    def update(self, payload, *a, **k):
        return self._record("update", payload)

    def delete(self, *a, **k):
        return self._record("delete", None)

    def execute(self):
        if self._is_write:
            return SimpleNamespace(data=[], count=0)
        if self._single:
            return SimpleNamespace(data=(self._rows[0] if self._rows else None), count=len(self._rows))
        return SimpleNamespace(data=list(self._rows), count=len(self._rows))


class FakeSupabase:
    """Minimal routing stand-in for the supabase-py client."""

    def __init__(self, tables: dict | None = None):
        self.tables = tables or {}
        self.writes: dict = {}

    def table(self, name: str):
        return _FakeQuery(name, self.tables.get(name, []), self.writes)

    # `.from_(...)` is the view-reading alias used in a few call sites.
    def from_(self, name: str):
        return self.table(name)

    def rpc(self, *a, **k):
        return _FakeQuery("__rpc__", [], self.writes)

    def inserted(self, table: str) -> list:
        return self.writes.get(table, {}).get("insert", [])


def _fake_request():
    """Stand-in for a Starlette Request — the endpoint only reads headers."""
    return SimpleNamespace(headers={})


class TestPersonalRecordsService:
    """Tests for PersonalRecordsService PR detection."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_check_for_pr_first_ever_pr(self):
        """Test detecting first-ever PR for an exercise."""
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=100,
            reps=5,
            existing_prs=[],
        )

        assert comparison.is_pr is True
        assert comparison.is_all_time_pr is True
        assert comparison.previous_1rm is None
        assert comparison.improvement_kg is None
        assert comparison.current_1rm > 100  # 1RM should be higher than 5RM weight

    def test_check_for_pr_new_pr_beats_existing(self):
        """Test detecting PR that beats existing record."""
        existing_prs = [
            {"estimated_1rm_kg": 110, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # 120kg x 5 reps ≈ 135kg 1RM (beats 110kg)
        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=120,
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.is_all_time_pr is True
        assert comparison.previous_1rm == 110
        assert comparison.improvement_kg > 0
        assert comparison.improvement_percent > 0

    def test_check_for_pr_no_improvement(self):
        """Test when lift doesn't beat existing PR."""
        existing_prs = [
            {"estimated_1rm_kg": 150, "achieved_at": datetime.now() - timedelta(days=7)}
        ]

        # 100kg x 5 reps ≈ 112kg 1RM (doesn't beat 150kg)
        comparison = self.service.check_for_pr(
            exercise_name="deadlift",
            weight_kg=100,
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is False
        assert comparison.is_all_time_pr is False
        assert comparison.improvement_kg is None

    def test_detect_prs_in_workout_multiple_prs(self):
        """Test detecting multiple PRs in a single workout."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 100, "reps": 5, "completed": True},
                    {"weight_kg": 105, "reps": 3, "completed": True},  # This is the PR
                ]
            },
            {
                "exercise_name": "squat",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 140, "reps": 5, "completed": True},  # This is a PR
                ]
            },
        ]

        existing_prs_by_exercise = {
            "bench_press": [{"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=60)}],
            "squat": [{"estimated_1rm_kg": 140, "achieved_at": datetime.now() - timedelta(days=30)}],
        }

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise=existing_prs_by_exercise,
        )

        # Should find PRs for both exercises
        assert len(new_prs) >= 2
        exercise_names = [pr.exercise_name for pr in new_prs]
        assert "bench_press" in exercise_names
        assert "squat" in exercise_names

    def test_detect_prs_in_workout_empty_exercises(self):
        """Test with no exercises in workout."""
        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=[],
            existing_prs_by_exercise={},
        )

        assert new_prs == []

    def test_detect_prs_in_workout_incomplete_sets(self):
        """Test that incomplete sets are skipped."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 200, "reps": 5, "completed": False},  # Skipped
                    {"weight_kg": 80, "reps": 5, "completed": True},
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},
        )

        # Should only count the completed set
        if new_prs:
            assert new_prs[0].weight_kg == 80

    def test_detect_prs_in_workout_zero_weight(self):
        """Test that an unloaded (bodyweight) set yields a REP PR, never a weight PR.

        RETIRED ASSERTION: this used to assert `new_prs == []` — zero-weight sets
        were dropped entirely. That was retired by FEATURE 3A (see
        `detect_prs_in_workout`'s `if weight_kg <= 0:` branch and
        `bodyweight_proxy_load_kg`): a set with no external load now records a
        *rep* PR carrying a bodyweight proxy load, so a user who goes 8 → 10
        pull-ups gets credit instead of being told they never PR'd.

        GUARANTEE PROTECTED (why the test existed): an unloaded set must never
        pollute the WEIGHT axis with a bogus loaded PR, and genuinely empty sets
        (0 reps) must still be dropped. Both are asserted below.
        """
        from services.exercise_rag.muscle_balance import bodyweight_proxy_load_kg

        workout_exercises = [
            {
                "exercise_name": "pull_ups",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 0, "reps": 10, "completed": True},
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},
            user_bodyweight_kg=70.0,
        )

        assert len(new_prs) == 1
        pr = new_prs[0]
        # Rep axis, not the weight axis.
        assert pr.pr_type == "reps"
        assert pr.reps == 10
        # The stored kg is the bodyweight proxy, not a fabricated external load.
        assert pr.weight_kg == bodyweight_proxy_load_kg("pull_ups", 70.0)
        # No external-load improvement is ever claimed for an unloaded set.
        assert pr.improvement_kg is None

        # A set with no reps is still garbage and is still dropped.
        empty = self.service.detect_prs_in_workout(
            workout_exercises=[
                {
                    "exercise_name": "pull_ups",
                    "workout_id": "workout-123",
                    "sets": [{"weight_kg": 0, "reps": 0, "completed": True}],
                }
            ],
            existing_prs_by_exercise={},
            user_bodyweight_kg=70.0,
        )
        assert empty == []

    def test_celebration_message_generation(self):
        """Test celebration message is generated."""
        workout_exercises = [
            {
                "exercise_name": "bench_press",
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 100, "reps": 5, "completed": True},
                ]
            },
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise={},  # First PR
        )

        assert len(new_prs) == 1
        assert new_prs[0].celebration_message is not None
        assert "Bench Press" in new_prs[0].celebration_message


class TestPRStatistics:
    """Tests for PR statistics calculation."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_get_pr_statistics_empty(self):
        """Test statistics with no PRs."""
        stats = self.service.get_pr_statistics([])

        assert stats["total_prs"] == 0
        assert stats["prs_this_period"] == 0
        assert stats["exercises_with_prs"] == 0
        assert stats["best_improvement_percent"] is None

    def test_get_pr_statistics_with_data(self):
        """Test statistics calculation with PR data."""
        all_prs = [
            {
                "exercise_name": "bench_press",
                "achieved_at": datetime.now() - timedelta(days=5),
                "improvement_percent": 5.5,
            },
            {
                "exercise_name": "squat",
                "achieved_at": datetime.now() - timedelta(days=10),
                "improvement_percent": 8.2,
            },
            {
                "exercise_name": "bench_press",
                "achieved_at": datetime.now() - timedelta(days=45),
                "improvement_percent": 3.0,
            },
        ]

        stats = self.service.get_pr_statistics(all_prs, period_days=30)

        assert stats["total_prs"] == 3
        assert stats["prs_this_period"] == 2  # Only 2 within 30 days
        assert stats["exercises_with_prs"] == 2  # bench_press and squat
        assert stats["best_improvement_percent"] == 8.2
        assert stats["most_improved_exercise"] == "squat"

    def test_get_exercise_pr_history(self):
        """Test getting PR history for specific exercise."""
        all_prs = [
            {
                "exercise_name": "Bench Press",
                "achieved_at": datetime.now() - timedelta(days=60),
                "estimated_1rm_kg": 100,
                "weight_kg": 90,
                "reps": 5,
            },
            {
                "exercise_name": "bench_press",  # Different format, same exercise
                "achieved_at": datetime.now() - timedelta(days=30),
                "estimated_1rm_kg": 110,
                "weight_kg": 95,
                "reps": 5,
            },
            {
                "exercise_name": "squat",
                "achieved_at": datetime.now() - timedelta(days=15),
                "estimated_1rm_kg": 150,
                "weight_kg": 130,
                "reps": 5,
            },
        ]

        history = self.service.get_exercise_pr_history("bench_press", all_prs)

        assert history["exercise_name"] == "bench_press"
        assert history["total_prs"] == 2
        assert history["total_improvement_kg"] == 10
        assert len(history["pr_timeline"]) == 2


class TestCompleteWorkoutWithPRDetection:
    """Tests for the complete_workout endpoint with PR detection.

    CALL-SITE FIX (the code MOVED, its behaviour did not): `complete_workout`
    was extracted out of `api.v1.workouts.crud` into
    `api.v1.workouts.crud_completion` ("Extracted from crud.py to keep files
    under 1000 lines"), and its signature grew `request` / `completion_method` /
    `current_user`. It also stopped taking a `get_db()` supabase handle and now
    reads `get_supabase_db().client`. These tests were still importing and
    calling the OLD symbol, so every one of them died at
    `ImportError: cannot import name 'complete_workout'`. Only HOW they call the
    endpoint changed here — WHAT they assert is preserved (and tightened, since
    the old `assert len(prs) >= 1 or "error" not in message` was an `or` that
    could never fail).
    """

    @staticmethod
    def _workout_row(name: str, exercises: list, difficulty: str = "medium",
                     wtype: str = "strength") -> dict:
        return {
            "id": "workout-1",
            "user_id": "user-1",
            "name": name,
            "type": wtype,
            "difficulty": difficulty,
            "scheduled_date": "2024-01-15",
            "is_completed": False,
            "gym_profile_id": None,
            "assignment_id": None,
            "exercises": exercises,
        }

    @staticmethod
    def _mock_db(workout_row, supabase):
        db = MagicMock()
        db.client = supabase
        db.get_workout.return_value = workout_row
        db.get_user.return_value = {"id": "user-1", "timezone": "UTC"}
        if workout_row is not None:
            db.update_workout.return_value = {**workout_row, "is_completed": True}
        return db

    @staticmethod
    def _patches(mock_db, celebration: str | None = None):
        """Patch the endpoint's I/O edges. Everything patched here is a
        fire-and-forget side effect (RAG index, redis bust, detached trophy
        task, debounced score recalc) or the Gemini call — never the PR
        detection logic under test.
        """
        mod = "api.v1.workouts.crud_completion"
        ctxs = [
            patch(f"{mod}.get_supabase_db", return_value=mock_db),
            patch(f"{mod}.index_workout_to_rag", new_callable=AsyncMock),
            patch(f"{mod}.invalidate_bootstrap_cache", new_callable=AsyncMock),
            patch(f"{mod}.schedule_score_recalc"),
            # log_workout_change builds its OWN supabase client (it does not use
            # the injected one), so without this patch the test writes to the
            # real production DB. Audit-log side effect, not the code under test.
            patch(f"{mod}.log_workout_change"),
            patch("services.mastery_writes.fire_trophy_check_detached"),
        ]
        if celebration is not None:
            ai = patch(
                f"{mod}.ai_insights_service.generate_pr_celebration",
                new_callable=AsyncMock,
            )
            ctxs.append(ai)
        return ctxs

    @pytest.mark.asyncio
    async def test_complete_workout_detects_prs(self):
        """Test that workout completion detects PRs and persists them."""
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import BackgroundTasks
        import contextlib

        supabase = FakeSupabase({
            "personal_records": [],  # no existing PRs → first-ever bench PR
            "users": [{"id": "user-1", "first_workout_completed_at": None,
                       "referred_by_code": None}],
            "user_metrics": [],
            "workout_logs": [],
            "workout_performance_summary": [],
            "xp_transactions": [],
        })
        workout_row = self._workout_row("Push Day", [
            {"name": "bench_press", "sets": [{"weight_kg": 100, "reps": 5, "completed": True}]}
        ])
        mock_db = self._mock_db(workout_row, supabase)

        with contextlib.ExitStack() as stack:
            entered = [stack.enter_context(c)
                       for c in self._patches(mock_db, celebration="Congrats on your new PR!")]
            entered[-1].return_value = "Congrats on your new PR!"  # the AI mock
            result = await complete_workout(
                request=_fake_request(),
                workout_id="workout-1",
                background_tasks=BackgroundTasks(),
                completion_method="tracked",
                current_user={"id": "user-1"},
            )

        assert result.workout.is_completed is True
        # First-ever bench press log → exactly one new PR.
        assert len(result.personal_records) == 1
        pr = result.personal_records[0]
        assert pr.exercise_name == "bench_press"
        assert pr.weight_kg == 100
        assert pr.reps == 5
        assert pr.is_all_time_pr is True
        assert pr.celebration_message == "Congrats on your new PR!"
        # And it was actually written to personal_records (bulk insert).
        inserted = supabase.inserted("personal_records")
        assert len(inserted) == 1
        assert inserted[0][0]["exercise_name"] == "bench_press"
        assert "personal record" in result.message.lower()

    @pytest.mark.asyncio
    async def test_complete_workout_no_prs(self):
        """Test workout completion when no PRs are set."""
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import BackgroundTasks
        import contextlib

        supabase = FakeSupabase({
            # Existing 1RM (150kg) far above what 50kg x 5 (~56kg 1RM) produces.
            "personal_records": [{
                "exercise_name": "bench_press",
                "estimated_1rm_kg": 150,
                "achieved_at": datetime.now().isoformat(),
            }],
            "users": [{"id": "user-1", "first_workout_completed_at": None,
                       "referred_by_code": None}],
            "user_metrics": [],
            "workout_logs": [],
            "workout_performance_summary": [],
            "xp_transactions": [],
        })
        workout_row = self._workout_row("Easy Day", [
            {"name": "bench_press", "sets": [{"weight_kg": 50, "reps": 5, "completed": True}]}
        ], difficulty="easy")
        mock_db = self._mock_db(workout_row, supabase)

        with contextlib.ExitStack() as stack:
            for c in self._patches(mock_db):
                stack.enter_context(c)
            result = await complete_workout(
                request=_fake_request(),
                workout_id="workout-1",
                background_tasks=BackgroundTasks(),
                completion_method="tracked",
                current_user={"id": "user-1"},
            )

        assert result.workout.is_completed is True
        assert result.personal_records == []
        assert "personal record" not in result.message.lower()
        # Nothing bogus written to personal_records either.
        assert supabase.inserted("personal_records") == []

    @pytest.mark.asyncio
    async def test_complete_workout_empty_exercises(self):
        """Test workout completion with no exercises."""
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import BackgroundTasks
        import contextlib

        supabase = FakeSupabase({
            "personal_records": [],
            "users": [{"id": "user-1", "first_workout_completed_at": None,
                       "referred_by_code": None}],
            "user_metrics": [],
            "workout_logs": [],
            "workout_performance_summary": [],
            "xp_transactions": [],
        })
        workout_row = self._workout_row("Rest Day", [], difficulty="easy", wtype="rest")
        mock_db = self._mock_db(workout_row, supabase)

        with contextlib.ExitStack() as stack:
            for c in self._patches(mock_db):
                stack.enter_context(c)
            result = await complete_workout(
                request=_fake_request(),
                workout_id="workout-1",
                background_tasks=BackgroundTasks(),
                completion_method="tracked",
                current_user={"id": "user-1"},
            )

        assert result.workout.is_completed is True
        assert result.personal_records == []
        assert supabase.inserted("personal_records") == []

    @pytest.mark.asyncio
    async def test_complete_workout_marked_done_never_fabricates_prs(self):
        """A 'marked_done' completion carries planned targets, not logged sets —
        it must never mint a PR out of an estimate.

        NEW: guards the `completion_method != "marked_done"` gate added to
        crud_completion.py. Same workout that produces a PR when tracked
        (see test_complete_workout_detects_prs) must produce none when merely
        marked done.
        """
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import BackgroundTasks
        import contextlib

        supabase = FakeSupabase({
            "personal_records": [],
            "users": [{"id": "user-1", "first_workout_completed_at": None,
                       "referred_by_code": None}],
            "user_metrics": [],
            "workout_logs": [],
            "workout_performance_summary": [],
            "xp_transactions": [],
        })
        workout_row = self._workout_row("Push Day", [
            {"name": "bench_press", "sets": [{"weight_kg": 100, "reps": 5, "completed": True}]}
        ])
        mock_db = self._mock_db(workout_row, supabase)

        with contextlib.ExitStack() as stack:
            for c in self._patches(mock_db):
                stack.enter_context(c)
            result = await complete_workout(
                request=_fake_request(),
                workout_id="workout-1",
                background_tasks=BackgroundTasks(),
                completion_method="marked_done",
                current_user={"id": "user-1"},
            )

        assert result.workout.is_completed is True
        assert result.personal_records == []
        assert supabase.inserted("personal_records") == []

    @pytest.mark.asyncio
    async def test_complete_workout_not_found(self):
        """Test completing non-existent workout."""
        from api.v1.workouts.crud_completion import complete_workout
        from fastapi import HTTPException, BackgroundTasks

        mock_db = self._mock_db(None, FakeSupabase())

        with patch("api.v1.workouts.crud_completion.get_supabase_db", return_value=mock_db):
            with pytest.raises(HTTPException) as exc_info:
                await complete_workout(
                    request=_fake_request(),
                    workout_id="nonexistent-id",
                    background_tasks=BackgroundTasks(),
                    completion_method="tracked",
                    current_user={"id": "user-1"},
                )

        assert exc_info.value.status_code == 404


class TestStrengthScoreRecalculation:
    """Tests for strength score background recalculation.

    CALL-SITE FIX: `recalculate_user_strength_scores` moved from
    `api.v1.workouts.crud` to `api.v1.workouts.crud_background_tasks` and gained
    a required `timezone_str` argument (it now derives the scoring period from
    the user's LOCAL date). It also stopped reading `workouts.exercises_json` and
    now delegates to the SHARED recompute (`services.strength_recalc.
    _recompute_strength_for_user`), which reads `workout_logs.sets_json` — the
    actual source of truth. The old mock fed `workouts.exercises`, which the
    current code never looks at, so the fixture data is updated to the shape the
    production code actually reads. The assertion (a strength_scores row is
    persisted) is unchanged and tightened.
    """

    @pytest.mark.asyncio
    async def test_recalculate_strength_scores_success(self):
        """Test successful strength score recalculation."""
        from api.v1.workouts.crud_background_tasks import recalculate_user_strength_scores

        supabase = FakeSupabase({
            "users": [{"weight_kg": 80, "gender": "male", "preferences": {}}],
            "workout_logs": [{
                "sets_json": [
                    {"exercise_name": "Bench Press", "weight_kg": 100, "reps": 5,
                     "completed": True},
                ],
                "completed_at": datetime.now().isoformat(),
                "gym_profile_id": None,
            }],
            "latest_strength_scores": [],
            "strength_scores": [],
            "exercise_library": [],
        })

        await recalculate_user_strength_scores("user-1", supabase, "UTC")

        # A real strength_scores row was persisted for the muscle the logged
        # bench press trains.
        rows = supabase.inserted("strength_scores")
        assert len(rows) >= 1
        chest = [r for r in rows if r["muscle_group"] == "chest"]
        assert len(chest) == 1
        assert chest[0]["user_id"] == "user-1"
        assert chest[0]["strength_score"] > 0
        assert chest[0]["best_estimated_1rm_kg"] > 100  # 100kg x 5 → 1RM above 100

    @pytest.mark.asyncio
    async def test_recalculate_strength_scores_user_not_found(self):
        """Test handling of non-existent user."""
        from api.v1.workouts.crud_background_tasks import recalculate_user_strength_scores

        supabase = FakeSupabase({"users": []})  # maybe_single() → data None

        # Should not raise, just log and return...
        await recalculate_user_strength_scores("nonexistent-user", supabase, "UTC")

        # ...and must not persist scores for a user that doesn't exist.
        assert supabase.inserted("strength_scores") == []


class TestPRImprovementCalculations:
    """Tests for PR improvement calculations."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_improvement_percentage_calculation(self):
        """Test improvement percentage is calculated correctly."""
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # New lift that gives ~120kg 1RM (20% improvement)
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=107,
            reps=5,  # ~120kg 1RM
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.improvement_percent is not None
        assert comparison.improvement_percent > 15  # Should be around 20%
        assert comparison.improvement_percent < 25

    def test_time_since_last_pr(self):
        """Test time since last PR calculation."""
        thirty_days_ago = datetime.now() - timedelta(days=30)
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": thirty_days_ago.isoformat()}
        ]

        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=120,  # Will beat the 100kg 1RM
            reps=5,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.time_since_last_pr is not None
        assert 29 <= comparison.time_since_last_pr <= 31  # ~30 days


class TestExerciseNameNormalization:
    """Tests for exercise name normalization in PR detection."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_normalize_exercise_name_spaces(self):
        """Test normalization with spaces."""
        assert self.service._normalize_exercise_name("Bench Press") == "bench_press"

    def test_normalize_exercise_name_dashes(self):
        """Test normalization with dashes."""
        assert self.service._normalize_exercise_name("pull-ups") == "pull_ups"

    def test_normalize_exercise_name_uppercase(self):
        """Test normalization with uppercase."""
        assert self.service._normalize_exercise_name("SQUAT") == "squat"

    def test_normalize_exercise_name_empty(self):
        """Test normalization with empty string."""
        assert self.service._normalize_exercise_name("") == ""

    def test_pr_detection_matches_normalized_names(self):
        """Test that PR detection matches normalized exercise names."""
        existing_prs_by_exercise = {
            "bench_press": [
                {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
            ]
        }

        workout_exercises = [
            {
                "exercise_name": "Bench Press",  # Different format
                "workout_id": "workout-123",
                "sets": [
                    {"weight_kg": 120, "reps": 5, "completed": True},  # Should beat existing PR
                ]
            }
        ]

        new_prs = self.service.detect_prs_in_workout(
            workout_exercises=workout_exercises,
            existing_prs_by_exercise=existing_prs_by_exercise,
        )

        # Should match despite different name format
        assert len(new_prs) == 1
        assert new_prs[0].improvement_kg is not None


class TestOneRepMaxCalculation:
    """Tests for 1RM calculation in PR context."""

    def setup_method(self):
        self.service = PersonalRecordsService()

    def test_higher_reps_lower_weight_can_be_pr(self):
        """Test that high reps at lower weight can still be a PR."""
        existing_prs = [
            {"estimated_1rm_kg": 100, "achieved_at": datetime.now() - timedelta(days=30)}
        ]

        # 85kg x 10 reps ≈ 113kg 1RM (beats 100kg)
        comparison = self.service.check_for_pr(
            exercise_name="bench_press",
            weight_kg=85,
            reps=10,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.current_1rm > 100

    def test_lower_reps_higher_weight_comparison(self):
        """Test comparing different rep ranges."""
        existing_prs = [
            {"estimated_1rm_kg": 115, "achieved_at": datetime.now() - timedelta(days=30)}  # e.g., 100kg x 5
        ]

        # 110kg x 3 reps ≈ 117kg 1RM (slightly beats 115kg)
        comparison = self.service.check_for_pr(
            exercise_name="squat",
            weight_kg=110,
            reps=3,
            existing_prs=existing_prs,
        )

        assert comparison.is_pr is True
        assert comparison.current_1rm > 115
