"""
Template player smoke test.

We stub out Supabase with an in-memory dict so the test runs offline. The
fixture simulates an active Wendler template with the user's squat 1RM at
180 kg; we expect the template player to return a workout with plate-rounded
weights.
"""
from __future__ import annotations

import pytest
from uuid import UUID

from services.workout_generation import template_player


_TEMPLATE_ROW = {
    "id": "00000000-0000-0000-0000-000000000001",
    "user_id": "11111111-1111-1111-1111-111111111111",
    "source_app": "wendler_531",
    "program_name": "5/3/1",
    "program_creator": "Jim Wendler",
    "program_version": None,
    "unit_hint": "kg",
    "one_rm_inputs": {"squat_kg": 180.0},
    "training_max_factor": 0.9,
    "rounding_multiple_kg": 2.5,
    "active": True,
    "current_week": 1,
    "current_day": 1,
    "notes": "Wendler 5/3/1",
    "raw_prescription": {
        "weeks": [
            {
                "week_number": 1,
                "label": None,
                "days": [
                    {
                        "day_number": 1,
                        "day_label": "Back Squat Day",
                        "exercises": [
                            {
                                "order": 0,
                                "exercise_name_raw": "Back Squat",
                                "exercise_name_canonical": None,
                                "warmup_set_count": 0,
                                "sets": [
                                    {
                                        "order": 0,
                                        "set_type": "working",
                                        "rep_target": {
                                            "min": 5, "max": 5, "amrap_last": False,
                                        },
                                        "load_prescription": {
                                            "kind": "percent_tm",
                                            "value_min": 0.65,
                                            "value_max": 0.65,
                                            "reference_1rm_exercise": "back_squat",
                                        },
                                    },
                                    {
                                        "order": 1,
                                        "set_type": "amrap",
                                        "rep_target": {
                                            "min": 5, "max": 99, "amrap_last": True,
                                        },
                                        "load_prescription": {
                                            "kind": "percent_tm",
                                            "value_min": 0.85,
                                            "value_max": 0.85,
                                            "reference_1rm_exercise": "back_squat",
                                        },
                                    },
                                ],
                            }
                        ],
                    }
                ],
            }
        ]
    },
}


class _FakeExecResult:
    def __init__(self, data):
        self.data = data


class _FakeQuery:
    def __init__(self, data):
        self._data = data
        self._filters: dict[str, str] = {}

    def select(self, *a, **kw):
        return self

    def eq(self, key, val):
        self._filters[key] = val
        return self

    def ilike(self, key, val):
        self._filters[key] = val.lower()
        return self

    def order(self, *a, **kw):
        return self

    def limit(self, n):
        return self

    def execute(self):
        # Minimal dispatch: templates table vs strength_records.
        if self._data is _TEMPLATE_ROW:
            # Only return when filters ask for the active row.
            if self._filters.get("active") is True:
                return _FakeExecResult([_TEMPLATE_ROW])
            return _FakeExecResult([])
        return _FakeExecResult(self._data)


class _FakeClient:
    def __init__(self, templates, strength_records):
        self._templates = templates
        self._strength = strength_records

    def table(self, name):
        if name == "workout_program_templates":
            return _FakeQuery(_TEMPLATE_ROW)
        if name == "strength_records":
            return _FakeQuery(self._strength)
        return _FakeQuery([])


@pytest.mark.asyncio
async def test_template_player_resolves_percent_tm(monkeypatch):
    """180 kg 1RM → 162 kg TM (factor 0.9).
    65% × 162 = 105.3 → rounded to 105 kg.
    85% × 162 = 137.7 → rounded to 137.5 kg.
    """
    fake_client = _FakeClient(
        templates=[_TEMPLATE_ROW],
        strength_records=[{"estimated_1rm": 180.0}],
    )
    monkeypatch.setattr(template_player, "get_supabase", lambda: fake_client)

    user_id = UUID("11111111-1111-1111-1111-111111111111")
    workout = await template_player.plan_workout_from_template(user_id=user_id)
    assert workout is not None
    assert workout.name.startswith("5/3/1 — Back Squat Day")
    assert len(workout.exercises) == 1
    ex = workout.exercises[0]
    assert ex.name == "Back Squat"
    assert ex.sets == 2
    # First set @ 65% of TM.
    t0 = ex.set_targets[0]
    assert t0.target_weight_kg == pytest.approx(105.0, abs=0.1)
    # AMRAP set @ 85% of TM.
    t1 = ex.set_targets[1]
    assert t1.target_weight_kg == pytest.approx(137.5, abs=0.1)


@pytest.mark.asyncio
async def test_template_player_none_when_no_active(monkeypatch):
    """No active template → returns None (caller falls through)."""
    class _EmptyQuery(_FakeQuery):
        def execute(self):
            return _FakeExecResult([])

    class _EmptyClient:
        def table(self, name):
            return _EmptyQuery([])

    monkeypatch.setattr(template_player, "get_supabase", lambda: _EmptyClient())

    user_id = UUID("11111111-1111-1111-1111-111111111111")
    workout = await template_player.plan_workout_from_template(user_id=user_id)
    assert workout is None
