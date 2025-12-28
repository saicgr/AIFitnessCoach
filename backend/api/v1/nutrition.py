"""
Nutrition API endpoints.

ENDPOINTS:
- GET  /api/v1/nutrition/food-logs/{user_id} - List food logs for a user
- GET  /api/v1/nutrition/food-logs/{user_id}/{log_id} - Get a specific food log
- DELETE /api/v1/nutrition/food-logs/{log_id} - Delete a food log
- GET  /api/v1/nutrition/summary/daily/{user_id} - Get daily nutrition summary
- GET  /api/v1/nutrition/summary/weekly/{user_id} - Get weekly nutrition summary
- GET  /api/v1/nutrition/targets/{user_id} - Get user's nutrition targets
- PUT  /api/v1/nutrition/targets/{user_id} - Update user's nutrition targets
- GET  /api/v1/nutrition/barcode/{barcode} - Lookup product by barcode
- POST /api/v1/nutrition/log-barcode - Log food from barcode scan
- POST /api/v1/nutrition/log-image - Log food from image (Gemini Vision)
- POST /api/v1/nutrition/log-text - Log food from text description

RECIPE ENDPOINTS:
- POST /api/v1/nutrition/recipes - Create a new recipe
- GET  /api/v1/nutrition/recipes - List user's recipes
- GET  /api/v1/nutrition/recipes/{recipe_id} - Get a specific recipe
- PUT  /api/v1/nutrition/recipes/{recipe_id} - Update a recipe
- DELETE /api/v1/nutrition/recipes/{recipe_id} - Delete a recipe
- POST /api/v1/nutrition/recipes/{recipe_id}/log - Log a recipe as a meal
- POST /api/v1/nutrition/recipes/{recipe_id}/ingredients - Add ingredient to recipe
- DELETE /api/v1/nutrition/recipes/{recipe_id}/ingredients/{ingredient_id} - Remove ingredient

MICRONUTRIENT ENDPOINTS:
- GET  /api/v1/nutrition/micronutrients/{user_id} - Get daily micronutrient summary
- GET  /api/v1/nutrition/micronutrients/{user_id}/contributors/{nutrient} - Get top contributors
- GET  /api/v1/nutrition/rdas - Get all RDA values
- PUT  /api/v1/nutrition/pinned-nutrients/{user_id} - Update pinned nutrients
"""
from datetime import datetime
from typing import List, Optional, AsyncGenerator
import uuid
import base64
import json
import time
from fastapi import APIRouter, HTTPException, Query, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from core.rate_limiter import limiter

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from models.schemas import (
    FoodLog,
    FoodItem,
    DailyNutritionSummary,
    NutritionTargets,
    UpdateNutritionTargetsRequest,
)


from services.food_database_service import get_food_database_service
from services.gemini_service import GeminiService
from services.nutrition_rag_service import get_nutrition_rag_service
from services.saved_foods_rag_service import get_saved_foods_rag_service
from models.saved_food import (
    SavedFood,
    SavedFoodCreate,
    SavedFoodUpdate,
    SavedFoodsResponse,
    SaveFoodFromLogRequest,
    RelogSavedFoodRequest,
    SavedFoodSummary,
    SearchSavedFoodsRequest,
    SimilarFoodsResponse,
    FoodSourceType,
)
from models.recipe import (
    Recipe,
    RecipeCreate,
    RecipeUpdate,
    RecipeSummary,
    RecipesResponse,
    RecipeIngredient,
    RecipeIngredientCreate,
    LogRecipeRequest,
    LogRecipeResponse,
    NutrientProgress,
    NutrientRDA,
    DailyMicronutrientSummary,
    NutrientContributorsResponse,
    NutrientContributor,
    RecipeCategory,
    RecipeSourceType,
)

router = APIRouter()
logger = get_logger(__name__)


# Response models
class FoodLogResponse(BaseModel):
    """Food log response model."""
    id: str
    user_id: str
    meal_type: str
    logged_at: str
    food_items: List[dict]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    health_score: Optional[int] = None
    ai_feedback: Optional[str] = None
    created_at: str


class DailyNutritionResponse(BaseModel):
    """Daily nutrition summary response."""
    date: str
    total_calories: int
    total_protein_g: float
    total_carbs_g: float
    total_fat_g: float
    total_fiber_g: float
    meal_count: int
    avg_health_score: Optional[float] = None
    meals: List[FoodLogResponse] = []


class WeeklyNutritionResponse(BaseModel):
    """Weekly nutrition summary response."""
    start_date: str
    end_date: str
    daily_summaries: List[dict]
    total_calories: int
    average_daily_calories: float
    total_meals: int


class NutritionTargetsResponse(BaseModel):
    """Nutrition targets response."""
    user_id: str
    daily_calorie_target: Optional[int] = None
    daily_protein_target_g: Optional[float] = None
    daily_carbs_target_g: Optional[float] = None
    

class BarcodeProductResponse(BaseModel):
    """Barcode product lookup response."""
    barcode: str
    product_name: str
    brand: Optional[str] = None
    categories: Optional[str] = None
    image_url: Optional[str] = None
    image_thumb_url: Optional[str] = None
    nutrients: dict
    nutriscore_grade: Optional[str] = None
    nova_group: Optional[int] = None
    ingredients_text: Optional[str] = None
    allergens: Optional[str] = None


class LogBarcodeRequest(BaseModel):
    """Request to log food from barcode."""
    user_id: str
    barcode: str
    meal_type: str  # breakfast, lunch, dinner, snack
    servings: float = 1.0
    serving_size_g: Optional[float] = None  # Override serving size


class LogBarcodeResponse(BaseModel):
    """Response after logging food from barcode."""
    success: bool
    food_log_id: str
    product_name: str
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float


class LogTextRequest(BaseModel):
    """Request to log food from text description."""
    user_id: str
    description: str  # e.g., "2 eggs, toast with butter, and orange juice"
    meal_type: str  # breakfast, lunch, dinner, snack


class FoodItemRanking(BaseModel):
    """Individual food item with goal-based ranking."""
    name: str
    amount: Optional[str] = None
    calories: int = 0
    protein_g: float = 0.0
    carbs_g: float = 0.0
    fat_g: float = 0.0
    fiber_g: Optional[float] = None
    # Ranking fields (optional for backward compatibility)
    goal_score: Optional[int] = None  # 1-10 based on user goals
    goal_alignment: Optional[str] = None  # "excellent", "good", "neutral", "poor"
    reason: Optional[str] = None  # Brief explanation


class LogFoodResponse(BaseModel):
    """Response after logging food from image or text with goal-based analysis."""
    success: bool
    food_log_id: str
    food_items: List[dict]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None
    # Enhanced fields for goal-based analysis
    overall_meal_score: Optional[int] = None  # 1-10 weighted average
    health_score: Optional[int] = None  # 1-10 general health score
    goal_alignment_percentage: Optional[int] = None  # 0-100%
    ai_suggestion: Optional[str] = None  # Personalized AI feedback
    encouragements: Optional[List[str]] = None  # Positive aspects
    warnings: Optional[List[str]] = None  # Concerns (high sodium, etc.)
    recommended_swap: Optional[str] = None  # Healthier alternative


@router.get("/food-logs/{user_id}", response_model=List[FoodLogResponse])
async def list_food_logs(
    user_id: str,
    limit: int = Query(default=50, le=100),
    from_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(default=None, description="End date (YYYY-MM-DD)"),
    meal_type: Optional[str] = Query(default=None, description="Filter by meal type"),
):
    """
    List food logs for a user.

    Optional filters:
    - from_date: Filter logs from this date
    - to_date: Filter logs until this date
    - meal_type: Filter by meal type (breakfast, lunch, dinner, snack)
    """
    logger.info(f"Listing food logs for user {user_id}, limit={limit}")

    try:
        db = get_supabase_db()
        logs = db.list_food_logs(
            user_id=user_id,
            from_date=from_date,
            to_date=to_date,
            meal_type=meal_type,
            limit=limit
        )

        # Format response
        result = []
        for log in logs:
            result.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=str(log.get("logged_at", "")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                created_at=str(log.get("created_at", "")),
            ))

        logger.info(f"Returning {len(result)} food logs for user {user_id}")
        return result

    except Exception as e:
        logger.error(f"Failed to list food logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/food-logs/{user_id}/{log_id}", response_model=FoodLogResponse)
