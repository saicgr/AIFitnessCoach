"""
Tests for Stats Gallery API endpoints.

Tests:
- Upload stats image
- List stats images
- Get single stats image
- Delete stats image
- Share to feed
- Track external share

Run with: pytest backend/tests/test_stats_gallery_api.py -v
"""

import pytest
from fastapi.testclient import TestClient
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone, date
import uuid
import base64

from main import app


client = TestClient(app)


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_supabase():
    """Mock Supabase client for testing."""
    with patch('api.v1.stats_gallery.get_supabase_db') as mock:
        supabase_mock = MagicMock()
        mock.return_value = supabase_mock
        yield supabase_mock


@pytest.fixture
def sample_user_id():
    """Sample user ID for testing."""
    return str(uuid.uuid4())


@pytest.fixture
def sample_image_id():
    """Sample stats gallery image ID for testing."""
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
def sample_stats_snapshot():
    """Sample stats snapshot data."""
    return {
        "total_workouts": 42,
        "weekly_completed": 4,
        "weekly_goal": 5,
        "current_streak": 7,
        "longest_streak": 14,
        "total_time_minutes": 1800,
        "total_volume_kg": 85000.0,
        "total_calories": 12500,
        "date_range_label": "Last 3 months",
    }


@pytest.fixture
def sample_stats_gallery_image(sample_user_id, sample_image_id):
    """Sample stats gallery image data."""
    return {
        "id": sample_image_id,
        "user_id": sample_user_id,
        "image_url": "data:image/png;base64,abc123",
        "thumbnail_url": None,
        "template_type": "overview",
        "stats_snapshot": {
            "total_workouts": 42,
            "current_streak": 7,
        },
        "date_range_start": "2024-10-01",
        "date_range_end": "2025-01-01",
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

class TestUploadStatsImage:
    """Test uploading stats images."""

    def test_upload_image_success(
        self, mock_supabase, sample_user_id, sample_image_base64,
        sample_stats_snapshot, sample_image_id
    ):
        """Test successfully uploading a stats image."""
        # Mock database insert
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": sample_image_id,
            "user_id": sample_user_id,
            "image_url": f"data:image/png;base64,{sample_image_base64}",
            "template_type": "overview",
            "stats_snapshot": sample_stats_snapshot,
            "date_range_start": "2024-10-01",
            "date_range_end": "2025-01-01",
            "prs_data": [],
            "achievements_data": [],
            "shared_to_feed": False,
            "shared_externally": False,
            "external_shares_count": 0,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }]

        response = client.post(
            f"/api/v1/stats-gallery/upload?user_id={sample_user_id}",
            json={
                "template_type": "overview",
                "image_base64": sample_image_base64,
                "stats_snapshot": sample_stats_snapshot,
                "date_range_start": "2024-10-01",
                "date_range_end": "2025-01-01",
            }
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["image"]["id"] == sample_image_id
        assert data["image"]["template_type"] == "overview"

    def test_upload_image_invalid_base64(self, mock_supabase, sample_user_id):
        """Test uploading with invalid base64 returns error."""
        response = client.post(
            f"/api/v1/stats-gallery/upload?user_id={sample_user_id}",
            json={
                "template_type": "overview",
                "image_base64": "not-valid-base64!!!",
                "stats_snapshot": {},
            }
        )

        assert response.status_code == 400
        assert "Invalid base64" in response.json()["detail"]

    def test_upload_image_all_template_types(
        self, mock_supabase, sample_user_id, sample_image_base64
    ):
        """Test uploading with all valid template types."""
        for template_type in ["overview", "achievements", "prs"]:
            mock_supabase.client.table.return_value.insert.return_value.execute.return_value.data = [{
                "id": str(uuid.uuid4()),
                "user_id": sample_user_id,
                "image_url": "data:image/png;base64,test",
                "template_type": template_type,
                "stats_snapshot": {},
                "prs_data": [],
                "achievements_data": [],
                "shared_to_feed": False,
                "shared_externally": False,
                "external_shares_count": 0,
                "created_at": datetime.now(timezone.utc).isoformat(),
            }]

            response = client.post(
                f"/api/v1/stats-gallery/upload?user_id={sample_user_id}",
                json={
                    "template_type": template_type,
                    "image_base64": sample_image_base64,
                    "stats_snapshot": {},
                }
            )

            assert response.status_code == 200
            assert response.json()["image"]["template_type"] == template_type


# ============================================================
# LIST IMAGES TESTS
# ============================================================

class TestListStatsImages:
    """Test listing stats gallery images."""

    def test_list_images_success(
        self, mock_supabase, sample_user_id, sample_stats_gallery_image
    ):
        """Test listing stats gallery images."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.data = [
            sample_stats_gallery_image
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.count = 1

        response = client.get(
            f"/api/v1/stats-gallery/{sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert len(data["images"]) == 1
        assert data["total"] == 1

    def test_list_images_with_pagination(
        self, mock_supabase, sample_user_id, sample_stats_gallery_image
    ):
        """Test listing with pagination."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.data = [
            sample_stats_gallery_image
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.range.return_value.execute.return_value.count = 25

        response = client.get(
            f"/api/v1/stats-gallery/{sample_user_id}?page=1&page_size=10"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["page"] == 1
        assert data["page_size"] == 10
        assert data["has_more"] is True

    def test_list_images_filter_by_template(
        self, mock_supabase, sample_user_id, sample_stats_gallery_image
    ):
        """Test filtering by template type."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.eq.return_value.range.return_value.execute.return_value.data = [
            sample_stats_gallery_image
        ]
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.is_.return_value.order.return_value.eq.return_value.range.return_value.execute.return_value.count = 1

        response = client.get(
            f"/api/v1/stats-gallery/{sample_user_id}?template_type=overview"
        )

        assert response.status_code == 200


# ============================================================
# GET SINGLE IMAGE TESTS
# ============================================================

class TestGetStatsImage:
    """Test getting a single stats gallery image."""

    def test_get_image_success(
        self, mock_supabase, sample_user_id, sample_image_id, sample_stats_gallery_image
    ):
        """Test getting a stats gallery image by ID."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = sample_stats_gallery_image

        response = client.get(
            f"/api/v1/stats-gallery/{sample_user_id}/{sample_image_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["id"] == sample_image_id

    def test_get_image_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test 404 when image not found."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.get(
            f"/api/v1/stats-gallery/{sample_user_id}/{sample_image_id}"
        )

        assert response.status_code == 404


# ============================================================
# DELETE IMAGE TESTS
# ============================================================

class TestDeleteStatsImage:
    """Test deleting stats gallery images."""

    def test_delete_image_success(
        self, mock_supabase, sample_user_id, sample_image_id
    ):
        """Test successfully soft-deleting a stats gallery image."""
        # Mock ownership check
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = {
            "id": sample_image_id
        }
        # Mock update
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": sample_image_id}
        ]

        response = client.delete(
            f"/api/v1/stats-gallery/{sample_image_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        assert response.json()["success"] is True

    def test_delete_image_not_found(self, mock_supabase, sample_user_id, sample_image_id):
        """Test 404 when trying to delete non-existent image."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.delete(
            f"/api/v1/stats-gallery/{sample_image_id}?user_id={sample_user_id}"
        )

        assert response.status_code == 404


# ============================================================
# SHARE TO FEED TESTS
# ============================================================

class TestShareStatsToFeed:
    """Test sharing stats images to social feed."""

    def test_share_to_feed_success(
        self, mock_supabase, sample_user_id, sample_image_id, sample_stats_gallery_image
    ):
        """Test successfully sharing a stats image to feed."""
        activity_id = str(uuid.uuid4())

        # Mock getting the image
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = sample_stats_gallery_image

        # Mock activity insert
        mock_supabase.client.table.return_value.insert.return_value.execute.return_value.data = [{
            "id": activity_id
        }]

        # Mock updating shared_to_feed
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": sample_image_id}
        ]

        response = client.post(
            f"/api/v1/stats-gallery/{sample_image_id}/share-to-feed?user_id={sample_user_id}",
            json={"caption": "Check out my progress!"}
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["activity_id"] == activity_id

    def test_share_to_feed_image_not_found(
        self, mock_supabase, sample_user_id, sample_image_id
    ):
        """Test 404 when image not found for sharing."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.is_.return_value.single.return_value.execute.return_value.data = None

        response = client.post(
            f"/api/v1/stats-gallery/{sample_image_id}/share-to-feed?user_id={sample_user_id}",
            json={}
        )

        assert response.status_code == 404


# ============================================================
# TRACK EXTERNAL SHARE TESTS
# ============================================================

class TestTrackExternalShare:
    """Test tracking external shares of stats images."""

    def test_track_external_share_success(
        self, mock_supabase, sample_user_id, sample_image_id
    ):
        """Test tracking external share increments count."""
        # Mock getting current count
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = {
            "external_shares_count": 5
        }

        # Mock update
        mock_supabase.client.table.return_value.update.return_value.eq.return_value.execute.return_value.data = [
            {"id": sample_image_id}
        ]

        response = client.put(
            f"/api/v1/stats-gallery/{sample_image_id}/track-external-share?user_id={sample_user_id}"
        )

        assert response.status_code == 200
        data = response.json()
        assert data["success"] is True
        assert data["external_shares_count"] == 6

    def test_track_external_share_image_not_found(
        self, mock_supabase, sample_user_id, sample_image_id
    ):
        """Test 404 when image not found for external share tracking."""
        mock_supabase.client.table.return_value.select.return_value.eq.return_value.eq.return_value.single.return_value.execute.return_value.data = None

        response = client.put(
            f"/api/v1/stats-gallery/{sample_image_id}/track-external-share?user_id={sample_user_id}"
        )

        assert response.status_code == 404
