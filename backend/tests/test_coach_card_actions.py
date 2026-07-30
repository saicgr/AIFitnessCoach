"""Regression tests for the coach workout card's terminal actions.

Covers the E2E 2026-07-28 register rows this file exists to keep fixed:

  row 55  — chat "Apply" dispatch actions wrote `{"exercises": …}` to `workouts`,
            a column that does not exist (the real one is `exercises_json`), so
            PostgREST rejected the WHOLE payload (PGRST204) on every invocation.
  row 63  — a "Quick Power Full Body" workout composed entirely of stretches.
  row 97  — coach-authored workouts pulled form-cue-shaped junk names out of the
            free exercise dataset, and TRX work for a user with no straps.
  row 99  — "Schedule" re-entered the LLM with free text, which authored a
            DIFFERENT workout and persisted nothing.

Everything here is mock-driven — no network, no DB.
"""
import uuid
from unittest.mock import MagicMock, patch

import pytest
from fastapi import FastAPI
from fastapi.testclient import TestClient


# ── row 55: the mutation tools must write the column that exists ─────────────


class TestDispatchWritesRealColumn:
    def _db(self, workout):
        db = MagicMock()
        db.get_workout.return_value = workout
        db.get_user.return_value = {
            "id": workout["user_id"], "fitness_level": "intermediate",
            "goals": ["Build Muscle"], "equipment": ["Bodyweight"],
        }
        db.update_workout.return_value = {"id": workout["id"]}
        return db

    def test_add_exercise_writes_exercises_json(self):
        from services.langgraph_agents.tools.workout_tools import add_exercise_to_workout

        wid, uid = str(uuid.uuid4()), str(uuid.uuid4())
        db = self._db({"id": wid, "user_id": uid, "exercises_json": []})

        rag = MagicMock()
        with patch("services.langgraph_agents.tools.workout_tools.get_supabase_db",
                   return_value=db), \
             patch("services.exercise_rag_service.get_exercise_rag_service",
                   return_value=rag), \
             patch("services.langgraph_agents.tools.workout_tools.run_async_in_sync",
                   return_value=[{"name": "Barbell Row", "equipment": "Barbell"}]):
            result = add_exercise_to_workout.invoke(
                {"workout_id": wid, "exercise_names": ["Barbell Row"]}
            )

        assert result["success"] is True
        payload = db.update_workout.call_args[0][1]
        assert "exercises_json" in payload, "must write the real column"
        assert "exercises" not in payload, "phantom column would 42703/PGRST204 the write"

    def test_rejected_write_is_not_reported_as_success(self):
        """A write that changes no row must surface as failure, never a success card."""
        from services.langgraph_agents.tools.workout_tools import add_exercise_to_workout

        wid, uid = str(uuid.uuid4()), str(uuid.uuid4())
        db = self._db({"id": wid, "user_id": uid, "exercises_json": []})
        db.update_workout.return_value = None          # PostgREST rejected / no row

        with patch("services.langgraph_agents.tools.workout_tools.get_supabase_db",
                   return_value=db), \
             patch("services.exercise_rag_service.get_exercise_rag_service",
                   return_value=MagicMock()), \
             patch("services.langgraph_agents.tools.workout_tools.run_async_in_sync",
                   return_value=[{"name": "Barbell Row", "equipment": "Barbell"}]):
            result = add_exercise_to_workout.invoke(
                {"workout_id": wid, "exercise_names": ["Barbell Row"]}
            )

        assert result["success"] is False

    def test_replace_all_writes_exercises_json(self):
        from services.langgraph_agents.tools.workout_tools import replace_all_exercises

        wid, uid = str(uuid.uuid4()), str(uuid.uuid4())
        db = self._db({
            "id": wid, "user_id": uid,
            "exercises_json": [{"name": "Old", "sets": 3}],
        })

        with patch("services.langgraph_agents.tools.workout_tools.get_supabase_db",
                   return_value=db), \
             patch("services.exercise_rag_service.get_exercise_rag_service",
                   return_value=MagicMock()), \
             patch("services.langgraph_agents.tools.workout_tools.run_async_in_sync",
                   return_value=[{"name": "Seated Cable Row", "equipment": "Cable machine"}]), \
             patch("services.coach_exercise_quality.filter_candidates",
                   side_effect=lambda _db, rows, **_kw: rows):
            result = replace_all_exercises.invoke(
                {"workout_id": wid, "muscle_group": "back", "num_exercises": 1}
            )

        assert result["success"] is True
        payload = db.update_workout.call_args[0][1]
        assert "exercises_json" in payload
        assert "exercises" not in payload
        assert result["exercises_removed"] == ["Old"], "must read exercises_json too"


