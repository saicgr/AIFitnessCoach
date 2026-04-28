"""Verify JSON round-trip: export → json.loads → data survives."""
from __future__ import annotations

import json

from services.workout_export.to_json import EXPORT_SCHEMA_VERSION, export_json
from services.workout_import.canonical import CanonicalCardioRow, CanonicalSetRow


def test_envelope_has_version_and_counts(sample_strength_rows, sample_cardio_rows, test_user_id):
    blob = export_json(
        sample_strength_rows, sample_cardio_rows,
        user_id=test_user_id,
    )
    envelope = json.loads(blob.decode("utf-8"))
    assert envelope["version"] == EXPORT_SCHEMA_VERSION
    assert envelope["counts"]["strength"] == len(sample_strength_rows)
    assert envelope["counts"]["cardio"] == len(sample_cardio_rows)
    assert envelope["source"] == "zealova"
    assert envelope["user_id"] == str(test_user_id)


def test_roundtrip_strength_preserves_fields(sample_strength_rows, test_user_id):
    blob = export_json(sample_strength_rows, [], user_id=test_user_id)
    envelope = json.loads(blob.decode("utf-8"))
    # Reparse each row back into the canonical model. If any field drifts,
    # pydantic validation fails and the test surfaces the bad field.
    reparsed = [CanonicalSetRow(**r) for r in envelope["strength"]]
    assert len(reparsed) == len(sample_strength_rows)
    for original, round_tripped in zip(sample_strength_rows, reparsed):
        assert original.exercise_name_canonical == round_tripped.exercise_name_canonical
        assert original.weight_kg == round_tripped.weight_kg
        assert original.reps == round_tripped.reps
        assert original.performed_at == round_tripped.performed_at
        assert original.source_row_hash == round_tripped.source_row_hash


def test_roundtrip_cardio_preserves_fields(sample_cardio_rows, test_user_id):
    blob = export_json([], sample_cardio_rows, user_id=test_user_id)
    envelope = json.loads(blob.decode("utf-8"))
    reparsed = [CanonicalCardioRow(**r) for r in envelope["cardio"]]
    assert len(reparsed) == len(sample_cardio_rows)
    for original, rt in zip(sample_cardio_rows, reparsed):
        assert original.activity_type == rt.activity_type
        assert original.duration_seconds == rt.duration_seconds
        assert original.distance_m == rt.distance_m
        assert original.performed_at == rt.performed_at


def test_excluding_cardio_emits_empty_list(sample_strength_rows, test_user_id):
    blob = export_json(
        sample_strength_rows, [],
        include_strength=True,
        include_cardio=False,
        user_id=test_user_id,
    )
    envelope = json.loads(blob.decode("utf-8"))
    assert envelope["cardio"] == []
    assert envelope["counts"]["cardio"] == 0
    assert envelope["counts"]["strength"] == len(sample_strength_rows)


def test_empty_export_is_valid_json():
    blob = export_json([], [])
    envelope = json.loads(blob.decode("utf-8"))
    assert envelope["counts"] == {"strength": 0, "cardio": 0, "templates": 0}
