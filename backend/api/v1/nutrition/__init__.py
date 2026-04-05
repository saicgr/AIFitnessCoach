"""
Nutrition API package.

Splits the monolithic nutrition.py (7400+ lines) into focused sub-modules:
- food_logs.py           - Food log CRUD (list, get, delete, update, copy, mood)
- summaries.py           - Daily/weekly summaries and nutrition targets
- barcode.py             - Barcode lookup and logging
- food_search.py         - USDA food search/lookup
- food_logging.py        - Log food from image/text/direct + analyze + review
- food_logging_stream.py - Streaming versions of food logging/analysis
- saved_foods.py         - Saved foods CRUD
- recipes.py             - Recipe CRUD and logging
- micronutrients.py      - Micronutrient tracking and RDAs
- preferences.py         - Nutrition preferences and dynamic targets
- weight_tracking.py     - Weight logs and trend calculation
- onboarding.py          - Nutrition onboarding flow
- streaks.py             - Nutrition streak tracking
- adaptive.py            - Adaptive TDEE calculation
- weekly_recommendations.py - Weekly check-in recommendations
- cooking_conversions.py - Cooking weight conversions
- tdee_adherence.py      - Detailed TDEE, adherence, recommendation options
- food_reports.py        - Food data reports and modifier search

Shared code:
- models.py              - All Pydantic request/response models
- helpers.py             - S3 upload, regional keywords
"""
from fastapi import APIRouter

from api.v1.nutrition import (
    food_logs,
    summaries,
    barcode,
    food_search,
    food_logging,
    food_logging_stream,
    saved_foods,
    recipes,
    micronutrients,
    preferences,
    weight_tracking,
    onboarding,
    streaks,
    adaptive,
    weekly_recommendations,
    cooking_conversions,
    tdee_adherence,
    food_reports,
)

router = APIRouter()

# Include all sub-routers (no prefix — the parent already mounts at /nutrition)
router.include_router(food_logs.router)
router.include_router(summaries.router)
router.include_router(barcode.router)
router.include_router(food_search.router)
router.include_router(food_logging.router)
router.include_router(food_logging_stream.router)
router.include_router(saved_foods.router)
router.include_router(recipes.router)
router.include_router(micronutrients.router)
router.include_router(preferences.router)
router.include_router(weight_tracking.router)
router.include_router(onboarding.router)
router.include_router(streaks.router)
router.include_router(adaptive.router)
router.include_router(weekly_recommendations.router)
router.include_router(cooking_conversions.router)
router.include_router(tdee_adherence.router)
router.include_router(food_reports.router)

# Re-export commonly used models for backward compatibility with test imports
from api.v1.nutrition.models import (  # noqa: E402, F401
    FoodLogResponse,
    DailyNutritionResponse,
    WeeklyNutritionResponse,
    NutritionTargetsResponse,
    LogFoodResponse,
    FoodItemRanking,
    LogTextRequest,
    NutritionPreferencesResponse,
    NutritionPreferencesUpdate,
    DynamicTargetsResponse,
    NutritionOnboardingRequest,
    NutritionStreakResponse,
    AdaptiveCalculationResponse,
    WeightLogCreate,
    WeightLogResponse,
    WeightTrendResponse,
    SkipOnboardingRequest,
)

# Re-export endpoint functions for backward compatibility with test imports
from api.v1.nutrition.food_logs import (  # noqa: E402, F401
    list_food_logs,
    get_food_log,
    delete_food_log,
)
from api.v1.nutrition.summaries import (  # noqa: E402, F401
    get_daily_summary,
    get_weekly_summary,
    get_nutrition_targets,
    update_nutrition_targets,
)
from api.v1.nutrition.food_logging import (  # noqa: E402, F401
    log_food_from_text,
)
from api.v1.nutrition.preferences import (  # noqa: E402, F401
    get_nutrition_preferences,
)
from api.v1.nutrition.weight_tracking import (  # noqa: E402, F401
    create_weight_log,
    get_weight_logs,
    delete_weight_log,
    get_weight_trend,
)
from api.v1.nutrition.onboarding import (  # noqa: E402, F401
    reset_nutrition_onboarding,
)
from api.v1.nutrition.streaks import (  # noqa: E402, F401
    get_nutrition_streak,
    use_streak_freeze,
)
from api.v1.nutrition.adaptive import (  # noqa: E402, F401
    get_adaptive_calculation,
)
from api.v1.nutrition.saved_foods import (  # noqa: E402, F401
    relog_saved_food,
)
