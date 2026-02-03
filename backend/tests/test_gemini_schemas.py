"""
Tests for Gemini API Response Schemas.

These tests verify that all Pydantic models used with Gemini's
response_schema parameter are valid and can be instantiated.
"""

import pytest
from pydantic import ValidationError

from models.gemini_schemas import (
    # Intent extraction
    IntentExtractionResponse,
    CoachIntentEnum,
    # Exercise extraction
    ExerciseListResponse,
    ExerciseIndicesResponse,
    # Workout generation
    SetTargetSchema,
    WorkoutExerciseSchema,
    GeneratedWorkoutResponse,
    WorkoutNameItem,
    WorkoutNamesResponse,
    WorkoutNamingResponse,
    ExerciseReasoningItem,
    ExerciseReasoningResponse,
    # Food analysis
    FoodItemSchema,
    FoodAnalysisResponse,
    # Inflammation
    IngredientAnalysisSchema,
    InflammationAnalysisGeminiResponse,
    # Warmup/Stretch
    WarmupExerciseSchema,
    WarmupResponse,
    StretchExerciseSchema,
    StretchResponse,
    # Calibration
    CalibrationExerciseSchema,
    CalibrationWorkoutResponse,
    PerformanceAnalysisResponse,
    # Custom goals
    CustomGoalItem,
    CustomGoalsResponse,
    # Fasting
    FastingImpactResponse,
    # Meal planning
    MealItemSchema,
    DailyMealPlanResponse,
    MealSuggestionItem,
    MealSuggestionsResponse,
    SnackItemSchema,
    SnackSuggestionsResponse,
    # Workout suggestions
    WorkoutSuggestionSchema,
    WorkoutSuggestionsResponse,
    # Custom goal keywords
    CustomGoalKeywordsResponse,
    # Fasting insight
    FastingInsightResponse,
)


class TestIntentExtractionSchemas:
    """Test intent extraction schemas."""

    def test_intent_extraction_valid(self):
        """Test IntentExtractionResponse with valid data."""
        data = IntentExtractionResponse(
            intent="question",
            exercises=["bench press", "squats"],
            muscle_groups=["chest", "legs"],
        )
        assert data.intent == "question"
        assert len(data.exercises) == 2
        assert len(data.muscle_groups) == 2

    def test_intent_extraction_minimal(self):
        """Test IntentExtractionResponse with minimal data."""
        data = IntentExtractionResponse(intent="start_workout")
        assert data.intent == "start_workout"
        assert data.exercises == []
        assert data.muscle_groups == []

    def test_intent_extraction_with_optionals(self):
        """Test IntentExtractionResponse with optional fields."""
        data = IntentExtractionResponse(
            intent="change_setting",
            setting_name="sound",
            setting_value=True,
            hydration_amount=8,
        )
        assert data.setting_name == "sound"
        assert data.setting_value is True
        assert data.hydration_amount == 8


class TestExerciseSchemas:
    """Test exercise-related schemas."""

    def test_exercise_list_response(self):
        """Test ExerciseListResponse."""
        data = ExerciseListResponse(
            exercises=["Push-ups", "Pull-ups", "Squats"]
        )
        assert len(data.exercises) == 3

    def test_exercise_indices_response(self):
        """Test ExerciseIndicesResponse."""
        data = ExerciseIndicesResponse(
            selected_indices=[1, 3, 5, 2, 4]
        )
        assert len(data.selected_indices) == 5
        assert data.selected_indices[0] == 1


