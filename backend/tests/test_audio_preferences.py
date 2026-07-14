"""
Tests for the Audio Preferences API (`api/v1/audio_preferences.py`).

Covers the three shipped endpoints:
- GET  /api/v1/audio-preferences/{user_id}
- PUT  /api/v1/audio-preferences/{user_id}
- POST /api/v1/audio-preferences/{user_id}

HISTORY — WHY THIS FILE WAS REWRITTEN (2026-07-13)
---------------------------------------------------
This file was originally written TDD-style (every test was wrapped in
`try: import ... except ImportError: pytest.skip("not yet implemented")`)
against a *proposed* audio model that was never built:

    master_volume / music_volume / voice_volume / sfx_volume / enable_ducking
    helpers `_get_default_preferences(user_id)` / `_preferences_to_response(row)`
    a model `AudioPreferencesCreate`
    a 404 "User not found" branch and a 409 "already exist" conflict branch

None of those names exist anywhere in the product: not in
`api/v1/audio_preferences.py`, not in the `audio_preferences` Postgres table
(whose real columns are `id, user_id, allow_background_music, tts_volume,
audio_ducking, duck_volume_level, mute_during_video, created_at, updated_at`),
and not in the Flutter client. The API that actually shipped models audio as a
*TTS-vs-background-music ducking* problem, not a game-style volume mixer.

So every test below has been retargeted onto the real, shipped contract while
preserving the ORIGINAL INTENT of each test. Where the intent maps onto a
different mechanism than the one originally imagined, the docstring says so
explicitly (what it used to assert / why that was retired / what guarantee it
protects now). No assertion was weakened, and the phantom-field tests were
converted into coverage of the *real* volume fields plus the model-level
guarantees they were reaching for (range bounds, boundary values, type
strictness) rather than dropped.

The other, mechanical reason every test failed: they called the async endpoints
directly without supplying `current_user`, so the `Depends(get_current_user)`
default object leaked into the body (`TypeError: 'Depends' object is not
subscriptable`), and they mocked a `.single()` Supabase chain the endpoints
never use (production uses `.select(...).eq(...).execute()` and reads
`result.data[0]`, precisely to avoid PostgREST's PGRST116-on-zero-rows).

Run with: pytest backend/tests/test_audio_preferences.py -v
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime

from fastapi import HTTPException
from pydantic import ValidationError

from main import app
from core.auth import get_current_user
from api.v1.audio_preferences import (
    AudioPreferences,
    AudioPreferencesResponse,
    AudioPreferencesUpdate,
    create_audio_preferences,
    get_audio_preferences,
    get_default_preferences,
    update_audio_preferences,
)

# The two float ("volume") fields the shipped model actually has. The original
# file hand-rolled one test per imagined volume field; parametrising over the
# real ones keeps that per-field rigor without inventing fields.
VOLUME_FIELDS = ["tts_volume", "duck_volume_level"]
BOOLEAN_FIELDS = ["allow_background_music", "audio_ducking", "mute_during_video"]


# ─────────────────────────────────────────────────────────────────────────────
# FIXTURES
# ─────────────────────────────────────────────────────────────────────────────


@pytest.fixture
def mock_user_id():
    """Sample user ID for testing (this is `users.id`, the backend id that
    `get_current_user()` returns — NOT the Supabase `auth_id`)."""
    return "test-user-audio-123"


@pytest.fixture
def current_user(mock_user_id):
    """The authenticated-user dict the real `get_current_user` dependency returns."""
    return {"id": mock_user_id, "email": "test@example.com"}


@pytest.fixture
def mock_audio_preferences(mock_user_id):
    """A full `audio_preferences` row, using the real column names."""
    return {
        "id": "audio-pref-123",
        "user_id": mock_user_id,
        "allow_background_music": True,
        "tts_volume": 0.8,
        "audio_ducking": True,
        "duck_volume_level": 0.3,
        "mute_during_video": False,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }


@pytest.fixture
def mock_supabase():
    """Patch `get_supabase` inside the endpoint module and hand back the client mock.

    Wires the exact call chains production uses:
        .table(t).select(cols).eq(...).execute()
        .table(t).update(data).eq(...).execute()
        .table(t).insert(data).execute()
    """
    with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:
        supabase = MagicMock()
        mock_get_supabase.return_value = supabase
        yield supabase


def set_select_result(supabase, rows):
    """Program the SELECT chain to return `rows` (a list, as PostgREST does)."""
    supabase.client.table.return_value.select.return_value.eq.return_value.execute.return_value = MagicMock(
        data=rows
    )


def set_update_result(supabase, rows):
    supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
        data=rows
    )


def set_insert_result(supabase, rows):
    supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
        data=rows
    )


def insert_payload(supabase):
    """The dict production passed to `.insert(...)`."""
    return supabase.client.table.return_value.insert.call_args.args[0]


def update_payload(supabase):
    """The dict production passed to `.update(...)`."""
    return supabase.client.table.return_value.update.call_args.args[0]


@pytest.fixture
def mock_activity_log():
    """Patch the activity logger so we can assert on analytics calls."""
    with patch(
        "api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock
    ) as mock_log:
        yield mock_log


@pytest.fixture
def authed_client(client, current_user):
    """FastAPI TestClient with the auth dependency satisfied."""

    async def _current_user():
        return current_user

    app.dependency_overrides[get_current_user] = _current_user
    yield client
    app.dependency_overrides.pop(get_current_user, None)


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Helper Functions
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesHelpers:
    """Tests for audio preferences helper functions."""

    def test_get_default_preferences(self):
        """Defaults are complete, in-range, and correctly typed.

        Originally called `_get_default_preferences(user_id)` and asserted a
        `user_id` key plus four volume sliders. The shipped helper is
        `get_default_preferences()` — it takes no user_id (the endpoints attach
        that themselves) and returns the five real settings. Same guarantee:
        every default the API can hand a brand-new user is valid.
        """
        defaults = get_default_preferences()

        assert set(defaults) == set(VOLUME_FIELDS) | set(BOOLEAN_FIELDS)

        for field in VOLUME_FIELDS:
            assert 0.0 <= defaults[field] <= 1.0
        for field in BOOLEAN_FIELDS:
            assert isinstance(defaults[field], bool)

        # The defaults must agree with the model's own declared defaults,
        # otherwise a POST with no body and a GET with no row would disagree.
        model_defaults = AudioPreferences().model_dump()
        assert defaults == model_defaults

    @pytest.mark.asyncio
    async def test_preferences_row_maps_to_response(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences
    ):
        """Every stored column is surfaced on the response, unmodified.

        Originally asserted a `_preferences_to_response(row)` helper. No such
        helper exists — the DB-row → response mapping lives inside the
        endpoints, so this now exercises that mapping through GET (the real
        code path), which is strictly stronger than testing a helper.
        """
        set_select_result(mock_supabase, [mock_audio_preferences])

        response = await get_audio_preferences(mock_user_id, current_user=current_user)

        assert response.user_id == mock_audio_preferences["user_id"]
        assert response.allow_background_music == mock_audio_preferences["allow_background_music"]
        assert response.tts_volume == mock_audio_preferences["tts_volume"]
        assert response.audio_ducking == mock_audio_preferences["audio_ducking"]
        assert response.duck_volume_level == mock_audio_preferences["duck_volume_level"]
        assert response.mute_during_video == mock_audio_preferences["mute_during_video"]
        assert response.created_at == mock_audio_preferences["created_at"]
        assert response.updated_at == mock_audio_preferences["updated_at"]

    @pytest.mark.asyncio
    async def test_preferences_row_with_missing_fields_falls_back_to_defaults(
        self, mock_user_id, current_user, mock_supabase
    ):
        """A partial row (column added after the row was written) still maps cleanly.

        Same intent as the original `_preferences_to_response` missing-fields
        test, retargeted onto the real mapping and the real default values.
        """
        set_select_result(mock_supabase, [{"user_id": mock_user_id}])

        response = await get_audio_preferences(mock_user_id, current_user=current_user)

        assert response.allow_background_music is True
        assert response.tts_volume == 0.8
        assert response.audio_ducking is True
        assert response.duck_volume_level == 0.3
        assert response.mute_during_video is False


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Request Models
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesModels:
    """Tests for audio preferences Pydantic models."""

    def test_audio_preferences_update_partial(self):
        """The update model accepts a single field (partial update)."""
        update = AudioPreferencesUpdate(tts_volume=0.5)
        data = update.model_dump(exclude_none=True)

        assert len(data) == 1
        assert data["tts_volume"] == 0.5

    def test_audio_preferences_update_all_fields(self):
        """The update model accepts every settable field at once."""
        update = AudioPreferencesUpdate(
            allow_background_music=False,
            tts_volume=0.9,
            audio_ducking=False,
            duck_volume_level=0.2,
            mute_during_video=True,
        )
        data = update.model_dump(exclude_none=True)

        assert len(data) == 5
        assert data["allow_background_music"] is False
        assert data["tts_volume"] == 0.9
        assert data["audio_ducking"] is False
        assert data["duck_volume_level"] == 0.2
        assert data["mute_during_video"] is True

    def test_audio_preferences_update_empty(self):
        """The update model allows no fields at all (the endpoint 400s on it)."""
        update = AudioPreferencesUpdate()
        data = update.model_dump(exclude_none=True)

        assert len(data) == 0

    def test_audio_preferences_response_model(self):
        """AudioPreferencesResponse validates and round-trips every field."""
        response = AudioPreferencesResponse(
            user_id="user-123",
            allow_background_music=True,
            tts_volume=0.8,
            audio_ducking=True,
            duck_volume_level=0.3,
            mute_during_video=False,
            created_at="2025-01-01T00:00:00Z",
            updated_at="2025-01-01T00:00:00Z",
        )

        assert response.user_id == "user-123"
        assert response.tts_volume == 0.8
        assert response.audio_ducking is True
        assert response.mute_during_video is False

    def test_audio_preferences_response_requires_user_id(self):
        """user_id is not optional — a response can never be user-ambiguous."""
        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesResponse(
                allow_background_music=True,
                tts_volume=0.8,
                audio_ducking=True,
                duck_volume_level=0.3,
                mute_during_video=False,
            )

        assert "user_id" in str(exc_info.value)


# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION TESTS: Volume Ranges
# ─────────────────────────────────────────────────────────────────────────────


class TestVolumeValidation:
    """Volume validation (0.0–1.0) on every real volume field.

    The original class had one trio of tests per imagined slider
    (master/music/voice/sfx). Those fields do not exist. The class now
    parametrises the identical checks — valid range, reject < 0.0, reject > 1.0,
    boundaries, non-numeric — across the volume fields that DO exist
    (`tts_volume`, `duck_volume_level`), on BOTH models that carry them
    (`AudioPreferencesUpdate` for PUT and `AudioPreferences` for POST), so no
    range guarantee the original file reached for is lost.
    """

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    @pytest.mark.parametrize("volume", [0.0, 0.001, 0.25, 0.5, 0.75, 0.999, 1.0])
    def test_volume_valid_range(self, field, volume):
        """Every value in [0.0, 1.0] is accepted and stored verbatim."""
        update = AudioPreferencesUpdate(**{field: volume})
        assert getattr(update, field) == volume

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    @pytest.mark.parametrize("volume", [-0.01, -0.1, -1.0])
    def test_volume_invalid_negative(self, field, volume):
        """Negative volumes are rejected, and the error names the field."""
        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(**{field: volume})

        assert field in str(exc_info.value)

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    @pytest.mark.parametrize("volume", [1.01, 1.1, 1.5, 2.0])
    def test_volume_invalid_over_one(self, field, volume):
        """Volumes above 1.0 are rejected, and the error names the field."""
        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(**{field: volume})

        assert field in str(exc_info.value)

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    def test_volume_rejects_non_numeric(self, field):
        """A non-numeric volume is rejected rather than coerced."""
        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(**{field: "loud"})

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    @pytest.mark.parametrize("volume", [-0.1, 1.5])
    def test_create_model_enforces_same_bounds(self, field, volume):
        """The POST body model (`AudioPreferences`) enforces the same 0.0–1.0 bounds.

        Without this, an out-of-range volume rejected by PUT could still be
        smuggled in through POST.
        """
        with pytest.raises(ValidationError) as exc_info:
            AudioPreferences(**{field: volume})

        assert field in str(exc_info.value)


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: GET Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestGetAudioPreferences:
    """Tests for GET /api/v1/audio-preferences/{user_id}."""

    @pytest.mark.asyncio
    async def test_get_audio_preferences_returns_default_for_new_user(
        self, mock_user_id, current_user, mock_supabase
    ):
        """A user with no stored row gets the defaults back.

        The original expected GET to *insert* a defaults row on first read. The
        shipped endpoint deliberately does not write on a read — it returns the
        defaults unpersisted (`created_at`/`updated_at` stay null until the user
        actually saves something). Both facts are asserted here so a future
        change to either half is caught.
        """
        set_select_result(mock_supabase, [])

        result = await get_audio_preferences(mock_user_id, current_user=current_user)

        assert result.user_id == mock_user_id
        assert result.allow_background_music is True
        assert result.tts_volume == 0.8
        assert result.audio_ducking is True
        assert result.duck_volume_level == 0.3
        assert result.mute_during_video is False
        assert result.created_at is None
        assert result.updated_at is None

        # A read must never write.
        mock_supabase.client.table.return_value.insert.assert_not_called()
        mock_supabase.client.table.return_value.update.assert_not_called()

    @pytest.mark.asyncio
    async def test_get_audio_preferences_returns_saved_preferences(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences
    ):
        """A user with a stored row gets that row back, not the defaults."""
        saved = {
            **mock_audio_preferences,
            "allow_background_music": False,
            "tts_volume": 0.4,
            "audio_ducking": False,
            "duck_volume_level": 0.1,
            "mute_during_video": True,
        }
        set_select_result(mock_supabase, [saved])

        result = await get_audio_preferences(mock_user_id, current_user=current_user)

        assert result.user_id == mock_user_id
        assert result.allow_background_music is False
        assert result.tts_volume == 0.4
        assert result.audio_ducking is False
        assert result.duck_volume_level == 0.1
        assert result.mute_during_video is True

        # It must read the caller's row, from the right table.
        mock_supabase.client.table.assert_called_with("audio_preferences")
        mock_supabase.client.table.return_value.select.return_value.eq.assert_called_with(
            "user_id", mock_user_id
        )

    @pytest.mark.asyncio
    async def test_get_audio_preferences_other_user_forbidden(
        self, current_user, mock_supabase
    ):
        """Reading someone else's preferences is refused with 403.

        Originally this asserted a 404 "User not found" branch. That branch does
        not exist and is unreachable by design: the endpoint is authenticated,
        so a nonexistent user can never reach it (`get_current_user` already
        401s on an unknown/absent user). The guarantee the original test was
        really protecting — *you cannot read preferences that are not yours* —
        is enforced by the `current_user["id"] != user_id` check, which is what
        is asserted now.
        """
        with pytest.raises(HTTPException) as exc_info:
            await get_audio_preferences(
                "somebody-elses-user-id", current_user=current_user
            )

        assert exc_info.value.status_code == 403
        assert "Access denied" in exc_info.value.detail

        # The refusal must happen before any DB read.
        mock_supabase.client.table.assert_not_called()

    def test_get_audio_preferences_unauthenticated(self, client):
        """An unauthenticated GET is rejected with 401.

        Originally this called the endpoint function with an empty user_id and
        hoped for 400/401/404 — which cannot test auth at all, since calling the
        function directly bypasses the dependency. Auth is only observable over
        HTTP, so this now issues a real request with no Authorization header.
        """
        response = client.get("/api/v1/audio-preferences/test-user-audio-123")

        assert response.status_code == 401


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: PUT Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestUpdateAudioPreferences:
    """Tests for PUT /api/v1/audio-preferences/{user_id}."""

    @pytest.mark.asyncio
    async def test_update_all_preference_fields(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """PUT writes every provided field and returns the new state."""
        set_select_result(mock_supabase, [mock_audio_preferences])

        updated_prefs = {
            **mock_audio_preferences,
            "allow_background_music": False,
            "tts_volume": 0.6,
            "audio_ducking": False,
            "duck_volume_level": 0.2,
            "mute_during_video": True,
        }
        set_update_result(mock_supabase, [updated_prefs])

        update = AudioPreferencesUpdate(
            allow_background_music=False,
            tts_volume=0.6,
            audio_ducking=False,
            duck_volume_level=0.2,
            mute_during_video=True,
        )
        result = await update_audio_preferences(
            mock_user_id, update, current_user=current_user
        )

        assert result.allow_background_music is False
        assert result.tts_volume == 0.6
        assert result.audio_ducking is False
        assert result.duck_volume_level == 0.2
        assert result.mute_during_video is True

        # Every field must actually have been sent to the DB, plus a fresh
        # updated_at — and it must be an UPDATE of the existing row, not an insert.
        written = update_payload(mock_supabase)
        assert written["allow_background_music"] is False
        assert written["tts_volume"] == 0.6
        assert written["audio_ducking"] is False
        assert written["duck_volume_level"] == 0.2
        assert written["mute_during_video"] is True
        assert "updated_at" in written
        mock_supabase.client.table.return_value.insert.assert_not_called()

    @pytest.mark.asyncio
    async def test_update_partial_preferences(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """A partial PUT writes ONLY the provided field and leaves the rest alone."""
        set_select_result(mock_supabase, [mock_audio_preferences])

        updated_prefs = {**mock_audio_preferences, "tts_volume": 0.5}
        set_update_result(mock_supabase, [updated_prefs])

        update = AudioPreferencesUpdate(tts_volume=0.5)
        result = await update_audio_preferences(
            mock_user_id, update, current_user=current_user
        )

        assert result.tts_volume == 0.5
        # Untouched values must survive.
        assert result.duck_volume_level == mock_audio_preferences["duck_volume_level"]
        assert result.allow_background_music == mock_audio_preferences["allow_background_music"]

        # Crucially: the un-provided fields must NOT be written (no null-clobber).
        written = update_payload(mock_supabase)
        assert set(written) == {"tts_volume", "updated_at"}

    @pytest.mark.asyncio
    async def test_update_returns_updated_preferences(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """PUT echoes back the row the DB returned, not the request body."""
        set_select_result(mock_supabase, [mock_audio_preferences])

        updated_prefs = {**mock_audio_preferences, "audio_ducking": False}
        set_update_result(mock_supabase, [updated_prefs])

        update = AudioPreferencesUpdate(audio_ducking=False)
        result = await update_audio_preferences(
            mock_user_id, update, current_user=current_user
        )

        assert result.audio_ducking is False
        assert result.user_id == mock_user_id

    @pytest.mark.asyncio
    async def test_update_other_user_forbidden(self, current_user, mock_supabase):
        """PUT refuses to write to someone else's preferences (403).

        Retargeted from the original 404 "User not found" expectation for the
        same reason as the GET case: the branch doesn't exist and is unreachable
        behind auth. The real guarantee — *you cannot write preferences that are
        not yours* — is what's asserted, including that nothing is written.
        """
        update = AudioPreferencesUpdate(tts_volume=0.5)

        with pytest.raises(HTTPException) as exc_info:
            await update_audio_preferences(
                "somebody-elses-user-id", update, current_user=current_user
            )

        assert exc_info.value.status_code == 403
        mock_supabase.client.table.assert_not_called()

    @pytest.mark.asyncio
    async def test_update_creates_preferences_if_not_exist(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """PUT upserts: with no existing row it inserts, filling defaults."""
        set_select_result(mock_supabase, [])

        new_prefs = {**mock_audio_preferences, "tts_volume": 0.7}
        set_insert_result(mock_supabase, [new_prefs])

        update = AudioPreferencesUpdate(tts_volume=0.7)
        result = await update_audio_preferences(
            mock_user_id, update, current_user=current_user
        )

        assert result.tts_volume == 0.7

        # The inserted row must carry the user, the requested value, and defaults
        # for everything the caller didn't send.
        written = insert_payload(mock_supabase)
        assert written["user_id"] == mock_user_id
        assert written["tts_volume"] == 0.7
        assert written["allow_background_music"] is True
        assert written["audio_ducking"] is True
        assert written["duck_volume_level"] == 0.3
        assert written["mute_during_video"] is False
        assert "created_at" in written and "updated_at" in written
        mock_supabase.client.table.return_value.update.assert_not_called()

    @pytest.mark.asyncio
    async def test_update_with_no_fields_rejected(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences
    ):
        """An empty PUT body is a 400, not a silent no-op write."""
        set_select_result(mock_supabase, [mock_audio_preferences])

        with pytest.raises(HTTPException) as exc_info:
            await update_audio_preferences(
                mock_user_id, AudioPreferencesUpdate(), current_user=current_user
            )

        assert exc_info.value.status_code == 400
        mock_supabase.client.table.return_value.update.assert_not_called()
        mock_supabase.client.table.return_value.insert.assert_not_called()


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: POST Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestCreateAudioPreferences:
    """Tests for POST /api/v1/audio-preferences/{user_id}."""

    @pytest.mark.asyncio
    async def test_create_preferences_for_new_user(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """POST with a body creates the row from that body.

        Originally imported `AudioPreferencesCreate`, which does not exist — the
        POST body model is `AudioPreferences`. Same intent.
        """
        set_select_result(mock_supabase, [])

        created = {
            **mock_audio_preferences,
            "allow_background_music": False,
            "tts_volume": 0.55,
            "mute_during_video": True,
        }
        set_insert_result(mock_supabase, [created])

        create_data = AudioPreferences(
            allow_background_music=False,
            tts_volume=0.55,
            mute_during_video=True,
        )
        result = await create_audio_preferences(
            mock_user_id, create_data, current_user=current_user
        )

        assert result.user_id == mock_user_id
        assert result.allow_background_music is False
        assert result.tts_volume == 0.55
        assert result.mute_during_video is True

        written = insert_payload(mock_supabase)
        assert written["user_id"] == mock_user_id
        assert written["allow_background_music"] is False
        assert written["tts_volume"] == 0.55
        assert written["mute_during_video"] is True
        # Unspecified fields fall back to the model defaults, never to null.
        assert written["audio_ducking"] is True
        assert written["duck_volume_level"] == 0.3

    @pytest.mark.asyncio
    async def test_create_preferences_with_no_body_uses_defaults(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """POST with no body creates a defaults row (the bootstrap call)."""
        set_select_result(mock_supabase, [])
        set_insert_result(mock_supabase, [mock_audio_preferences])

        result = await create_audio_preferences(
            mock_user_id, None, current_user=current_user
        )

        assert result.user_id == mock_user_id

        written = insert_payload(mock_supabase)
        assert written["user_id"] == mock_user_id
        for field, value in get_default_preferences().items():
            assert written[field] == value

    @pytest.mark.asyncio
    async def test_create_is_idempotent_when_preferences_already_exist(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """POST on an existing row returns it and does NOT create a duplicate.

        The original expected a 409 Conflict. The shipped endpoint is
        deliberately an idempotent get-or-create (its docstring: "If preferences
        already exist, returns the existing ones") — the client bootstraps
        preferences by POSTing unconditionally, so a 409 would be a false alarm.
        The guarantee the 409 was protecting — *a second POST must never
        overwrite or duplicate a user's saved settings* — is asserted directly:
        the caller's saved values come back untouched, and nothing is written.
        """
        set_select_result(mock_supabase, [mock_audio_preferences])

        result = await create_audio_preferences(
            mock_user_id, AudioPreferences(tts_volume=0.1), current_user=current_user
        )

        # The EXISTING values win — the POST body must not clobber them.
        assert result.tts_volume == mock_audio_preferences["tts_volume"] == 0.8
        assert result.user_id == mock_user_id

        mock_supabase.client.table.return_value.insert.assert_not_called()
        mock_supabase.client.table.return_value.update.assert_not_called()
        mock_activity_log.assert_not_called()

    @pytest.mark.asyncio
    async def test_create_other_user_forbidden(self, current_user, mock_supabase):
        """POST refuses to create preferences for another user (403).

        Retargeted from the original 404 "User not found" expectation — see
        `test_get_audio_preferences_other_user_forbidden`.
        """
        with pytest.raises(HTTPException) as exc_info:
            await create_audio_preferences(
                "somebody-elses-user-id",
                AudioPreferences(),
                current_user=current_user,
            )

        assert exc_info.value.status_code == 403
        mock_supabase.client.table.assert_not_called()


# ─────────────────────────────────────────────────────────────────────────────
# EDGE CASE TESTS
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesEdgeCases:
    """Tests for edge cases in audio preferences."""

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    @pytest.mark.parametrize("boundary", [0.0, 1.0])
    def test_volume_boundary_values(self, field, boundary):
        """The exact boundaries 0.0 (silent) and 1.0 (full) are inclusive."""
        update = AudioPreferencesUpdate(**{field: boundary})
        assert getattr(update, field) == boundary

        create = AudioPreferences(**{field: boundary})
        assert getattr(create, field) == boundary

    @pytest.mark.asyncio
    async def test_missing_fields_in_db_row_are_defaulted(
        self, mock_user_id, current_user, mock_supabase
    ):
        """A row carrying only user_id still produces a fully-valid response."""
        set_select_result(mock_supabase, [{"user_id": mock_user_id}])

        response = await get_audio_preferences(mock_user_id, current_user=current_user)

        assert response.user_id == mock_user_id
        assert 0.0 <= response.tts_volume <= 1.0
        assert 0.0 <= response.duck_volume_level <= 1.0
        assert isinstance(response.allow_background_music, bool)
        assert isinstance(response.audio_ducking, bool)
        assert isinstance(response.mute_during_video, bool)

    @pytest.mark.asyncio
    async def test_database_error_handling(
        self, mock_user_id, current_user, mock_supabase
    ):
        """A DB failure surfaces as a 500, not a leaked exception."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.execute.side_effect = Exception(
            "Database connection failed"
        )

        with pytest.raises(HTTPException) as exc_info:
            await get_audio_preferences(mock_user_id, current_user=current_user)

        assert exc_info.value.status_code == 500
        # The internal error text must not leak to the client.
        assert "Database connection failed" not in str(exc_info.value.detail)

    def test_boolean_fields_reject_non_boolean(self):
        """The boolean settings accept True/False and reject non-booleans.

        (Originally `enable_ducking`; the real field is `audio_ducking`, joined
        here by the other two booleans the model carries.)
        """
        for field in BOOLEAN_FIELDS:
            assert getattr(AudioPreferencesUpdate(**{field: True}), field) is True
            assert getattr(AudioPreferencesUpdate(**{field: False}), field) is False

            with pytest.raises(ValidationError):
                AudioPreferencesUpdate(**{field: "not-a-bool"})

            # 0/1 are the only ints Pydantic treats as bool; 2 is nonsense.
            with pytest.raises(ValidationError):
                AudioPreferencesUpdate(**{field: 2})

    def test_very_small_volume_values(self):
        """Very small but valid volumes are preserved exactly (no rounding to 0)."""
        update = AudioPreferencesUpdate(tts_volume=0.001, duck_volume_level=0.00001)

        assert update.tts_volume == 0.001
        assert update.duck_volume_level == 0.00001


