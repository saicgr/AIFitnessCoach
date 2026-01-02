"""
Tests for Audio Preferences API endpoints.

Tests CRUD operations for audio preferences including:
- Volume levels (master_volume, music_volume, voice_volume, sfx_volume)
- Audio ducking settings (duck_volume_level, enable_ducking)
- Other audio settings

All volume values should be in the range 0.0-1.0.

Run with: pytest backend/tests/test_audio_preferences.py -v
"""

import pytest
from unittest.mock import AsyncMock, MagicMock, patch
from datetime import datetime
from fastapi import HTTPException


# ─────────────────────────────────────────────────────────────────────────────
# FIXTURES
# ─────────────────────────────────────────────────────────────────────────────


@pytest.fixture
def mock_user_id():
    """Sample user ID for testing."""
    return "test-user-audio-123"


@pytest.fixture
def mock_user_data(mock_user_id):
    """Sample user data."""
    return {
        "id": mock_user_id,
        "email": "test@example.com",
        "name": "Test User",
    }


@pytest.fixture
def mock_audio_preferences(mock_user_id):
    """Sample audio preferences data with all fields."""
    return {
        "id": "audio-pref-123",
        "user_id": mock_user_id,
        "master_volume": 0.8,
        "music_volume": 0.5,
        "voice_volume": 1.0,
        "sfx_volume": 0.7,
        "duck_volume_level": 0.3,
        "enable_ducking": True,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }


@pytest.fixture
def default_audio_preferences(mock_user_id):
    """Default audio preferences for new user."""
    return {
        "id": "audio-pref-default",
        "user_id": mock_user_id,
        "master_volume": 1.0,
        "music_volume": 0.5,
        "voice_volume": 1.0,
        "sfx_volume": 0.8,
        "duck_volume_level": 0.3,
        "enable_ducking": True,
        "created_at": datetime.utcnow().isoformat(),
        "updated_at": datetime.utcnow().isoformat(),
    }


@pytest.fixture
def mock_supabase():
    """Mock Supabase client."""
    mock = MagicMock()
    return mock


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Helper Functions
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesHelpers:
    """Tests for audio preferences helper functions."""

    def test_get_default_preferences(self):
        """Test that default preferences have correct values."""
        try:
            from api.v1.audio_preferences import _get_default_preferences
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        user_id = "test-user-123"
        defaults = _get_default_preferences(user_id)

        # Check all defaults are in valid range
        assert defaults["user_id"] == user_id
        assert 0.0 <= defaults["master_volume"] <= 1.0
        assert 0.0 <= defaults["music_volume"] <= 1.0
        assert 0.0 <= defaults["voice_volume"] <= 1.0
        assert 0.0 <= defaults["sfx_volume"] <= 1.0
        assert 0.0 <= defaults["duck_volume_level"] <= 1.0
        assert isinstance(defaults["enable_ducking"], bool)

    def test_preferences_to_response(self, mock_audio_preferences):
        """Test conversion from database row to response model."""
        try:
            from api.v1.audio_preferences import _preferences_to_response
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        response = _preferences_to_response(mock_audio_preferences)

        assert response.id == mock_audio_preferences["id"]
        assert response.user_id == mock_audio_preferences["user_id"]
        assert response.master_volume == mock_audio_preferences["master_volume"]
        assert response.music_volume == mock_audio_preferences["music_volume"]
        assert response.voice_volume == mock_audio_preferences["voice_volume"]
        assert response.sfx_volume == mock_audio_preferences["sfx_volume"]
        assert response.duck_volume_level == mock_audio_preferences["duck_volume_level"]
        assert response.enable_ducking == mock_audio_preferences["enable_ducking"]

    def test_preferences_to_response_with_missing_fields(self):
        """Test conversion handles missing fields gracefully with defaults."""
        try:
            from api.v1.audio_preferences import _preferences_to_response
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        incomplete_data = {
            "id": "audio-pref-123",
            "user_id": "user-123",
            # Missing volume fields
        }

        response = _preferences_to_response(incomplete_data)

        # Should use defaults for missing fields
        assert response.master_volume == 1.0
        assert response.music_volume == 0.5
        assert response.voice_volume == 1.0
        assert response.sfx_volume == 0.8
        assert response.duck_volume_level == 0.3
        assert response.enable_ducking is True