class TestWorkoutGenerationSchemas:
    """Test workout generation schemas."""

    def test_workout_exercise_schema(self):
        """Test WorkoutExerciseSchema with valid data. Note: set_type is required."""
        set_targets = [
            SetTargetSchema(set_number=1, target_reps=10, target_weight_kg=60.0, set_type="warmup"),
            SetTargetSchema(set_number=2, target_reps=10, target_weight_kg=60.0, set_type="working"),
            SetTargetSchema(set_number=3, target_reps=10, target_weight_kg=60.0, set_type="working"),
        ]
        exercise = WorkoutExerciseSchema(
            name="Bench Press",
            sets=3,
            reps=10,
            rest_seconds=90,
            weight_kg=60.0,
            equipment="barbell",
            muscle_group="chest",
            set_targets=set_targets,
        )
        assert exercise.name == "Bench Press"
        assert exercise.sets == 3
        assert exercise.weight_kg == 60.0
        assert len(exercise.set_targets) == 3

    def test_workout_exercise_schema_defaults(self):
        """Test WorkoutExerciseSchema with defaults. Note: set_type is required."""
        set_targets = [
            SetTargetSchema(set_number=1, target_reps=12, set_type="warmup"),
            SetTargetSchema(set_number=2, target_reps=12, set_type="working"),
            SetTargetSchema(set_number=3, target_reps=12, set_type="working"),
        ]
        exercise = WorkoutExerciseSchema(name="Push-ups", set_targets=set_targets)
        assert exercise.sets == 3
        assert exercise.reps == 12
        assert exercise.rest_seconds == 60
        assert exercise.is_unilateral is False

    def test_generated_workout_response(self):
        """Test GeneratedWorkoutResponse with valid data."""
        bench_targets = [
            SetTargetSchema(set_number=1, target_reps=10, set_type="warmup"),
            SetTargetSchema(set_number=2, target_reps=10, set_type="working"),
            SetTargetSchema(set_number=3, target_reps=10, set_type="working"),
        ]
        incline_targets = [
            SetTargetSchema(set_number=1, target_reps=10, set_type="warmup"),
            SetTargetSchema(set_number=2, target_reps=10, set_type="working"),
            SetTargetSchema(set_number=3, target_reps=10, set_type="working"),
        ]
        workout = GeneratedWorkoutResponse(
            name="Power Chest Day",
            type="strength",
            difficulty="medium",
            duration_minutes=45,
            target_muscles=["chest", "triceps"],
            exercises=[
                WorkoutExerciseSchema(name="Bench Press", set_targets=bench_targets),
                WorkoutExerciseSchema(name="Incline Press", set_targets=incline_targets),
            ],
        )
        assert workout.name == "Power Chest Day"
        assert len(workout.exercises) == 2
        assert workout.duration_minutes == 45

    def test_exercise_reasoning_response(self):
        """Test ExerciseReasoningResponse."""
        reasoning = ExerciseReasoningResponse(
            workout_reasoning="This workout focuses on building upper body strength.",
            exercise_reasoning=[
                ExerciseReasoningItem(
                    exercise_name="Bench Press",
                    reasoning="Primary chest builder for strength."
                ),
            ],
        )
        assert "upper body" in reasoning.workout_reasoning
        assert len(reasoning.exercise_reasoning) == 1

    def test_workout_naming_response(self):
        """Test WorkoutNamingResponse - the schema for generate_workout_from_library.

        This schema is used when RAG provides exercises and we only need Gemini
        to generate a creative name and notes. It does NOT include exercises.
        """
        naming = WorkoutNamingResponse(
            name="Thunder Strike Chest",
            type="strength",
            difficulty="medium",
            notes="Focus on controlled movements and progressive overload.",
        )
        assert naming.name == "Thunder Strike Chest"
        assert naming.type == "strength"
        assert naming.difficulty == "medium"
        assert naming.notes is not None

    def test_workout_naming_response_minimal(self):
        """Test WorkoutNamingResponse with only required fields."""
        naming = WorkoutNamingResponse(
            name="Power Push",
            type="strength",
            difficulty="easy",
        )
        assert naming.name == "Power Push"
        assert naming.notes is None  # Optional field


class TestFoodAnalysisSchemas:
    """Test food analysis schemas."""

    def test_food_item_schema(self):
        """Test FoodItemSchema."""
        food = FoodItemSchema(
            name="Chicken Breast",
            amount="150g",
            calories=165,
            protein_g=31.0,
            carbs_g=0.0,
            fat_g=3.6,
        )
        assert food.name == "Chicken Breast"
        assert food.calories == 165
        assert food.protein_g == 31.0

    def test_food_analysis_response(self):
        """Test FoodAnalysisResponse with valid data."""
        analysis = FoodAnalysisResponse(
            food_items=[
                FoodItemSchema(
                    name="Rice",
                    amount="200g",
                    calories=260,
                    protein_g=5.0,
                    carbs_g=57.0,
                    fat_g=0.6,
                ),
            ],
            total_calories=260,
            protein_g=5.0,
            carbs_g=57.0,
            fat_g=0.6,
            feedback="Good source of carbohydrates.",
        )
        assert len(analysis.food_items) == 1
        assert analysis.total_calories == 260


class TestInflammationSchemas:
    """Test inflammation analysis schemas."""

    def test_ingredient_analysis_schema(self):
        """Test IngredientAnalysisSchema."""
        ingredient = IngredientAnalysisSchema(
            name="Turmeric",
            category="anti_inflammatory",
            score=9,
            reason="Contains curcumin, a powerful anti-inflammatory compound.",
            is_inflammatory=False,
        )
        assert ingredient.name == "Turmeric"
        assert ingredient.score == 9
        assert ingredient.is_inflammatory is False

    def test_inflammation_analysis_response(self):
        """Test InflammationAnalysisGeminiResponse."""
        analysis = InflammationAnalysisGeminiResponse(
            overall_score=7,
            overall_category="anti_inflammatory",
            summary="This product is generally anti-inflammatory.",
            ingredient_analyses=[],
        )
        assert analysis.overall_score == 7
        assert analysis.overall_category == "anti_inflammatory"


class TestWarmupStretchSchemas:
    """Test warmup and stretch schemas."""

    def test_warmup_response(self):
        """Test WarmupResponse."""
        warmup = WarmupResponse(
            exercises=[
                WarmupExerciseSchema(
                    name="Arm Circles",
                    sets=1,
                    reps=10,
                    duration_seconds=30,
                ),
            ],
            duration_minutes=5,
        )
        assert len(warmup.exercises) == 1
        assert warmup.duration_minutes == 5

    def test_stretch_response(self):
        """Test StretchResponse."""
        stretch = StretchResponse(
            exercises=[
                StretchExerciseSchema(
                    name="Hamstring Stretch",
                    duration_seconds=30,
                    muscle_group="hamstrings",
                ),
            ],
        )
        assert len(stretch.exercises) == 1