# ── rows 97 + 63: library junk / off-intent / un-owned gear ──────────────────


class TestCoachExerciseQuality:
    def _db_with_categories(self, mapping):
        db = MagicMock()
        db.client.table.return_value.select.return_value.in_.return_value.limit.return_value.execute.return_value.data = [
            {"name": n, "category": c} for n, c in mapping.items()
        ]
        # gear vocabulary query
        db.client.table.return_value.select.return_value.limit.return_value.execute.return_value.data = [
            {"equipment": "suspension trainer"}, {"equipment": "barbell"},
            {"equipment": "bench"}, {"equipment": "Bodyweight"},
        ]
        return db

    def _reset_vocab(self):
        import services.coach_exercise_quality as q
        q._gear_vocab_cache = None

    def test_form_cue_name_is_dropped(self):
        from services.coach_exercise_quality import filter_candidates
        self._reset_vocab()
        db = self._db_with_categories({
            "Chest Bench Press Correct Stance": "strength",
            "Bodyweight Svend Press": "strength",
        })
        kept = filter_candidates(
            db,
            [{"name": "Chest Bench Press Correct Stance"},
             {"name": "Bodyweight Svend Press"}],
            training_intent="chest", user_equipment=["Bodyweight"],
        )
        assert [c["name"] for c in kept] == ["Bodyweight Svend Press"]

    def test_stretches_dropped_for_strength_intent_kept_for_mobility(self):
        from services.coach_exercise_quality import filter_candidates
        self._reset_vocab()
        cands = [{"name": "Calve Stretch Foot On Wall"},
                 {"name": "Standing Forward Fold (Uttanasana)"},
                 {"name": "Bodyweight Svend Press"}]
        db = self._db_with_categories({
            "Calve Stretch Foot On Wall": "stretching",
            "Standing Forward Fold (Uttanasana)": "yoga",
            "Bodyweight Svend Press": "strength",
        })

        strength = filter_candidates(db, cands, training_intent="full_body",
                                     user_equipment=["Bodyweight"])
        assert [c["name"] for c in strength] == ["Bodyweight Svend Press"]

        self._reset_vocab()
        mobility = filter_candidates(db, cands, training_intent="mobility",
                                     user_equipment=["Bodyweight"])
        assert len(mobility) == 3, "a mobility request WANTS stretches"

    def test_gear_named_in_the_exercise_name_is_gated(self):
        """The library stores 'Trx Body-Up' as equipment='Bodyweight' — only the
        NAME reveals it needs straps, so column-level gating can't catch it."""
        from services.coach_exercise_quality import filter_candidates
        self._reset_vocab()
        db = self._db_with_categories({
            "Trx Body-Up": "strength", "Bodyweight Svend Press": "strength",
        })
        cands = [{"name": "Trx Body-Up", "equipment": "Bodyweight"},
                 {"name": "Bodyweight Svend Press", "equipment": "Bodyweight"}]

        no_straps = filter_candidates(db, cands, training_intent="chest",
                                      user_equipment=["Bodyweight"])
        assert [c["name"] for c in no_straps] == ["Bodyweight Svend Press"]

        self._reset_vocab()
        has_straps = filter_candidates(db, cands, training_intent="chest",
                                       user_equipment=["Bodyweight", "Suspension Trainer"])
        assert len(has_straps) == 2

    def test_conditioning_intent_keeps_plyometrics(self):
        """`_JUNK_RE` bans jump/burpee — right for an accessory slot, wrong for HIIT."""
        from services.coach_exercise_quality import filter_candidates
        self._reset_vocab()
        db = self._db_with_categories({
            "Tuck Jump": "plyometric", "Burpee": "cardio",
        })
        kept = filter_candidates(
            db, [{"name": "Tuck Jump"}, {"name": "Burpee"}],
            training_intent="hiit", user_equipment=["Bodyweight"],
        )
        assert len(kept) == 2


