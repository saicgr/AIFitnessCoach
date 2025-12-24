"""
Tests for Social RAG Service (ChromaDB integration).

Tests:
- Adding activities to ChromaDB
- Adding reactions to ChromaDB
- Querying user activities
- Getting friend activity context
- Social engagement metrics
"""

import pytest
from unittest.mock import Mock, patch, MagicMock
from datetime import datetime, timezone
import uuid

from services.social_rag_service import SocialRAGService, get_social_rag_service


# ============================================================
# FIXTURES
# ============================================================

@pytest.fixture
def mock_chroma_client():
    """Mock ChromaDB client for testing."""
    with patch('services.social_rag_service.get_chroma_cloud_client') as mock:
        chroma_mock = MagicMock()
        collection_mock = MagicMock()
        chroma_mock.get_or_create_collection.return_value = collection_mock
        mock.return_value = chroma_mock
        yield chroma_mock, collection_mock


@pytest.fixture
def social_rag_service(mock_chroma_client):
    """Social RAG service instance with mocked ChromaDB."""
    return SocialRAGService()


@pytest.fixture
def sample_activity_data():
    """Sample workout activity data."""
    return {
        "workout_name": "Full Body Workout",
        "duration_minutes": 60,
        "exercises_count": 10,
        "total_volume": 8500,
        "exercises_performance": [
            {"name": "Squats", "sets": 4, "reps": 8, "weight_kg": 100},
            {"name": "Bench Press", "sets": 4, "reps": 10, "weight_kg": 80},
            {"name": "Deadlifts", "sets": 3, "reps": 5, "weight_kg": 140},
        ]
    }


# ============================================================
# ACTIVITY TESTS
# ============================================================

def test_add_activity_to_rag(social_rag_service, mock_chroma_client, sample_activity_data):
    """Test adding an activity to ChromaDB."""
    chroma_mock, collection_mock = mock_chroma_client

    activity_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    user_name = "John Doe"
    activity_type = "workout_completed"
    visibility = "friends"
    created_at = datetime.now(timezone.utc)

    # Call the method
    social_rag_service.add_activity_to_rag(
        activity_id=activity_id,
        user_id=user_id,
        user_name=user_name,
        activity_type=activity_type,
        activity_data=sample_activity_data,
        visibility=visibility,
        created_at=created_at,
    )

    # Verify collection.add was called
    collection_mock.add.assert_called_once()

    # Get the call arguments
    call_args = collection_mock.add.call_args
    documents = call_args.kwargs["documents"]
    metadatas = call_args.kwargs["metadatas"]
    ids = call_args.kwargs["ids"]

    # Verify document text contains key information
    assert "John Doe" in documents[0]
    assert "Full Body Workout" in documents[0]
    assert "60 minutes" in documents[0]
    assert "10 exercises" in documents[0]

    # Verify metadata
    assert metadatas[0]["user_id"] == user_id
    assert metadatas[0]["user_name"] == user_name
    assert metadatas[0]["activity_type"] == activity_type
    assert metadatas[0]["visibility"] == visibility
    assert metadatas[0]["has_exercises"] is True
    assert metadatas[0]["exercise_count"] == 3

    # Verify ID format
    assert ids[0] == f"activity_{activity_id}"


def test_add_activity_achievement(social_rag_service, mock_chroma_client):
    """Test adding an achievement activity."""
    chroma_mock, collection_mock = mock_chroma_client

    activity_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    activity_data = {
        "achievement_name": "100 Workouts Complete"
    }

    social_rag_service.add_activity_to_rag(
        activity_id=activity_id,
        user_id=user_id,
        user_name="Jane Smith",
        activity_type="achievement_earned",
        activity_data=activity_data,
        visibility="public",
        created_at=datetime.now(timezone.utc),
    )

    # Verify document mentions achievement
    call_args = collection_mock.add.call_args
    documents = call_args.kwargs["documents"]
    assert "earned the achievement" in documents[0]
    assert "100 Workouts Complete" in documents[0]


def test_delete_activity_from_rag(social_rag_service, mock_chroma_client):
    """Test deleting an activity from ChromaDB."""
    chroma_mock, collection_mock = mock_chroma_client

    activity_id = str(uuid.uuid4())

    # Call delete
    social_rag_service.delete_activity_from_rag(activity_id)

    # Verify collection.delete was called with correct ID
    collection_mock.delete.assert_called_once_with(ids=[f"activity_{activity_id}"])


