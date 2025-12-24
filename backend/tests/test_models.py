"""
Tests for Pydantic models and validation.

Tests:
- Model creation and validation
- Enum values
- Optional fields
- Default values
- Serialization

Run with: pytest backend/tests/test_models.py -v
"""

import pytest
from datetime import datetime, date, time, timezone, timedelta
from pydantic import ValidationError
import uuid


# ============================================================
# WORKOUT CHALLENGES MODELS TESTS
# ============================================================

class TestWorkoutChallengeModels:
    """Test workout challenge models."""

    def test_challenge_status_enum(self):
        """Test ChallengeStatus enum values."""
        from models.workout_challenges import ChallengeStatus

        assert ChallengeStatus.pending == "pending"
        assert ChallengeStatus.accepted == "accepted"
        assert ChallengeStatus.declined == "declined"
        assert ChallengeStatus.completed == "completed"
        assert ChallengeStatus.expired == "expired"
        assert ChallengeStatus.abandoned == "abandoned"

    def test_notification_type_enum(self):
        """Test NotificationType enum values."""
        from models.workout_challenges import NotificationType

        assert NotificationType.challenge_received == "challenge_received"
        assert NotificationType.challenge_accepted == "challenge_accepted"
        assert NotificationType.challenge_completed == "challenge_completed"
        assert NotificationType.challenge_beaten == "challenge_beaten"
        assert NotificationType.challenge_abandoned == "challenge_abandoned"

    def test_send_challenge_request_valid(self):
        """Test valid SendChallengeRequest creation."""
        from models.workout_challenges import SendChallengeRequest

        request = SendChallengeRequest(
            to_user_ids=[str(uuid.uuid4()), str(uuid.uuid4())],
            workout_name="Upper Body",
            workout_data={"duration_minutes": 45, "total_volume": 5000},
            challenge_message="Beat this!",
        )

        assert len(request.to_user_ids) == 2
        assert request.workout_name == "Upper Body"
        assert request.is_retry is False  # Default
        assert request.retried_from_challenge_id is None

    def test_send_challenge_request_retry(self):
        """Test SendChallengeRequest with retry flag."""
        from models.workout_challenges import SendChallengeRequest

        original_id = str(uuid.uuid4())
        request = SendChallengeRequest(
            to_user_ids=[str(uuid.uuid4())],
            workout_name="Leg Day",
            workout_data={},
            is_retry=True,
            retried_from_challenge_id=original_id,
        )

        assert request.is_retry is True
        assert request.retried_from_challenge_id == original_id

    def test_send_challenge_request_missing_required(self):
        """Test SendChallengeRequest with missing required fields."""
        from models.workout_challenges import SendChallengeRequest

        with pytest.raises(ValidationError):
            SendChallengeRequest(
                to_user_ids=[str(uuid.uuid4())],
                # Missing workout_name and workout_data
            )

    def test_workout_challenge_model(self):
        """Test WorkoutChallenge model creation."""
        from models.workout_challenges import WorkoutChallenge, ChallengeStatus

        now = datetime.now(timezone.utc)
        challenge = WorkoutChallenge(
            id=str(uuid.uuid4()),
            from_user_id=str(uuid.uuid4()),
            to_user_id=str(uuid.uuid4()),
            workout_name="Full Body",
            workout_data={"duration_minutes": 60},
            status=ChallengeStatus.pending,
            created_at=now,
            expires_at=now + timedelta(days=7),
        )

        assert challenge.status == ChallengeStatus.pending
        assert challenge.is_retry is False
        assert challenge.did_beat is None

    def test_complete_challenge_request(self):
        """Test CompleteChallengeRequest model."""
        from models.workout_challenges import CompleteChallengeRequest

        request = CompleteChallengeRequest(
            challenge_id=str(uuid.uuid4()),
            workout_log_id=str(uuid.uuid4()),
            challenged_stats={"duration_minutes": 50, "total_volume": 6000},
        )

        assert request.challenged_stats["total_volume"] == 6000

    def test_abandon_challenge_request(self):
        """Test AbandonChallengeRequest model."""
        from models.workout_challenges import AbandonChallengeRequest

        request = AbandonChallengeRequest(
            challenge_id=str(uuid.uuid4()),
            quit_reason="Too tired to continue",
            partial_stats={"completed_exercises": 3, "duration_so_far": 20},
        )

        assert request.quit_reason == "Too tired to continue"
        assert request.partial_stats is not None

    def test_challenge_stats_model(self):
        """Test ChallengeStats model."""
        from models.workout_challenges import ChallengeStats

        stats = ChallengeStats(
            user_id=str(uuid.uuid4()),
            challenges_sent=10,
            challenges_received=15,
            challenges_accepted=12,
            challenges_declined=3,
            challenges_won=8,
            challenges_lost=4,
            challenges_abandoned=0,
            win_rate=66.67,
            total_retries=2,
            retries_won=1,
            retry_win_rate=50.0,
        )

        assert stats.win_rate == 66.67
        assert stats.challenges_won == 8


