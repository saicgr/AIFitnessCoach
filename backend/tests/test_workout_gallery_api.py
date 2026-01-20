"""
Tests for Workout Gallery API endpoints.

Tests:
- Upload gallery image
- List gallery images
- Get single gallery image
- Delete gallery image
- Share to feed
- Track external share

Run with: pytest backend/tests/test_workout_gallery_api.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid
import base64

from main import app
from models.workout_gallery import TemplateType


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client for testing."""
    with patch('api.v1.workout_gallery.get_supabase_db') as mock:
        db_mock = MagicMock()
        client_mock = MagicMock()
        db_mock.client = client_mock
        mock.return_value = db_mock
        yield client_mock  # Return the client mock so tests can configure it


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_workout_log_id():
    """Sample workout log ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_image_id():
    """Sample gallery image ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_image_base64():
    """Sample base64 encoded image (1x1 red PNG)."""
    # Minimal valid PNG (1x1 red pixel)
    png_bytes = bytes([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
        0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,
        0x54, 0x08, 0xD7, 0x63, 0xF8, 0x00, 0x00, 0x00,
        0x01, 0x00, 0x01, 0x5C, 0xCD, 0xFF, 0xE8, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
    ])
    return base64.b64encode(png_bytes).decode('utf-8')


@pytest.fixture
def sample_workout_snapshot():
    """Sample workout snapshot data."""
    return {
        "workout_name": "Full Body Blast",
        "duration_seconds": 3600,
        "calories": 450,
        "total_volume_kg": 8500.0,
        "total_sets": 24,
        "total_reps": 180,
        "exercises_count": 8,
    }


@pytest.fixture
def sample_gallery_image(sample_user_id, sample_workout_log_id, sample_image_id):
    """Sample gallery image data."""
    return {
        "id": sample_image_id,
        "user_id": sample_user_id,
        "workout_log_id": sample_workout_log_id,
        "image_url": "https://supabase.co/storage/workout-recaps/test.png",
        "thumbnail_url": None,
        "template_type": "stats",
        "workout_name": "Full Body Blast",
        "duration_seconds": 3600,
        "calories": 450,
        "total_volume_kg": 8500.0,
        "total_sets": 24,
        "total_reps": 180,
        "exercises_count": 8,
        "user_photo_url": None,
        "prs_data": [],
        "achievements_data": [],
        "shared_to_feed": False,
        "shared_externally": False,
        "external_shares_count": 0,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }


# ============================================================
# UPLOAD IMAGE TESTS
# ============================================================

