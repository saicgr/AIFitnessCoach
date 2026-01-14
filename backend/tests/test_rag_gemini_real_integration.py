"""
Real integration tests that make actual API calls to ChromaDB and Gemini.

These tests verify the complete workout generation workflow works end-to-end:
1. RAG selects exercises from ChromaDB
2. Exercises are formatted with set_targets
3. Gemini generates workout name/notes
4. Final workout has all required fields

Requires:
- GEMINI_API_KEY environment variable
- CHROMADB_TOKEN or CHROMA_API_KEY environment variable
- Network access to ChromaDB Cloud and Gemini API

Marked with @pytest.mark.integration - skipped by default, run with:
  pytest -m integration tests/test_rag_gemini_real_integration.py

To run in CI/CD, set RUN_INTEGRATION_TESTS=true in environment.
"""
import pytest
import os

# Skip entire module if GEMINI_API_KEY not available
pytestmark = [
    pytest.mark.integration,
    pytest.mark.skipif(
        not os.getenv("GEMINI_API_KEY"),
        reason="GEMINI_API_KEY not set - skipping real integration tests"
    ),
]


class TestRealRAGIntegration:
    """Tests that make real calls to ChromaDB for exercise selection."""

    def test_rag_service_initialization(self):
        """Verify RAG service can be initialized with real ChromaDB connection."""
        from services.exercise_rag.service import get_exercise_rag_service

        service = get_exercise_rag_service()
        assert service is not None, "RAG service should initialize"
        assert service.collection is not None, "Collection should be available"
        print(f"✅ RAG service initialized with {service.collection.count()} exercises")

    @pytest.mark.asyncio
    async def test_rag_selects_exercises_from_chromadb(self):
        """Verify RAG can select exercises from real ChromaDB."""
        from services.exercise_rag.service import get_exercise_rag_service

        service = get_exercise_rag_service()

        exercises = await service.select_exercises_for_workout(
            focus_area="chest",
            equipment=["barbell", "dumbbell"],
            fitness_level="intermediate",
            goals=["build_muscle"],
            count=3,
        )

        assert len(exercises) >= 1, "Should select at least 1 exercise"
        print(f"✅ Selected {len(exercises)} exercises for chest workout")

        for ex in exercises:
            assert "name" in ex, "Exercise must have name"
            assert "sets" in ex, "Exercise must have sets"
            assert "reps" in ex, "Exercise must have reps"
            # CRITICAL: Verify set_targets is generated
            assert "set_targets" in ex, f"Exercise '{ex.get('name')}' missing set_targets"
            assert len(ex["set_targets"]) > 0, f"Exercise '{ex.get('name')}' has empty set_targets"
            print(f"  - {ex['name']}: {ex['sets']}x{ex['reps']} with {len(ex['set_targets'])} set_targets")

    @pytest.mark.asyncio
    async def test_set_targets_have_required_fields(self):
        """Verify each set_target has all required fields."""
        from services.exercise_rag.service import get_exercise_rag_service

        service = get_exercise_rag_service()

        exercises = await service.select_exercises_for_workout(
            focus_area="back",
            equipment=["cable", "machine"],
            fitness_level="beginner",
            goals=["build_muscle"],
            count=2,
        )

        required_fields = ["set_number", "set_type", "target_reps", "target_weight_kg", "target_rpe"]

        for ex in exercises:
            for set_target in ex.get("set_targets", []):
                for field in required_fields:
                    assert field in set_target, f"set_target missing '{field}' for exercise '{ex.get('name')}'"

        print(f"✅ All {len(exercises)} exercises have complete set_targets with required fields")

    @pytest.mark.asyncio
    async def test_bodyweight_exercises_have_zero_weight(self):
        """Verify bodyweight exercises have weight_kg = 0 in set_targets."""
        from services.exercise_rag.service import get_exercise_rag_service

        service = get_exercise_rag_service()

        exercises = await service.select_exercises_for_workout(
            focus_area="chest",
            equipment=["bodyweight"],  # Only bodyweight
            fitness_level="intermediate",
            goals=["general_fitness"],
            count=2,
        )

        bodyweight_count = 0
        for ex in exercises:
            if ex.get("equipment_type") == "bodyweight" or ex.get("equipment", "").lower() in ["bodyweight", "body weight", ""]:
                bodyweight_count += 1
                for set_target in ex.get("set_targets", []):
                    assert set_target.get("target_weight_kg", 0) == 0, \
                        f"Bodyweight exercise '{ex.get('name')}' should have target_weight_kg=0, got {set_target.get('target_weight_kg')}"

        print(f"✅ Verified {bodyweight_count} bodyweight exercises have zero weight in set_targets")

    @pytest.mark.asyncio
    async def test_set_targets_rpe_values_match_fitness_level(self):
        """Verify RPE values in set_targets match expected values for fitness level."""
        from services.exercise_rag.service import get_exercise_rag_service

        service = get_exercise_rag_service()

        # Test beginner - should have lower RPE (7)
        beginner_exercises = await service.select_exercises_for_workout(
            focus_area="legs",
            equipment=["barbell"],
            fitness_level="beginner",
            goals=["build_muscle"],
            count=2,
        )

        for ex in beginner_exercises:
            for set_target in ex.get("set_targets", []):
                if set_target.get("set_type") == "working":
                    # Beginners should have RPE 7
                    assert set_target.get("target_rpe") in [5, 7, 8], \
                        f"Beginner RPE should be 5-8, got {set_target.get('target_rpe')}"

        # Test advanced - should have higher RPE (8-9)
        advanced_exercises = await service.select_exercises_for_workout(
            focus_area="legs",
            equipment=["barbell"],
            fitness_level="advanced",
            goals=["build_muscle"],
            count=2,
        )

        for ex in advanced_exercises:
            for set_target in ex.get("set_targets", []):
                if set_target.get("set_type") == "working":
                    # Advanced users should have RPE 8-9
                    assert set_target.get("target_rpe") in [5, 8, 9], \
                        f"Advanced RPE should be 5 (warmup) or 8-9, got {set_target.get('target_rpe')}"

        print("✅ RPE values correctly adjusted for fitness level")