# ============================================================
# LEADERBOARD MODELS TESTS
# ============================================================

class TestLeaderboardModels:
    """Test leaderboard models."""

    def test_leaderboard_type_enum(self):
        """Test LeaderboardType enum values."""
        from models.leaderboard import LeaderboardType

        assert LeaderboardType.challenge_masters == "challenge_masters"
        assert LeaderboardType.volume_kings == "volume_kings"
        assert LeaderboardType.streaks == "streaks"
        assert LeaderboardType.weekly_challenges == "weekly_challenges"

    def test_leaderboard_filter_enum(self):
        """Test LeaderboardFilter enum values."""
        from models.leaderboard import LeaderboardFilter

        assert LeaderboardFilter.global_lb == "global"
        assert LeaderboardFilter.country == "country"
        assert LeaderboardFilter.friends == "friends"

    def test_get_leaderboard_request_defaults(self):
        """Test GetLeaderboardRequest default values."""
        from models.leaderboard import GetLeaderboardRequest, LeaderboardType, LeaderboardFilter

        request = GetLeaderboardRequest()

        assert request.leaderboard_type == LeaderboardType.challenge_masters
        assert request.filter_type == LeaderboardFilter.global_lb
        assert request.limit == 100
        assert request.offset == 0

    def test_get_leaderboard_request_validation(self):
        """Test GetLeaderboardRequest validation."""
        from models.leaderboard import GetLeaderboardRequest

        # Limit out of range
        with pytest.raises(ValidationError):
            GetLeaderboardRequest(limit=1000)  # Max is 500

        # Negative offset
        with pytest.raises(ValidationError):
            GetLeaderboardRequest(offset=-1)

    def test_leaderboard_entry_challenge_masters(self):
        """Test LeaderboardEntry for challenge masters."""
        from models.leaderboard import LeaderboardEntry

        entry = LeaderboardEntry(
            rank=1,
            user_id=str(uuid.uuid4()),
            user_name="Champion",
            country_code="US",
            first_wins=100,
            win_rate=95.5,
            total_completed=105,
            is_friend=False,
            is_current_user=True,
        )

        assert entry.rank == 1
        assert entry.first_wins == 100
        assert entry.is_current_user is True

    def test_leaderboard_entry_volume_kings(self):
        """Test LeaderboardEntry for volume kings."""
        from models.leaderboard import LeaderboardEntry

        entry = LeaderboardEntry(
            rank=1,
            user_id=str(uuid.uuid4()),
            user_name="Heavy Lifter",
            total_volume_lbs=1000000.0,
            total_workouts=500,
            avg_volume_per_workout=2000.0,
        )

        assert entry.total_volume_lbs == 1000000.0
        assert entry.avg_volume_per_workout == 2000.0

    def test_leaderboard_entry_streaks(self):
        """Test LeaderboardEntry for streaks."""
        from models.leaderboard import LeaderboardEntry

        entry = LeaderboardEntry(
            rank=1,
            user_id=str(uuid.uuid4()),
            user_name="Consistent",
            current_streak=30,
            best_streak=60,
            last_workout_date=datetime.now(timezone.utc),
        )

        assert entry.current_streak == 30
        assert entry.best_streak == 60

    def test_user_rank_model(self):
        """Test UserRank model."""
        from models.leaderboard import UserRank, LeaderboardEntry

        entry = LeaderboardEntry(
            rank=25,
            user_id=str(uuid.uuid4()),
            user_name="Test User",
        )

        rank = UserRank(
            user_id=entry.user_id,
            rank=25,
            total_users=500,
            percentile=5.0,
            user_stats=entry,
        )

        assert rank.percentile == 5.0
        assert rank.user_stats.rank == 25

    def test_leaderboard_unlock_status(self):
        """Test LeaderboardUnlockStatus model."""
        from models.leaderboard import LeaderboardUnlockStatus

        status = LeaderboardUnlockStatus(
            is_unlocked=False,
            workouts_completed=7,
            workouts_needed=3,
            days_active=14,
            unlock_message="Complete 3 more workouts!",
            progress_percentage=70.0,
        )

        assert status.is_unlocked is False
        assert status.progress_percentage == 70.0

    def test_async_challenge_request(self):
        """Test AsyncChallengeRequest model."""
        from models.leaderboard import AsyncChallengeRequest

        request = AsyncChallengeRequest(
            target_user_id=str(uuid.uuid4()),
            workout_log_id=str(uuid.uuid4()),
            challenge_message="Coming for your record!",
        )

        assert request.target_user_id is not None
        assert "record" in request.challenge_message

    def test_async_challenge_request_defaults(self):
        """Test AsyncChallengeRequest default values."""
        from models.leaderboard import AsyncChallengeRequest

        request = AsyncChallengeRequest(
            target_user_id=str(uuid.uuid4()),
        )

        assert request.workout_log_id is None
        assert request.challenge_message == "I'm coming for your record! muscle"