class TestCalibrationSchemas:
    """Test calibration workout schemas."""

    def test_calibration_workout_response(self):
        """Test CalibrationWorkoutResponse."""
        calibration = CalibrationWorkoutResponse(
            difficulty_assessment="User appears to be intermediate level.",
            suggested_level="intermediate",
            exercises=[
                CalibrationExerciseSchema(
                    name="Push-ups",
                    target_reps=15,
                ),
            ],
        )
        assert calibration.suggested_level == "intermediate"
        assert len(calibration.exercises) == 1

    def test_performance_analysis_response(self):
        """Test PerformanceAnalysisResponse."""
        analysis = PerformanceAnalysisResponse(
            performance_score=7,
            next_difficulty_level="intermediate",
            recommendations=["Focus on form before increasing weight."],
        )
        assert analysis.performance_score == 7
        assert len(analysis.recommendations) == 1


class TestMealPlanningSchemas:
    """Test meal planning schemas."""

    def test_daily_meal_plan_response(self):
        """Test DailyMealPlanResponse."""
        plan = DailyMealPlanResponse(
            daily_meals=[
                MealItemSchema(
                    meal_type="breakfast",
                    name="Oatmeal with Berries",
                    description="Healthy breakfast option",
                    calories=350,
                    protein_g=10.0,
                    carbs_g=60.0,
                    fat_g=8.0,
                ),
            ],
            total_calories=350,
            total_protein_g=10.0,
            total_carbs_g=60.0,
            total_fat_g=8.0,
        )
        assert len(plan.daily_meals) == 1
        assert plan.total_calories == 350

    def test_snack_suggestions_response(self):
        """Test SnackSuggestionsResponse."""
        snacks = SnackSuggestionsResponse(
            snacks=[
                SnackItemSchema(
                    name="Greek Yogurt",
                    calories=100,
                    protein_g=17.0,
                    carbs_g=6.0,
                    fat_g=0.7,
                ),
            ],
        )
        assert len(snacks.snacks) == 1


class TestWorkoutSuggestionSchemas:
    """Test workout suggestion schemas."""

    def test_workout_suggestions_response(self):
        """Test WorkoutSuggestionsResponse."""
        suggestions = WorkoutSuggestionsResponse(
            suggestions=[
                WorkoutSuggestionSchema(
                    name="Full Body Blast",
                    type="Strength",
                    difficulty="medium",
                    duration_minutes=45,
                    description="Complete full body workout.",
                    focus_areas=["full body"],
                    sample_exercises=["Squats", "Push-ups"],
                ),
            ],
        )
        assert len(suggestions.suggestions) == 1
        assert suggestions.suggestions[0].name == "Full Body Blast"


class TestCustomGoalSchemas:
    """Test custom goal schemas."""

    def test_custom_goal_keywords_response(self):
        """Test CustomGoalKeywordsResponse."""
        keywords = CustomGoalKeywordsResponse(
            keywords=["plyometrics", "explosive", "power"],
            goal_type="power",
            progression_strategy="wave",
            exercise_categories=["plyometrics"],
            muscle_groups=["legs", "glutes"],
        )
        assert len(keywords.keywords) == 3
        assert keywords.goal_type == "power"


class TestFastingInsightSchemas:
    """Test fasting insight schemas."""

    def test_fasting_insight_response(self):
        """Test FastingInsightResponse."""
        insight = FastingInsightResponse(
            insight_type="positive",
            title="Good Fasting Adherence",
            message="Your fasting schedule aligns well with your workout timing.",
            recommendation="Continue your current fasting window.",
        )
        assert insight.insight_type == "positive"
        assert "fasting" in insight.message.lower()


class TestSchemaValidation:
    """Test schema validation (should reject invalid data)."""

    def test_inflammation_score_range(self):
        """Test that inflammation score must be between 1 and 10."""
        with pytest.raises(ValidationError):
            IngredientAnalysisSchema(
                name="Test",
                category="neutral",
                score=15,  # Invalid: > 10
                reason="Test",
                is_inflammatory=False,
            )

    def test_required_fields(self):
        """Test that required fields are enforced."""
        with pytest.raises(ValidationError):
            # Missing required 'name' field
            WorkoutExerciseSchema()

    def test_generated_workout_requires_exercises(self):
        """Test that GeneratedWorkoutResponse requires exercises."""
        # This should work - exercises is required. Note: set_type is now required.
        test_targets = [
            SetTargetSchema(set_number=1, target_reps=12, set_type="warmup"),
            SetTargetSchema(set_number=2, target_reps=12, set_type="working"),
            SetTargetSchema(set_number=3, target_reps=12, set_type="working"),
        ]
        workout = GeneratedWorkoutResponse(
            name="Test",
            type="strength",
            difficulty="easy",
            duration_minutes=30,
            exercises=[WorkoutExerciseSchema(name="Test Exercise", set_targets=test_targets)],
        )
        assert len(workout.exercises) == 1
