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

COOKING CONVERSION ENDPOINTS:
- GET  /api/v1/nutrition/cooking-conversions - List all cooking conversion factors
- GET  /api/v1/nutrition/cooking-conversions/{food_category} - Get conversions by category
- POST /api/v1/nutrition/convert-weight - Convert between raw and cooked weight
"""
from datetime import datetime, timedelta
from typing import List, Optional, AsyncGenerator, Tuple
import uuid
import base64
import json
import time
import asyncio
import boto3
from fastapi import APIRouter, HTTPException, Query, UploadFile, File, Form, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, validator

from core.rate_limiter import limiter

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error
from models.schemas import (
    FoodLog,
    FoodItem,
    DailyNutritionSummary,
    NutritionTargets,
    UpdateNutritionTargetsRequest,
)


from services.food_database_service import get_food_database_service
from services.cooking_conversion_service import get_cooking_conversion_service
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


# ============================================================================
# S3 Upload Helper for Food Images
# ============================================================================

def get_s3_client():
    """Get S3 client with configured credentials."""
    from core.config import get_settings
    settings = get_settings()
    return boto3.client(
        's3',
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
    )


async def upload_food_image_to_s3(
    file_bytes: bytes,
    user_id: str,
    content_type: str = "image/jpeg",
    source: str = "camera",
    meal_type: str = "meal",
) -> Tuple[str, str]:
    """
    Upload food image to S3 in parallel with Gemini analysis.

    Args:
        file_bytes: Raw image bytes
        user_id: User's UUID
        content_type: MIME type of the image
        source: Source of image ("camera" or "barcode")
        meal_type: Type of meal (breakfast, lunch, dinner, snack)

    Returns:
        Tuple of (image_url, storage_key)

    Path format: images/{source}/{user_id}/{date_timestamp}/{meal_type}_{uuid}.{ext}
    Example: images/camera/abc123/2026-01-11_143052/breakfast_a1b2c3d4.jpg
    """
    from core.config import get_settings
    settings = get_settings()

    # Generate unique storage key with organized path
    date_timestamp = datetime.utcnow().strftime('%Y-%m-%d_%H%M%S')
    ext = content_type.split('/')[-1] if content_type else 'jpeg'
    if ext not in ['jpeg', 'jpg', 'png', 'webp', 'gif']:
        ext = 'jpeg'
    unique_id = uuid.uuid4().hex[:8]
    storage_key = f"images/{source}/{user_id}/{date_timestamp}/{meal_type}_{unique_id}.{ext}"

    # Upload to S3 (runs in thread pool to not block event loop)
    def _upload():
        s3 = get_s3_client()
        s3.put_object(
            Bucket=settings.s3_bucket_name,
            Key=storage_key,
            Body=file_bytes,
            ContentType=content_type,
        )

    loop = asyncio.get_event_loop()
    await loop.run_in_executor(None, _upload)

    # Generate public URL
    image_url = f"https://{settings.s3_bucket_name}.s3.{settings.aws_default_region}.amazonaws.com/{storage_key}"

    logger.info(f"Uploaded food image to S3: {storage_key}")
    return image_url, storage_key


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

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


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

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


class LogDirectRequest(BaseModel):
    """Request to log already-analyzed food directly (e.g., from restaurant mode with portion adjustments)."""
    user_id: str
    meal_type: str  # breakfast, lunch, dinner, snack
    food_items: List[dict]
    total_calories: int
    total_protein: int
    total_carbs: int
    total_fat: int
    total_fiber: Optional[int] = None
    source_type: str = "restaurant"  # restaurant, manual, adjusted
    notes: Optional[str] = None
    # Micronutrients
    sodium_mg: Optional[float] = None
    sugar_g: Optional[float] = None
    saturated_fat_g: Optional[float] = None
    cholesterol_mg: Optional[float] = None
    potassium_mg: Optional[float] = None
    vitamin_a_ug: Optional[float] = None
    vitamin_c_mg: Optional[float] = None
    vitamin_d_iu: Optional[float] = None
    vitamin_e_mg: Optional[float] = None
    vitamin_k_ug: Optional[float] = None
    vitamin_b1_mg: Optional[float] = None
    vitamin_b2_mg: Optional[float] = None
    vitamin_b3_mg: Optional[float] = None
    vitamin_b5_mg: Optional[float] = None
    vitamin_b6_mg: Optional[float] = None
    vitamin_b7_ug: Optional[float] = None
    vitamin_b9_ug: Optional[float] = None
    vitamin_b12_ug: Optional[float] = None
    calcium_mg: Optional[float] = None
    iron_mg: Optional[float] = None
    magnesium_mg: Optional[float] = None
    zinc_mg: Optional[float] = None
    phosphorus_mg: Optional[float] = None
    copper_mg: Optional[float] = None
    manganese_mg: Optional[float] = None
    selenium_ug: Optional[float] = None
    choline_mg: Optional[float] = None
    omega3_g: Optional[float] = None
    omega6_g: Optional[float] = None

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v


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
    # AI confidence for estimates
    confidence_score: Optional[float] = None  # 0.0-1.0 confidence in analysis
    confidence_level: Optional[str] = None  # 'low', 'medium', 'high'
    source_type: Optional[str] = None  # 'image', 'text', 'barcode', 'restaurant'


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
    import re

    # Validate barcode format BEFORE lookup
    cleaned = barcode.strip().replace(" ", "").replace("-", "")
    if not re.match(r'^\d{8,14}$', cleaned):
        logger.warning(f"Invalid barcode format rejected: {barcode[:50]}...")
        raise HTTPException(
            status_code=400,
            detail="Invalid barcode. Product barcodes must be 8-14 digits."
        )

    logger.info(f"Looking up barcode: {cleaned}")

    try:
        service = get_food_database_service()
        product = await service.lookup_barcode(cleaned)
        
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
# USDA FoodData Central Endpoints
# ============================================

from services.usda_food_service import get_usda_food_service, USDAFood, USDASearchResult


class USDAFoodResponse(BaseModel):
    """USDA food item response."""
    fdc_id: int
    description: str
    data_type: str
    brand_owner: Optional[str] = None
    brand_name: Optional[str] = None
    ingredients: Optional[str] = None
    food_category: Optional[str] = None
    gtin_upc: Optional[str] = None
    nutrients: dict
    nutrients_per_serving: Optional[dict] = None
    score: Optional[float] = None


class USDASearchResponse(BaseModel):
    """USDA food search response."""
    foods: List[USDAFoodResponse]
    total_hits: int
    current_page: int
    total_pages: int
    query: str


class CombinedFoodSearchResponse(BaseModel):
    """Combined food search from multiple sources."""
    usda_foods: List[USDAFoodResponse]
    usda_total_hits: int
    source: str = "combined"
    query: str


@router.get("/food-search", response_model=USDASearchResponse)
async def search_usda_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    page_size: int = Query(default=25, ge=1, le=50, description="Number of results per page"),
    page: int = Query(default=1, ge=1, description="Page number"),
    data_types: Optional[str] = Query(
        default=None,
        description="Comma-separated food types: Branded,Foundation,SR Legacy"
    ),
    brand_owner: Optional[str] = Query(
        default=None,
        max_length=200,
        description="Filter by brand owner (for branded foods)"
    ),
):
    """
    Search USDA FoodData Central for foods.

    This endpoint searches the comprehensive USDA food database which includes:
    - **Branded Foods**: Packaged/processed foods from manufacturers
    - **Foundation Foods**: Minimally processed foods with detailed nutrients
    - **SR Legacy**: USDA Standard Reference database (basic foods)

    Returns complete nutrient data including calories, macros, vitamins, and minerals.

    **Rate Limits**: USDA API has rate limits. Results are cached for 1 hour.
    """
    logger.info(f"Searching USDA foods for: {query} (page {page}, size {page_size})")

    try:
        service = get_usda_food_service()

        # Parse data types if provided
        parsed_data_types = None
        if data_types:
            parsed_data_types = [dt.strip() for dt in data_types.split(",") if dt.strip()]

        result = await service.search_foods(
            query=query,
            page_size=page_size,
            page_number=page,
            data_types=parsed_data_types,
            brand_owner=brand_owner,
        )

        # Convert to response format
        foods = []
        for food in result.foods:
            food_dict = food.to_dict()
            foods.append(USDAFoodResponse(
                fdc_id=food_dict["fdc_id"],
                description=food_dict["description"],
                data_type=food_dict["data_type"],
                brand_owner=food_dict.get("brand_owner"),
                brand_name=food_dict.get("brand_name"),
                ingredients=food_dict.get("ingredients"),
                food_category=food_dict.get("food_category"),
                gtin_upc=food_dict.get("gtin_upc"),
                nutrients=food_dict["nutrients"],
                nutrients_per_serving=food_dict.get("nutrients_per_serving"),
                score=food_dict.get("score"),
            ))

        logger.info(f"Found {len(foods)} USDA foods for query: {query}")

        return USDASearchResponse(
            foods=foods,
            total_hits=result.total_hits,
            current_page=result.current_page,
            total_pages=result.total_pages,
            query=query,
        )

    except Exception as e:
        logger.error(f"Failed to search USDA foods: {e}")
        if "not configured" in str(e).lower():
            raise HTTPException(
                status_code=503,
                detail="USDA food search is not available. Please configure USDA_API_KEY."
            )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/food/{fdc_id}", response_model=USDAFoodResponse)
async def get_usda_food(fdc_id: int):
    """
    Get complete food details from USDA by FDC ID.

    Returns full nutrient profile including:
    - Macronutrients (calories, protein, carbs, fat, fiber, sugar)
    - Vitamins (A, C, D, B12, folate)
    - Minerals (sodium, potassium, calcium, iron, magnesium, zinc)
    - Serving size information
    """
    logger.info(f"Fetching USDA food by FDC ID: {fdc_id}")

    try:
        service = get_usda_food_service()
        food = await service.get_food(fdc_id)

        if not food:
            raise HTTPException(
                status_code=404,
                detail=f"Food not found for FDC ID: {fdc_id}"
            )

        food_dict = food.to_dict()
        return USDAFoodResponse(
            fdc_id=food_dict["fdc_id"],
            description=food_dict["description"],
            data_type=food_dict["data_type"],
            brand_owner=food_dict.get("brand_owner"),
            brand_name=food_dict.get("brand_name"),
            ingredients=food_dict.get("ingredients"),
            food_category=food_dict.get("food_category"),
            gtin_upc=food_dict.get("gtin_upc"),
            nutrients=food_dict["nutrients"],
            nutrients_per_serving=food_dict.get("nutrients_per_serving"),
            score=None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get USDA food {fdc_id}: {e}")
        if "not configured" in str(e).lower():
            raise HTTPException(
                status_code=503,
                detail="USDA food lookup is not available. Please configure USDA_API_KEY."
            )
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/food-search/branded", response_model=USDASearchResponse)
async def search_branded_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    page_size: int = Query(default=25, ge=1, le=50, description="Number of results per page"),
):
    """
    Search only branded/packaged foods from USDA database.

    Branded foods include products from manufacturers with UPC codes.
    Ideal for searching packaged foods, snacks, beverages, etc.
    """
    logger.info(f"Searching USDA branded foods for: {query}")

    try:
        service = get_usda_food_service()
        result = await service.search_branded_foods(query=query, page_size=page_size)

        foods = []
        for food in result.foods:
            food_dict = food.to_dict()
            foods.append(USDAFoodResponse(
                fdc_id=food_dict["fdc_id"],
                description=food_dict["description"],
                data_type=food_dict["data_type"],
                brand_owner=food_dict.get("brand_owner"),
                brand_name=food_dict.get("brand_name"),
                ingredients=food_dict.get("ingredients"),
                food_category=food_dict.get("food_category"),
                gtin_upc=food_dict.get("gtin_upc"),
                nutrients=food_dict["nutrients"],
                nutrients_per_serving=food_dict.get("nutrients_per_serving"),
                score=food_dict.get("score"),
            ))

        return USDASearchResponse(
            foods=foods,
            total_hits=result.total_hits,
            current_page=result.current_page,
            total_pages=result.total_pages,
            query=query,
        )

    except Exception as e:
        logger.error(f"Failed to search branded foods: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/food-search/whole-foods", response_model=USDASearchResponse)
async def search_whole_foods(
    query: str = Query(..., min_length=1, max_length=200, description="Food search query"),
    page_size: int = Query(default=25, ge=1, le=50, description="Number of results per page"),
):
    """
    Search foundation and SR Legacy foods from USDA database.

    These are whole/basic foods like fruits, vegetables, meats, grains.
    Foundation foods have the most detailed and accurate nutrient data.
    """
    logger.info(f"Searching USDA whole foods for: {query}")

    try:
        service = get_usda_food_service()
        result = await service.search_all_types(query=query, page_size=page_size)

        foods = []
        for food in result.foods:
            food_dict = food.to_dict()
            foods.append(USDAFoodResponse(
                fdc_id=food_dict["fdc_id"],
                description=food_dict["description"],
                data_type=food_dict["data_type"],
                brand_owner=food_dict.get("brand_owner"),
                brand_name=food_dict.get("brand_name"),
                ingredients=food_dict.get("ingredients"),
                food_category=food_dict.get("food_category"),
                gtin_upc=food_dict.get("gtin_upc"),
                nutrients=food_dict["nutrients"],
                nutrients_per_serving=food_dict.get("nutrients_per_serving"),
                score=food_dict.get("score"),
            ))

        return USDASearchResponse(
            foods=foods,
            total_hits=result.total_hits,
            current_page=result.current_page,
            total_pages=result.total_pages,
            query=query,
        )

    except Exception as e:
        logger.error(f"Failed to search whole foods: {e}")
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
    1. Uploads image to S3 and analyzes with Gemini Vision IN PARALLEL (no delay)
    2. Extracts food items with weight/count fields for portion editing
    3. Creates a food log entry with image URL
    """
    logger.info(f"Logging food from image for user {user_id}, meal_type={meal_type}")

    try:
        # Read and encode image
        image_bytes = await image.read()
        image_base64 = base64.b64encode(image_bytes).decode('utf-8')

        # Determine mime type
        content_type = image.content_type or 'image/jpeg'

        # Run Gemini analysis and S3 upload IN PARALLEL (no added delay for user)
        logger.info(f"Analyzing image + uploading to S3: size={len(image_bytes)} bytes, mime_type={content_type}")
        gemini_service = GeminiService()

        # Both tasks run concurrently - total time = max(gemini_time, s3_time)
        food_analysis, (image_url, storage_key) = await asyncio.gather(
            gemini_service.analyze_food_image(
                image_base64=image_base64,
                mime_type=content_type,
            ),
            upload_food_image_to_s3(
                file_bytes=image_bytes,
                user_id=user_id,
                content_type=content_type,
                source="camera",
                meal_type=meal_type,
            ),
        )
        logger.info(f"Gemini analysis result: {food_analysis}")
        logger.info(f"S3 upload complete: {image_url}")

        if not food_analysis or not food_analysis.get('food_items'):
            logger.warning(f"No food items identified in image. Analysis result: {food_analysis}")
            raise HTTPException(
                status_code=400,
                detail="Could not identify any food items in the image"
            )

        # Extract data from analysis (includes weight_g, unit, count, weight_per_unit_g)
        food_items = food_analysis.get('food_items', [])
        total_calories = food_analysis.get('total_calories', 0)
        protein_g = food_analysis.get('protein_g', 0.0)
        carbs_g = food_analysis.get('carbs_g', 0.0)
        fat_g = food_analysis.get('fat_g', 0.0)
        fiber_g = food_analysis.get('fiber_g', 0.0)

        # Create food log with image URL
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
            image_url=image_url,
            image_storage_key=storage_key,
            source_type="image",
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food from image as {food_log_id}")

        # Log successful image food logging
        await log_user_activity(
            user_id=user_id,
            action="food_log_image",
            endpoint="/api/v1/nutrition/log-image",
            message=f"Logged {len(food_items)} food items from image ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
            },
            status_code=200
        )

        # Calculate confidence based on image analysis factors
        # Higher confidence for clearer images with identifiable foods
        confidence_score = 0.7  # Base confidence for image analysis
        if len(food_items) == 1:
            confidence_score = 0.8  # Single item is more accurate
        elif len(food_items) > 5:
            confidence_score = 0.6  # Complex meals have lower confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=food_items,
            total_calories=total_calories,
            protein_g=protein_g,
            carbs_g=carbs_g,
            fat_g=fat_g,
            fiber_g=fiber_g,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="image",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from image: {e}")
        # Log error
        await log_user_error(
            user_id=user_id,
            action="food_log_image",
            error=e,
            endpoint="/api/v1/nutrition/log-image",
            metadata={"meal_type": meal_type},
            status_code=500
        )
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

        # Log successful text food logging
        await log_user_activity(
            user_id=request.user_id,
            action="food_log_text",
            endpoint="/api/v1/nutrition/log-text",
            message=f"Logged {len(food_items)} food items from text ({total_calories} cal)",
            metadata={
                "food_log_id": food_log_id,
                "meal_type": request.meal_type,
                "total_calories": total_calories,
                "food_items_count": len(food_items),
                "health_score": health_score,
            },
            status_code=200
        )

        # Text descriptions are generally more accurate than images
        confidence_score = 0.85  # Base confidence for text
        if len(request.description) < 20:
            confidence_score = 0.7  # Short descriptions have less context
        elif "about" in request.description.lower() or "roughly" in request.description.lower():
            confidence_score = 0.65  # Approximate language reduces confidence

        confidence_level = "high" if confidence_score >= 0.75 else "medium" if confidence_score >= 0.5 else "low"

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
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type="text",
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from text: {e}")
        # Log error
        await log_user_error(
            user_id=request.user_id,
            action="food_log_text",
            error=e,
            endpoint="/api/v1/nutrition/log-text",
            metadata={
                "meal_type": request.meal_type,
                "description": request.description[:100] if request.description else None,
            },
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


# ============================================
# Direct Food Logging (for restaurant mode, manual adjustments)
# ============================================


@router.post("/log-direct", response_model=LogFoodResponse)
async def log_food_direct(request: LogDirectRequest):
    """
    Log pre-analyzed food directly without AI processing.

    Used for:
    - Restaurant mode with portion adjustments
    - Manual food entry
    - Adjusted servings from previous logs

    The caller provides the nutrition data directly, which is logged as-is.
    """
    logger.info(f"Logging food directly for user {request.user_id}, source: {request.source_type}")

    # Debug: Log incoming values
    logger.info(
        f"[LOG-DIRECT] RECEIVED VALUES | "
        f"user={request.user_id} | "
        f"calories={request.total_calories} | "
        f"protein={request.total_protein} | "
        f"carbs={request.total_carbs} | "
        f"fat={request.total_fat} | "
        f"food_items_count={len(request.food_items)}"
    )
    if request.food_items:
        for idx, item in enumerate(request.food_items[:3]):  # Log first 3 items
            logger.info(f"[LOG-DIRECT] ITEM[{idx}] | name={item.get('name')} | calories={item.get('calories')}")

    try:
        db = get_supabase_db()

        # Build micronutrients dict from request
        micronutrients = {}
        micronutrient_fields = [
            'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
            'vitamin_a_ug', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg', 'vitamin_k_ug',
            'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg', 'vitamin_b6_mg',
            'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
            'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
            'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
        ]
        for field in micronutrient_fields:
            value = getattr(request, field, None)
            if value is not None:
                micronutrients[field] = value

        # Create food log directly
        created_log = db.create_food_log(
            user_id=request.user_id,
            meal_type=request.meal_type,
            food_items=request.food_items,
            total_calories=request.total_calories,
            protein_g=request.total_protein,
            carbs_g=request.total_carbs,
            fat_g=request.total_fat,
            fiber_g=request.total_fiber,
            ai_feedback=f"Logged via {request.source_type}" + (f": {request.notes}" if request.notes else ""),
            health_score=None,  # No AI scoring for direct logs
            **micronutrients,
        )

        food_log_id = created_log.get('id') if created_log else "unknown"
        logger.info(f"Successfully logged food directly as {food_log_id}")

        # Restaurant mode has lower confidence due to portion estimation
        confidence_score = 0.6 if request.source_type == "restaurant" else 0.9
        confidence_level = "medium" if request.source_type == "restaurant" else "high"

        return LogFoodResponse(
            success=True,
            food_log_id=food_log_id,
            food_items=request.food_items,
            total_calories=request.total_calories,
            protein_g=float(request.total_protein),
            carbs_g=float(request.total_carbs),
            fat_g=float(request.total_fat),
            fiber_g=float(request.total_fiber) if request.total_fiber else 0.0,
            overall_meal_score=None,
            ai_suggestion=None,
            confidence_score=confidence_score,
            confidence_level=confidence_level,
            source_type=request.source_type,
        )
    except Exception as e:
        logger.error(f"Error logging food directly: {e}")
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

            # Extract micronutrients from analysis
            micronutrients = {}
            micronutrient_keys = [
                'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
                'vitamin_a_ug', 'vitamin_a_iu', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
                'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg',
                'vitamin_b6_mg', 'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
                'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
                'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
            ]
            for key in micronutrient_keys:
                value = food_analysis.get(key)
                if value is not None:
                    # Convert vitamin_a_iu to vitamin_a_ug (1 IU = 0.3 ug retinol)
                    if key == 'vitamin_a_iu':
                        micronutrients['vitamin_a_ug'] = float(value) * 0.3
                    else:
                        micronutrients[key] = float(value) if value else None

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
                **micronutrients,
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


@router.post("/analyze-text-stream")
@limiter.limit("10/minute")
async def analyze_food_from_text_streaming(request: Request, body: LogTextRequest):
    """
    Analyze food from text description with streaming progress updates via SSE.

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Provides real-time feedback during food analysis:
    - Step 1: Loading user profile and goals
    - Step 2: Analyzing food with AI
    - Step 3: Calculating nutrition (analysis complete)

    Returns SSE events with progress updates and final analysis (no save).
    """
    logger.info(f"[ANALYZE-STREAM] Analyzing food from text for user {body.user_id}: {body.description[:50]}...")

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
            yield send_progress(1, 6, "Loading your profile...", "Fetching nutrition goals")

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
                logger.warning(f"[ANALYZE-STREAM] Could not fetch user goals: {e}")

            # Step 2: Get RAG context and analyze with AI
            # Check if this is a complex/regional food that may take longer
            description_lower = body.description.lower()
            regional_keywords = ['biryani', 'curry', 'masala', 'tikka', 'tandoori', 'paneer', 'dosa', 'idli',
                               'sambar', 'rasam', 'korma', 'vindaloo', 'rogan josh', 'dal', 'chapati', 'naan',
                               'paratha', 'puri', 'samosa', 'pakora', 'chutney', 'raita', 'lassi', 'kulfi',
                               'halwa', 'ladoo', 'gulab jamun', 'jalebi', 'kheer', 'payasam', 'upma', 'poha',
                               'pav bhaji', 'vada pav', 'chole', 'rajma', 'aloo', 'gobi', 'bhindi', 'palak',
                               'pho', 'banh mi', 'pad thai', 'tom yum', 'rendang', 'satay', 'laksa', 'nasi',
                               'kimchi', 'bibimbap', 'bulgogi', 'japchae', 'ramen', 'udon', 'sushi', 'tempura',
                               'dim sum', 'congee', 'char siu', 'kung pao', 'mapo tofu', 'szechuan',
                               'tacos', 'burrito', 'enchilada', 'tamale', 'mole', 'pozole', 'ceviche',
                               'falafel', 'shawarma', 'hummus', 'baba ganoush', 'tabouleh', 'fattoush',
                               'injera', 'doro wat', 'tagine', 'couscous', 'jollof', 'fufu', 'egusi',
                               'pierogi', 'borscht', 'goulash', 'schnitzel', 'paella', 'tapas', 'risotto',
                               'gnocchi', 'carbonara', 'bolognese', 'osso buco', 'tiramisu', 'panna cotta']
            is_complex = any(keyword in description_lower for keyword in regional_keywords)

            # Step 2: Prepare AI analysis
            yield send_progress(2, 6, "Preparing AI analysis...", "Building context")

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
                    logger.warning(f"[ANALYZE-STREAM] Could not fetch RAG context: {e}")

            # Step 3: Identify ingredients
            desc_preview = body.description[:30] + "..." if len(body.description) > 30 else body.description
            if is_complex:
                yield send_progress(3, 6, "Analyzing regional cuisine...", f"🌍 {desc_preview}")
            else:
                yield send_progress(3, 6, "Identifying ingredients...", f"Analyzing: {desc_preview}")

            # Step 4: AI portion estimation
            yield send_progress(4, 6, "Calculating portions...", "AI is estimating serving sizes")

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

            # Step 5: Fetch nutrition data
            yield send_progress(5, 6, "Fetching nutrition data...", f"Found {len(food_analysis.get('food_items', []))} items")

            # Step 6: Finalize results
            yield send_progress(6, 6, "Finalizing results...", "Almost ready!")

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

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            logger.info(f"[ANALYZE-STREAM] Analysis complete for user {body.user_id}: {total_calories} calories")

            # Send the analysis result (NO database save - user must confirm first)
            response_data = {
                "success": True,
                "is_analysis_only": True,  # Flag to indicate this is not yet saved
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
                "source_type": "text",
                "total_time_ms": elapsed_ms(),
                # Micronutrients
                "sodium_mg": sodium_mg,
                "sugar_g": sugar_g,
                "saturated_fat_g": saturated_fat_g,
                "cholesterol_mg": cholesterol_mg,
                "potassium_mg": potassium_mg,
                "vitamin_a_iu": vitamin_a_iu,
                "vitamin_c_mg": vitamin_c_mg,
                "vitamin_d_iu": vitamin_d_iu,
                "calcium_mg": calcium_mg,
                "iron_mg": iron_mg,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.error(f"[ANALYZE-STREAM] Food analysis error: {e}")
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

            # Step 2: Analyze with AI + Upload to S3 (in parallel)
            yield send_progress(2, 4, "Analyzing your food...", "AI is identifying ingredients")

            gemini_service = GeminiService()

            # Run Gemini analysis and S3 upload concurrently (no added delay)
            food_analysis, (image_url, storage_key) = await asyncio.gather(
                gemini_service.analyze_food_image(
                    image_base64=image_base64,
                    mime_type=content_type,
                ),
                upload_food_image_to_s3(
                    file_bytes=image_bytes,
                    user_id=user_id,
                    content_type=content_type,
                ),
            )
            logger.info(f"[STREAM] S3 upload complete: {image_url}")

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

            # Extract micronutrients from analysis
            micronutrients = {}
            micronutrient_keys = [
                'sodium_mg', 'sugar_g', 'saturated_fat_g', 'cholesterol_mg', 'potassium_mg',
                'vitamin_a_ug', 'vitamin_a_iu', 'vitamin_c_mg', 'vitamin_d_iu', 'vitamin_e_mg',
                'vitamin_k_ug', 'vitamin_b1_mg', 'vitamin_b2_mg', 'vitamin_b3_mg', 'vitamin_b5_mg',
                'vitamin_b6_mg', 'vitamin_b7_ug', 'vitamin_b9_ug', 'vitamin_b12_ug',
                'calcium_mg', 'iron_mg', 'magnesium_mg', 'zinc_mg', 'phosphorus_mg',
                'copper_mg', 'manganese_mg', 'selenium_ug', 'choline_mg', 'omega3_g', 'omega6_g',
            ]
            for key in micronutrient_keys:
                value = food_analysis.get(key)
                if value is not None:
                    # Convert vitamin_a_iu to vitamin_a_ug (1 IU = 0.3 ug retinol)
                    if key == 'vitamin_a_iu':
                        micronutrients['vitamin_a_ug'] = float(value) * 0.3
                    else:
                        micronutrients[key] = float(value) if value else None

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
                image_url=image_url,
                image_storage_key=storage_key,
                source_type="image",
                **micronutrients,
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


@router.post("/analyze-image-stream")
@limiter.limit("10/minute")
async def analyze_food_from_image_streaming(
    request: Request,
    user_id: str = Form(...),
    meal_type: str = Form(...),
    image: UploadFile = File(...),
):
    """
    Analyze food from an image with streaming progress updates via SSE.

    DOES NOT save to database - returns analysis only for user review.
    Use /log-direct to save after user confirmation.

    Provides real-time feedback during food image analysis:
    - Step 1: Processing image
    - Step 2: AI analyzing food
    - Step 3: Calculating nutrition (analysis complete)

    Returns SSE events with progress updates and final analysis (no save).
    """
    import uuid
    request_id = f"req_{uuid.uuid4().hex[:12]}"

    # Read image upfront (before generator)
    image_bytes = await image.read()
    content_type = image.content_type or 'image/jpeg'
    image_size_kb = len(image_bytes) // 1024

    logger.info(
        f"[ANALYZE-STREAM:{request_id}] START | "
        f"user={user_id} | "
        f"meal_type={meal_type} | "
        f"content_type={content_type} | "
        f"image_size_kb={image_size_kb}"
    )

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
                "request_id": request_id,
                "elapsed_ms": elapsed_ms()
            }
            return f"event: progress\ndata: {json.dumps(data)}\n\n"

        def send_error(error: str, error_code: str = "UNKNOWN_ERROR", error_details: str = None):
            data = {
                "type": "error",
                "error": error,
                "error_code": error_code,
                "error_details": error_details,
                "request_id": request_id,
                "user_id": user_id,
                "elapsed_ms": elapsed_ms()
            }
            logger.error(
                f"[ANALYZE-STREAM:{request_id}] FAILED | "
                f"user={user_id} | "
                f"error_code={error_code} | "
                f"error={error} | "
                f"details={error_details} | "
                f"elapsed_ms={elapsed_ms()}"
            )
            return f"event: error\ndata: {json.dumps(data)}\n\n"

        try:
            # Step 1: Process image
            yield send_progress(1, 3, "Processing image...", f"{image_size_kb} KB")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 1: Image processing started")

            image_base64 = base64.b64encode(image_bytes).decode('utf-8')

            # Step 2: Analyze with AI
            yield send_progress(2, 3, "Analyzing your food...", "AI is identifying ingredients")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 2: Sending to Gemini for analysis")

            gemini_service = GeminiService()
            food_analysis = await gemini_service.analyze_food_image(
                image_base64=image_base64,
                mime_type=content_type,
                request_id=request_id,
            )

            # Check if Gemini returned an error structure
            if food_analysis and food_analysis.get('error'):
                yield send_error(
                    food_analysis.get('error'),
                    food_analysis.get('error_code', 'GEMINI_ERROR'),
                    food_analysis.get('error_details')
                )
                return

            # Check for empty or missing food items
            if not food_analysis or not food_analysis.get('food_items'):
                yield send_error(
                    "Could not identify any food items in the image. Please try a clearer photo.",
                    "NO_FOOD_DETECTED",
                    "Gemini analysis returned empty food_items"
                )
                return

            # Step 3: Calculate nutrition (analysis complete - NO SAVE)
            food_items = food_analysis.get('food_items', [])
            yield send_progress(3, 3, "Calculating nutrition...", f"Found {len(food_items)} items")
            logger.info(f"[ANALYZE-STREAM:{request_id}] Step 3: Found {len(food_items)} food items")

            total_calories = food_analysis.get('total_calories', 0)
            protein_g = food_analysis.get('protein_g', 0.0)
            carbs_g = food_analysis.get('carbs_g', 0.0)
            fat_g = food_analysis.get('fat_g', 0.0)
            fiber_g = food_analysis.get('fiber_g', 0.0)

            # Micronutrients
            sodium_mg = food_analysis.get('sodium_mg')
            sugar_g = food_analysis.get('sugar_g')
            saturated_fat_g = food_analysis.get('saturated_fat_g')
            cholesterol_mg = food_analysis.get('cholesterol_mg')
            potassium_mg = food_analysis.get('potassium_mg')
            vitamin_a_iu = food_analysis.get('vitamin_a_iu')
            vitamin_c_mg = food_analysis.get('vitamin_c_mg')
            vitamin_d_iu = food_analysis.get('vitamin_d_iu')
            calcium_mg = food_analysis.get('calcium_mg')
            iron_mg = food_analysis.get('iron_mg')

            # Log success with full details
            logger.info(
                f"[ANALYZE-STREAM:{request_id}] SUCCESS | "
                f"user={user_id} | "
                f"meal_type={meal_type} | "
                f"items={len(food_items)} | "
                f"calories={total_calories} | "
                f"protein={protein_g}g | "
                f"carbs={carbs_g}g | "
                f"fat={fat_g}g | "
                f"elapsed_ms={elapsed_ms()}"
            )

            # Send the analysis result (NO database save - user must confirm first)
            response_data = {
                "success": True,
                "is_analysis_only": True,  # Flag to indicate this is not yet saved
                "request_id": request_id,
                "food_items": food_items,
                "total_calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "ai_suggestion": food_analysis.get('feedback'),
                "source_type": "image",
                "total_time_ms": elapsed_ms(),
                # Micronutrients
                "sodium_mg": sodium_mg,
                "sugar_g": sugar_g,
                "saturated_fat_g": saturated_fat_g,
                "cholesterol_mg": cholesterol_mg,
                "potassium_mg": potassium_mg,
                "vitamin_a_iu": vitamin_a_iu,
                "vitamin_c_mg": vitamin_c_mg,
                "vitamin_d_iu": vitamin_d_iu,
                "calcium_mg": calcium_mg,
                "iron_mg": iron_mg,
            }
            yield f"event: done\ndata: {json.dumps(response_data)}\n\n"

        except Exception as e:
            logger.exception(f"[ANALYZE-STREAM:{request_id}] EXCEPTION | user={user_id} | error={e}")
            yield send_error(
                "An unexpected error occurred. Please try again.",
                "UNEXPECTED_EXCEPTION",
                f"{type(e).__name__}: {str(e)}"
            )

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


# ==================== Nutrition Preferences ====================

class NutritionPreferencesResponse(BaseModel):
    """Nutrition preferences response model."""
    id: Optional[str] = None
    user_id: str
    nutrition_goals: List[str] = []  # Multi-select goals array
    nutrition_goal: str = "maintain"  # Legacy field (primary goal)
    rate_of_change: Optional[str] = None
    calculated_bmr: Optional[int] = None
    calculated_tdee: Optional[int] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None
    target_fiber_g: int = 25
    diet_type: str = "balanced"
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None
    allergies: List[str] = []
    dietary_restrictions: List[str] = []
    disliked_foods: List[str] = []
    meal_pattern: str = "3_meals"
    cooking_skill: str = "intermediate"
    cooking_time_minutes: int = 30
    budget_level: str = "moderate"
    show_ai_feedback_after_logging: bool = True
    calm_mode_enabled: bool = False
    show_weekly_instead_of_daily: bool = False
    adjust_calories_for_training: bool = True
    adjust_calories_for_rest: bool = False
    nutrition_onboarding_completed: bool = False
    onboarding_completed_at: Optional[datetime] = None
    last_recalculated_at: Optional[datetime] = None
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


class NutritionPreferencesUpdate(BaseModel):
    """Nutrition preferences update request."""
    nutrition_goals: Optional[List[str]] = None  # Multi-select goals array
    nutrition_goal: Optional[str] = None  # Legacy field
    rate_of_change: Optional[str] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None
    target_fiber_g: Optional[int] = None
    diet_type: Optional[str] = None
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None
    allergies: Optional[List[str]] = None
    dietary_restrictions: Optional[List[str]] = None
    disliked_foods: Optional[List[str]] = None
    meal_pattern: Optional[str] = None
    cooking_skill: Optional[str] = None
    cooking_time_minutes: Optional[int] = None
    budget_level: Optional[str] = None
    show_ai_feedback_after_logging: Optional[bool] = None
    calm_mode_enabled: Optional[bool] = None
    show_weekly_instead_of_daily: Optional[bool] = None
    adjust_calories_for_training: Optional[bool] = None
    adjust_calories_for_rest: Optional[bool] = None


class DynamicTargetsResponse(BaseModel):
    """Dynamic nutrition targets response model."""
    target_calories: int = 2000
    target_protein_g: int = 150
    target_carbs_g: int = 200
    target_fat_g: int = 65
    target_fiber_g: int = 25
    is_training_day: bool = False
    is_fasting_day: bool = False
    is_rest_day: bool = True
    adjustment_reason: Optional[str] = None
    calorie_adjustment: int = 0


@router.get("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def get_nutrition_preferences(user_id: str):
    """
    Get user's nutrition preferences.

    Returns nutrition goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Getting nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result or not result.data:
            # Return default preferences
            return NutritionPreferencesResponse(user_id=user_id)

        data = result.data
        # Get nutrition_goals, fallback to single goal in array if not present
        nutrition_goals = data.get("nutrition_goals") or []
        if not nutrition_goals and data.get("nutrition_goal"):
            nutrition_goals = [data.get("nutrition_goal")]

        return NutritionPreferencesResponse(
            id=data.get("id"),
            user_id=data.get("user_id", user_id),
            nutrition_goals=nutrition_goals,
            nutrition_goal=data.get("nutrition_goal", "maintain"),
            rate_of_change=data.get("rate_of_change"),
            calculated_bmr=data.get("calculated_bmr"),
            calculated_tdee=data.get("calculated_tdee"),
            target_calories=data.get("target_calories"),
            target_protein_g=data.get("target_protein_g"),
            target_carbs_g=data.get("target_carbs_g"),
            target_fat_g=data.get("target_fat_g"),
            target_fiber_g=data.get("target_fiber_g", 25),
            diet_type=data.get("diet_type", "balanced"),
            custom_carb_percent=data.get("custom_carb_percent"),
            custom_protein_percent=data.get("custom_protein_percent"),
            custom_fat_percent=data.get("custom_fat_percent"),
            allergies=data.get("allergies") or [],
            dietary_restrictions=data.get("dietary_restrictions") or [],
            disliked_foods=data.get("disliked_foods") or [],
            meal_pattern=data.get("meal_pattern", "3_meals"),
            cooking_skill=data.get("cooking_skill", "intermediate"),
            cooking_time_minutes=data.get("cooking_time_minutes", 30),
            budget_level=data.get("budget_level", "moderate"),
            show_ai_feedback_after_logging=data.get("show_ai_feedback_after_logging", True),
            calm_mode_enabled=data.get("calm_mode_enabled", False),
            show_weekly_instead_of_daily=data.get("show_weekly_instead_of_daily", False),
            adjust_calories_for_training=data.get("adjust_calories_for_training", True),
            adjust_calories_for_rest=data.get("adjust_calories_for_rest", False),
            nutrition_onboarding_completed=data.get("nutrition_onboarding_completed", False),
            onboarding_completed_at=datetime.fromisoformat(str(data.get("onboarding_completed_at")).replace("Z", "+00:00")) if data.get("onboarding_completed_at") else None,
            last_recalculated_at=datetime.fromisoformat(str(data.get("last_recalculated_at")).replace("Z", "+00:00")) if data.get("last_recalculated_at") else None,
            created_at=datetime.fromisoformat(str(data.get("created_at")).replace("Z", "+00:00")) if data.get("created_at") else None,
            updated_at=datetime.fromisoformat(str(data.get("updated_at")).replace("Z", "+00:00")) if data.get("updated_at") else None,
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/preferences/{user_id}", response_model=NutritionPreferencesResponse)
async def update_nutrition_preferences(user_id: str, request: NutritionPreferencesUpdate):
    """
    Update user's nutrition preferences.

    Allows updating goals, targets, dietary restrictions, and settings.
    """
    logger.info(f"Updating nutrition preferences for user {user_id}")

    try:
        db = get_supabase_db()

        # Build update data, only including non-None fields
        update_data = {}
        for field, value in request.model_dump().items():
            if value is not None:
                update_data[field] = value

        update_data["updated_at"] = datetime.utcnow().isoformat()

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            # Update existing
            result = db.client.table("nutrition_preferences")\
                .update(update_data)\
                .eq("user_id", user_id)\
                .execute()
        else:
            # Insert new
            update_data["user_id"] = user_id
            result = db.client.table("nutrition_preferences")\
                .insert(update_data)\
                .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to update preferences")

        # Return the updated preferences
        return await get_nutrition_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to update nutrition preferences: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/dynamic-targets/{user_id}", response_model=DynamicTargetsResponse)
async def get_dynamic_nutrition_targets(
    user_id: str,
    date: Optional[str] = Query(None, description="Date in YYYY-MM-DD format, defaults to today"),
):
    """
    Get dynamic nutrition targets for a specific date.

    Adjusts base targets based on:
    - Whether it's a training day (workout scheduled/completed)
    - Whether it's a fasting day (for 5:2, ADF protocols)
    - User's preferences for training/rest day adjustments
    """
    from datetime import date as date_type

    logger.info(f"Getting dynamic nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()

        # Parse target date
        if date:
            target_date = datetime.fromisoformat(date).date()
        else:
            target_date = date_type.today()

        target_date_str = target_date.isoformat()

        # Get user's base preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        prefs = (prefs_result.data if prefs_result else None) or {}

        base_calories = prefs.get("target_calories") or 2000
        base_protein = prefs.get("target_protein_g") or 150
        base_carbs = prefs.get("target_carbs_g") or 200
        base_fat = prefs.get("target_fat_g") or 65
        base_fiber = prefs.get("target_fiber_g") or 25
        adjust_for_training = prefs.get("adjust_calories_for_training", True)
        adjust_for_rest = prefs.get("adjust_calories_for_rest", False)

        # Check if there's a workout logged today
        workout_result = db.client.table("workout_logs")\
            .select("id")\
            .eq("user_id", user_id)\
            .gte("completed_at", f"{target_date_str}T00:00:00")\
            .lt("completed_at", f"{target_date_str}T23:59:59")\
            .execute()

        has_workout = bool(workout_result and workout_result.data)

        # Also check scheduled workouts if no log exists
        if not has_workout:
            schedule_result = db.client.table("workouts")\
                .select("id")\
                .eq("user_id", user_id)\
                .gte("scheduled_date", f"{target_date_str}T00:00:00")\
                .lt("scheduled_date", f"{target_date_str}T23:59:59")\
                .execute()
            has_workout = bool(schedule_result and schedule_result.data)

        # Check if it's a fasting day (for 5:2 or ADF protocols)
        is_fasting_day = False
        fasting_prefs = db.client.table("fasting_preferences")\
            .select("default_protocol, fasting_days")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if fasting_prefs and fasting_prefs.data:
            protocol = fasting_prefs.data.get("default_protocol", "")
            fasting_days = fasting_prefs.data.get("fasting_days") or []

            if protocol in ["5:2", "adf"]:
                day_name = target_date.strftime("%A").lower()
                is_fasting_day = day_name in [d.lower() for d in fasting_days]

        # Calculate adjustments
        calorie_adjustment = 0
        adjustment_reason = None

        if is_fasting_day:
            # Fasting day: significant calorie reduction
            calorie_adjustment = -int(base_calories * 0.75)  # 25% of normal
            adjustment_reason = "Fasting day - reduced calories"
        elif has_workout and adjust_for_training:
            # Training day: increase calories
            calorie_adjustment = 200
            adjustment_reason = "Training day - extra fuel for workout and recovery"
        elif not has_workout and adjust_for_rest:
            # Rest day: slight decrease
            calorie_adjustment = -100
            adjustment_reason = "Rest day - slightly reduced intake"

        target_calories = base_calories + calorie_adjustment

        # Adjust protein on training days
        target_protein = base_protein
        if has_workout and adjust_for_training:
            target_protein = int(base_protein * 1.1)  # 10% more protein

        # Adjust carbs on training days
        target_carbs = base_carbs
        if has_workout and adjust_for_training:
            target_carbs = int(base_carbs * 1.15)  # 15% more carbs for glycogen

        return DynamicTargetsResponse(
            target_calories=target_calories,
            target_protein_g=target_protein,
            target_carbs_g=target_carbs,
            target_fat_g=base_fat,
            target_fiber_g=base_fiber,
            is_training_day=has_workout,
            is_fasting_day=is_fasting_day,
            is_rest_day=not has_workout and not is_fasting_day,
            adjustment_reason=adjustment_reason,
            calorie_adjustment=calorie_adjustment,
        )

    except Exception as e:
        logger.error(f"Failed to get dynamic nutrition targets: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# WEIGHT LOGGING ENDPOINTS
# ============================================================================


class WeightLogCreate(BaseModel):
    """Request model for creating a weight log"""
    user_id: str
    weight_kg: float
    logged_at: Optional[datetime] = None
    source: str = "manual"
    notes: Optional[str] = None


class WeightLogResponse(BaseModel):
    """Response model for weight log"""
    id: str
    user_id: str
    weight_kg: float
    logged_at: datetime
    source: str = "manual"
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


class WeightTrendResponse(BaseModel):
    """Response model for weight trend"""
    start_weight: Optional[float] = None
    end_weight: Optional[float] = None
    change_kg: Optional[float] = None
    weekly_rate_kg: Optional[float] = None
    direction: str = "maintaining"  # 'losing', 'maintaining', 'gaining'
    days_analyzed: int = 0
    confidence: float = 0.0


@router.post("/weight-logs", response_model=WeightLogResponse)
async def create_weight_log(request: WeightLogCreate):
    """
    Log a weight entry for a user.

    Used for tracking weight over time and enabling adaptive TDEE calculations.
    """
    logger.info(f"Creating weight log for user {request.user_id}: {request.weight_kg} kg")

    try:
        db = get_supabase_db()

        log_data = {
            "user_id": request.user_id,
            "weight_kg": request.weight_kg,
            "logged_at": (request.logged_at or datetime.utcnow()).isoformat(),
            "source": request.source,
        }
        if request.notes:
            log_data["notes"] = request.notes

        result = db.client.table("weight_logs")\
            .insert(log_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create weight log")

        data = result.data[0]
        return WeightLogResponse(
            id=data["id"],
            user_id=data["user_id"],
            weight_kg=float(data["weight_kg"]),
            logged_at=datetime.fromisoformat(str(data["logged_at"]).replace("Z", "+00:00")),
            source=data.get("source", "manual"),
            notes=data.get("notes"),
            created_at=datetime.fromisoformat(str(data["created_at"]).replace("Z", "+00:00")) if data.get("created_at") else None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to create weight log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/weight-logs/{user_id}", response_model=List[WeightLogResponse])
async def get_weight_logs(
    user_id: str,
    limit: int = Query(30, description="Maximum number of logs to return"),
    from_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD)"),
    to_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD)"),
):
    """
    Get weight logs for a user.

    Returns logs sorted by date descending (newest first).
    """
    logger.info(f"Getting weight logs for user {user_id}")

    try:
        db = get_supabase_db()

        query = db.client.table("weight_logs")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("logged_at", desc=True)\
            .limit(limit)

        if from_date:
            query = query.gte("logged_at", f"{from_date}T00:00:00")
        if to_date:
            query = query.lte("logged_at", f"{to_date}T23:59:59")

        result = query.execute()

        logs = []
        for data in (result.data or []):
            logs.append(WeightLogResponse(
                id=data["id"],
                user_id=data["user_id"],
                weight_kg=float(data["weight_kg"]),
                logged_at=datetime.fromisoformat(str(data["logged_at"]).replace("Z", "+00:00")),
                source=data.get("source", "manual"),
                notes=data.get("notes"),
                created_at=datetime.fromisoformat(str(data["created_at"]).replace("Z", "+00:00")) if data.get("created_at") else None,
            ))

        return logs

    except Exception as e:
        logger.error(f"Failed to get weight logs: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/weight-logs/{log_id}")
async def delete_weight_log(
    log_id: str,
    user_id: str = Query(..., description="User ID for verification"),
):
    """
    Delete a weight log entry.
    """
    logger.info(f"Deleting weight log {log_id} for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weight_logs")\
            .delete()\
            .eq("id", log_id)\
            .eq("user_id", user_id)\
            .execute()

        return {"success": True, "message": "Weight log deleted"}

    except Exception as e:
        logger.error(f"Failed to delete weight log: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/weight-logs/{user_id}/trend", response_model=WeightTrendResponse)
async def get_weight_trend(
    user_id: str,
    days: int = Query(14, description="Number of days to analyze"),
):
    """
    Calculate weight trend from recent weight logs.

    Uses exponential moving average for smoothing.
    """
    logger.info(f"Calculating weight trend for user {user_id} over {days} days")

    try:
        db = get_supabase_db()

        from_date = (datetime.utcnow() - timedelta(days=days)).isoformat()

        result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", from_date)\
            .order("logged_at", desc=False)\
            .execute()

        logs = result.data or []

        if len(logs) < 2:
            return WeightTrendResponse(
                direction="maintaining",
                days_analyzed=len(logs),
                confidence=0.0,
            )

        # Get start and end weights (simple moving average of first/last 3 entries)
        start_weights = [float(log["weight_kg"]) for log in logs[:min(3, len(logs))]]
        end_weights = [float(log["weight_kg"]) for log in logs[-min(3, len(logs)):]]

        start_weight = sum(start_weights) / len(start_weights)
        end_weight = sum(end_weights) / len(end_weights)
        change_kg = end_weight - start_weight

        # Calculate weekly rate
        days_between = (datetime.fromisoformat(str(logs[-1]["logged_at"]).replace("Z", "+00:00")) -
                       datetime.fromisoformat(str(logs[0]["logged_at"]).replace("Z", "+00:00"))).days
        if days_between > 0:
            weekly_rate = (change_kg / days_between) * 7
        else:
            weekly_rate = 0.0

        # Determine direction
        if change_kg < -0.2:
            direction = "losing"
        elif change_kg > 0.2:
            direction = "gaining"
        else:
            direction = "maintaining"

        # Confidence based on number of data points
        confidence = min(1.0, len(logs) / 10)

        return WeightTrendResponse(
            start_weight=round(start_weight, 2),
            end_weight=round(end_weight, 2),
            change_kg=round(change_kg, 2),
            weekly_rate_kg=round(weekly_rate, 2),
            direction=direction,
            days_analyzed=days_between or 1,
            confidence=round(confidence, 2),
        )

    except Exception as e:
        logger.error(f"Failed to calculate weight trend: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# NUTRITION ONBOARDING ENDPOINTS
# ============================================================================


class NutritionOnboardingRequest(BaseModel):
    """Request model for completing nutrition onboarding"""
    user_id: str
    nutrition_goals: List[str] = []  # Multi-select: ['lose_fat', 'improve_energy', ...]
    nutrition_goal: Optional[str] = None  # Legacy single goal (backward compatibility)
    rate_of_change: Optional[str] = None  # 'slow', 'moderate', 'aggressive'
    diet_type: str = "balanced"
    allergies: List[str] = []
    dietary_restrictions: List[str] = []
    meal_pattern: str = "3_meals"
    fasting_start_hour: Optional[int] = None
    fasting_end_hour: Optional[int] = None
    cooking_skill: str = "intermediate"
    cooking_time_minutes: int = 30
    budget_level: str = "moderate"
    custom_carb_percent: Optional[int] = None
    custom_protein_percent: Optional[int] = None
    custom_fat_percent: Optional[int] = None

    @validator('user_id')
    def user_id_must_not_be_empty(cls, v):
        if not v or not v.strip():
            raise ValueError('user_id cannot be empty')
        return v

    # Pre-calculated values from frontend (optional - if provided, use these instead of recalculating)
    # This ensures calorie displayed during onboarding matches what's saved
    calculated_bmr: Optional[int] = None
    calculated_tdee: Optional[int] = None
    target_calories: Optional[int] = None
    target_protein_g: Optional[int] = None
    target_carbs_g: Optional[int] = None
    target_fat_g: Optional[int] = None

    @property
    def primary_goal(self) -> str:
        """Get primary goal - first in goals list or legacy goal field"""
        if self.nutrition_goals:
            return self.nutrition_goals[0]
        return self.nutrition_goal or "maintain"

    @property
    def all_goals(self) -> List[str]:
        """Get all goals as list"""
        if self.nutrition_goals:
            return self.nutrition_goals
        if self.nutrition_goal:
            return [self.nutrition_goal]
        return ["maintain"]


@router.post("/onboarding/complete", response_model=NutritionPreferencesResponse)
async def complete_nutrition_onboarding(request: NutritionOnboardingRequest):
    """
    Complete nutrition onboarding and calculate initial targets.

    Calculates BMR, TDEE, and macro targets based on user profile and goals.
    """
    logger.info(f"Completing nutrition onboarding for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Get user profile for BMR/TDEE calculation
        user_result = db.client.table("users")\
            .select("weight_kg, height_cm, age, gender, activity_level")\
            .eq("id", request.user_id)\
            .single()\
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = user_result.data
        weight_kg = float(user.get("weight_kg") or 70)
        height_cm = float(user.get("height_cm") or 170)
        age = int(user.get("age") or 30)
        gender = user.get("gender", "male").lower()
        activity_level = user.get("activity_level", "moderately_active")

        # Calculate BMR using Mifflin-St Jeor equation
        if gender == "male":
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5)
        else:
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161)

        # Calculate TDEE
        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }
        multiplier = activity_multipliers.get(activity_level, 1.55)
        tdee = int(bmr * multiplier)

        # Calculate calorie target based on goal
        goal_adjustments = {
            "lose_fat": -500,
            "build_muscle": 300,
            "maintain": 0,
            "improve_energy": 0,
            "eat_healthier": 0,
            "recomposition": -200,
        }

        rate_adjustments = {
            "slow": 250,
            "moderate": 500,
            "aggressive": 750,
        }

        # Use primary_goal property for calculations (first goal in multi-select list)
        primary_goal = request.primary_goal
        adjustment = goal_adjustments.get(primary_goal, 0)
        if primary_goal == "lose_fat" and request.rate_of_change:
            adjustment = -rate_adjustments.get(request.rate_of_change, 500)
        elif primary_goal == "build_muscle" and request.rate_of_change:
            adjustment = rate_adjustments.get(request.rate_of_change, 500) // 2

        target_calories = max(
            1200 if gender == "female" else 1500,
            tdee + adjustment
        )

        # Calculate macros based on diet type
        # Format: (carb%, protein%, fat%)
        diet_macros = {
            # No restrictions
            "no_diet": (45, 25, 30),
            # Macro-focused diets
            "balanced": (45, 25, 30),
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
            "high_protein": (35, 40, 25),
            "mediterranean": (45, 20, 35),
            # Plant-based diets (strict to flexible)
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "pescatarian": (45, 25, 30),
            # Flexible/part-time diets
            "flexitarian": (45, 25, 30),
            "part_time_veg": (50, 20, 30),
        }

        if request.diet_type == "custom" and all([
            request.custom_carb_percent,
            request.custom_protein_percent,
            request.custom_fat_percent
        ]):
            carb_pct = request.custom_carb_percent
            protein_pct = request.custom_protein_percent
            fat_pct = request.custom_fat_percent
        else:
            carb_pct, protein_pct, fat_pct = diet_macros.get(request.diet_type, (45, 25, 30))

        target_protein = int((target_calories * protein_pct / 100) / 4)
        target_carbs = int((target_calories * carb_pct / 100) / 4)
        target_fat = int((target_calories * fat_pct / 100) / 9)

        # Use frontend-calculated values if provided (ensures consistency with what user saw)
        # Otherwise use the values we just calculated above
        final_bmr = request.calculated_bmr if request.calculated_bmr is not None else bmr
        final_tdee = request.calculated_tdee if request.calculated_tdee is not None else tdee
        final_calories = request.target_calories if request.target_calories is not None else target_calories
        final_protein = request.target_protein_g if request.target_protein_g is not None else target_protein
        final_carbs = request.target_carbs_g if request.target_carbs_g is not None else target_carbs
        final_fat = request.target_fat_g if request.target_fat_g is not None else target_fat

        if request.target_calories is not None:
            logger.info(f"Using frontend-calculated values: calories={final_calories}, protein={final_protein}g")
        else:
            logger.info(f"Using backend-calculated values: calories={final_calories}, protein={final_protein}g")

        # Create/update nutrition preferences
        prefs_data = {
            "user_id": request.user_id,
            "nutrition_goals": request.all_goals,  # Multi-select goals array
            "nutrition_goal": request.primary_goal,  # Legacy single goal (primary)
            "rate_of_change": request.rate_of_change,
            "calculated_bmr": final_bmr,
            "calculated_tdee": final_tdee,
            "target_calories": final_calories,
            "target_protein_g": final_protein,
            "target_carbs_g": final_carbs,
            "target_fat_g": final_fat,
            "diet_type": request.diet_type,
            "custom_carb_percent": request.custom_carb_percent,
            "custom_protein_percent": request.custom_protein_percent,
            "custom_fat_percent": request.custom_fat_percent,
            "allergies": request.allergies,
            "dietary_restrictions": request.dietary_restrictions,
            "meal_pattern": request.meal_pattern,
            "cooking_skill": request.cooking_skill,
            "cooking_time_minutes": request.cooking_time_minutes,
            "budget_level": request.budget_level,
            "nutrition_onboarding_completed": True,
            "onboarding_completed_at": datetime.utcnow().isoformat(),
            "last_recalculated_at": datetime.utcnow().isoformat(),
        }

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            result = db.client.table("nutrition_preferences")\
                .update(prefs_data)\
                .eq("user_id", request.user_id)\
                .execute()
        else:
            result = db.client.table("nutrition_preferences")\
                .insert(prefs_data)\
                .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to save preferences")

        # Initialize nutrition streak
        streak_exists = db.client.table("nutrition_streaks")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if not streak_exists.data:
            db.client.table("nutrition_streaks")\
                .insert({"user_id": request.user_id})\
                .execute()

        # Return the updated preferences
        return await get_nutrition_preferences(request.user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to complete nutrition onboarding: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class SkipOnboardingRequest(BaseModel):
    """Request to skip nutrition onboarding."""
    user_id: str


@router.post("/onboarding/skip")
async def skip_nutrition_onboarding(request: SkipOnboardingRequest):
    """
    Skip nutrition onboarding permanently.

    Sets nutrition_onboarding_completed to true with default targets (2000 cal).
    User can always customize later in settings.
    """
    logger.info(f"Skipping nutrition onboarding for user {request.user_id}")

    try:
        db = get_supabase_db()

        # Default targets for skipped users
        default_prefs = {
            "user_id": request.user_id,
            "nutrition_onboarding_completed": True,
            "onboarding_completed_at": datetime.utcnow().isoformat(),
            "target_calories": 2000,
            "target_protein_g": 150,
            "target_carbs_g": 200,
            "target_fat_g": 67,
            "target_fiber_g": 25,
            "diet_type": "balanced",
            "meal_pattern": "3_meals",
        }

        # Check if preferences exist
        existing = db.client.table("nutrition_preferences")\
            .select("id")\
            .eq("user_id", request.user_id)\
            .maybe_single()\
            .execute()

        if existing.data:
            # Update existing preferences
            db.client.table("nutrition_preferences")\
                .update({
                    "nutrition_onboarding_completed": True,
                    "onboarding_completed_at": datetime.utcnow().isoformat(),
                })\
                .eq("user_id", request.user_id)\
                .execute()
        else:
            # Create new preferences with defaults
            db.client.table("nutrition_preferences")\
                .insert(default_prefs)\
                .execute()

        return {"success": True, "message": "Nutrition onboarding skipped"}

    except Exception as e:
        logger.error(f"Failed to skip nutrition onboarding: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{user_id}/reset-onboarding")
async def reset_nutrition_onboarding(user_id: str):
    """
    Reset nutrition onboarding so user can redo it.

    Sets nutrition_onboarding_completed to false while preserving
    all food logs and nutrition history.
    """
    logger.info(f"Resetting nutrition onboarding for user {user_id}")

    try:
        db = get_supabase_db()

        # Update nutrition_onboarding_completed to false
        result = db.client.table("nutrition_preferences")\
            .update({"nutrition_onboarding_completed": False})\
            .eq("user_id", user_id)\
            .execute()

        if not result.data:
            # No preferences exist yet, that's fine
            logger.info(f"No nutrition preferences found for user {user_id}, nothing to reset")

        return {"success": True, "message": "Nutrition onboarding reset successfully"}

    except Exception as e:
        logger.error(f"Failed to reset nutrition onboarding: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/preferences/{user_id}/recalculate", response_model=NutritionPreferencesResponse)
async def recalculate_nutrition_targets(user_id: str):
    """
    Recalculate nutrition targets based on current user data.

    Useful after weight changes or profile updates.
    """
    logger.info(f"Recalculating nutrition targets for user {user_id}")

    try:
        db = get_supabase_db()

        # Get current preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not prefs_result.data:
            raise HTTPException(status_code=404, detail="Nutrition preferences not found")

        prefs = prefs_result.data

        # Get user profile
        user_result = db.client.table("users")\
            .select("weight_kg, height_cm, age, gender, activity_level")\
            .eq("id", user_id)\
            .single()\
            .execute()

        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")

        user = user_result.data
        weight_kg = float(user.get("weight_kg") or 70)
        height_cm = float(user.get("height_cm") or 170)
        age = int(user.get("age") or 30)
        gender = user.get("gender", "male").lower()
        activity_level = user.get("activity_level", "moderately_active")

        # Recalculate BMR and TDEE
        if gender == "male":
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) + 5)
        else:
            bmr = int((10 * weight_kg) + (6.25 * height_cm) - (5 * age) - 161)

        activity_multipliers = {
            "sedentary": 1.2,
            "lightly_active": 1.375,
            "moderately_active": 1.55,
            "very_active": 1.725,
            "extra_active": 1.9,
        }
        multiplier = activity_multipliers.get(activity_level, 1.55)
        tdee = int(bmr * multiplier)

        # Calculate calorie target
        goal_adjustments = {
            "lose_fat": -500,
            "build_muscle": 300,
            "maintain": 0,
            "improve_energy": 0,
            "eat_healthier": 0,
            "recomposition": -200,
        }

        rate_adjustments = {
            "slow": 250,
            "moderate": 500,
            "aggressive": 750,
        }

        nutrition_goal = prefs.get("nutrition_goal", "maintain")
        rate_of_change = prefs.get("rate_of_change")

        adjustment = goal_adjustments.get(nutrition_goal, 0)
        if nutrition_goal == "lose_fat" and rate_of_change:
            adjustment = -rate_adjustments.get(rate_of_change, 500)
        elif nutrition_goal == "build_muscle" and rate_of_change:
            adjustment = rate_adjustments.get(rate_of_change, 500) // 2

        target_calories = max(
            1200 if gender == "female" else 1500,
            tdee + adjustment
        )

        # Recalculate macros
        diet_type = prefs.get("diet_type", "balanced")
        # Format: (carb%, protein%, fat%)
        diet_macros = {
            # No restrictions
            "no_diet": (45, 25, 30),
            # Macro-focused diets
            "balanced": (45, 25, 30),
            "low_carb": (25, 35, 40),
            "keto": (5, 25, 70),
            "high_protein": (35, 40, 25),
            "mediterranean": (45, 20, 35),
            # Plant-based diets (strict to flexible)
            "vegan": (55, 20, 25),
            "vegetarian": (50, 20, 30),
            "lacto_ovo": (50, 22, 28),
            "pescatarian": (45, 25, 30),
            # Flexible/part-time diets
            "flexitarian": (45, 25, 30),
            "part_time_veg": (50, 20, 30),
        }

        if diet_type == "custom" and all([
            prefs.get("custom_carb_percent"),
            prefs.get("custom_protein_percent"),
            prefs.get("custom_fat_percent")
        ]):
            carb_pct = prefs["custom_carb_percent"]
            protein_pct = prefs["custom_protein_percent"]
            fat_pct = prefs["custom_fat_percent"]
        else:
            carb_pct, protein_pct, fat_pct = diet_macros.get(diet_type, (45, 25, 30))

        target_protein = int((target_calories * protein_pct / 100) / 4)
        target_carbs = int((target_calories * carb_pct / 100) / 4)
        target_fat = int((target_calories * fat_pct / 100) / 9)

        # Update preferences
        update_data = {
            "calculated_bmr": bmr,
            "calculated_tdee": tdee,
            "target_calories": target_calories,
            "target_protein_g": target_protein,
            "target_carbs_g": target_carbs,
            "target_fat_g": target_fat,
            "last_recalculated_at": datetime.utcnow().isoformat(),
        }

        db.client.table("nutrition_preferences")\
            .update(update_data)\
            .eq("user_id", user_id)\
            .execute()

        return await get_nutrition_preferences(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to recalculate nutrition targets: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# NUTRITION STREAKS ENDPOINTS
# ============================================================================


class NutritionStreakResponse(BaseModel):
    """Response model for nutrition streak"""
    id: Optional[str] = None
    user_id: str
    current_streak_days: int = 0
    streak_start_date: Optional[datetime] = None
    last_logged_date: Optional[datetime] = None
    freezes_available: int = 2
    freezes_used_this_week: int = 0
    week_start_date: Optional[datetime] = None
    longest_streak_ever: int = 0
    total_days_logged: int = 0
    weekly_goal_enabled: bool = False
    weekly_goal_days: int = 5
    days_logged_this_week: int = 0


@router.get("/streak/{user_id}", response_model=NutritionStreakResponse)
async def get_nutrition_streak(user_id: str):
    """
    Get nutrition streak for a user.
    """
    logger.info(f"Getting nutrition streak for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("nutrition_streaks")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result or not result.data:
            # Create default streak (if table exists) or return defaults
            try:
                insert_result = db.client.table("nutrition_streaks")\
                    .insert({"user_id": user_id})\
                    .execute()
                data = insert_result.data[0] if insert_result and insert_result.data else {"user_id": user_id}
            except Exception:
                # Table might not exist yet - return defaults
                data = {"user_id": user_id}
        else:
            data = result.data

        return NutritionStreakResponse(
            id=data.get("id"),
            user_id=data.get("user_id", user_id),
            current_streak_days=data.get("current_streak_days", 0),
            streak_start_date=datetime.fromisoformat(str(data["streak_start_date"]).replace("Z", "+00:00")) if data.get("streak_start_date") else None,
            last_logged_date=datetime.fromisoformat(str(data["last_logged_date"]).replace("Z", "+00:00")) if data.get("last_logged_date") else None,
            freezes_available=data.get("freezes_available", 2),
            freezes_used_this_week=data.get("freezes_used_this_week", 0),
            week_start_date=datetime.fromisoformat(str(data["week_start_date"]).replace("Z", "+00:00")) if data.get("week_start_date") else None,
            longest_streak_ever=data.get("longest_streak_ever", 0),
            total_days_logged=data.get("total_days_logged", 0),
            weekly_goal_enabled=data.get("weekly_goal_enabled", False),
            weekly_goal_days=data.get("weekly_goal_days", 5),
            days_logged_this_week=data.get("days_logged_this_week", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get nutrition streak: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/streak/{user_id}/freeze", response_model=NutritionStreakResponse)
async def use_streak_freeze(user_id: str):
    """
    Use a streak freeze to preserve current streak.
    """
    logger.info(f"Using streak freeze for user {user_id}")

    try:
        db = get_supabase_db()

        # Get current streak
        result = db.client.table("nutrition_streaks")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not result.data:
            raise HTTPException(status_code=404, detail="Streak not found")

        data = result.data
        freezes_available = data.get("freezes_available", 0)

        if freezes_available <= 0:
            raise HTTPException(status_code=400, detail="No freezes available")

        # Use a freeze
        db.client.table("nutrition_streaks")\
            .update({
                "freezes_available": freezes_available - 1,
                "freezes_used_this_week": data.get("freezes_used_this_week", 0) + 1,
                "last_logged_date": datetime.utcnow().date().isoformat(),
            })\
            .eq("user_id", user_id)\
            .execute()

        return await get_nutrition_streak(user_id)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to use streak freeze: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# ADAPTIVE TDEE CALCULATION ENDPOINTS
# ============================================================================


class AdaptiveCalculationResponse(BaseModel):
    """Response model for adaptive TDEE calculation"""
    id: str
    user_id: str
    calculated_at: datetime
    period_start: datetime
    period_end: datetime
    avg_daily_intake: int
    start_trend_weight_kg: Optional[float] = None
    end_trend_weight_kg: Optional[float] = None
    calculated_tdee: int
    data_quality_score: float = 0.0
    confidence_level: str = "low"
    days_logged: int = 0
    weight_entries: int = 0


@router.get("/adaptive/{user_id}", response_model=Optional[AdaptiveCalculationResponse])
async def get_adaptive_calculation(user_id: str):
    """
    Get the latest adaptive TDEE calculation for a user.
    """
    logger.info(f"Getting adaptive calculation for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("adaptive_nutrition_calculations")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        if not result.data:
            return None

        data = result.data
        return AdaptiveCalculationResponse(
            id=data["id"],
            user_id=data["user_id"],
            calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
            period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
            period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
            avg_daily_intake=data.get("avg_daily_intake", 0),
            start_trend_weight_kg=float(data["start_trend_weight_kg"]) if data.get("start_trend_weight_kg") else None,
            end_trend_weight_kg=float(data["end_trend_weight_kg"]) if data.get("end_trend_weight_kg") else None,
            calculated_tdee=data.get("calculated_tdee", 0),
            data_quality_score=float(data.get("data_quality_score", 0)),
            confidence_level=data.get("confidence_level", "low"),
            days_logged=data.get("days_logged", 0),
            weight_entries=data.get("weight_entries", 0),
        )

    except Exception as e:
        logger.error(f"Failed to get adaptive calculation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/adaptive/{user_id}/calculate", response_model=AdaptiveCalculationResponse)
async def calculate_adaptive_tdee(
    user_id: str,
    days: int = Query(14, description="Number of days to analyze"),
):
    """
    Calculate adaptive TDEE based on food intake and weight changes.

    Formula: TDEE = Calories In - (Weight Change * 7700 kcal/kg)

    Requires at least 6 days of food logs and 2 weight entries.
    """
    logger.info(f"Calculating adaptive TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()

        from_date = datetime.utcnow() - timedelta(days=days)
        from_date_str = from_date.date().isoformat()
        to_date_str = datetime.utcnow().date().isoformat()

        # Get food logs for the period
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_macros")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the period
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Check minimum data requirements
        days_logged = len(set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            for log in food_logs
        ))
        weight_entries = len(weight_logs)

        if days_logged < 6 or weight_entries < 2:
            # Not enough data, return placeholder calculation
            quality_score = min(days_logged / 6, weight_entries / 2) * 0.5

            calc_data = {
                "user_id": user_id,
                "calculated_at": datetime.utcnow().isoformat(),
                "period_start": from_date_str,
                "period_end": to_date_str,
                "avg_daily_intake": 0,
                "calculated_tdee": 0,
                "data_quality_score": quality_score,
                "confidence_level": "low",
                "days_logged": days_logged,
                "weight_entries": weight_entries,
            }

            result = db.client.table("adaptive_nutrition_calculations")\
                .insert(calc_data)\
                .execute()

            if not result.data:
                raise HTTPException(status_code=500, detail="Failed to create adaptive calculation")

            data = result.data[0]
            return AdaptiveCalculationResponse(
                id=data["id"],
                user_id=data["user_id"],
                calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
                period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
                period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
                avg_daily_intake=0,
                calculated_tdee=0,
                data_quality_score=quality_score,
                confidence_level="low",
                days_logged=days_logged,
                weight_entries=weight_entries,
            )

        # Calculate average daily calorie intake
        total_calories = 0
        for log in food_logs:
            macros = log.get("total_macros") or {}
            total_calories += macros.get("calories", 0)

        avg_daily_intake = int(total_calories / days_logged) if days_logged > 0 else 0

        # Calculate weight trend
        start_weights = [float(log["weight_kg"]) for log in weight_logs[:min(3, len(weight_logs))]]
        end_weights = [float(log["weight_kg"]) for log in weight_logs[-min(3, len(weight_logs)):]]

        start_trend = sum(start_weights) / len(start_weights) if start_weights else None
        end_trend = sum(end_weights) / len(end_weights) if end_weights else None

        if start_trend and end_trend:
            weight_change = end_trend - start_trend
            # 7700 kcal = 1 kg of body weight
            caloric_difference = int(weight_change * 7700 / days)
            calculated_tdee = avg_daily_intake - caloric_difference
        else:
            calculated_tdee = avg_daily_intake

        # Calculate quality score (0-1)
        quality_score = min(1.0, (
            (min(days_logged, 14) / 14) * 0.5 +
            (min(weight_entries, 7) / 7) * 0.5
        ))

        confidence = "low" if quality_score < 0.4 else "medium" if quality_score < 0.7 else "high"

        # Save calculation
        calc_data = {
            "user_id": user_id,
            "calculated_at": datetime.utcnow().isoformat(),
            "period_start": from_date_str,
            "period_end": to_date_str,
            "avg_daily_intake": avg_daily_intake,
            "start_trend_weight_kg": start_trend,
            "end_trend_weight_kg": end_trend,
            "calculated_tdee": max(1000, calculated_tdee),  # Minimum TDEE
            "data_quality_score": quality_score,
            "confidence_level": confidence,
            "days_logged": days_logged,
            "weight_entries": weight_entries,
        }

        result = db.client.table("adaptive_nutrition_calculations")\
            .insert(calc_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create adaptive calculation")

        data = result.data[0]
        return AdaptiveCalculationResponse(
            id=data["id"],
            user_id=data["user_id"],
            calculated_at=datetime.fromisoformat(str(data["calculated_at"]).replace("Z", "+00:00")),
            period_start=datetime.fromisoformat(str(data["period_start"]).replace("Z", "+00:00")),
            period_end=datetime.fromisoformat(str(data["period_end"]).replace("Z", "+00:00")),
            avg_daily_intake=avg_daily_intake,
            start_trend_weight_kg=start_trend,
            end_trend_weight_kg=end_trend,
            calculated_tdee=max(1000, calculated_tdee),
            data_quality_score=quality_score,
            confidence_level=confidence,
            days_logged=days_logged,
            weight_entries=weight_entries,
        )

    except Exception as e:
        logger.error(f"Failed to calculate adaptive TDEE: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# WEEKLY RECOMMENDATIONS ENDPOINTS
# ============================================================================


class WeeklyRecommendationResponse(BaseModel):
    """Response model for weekly nutrition recommendation"""
    id: str
    user_id: str
    week_start: datetime
    current_goal: str
    target_rate_per_week: float
    calculated_tdee: int
    recommended_calories: int
    recommended_protein_g: int
    recommended_carbs_g: int
    recommended_fat_g: int
    adjustment_reason: Optional[str] = None
    adjustment_amount: int = 0
    user_accepted: bool = False
    user_modified: bool = False
    modified_calories: Optional[int] = None


@router.post("/recommendations/{recommendation_id}/respond")
async def respond_to_recommendation(
    recommendation_id: str,
    user_id: str,
    accepted: bool,
):
    """
    Respond to a weekly nutrition recommendation (accept or decline).

    If accepted, updates the user's nutrition preferences with recommended values.
    """
    logger.info(f"User {user_id} responding to recommendation {recommendation_id}: accepted={accepted}")

    try:
        db = get_supabase_db()

        # Get the recommendation
        rec_result = db.client.table("weekly_nutrition_recommendations")\
            .select("*")\
            .eq("id", recommendation_id)\
            .eq("user_id", user_id)\
            .single()\
            .execute()

        if not rec_result.data:
            raise HTTPException(status_code=404, detail="Recommendation not found")

        rec = rec_result.data

        # Update recommendation status
        db.client.table("weekly_nutrition_recommendations")\
            .update({"user_accepted": accepted})\
            .eq("id", recommendation_id)\
            .execute()

        # If accepted, update preferences
        if accepted:
            db.client.table("nutrition_preferences")\
                .update({
                    "target_calories": rec["recommended_calories"],
                    "target_protein_g": rec["recommended_protein_g"],
                    "target_carbs_g": rec["recommended_carbs_g"],
                    "target_fat_g": rec["recommended_fat_g"],
                    "calculated_tdee": rec["calculated_tdee"],
                    "last_recalculated_at": datetime.utcnow().isoformat(),
                })\
                .eq("user_id", user_id)\
                .execute()

        return {"success": True, "accepted": accepted}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to respond to recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recommendations/{user_id}", response_model=Optional[WeeklyRecommendationResponse])
async def get_weekly_recommendation(user_id: str):
    """
    Get the latest pending weekly nutrition recommendation for a user.
    """
    logger.info(f"Getting weekly recommendation for user {user_id}")

    try:
        db = get_supabase_db()

        result = db.client.table("weekly_nutrition_recommendations")\
            .select("*")\
            .eq("user_id", user_id)\
            .eq("user_accepted", False)\
            .order("created_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        if not result.data:
            return None

        data = result.data
        return WeeklyRecommendationResponse(
            id=data["id"],
            user_id=data["user_id"],
            week_start=datetime.fromisoformat(str(data["week_start"]).replace("Z", "+00:00")),
            current_goal=data.get("current_goal", "maintain"),
            target_rate_per_week=float(data.get("target_rate_per_week", 0)),
            calculated_tdee=data.get("calculated_tdee", 0),
            recommended_calories=data.get("recommended_calories", 0),
            recommended_protein_g=data.get("recommended_protein_g", 0),
            recommended_carbs_g=data.get("recommended_carbs_g", 0),
            recommended_fat_g=data.get("recommended_fat_g", 0),
            adjustment_reason=data.get("adjustment_reason"),
            adjustment_amount=data.get("adjustment_amount", 0),
            user_accepted=data.get("user_accepted", False),
            user_modified=data.get("user_modified", False),
            modified_calories=data.get("modified_calories"),
        )

    except Exception as e:
        logger.error(f"Failed to get weekly recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class WeeklySummaryResponse(BaseModel):
    """Response model for weekly nutrition summary"""
    days_logged: int
    avg_calories: int
    avg_protein: int
    weight_change: Optional[float] = None
    total_meals: int = 0
    start_weight_kg: Optional[float] = None
    end_weight_kg: Optional[float] = None


@router.get("/weekly-summary/{user_id}", response_model=WeeklySummaryResponse)
async def get_weekly_summary(user_id: str):
    """
    Get the weekly nutrition summary for a user (last 7 days).
    """
    logger.info(f"Getting weekly summary for user {user_id}")

    try:
        db = get_supabase_db()

        from_date = datetime.utcnow() - timedelta(days=7)
        from_date_str = from_date.date().isoformat()

        # Get food logs for the past week
        food_result = db.client.table("food_logs")\
            .select("logged_at, total_macros")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .execute()

        food_logs = food_result.data or []

        # Get weight logs for the past week
        weight_result = db.client.table("weight_logs")\
            .select("weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", f"{from_date_str}T00:00:00")\
            .order("logged_at", desc=False)\
            .execute()

        weight_logs = weight_result.data or []

        # Calculate days logged
        logged_dates = set(
            datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            for log in food_logs
        )
        days_logged = len(logged_dates)

        # Calculate average calories and protein
        total_calories = 0
        total_protein = 0
        for log in food_logs:
            macros = log.get("total_macros") or {}
            total_calories += macros.get("calories", 0)
            total_protein += macros.get("protein", 0)

        avg_calories = int(total_calories / days_logged) if days_logged > 0 else 0
        avg_protein = int(total_protein / days_logged) if days_logged > 0 else 0

        # Calculate weight change
        weight_change = None
        start_weight = None
        end_weight = None
        if len(weight_logs) >= 2:
            start_weight = float(weight_logs[0]["weight_kg"])
            end_weight = float(weight_logs[-1]["weight_kg"])
            weight_change = round(end_weight - start_weight, 2)

        return WeeklySummaryResponse(
            days_logged=days_logged,
            avg_calories=avg_calories,
            avg_protein=avg_protein,
            weight_change=weight_change,
            total_meals=len(food_logs),
            start_weight_kg=start_weight,
            end_weight_kg=end_weight,
        )

    except Exception as e:
        logger.error(f"Failed to get weekly summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/recommendations/{user_id}/generate", response_model=WeeklyRecommendationResponse)
async def generate_weekly_recommendation(user_id: str):
    """
    Generate a new weekly nutrition recommendation based on adaptive TDEE calculation.
    """
    logger.info(f"Generating weekly recommendation for user {user_id}")

    try:
        db = get_supabase_db()

        # First, get the latest adaptive calculation
        adaptive_result = db.client.table("adaptive_nutrition_calculations")\
            .select("*")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        # Get user's nutrition preferences
        prefs_result = db.client.table("nutrition_preferences")\
            .select("*")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        prefs = prefs_result.data or {}
        current_goal = prefs.get("nutrition_goal", "maintain")
        current_calories = prefs.get("target_calories", 2000)
        current_protein = prefs.get("target_protein_g", 150)
        current_carbs = prefs.get("target_carbs_g", 200)
        current_fat = prefs.get("target_fat_g", 70)

        # Determine adjustment
        adjustment_reason = None
        adjustment_amount = 0
        calculated_tdee = 0
        target_rate = 0.0

        if adaptive_result.data:
            adaptive = adaptive_result.data
            calculated_tdee = adaptive.get("calculated_tdee", 0)
            quality = adaptive.get("data_quality_score", 0)

            # Only make recommendations if we have enough data
            if quality >= 0.5 and calculated_tdee > 0:
                # Determine goal-based adjustment
                if current_goal == "lose_fat":
                    target_rate = -0.5  # 0.5 kg/week loss
                    recommended_calories = calculated_tdee - 500
                    adjustment_amount = recommended_calories - current_calories
                    if adjustment_amount != 0:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for fat loss goal"
                elif current_goal == "build_muscle":
                    target_rate = 0.25  # 0.25 kg/week gain
                    recommended_calories = calculated_tdee + 250
                    adjustment_amount = recommended_calories - current_calories
                    if adjustment_amount != 0:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for muscle building"
                else:  # maintain
                    target_rate = 0.0
                    recommended_calories = calculated_tdee
                    adjustment_amount = recommended_calories - current_calories
                    if abs(adjustment_amount) > 100:
                        adjustment_reason = f"Based on your actual TDEE of {calculated_tdee} cal, adjusting by {adjustment_amount:+d} cal for maintenance"
                    else:
                        adjustment_amount = 0
            else:
                # Not enough data - keep current targets
                recommended_calories = current_calories
                adjustment_reason = "Need more tracking data (6+ days logged, 2+ weight entries) for adaptive recommendations"
        else:
            recommended_calories = current_calories
            adjustment_reason = "No adaptive calculation available yet - continue tracking to get personalized recommendations"

        # Calculate macros based on new calories
        # Use a balanced split: 30% protein, 40% carbs, 30% fat
        recommended_protein = int((recommended_calories * 0.30) / 4)  # 4 cal/g
        recommended_carbs = int((recommended_calories * 0.40) / 4)    # 4 cal/g
        recommended_fat = int((recommended_calories * 0.30) / 9)      # 9 cal/g

        # Create the recommendation
        week_start = datetime.utcnow().date() - timedelta(days=datetime.utcnow().weekday())

        rec_data = {
            "user_id": user_id,
            "week_start": week_start.isoformat(),
            "current_goal": current_goal,
            "target_rate_per_week": target_rate,
            "calculated_tdee": calculated_tdee,
            "recommended_calories": recommended_calories,
            "recommended_protein_g": recommended_protein,
            "recommended_carbs_g": recommended_carbs,
            "recommended_fat_g": recommended_fat,
            "adjustment_reason": adjustment_reason,
            "adjustment_amount": adjustment_amount,
            "user_accepted": False,
            "user_modified": False,
        }

        result = db.client.table("weekly_nutrition_recommendations")\
            .insert(rec_data)\
            .execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to create weekly nutrition recommendation")

        data = result.data[0]
        return WeeklyRecommendationResponse(
            id=data["id"],
            user_id=data["user_id"],
            week_start=datetime.fromisoformat(str(data["week_start"]).replace("Z", "+00:00")),
            current_goal=data.get("current_goal", "maintain"),
            target_rate_per_week=float(data.get("target_rate_per_week", 0)),
            calculated_tdee=data.get("calculated_tdee", 0),
            recommended_calories=data.get("recommended_calories", 0),
            recommended_protein_g=data.get("recommended_protein_g", 0),
            recommended_carbs_g=data.get("recommended_carbs_g", 0),
            recommended_fat_g=data.get("recommended_fat_g", 0),
            adjustment_reason=data.get("adjustment_reason"),
            adjustment_amount=data.get("adjustment_amount", 0),
            user_accepted=data.get("user_accepted", False),
            user_modified=data.get("user_modified", False),
            modified_calories=data.get("modified_calories"),
        )

    except Exception as e:
        logger.error(f"Failed to generate weekly recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# COOKING CONVERSION ENDPOINTS
# ============================================================================

class CookingConversionFactorResponse(BaseModel):
    """Response model for a cooking conversion factor."""
    food_name: str
    food_category: str
    raw_to_cooked_ratio: float
    cooking_method: str
    calories_retention: float
    protein_retention: float
    carbs_retention: float
    fat_change: float
    notes: Optional[str] = None


class ConvertWeightRequest(BaseModel):
    """Request to convert between raw and cooked weight."""
    weight_g: float
    food_name: str
    from_state: str  # "raw" or "cooked"
    cooking_method: Optional[str] = None
    nutrients_per_100g: Optional[dict] = None  # {"calories": 100, "protein": 10, "carbs": 20, "fat": 5}


class ConvertWeightResponse(BaseModel):
    """Response after converting weight."""
    original_weight_g: float
    original_state: str
    converted_weight_g: float
    converted_state: str
    food_name: str
    cooking_method: str
    raw_to_cooked_ratio: float
    adjusted_calories_per_100g: Optional[float] = None
    adjusted_protein_per_100g: Optional[float] = None
    adjusted_carbs_per_100g: Optional[float] = None
    adjusted_fat_per_100g: Optional[float] = None
    notes: Optional[str] = None


class CookingConversionsListResponse(BaseModel):
    """Response with list of cooking conversions."""
    conversions: List[CookingConversionFactorResponse]
    total_count: int
    categories: List[str]
    cooking_methods: List[str]


@router.get("/cooking-conversions", response_model=CookingConversionsListResponse)
async def list_cooking_conversions(
    category: Optional[str] = Query(None, description="Filter by food category (e.g., grains, meats, vegetables)"),
    search: Optional[str] = Query(None, description="Search for specific foods"),
):
    """
    List all available cooking conversion factors.

    Use category to filter by food type (grains, legumes, meats, poultry, seafood, vegetables, eggs).
    Use search to find specific foods by name.
    """
    try:
        service = get_cooking_conversion_service()

        if search:
            # Search for specific foods
            conversions = service.search_foods(search)
        elif category:
            # Filter by category
            conversions = service.get_conversions_by_category(category)
        else:
            # Get all conversions
            conversions = service.get_all_conversions()

        return CookingConversionsListResponse(
            conversions=[CookingConversionFactorResponse(**c) for c in conversions],
            total_count=len(conversions),
            categories=service.get_available_categories(),
            cooking_methods=service.get_cooking_methods(),
        )

    except Exception as e:
        logger.error(f"Failed to list cooking conversions: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/cooking-conversions/{food_category}", response_model=List[CookingConversionFactorResponse])
async def get_cooking_conversions_by_category(food_category: str):
    """
    Get cooking conversion factors for a specific food category.

    Categories: grains, legumes, meats, poultry, seafood, vegetables, eggs
    """
    try:
        service = get_cooking_conversion_service()
        conversions = service.get_conversions_by_category(food_category)

        if not conversions:
            raise HTTPException(
                status_code=404,
                detail=f"No conversions found for category: {food_category}. "
                       f"Valid categories: {', '.join(service.get_available_categories())}"
            )

        return [CookingConversionFactorResponse(**c) for c in conversions]

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get cooking conversions by category: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/convert-weight", response_model=ConvertWeightResponse)
async def convert_food_weight(request: ConvertWeightRequest):
    """
    Convert food weight between raw and cooked states.

    Examples:
    - Convert 100g raw rice to cooked weight: {"weight_g": 100, "food_name": "white_rice", "from_state": "raw"}
    - Convert 240g cooked rice to raw weight: {"weight_g": 240, "food_name": "white_rice", "from_state": "cooked"}
    - Convert with nutrients adjustment: include nutrients_per_100g to get adjusted nutrient values

    Ratios:
    - Grains/legumes have ratio > 1 (absorb water, increase in weight when cooked)
    - Meats/seafood have ratio < 1 (lose moisture, decrease in weight when cooked)
    """
    try:
        service = get_cooking_conversion_service()

        result = service.convert_weight(
            weight_g=request.weight_g,
            food_name=request.food_name,
            from_state=request.from_state,
            cooking_method=request.cooking_method,
            nutrients_per_100g=request.nutrients_per_100g,
        )

        if not result:
            raise HTTPException(
                status_code=404,
                detail=f"No conversion factor found for '{request.food_name}'. "
                       f"Try searching with /cooking-conversions?search={request.food_name}"
            )

        # Log the conversion activity
        await log_user_activity(
            user_id="system",  # Could be updated if user_id is added to request
            action="cooking_conversion",
            endpoint="/api/v1/nutrition/convert-weight",
            message=f"Converted {request.weight_g}g {request.from_state} {request.food_name} to {result.converted_weight_g:.1f}g {result.converted_state}",
            metadata={
                "food_name": request.food_name,
                "from_state": request.from_state,
                "original_weight_g": request.weight_g,
                "converted_weight_g": result.converted_weight_g,
                "cooking_method": result.cooking_method,
                "ratio": result.raw_to_cooked_ratio,
            },
            status_code=200
        )

        return ConvertWeightResponse(**result.to_dict())

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to convert food weight: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================================
# MACROFACTOR-STYLE ADAPTIVE TDEE ENDPOINTS
# ============================================================================

from services.adaptive_tdee_service import (
    get_adaptive_tdee_service,
    TDEECalculation,
    WeightLog as ServiceWeightLog,
    FoodLogSummary,
)
from services.metabolic_adaptation_service import (
    get_metabolic_adaptation_service,
    TDEEHistoryEntry,
    MetabolicAdaptationEvent,
    AdaptationEventType,
)
from services.adherence_tracking_service import (
    get_adherence_tracking_service,
    NutritionTargets as ServiceNutritionTargets,
    NutritionActuals,
    DailyAdherence,
    WeeklyAdherenceSummary,
    SustainabilityScore,
)


class DetailedTDEEResponse(BaseModel):
    """Response model for detailed TDEE with confidence intervals."""
    tdee: int
    confidence_low: int
    confidence_high: int
    uncertainty_display: str  # e.g., "±150"
    uncertainty_calories: int
    data_quality_score: float
    weight_change_kg: float
    avg_daily_intake: int
    start_weight_kg: float
    end_weight_kg: float
    days_analyzed: int
    food_logs_count: int
    weight_logs_count: int
    weight_trend: dict
    metabolic_adaptation: Optional[dict] = None


class AdherenceSummaryResponse(BaseModel):
    """Response model for adherence summary."""
    weekly_adherence: List[dict]
    average_adherence: float
    sustainability_score: float
    sustainability_rating: str
    recommendation: str
    weeks_analyzed: int


class RecommendationOption(BaseModel):
    """Single recommendation option."""
    option_type: str  # 'aggressive', 'moderate', 'conservative', 'maintenance'
    calories: int
    protein_g: int
    carbs_g: int
    fat_g: int
    expected_weekly_change_kg: float
    sustainability_rating: str
    description: str
    is_recommended: bool = False


class RecommendationOptionsResponse(BaseModel):
    """Response model for multiple recommendation options."""
    current_tdee: int
    current_goal: str
    adherence_score: float
    has_adaptation: bool
    adaptation_details: Optional[dict] = None
    options: List[RecommendationOption]
    recommended_option: str


class SelectRecommendationRequest(BaseModel):
    """Request to select a recommendation option."""
    option_type: str


@router.get("/tdee/{user_id}/detailed", response_model=DetailedTDEEResponse)
async def get_detailed_tdee(user_id: str, days: int = Query(default=14, ge=7, le=30)):
    """
    Get TDEE with confidence intervals, weight trend, and metabolic adaptation status.

    This endpoint provides MacroFactor-style detailed TDEE calculation:
    - EMA-smoothed weight trends
    - Confidence intervals (e.g., "2,150 ±120 cal")
    - Metabolic adaptation detection
    - Data quality scoring
    """
    logger.info(f"Getting detailed TDEE for user {user_id} over {days} days")

    try:
        db = get_supabase_db()
        tdee_service = get_adaptive_tdee_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get food logs for the period
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(days=days)

        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, total_macros")\
            .eq("user_id", user_id)\
            .gte("logged_at", start_date.isoformat())\
            .lte("logged_at", end_date.isoformat())\
            .execute()

        # Aggregate food logs by day
        daily_calories = {}
        for log in food_logs_result.data or []:
            log_date = datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            if log_date not in daily_calories:
                daily_calories[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0}
            daily_calories[log_date]["calories"] += log.get("total_calories", 0) or 0
            macros = log.get("total_macros") or {}
            daily_calories[log_date]["protein"] += macros.get("protein_g", 0) or 0
            daily_calories[log_date]["carbs"] += macros.get("carbs_g", 0) or 0
            daily_calories[log_date]["fat"] += macros.get("fat_g", 0) or 0

        food_logs = [
            FoodLogSummary(
                date=d,
                total_calories=int(data["calories"]),
                protein_g=data["protein"],
                carbs_g=data["carbs"],
                fat_g=data["fat"],
            )
            for d, data in daily_calories.items()
        ]

        # Get weight logs
        weight_logs_result = db.client.table("weight_logs")\
            .select("id, user_id, weight_kg, logged_at")\
            .eq("user_id", user_id)\
            .gte("logged_at", start_date.isoformat())\
            .order("logged_at")\
            .execute()

        weight_logs = [
            ServiceWeightLog(
                id=log["id"],
                user_id=log["user_id"],
                weight_kg=float(log["weight_kg"]),
                logged_at=datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")),
            )
            for log in weight_logs_result.data or []
        ]

        # Calculate TDEE with confidence intervals
        calculation = tdee_service.calculate_tdee_with_confidence(food_logs, weight_logs, days)

        if not calculation:
            raise HTTPException(
                status_code=400,
                detail="Insufficient data for TDEE calculation. Need at least 5 food logs and 2 weight entries."
            )

        # Get weight trend
        trend = tdee_service.get_weight_trend(weight_logs)

        # Check for metabolic adaptation
        # Get historical TDEE calculations
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee", 0),
                weight_change_kg=float(h.get("weight_change_kg", 0) or 0),
                avg_daily_intake=h.get("avg_daily_intake", 0),
                data_quality_score=float(h.get("data_quality_score", 0) or 0),
            )
            for h in history_result.data or []
        ]

        # Get user's current goal
        prefs_result = db.client.table("nutrition_preferences")\
            .select("nutrition_goal, target_calories")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        current_goal = prefs_result.data.get("nutrition_goal", "maintain") if prefs_result.data else "maintain"
        current_deficit = 500  # Default deficit

        if prefs_result.data and prefs_result.data.get("target_calories"):
            current_deficit = calculation.tdee - prefs_result.data.get("target_calories", calculation.tdee)

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(
            tdee_history, current_goal, abs(current_deficit)
        )

        # Store this calculation in history
        try:
            db.client.table("tdee_calculation_history").insert({
                "user_id": user_id,
                "period_start": start_date.isoformat(),
                "period_end": end_date.isoformat(),
                "days_analyzed": calculation.days_analyzed,
                "food_logs_count": calculation.food_logs_count,
                "weight_logs_count": calculation.weight_logs_count,
                "start_weight_kg": calculation.start_weight_kg,
                "end_weight_kg": calculation.end_weight_kg,
                "weight_change_kg": calculation.weight_change_kg,
                "avg_daily_intake": calculation.avg_daily_intake,
                "calculated_tdee": calculation.tdee,
                "confidence_low": calculation.confidence_low,
                "confidence_high": calculation.confidence_high,
                "uncertainty_calories": calculation.uncertainty_calories,
                "data_quality_score": calculation.data_quality_score,
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to store TDEE history: {e}")

        return DetailedTDEEResponse(
            tdee=calculation.tdee,
            confidence_low=calculation.confidence_low,
            confidence_high=calculation.confidence_high,
            uncertainty_display=f"±{calculation.uncertainty_calories}",
            uncertainty_calories=calculation.uncertainty_calories,
            data_quality_score=calculation.data_quality_score,
            weight_change_kg=calculation.weight_change_kg,
            avg_daily_intake=calculation.avg_daily_intake,
            start_weight_kg=calculation.start_weight_kg,
            end_weight_kg=calculation.end_weight_kg,
            days_analyzed=calculation.days_analyzed,
            food_logs_count=calculation.food_logs_count,
            weight_logs_count=calculation.weight_logs_count,
            weight_trend={
                "smoothed_weight_kg": trend.smoothed_weight if trend else None,
                "raw_weight_kg": trend.raw_weight if trend else None,
                "direction": trend.trend_direction if trend else "stable",
                "weekly_rate_kg": trend.weekly_rate_kg if trend else 0,
                "confidence": trend.confidence if trend else "low",
            },
            metabolic_adaptation=adaptation.to_dict() if adaptation else None,
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get detailed TDEE: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/adherence/{user_id}/summary", response_model=AdherenceSummaryResponse)
async def get_adherence_summary(user_id: str, weeks: int = Query(default=4, ge=1, le=12)):
    """
    Get adherence summary with sustainability score.

    Returns:
    - Weekly adherence breakdown
    - Overall sustainability rating (high/medium/low)
    - Recommendations based on adherence patterns
    """
    logger.info(f"Getting adherence summary for user {user_id} over {weeks} weeks")

    try:
        db = get_supabase_db()
        adherence_service = get_adherence_tracking_service()

        # Get user's nutrition targets
        prefs_result = db.client.table("nutrition_preferences")\
            .select("target_calories, target_protein_g, target_carbs_g, target_fat_g, nutrition_goal")\
            .eq("user_id", user_id)\
            .maybe_single()\
            .execute()

        if not prefs_result.data:
            raise HTTPException(status_code=404, detail="Nutrition preferences not found")

        prefs = prefs_result.data
        targets = ServiceNutritionTargets(
            calories=prefs.get("target_calories", 2000),
            protein_g=prefs.get("target_protein_g", 150),
            carbs_g=prefs.get("target_carbs_g", 200),
            fat_g=prefs.get("target_fat_g", 65),
        )

        # Get daily nutrition summaries for the period
        end_date = datetime.utcnow().date()
        start_date = end_date - timedelta(weeks=weeks * 7)

        # Get food logs aggregated by day
        food_logs_result = db.client.table("food_logs")\
            .select("logged_at, total_calories, total_macros")\
            .eq("user_id", user_id)\
            .gte("logged_at", start_date.isoformat())\
            .lte("logged_at", end_date.isoformat())\
            .execute()

        # Aggregate by day
        daily_totals = {}
        for log in food_logs_result.data or []:
            log_date = datetime.fromisoformat(str(log["logged_at"]).replace("Z", "+00:00")).date()
            if log_date not in daily_totals:
                daily_totals[log_date] = {"calories": 0, "protein": 0, "carbs": 0, "fat": 0, "meals": 0}
            daily_totals[log_date]["calories"] += log.get("total_calories", 0) or 0
            macros = log.get("total_macros") or {}
            daily_totals[log_date]["protein"] += macros.get("protein_g", 0) or 0
            daily_totals[log_date]["carbs"] += macros.get("carbs_g", 0) or 0
            daily_totals[log_date]["fat"] += macros.get("fat_g", 0) or 0
            daily_totals[log_date]["meals"] += 1

        # Calculate daily adherence
        daily_adherences = []
        for log_date, totals in daily_totals.items():
            actuals = NutritionActuals(
                date=log_date,
                calories=int(totals["calories"]),
                protein_g=totals["protein"],
                carbs_g=totals["carbs"],
                fat_g=totals["fat"],
                meals_logged=totals["meals"],
            )
            adherence = adherence_service.calculate_daily_adherence(targets, actuals)
            daily_adherences.append(adherence)

        # Group by week and calculate summaries
        weekly_summaries = []
        current_week_start = start_date - timedelta(days=start_date.weekday())  # Monday

        while current_week_start <= end_date:
            week_end = current_week_start + timedelta(days=6)
            week_adherences = [
                a for a in daily_adherences
                if current_week_start <= a.date <= week_end
            ]
            summary = adherence_service.calculate_weekly_summary(week_adherences, current_week_start)
            weekly_summaries.append(summary)
            current_week_start += timedelta(days=7)

        # Calculate sustainability score
        sustainability = adherence_service.calculate_sustainability_score(weekly_summaries)

        return AdherenceSummaryResponse(
            weekly_adherence=[s.to_dict() for s in weekly_summaries[-weeks:]],
            average_adherence=sustainability.avg_adherence,
            sustainability_score=sustainability.score,
            sustainability_rating=sustainability.rating.value,
            recommendation=sustainability.recommendation,
            weeks_analyzed=len(weekly_summaries),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get adherence summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recommendations/{user_id}/options", response_model=RecommendationOptionsResponse)
async def get_recommendation_options(user_id: str):
    """
    Get multiple recommendation options for user to choose from.

    MacroFactor-style multi-option recommendations:
    - Aggressive (if adherence >80% and no adaptation)
    - Moderate (always shown, recommended)
    - Conservative (if adherence <70% or adaptation detected)
    """
    logger.info(f"Getting recommendation options for user {user_id}")

    try:
        db = get_supabase_db()
        adherence_service = get_adherence_tracking_service()
        adaptation_service = get_metabolic_adaptation_service()

        # Get latest adaptive TDEE
        tdee_result = db.client.table("adaptive_nutrition_calculations")\
            .select("calculated_tdee, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(1)\
            .maybe_single()\
            .execute()

        if not tdee_result.data or not tdee_result.data.get("calculated_tdee"):
            # Fall back to nutrition preferences TDEE
            prefs = db.client.table("nutrition_preferences")\
                .select("calculated_tdee, nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()

            if not prefs.data or not prefs.data.get("calculated_tdee"):
                raise HTTPException(
                    status_code=400,
                    detail="No TDEE available. Please log food and weight data first."
                )

            current_tdee = prefs.data.get("calculated_tdee", 2000)
            current_goal = prefs.data.get("nutrition_goal", "maintain")
        else:
            current_tdee = tdee_result.data.get("calculated_tdee", 2000)
            # Get goal from preferences
            prefs = db.client.table("nutrition_preferences")\
                .select("nutrition_goal")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()
            current_goal = prefs.data.get("nutrition_goal", "maintain") if prefs.data else "maintain"

        # Get adherence summary
        adherence_response = await get_adherence_summary(user_id, weeks=4)
        adherence_score = adherence_response.sustainability_score

        # Get TDEE history for adaptation detection
        history_result = db.client.table("adaptive_nutrition_calculations")\
            .select("id, user_id, calculated_at, calculated_tdee, weight_change_kg, avg_daily_intake, data_quality_score")\
            .eq("user_id", user_id)\
            .order("calculated_at", desc=True)\
            .limit(8)\
            .execute()

        tdee_history = [
            TDEEHistoryEntry(
                id=h["id"],
                user_id=h["user_id"],
                calculated_at=datetime.fromisoformat(str(h["calculated_at"]).replace("Z", "+00:00")),
                calculated_tdee=h.get("calculated_tdee", 0),
                weight_change_kg=float(h.get("weight_change_kg", 0) or 0),
                avg_daily_intake=h.get("avg_daily_intake", 0),
                data_quality_score=float(h.get("data_quality_score", 0) or 0),
            )
            for h in history_result.data or []
        ]

        # Detect metabolic adaptation
        adaptation = adaptation_service.detect_metabolic_adaptation(tdee_history, current_goal, 500)

        # Generate recommendation options
        options = _generate_recommendation_options(
            current_tdee=current_tdee,
            goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
        )

        return RecommendationOptionsResponse(
            current_tdee=current_tdee,
            current_goal=current_goal,
            adherence_score=adherence_score,
            has_adaptation=adaptation is not None,
            adaptation_details=adaptation.to_dict() if adaptation else None,
            options=options,
            recommended_option=next((o.option_type for o in options if o.is_recommended), "moderate"),
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to get recommendation options: {e}")
        raise HTTPException(status_code=500, detail=str(e))


def _generate_recommendation_options(
    current_tdee: int,
    goal: str,
    adherence_score: float,
    has_adaptation: bool,
) -> List[RecommendationOption]:
    """Generate 2-3 recommendation options based on user context."""
    options = []

    if goal in ["lose_fat", "lose_weight"]:
        # Aggressive option (only if high adherence and no adaptation)
        if adherence_score >= 0.8 and not has_adaptation:
            aggressive_cals = current_tdee - 750
            options.append(RecommendationOption(
                option_type="aggressive",
                calories=aggressive_cals,
                protein_g=int((aggressive_cals * 0.35) / 4),
                carbs_g=int((aggressive_cals * 0.35) / 4),
                fat_g=int((aggressive_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.68,
                sustainability_rating="low",
                description="Faster results, requires strict adherence. Best for short-term pushes.",
                is_recommended=False,
            ))

        # Moderate option (always shown, usually recommended)
        moderate_cals = current_tdee - 500
        options.append(RecommendationOption(
            option_type="moderate",
            calories=moderate_cals,
            protein_g=int((moderate_cals * 0.30) / 4),
            carbs_g=int((moderate_cals * 0.40) / 4),
            fat_g=int((moderate_cals * 0.30) / 9),
            expected_weekly_change_kg=-0.45,
            sustainability_rating="medium",
            description="Balanced approach. Steady progress without extreme restriction.",
            is_recommended=not has_adaptation and adherence_score >= 0.6,
        ))

        # Conservative option (for low adherence or adaptation)
        if adherence_score < 0.7 or has_adaptation:
            conservative_cals = current_tdee - 250
            options.append(RecommendationOption(
                option_type="conservative",
                calories=conservative_cals,
                protein_g=int((conservative_cals * 0.30) / 4),
                carbs_g=int((conservative_cals * 0.40) / 4),
                fat_g=int((conservative_cals * 0.30) / 9),
                expected_weekly_change_kg=-0.23,
                sustainability_rating="high",
                description="Slower but more sustainable. Better for long-term success.",
                is_recommended=has_adaptation or adherence_score < 0.6,
            ))

    elif goal == "build_muscle":
        # Lean bulk
        lean_cals = current_tdee + 250
        options.append(RecommendationOption(
            option_type="lean_bulk",
            calories=lean_cals,
            protein_g=int((lean_cals * 0.30) / 4),
            carbs_g=int((lean_cals * 0.45) / 4),
            fat_g=int((lean_cals * 0.25) / 9),
            expected_weekly_change_kg=0.20,
            sustainability_rating="high",
            description="Minimize fat gain while building muscle. Slow and steady.",
            is_recommended=True,
        ))

        # Standard bulk
        standard_cals = current_tdee + 400
        options.append(RecommendationOption(
            option_type="standard_bulk",
            calories=standard_cals,
            protein_g=int((standard_cals * 0.28) / 4),
            carbs_g=int((standard_cals * 0.47) / 4),
            fat_g=int((standard_cals * 0.25) / 9),
            expected_weekly_change_kg=0.35,
            sustainability_rating="medium",
            description="Faster muscle gain, some fat gain expected.",
            is_recommended=False,
        ))

    else:  # maintain
        options.append(RecommendationOption(
            option_type="maintenance",
            calories=current_tdee,
            protein_g=int((current_tdee * 0.25) / 4),
            carbs_g=int((current_tdee * 0.45) / 4),
            fat_g=int((current_tdee * 0.30) / 9),
            expected_weekly_change_kg=0.0,
            sustainability_rating="high",
            description="Maintain current weight and body composition.",
            is_recommended=True,
        ))

    # Ensure at least one option is recommended
    if not any(o.is_recommended for o in options) and options:
        options[0].is_recommended = True

    return options


@router.post("/recommendations/{user_id}/select")
async def select_recommendation(user_id: str, request: SelectRecommendationRequest):
    """
    User selects a recommendation option to apply.

    This updates the user's nutrition targets to match the selected option.
    """
    logger.info(f"User {user_id} selecting recommendation: {request.option_type}")

    try:
        # Get available options
        options_response = await get_recommendation_options(user_id)

        # Find selected option
        selected = None
        for opt in options_response.options:
            if opt.option_type == request.option_type:
                selected = opt
                break

        if not selected:
            raise HTTPException(
                status_code=404,
                detail=f"Option '{request.option_type}' not found. Available options: {[o.option_type for o in options_response.options]}"
            )

        db = get_supabase_db()

        # Update user's nutrition targets
        db.client.table("nutrition_preferences")\
            .update({
                "target_calories": selected.calories,
                "target_protein_g": selected.protein_g,
                "target_carbs_g": selected.carbs_g,
                "target_fat_g": selected.fat_g,
                "last_recalculated_at": datetime.utcnow().isoformat(),
            })\
            .eq("user_id", user_id)\
            .execute()

        # Log the decision for analytics
        await log_user_activity(
            user_id=user_id,
            action="recommendation_selected",
            endpoint="/api/v1/nutrition/recommendations/select",
            message=f"Selected {request.option_type} plan: {selected.calories} cal",
            metadata={
                "option_type": request.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "expected_weekly_change_kg": selected.expected_weekly_change_kg,
            },
            status_code=200
        )

        return {
            "success": True,
            "message": f"Applied {request.option_type} plan",
            "applied": {
                "option_type": selected.option_type,
                "calories": selected.calories,
                "protein_g": selected.protein_g,
                "carbs_g": selected.carbs_g,
                "fat_g": selected.fat_g,
                "description": selected.description,
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to select recommendation: {e}")
        raise HTTPException(status_code=500, detail=str(e))