# ─────────────────────────────────────────────────────────────────────────────
# UNIT TESTS: Request Models
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesModels:
    """Tests for audio preferences Pydantic models."""

    def test_audio_preferences_update_partial(self):
        """Test that update model accepts partial updates."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Only update one field
        update = AudioPreferencesUpdate(master_volume=0.5)
        data = update.model_dump(exclude_none=True)

        assert len(data) == 1
        assert data["master_volume"] == 0.5

    def test_audio_preferences_update_all_fields(self):
        """Test that update model accepts all fields."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        update = AudioPreferencesUpdate(
            master_volume=0.9,
            music_volume=0.6,
            voice_volume=0.8,
            sfx_volume=0.5,
            duck_volume_level=0.2,
            enable_ducking=False,
        )
        data = update.model_dump(exclude_none=True)

        assert len(data) == 6
        assert data["master_volume"] == 0.9
        assert data["music_volume"] == 0.6
        assert data["voice_volume"] == 0.8
        assert data["sfx_volume"] == 0.5
        assert data["duck_volume_level"] == 0.2
        assert data["enable_ducking"] is False

    def test_audio_preferences_update_empty(self):
        """Test that update model allows no fields (no-op update)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        update = AudioPreferencesUpdate()
        data = update.model_dump(exclude_none=True)

        assert len(data) == 0

    def test_audio_preferences_response_model(self):
        """Test AudioPreferencesResponse model validation."""
        try:
            from api.v1.audio_preferences import AudioPreferencesResponse
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        response = AudioPreferencesResponse(
            id="audio-pref-123",
            user_id="user-123",
            master_volume=0.8,
            music_volume=0.5,
            voice_volume=1.0,
            sfx_volume=0.7,
            duck_volume_level=0.3,
            enable_ducking=True,
            created_at="2025-01-01T00:00:00Z",
            updated_at="2025-01-01T00:00:00Z",
        )

        assert response.id == "audio-pref-123"
        assert response.master_volume == 0.8
        assert response.enable_ducking is True


# ─────────────────────────────────────────────────────────────────────────────
# VALIDATION TESTS: Volume Ranges
# ─────────────────────────────────────────────────────────────────────────────


class TestVolumeValidation:
    """Tests for volume value validation (0.0-1.0 range)."""

    def test_master_volume_valid_range(self):
        """Test that master_volume accepts valid values (0.0-1.0)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Valid values
        for volume in [0.0, 0.5, 1.0, 0.001, 0.999]:
            update = AudioPreferencesUpdate(master_volume=volume)
            assert update.master_volume == volume

    def test_master_volume_invalid_negative(self):
        """Test that master_volume rejects negative values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(master_volume=-0.1)

        assert "master_volume" in str(exc_info.value)

    def test_master_volume_invalid_over_one(self):
        """Test that master_volume rejects values greater than 1.0."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(master_volume=1.5)

        assert "master_volume" in str(exc_info.value)

    def test_music_volume_valid_range(self):
        """Test that music_volume accepts valid values (0.0-1.0)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        for volume in [0.0, 0.25, 0.75, 1.0]:
            update = AudioPreferencesUpdate(music_volume=volume)
            assert update.music_volume == volume

    def test_music_volume_invalid_negative(self):
        """Test that music_volume rejects negative values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(music_volume=-0.5)

    def test_music_volume_invalid_over_one(self):
        """Test that music_volume rejects values greater than 1.0."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(music_volume=2.0)

    def test_voice_volume_valid_range(self):
        """Test that voice_volume accepts valid values (0.0-1.0)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        for volume in [0.0, 0.5, 1.0]:
            update = AudioPreferencesUpdate(voice_volume=volume)
            assert update.voice_volume == volume

    def test_voice_volume_invalid_values(self):
        """Test that voice_volume rejects invalid values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(voice_volume=-1.0)

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(voice_volume=1.01)

    def test_sfx_volume_valid_range(self):
        """Test that sfx_volume accepts valid values (0.0-1.0)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        for volume in [0.0, 0.3, 0.8, 1.0]:
            update = AudioPreferencesUpdate(sfx_volume=volume)
            assert update.sfx_volume == volume

    def test_sfx_volume_invalid_values(self):
        """Test that sfx_volume rejects invalid values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(sfx_volume=-0.01)

        with pytest.raises(ValidationError):
            AudioPreferencesUpdate(sfx_volume=1.1)

    def test_duck_volume_level_valid_range(self):
        """Test that duck_volume_level accepts valid values (0.0-1.0)."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        for volume in [0.0, 0.3, 0.5, 1.0]:
            update = AudioPreferencesUpdate(duck_volume_level=volume)
            assert update.duck_volume_level == volume

    def test_duck_volume_level_invalid_negative(self):
        """Test that duck_volume_level rejects negative values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(duck_volume_level=-0.1)

        assert "duck_volume_level" in str(exc_info.value)

    def test_duck_volume_level_invalid_over_one(self):
        """Test that duck_volume_level rejects values greater than 1.0."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with pytest.raises(ValidationError) as exc_info:
            AudioPreferencesUpdate(duck_volume_level=1.5)

        assert "duck_volume_level" in str(exc_info.value)


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: GET Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestGetAudioPreferences:
    """Tests for GET /api/v1/audio-preferences/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_get_audio_preferences_returns_default_for_new_user(
        self, mock_user_id, mock_user_data, default_audio_preferences
    ):
        """Test that GET returns default preferences for new user without existing preferences."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists, but no preferences yet
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists check
                MagicMock(data=None),  # No existing preferences
            ]

            # Mock insert for creating defaults
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
                data=[default_audio_preferences]
            )

            result = await get_audio_preferences(mock_user_id)

            assert result.user_id == mock_user_id
            assert result.master_volume == 1.0  # Default value

    @pytest.mark.asyncio
    async def test_get_audio_preferences_returns_saved_preferences(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that GET returns saved preferences for existing user."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists and has preferences
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists check
                MagicMock(data=mock_audio_preferences),  # Existing preferences
            ]

            result = await get_audio_preferences(mock_user_id)

            assert result.user_id == mock_user_id
            assert result.master_volume == 0.8
            assert result.music_volume == 0.5
            assert result.voice_volume == 1.0
            assert result.sfx_volume == 0.7
            assert result.duck_volume_level == 0.3
            assert result.enable_ducking is True

    @pytest.mark.asyncio
    async def test_get_audio_preferences_user_not_found(self):
        """Test that GET returns 404 for non-existent user."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User not found
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )

            with pytest.raises(HTTPException) as exc_info:
                await get_audio_preferences("non-existent-user")

            assert exc_info.value.status_code == 404
            assert "User not found" in exc_info.value.detail

    @pytest.mark.asyncio
    async def test_get_audio_preferences_unauthenticated(self):
        """Test that GET returns 401 for unauthenticated request (no user_id)."""
        # This would typically be handled by auth middleware
        # but we test the endpoint behavior for empty/invalid user_id
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Empty user_id should fail validation or return 401
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )

            with pytest.raises(HTTPException) as exc_info:
                await get_audio_preferences("")

            assert exc_info.value.status_code in [400, 401, 404]


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: PUT Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestUpdateAudioPreferences:
    """Tests for PUT /api/v1/audio-preferences/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_update_all_preference_fields(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that PUT updates all preference fields."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Mock responses
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists check
                MagicMock(data={"id": "audio-pref-123"}),  # Preferences exist check
            ]

            updated_prefs = {
                **mock_audio_preferences,
                "master_volume": 0.6,
                "music_volume": 0.4,
                "voice_volume": 0.9,
                "sfx_volume": 0.5,
                "duck_volume_level": 0.2,
                "enable_ducking": False,
            }
            mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[updated_prefs]
            )

            update = AudioPreferencesUpdate(
                master_volume=0.6,
                music_volume=0.4,
                voice_volume=0.9,
                sfx_volume=0.5,
                duck_volume_level=0.2,
                enable_ducking=False,
            )
            result = await update_audio_preferences(mock_user_id, update)

            assert result.master_volume == 0.6
            assert result.music_volume == 0.4
            assert result.voice_volume == 0.9
            assert result.sfx_volume == 0.5
            assert result.duck_volume_level == 0.2
            assert result.enable_ducking is False

    @pytest.mark.asyncio
    async def test_update_partial_preferences(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that PUT allows partial updates."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),
                MagicMock(data={"id": "audio-pref-123"}),
            ]

            # Only update master_volume
            updated_prefs = {**mock_audio_preferences, "master_volume": 0.5}
            mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[updated_prefs]
            )

            update = AudioPreferencesUpdate(master_volume=0.5)
            result = await update_audio_preferences(mock_user_id, update)

            assert result.master_volume == 0.5
            # Other values should remain unchanged
            assert result.music_volume == mock_audio_preferences["music_volume"]

    @pytest.mark.asyncio
    async def test_update_returns_updated_preferences(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that PUT returns the updated preferences."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),
                MagicMock(data={"id": "audio-pref-123"}),
            ]

            updated_prefs = {**mock_audio_preferences, "enable_ducking": False}
            mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[updated_prefs]
            )

            update = AudioPreferencesUpdate(enable_ducking=False)
            result = await update_audio_preferences(mock_user_id, update)

            assert result.enable_ducking is False
            assert result.user_id == mock_user_id

    @pytest.mark.asyncio
    async def test_update_user_not_found(self):
        """Test that PUT returns 404 for non-existent user."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )

            update = AudioPreferencesUpdate(master_volume=0.5)

            with pytest.raises(HTTPException) as exc_info:
                await update_audio_preferences("non-existent-user", update)

            assert exc_info.value.status_code == 404

    @pytest.mark.asyncio
    async def test_update_creates_preferences_if_not_exist(
        self, mock_user_id, mock_user_data, default_audio_preferences
    ):
        """Test that PUT creates preferences if they don't exist yet."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists but no preferences
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists
                MagicMock(data=None),  # No preferences exist
            ]

            new_prefs = {**default_audio_preferences, "master_volume": 0.7}
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
                data=[new_prefs]
            )

            update = AudioPreferencesUpdate(master_volume=0.7)
            result = await update_audio_preferences(mock_user_id, update)

            assert result.master_volume == 0.7