async def get_food_log(user_id: str, log_id: str):
    """Get a specific food log."""
    logger.info(f"Getting food log {log_id} for user {user_id}")

    try:
        db = get_supabase_db()
        log = db.get_food_log(log_id)

        if not log:
            raise HTTPException(status_code=404, detail="Food log not found")

        # Verify ownership
        if log.get("user_id") != user_id:
            raise HTTPException(status_code=403, detail="Access denied")

        return FoodLogResponse(
            id=log.get("id"),
            user_id=log.get("user_id"),
            meal_type=log.get("meal_type"),
            logged_at=str(log.get("logged_at", "")),
            food_items=log.get("food_items", []),
            total_calories=log.get("total_calories", 0),
            protein_g=log.get("protein_g", 0),
            carbs_g=log.get("carbs_g", 0),
            fat_g=log.get("fat_g", 0),
            fiber_g=log.get("fiber_g"),
            health_score=log.get("health_score"),
            ai_feedback=log.get("ai_feedback"),
            created_at=str(log.get("created_at", "")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get food log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/food-logs/{log_id}")
async def delete_food_log(log_id: str):
    """Delete a food log."""
    logger.info(f"Deleting food log {log_id}")

    try:
        db = get_supabase_db()
        success = db.delete_food_log(log_id)

        if not success:
            raise HTTPException(status_code=404, detail="Food log not found")

        return {"status": "deleted", "id": log_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete food log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary/daily/{user_id}", response_model=DailyNutritionResponse)
async def get_daily_summary(
    user_id: str,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
):
    """
    Get daily nutrition summary for a user.

    Returns total calories, macros, and list of meals for the day.
    """
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")

    logger.info(f"Getting daily nutrition summary for user {user_id}, date={date}")

    try:
        db = get_supabase_db()

        # Get summary
        summary = db.get_daily_nutrition_summary(user_id, date)

        # Get meals for the day - use full timestamp range to include all meals
        start_of_day = f"{date}T00:00:00"
        end_of_day = f"{date}T23:59:59"
        meals = db.list_food_logs(
            user_id=user_id,
            from_date=start_of_day,
            to_date=end_of_day,
            limit=20
        )

        meal_responses = []
        for log in meals:
            meal_responses.append(FoodLogResponse(
                id=log.get("id"),
                user_id=log.get("user_id"),
                meal_type=log.get("meal_type"),
                logged_at=str(log.get("logged_at", "")),
                food_items=log.get("food_items", []),
                total_calories=log.get("total_calories", 0),
                protein_g=log.get("protein_g", 0),
                carbs_g=log.get("carbs_g", 0),
                fat_g=log.get("fat_g", 0),
                fiber_g=log.get("fiber_g"),
                health_score=log.get("health_score"),
                ai_feedback=log.get("ai_feedback"),
                created_at=str(log.get("created_at", "")),
            ))

        return DailyNutritionResponse(
            date=date,
            total_calories=summary.get("total_calories", 0) or 0,
            total_protein_g=summary.get("total_protein_g", 0) or 0,
            total_carbs_g=summary.get("total_carbs_g", 0) or 0,
            total_fat_g=summary.get("total_fat_g", 0) or 0,
            total_fiber_g=summary.get("total_fiber_g", 0) or 0,
            meal_count=summary.get("meal_count", 0) or 0,
            avg_health_score=summary.get("avg_health_score"),
            meals=meal_responses,
        )

    except Exception as e:
        logger.error(f"Failed to get daily summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary/weekly/{user_id}", response_model=WeeklyNutritionResponse)
async def get_weekly_summary(
    user_id: str,
    start_date: Optional[str] = Query(default=None, description="Start date (YYYY-MM-DD), defaults to 7 days ago"),
):
    """
    Get weekly nutrition summary for a user.

    Returns daily summaries for 7 days starting from start_date.
    """
    if start_date is None:
        # Default to 7 days ago
        from datetime import timedelta
        start_date = (datetime.now() - timedelta(days=6)).strftime("%Y-%m-%d")

    logger.info(f"Getting weekly nutrition summary for user {user_id}, start_date={start_date}")

    try:
        db = get_supabase_db()

        # Get weekly summary
        daily_summaries = db.get_weekly_nutrition_summary(user_id, start_date)

        # Calculate totals
        total_calories = 0
        total_meals = 0

        for day in daily_summaries:
            total_calories += day.get("total_calories", 0) or 0
            total_meals += day.get("meal_count", 0) or 0

        days_with_data = len([d for d in daily_summaries if d.get("total_calories")])
        avg_daily_calories = total_calories / days_with_data if days_with_data > 0 else 0

        # Calculate end date
        from datetime import timedelta
        start = datetime.strptime(start_date, "%Y-%m-%d")
        end_date = (start + timedelta(days=6)).strftime("%Y-%m-%d")

        return WeeklyNutritionResponse(
            start_date=start_date,
            end_date=end_date,
            daily_summaries=daily_summaries,
            total_calories=total_calories,
            average_daily_calories=avg_daily_calories,
            total_meals=total_meals,
        )

    except Exception as e:
        logger.error(f"Failed to get weekly summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def get_nutrition_targets(user_id: str):
    """Get user's nutrition targets."""
    logger.info(f"Getting nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()
        targets = db.get_user_nutrition_targets(user_id)

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=targets.get("daily_calorie_target"),
            daily_protein_target_g=targets.get("daily_protein_target_g"),
            daily_carbs_target_g=targets.get("daily_carbs_target_g"),
            daily_fat_target_g=targets.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition targets: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/targets/{user_id}", response_model=NutritionTargetsResponse)
async def update_nutrition_targets(user_id: str, request: UpdateNutritionTargetsRequest):
    """Update user's nutrition targets."""
    logger.info(f"Updating nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()

        # Update targets
        updated = db.update_user_nutrition_targets(
            user_id=user_id,
            daily_calorie_target=request.daily_calorie_target,
            daily_protein_target_g=request.daily_protein_target_g,
            daily_carbs_target_g=request.daily_carbs_target_g,
            daily_fat_target_g=request.daily_fat_target_g,
        )

        return NutritionTargetsResponse(
            user_id=user_id,
            daily_calorie_target=updated.get("daily_calorie_target"),
            daily_protein_target_g=updated.get("daily_protein_target_g"),
            daily_carbs_target_g=updated.get("daily_carbs_target_g"),
            daily_fat_target_g=updated.get("daily_fat_target_g"),
        )

    except Exception as e:
        logger.error(f"Failed to update nutrition targets: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ============================================
# Barcode Scanning Endpoints
# ============================================


@router.get("/barcode/{barcode}", response_model=BarcodeProductResponse)
async def lookup_barcode(barcode: str):
    """
    Look up a product by barcode using Open Food Facts API.
    
    Returns product information including:
    - Product name and brand
    - Nutritional information (per 100g and per serving)
    - Nutri-Score grade
    - Ingredients and allergens
    """
    logger.info(f"Looking up barcode: {barcode}")
    
    try:
        service = get_food_database_service()
        product = await service.lookup_barcode(barcode)
        
        if not product:
            raise HTTPException(
                status_code=404, 
                detail=f"Product not found for barcode: {barcode}"
            )
        
        return BarcodeProductResponse(
            barcode=product.barcode,
            product_name=product.product_name,
            brand=product.brand,
            categories=product.categories,
            image_url=product.image_url,
            image_thumb_url=product.image_thumb_url,
            nutrients=product.nutrients.to_dict(),
            nutriscore_grade=product.nutriscore_grade,
            nova_group=product.nova_group,
            ingredients_text=product.ingredients_text,
            allergens=product.allergens,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to lookup barcode {barcode}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/log-barcode", response_model=LogBarcodeResponse)
async def log_food_from_barcode(request: LogBarcodeRequest):
    """
    Log food to meal diary from barcode scan.
    
    This endpoint:
    1. Looks up the product by barcode
    2. Calculates nutrition based on servings
    3. Creates a food log entry
    """
    logger.info(f"Logging barcode {request.barcode} for user {request.user_id}")
    
    try:
        # First, lookup the product
        service = get_food_database_service()
        product = await service.lookup_barcode(request.barcode)
        
        if not product:
            raise HTTPException(
                status_code=404,
                detail=f"Product not found for barcode: {request.barcode}"
            )
        
        # Calculate serving size
        serving_size_g = request.serving_size_g
        if serving_size_g is None:
            serving_size_g = product.nutrients.serving_size_g or 100.0
        
        # Calculate nutrition based on servings
        total_grams = serving_size_g * request.servings
        multiplier = total_grams / 100.0
        
        total_calories = int(product.nutrients.calories_per_100g * multiplier)
        protein_g = round(product.nutrients.protein_per_100g * multiplier, 1)
        carbs_g = round(product.nutrients.carbs_per_100g * multiplier, 1)
        fat_g = round(product.nutrients.fat_per_100g * multiplier, 1)
        fiber_g = round(product.nutrients.fiber_per_100g * multiplier, 1)
        
        # Create food item
        food_item = {
            "name": product.product_name,
            "amount": f"{total_grams:.0f}g ({request.servings} serving{'s' if request.servings != 1 else ''})",
            "calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "barcode": request.barcode,
            "brand": product.brand,
        }
        
        # Create food log
        db = get_supabase_db()

        # Save to database using positional arguments
        created_log = db.create_food_log(
            user_id=request.user_id,
            meal_type=request.meal_type,
            food_items=[food_item],
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=None,
            health_score=None,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged barcode {request.barcode} as {food_log_id}")
        
        return LogBarcodeResponse(
            success=True,
            food_log_id=food_log_id,
            product_name=product.product_name,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
        )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log barcode {request.barcode}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# AI-Powered Food Logging Endpoints
# ============================================


@router.post("/log-image", response_model=LogFoodResponse)
async def log_food_from_image(
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
):
    """
    Log food from an image using Gemini Vision.

    This endpoint:
    1. Analyzes the food image with Gemini Vision
    2. Extracts food items and estimates nutrition
    3. Creates a food log entry
    """
    logger.info(f"Logging food from image for user {user_id}, meal_type={meal_type}")

    try:
        # Read and encode image
        image_bytes = await image.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')

        # Determine mime type
        content_type = image.content_type or 'image/jpeg'

        # Analyze image with Gemini
        logger.info(f"Analyzing image: size={len(image_bytes)} bytes, mime_type={content_type}")
        gemini_service = GeminiService()
        food_analysis = await gemini_service.analyze_food_image(
            image_base64=image_base64,
            mime_type=content_type,
        )
        logger.info(f"Gemini analysis result: {food_analysis}")

        if not food_analysis or not food_analysis.get('food_items'):
            logger.warning(f"No food items identified in image. Analysis result: {food_analysis}")
            raise HTTPException(
                status_code=400,
                detail="Could not identify any food items in the image"
            )

        # Extract data from analysis
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Create food log
        db = get_supabase_db()

        # Save to database using positional arguments
        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=food_analysis.get('feedback'),
            health_score=None,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food from image as {food_log_id}")

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from image: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/log-text", response_model=LogFoodResponse)
async def log_food_from_text(request: LogTextRequest):
    """
    Log food from a text description using Gemini with goal-based analysis.

    This endpoint:
    1. Fetches user's fitness goals and nutrition targets
    2. Parses the text description with Gemini (with goal context)
    3. Extracts food items with per-item rankings
    4. Creates a food log entry with AI suggestions

    Example descriptions:
    - "2 eggs, toast with butter, and orange juice"
    - "chicken salad with grilled chicken, lettuce, tomatoes, and ranch dressing"
    - "a bowl of oatmeal with banana and honey"
    """
    logger.info(f"Logging food from text for user {request.user_id}: {request.description[:50]}...")

    try:
        db = get_supabase_db()

        # Fetch user goals and nutrition targets for personalized analysis
        user_goals = None
        nutrition_targets = None
        try:
            user = db.get_user(request.user_id)
            if user:
                # Parse goals from JSON string
                goals_str = user.get('goals', '[]')
                if isinstance(goals_str, str):
                    import json
                    try:
                        user_goals = json.loads(goals_str)
                    except json.JSONDecodeError:
                        user_goals = []
                elif isinstance(goals_str, list):
                    user_goals = goals_str

                # Get nutrition targets
                nutrition_targets = {
                    'daily_calorie_target': user.get('daily_calorie_target'),
                    'daily_protein_target_g': user.get('daily_protein_target_g'),
                    'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                    'daily_fat_target_g': user.get('daily_fat_target_g'),
                }
                logger.info(f"User goals: {user_goals}, targets: {nutrition_targets}")
        except Exception as e:
            logger.warning(f"Could not fetch user goals/targets: {e}")

        # Get RAG context from nutrition knowledge base (if user has goals)
        rag_context = None
        if user_goals:
            try:
                nutrition_rag = get_nutrition_rag_service()
                rag_context = await nutrition_rag.get_context_for_goals(
                    food_description=request.description,
                    user_goals=user_goals,
                    n_results=5,
                )
                if rag_context:
                    logger.info(f"Retrieved RAG context ({len(rag_context)} chars) for goals: {user_goals}")
            except Exception as e:
                logger.warning(f"Could not fetch RAG context: {e}")

        # Parse description with Gemini (with goal context + RAG)
        gemini_service = GeminiService()
        food_analysis = await gemini_service.parse_food_description(
            description=request.description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
        )

        if not food_analysis or not food_analysis.get('food_items'):
            raise HTTPException(
                status_code=400,
                detail="Could not parse any food items from the description"
            )

        # Extract data from analysis
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Extract enhanced analysis fields
        overall_meal_score = food_analysis.get('overall_meal_score')
        health_score = food_analysis.get('health_score')
        goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
        ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
        encouragements = food_analysis.get('encouragements', [])
        warnings = food_analysis.get('warnings', [])
        recommended_swap = food_analysis.get('recommended_swap')

        # Save to database using positional arguments
        created_log = db.create_food_log(
            user_id=request.user_id,
            meal_type=request.meal_type,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            ai_feedback=ai_suggestion,
            health_score=health_score,
        )

        # Get the food log ID from the created record
        food_log_id = created_log.get('id') if created_log else "unknown"

        logger.info(f"Successfully logged food from text as {food_log_id}")

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            overall_meal_score=overall_meal_score,
            health_score=health_score,
            goal_alignment_percentage=goal_alignment_percentage,
            ai_suggestion=ai_suggestion,
            encouragements=encouragements,
            warnings=warnings,
            recommended_swap=recommended_swap,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from text: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Streaming Food Logging Endpoints
# ============================================


@router.post("/log-text-stream")
@limiter.limit("10/minute")
async def log_food_from_text_streaming(request: Request, body: LogTextRequest):
    """
    Log food from text description with streaming progress updates via SSE.

    Provides real-time feedback during food analysis:
    - Step 1: Loading user profile and goals
    - Step 2: Analyzing food with AI
    - Step 3: Calculating nutrition
    - Step 4: Saving to database

    Returns SSE events with progress updates and final food log.
    """
    logger.info(f"[STREAM] Logging food from text for user {body.user_id}: {body.description[:50]}...")

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "step": step,
                "total_steps": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Load user profile and goals
            yield send_progress(1, 4, "Loading your profile...", "Fetching nutrition goals")

            db = get_supabase_db()

            user_goals = None
            nutrition_targets = None
            try:
                user = db.get_user(body.user_id)
                if user:
                    goals_str = user.get('goals', '[]')
                    if isinstance(goals_str, str):
                        try:
                            user_goals = json.loads(goals_str)
                        except json.JSONDecodeError:
                            user_goals = []
                    elif isinstance(goals_str, list):
                        user_goals = goals_str

                    nutrition_targets = {
                        'daily_calorie_target': user.get('daily_calorie_target'),
                        'daily_protein_target_g': user.get('daily_protein_target_g'),
                        'daily_carbs_target_g': user.get('daily_carbs_target_g'),
                        'daily_fat_target_g': user.get('daily_fat_target_g'),
                    }
            except Exception as e:
                logger.warning(f"[STREAM] Could not fetch user goals: {e}")

            # Step 2: Get RAG context and analyze with AI
            yield send_progress(2, 4, "Analyzing your food...", "AI is identifying ingredients")

            rag_context = None
            if user_goals:
                try:
                    nutrition_rag = get_nutrition_rag_service()
                    rag_context = await nutrition_rag.get_context_for_goals(
                        food_description=body.description,
                        user_goals=user_goals,
                        n_results=5,
                    )
                except Exception as e:
                    logger.warning(f"[STREAM] Could not fetch RAG context: {e}")

            gemini_service = GeminiService()
            food_analysis = await gemini_service.parse_food_description(
                description=body.description,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                rag_context=rag_context,
            )

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items from your description")
                return

            # Step 3: Calculate nutrition
            yield send_progress(3, 4, "Calculating nutrition...", f"Found {len(food_analysis.get('food_items', []))} items")

            food_items = food_analysis.get('food_items', [])
            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)
            overall_meal_score = food_analysis.get('overall_meal_score')
            health_score = food_analysis.get('health_score')
            goal_alignment_percentage = food_analysis.get('goal_alignment_percentage')
            ai_suggestion = food_analysis.get('ai_suggestion') or food_analysis.get('feedback')
            encouragements = food_analysis.get('encouragements', [])
            warnings = food_analysis.get('warnings', [])
            recommended_swap = food_analysis.get('recommended_swap')

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving your meal...", "Almost done!")

            created_log = db.create_food_log(
                user_id=body.user_id,
                meal_type=body.meal_type,
                food_items=food_items,
                total_calories=total_calories,
                protein_g=protein_g,
                carbs_g=carbs_g,
                fat_g=fat_g,
                fiber_g=fiber_g,
                ai_feedback=ai_suggestion,
                health_score=health_score,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from text as {food_log_id}")

            # Send the completed food log
            response_data = {
                "success": True,
                "food_log_id": food_log_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "overall_meal_score": overall_meal_score,
                "health_score": health_score,
                "goal_alignment_percentage": goal_alignment_percentage,
                "ai_suggestion": ai_suggestion,
                "encouragements": encouragements,
                "warnings": warnings,
                "recommended_swap": recommended_swap,
                "total_time_ms": elapsed_ms(),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Food logging error: {e}")
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


@router.post("/log-image-stream")
@limiter.limit("10/minute")
async def log_food_from_image_streaming(
    request: Request,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
):
    """
    Log food from an image with streaming progress updates via SSE.

    Provides real-time feedback during food image analysis:
    - Step 1: Processing image
    - Step 2: AI analyzing food
    - Step 3: Calculating nutrition
    - Step 4: Saving to database

    Returns SSE events with progress updates and final food log.
    """
    logger.info(f"[STREAM] Logging food from image for user {user_id}, meal_type={meal_type}")

    # Read image upfront (before generator)
    image_bytes = await image.read()
    content_type = image.content_type or 'image/jpeg'

    async def generate_sse() -> AsyncGenerator[str, None]:
        start_time = time.time()

        def elapsed_ms() -> int:
            return int((time.time() - start_time) * 1000)

        def send_progress(step: int, total: int, message: str, detail: str = None):
            data = {
                "type": "progress",
                "step": step,
                "total_steps": total,
                "message": message,
                "detail": detail,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str):
            data = {"type": "error", "error": error, "elapsed_ms": elapsed_ms()}
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Process image
            yield send_progress(1, 4, "Processing image...", f"{len(image_bytes) // 1024} KB")

            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            # Step 2: Analyze with AI
            yield send_progress(2, 4, "Analyzing your food...", "AI is identifying ingredients")

            gemini_service = GeminiService()
            food_analysis = await gemini_service.analyze_food_image(
                image_base64=image_base64,
                mime_type=content_type,
            )

            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error("Could not identify any food items in the image")
                return

            # Step 3: Calculate nutrition
            food_items = food_analysis.get('food_items', [])
            yield send_progress(3, 4, "Calculating nutrition...", f"Found {len(food_items)} items")

            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)

            # Step 4: Save to database
            yield send_progress(4, 4, "Saving your meal...", "Almost done!")

            db = get_supabase_db()
            created_log = db.create_food_log(
                user_id=user_id,
                meal_type=meal_type,
                food_items=food_items,
                total_calories=total_calories,
                protein_g=protein_g,
                carbs_g=carbs_g,
                fat_g=fat_g,
                fiber_g=fiber_g,
                ai_feedback=food_analysis.get('feedback'),
                health_score=None,
            )

            food_log_id = created_log.get('id') if created_log else "unknown"
            logger.info(f"[STREAM] Successfully logged food from image as {food_log_id}")

            # Send the completed food log
            response_data = {
                "success": True,
                "food_log_id": food_log_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "total_time_ms": elapsed_ms(),
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[STREAM] Image food logging error: {e}")
            yield send_error(str(e))

    return StreamingResponse(
        generate_sse(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        }
    )


# ============================================
# Saved Foods (Favorite Recipes) Endpoints
# ============================================


@router.post("/saved-foods", response_model=SavedFood)
async def save_food(user_id: str = Form(...), request: SaveFoodFromLogRequest = None):
    """
    Save a meal as a favorite recipe.

    This endpoint:
    1. Creates a saved_foods entry in the database
    2. Stores the meal in ChromaDB for semantic search
    """
    logger.info(f"Saving food for user {user_id}: {request.name if request else 'N/A'}")

    try:
        db = get_supabase_db()

        # Generate ID
        saved_food_id = str(uuid.uuid4())

        # Prepare food items for storage
        food_items_data = [
            {
                "name": item.name,
                "amount": item.amount,
                "calories": item.calories,
                "protein_g": item.protein_g,
                "carbs_g": item.carbs_g,
                "fat_g": item.fat_g,
                "fiber_g": item.fiber_g,
                "goal_score": item.goal_score,
                "goal_alignment": item.goal_alignment,
            }
            for item in request.food_items
        ] if request.food_items else []

        # Insert into database
        now = datetime.now().isoformat()
        saved_food_data = {
            "id": saved_food_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "source_type": request.source_type.value if request.source_type else "text",
            "barcode": request.barcode,
            "image_url": request.image_url,
            "total_calories": request.total_calories,
            "total_protein_g": request.total_protein_g,
            "total_carbs_g": request.total_carbs_g,
            "total_fat_g": request.total_fat_g,
            "total_fiber_g": request.total_fiber_g,
            "food_items": food_items_data,
            "overall_meal_score": request.overall_meal_score,
            "goal_alignment_percentage": request.goal_alignment_percentage,
            "tags": request.tags or [],
            "notes": None,
            "times_logged": 0,
            "last_logged_at": None,
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
        }

        # Save to database
        result = db.client.table("saved_foods").insert(saved_food_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save food to database")

        # Save to ChromaDB for semantic search
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.save_food(
                saved_food_id=saved_food_id,
                user_id=user_id,
                name=request.name,
                description=request.description,
                food_items=food_items_data,
                total_calories=request.total_calories,
                total_protein_g=request.total_protein_g,
                source_type=request.source_type.value if request.source_type else "text",
                tags=request.tags,
            )
        except Exception as e:
            logger.warning(f"Failed to save food to ChromaDB: {e}")
            # Continue - database save is the primary storage

        logger.info(f"Successfully saved food {saved_food_id}")

        # Return saved food
        saved_data = result.data[0]
        return SavedFood(
            id=saved_data["id"],
            user_id=saved_data["user_id"],
            name=saved_data["name"],
            description=saved_data.get("description"),
            source_type=FoodSourceType(saved_data.get("source_type", "text")),
            barcode=saved_data.get("barcode"),
            image_url=saved_data.get("image_url"),
            total_calories=saved_data.get("total_calories"),
            total_protein_g=saved_data.get("total_protein_g"),
            total_carbs_g=saved_data.get("total_carbs_g"),
            total_fat_g=saved_data.get("total_fat_g"),
            total_fiber_g=saved_data.get("total_fiber_g"),
            food_items=saved_data.get("food_items", []),
            overall_meal_score=saved_data.get("overall_meal_score"),
            goal_alignment_percentage=saved_data.get("goal_alignment_percentage"),
            tags=saved_data.get("tags", []),
            notes=saved_data.get("notes"),
            times_logged=saved_data.get("times_logged", 0),
            last_logged_at=saved_data.get("last_logged_at"),
            created_at=datetime.fromisoformat(saved_data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(saved_data["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save food: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/saved-foods/save", response_model=SavedFood)
async def save_food_json(request: SaveFoodFromLogRequest, user_id: str = Query(...)):
    """
    Save a meal as a favorite recipe (JSON body version).

    This endpoint:
    1. Creates a saved_foods entry in the database
    2. Stores the meal in ChromaDB for semantic search
    """
    logger.info(f"Saving food for user {user_id}: {request.name}")

    try:
        db = get_supabase_db()

        # Generate ID
        saved_food_id = str(uuid.uuid4())

        # Prepare food items for storage
        food_items_data = [
            {
                "name": item.name,
                "amount": item.amount,
                "calories": item.calories,
                "protein_g": item.protein_g,
                "carbs_g": item.carbs_g,
                "fat_g": item.fat_g,
                "fiber_g": item.fiber_g,
                "goal_score": item.goal_score,
                "goal_alignment": item.goal_alignment,
            }
            for item in request.food_items
        ] if request.food_items else []

        # Insert into database
        now = datetime.now().isoformat()
        saved_food_data = {
            "id": saved_food_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "source_type": request.source_type.value if request.source_type else "text",
            "barcode": request.barcode,
            "image_url": request.image_url,
            "total_calories": request.total_calories,
            "total_protein_g": request.total_protein_g,
            "total_carbs_g": request.total_carbs_g,
            "total_fat_g": request.total_fat_g,
            "total_fiber_g": request.total_fiber_g,
            "food_items": food_items_data,
            "overall_meal_score": request.overall_meal_score,
            "goal_alignment_percentage": request.goal_alignment_percentage,
            "tags": request.tags or [],
            "notes": None,
            "times_logged": 0,
            "last_logged_at": None,
            "created_at": now,
            "updated_at": now,
            "deleted_at": None,
        }

        # Save to database
        result = db.client.table("saved_foods").insert(saved_food_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save food to database")

        # Save to ChromaDB for semantic search
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.save_food(
                saved_food_id=saved_food_id,
                user_id=user_id,
                name=request.name,
                description=request.description,
                food_items=food_items_data,
                total_calories=request.total_calories,
                total_protein_g=request.total_protein_g,
                source_type=request.source_type.value if request.source_type else "text",
                tags=request.tags,
            )
        except Exception as e:
            logger.warning(f"Failed to save food to ChromaDB: {e}")

        logger.info(f"Successfully saved food {saved_food_id}")

        # Return saved food
        saved_data = result.data[0]
        return SavedFood(
            id=saved_data["id"],
            user_id=saved_data["user_id"],
            name=saved_data["name"],
            description=saved_data.get("description"),
            source_type=FoodSourceType(saved_data.get("source_type", "text")),
            barcode=saved_data.get("barcode"),
            image_url=saved_data.get("image_url"),
            total_calories=saved_data.get("total_calories"),
            total_protein_g=saved_data.get("total_protein_g"),
            total_carbs_g=saved_data.get("total_carbs_g"),
            total_fat_g=saved_data.get("total_fat_g"),
            total_fiber_g=saved_data.get("total_fiber_g"),
            food_items=saved_data.get("food_items", []),
            overall_meal_score=saved_data.get("overall_meal_score"),
            goal_alignment_percentage=saved_data.get("goal_alignment_percentage"),
            tags=saved_data.get("tags", []),
            notes=saved_data.get("notes"),
            times_logged=saved_data.get("times_logged", 0),
            last_logged_at=saved_data.get("last_logged_at"),
            created_at=datetime.fromisoformat(saved_data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(saved_data["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to save food: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/saved-foods", response_model=SavedFoodsResponse)
async def list_saved_foods(
    user_id: str = Query(...),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    source_type: Optional[str] = Query(default=None),
):
    """
    List saved foods (favorite recipes) for a user.
    """
    logger.info(f"Listing saved foods for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("saved_foods")\
            .select("*")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .order("times_logged", desc=True)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)

        if source_type:
            query = query.eq("source_type", source_type)

        result = query.execute()

        # Get total count
        count_result = db.client.table("saved_foods")\
            .select("id", count="exact")\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .execute()

        total_count = count_result.count or 0

        # Parse results
        items = []
        for row in result.data or []:
            items.append(SavedFood(
                id=row["id"],
                user_id=row["user_id"],
                name=row["name"],
                description=row.get("description"),
                source_type=FoodSourceType(row.get("source_type", "text")),
                barcode=row.get("barcode"),
                image_url=row.get("image_url"),
                total_calories=row.get("total_calories"),
                total_protein_g=row.get("total_protein_g"),
                total_carbs_g=row.get("total_carbs_g"),
                total_fat_g=row.get("total_fat_g"),
                total_fiber_g=row.get("total_fiber_g"),
                food_items=row.get("food_items", []),
                overall_meal_score=row.get("overall_meal_score"),
                goal_alignment_percentage=row.get("goal_alignment_percentage"),
                tags=row.get("tags", []),
                notes=row.get("notes"),
                times_logged=row.get("times_logged", 0),
                last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
                updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
                deleted_at=None,
            ))

        return SavedFoodsResponse(items=items, total_count=total_count)

    except Exception as e:
        logger.error(f"Failed to list saved foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/saved-foods/{saved_food_id}", response_model=SavedFood)
async def get_saved_food(saved_food_id: str, user_id: str = Query(...)):
    """
    Get a specific saved food.
    """
    logger.info(f"Getting saved food {saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("saved_foods")\
            .select("*")\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        row = result.data
        return SavedFood(
            id=row["id"],
            user_id=row["user_id"],
            name=row["name"],
            description=row.get("description"),
            source_type=FoodSourceType(row.get("source_type", "text")),
            barcode=row.get("barcode"),
            image_url=row.get("image_url"),
            total_calories=row.get("total_calories"),
            total_protein_g=row.get("total_protein_g"),
            total_carbs_g=row.get("total_carbs_g"),
            total_fat_g=row.get("total_fat_g"),
            total_fiber_g=row.get("total_fiber_g"),
            food_items=row.get("food_items", []),
            overall_meal_score=row.get("overall_meal_score"),
            goal_alignment_percentage=row.get("goal_alignment_percentage"),
            tags=row.get("tags", []),
            notes=row.get("notes"),
            times_logged=row.get("times_logged", 0),
            last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
            created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
            deleted_at=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get saved food: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/saved-foods/{saved_food_id}")
async def delete_saved_food(saved_food_id: str, user_id: str = Query(...)):
    """
    Delete a saved food (soft delete).
    """
    logger.info(f"Deleting saved food {saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Soft delete
        result = db.client.table("saved_foods")\
            .update({"deleted_at": datetime.now().isoformat()})\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        # Also delete from ChromaDB
        try:
            rag_service = get_saved_foods_rag_service()
            await rag_service.delete_food(saved_food_id)
        except Exception as e:
            logger.warning(f"Failed to delete food from ChromaDB: {e}")

        return {"status": "deleted", "id": saved_food_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete saved food: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/saved-foods/{saved_food_id}/log", response_model=LogFoodResponse)
async def relog_saved_food(
    saved_food_id: str,
    request: RelogSavedFoodRequest,
    user_id: str = Query(...),
):
    """
    Re-log a saved food to today's meal diary.
    """
    logger.info(f"Re-logging saved food {saved_food_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get the saved food
        result = db.client.table("saved_foods")\
            .select("*")\
            .eq("id", saved_food_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Saved food not found")

        saved_food = result.data

        # Create food log from saved food
        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=request.meal_type,
            food_items=saved_food.get("food_items", []),
            total_calories=saved_food.get("total_calories", 0),
            protein_g=saved_food.get("total_protein_g", 0),
            carbs_g=saved_food.get("total_carbs_g", 0),
            fat_g=saved_food.get("total_fat_g", 0),
            fiber_g=saved_food.get("total_fiber_g"),
            ai_feedback=None,
            health_score=saved_food.get("overall_meal_score"),
        )

        food_log_id = created_log.get('id') if created_log else "unknown"

        # Update times_logged
        db.client.table("saved_foods")\
            .update({
                "times_logged": saved_food.get("times_logged", 0) + 1,
                "last_logged_at": datetime.now().isoformat(),
                "updated_at": datetime.now().isoformat(),
            })\
            .eq("id", saved_food_id)\
            .execute()

        logger.info(f"Successfully re-logged saved food {saved_food_id} as {food_log_id}")

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=saved_food.get("food_items", []),
            total_calories=saved_food.get("total_calories", 0),
            protein_g=saved_food.get("total_protein_g", 0),
            carbs_g=saved_food.get("total_carbs_g", 0),
            fat_g=saved_food.get("total_fat_g", 0),
            fiber_g=saved_food.get("total_fiber_g"),
            overall_meal_score=saved_food.get("overall_meal_score"),
            health_score=saved_food.get("overall_meal_score"),
            goal_alignment_percentage=saved_food.get("goal_alignment_percentage"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to re-log saved food: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/saved-foods/search", response_model=SimilarFoodsResponse)
async def search_saved_foods(
    request: SearchSavedFoodsRequest,
    user_id: str = Query(...),
):
    """
    Search saved foods using semantic search.
    """
    logger.info(f"Searching saved foods for user {user_id}: {request.query}")

    try:
        if not request.query:
            raise HTTPException(status_code=400, detail="Query is required")

        rag_service = get_saved_foods_rag_service()
        results = await rag_service.search_similar(
            query=request.query,
            user_id=user_id,
            n_results=request.limit,
            min_calories=request.min_calories,
            max_calories=request.max_calories,
        )

        similar_foods = [
            SavedFoodSummary(
                id=r["id"],
                name=r["name"],
                total_calories=r.get("total_calories"),
                total_protein_g=r.get("total_protein_g"),
                source_type=FoodSourceType(r.get("source_type", "text")),
                times_logged=0,  # Not available from ChromaDB
                last_logged_at=None,
                created_at=datetime.now(),  # Not available from ChromaDB
                tags=r.get("tags", []),
            )
            for r in results
        ]

        return SimilarFoodsResponse(
            similar_foods=similar_foods,
            query=request.query,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to search saved foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Recipe Endpoints
# ============================================


@router.post("/recipes", response_model=Recipe)
async def create_recipe(request: RecipeCreate, user_id: str = Query(...)):
    """
    Create a new recipe with ingredients.

    The recipe's nutrition values are automatically calculated from ingredients.
    """
    logger.info(f"Creating recipe '{request.name}' for user {user_id}")

    try:
        db = get_supabase_db()

        # Generate ID
        recipe_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        # Create recipe
        recipe_data = {
            "id": recipe_id,
            "user_id": user_id,
            "name": request.name,
            "description": request.description,
            "servings": request.servings,
            "prep_time_minutes": request.prep_time_minutes,
            "cook_time_minutes": request.cook_time_minutes,
            "instructions": request.instructions,
            "image_url": request.image_url,
            "category": request.category.value if request.category else None,
            "cuisine": request.cuisine,
            "tags": request.tags or [],
            "source_url": request.source_url,
            "source_type": request.source_type.value,
            "is_public": request.is_public,
            "times_logged": 0,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("user_recipes").insert(recipe_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create recipe")

        # Add ingredients
        ingredients = []
        for idx, ing in enumerate(request.ingredients):
            ing_id = str(uuid.uuid4())
            ing_data = {
                "id": ing_id,
                "recipe_id": recipe_id,
                "ingredient_order": idx,
                "food_name": ing.food_name,
                "brand": ing.brand,
                "amount": ing.amount,
                "unit": ing.unit,
                "amount_grams": ing.amount_grams,
                "barcode": ing.barcode,
                "calories": ing.calories,
                "protein_g": ing.protein_g,
                "carbs_g": ing.carbs_g,
                "fat_g": ing.fat_g,
                "fiber_g": ing.fiber_g,
                "sugar_g": ing.sugar_g,
                "vitamin_d_iu": ing.vitamin_d_iu,
                "calcium_mg": ing.calcium_mg,
                "iron_mg": ing.iron_mg,
                "sodium_mg": ing.sodium_mg,
                "omega3_g": ing.omega3_g,
                "notes": ing.notes,
                "is_optional": ing.is_optional,
                "created_at": now,
                "updated_at": now,
            }
            db.client.table("recipe_ingredients").insert(ing_data).execute()
            ingredients.append(RecipeIngredient(
                id=ing_id,
                recipe_id=recipe_id,
                ingredient_order=idx,
                food_name=ing.food_name,
                brand=ing.brand,
                amount=ing.amount,
                unit=ing.unit,
                amount_grams=ing.amount_grams,
                barcode=ing.barcode,
                calories=ing.calories,
                protein_g=ing.protein_g,
                carbs_g=ing.carbs_g,
                fat_g=ing.fat_g,
                fiber_g=ing.fiber_g,
                sugar_g=ing.sugar_g,
                vitamin_d_iu=ing.vitamin_d_iu,
                calcium_mg=ing.calcium_mg,
                iron_mg=ing.iron_mg,
                sodium_mg=ing.sodium_mg,
                omega3_g=ing.omega3_g,
                notes=ing.notes,
                is_optional=ing.is_optional,
                created_at=datetime.fromisoformat(now),
                updated_at=datetime.fromisoformat(now),
            ))

        # Fetch the updated recipe (trigger will have calculated nutrition)
        updated = db.client.table("user_recipes").select("*").eq("id", recipe_id).single().execute()

        logger.info(f"Successfully created recipe {recipe_id}")

        return Recipe(
            id=updated.data["id"],
            user_id=updated.data["user_id"],
            name=updated.data["name"],
            description=updated.data.get("description"),
            servings=updated.data.get("servings", 1),
            prep_time_minutes=updated.data.get("prep_time_minutes"),
            cook_time_minutes=updated.data.get("cook_time_minutes"),
            instructions=updated.data.get("instructions"),
            image_url=updated.data.get("image_url"),
            category=RecipeCategory(updated.data["category"]) if updated.data.get("category") else None,
            cuisine=updated.data.get("cuisine"),
            tags=updated.data.get("tags", []),
            source_url=updated.data.get("source_url"),
            source_type=RecipeSourceType(updated.data.get("source_type", "manual")),
            is_public=updated.data.get("is_public", False),
            calories_per_serving=updated.data.get("calories_per_serving"),
            protein_per_serving_g=updated.data.get("protein_per_serving_g"),
            carbs_per_serving_g=updated.data.get("carbs_per_serving_g"),
            fat_per_serving_g=updated.data.get("fat_per_serving_g"),
            fiber_per_serving_g=updated.data.get("fiber_per_serving_g"),
            sugar_per_serving_g=updated.data.get("sugar_per_serving_g"),
            vitamin_d_per_serving_iu=updated.data.get("vitamin_d_per_serving_iu"),
            calcium_per_serving_mg=updated.data.get("calcium_per_serving_mg"),
            iron_per_serving_mg=updated.data.get("iron_per_serving_mg"),
            omega3_per_serving_g=updated.data.get("omega3_per_serving_g"),
            sodium_per_serving_mg=updated.data.get("sodium_per_serving_mg"),
            times_logged=updated.data.get("times_logged", 0),
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=datetime.fromisoformat(updated.data["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(updated.data["updated_at"].replace("Z", "+00:00")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create recipe: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recipes", response_model=RecipesResponse)
async def list_recipes(
    user_id: str = Query(...),
    limit: int = Query(default=50, le=100),
    offset: int = Query(default=0, ge=0),
    category: Optional[str] = Query(default=None),
    include_public: bool = Query(default=False),
):
    """
    List user's recipes with optional public recipes.
    """
    logger.info(f"Listing recipes for user {user_id}")

    try:
        db = get_supabase_db()

        # Build query
        query = db.client.table("user_recipes")\
            .select("id, name, category, calories_per_serving, protein_per_serving_g, servings, times_logged, image_url, created_at")\
            .is_("deleted_at", "null")\
            .order("times_logged", desc=True)\
            .order("created_at", desc=True)\
            .range(offset, offset + limit - 1)

        if include_public:
            query = query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            query = query.eq("user_id", user_id)

        if category:
            query = query.eq("category", category)

        result = query.execute()

        # Get ingredient counts
        items = []
        for row in result.data or []:
            # Count ingredients
            count_result = db.client.table("recipe_ingredients")\
                .select("id", count="exact")\
                .eq("recipe_id", row["id"])\
                .execute()
            ingredient_count = count_result.count or 0

            items.append(RecipeSummary(
                id=row["id"],
                name=row["name"],
                category=row.get("category"),
                calories_per_serving=row.get("calories_per_serving"),
                protein_per_serving_g=row.get("protein_per_serving_g"),
                servings=row.get("servings", 1),
                ingredient_count=ingredient_count,
                times_logged=row.get("times_logged", 0),
                image_url=row.get("image_url"),
                created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            ))

        # Get total count
        count_query = db.client.table("user_recipes")\
            .select("id", count="exact")\
            .is_("deleted_at", "null")

        if include_public:
            count_query = count_query.or_(f"user_id.eq.{user_id},is_public.eq.true")
        else:
            count_query = count_query.eq("user_id", user_id)

        if category:
            count_query = count_query.eq("category", category)

        count_result = count_query.execute()
        total_count = count_result.count or 0

        return RecipesResponse(items=items, total_count=total_count)

    except Exception as e:
        logger.error(f"Failed to list recipes: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recipes/{recipe_id}", response_model=Recipe)
async def get_recipe(recipe_id: str, user_id: str = Query(...)):
    """
    Get a specific recipe with all ingredients.
    """
    logger.info(f"Getting recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get recipe
        result = db.client.table("user_recipes")\
            .select("*")\
            .eq("id", recipe_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        row = result.data

        # Check ownership or public
        if row["user_id"] != user_id and not row.get("is_public"):
            raise HTTPException(status_code=403, detail="Access denied")

        # Get ingredients
        ing_result = db.client.table("recipe_ingredients")\
            .select("*")\
            .eq("recipe_id", recipe_id)\
            .order("ingredient_order")\
            .execute()

        ingredients = [
            RecipeIngredient(
                id=ing["id"],
                recipe_id=ing["recipe_id"],
                ingredient_order=ing.get("ingredient_order", 0),
                food_name=ing["food_name"],
                brand=ing.get("brand"),
                amount=ing["amount"],
                unit=ing["unit"],
                amount_grams=ing.get("amount_grams"),
                barcode=ing.get("barcode"),
                calories=ing.get("calories"),
                protein_g=ing.get("protein_g"),
                carbs_g=ing.get("carbs_g"),
                fat_g=ing.get("fat_g"),
                fiber_g=ing.get("fiber_g"),
                sugar_g=ing.get("sugar_g"),
                vitamin_d_iu=ing.get("vitamin_d_iu"),
                calcium_mg=ing.get("calcium_mg"),
                iron_mg=ing.get("iron_mg"),
                sodium_mg=ing.get("sodium_mg"),
                omega3_g=ing.get("omega3_g"),
                notes=ing.get("notes"),
                is_optional=ing.get("is_optional", False),
                created_at=datetime.fromisoformat(ing["created_at"].replace("Z", "+00:00")),
                updated_at=datetime.fromisoformat(ing["updated_at"].replace("Z", "+00:00")),
            )
            for ing in (ing_result.data or [])
        ]

        return Recipe(
            id=row["id"],
            user_id=row["user_id"],
            name=row["name"],
            description=row.get("description"),
            servings=row.get("servings", 1),
            prep_time_minutes=row.get("prep_time_minutes"),
            cook_time_minutes=row.get("cook_time_minutes"),
            instructions=row.get("instructions"),
            image_url=row.get("image_url"),
            category=RecipeCategory(row["category"]) if row.get("category") else None,
            cuisine=row.get("cuisine"),
            tags=row.get("tags", []),
            source_url=row.get("source_url"),
            source_type=RecipeSourceType(row.get("source_type", "manual")),
            is_public=row.get("is_public", False),
            calories_per_serving=row.get("calories_per_serving"),
            protein_per_serving_g=row.get("protein_per_serving_g"),
            carbs_per_serving_g=row.get("carbs_per_serving_g"),
            fat_per_serving_g=row.get("fat_per_serving_g"),
            fiber_per_serving_g=row.get("fiber_per_serving_g"),
            sugar_per_serving_g=row.get("sugar_per_serving_g"),
            vitamin_d_per_serving_iu=row.get("vitamin_d_per_serving_iu"),
            calcium_per_serving_mg=row.get("calcium_per_serving_mg"),
            iron_per_serving_mg=row.get("iron_per_serving_mg"),
            omega3_per_serving_g=row.get("omega3_per_serving_g"),
            sodium_per_serving_mg=row.get("sodium_per_serving_mg"),
            times_logged=row.get("times_logged", 0),
            last_logged_at=datetime.fromisoformat(row["last_logged_at"].replace("Z", "+00:00")) if row.get("last_logged_at") else None,
            ingredients=ingredients,
            ingredient_count=len(ingredients),
            created_at=datetime.fromisoformat(row["created_at"].replace("Z", "+00:00")),
            updated_at=datetime.fromisoformat(row["updated_at"].replace("Z", "+00:00")),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recipe: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/recipes/{recipe_id}")
async def delete_recipe(recipe_id: str, user_id: str = Query(...)):
    """
    Delete a recipe (soft delete).
    """
    logger.info(f"Deleting recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("user_recipes")\
            .update({"deleted_at": datetime.now().isoformat()})\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        return {"status": "deleted", "id": recipe_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to delete recipe: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/recipes/{recipe_id}/log", response_model=LogRecipeResponse)
async def log_recipe(
    recipe_id: str,
    request: LogRecipeRequest,
    user_id: str = Query(...),
):
    """
    Log a recipe as a meal (like re-logging a saved food).
    """
    logger.info(f"Logging recipe {recipe_id} for user {user_id}")

    try:
        db = get_supabase_db()

        # Get the recipe
        result = db.client.table("user_recipes")\
            .select("*")\
            .eq("id", recipe_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        recipe = result.data

        # Check ownership or public
        if recipe["user_id"] != user_id and not recipe.get("is_public"):
            raise HTTPException(status_code=403, detail="Access denied")

        # Calculate nutrition based on servings
        calories = int((recipe.get("calories_per_serving") or 0) * request.servings)
        protein = round((recipe.get("protein_per_serving_g") or 0) * request.servings, 2)
        carbs = round((recipe.get("carbs_per_serving_g") or 0) * request.servings, 2)
        fat = round((recipe.get("fat_per_serving_g") or 0) * request.servings, 2)
        fiber = round((recipe.get("fiber_per_serving_g") or 0) * request.servings, 2) if recipe.get("fiber_per_serving_g") else None

        # Create food log
        food_items = [{
            "name": recipe["name"],
            "amount": f"{request.servings} serving{'s' if request.servings != 1 else ''}",
            "calories": calories,
            "protein_g": protein,
            "carbs_g": carbs,
            "fat_g": fat,
            "is_recipe": True,
            "recipe_id": recipe_id,
        }]

        created_log = db.create_food_log(
            user_id=user_id,
            meal_type=request.meal_type,
            food_items=food_items,
            total_calories=calories,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=fiber,
            ai_feedback=None,
            health_score=None,
        )

        # Also update the food_logs table with recipe_id
        food_log_id = created_log.get('id') if created_log else "unknown"
        if food_log_id != "unknown":
            db.client.table("food_logs")\
                .update({"recipe_id": recipe_id})\
                .eq("id", food_log_id)\
                .execute()

        logger.info(f"Successfully logged recipe {recipe_id} as {food_log_id}")

        return LogRecipeResponse(
            success=True,
            food_log_id=food_log_id,
            recipe_name=recipe["name"],
            servings=request.servings,
            total_calories=calories,
            protein_g=protein,
            carbs_g=carbs,
            fat_g=fat,
            fiber_g=fiber,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log recipe: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/recipes/{recipe_id}/ingredients", response_model=RecipeIngredient)
async def add_ingredient(
    recipe_id: str,
    request: RecipeIngredientCreate,
    user_id: str = Query(...),
):
    """
    Add an ingredient to a recipe.
    """
    logger.info(f"Adding ingredient to recipe {recipe_id}")

    try:
        db = get_supabase_db()

        # Verify recipe ownership
        recipe_result = db.client.table("user_recipes")\
            .select("id, user_id")\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not recipe_result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        # Create ingredient
        ing_id = str(uuid.uuid4())
        now = datetime.now().isoformat()

        ing_data = {
            "id": ing_id,
            "recipe_id": recipe_id,
            "ingredient_order": request.ingredient_order,
            "food_name": request.food_name,
            "brand": request.brand,
            "amount": request.amount,
            "unit": request.unit,
            "amount_grams": request.amount_grams,
            "barcode": request.barcode,
            "calories": request.calories,
            "protein_g": request.protein_g,
            "carbs_g": request.carbs_g,
            "fat_g": request.fat_g,
            "fiber_g": request.fiber_g,
            "sugar_g": request.sugar_g,
            "vitamin_d_iu": request.vitamin_d_iu,
            "calcium_mg": request.calcium_mg,
            "iron_mg": request.iron_mg,
            "sodium_mg": request.sodium_mg,
            "omega3_g": request.omega3_g,
            "notes": request.notes,
            "is_optional": request.is_optional,
            "created_at": now,
            "updated_at": now,
        }

        result = db.client.table("recipe_ingredients").insert(ing_data).execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to add ingredient")

        return RecipeIngredient(
            id=ing_id,
            recipe_id=recipe_id,
            ingredient_order=request.ingredient_order,
            food_name=request.food_name,
            brand=request.brand,
            amount=request.amount,
            unit=request.unit,
            amount_grams=request.amount_grams,
            barcode=request.barcode,
            calories=request.calories,
            protein_g=request.protein_g,
            carbs_g=request.carbs_g,
            fat_g=request.fat_g,
            fiber_g=request.fiber_g,
            sugar_g=request.sugar_g,
            vitamin_d_iu=request.vitamin_d_iu,
            calcium_mg=request.calcium_mg,
            iron_mg=request.iron_mg,
            sodium_mg=request.sodium_mg,
            omega3_g=request.omega3_g,
            notes=request.notes,
            is_optional=request.is_optional,
            created_at=datetime.fromisoformat(now),
            updated_at=datetime.fromisoformat(now),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to add ingredient: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/recipes/{recipe_id}/ingredients/{ingredient_id}")
async def remove_ingredient(
    recipe_id: str,
    ingredient_id: str,
    user_id: str = Query(...),
):
    """
    Remove an ingredient from a recipe.
    """
    logger.info(f"Removing ingredient {ingredient_id} from recipe {recipe_id}")

    try:
        db = get_supabase_db()

        # Verify recipe ownership
        recipe_result = db.client.table("user_recipes")\
            .select("id, user_id")\
            .eq("id", recipe_id)\
            .eq("user_id", user_id)\
            .is_("deleted_at", "null")\
            .single()\
            .execute()

        if not recipe_result.data:
            raise HTTPException(status_code=404, detail="Recipe not found")

        # Delete ingredient
        result = db.client.table("recipe_ingredients")\
            .delete()\
            .eq("id", ingredient_id)\
            .eq("recipe_id", recipe_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Ingredient not found")

        return {"status": "deleted", "id": ingredient_id}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to remove ingredient: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Micronutrient Endpoints
# ============================================


class PinnedNutrientsUpdate(BaseModel):
    """Update pinned nutrients request."""
    pinned_nutrients: List[str]


@router.get("/micronutrients/{user_id}", response_model=DailyMicronutrientSummary)
async def get_daily_micronutrients(
    user_id: str,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
):
    """
    Get daily micronutrient summary with progress towards RDA goals.

    Returns vitamins, minerals, fatty acids, and other nutrients with
    floor/target/ceiling values and current intake.
    """
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")

    logger.info(f"Getting daily micronutrients for user {user_id}, date={date}")

    try:
        db = get_supabase_db()

        # Get RDA values
        rda_result = db.client.table("nutrient_rdas")\
            .select("*")\
            .order("display_order")\
            .execute()

        rdas = {r["nutrient_key"]: r for r in (rda_result.data or [])}

        # Get user's pinned nutrients
        user = db.get_user(user_id)
        pinned_keys = user.get("pinned_nutrients", ["vitamin_d", "calcium", "iron", "omega3"]) if user else []

        # Get all food logs for the day and sum up micronutrients
        logs = db.list_food_logs(
            user_id=user_id,
            from_date=date,
            to_date=date,
            limit=50
        )

        # Aggregate micronutrients from all logs
        totals = {}
        for log in logs:
            for key in rdas.keys():
                col_name = key  # e.g., 'vitamin_d_iu'
                value = log.get(col_name) or 0
                totals[key] = totals.get(key, 0) + float(value)

        # Build progress for each category
        def make_progress(key: str, rda: dict) -> NutrientProgress:
            current = totals.get(key, 0)
            target = rda.get("rda_target") or 1
            floor_val = rda.get("rda_floor")
            ceiling = rda.get("rda_ceiling")
            percentage = round((current / target) * 100, 1) if target > 0 else 0

            if ceiling and current > ceiling:
                status = "over_ceiling"
            elif current >= target:
                status = "optimal"
            elif floor_val and current >= floor_val:
                status = "adequate"
            else:
                status = "low"

            return NutrientProgress(
                nutrient_key=key,
                display_name=rda.get("display_name", key),
                unit=rda.get("unit", ""),
                category=rda.get("category", "other"),
                current_value=round(current, 2),
                target_value=target,
                floor_value=floor_val,
                ceiling_value=ceiling,
                percentage=percentage,
                status=status,
                color_hex=rda.get("color_hex"),
            )

        vitamins = []
        minerals = []
        fatty_acids = []
        other = []
        pinned = []

        for key, rda in rdas.items():
            progress = make_progress(key, rda)

            if rda["category"] == "vitamin":
                vitamins.append(progress)
            elif rda["category"] == "mineral":
                minerals.append(progress)
            elif rda["category"] == "fatty_acid":
                fatty_acids.append(progress)
            else:
                other.append(progress)

            if key in pinned_keys or key.replace("_ug", "").replace("_mg", "").replace("_g", "").replace("_iu", "") in pinned_keys:
                pinned.append(progress)

        return DailyMicronutrientSummary(
            date=date,
            user_id=user_id,
            vitamins=vitamins,
            minerals=minerals,
            fatty_acids=fatty_acids,
            other=other,
            pinned=pinned[:8],  # Max 8 pinned
        )

    except Exception as e:
        logger.error(f"Failed to get daily micronutrients: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/micronutrients/{user_id}/contributors/{nutrient}", response_model=NutrientContributorsResponse)
async def get_nutrient_contributors(
    user_id: str,
    nutrient: str,
    date: Optional[str] = Query(default=None, description="Date (YYYY-MM-DD), defaults to today"),
    limit: int = Query(default=10, le=20),
):
    """
    Get top food contributors for a specific nutrient.

    Shows which foods contributed the most to the day's intake.
    """
    if date is None:
        date = datetime.now().strftime("%Y-%m-%d")

    logger.info(f"Getting contributors for {nutrient} for user {user_id}, date={date}")

    try:
        db = get_supabase_db()

        # Get RDA info
        rda_result = db.client.table("nutrient_rdas")\
            .select("*")\
            .eq("nutrient_key", nutrient)\
            .single()\
            .execute()

        if not rda_result.data:
            raise HTTPException(status_code=404, detail=f"Unknown nutrient: {nutrient}")

        rda = rda_result.data

        # Get all food logs for the day with this nutrient
        logs = db.list_food_logs(
            user_id=user_id,
            from_date=date,
            to_date=date,
            limit=50
        )

        # Extract contributors
        contributors = []
        total_intake = 0

        for log in logs:
            value = log.get(nutrient) or 0
            if value > 0:
                total_intake += float(value)

                # Get food names from food_items
                food_items = log.get("food_items", [])
                food_name = ", ".join([f.get("name", "Unknown") for f in food_items[:3]])
                if len(food_items) > 3:
                    food_name += f" (+{len(food_items) - 3} more)"

                contributors.append(NutrientContributor(
                    food_log_id=log["id"],
                    food_name=food_name or log.get("meal_type", "Meal"),
                    meal_type=log.get("meal_type", ""),
                    amount=float(value),
                    unit=rda.get("unit", ""),
                    logged_at=datetime.fromisoformat(str(log.get("logged_at", "")).replace("Z", "+00:00")) if log.get("logged_at") else datetime.now(),
                ))

        # Sort by amount descending
        contributors.sort(key=lambda x: x.amount, reverse=True)

        return NutrientContributorsResponse(
            nutrient_key=nutrient,
            display_name=rda.get("display_name", nutrient),
            unit=rda.get("unit", ""),
            total_intake=round(total_intake, 2),
            target=rda.get("rda_target", 0),
            contributors=contributors[:limit],
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get nutrient contributors: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/rdas", response_model=List[NutrientRDA])
async def get_all_rdas():
    """
    Get all RDA (Reference Daily Allowance) values for micronutrients.

    Returns floor/target/ceiling values for all tracked nutrients.
    """
    logger.info("Getting all RDAs")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrient_rdas")\
            .select("*")\
            .order("display_order")\
            .execute()

        return [
            NutrientRDA(
                nutrient_name=r["nutrient_name"],
                nutrient_key=r["nutrient_key"],
                unit=r["unit"],
                category=r["category"],
                rda_floor=r.get("rda_floor"),
                rda_target=r.get("rda_target"),
                rda_ceiling=r.get("rda_ceiling"),
                rda_target_male=r.get("rda_target_male"),
                rda_target_female=r.get("rda_target_female"),
                display_name=r["display_name"],
                display_order=r.get("display_order", 0),
                color_hex=r.get("color_hex"),
            )
            for r in (result.data or [])
        ]

    except Exception as e:
        logger.error(f"Failed to get RDAs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/pinned-nutrients/{user_id}")
async def update_pinned_nutrients(user_id: str, request: PinnedNutrientsUpdate):
    """
    Update user's pinned micronutrients for the dashboard.

    Maximum 8 nutrients can be pinned.
    """
    logger.info(f"Updating pinned nutrients for user {user_id}")

    if len(request.pinned_nutrients) > 8:
        raise HTTPException(status_code=400, detail="Maximum 8 nutrients can be pinned")

    try:
        db = get_supabase_db()

        result = db.client.table("users")\
            .update({"pinned_nutrients": request.pinned_nutrients})\
            .eq("id", user_id)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="User not found")

        return {"status": "updated", "pinned_nutrients": request.pinned_nutrients}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update pinned nutrients: {e}")
        raise HTTPException(status_code=500, detail=str(e))