class TestUploadGalleryImage:
    """Test uploading gallery images."""

    def test_upload_image_success(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot, sample_image_id
    ):
        """Test successfully uploading a gallery image."""
        # Mock storage upload
        storage_mock = MagicMock()
        storage_mock.from_.return_value.upload.return_value = {"path": "test.png"}
        storage_mock.from_.return_value.get_public_url.return_value = "https://supabase.co/storage/test.png"
        mock_supabase.storage = storage_mock

        # Mock database insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "user_id": sample_user_id,
            "workout_log_id": sample_workout_log_id,
            "image_url": "https://supabase.co/storage/test.png",
            "template_type": "stats",
            "workout_name": "Full Body Blast",
            "duration_seconds": 3600,
            "calories": 450,
            "total_volume_kg": 8500.0,
            "total_sets": 24,
            "total_reps": 180,
            "exercises_count": 8,
            "prs_data": [],
            "achievements_data": [],
            "shared_to_feed": False,
            "shared_externally": False,
            "external_shares_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "stats",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
                "prs_data": [],
                "achievements_data": [],
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["image"]["id"] == sample_image_id
        assert data["message"] == "Image uploaded successfully"

    def test_upload_image_invalid_base64(
        self, mock_supabase, sample_user_id, sample_workout_log_id, sample_workout_snapshot
    ):
        """Test uploading with invalid base64 data."""
        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "stats",
                "image_base64": "not-valid-base64!!!",
                "workout_snapshot": sample_workout_snapshot,
            }
        )

        assert response.status_code == 400
        assert "Invalid base64" in response.json()["detail"]

    def test_upload_image_with_user_photo(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot, sample_image_id
    ):
        """Test uploading with optional user photo."""
        # Mock storage
        storage_mock = MagicMock()
        storage_mock.from_.return_value.upload.return_value = {"path": "test.png"}
        storage_mock.from_.return_value.get_public_url.return_value = "https://supabase.co/storage/test.png"
        mock_supabase.storage = storage_mock

        # Mock database insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "user_id": sample_user_id,
            "workout_log_id": sample_workout_log_id,
            "image_url": "https://supabase.co/storage/test.png",
            "template_type": "photo_overlay",
            "workout_name": "Full Body Blast",
            "duration_seconds": 3600,
            "calories": 450,
            "total_volume_kg": 8500.0,
            "total_sets": 24,
            "total_reps": 180,
            "exercises_count": 8,
            "user_photo_url": "https://supabase.co/storage/user_photo.png",
            "prs_data": [],
            "achievements_data": [],
            "shared_to_feed": False,
            "shared_externally": False,
            "external_shares_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "photo_overlay",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
                "user_photo_base64": sample_image_base64,
            }
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_upload_prs_template(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot, sample_image_id
    ):
        """Test uploading PRs template with achievement data."""
        storage_mock = MagicMock()
        storage_mock.from_.return_value.upload.return_value = {"path": "test.png"}
        storage_mock.from_.return_value.get_public_url.return_value = "https://supabase.co/storage/test.png"
        mock_supabase.storage = storage_mock

        prs_data = [
            {"exercise": "Bench Press", "weight_kg": 100, "pr_type": "weight"},
            {"exercise": "Squats", "weight_kg": 150, "pr_type": "weight"},
        ]

        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "user_id": sample_user_id,
            "workout_log_id": sample_workout_log_id,
            "image_url": "https://supabase.co/storage/test.png",
            "template_type": "prs",
            "workout_name": "Full Body Blast",
            "duration_seconds": 3600,
            "calories": 450,
            "total_volume_kg": 8500.0,
            "total_sets": 24,
            "total_reps": 180,
            "exercises_count": 8,
            "prs_data": prs_data,
            "achievements_data": [],
            "shared_to_feed": False,
            "shared_externally": False,
            "external_shares_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "prs",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
                "prs_data": prs_data,
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["image"]["template_type"] == "prs"


# ============================================================
# LIST GALLERY IMAGES TESTS
# ============================================================

class TestListGalleryImages:
    """Test listing gallery images."""

    def test_list_images_success(self, mock_supabase, sample_user_id, sample_gallery_image):
        """Test listing user's gallery images."""
        # Mock query with pagination
        query_mock = MagicMock()
        query_mock.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[sample_gallery_image],
            count=1
        )
        mock_supabase.table.return_value = query_mock

        response = client.get(f"/api/v1/workout-gallery/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 1
        assert len(data["images"]) == 1
        assert data["page"] == 1
        assert data["has_more"] is False

    def test_list_images_with_pagination(self, mock_supabase, sample_user_id, sample_gallery_image):
        """Test listing with pagination parameters."""
        query_mock = MagicMock()
        query_mock.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[sample_gallery_image],
            count=25
        )
        mock_supabase.table.return_value = query_mock

        response = client.get(
            f"/api/v1/workout-gallery/{sample_user_id}?page=2&page_size=10"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 2
        assert data["page_size"] == 10

    def test_list_images_filter_by_template(self, mock_supabase, sample_user_id, sample_gallery_image):
        """Test listing with template type filter."""
        query_mock = MagicMock()
        query_mock.select.return_value.eq.return_value.is_.return_value.order.return_value.eq.return_value.range.return_value.execute.return_value = MagicMock(
            data=[sample_gallery_image],
            count=1
        )
        mock_supabase.table.return_value = query_mock

        response = client.get(
            f"/api/v1/workout-gallery/{sample_user_id}?template_type=stats"
        )

        assert response.status_code == 200

    def test_list_images_empty(self, mock_supabase, sample_user_id):
        """Test listing when no images exist."""
        query_mock = MagicMock()
        query_mock.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[],
            count=0
        )
        mock_supabase.table.return_value = query_mock

        response = client.get(f"/api/v1/workout-gallery/{sample_user_id}")

        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 0
        assert data["images"] == []