# ─────────────────────────────────────────────────────────────────────────────
# INTEGRATION TESTS: POST Endpoint
# ─────────────────────────────────────────────────────────────────────────────


class TestCreateAudioPreferences:
    """Tests for POST /api/v1/audio-preferences/{user_id} endpoint."""

    @pytest.mark.asyncio
    async def test_create_preferences_for_new_user(
        self, mock_user_id, mock_user_data, default_audio_preferences
    ):
        """Test that POST creates preferences for new user."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            try:
                from api.v1.audio_preferences import create_audio_preferences, AudioPreferencesCreate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists, no preferences yet
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists
                MagicMock(data=None),  # No existing preferences
            ]

            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
                data=[default_audio_preferences]
            )

            create_data = AudioPreferencesCreate(
                master_volume=0.8,
                music_volume=0.5,
                voice_volume=1.0,
                sfx_volume=0.7,
            )
            result = await create_audio_preferences(mock_user_id, create_data)

            assert result.user_id == mock_user_id

    @pytest.mark.asyncio
    async def test_create_preferences_conflict_if_already_exist(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that POST returns 409 conflict if preferences already exist."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import create_audio_preferences, AudioPreferencesCreate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists and already has preferences
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),  # User exists
                MagicMock(data=mock_audio_preferences),  # Preferences already exist
            ]

            create_data = AudioPreferencesCreate(master_volume=0.8)

            with pytest.raises(HTTPException) as exc_info:
                await create_audio_preferences(mock_user_id, create_data)

            assert exc_info.value.status_code == 409
            assert "already exist" in exc_info.value.detail.lower()

    @pytest.mark.asyncio
    async def test_create_user_not_found(self):
        """Test that POST returns 404 for non-existent user."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import create_audio_preferences, AudioPreferencesCreate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.return_value = MagicMock(
                data=None
            )

            create_data = AudioPreferencesCreate(master_volume=0.8)

            with pytest.raises(HTTPException) as exc_info:
                await create_audio_preferences("non-existent-user", create_data)

            assert exc_info.value.status_code == 404


