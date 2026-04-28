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
    food_patterns,
    summaries,
    barcode,
    food_search,
    food_logging,
    food_logging_stream,
    menu_analyses,
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
    quick_suggestion,
    companions,
    # Recipes Tab v1 additions
    recipe_imports,
    recipe_search,
    recipe_sharing,
    recipe_versions,
    coach_reviews,
    cook_events,
    grocery_lists,
    meal_plans,
    scheduled_recipes,
    # Discover / Favorites / Improvize (migration 1925)
    recipe_favorites,
    recipe_discover,
    recipe_improvize,
    # Daily / weekly AI nutrition reports (item 14)
    reports,
)

router = APIRouter()

# Include all sub-routers (no prefix — the parent already mounts at /nutrition)
router.include_router(food_logs.router)
router.include_router(food_patterns.router)
router.include_router(summaries.router)
router.include_router(barcode.router)
router.include_router(food_search.router)
router.include_router(food_logging.router)
router.include_router(food_logging_stream.router)
router.include_router(menu_analyses.router)
router.include_router(saved_foods.router)

# Recipes Tab v1 — LITERAL-path recipe routers MUST be registered BEFORE
# `recipes.router` because recipes.router defines `GET /recipes/{recipe_id}`
# which would otherwise swallow literal paths like `/recipes/analyze-ingredient`
# and produce 405 Method Not Allowed for POSTs.
router.include_router(recipe_imports.router)
router.include_router(recipe_search.router)
router.include_router(recipe_sharing.router)
router.include_router(recipe_versions.router)
router.include_router(coach_reviews.router)
router.include_router(cook_events.router)
router.include_router(grocery_lists.router)
router.include_router(meal_plans.router)
router.include_router(scheduled_recipes.router)
# Discover / Favorites / Improvize — literal paths, MUST be before recipes.router
# so `/recipes/favorites`, `/recipes/discover`, `/recipes/{id}/favorite`, and
# `/recipes/{id}/improvize` aren't swallowed by `GET /recipes/{recipe_id}`.
router.include_router(recipe_favorites.router)
router.include_router(recipe_discover.router)
router.include_router(recipe_improvize.router)

# Catch-all recipes router (includes `GET /recipes/{recipe_id}`) registered last
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
router.include_router(quick_suggestion.router)
router.include_router(companions.router)
router.include_router(reports.router)

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