def test_delete_activity_handles_error(social_rag_service, mock_chroma_client):
    """Test that delete handles errors gracefully."""
    chroma_mock, collection_mock = mock_chroma_client
    collection_mock.delete.side_effect = Exception("ChromaDB error")

    activity_id = str(uuid.uuid4())

    # Should not raise exception
    social_rag_service.delete_activity_from_rag(activity_id)


# ============================================================
# REACTION TESTS
# ============================================================

def test_add_reaction_to_rag(social_rag_service, mock_chroma_client):
    """Test adding a reaction to ChromaDB."""
    chroma_mock, collection_mock = mock_chroma_client

    reaction_id = str(uuid.uuid4())
    activity_id = str(uuid.uuid4())
    user_id = str(uuid.uuid4())
    user_name = "Alice"
    reaction_type = "fire"
    activity_owner = "Bob"
    created_at = datetime.now(timezone.utc)

    # Call the method
    social_rag_service.add_reaction_to_rag(
        reaction_id=reaction_id,
        activity_id=activity_id,
        user_id=user_id,
        user_name=user_name,
        reaction_type=reaction_type,
        activity_owner=activity_owner,
        created_at=created_at,
    )

    # Verify collection.add was called
    collection_mock.add.assert_called_once()

    # Get call arguments
    call_args = collection_mock.add.call_args
    documents = call_args.kwargs["documents"]
    metadatas = call_args.kwargs["metadatas"]
    ids = call_args.kwargs["ids"]

    # Verify document text
    assert "Alice" in documents[0]
    assert "fire" in documents[0]
    assert "Bob" in documents[0]

    # Verify metadata
    assert metadatas[0]["user_id"] == user_id
    assert metadatas[0]["activity_id"] == activity_id
    assert metadatas[0]["reaction_type"] == reaction_type
    assert metadatas[0]["activity_owner"] == activity_owner
    assert metadatas[0]["interaction_type"] == "reaction"

    # Verify ID
    assert ids[0] == f"reaction_{reaction_id}"


def test_remove_reaction_from_rag(social_rag_service, mock_chroma_client):
    """Test removing a reaction from ChromaDB."""
    chroma_mock, collection_mock = mock_chroma_client

    reaction_id = str(uuid.uuid4())

    # Call remove
    social_rag_service.remove_reaction_from_rag(reaction_id)

    # Verify collection.delete was called
    collection_mock.delete.assert_called_once_with(ids=[f"reaction_{reaction_id}"])


def test_remove_reaction_handles_error(social_rag_service, mock_chroma_client):
    """Test that remove reaction handles errors gracefully."""
    chroma_mock, collection_mock = mock_chroma_client
    collection_mock.delete.side_effect = Exception("ChromaDB error")

    reaction_id = str(uuid.uuid4())

    # Should not raise exception
    social_rag_service.remove_reaction_from_rag(reaction_id)


# ============================================================
# QUERY TESTS
# ============================================================

def test_get_user_recent_activities(social_rag_service, mock_chroma_client):
    """Test querying user's recent activities."""
    chroma_mock, collection_mock = mock_chroma_client
    user_id = str(uuid.uuid4())

    # Mock query results
    collection_mock.query.return_value = {
        "ids": [["activity_1", "activity_2"]],
        "documents": [["Doc 1", "Doc 2"]],
        "metadatas": [[
            {"user_id": user_id, "activity_type": "workout_completed"},
            {"user_id": user_id, "activity_type": "achievement_earned"}
        ]]
    }

    # Call method
    results = social_rag_service.get_user_recent_activities(user_id, n_results=10)

    # Verify query was called with correct parameters
    collection_mock.query.assert_called_once()
    call_args = collection_mock.query.call_args
    assert call_args.kwargs["where"] == {"user_id": user_id}
    assert call_args.kwargs["n_results"] == 10

    # Verify results formatting
    assert len(results) == 2
    assert results[0]["id"] == "activity_1"
    assert results[0]["document"] == "Doc 1"
    assert results[1]["id"] == "activity_2"


def test_get_friend_activities_context(social_rag_service, mock_chroma_client):
    """Test getting friend activities as context string."""
    chroma_mock, collection_mock = mock_chroma_client

    friend_id_1 = str(uuid.uuid4())
    friend_id_2 = str(uuid.uuid4())
    friend_ids = [friend_id_1, friend_id_2]

    # Mock get results
    collection_mock.get.return_value = {
        "documents": [
            "Friend 1 completed a workout",
            "Friend 2 earned an achievement",
            "Random user did something",  # Not a friend
        ],
        "metadatas": [
            {"user_id": friend_id_1, "visibility": "friends"},
            {"user_id": friend_id_2, "visibility": "public"},
            {"user_id": str(uuid.uuid4()), "visibility": "public"},
        ]
    }

    # Call method
    context = social_rag_service.get_friend_activities_context(friend_ids, n_results=20)

    # Verify query was called
    collection_mock.get.assert_called_once()

    # Verify context string contains friend activities
    assert "Friend 1 completed a workout" in context
    assert "Friend 2 earned an achievement" in context
    assert "Random user" not in context  # Non-friend filtered out