# ─────────────────────────────────────────────────────────────────────────────
# EDGE CASE TESTS
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesEdgeCases:
    """Tests for edge cases in audio preferences."""

    def test_volume_boundary_values(self):
        """Test that boundary values (0.0 and 1.0) are accepted."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Exact boundary values should work
        update_zero = AudioPreferencesUpdate(
            master_volume=0.0,
            music_volume=0.0,
            voice_volume=0.0,
            sfx_volume=0.0,
            duck_volume_level=0.0,
        )
        assert update_zero.master_volume == 0.0

        update_one = AudioPreferencesUpdate(
            master_volume=1.0,
            music_volume=1.0,
            voice_volume=1.0,
            sfx_volume=1.0,
            duck_volume_level=1.0,
        )
        assert update_one.master_volume == 1.0

    def test_missing_required_fields_in_response(self):
        """Test handling of missing required fields in database response."""
        try:
            from api.v1.audio_preferences import _preferences_to_response
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Minimal data - only required id and user_id
        minimal_data = {
            "id": "audio-123",
            "user_id": "user-123",
        }

        response = _preferences_to_response(minimal_data)

        # Should have default values for missing fields
        assert response.id == "audio-123"
        assert response.user_id == "user-123"
        assert 0.0 <= response.master_volume <= 1.0
        assert 0.0 <= response.duck_volume_level <= 1.0

    @pytest.mark.asyncio
    async def test_database_error_handling(self, mock_user_id, mock_user_data):
        """Test proper error handling when database fails."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase:

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # Simulate database error
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = Exception(
                "Database connection failed"
            )

            with pytest.raises(HTTPException) as exc_info:
                await get_audio_preferences(mock_user_id)

            assert exc_info.value.status_code == 500

    def test_enable_ducking_boolean_type(self):
        """Test that enable_ducking only accepts boolean values."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
            from pydantic import ValidationError
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Valid boolean values
        update_true = AudioPreferencesUpdate(enable_ducking=True)
        assert update_true.enable_ducking is True

        update_false = AudioPreferencesUpdate(enable_ducking=False)
        assert update_false.enable_ducking is False

        # Invalid non-boolean values should fail (Pydantic may coerce some)
        # Test with explicit type checking in the model

    def test_very_small_volume_values(self):
        """Test that very small but valid volume values are accepted."""
        try:
            from api.v1.audio_preferences import AudioPreferencesUpdate
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        update = AudioPreferencesUpdate(
            master_volume=0.001,
            music_volume=0.0001,
            voice_volume=0.00001,
        )
        assert update.master_volume == 0.001
        assert update.music_volume == 0.0001
        assert update.voice_volume == 0.00001


# ─────────────────────────────────────────────────────────────────────────────
# ACTIVITY LOGGING TESTS
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesLogging:
    """Tests for activity logging in audio preferences."""

    @pytest.mark.asyncio
    async def test_activity_logging_on_create(
        self, mock_user_id, mock_user_data, default_audio_preferences
    ):
        """Test that preference creation is logged for analytics."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock) as mock_log:

            try:
                from api.v1.audio_preferences import get_audio_preferences
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            # User exists, no preferences (will create defaults)
            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),
                MagicMock(data=None),
            ]
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value = MagicMock(
                data=[default_audio_preferences]
            )

            await get_audio_preferences(mock_user_id)

            # Verify logging was called
            mock_log.assert_called_once()
            call_kwargs = mock_log.call_args.kwargs
            assert call_kwargs["action"] == "audio_preferences_created"

    @pytest.mark.asyncio
    async def test_activity_logging_on_update(
        self, mock_user_id, mock_user_data, mock_audio_preferences
    ):
        """Test that preference updates are logged for analytics."""
        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock) as mock_log:

            try:
                from api.v1.audio_preferences import update_audio_preferences, AudioPreferencesUpdate
            except ImportError:
                pytest.skip("audio_preferences module not yet implemented")

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=mock_user_data),
                MagicMock(data={"id": "audio-pref-123"}),
            ]

            updated_prefs = {**mock_audio_preferences, "master_volume": 0.5}
            mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value = MagicMock(
                data=[updated_prefs]
            )

            update = AudioPreferencesUpdate(master_volume=0.5)
            await update_audio_preferences(mock_user_id, update)

            # Verify logging was called
            mock_log.assert_called_once()
            call_kwargs = mock_log.call_args.kwargs
            assert call_kwargs["action"] == "audio_preferences_updated"
            assert "master_volume" in call_kwargs["metadata"]["changed_fields"]