# ── row 99: Schedule must persist THE CARD'S workout, noon-anchored ──────────


@pytest.fixture
def schedule_client():
    from core.auth import get_current_user
    from api.v1 import chat_proposals

    app = FastAPI()
    app.include_router(chat_proposals.router, prefix="/api/v1/chat")
    user_id = str(uuid.uuid4())
    app.dependency_overrides[get_current_user] = lambda: {"id": user_id}
    return TestClient(app), user_id


def _mock_db(user_id, workout_id, **overrides):
    row = {
        "id": workout_id, "user_id": user_id, "name": "Quick Power Upper Body",
        "is_completed": False, "scheduled_date": "2026-07-28T17:00:00+00:00",
        "exercises_json": [{"name": "Push-Up"}, {"name": "Bench Dip"}],
    }
    row.update(overrides)
    db = MagicMock()
    db.get_workout.return_value = row
    db.update_workout.side_effect = lambda wid, payload: {**row, **payload}
    return db, row


class TestScheduleFromCard:
    HEADERS = {"X-User-Timezone": "America/Chicago"}

    def test_schedules_the_card_workout_at_local_noon(self, schedule_client):
        client, uid = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(uid, wid)

        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid, "target_date": "2026-08-02"},
                            headers=self.HEADERS)

        assert r.status_code == 200
        body = r.json()
        assert body["workout_id"] == wid, "must schedule the card's workout, not a new one"
        assert body["scheduled_local_date"] == "2026-08-02"
        # CDT is UTC-5 → local noon is 17:00Z. NOT 00:00Z.
        payload = db.update_workout.call_args[0][1]
        assert payload["scheduled_date"] == "2026-08-02T17:00:00+00:00"
        assert body["exercise_count"] == 2

    def test_defaults_to_tomorrow_in_the_users_timezone(self, schedule_client):
        from core.timezone_utils import get_user_today
        from datetime import date, timedelta

        client, uid = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(uid, wid)
        expected = (date.fromisoformat(get_user_today("America/Chicago"))
                    + timedelta(days=1)).isoformat()

        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid}, headers=self.HEADERS)

        assert r.status_code == 200
        assert r.json()["scheduled_local_date"] == expected

    def test_rejects_another_users_workout(self, schedule_client):
        client, _ = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(str(uuid.uuid4()), wid)     # owned by somebody else

        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid}, headers=self.HEADERS)
        assert r.status_code == 403
        db.update_workout.assert_not_called()

    def test_unknown_workout_is_404(self, schedule_client):
        client, _ = schedule_client
        db = MagicMock()
        db.get_workout.return_value = None
        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": str(uuid.uuid4())}, headers=self.HEADERS)
        assert r.status_code == 404

    def test_completed_workout_is_409(self, schedule_client):
        client, uid = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(uid, wid, is_completed=True)
        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid}, headers=self.HEADERS)
        assert r.status_code == 409

    def test_malformed_date_is_422(self, schedule_client):
        client, uid = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(uid, wid)
        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid, "target_date": "tomorrow"},
                            headers=self.HEADERS)
        assert r.status_code == 422

    def test_write_that_changes_nothing_is_not_reported_as_scheduled(self, schedule_client):
        client, uid = schedule_client
        wid = str(uuid.uuid4())
        db, _ = _mock_db(uid, wid)
        db.update_workout.side_effect = None
        db.update_workout.return_value = None

        with patch("api.v1.chat_proposals.get_supabase_db", return_value=db):
            r = client.post("/api/v1/chat/workout-card/schedule",
                            json={"workout_id": wid}, headers=self.HEADERS)
        assert r.status_code >= 500