def test_get_friend_activities_empty(social_rag_service, mock_chroma_client):
    """Test getting friend activities when there are none."""
    chroma_mock, collection_mock = mock_chroma_client

    friend_ids = [str(uuid.uuid4())]

    # Mock empty results
    collection_mock.get.return_value = {
        "documents": [],
        "metadatas": []
    }

    # Call method
    context = social_rag_service.get_friend_activities_context(friend_ids)

    # Should return empty message
    assert context == "No recent friend activity."


def test_get_social_engagement_context(social_rag_service, mock_chroma_client):
    """Test getting social engagement metrics."""
    chroma_mock, collection_mock = mock_chroma_client
    user_id = str(uuid.uuid4())

    # Mock reactions given
    collection_mock.query.side_effect = [
        # First call: reactions given
        {
            "ids": [["reaction_1", "reaction_2", "reaction_3"]],
            "documents": [["Doc 1", "Doc 2", "Doc 3"]],
            "metadatas": [[{}, {}, {}]]
        },
        # Second call: reactions received
        {
            "ids": [["reaction_4", "reaction_5"]],
            "documents": [["Doc 4", "Doc 5"]],
            "metadatas": [[{}, {}]]
        }
    ]

    # Call method
    metrics = social_rag_service.get_social_engagement_context(user_id, days_back=7)

    # Verify results
    assert metrics["reactions_given_count"] == 3
    assert metrics["reactions_received_count"] == 2
    assert metrics["is_socially_active"] is True


def test_get_social_engagement_inactive(social_rag_service, mock_chroma_client):
    """Test engagement metrics for inactive user."""
    chroma_mock, collection_mock = mock_chroma_client
    user_id = str(uuid.uuid4())

    # Mock no reactions
    collection_mock.query.side_effect = [
        {"ids": [[]], "documents": [[]], "metadatas": [[]]},
        {"ids": [[]], "documents": [[]], "metadatas": [[]]}
    ]

    # Call method
    metrics = social_rag_service.get_social_engagement_context(user_id)

    # Verify inactive
    assert metrics["reactions_given_count"] == 0
    assert metrics["reactions_received_count"] == 0
    assert metrics["is_socially_active"] is False


# ============================================================
# DOCUMENT BUILDING TESTS
# ============================================================

def test_build_workout_document_with_exercises(social_rag_service, sample_activity_data):
    """Test building a natural language document from workout data."""
    user_name = "Test User"
    created_at = datetime.now(timezone.utc)

    doc = social_rag_service._build_activity_document(
        user_name=user_name,
        activity_type="workout_completed",
        activity_data=sample_activity_data,
        created_at=created_at,
    )

    # Verify key information is present
    assert "Test User" in doc
    assert "Full Body Workout" in doc
    assert "60 minutes" in doc
    assert "10 exercises" in doc
    assert "Squats" in doc
    assert "4x8 @ 100kg" in doc
    assert "Total volume: 8500kg" in doc


def test_build_pr_document(social_rag_service):
    """Test building document for personal record."""
    activity_data = {
        "exercise_name": "Deadlift",
        "pr_value": "200kg"
    }

    doc = social_rag_service._build_activity_document(
        user_name="Strong User",
        activity_type="personal_record",
        activity_data=activity_data,
        created_at=datetime.now(timezone.utc),
    )

    assert "Strong User" in doc
    assert "personal record" in doc
    assert "Deadlift" in doc
    assert "200kg" in doc


def test_build_streak_document(social_rag_service):
    """Test building document for streak milestone."""
    activity_data = {
        "streak_days": 30
    }

    doc = social_rag_service._build_activity_document(
        user_name="Consistent User",
        activity_type="streak_milestone",
        activity_data=activity_data,
        created_at=datetime.now(timezone.utc),
    )

    assert "Consistent User" in doc
    assert "30-day" in doc
    assert "streak" in doc


# ============================================================
# SINGLETON TESTS
# ============================================================

def test_get_social_rag_service_singleton():
    """Test that get_social_rag_service returns a singleton."""
    service1 = get_social_rag_service()
    service2 = get_social_rag_service()

    # Should be the same instance
    assert service1 is service2


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