# ============================================================
# SAVED WORKOUTS MODELS TESTS
# ============================================================

class TestSavedWorkoutsModels:
    """Test saved workouts models."""

    def test_difficulty_level_enum(self):
        """Test DifficultyLevel enum values."""
        from models.saved_workouts import DifficultyLevel

        assert DifficultyLevel.BEGINNER == "beginner"
        assert DifficultyLevel.INTERMEDIATE == "intermediate"
        assert DifficultyLevel.ADVANCED == "advanced"

    def test_scheduled_workout_status_enum(self):
        """Test ScheduledWorkoutStatus enum values."""
        from models.saved_workouts import ScheduledWorkoutStatus

        assert ScheduledWorkoutStatus.SCHEDULED == "scheduled"
        assert ScheduledWorkoutStatus.COMPLETED == "completed"
        assert ScheduledWorkoutStatus.SKIPPED == "skipped"
        assert ScheduledWorkoutStatus.RESCHEDULED == "rescheduled"

    def test_exercise_template(self):
        """Test ExerciseTemplate model."""
        from models.saved_workouts import ExerciseTemplate

        exercise = ExerciseTemplate(
            name="Squats",
            sets=4,
            reps=10,
            weight_kg=100.0,
            rest_seconds=90,
            notes="Focus on depth",
        )

        assert exercise.name == "Squats"
        assert exercise.rest_seconds == 90

    def test_exercise_template_defaults(self):
        """Test ExerciseTemplate default values."""
        from models.saved_workouts import ExerciseTemplate

        exercise = ExerciseTemplate(
            name="Push-ups",
            sets=3,
            reps=15,
            weight_kg=0,
        )

        assert exercise.rest_seconds == 60  # Default
        assert exercise.notes is None

    def test_saved_workout_model(self):
        """Test SavedWorkout model."""
        from models.saved_workouts import SavedWorkout, ExerciseTemplate

        exercises = [
            ExerciseTemplate(name="Squats", sets=4, reps=10, weight_kg=100),
            ExerciseTemplate(name="Lunges", sets=3, reps=12, weight_kg=30),
        ]

        now = datetime.now(timezone.utc)
        workout = SavedWorkout(
            id=str(uuid.uuid4()),
            user_id=str(uuid.uuid4()),
            workout_name="Leg Day",
            exercises=exercises,
            total_exercises=2,
            folder="Favorites",
            tags=["legs", "strength"],
            times_completed=5,
            saved_at=now,
            updated_at=now,
        )

        assert workout.times_completed == 5
        assert len(workout.exercises) == 2
        assert "legs" in workout.tags

    def test_save_workout_from_activity(self):
        """Test SaveWorkoutFromActivity model."""
        from models.saved_workouts import SaveWorkoutFromActivity

        request = SaveWorkoutFromActivity(
            activity_id=str(uuid.uuid4()),
            folder="From Friends",
            notes="Great workout from John",
        )

        assert request.folder == "From Friends"

    def test_schedule_workout_request(self):
        """Test ScheduleWorkoutRequest model."""
        from models.saved_workouts import ScheduleWorkoutRequest

        schedule_date = date.today() + timedelta(days=3)
        schedule_time = time(9, 0, 0)

        request = ScheduleWorkoutRequest(
            saved_workout_id=str(uuid.uuid4()),
            scheduled_date=schedule_date,
            scheduled_time=schedule_time,
            reminder_enabled=True,
            reminder_minutes_before=30,
        )

        assert request.reminder_minutes_before == 30
        assert request.reminder_enabled is True

    def test_monthly_calendar(self):
        """Test MonthlyCalendar model."""
        from models.saved_workouts import MonthlyCalendar, CalendarWorkout, ScheduledWorkoutStatus

        workout = CalendarWorkout(
            id=str(uuid.uuid4()),
            date=date.today(),
            name="Full Body",
            status=ScheduledWorkoutStatus.SCHEDULED,
            exercise_count=8,
            estimated_duration=60,
        )

        calendar = MonthlyCalendar(
            year=2025,
            month=1,
            workouts=[workout],
            total_scheduled=1,
            total_completed=0,
        )

        assert calendar.year == 2025
        assert len(calendar.workouts) == 1