# ─────────────────────────────────────────────────────────────────────────────
# ACTIVITY LOGGING TESTS
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesLogging:
    """Tests for activity logging in audio preferences."""

    @pytest.mark.asyncio
    async def test_activity_logging_on_create(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """Creating preferences is logged for analytics.

        The original drove this through GET (it assumed GET lazily created the
        row). GET does not create — POST does — so this now exercises POST, the
        endpoint that actually emits `audio_preferences_created`.
        """
        set_select_result(mock_supabase, [])
        set_insert_result(mock_supabase, [mock_audio_preferences])

        await create_audio_preferences(
            mock_user_id, AudioPreferences(), current_user=current_user
        )

        mock_activity_log.assert_called_once()
        call_kwargs = mock_activity_log.call_args.kwargs
        assert call_kwargs["action"] == "audio_preferences_created"
        assert call_kwargs["user_id"] == mock_user_id
        assert call_kwargs["status_code"] == 201
        assert call_kwargs["metadata"]["tts_volume"] == mock_audio_preferences["tts_volume"]

    @pytest.mark.asyncio
    async def test_activity_logging_on_update(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """Toggling background-music support is logged, with its previous value.

        The original asserted that ANY update logs, with a `changed_fields`
        metadata list. The shipped endpoint logs a narrower, deliberate signal:
        it records the background-music toggle (the setting that changes how the
        app behaves against Spotify/Apple Music) together with its old value, so
        support can see what a user flipped. That exact contract is asserted
        here; the companion test below pins the other half of it.
        """
        set_select_result(
            mock_supabase, [{**mock_audio_preferences, "allow_background_music": True}]
        )
        set_update_result(
            mock_supabase, [{**mock_audio_preferences, "allow_background_music": False}]
        )

        update = AudioPreferencesUpdate(allow_background_music=False)
        await update_audio_preferences(mock_user_id, update, current_user=current_user)

        mock_activity_log.assert_called_once()
        call_kwargs = mock_activity_log.call_args.kwargs
        assert call_kwargs["action"] == "audio_preferences_updated"
        assert call_kwargs["user_id"] == mock_user_id
        assert call_kwargs["metadata"]["allow_background_music"] is False
        assert call_kwargs["metadata"]["previous_value"] is True
        assert call_kwargs["message"] == "Disabled background music support"

    @pytest.mark.asyncio
    async def test_activity_logging_skipped_when_background_music_unchanged(
        self, mock_user_id, current_user, mock_supabase, mock_audio_preferences,
        mock_activity_log,
    ):
        """A no-op toggle does not spam the activity log.

        Pins the other half of the logging contract: the log fires on a CHANGE
        to `allow_background_music`, not on every PUT (a volume-slider drag
        would otherwise write an activity row per frame).
        """
        set_select_result(
            mock_supabase, [{**mock_audio_preferences, "allow_background_music": True}]
        )
        set_update_result(mock_supabase, [mock_audio_preferences])

        # Same value as stored → no change → no log.
        update = AudioPreferencesUpdate(allow_background_music=True, tts_volume=0.42)
        await update_audio_preferences(mock_user_id, update, current_user=current_user)

        mock_activity_log.assert_not_called()


# ─────────────────────────────────────────────────────────────────────────────
# HTTP CLIENT TESTS (using FastAPI TestClient)
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesHTTPEndpoints:
    """Tests using FastAPI TestClient for HTTP-level testing."""

    def test_get_audio_preferences_http(
        self, authed_client, mock_user_id, mock_supabase, mock_audio_preferences
    ):
        """GET returns 200 and the stored preferences over HTTP."""
        set_select_result(mock_supabase, [mock_audio_preferences])

        response = authed_client.get(f"/api/v1/audio-preferences/{mock_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["user_id"] == mock_user_id
        assert data["tts_volume"] == 0.8
        assert data["allow_background_music"] is True
        assert data["duck_volume_level"] == 0.3

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    def test_put_audio_preferences_invalid_volume_http(
        self, authed_client, mock_user_id, mock_supabase, field
    ):
        """PUT rejects a volume above 1.0 with 422 before touching the DB."""
        response = authed_client.put(
            f"/api/v1/audio-preferences/{mock_user_id}",
            json={field: 1.5},
        )

        assert response.status_code == 422
        mock_supabase.client.table.assert_not_called()

    @pytest.mark.parametrize("field", VOLUME_FIELDS)
    def test_put_audio_preferences_negative_volume_http(
        self, authed_client, mock_user_id, mock_supabase, field
    ):
        """PUT rejects a negative volume with 422 before touching the DB."""
        response = authed_client.put(
            f"/api/v1/audio-preferences/{mock_user_id}",
            json={field: -0.1},
        )

        assert response.status_code == 422
        mock_supabase.client.table.assert_not_called()

    def test_put_audio_preferences_other_user_http(
        self, authed_client, mock_supabase, mock_audio_preferences
    ):
        """PUT at another user's path is 403 over HTTP, and writes nothing."""
        response = authed_client.put(
            "/api/v1/audio-preferences/somebody-elses-user-id",
            json={"tts_volume": 0.5},
        )

        assert response.status_code == 403
        mock_supabase.client.table.assert_not_called()


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
