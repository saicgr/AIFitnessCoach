"""
Unit tests for AiExerciseExtractor + the shared duplicate-detection helper.

Gemini is mocked at the `gemini_generate_with_retry` boundary. S3 / ffmpeg are
stubbed so tests run offline.

Run with:
  cd backend && pytest tests/test_ai_exercise_extractor.py -v
"""
from __future__ import annotations

import json
from types import SimpleNamespace
from unittest.mock import AsyncMock, MagicMock, patch

import pytest


# ---------------------------------------------------------------- helpers


def _gemini_json(payload):
    return SimpleNamespace(text=json.dumps(payload))


def _hip_thrust_payload():
    # Exactly what Gemini is expected to return for "barbell hip thrust"
    return {
        "name": "Barbell Hip Thrust",
        "description": "Hip-dominant compound glute builder.",
        "instructions": [
            "Sit with upper back against a bench.",
            "Roll a loaded barbell over your hips.",
            "Drive through heels, extending hips until thighs are parallel.",
            "Pause at lockout, squeeze glutes, then lower under control.",
        ],
        "body_part": "glutes",
        "target_muscles": ["glutes", "hamstrings"],
        "secondary_muscles": ["core"],
        "equipment": "barbell",
        "exercise_type": "strength",
        "movement_type": "dynamic",
        "difficulty_level": "intermediate",
        "default_sets": 4,
        "default_reps": 10,
        "default_duration_seconds": None,
        "default_rest_seconds": 90,
        "is_warmup_suitable": False,
        "is_stretch_suitable": False,
        "is_cooldown_suitable": False,
    }


# ---------------------------------------------------------------- text source


@pytest.mark.asyncio
async def test_extract_from_text_matches_schema():
    from services.ai_exercise_extractor import AiExerciseExtractor

    ext = AiExerciseExtractor(vision_service=None)

    with patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json(_hip_thrust_payload())),
    ):
        payload = await ext.extract_from_text("barbell hip thrust")

    assert payload["name"] == "Barbell Hip Thrust"
    assert "glutes" in payload["target_muscles"]
    assert payload["equipment"] == "barbell"
    assert payload["default_sets"] == 4
    assert payload["default_reps"] == 10
    assert payload["default_duration_seconds"] is None


@pytest.mark.asyncio
async def test_extract_from_text_cable_row_equipment():
    """seated cable row should end up with equipment='cable'."""
    from services.ai_exercise_extractor import AiExerciseExtractor

    ext = AiExerciseExtractor(vision_service=None)

    fake = {
        "name": "Seated Cable Row",
        "description": "Horizontal pull for mid-back thickness.",
        "instructions": ["Sit at the cable machine.", "Pull handle to waist.", "Return slowly."],
        "body_part": "back",
        "target_muscles": ["back", "biceps"],
        "secondary_muscles": ["forearms"],
        "equipment": "cable",
        "exercise_type": "strength",
        "movement_type": "dynamic",
        "difficulty_level": "beginner",
        "default_sets": 3,
        "default_reps": 12,
        "default_duration_seconds": None,
        "default_rest_seconds": 60,
        "is_warmup_suitable": False,
        "is_stretch_suitable": False,
        "is_cooldown_suitable": False,
    }

    with patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json(fake)),
    ):
        payload = await ext.extract_from_text("seated cable row neutral grip")

    assert payload["equipment"] == "cable"
    assert "back" in payload["target_muscles"]


@pytest.mark.asyncio
async def test_extract_from_text_empty_input_raises():
    from services.ai_exercise_extractor import AiExerciseExtractor

    ext = AiExerciseExtractor(vision_service=None)
    with pytest.raises(ValueError):
        await ext.extract_from_text("   ")


@pytest.mark.asyncio
async def test_extract_from_text_gemini_empty_raises():
    from services.ai_exercise_extractor import AiExerciseExtractor

    ext = AiExerciseExtractor(vision_service=None)
    with patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=SimpleNamespace(text="")),
    ):
        with pytest.raises(ValueError):
            await ext.extract_from_text("bench press")


# ---------------------------------------------------------------- photo source


@pytest.mark.asyncio
async def test_extract_from_photo_with_bytes():
    from services.ai_exercise_extractor import AiExerciseExtractor

    ext = AiExerciseExtractor(vision_service=None)

    with patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json(_hip_thrust_payload())),
    ):
        payload = await ext.extract_from_photo(image_bytes=b"\xff\xd8\xff\xe0fake_jpeg")

    assert payload["name"] == "Barbell Hip Thrust"
    assert payload["equipment"] == "barbell"