# ============================================================
# SOCIAL MODELS TESTS
# ============================================================

class TestSocialModels:
    """Test social models."""

    def test_activity_type_enum(self):
        """Test ActivityType enum values."""
        from models.social import ActivityType

        assert ActivityType.workout_completed == "workout_completed"
        assert ActivityType.achievement_earned == "achievement_earned"
        assert ActivityType.personal_record == "personal_record"
        assert ActivityType.streak_milestone == "streak_milestone"

    def test_visibility_enum(self):
        """Test Visibility enum values."""
        from models.social import Visibility

        assert Visibility.public == "public"
        assert Visibility.friends == "friends"
        assert Visibility.private == "private"

    def test_reaction_type_enum(self):
        """Test ReactionType enum values."""
        from models.social import ReactionType

        assert ReactionType.fire == "fire"
        assert ReactionType.strong == "strong"
        assert ReactionType.cheer == "cheer"


# ============================================================
# CHAT MODELS TESTS
# ============================================================

class TestChatModels:
    """Test chat models."""

    def test_coach_intent_enum(self):
        """Test CoachIntent enum values."""
        from models.chat import CoachIntent

        assert CoachIntent.QUESTION == "question"
        assert CoachIntent.ADD_EXERCISE == "add_exercise"
        assert CoachIntent.REMOVE_EXERCISE == "remove_exercise"
        assert CoachIntent.SWAP_WORKOUT == "swap_workout"
        assert CoachIntent.MODIFY_INTENSITY == "modify_intensity"
        assert CoachIntent.REPORT_INJURY == "report_injury"

    def test_chat_request_model(self):
        """Test ChatRequest model."""
        from models.chat import ChatRequest

        request = ChatRequest(
            message="Add push-ups to my workout",
            user_id=1,
        )

        assert request.message == "Add push-ups to my workout"
        assert request.conversation_history == []

    def test_user_profile_model(self):
        """Test UserProfile model."""
        from models.chat import UserProfile

        profile = UserProfile(
            id=1,
            fitness_level="intermediate",
            goals=["build muscle", "lose fat"],
            equipment=["dumbbells", "barbell"],
            active_injuries=["shoulder"],
        )

        assert profile.fitness_level == "intermediate"
        assert len(profile.goals) == 2
        assert "shoulder" in profile.active_injuries

    def test_workout_context_model(self):
        """Test WorkoutContext model."""
        from models.chat import WorkoutContext

        context = WorkoutContext(
            id=1,
            name="Upper Body Day",
            type="strength",
            difficulty="medium",
            exercises=[
                {"name": "Bench Press", "sets": 4, "reps": 8},
                {"name": "Rows", "sets": 4, "reps": 10},
            ],
        )

        assert context.name == "Upper Body Day"
        assert len(context.exercises) == 2