class TestRealGeminiIntegration:
    """Tests that make real calls to Gemini API."""

    def test_gemini_service_initialization(self):
        """Verify Gemini service can be initialized."""
        from services.gemini_service import GeminiService

        gemini = GeminiService()
        assert gemini is not None, "Gemini service should initialize"
        print("✅ Gemini service initialized successfully")

    @pytest.mark.asyncio
    async def test_gemini_generates_workout_name(self):
        """Verify Gemini generates workout name from library exercises."""
        from services.gemini_service import GeminiService
        from services.exercise_rag.service import get_exercise_rag_service

        # First get real exercises from RAG
        rag_service = get_exercise_rag_service()
        exercises = await rag_service.select_exercises_for_workout(
            focus_area="legs",
            equipment=["barbell", "machine"],
            fitness_level="intermediate",
            goals=["build_muscle"],
            count=4,
        )

        # Ensure exercises have set_targets before Gemini
        for ex in exercises:
            assert "set_targets" in ex, f"RAG must add set_targets to '{ex.get('name')}'"

        # Now use Gemini to name the workout
        gemini = GeminiService()
        result = await gemini.generate_workout_from_library(
            exercises=exercises,
            fitness_level="intermediate",
            goals=["build_muscle"],
            duration_minutes=45,
            focus_areas=["legs"],
        )

        assert "name" in result, "Workout must have a name"
        assert len(result["name"]) > 0, "Workout name must not be empty"
        assert "exercises" in result, "Workout must have exercises"
        assert len(result["exercises"]) == len(exercises), "Exercise count should match"

        print(f"✅ Gemini generated workout: '{result['name']}' with {len(result['exercises'])} exercises")