@pytest.mark.asyncio
async def test_extract_from_photo_downloads_from_s3():
    from services.ai_exercise_extractor import AiExerciseExtractor

    vs = MagicMock()
    vs._s3_client = MagicMock()
    vs._bucket = "fake-bucket"
    # The extractor stores these attributes from the vision_service in __init__
    ext = AiExerciseExtractor(vision_service=vs)
    ext._s3_client.get_object = MagicMock(
        return_value={"Body": MagicMock(read=MagicMock(return_value=b"\xff\xd8ffakebytes"))}
    )

    with patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(return_value=_gemini_json(_hip_thrust_payload())),
    ):
        payload = await ext.extract_from_photo(s3_key="custom-exercises/u1/photo.jpg")

    assert payload["name"] == "Barbell Hip Thrust"
    ext._s3_client.get_object.assert_called_once()


# ---------------------------------------------------------------- video source


@pytest.mark.asyncio
async def test_extract_from_video_merges_frames():
    from services.ai_exercise_extractor import AiExerciseExtractor

    vs = MagicMock()
    vs._s3_client = MagicMock()
    vs._bucket = "fake"
    ext = AiExerciseExtractor(vision_service=vs)
    ext._s3_client.get_object = MagicMock(
        return_value={"Body": MagicMock(read=MagicMock(return_value=b"fakevideobytes"))}
    )

    # 3 fake keyframes → 3 Gemini calls w/ slightly different confidences.
    frame_results = [
        {**_hip_thrust_payload(), "frame_confidence": 0.7},
        {**_hip_thrust_payload(), "frame_confidence": 0.9},
        {**_hip_thrust_payload(), "frame_confidence": 0.5},
    ]
    responses = [_gemini_json(r) for r in frame_results]

    with patch(
        "services.ai_exercise_extractor.extract_key_frames",
        new=AsyncMock(return_value=[(b"\xff\xd8f1", "image/jpeg"),
                                    (b"\xff\xd8f2", "image/jpeg"),
                                    (b"\xff\xd8f3", "image/jpeg")]),
    ), patch(
        "services.ai_exercise_extractor.gemini_generate_with_retry",
        new=AsyncMock(side_effect=responses),
    ):
        payload = await ext.extract_from_video(s3_key="u1/video.mp4", num_frames=3)

    assert payload["name"] == "Barbell Hip Thrust"
    assert payload["equipment"] == "barbell"
    assert "keyframe_confidences" in payload
    assert len(payload["keyframe_confidences"]) == 3


# ---------------------------------------------------------------- duplicate detection


@pytest.mark.asyncio
async def test_duplicate_detection_returns_existing_row():
    """`_save_imported_exercise` should return the existing row with
    duplicate=True when a row with the same (user_id, name) already exists."""
    from api.v1.custom_exercises import _save_imported_exercise

    payload = _hip_thrust_payload()
    existing_row = {**payload, "id": "existing-uuid", "user_id": "u1"}

    # Build a mock db whose `.ilike()` query resolves to the existing row.
    db = MagicMock()
    chain = db.client.table.return_value.select.return_value.eq.return_value.ilike.return_value.limit.return_value
    chain.execute.return_value = SimpleNamespace(data=[existing_row])

    row, rag_indexed, duplicate = await _save_imported_exercise(db, "u1", payload)

    assert duplicate is True
    assert rag_indexed is False
    assert row["id"] == "existing-uuid"


@pytest.mark.asyncio
async def test_new_exercise_inserts_and_indexes():
    from api.v1.custom_exercises import _save_imported_exercise

    payload = _hip_thrust_payload()
    inserted = {**payload, "id": "new-uuid", "user_id": "u1"}

    db = MagicMock()
    # duplicate check: empty
    db.client.table.return_value.select.return_value.eq.return_value.ilike.return_value.limit.return_value.execute.return_value = SimpleNamespace(data=[])
    # insert returns the new row
    db.client.table.return_value.insert.return_value.execute.return_value = SimpleNamespace(data=[inserted])

    mock_rag = MagicMock()
    mock_rag.index_custom_exercise = AsyncMock(return_value=True)

    with patch(
        "api.v1.custom_exercises.get_exercise_rag_service",
        return_value=mock_rag,
    ):
        row, rag_indexed, duplicate = await _save_imported_exercise(db, "u1", payload)

    assert duplicate is False
    assert rag_indexed is True
    assert row["id"] == "new-uuid"
    mock_rag.index_custom_exercise.assert_awaited_once()