# ============================================================
# SERIALIZATION TESTS
# ============================================================

class TestSerialization:
    """Test model serialization."""

    def test_challenge_model_to_dict(self):
        """Test WorkoutChallenge serialization to dict."""
        from models.workout_challenges import WorkoutChallenge, ChallengeStatus

        now = datetime.now(timezone.utc)
        challenge = WorkoutChallenge(
            id=str(uuid.uuid4()),
            from_user_id=str(uuid.uuid4()),
            to_user_id=str(uuid.uuid4()),
            workout_name="Test",
            workout_data={},
            status=ChallengeStatus.pending,
            created_at=now,
            expires_at=now + timedelta(days=7),
        )

        data = challenge.model_dump()

        assert "id" in data
        assert "status" in data
        assert data["status"] == "pending"

    def test_leaderboard_entry_to_dict(self):
        """Test LeaderboardEntry serialization to dict."""
        from models.leaderboard import LeaderboardEntry

        entry = LeaderboardEntry(
            rank=1,
            user_id=str(uuid.uuid4()),
            user_name="Test",
            first_wins=50,
        )

        data = entry.model_dump()

        assert data["rank"] == 1
        assert data["first_wins"] == 50
        assert data["is_friend"] is False  # Default

    def test_saved_workout_to_dict(self):
        """Test SavedWorkout serialization to dict."""
        from models.saved_workouts import SavedWorkout, ExerciseTemplate

        now = datetime.now(timezone.utc)
        workout = SavedWorkout(
            id=str(uuid.uuid4()),
            user_id=str(uuid.uuid4()),
            workout_name="Test Workout",
            exercises=[],
            total_exercises=0,
            saved_at=now,
            updated_at=now,
        )

        data = workout.model_dump()

        assert "workout_name" in data
        assert data["times_completed"] == 0  # Default


# ============================================================
# EDGE CASES
# ============================================================

class TestEdgeCases:
    """Test edge cases in models."""

    def test_empty_exercise_list(self):
        """Test model with empty exercise list."""
        from models.saved_workouts import SavedWorkout

        now = datetime.now(timezone.utc)
        workout = SavedWorkout(
            id=str(uuid.uuid4()),
            user_id=str(uuid.uuid4()),
            workout_name="Empty Workout",
            exercises=[],
            total_exercises=0,
            saved_at=now,
            updated_at=now,
        )

        assert workout.exercises == []
        assert workout.total_exercises == 0

    def test_optional_fields_none(self):
        """Test models with optional fields as None."""
        from models.workout_challenges import WorkoutChallenge, ChallengeStatus

        now = datetime.now(timezone.utc)
        challenge = WorkoutChallenge(
            id=str(uuid.uuid4()),
            from_user_id=str(uuid.uuid4()),
            to_user_id=str(uuid.uuid4()),
            workout_name="Test",
            workout_data={},
            status=ChallengeStatus.pending,
            created_at=now,
            expires_at=now + timedelta(days=7),
            # All optional fields should be None
        )

        assert challenge.workout_log_id is None
        assert challenge.activity_id is None
        assert challenge.challenge_message is None
        assert challenge.did_beat is None

    def test_datetime_handling(self):
        """Test datetime handling in models."""
        from models.workout_challenges import WorkoutChallenge, ChallengeStatus

        now = datetime.now(timezone.utc)
        expires = now + timedelta(days=7)

        challenge = WorkoutChallenge(
            id=str(uuid.uuid4()),
            from_user_id=str(uuid.uuid4()),
            to_user_id=str(uuid.uuid4()),
            workout_name="Test",
            workout_data={},
            status=ChallengeStatus.pending,
            created_at=now,
            expires_at=expires,
        )

        assert challenge.created_at == now
        assert challenge.expires_at > challenge.created_at


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