class TestFullWorkoutGenerationPipeline:
    """End-to-end tests for the complete workout generation workflow."""

    @pytest.mark.asyncio
    async def test_full_workout_generation_pipeline(self):
        """Test the complete workout generation pipeline end-to-end."""
        from services.exercise_rag.service import get_exercise_rag_service
        from services.gemini_service import GeminiService, validate_set_targets_strict

        # Step 1: RAG selects exercises
        print("Step 1: RAG selecting exercises from ChromaDB...")
        rag_service = get_exercise_rag_service()
        exercises = await rag_service.select_exercises_for_workout(
            focus_area="chest",
            equipment=["barbell", "dumbbell", "cable"],
            fitness_level="intermediate",
            goals=["build_muscle"],
            count=5,
        )
        print(f"  Selected {len(exercises)} exercises")

        # Step 2: Verify exercises have set_targets BEFORE Gemini
        print("Step 2: Verifying set_targets exist before Gemini...")
        for ex in exercises:
            assert "set_targets" in ex, f"RAG must add set_targets to '{ex.get('name')}'"
            print(f"  - {ex['name']}: {len(ex['set_targets'])} set_targets")

        # Step 3: Gemini names the workout
        print("Step 3: Gemini generating workout name...")
        gemini = GeminiService()
        workout = await gemini.generate_workout_from_library(
            exercises=exercises,
            fitness_level="intermediate",
            goals=["build_muscle"],
            duration_minutes=45,
            focus_areas=["chest"],
        )
        print(f"  Workout named: '{workout['name']}'")

        # Step 4: Validate set_targets (this is what was failing!)
        print("Step 4: Validating set_targets with validate_set_targets_strict()...")
        user_context = {"fitness_level": "intermediate"}
        validated_exercises = validate_set_targets_strict(workout["exercises"], user_context)

        # If we get here without exception, the pipeline works!
        assert len(validated_exercises) == len(exercises)
        print(f"✅ Full pipeline test PASSED with {len(validated_exercises)} exercises")

    @pytest.mark.asyncio
    async def test_pipeline_with_bodyweight_exercises(self):
        """Test pipeline handles bodyweight exercises correctly (the exercises that were failing)."""
        from services.exercise_rag.service import get_exercise_rag_service
        from services.gemini_service import GeminiService, validate_set_targets_strict

        # These are the types of exercises that were failing
        rag_service = get_exercise_rag_service()
        exercises = await rag_service.select_exercises_for_workout(
            focus_area="full_body",
            equipment=["bodyweight"],  # Bodyweight only - like the failing exercises
            fitness_level="intermediate",
            goals=["general_fitness"],
            count=4,
        )

        # Verify set_targets exist
        for ex in exercises:
            assert "set_targets" in ex, f"'{ex.get('name')}' missing set_targets"
            for st in ex["set_targets"]:
                # Bodyweight should have 0 weight
                assert st.get("target_weight_kg", 0) == 0 or ex.get("equipment_type") != "bodyweight", \
                    f"Bodyweight exercise '{ex.get('name')}' should have 0 weight"

        # Validate with strict validation
        gemini = GeminiService()
        workout = await gemini.generate_workout_from_library(
            exercises=exercises,
            fitness_level="intermediate",
            goals=["general_fitness"],
            duration_minutes=30,
            focus_areas=["full_body"],
        )

        user_context = {"fitness_level": "intermediate"}
        validated = validate_set_targets_strict(workout["exercises"], user_context)
        assert len(validated) == len(exercises)
        print(f"✅ Bodyweight pipeline test PASSED with {len(validated)} exercises")

    @pytest.mark.asyncio
    async def test_pipeline_with_different_fitness_levels(self):
        """Test pipeline works correctly for all fitness levels."""
        from services.exercise_rag.service import get_exercise_rag_service
        from services.gemini_service import validate_set_targets_strict

        rag_service = get_exercise_rag_service()

        for fitness_level in ["beginner", "intermediate", "advanced"]:
            exercises = await rag_service.select_exercises_for_workout(
                focus_area="back",
                equipment=["cable", "dumbbell"],
                fitness_level=fitness_level,
                goals=["build_muscle"],
                count=3,
            )

            # Verify set_targets exist and validate
            user_context = {"fitness_level": fitness_level}
            validated = validate_set_targets_strict(exercises, user_context)
            assert len(validated) == len(exercises)
            print(f"  ✅ {fitness_level}: {len(validated)} exercises validated")

        print("✅ All fitness levels passed validation")