# ─────────────────────────────────────────────────────────────────────────────
# HTTP CLIENT TESTS (using FastAPI TestClient)
# ─────────────────────────────────────────────────────────────────────────────


class TestAudioPreferencesHTTPEndpoints:
    """Tests using FastAPI TestClient for HTTP-level testing."""

    def test_get_audio_preferences_http(self, client):
        """Test GET endpoint via HTTP client."""
        try:
            from api.v1 import audio_preferences as _  # noqa: F401
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        with patch("api.v1.audio_preferences.get_supabase") as mock_get_supabase, \
             patch("api.v1.audio_preferences.log_user_activity", new_callable=AsyncMock):

            mock_supabase = MagicMock()
            mock_get_supabase.return_value = mock_supabase

            user_data = {"id": "test-user", "email": "test@test.com"}
            prefs_data = {
                "id": "pref-123",
                "user_id": "test-user",
                "master_volume": 0.8,
                "music_volume": 0.5,
                "voice_volume": 1.0,
                "sfx_volume": 0.7,
                "duck_volume_level": 0.3,
                "enable_ducking": True,
                "created_at": "2025-01-01T00:00:00Z",
                "updated_at": "2025-01-01T00:00:00Z",
            }

            mock_supabase.client.table.return_value.select.return_value.eq.return_value.single.return_value.execute.side_effect = [
                MagicMock(data=user_data),
                MagicMock(data=prefs_data),
            ]

            response = client.get("/api/v1/audio-preferences/test-user")

            assert response.status_code == 200
            data = response.json()
            assert data["master_volume"] == 0.8

    def test_put_audio_preferences_invalid_volume_http(self, client):
        """Test PUT endpoint rejects invalid volume via HTTP client."""
        try:
            from api.v1 import audio_preferences as _  # noqa: F401
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Volume > 1.0 should be rejected
        response = client.put(
            "/api/v1/audio-preferences/test-user",
            json={"master_volume": 1.5}
        )

        assert response.status_code == 422  # Validation error

    def test_put_audio_preferences_negative_volume_http(self, client):
        """Test PUT endpoint rejects negative volume via HTTP client."""
        try:
            from api.v1 import audio_preferences as _  # noqa: F401
        except ImportError:
            pytest.skip("audio_preferences module not yet implemented")

        # Negative volume should be rejected
        response = client.put(
            "/api/v1/audio-preferences/test-user",
            json={"master_volume": -0.1}
        )

        assert response.status_code == 422  # Validation error


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