# ============================================================
# GET SINGLE IMAGE TESTS
# ============================================================

class TestGetGalleryImage:
    """Test getting a single gallery image."""

    def test_get_image_success(self, mock_supabase, sample_user_id, sample_image_id, sample_gallery_image):
        """Test getting a single image by ID."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = sample_gallery_image

        response = client.get(
            f"/api/v1/workout-gallery/{sample_user_id}/{sample_image_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_image_id

    def test_get_image_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test getting non-existent image."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.get(
            f"/api/v1/workout-gallery/{sample_user_id}/{sample_image_id}"
        )

        assert response.status_code == 404
        assert "not found" in response.json()["detail"].lower()


# ============================================================
# DELETE IMAGE TESTS
# ============================================================

class TestDeleteGalleryImage:
    """Test deleting gallery images."""

    def test_delete_image_success(self, mock_supabase, sample_user_id, sample_image_id):
        """Test soft deleting an image."""
        # Mock ownership check
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = {
            "id": sample_image_id
        }

        # Mock update (soft delete)
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "deleted_at": datetime.now(timezone.utc).isoformat()
        }]

        response = client.delete(
            f"/api/v1/workout-gallery/{sample_image_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert "deleted" in data["message"].lower()

    def test_delete_image_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test deleting non-existent image."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.delete(
            f"/api/v1/workout-gallery/{sample_image_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404

    def test_delete_image_wrong_user(self, mock_supabase, sample_user_id, sample_image_id):
        """Test deleting image owned by different user."""
        other_user_id = str(uuid.uuid4())

        # Mock no match (user doesn't own this image)
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.delete(
            f"/api/v1/workout-gallery/{sample_image_id}?user_id={other_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# SHARE TO FEED TESTS
# ============================================================

class TestShareToFeed:
    """Test sharing images to social feed."""

    def test_share_to_feed_success(self, mock_supabase, sample_user_id, sample_image_id, sample_gallery_image):
        """Test sharing an image to the social feed."""
        activity_id = str(uuid.uuid4())

        # Mock image lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = sample_gallery_image

        # Mock activity creation
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": activity_id,
            "user_id": sample_user_id,
            "activity_type": "workout_recap_shared",
        }]

        # Mock gallery image update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(
            f"/api/v1/workout-gallery/{sample_image_id}/share-to-feed?user_id={sample_user_id}",
            json={
                "caption": "Check out my workout!",
                "visibility": "friends",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["activity_id"] == activity_id

    def test_share_to_feed_with_default_visibility(
        self, mock_supabase, sample_user_id, sample_image_id, sample_gallery_image
    ):
        """Test sharing with default visibility."""
        activity_id = str(uuid.uuid4())

        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = sample_gallery_image

        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": activity_id,
        }]

        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.post(
            f"/api/v1/workout-gallery/{sample_image_id}/share-to-feed?user_id={sample_user_id}",
            json={}
        )

        assert response.status_code == 200

    def test_share_to_feed_image_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test sharing non-existent image."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.post(
            f"/api/v1/workout-gallery/{sample_image_id}/share-to-feed?user_id={sample_user_id}",
            json={}
        )

        assert response.status_code == 404


# ============================================================
# TRACK EXTERNAL SHARE TESTS
# ============================================================

class TestTrackExternalShare:
    """Test tracking external shares (Instagram, etc.)."""

    def test_track_external_share_first_time(self, mock_supabase, sample_user_id, sample_image_id):
        """Test tracking first external share."""
        # Mock image lookup
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "external_shares_count": 0
        }

        # Mock update
        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.put(
            f"/api/v1/workout-gallery/{sample_image_id}/track-external-share?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["external_shares_count"] == 1

    def test_track_external_share_increment(self, mock_supabase, sample_user_id, sample_image_id):
        """Test incrementing external share count."""
        # Mock image with existing shares
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "external_shares_count": 5
        }

        mock_supabase.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [{}]

        response = client.put(
            f"/api/v1/workout-gallery/{sample_image_id}/track-external-share?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["external_shares_count"] == 6

    def test_track_external_share_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test tracking share for non-existent image."""
        mock_supabase.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.put(
            f"/api/v1/workout-gallery/{sample_image_id}/track-external-share?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# TEMPLATE TYPE VALIDATION TESTS
# ============================================================

class TestTemplateTypeValidation:
    """Test template type validation."""

    def test_valid_template_types(self):
        """Test all valid template types are accepted."""
        assert TemplateType.STATS.value == "stats"
        assert TemplateType.PRS.value == "prs"
        assert TemplateType.PHOTO_OVERLAY.value == "photo_overlay"
        assert TemplateType.MOTIVATIONAL.value == "motivational"

    def test_upload_with_invalid_template_type(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot
    ):
        """Test uploading with invalid template type."""
        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "invalid_type",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
            }
        )

        assert response.status_code == 422  # Validation error


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases and error handling."""

    def test_storage_failure_fallback(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot, sample_image_id
    ):
        """Test that storage failure uses placeholder URL."""
        # Mock storage to raise exception
        storage_mock = MagicMock()
        storage_mock.from_.return_value.upload.side_effect = Exception("Storage error")
        mock_supabase.storage = storage_mock

        # Mock database insert
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "user_id": sample_user_id,
            "workout_log_id": sample_workout_log_id,
            "image_url": "https://placeholder.supabase.co/storage/v1/object/public/workout-recaps/test.png",
            "template_type": "stats",
            "workout_name": "Full Body Blast",
            "duration_seconds": 3600,
            "calories": 450,
            "total_volume_kg": 8500.0,
            "total_sets": 24,
            "total_reps": 180,
            "exercises_count": 8,
            "prs_data": [],
            "achievements_data": [],
            "shared_to_feed": False,
            "shared_externally": False,
            "external_shares_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "stats",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
            }
        )

        # Should still succeed with placeholder URL
        assert response.status_code == 200

    def test_database_insert_failure(
        self, mock_supabase, sample_user_id, sample_workout_log_id,
        sample_image_base64, sample_workout_snapshot
    ):
        """Test handling database insert failure."""
        # Mock storage success
        storage_mock = MagicMock()
        storage_mock.from_.return_value.upload.return_value = {"path": "test.png"}
        storage_mock.from_.return_value.get_public_url.return_value = "https://supabase.co/test.png"
        mock_supabase.storage = storage_mock

        # Mock database insert failure
        mock_supabase.table.return_value.insert.return_value.execute.return_value.data = []

        response = client.post(
            f"/api/v1/workout-gallery/upload?user_id={sample_user_id}",
            json={
                "workout_log_id": sample_workout_log_id,
                "template_type": "stats",
                "image_base64": sample_image_base64,
                "workout_snapshot": sample_workout_snapshot,
            }
        )

        assert response.status_code == 500
        assert "Failed to save" in response.json()["detail"]

    def test_list_with_max_page_size(self, mock_supabase, sample_user_id):
        """Test that page_size is capped at 50."""
        query_mock = MagicMock()
        query_mock.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value = MagicMock(
            data=[],
            count=0
        )
        mock_supabase.table.return_value = query_mock

        response = client.get(
            f"/api/v1/workout-gallery/{sample_user_id}?page_size=100"
        )

        # Should be capped or rejected
        # Based on Query definition: page_size: int = Query(20, ge=1, le=50)
        assert response.status_code == 422  # Validation error for >50


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
