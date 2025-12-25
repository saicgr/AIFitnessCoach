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
"""
from datetime import datetime
from typing import List, Optional
import uuid
import base64
from fastapi import APIRouter, HTTPException, Query, UploadFile, File, Form
from pydantic import BaseModel

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


class LogFoodResponse(BaseModel):
    """Response after logging food from image or text."""
    success: bool
    food_log_id: str
    food_items: List[dict]
    total_calories: int
    protein_g: float
    carbs_g: float
    fat_g: float
    fiber_g: Optional[float] = None


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

        # Get meals for the day
        meals = db.list_food_logs(
            user_id=user_id,
            from_date=date,
            to_date=date,
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
        gemini_service = GeminiService()
        food_analysis = await gemini_service.analyze_food_image(
            image_base64=image_base64,
            mime_type=content_type,
        )

        if not food_analysis or not food_analysis.get('food_items'):
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
    Log food from a text description using Gemini.

    This endpoint:
    1. Parses the text description with Gemini
    2. Extracts food items and estimates nutrition
    3. Creates a food log entry

    Example descriptions:
    - "2 eggs, toast with butter, and orange juice"
    - "chicken salad with grilled chicken, lettuce, tomatoes, and ranch dressing"
    - "a bowl of oatmeal with banana and honey"
    """
    logger.info(f"Logging food from text for user {request.user_id}: {request.description[:50]}...")

    try:
        # Parse description with Gemini
        gemini_service = GeminiService()
        food_analysis = await gemini_service.parse_food_description(request.description)

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

        # Create food log
        db = get_supabase_db()

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
            ai_feedback=food_analysis.get('feedback'),
            health_score=None,
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
        )

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to log food from text: {e}")
        raise HTTPException(status_code=500, detail=str(e))
