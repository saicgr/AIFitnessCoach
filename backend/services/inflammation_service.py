"""
Inflammation Analysis Service

Handles:
- Ingredient inflammation analysis via Gemini
- Caching by barcode
- User scan history
- Rate limiting and error handling
"""

from typing import Optional, Dict, List
from datetime import datetime, timedelta
import asyncio
import logging

from core.supabase_client import get_supabase
from services.gemini_service import GeminiService
from services.user_context_service import UserContextService, EventType
from models.inflammation import (
    InflammationAnalysisResponse,
    InflammationCategory,
    IngredientAnalysis,
    IngredientCategory,
    UserInflammationScan,
    UserInflammationStatsResponse,
)

logger = logging.getLogger(__name__)

# Rate limiting: max concurrent Gemini requests
_semaphore = asyncio.Semaphore(5)


class InflammationService:
    """Service for analyzing ingredient inflammation properties."""

    def __init__(self):
        self.gemini = GeminiService()
        self.context_service = UserContextService()

    async def analyze_barcode(
        self,
        user_id: str,
        barcode: str,
        product_name: Optional[str],
        ingredients_text: str,
    ) -> InflammationAnalysisResponse:
        """
        Analyze ingredients for a barcode, using cache if available.

        Args:
            user_id: User requesting the analysis
            barcode: Product barcode (cache key)
            product_name: Product name for context
            ingredients_text: Raw ingredients from Open Food Facts

        Returns:
            InflammationAnalysisResponse with full analysis
        """
        # 1. Check cache first
        cached = await self._get_cached_analysis(barcode)
        if cached:
            logger.info(f"Cache hit for barcode {barcode}")
            # Record user scan even if cached
            await self._record_user_scan(user_id, cached["id"])
            # Log context event (cache hit)
            await self._log_scan_event(
                user_id=user_id,
                barcode=barcode,
                product_name=cached.get("product_name"),
                overall_score=cached.get("overall_score", 5),
                inflammatory_count=len(cached.get("inflammatory_ingredients", [])),
                from_cache=True,
            )
            return self._build_response(cached, from_cache=True)

        # 2. Not cached - run Gemini analysis with rate limiting
        logger.info(f"Cache miss for barcode {barcode}, running Gemini analysis")

        async with _semaphore:
            try:
                analysis = await self._analyze_with_retry(
                    ingredients_text=ingredients_text,
                    product_name=product_name,
                )
            except Exception as e:
                logger.error(f"Gemini analysis failed for {barcode}: {e}")
                raise

        if not analysis:
            raise ValueError("Failed to analyze ingredients")

        # 3. Store in cache
        analysis_id = await self._store_analysis(
            barcode=barcode,
            product_name=product_name,
            ingredients_text=ingredients_text,
            analysis=analysis,
        )

        # 4. Record user scan
        await self._record_user_scan(user_id, analysis_id)

        # 5. Log context event for AI personalization
        await self._log_scan_event(
            user_id=user_id,
            barcode=barcode,
            product_name=product_name,
            overall_score=analysis.get("overall_score", 5),
            inflammatory_count=len(analysis.get("inflammatory_ingredients", [])),
            from_cache=False,
        )

        # 6. Build and return response
        stored = await self._get_cached_analysis(barcode)
        return self._build_response(stored, from_cache=False)

    async def _analyze_with_retry(
        self,
        ingredients_text: str,
        product_name: Optional[str],
        max_retries: int = 3,
    ) -> Optional[Dict]:
        """Analyze with exponential backoff retry."""
        last_error = None
        for attempt in range(max_retries):
            try:
                result = await self.gemini.analyze_ingredient_inflammation(
                    ingredients_text=ingredients_text,
                    product_name=product_name,
                )
                if result:
                    return result
            except Exception as e:
                last_error = e
                if attempt < max_retries - 1:
                    wait_time = 2 ** attempt  # 1, 2, 4 seconds
                    logger.warning(f"Retry {attempt + 1} after {wait_time}s: {e}")
                    await asyncio.sleep(wait_time)
                else:
                    raise last_error
        return None

    async def _get_cached_analysis(self, barcode: str) -> Optional[Dict]:
        """Get cached analysis if exists and not expired."""
        try:
            client = get_supabase().client
            # Use limit(1) instead of maybe_single() to avoid 406 error when
            # multiple rows match (shouldn't happen with unique barcode, but safer)
            result = client.table("food_inflammation_analyses")\
                .select("*")\
                .eq("barcode", barcode)\
                .gt("expires_at", datetime.utcnow().isoformat())\
                .limit(1)\
                .execute()

            if result.data and len(result.data) > 0:
                return result.data[0]
            return None
        except Exception as e:
            logger.error(f"Error fetching cached analysis: {e}")
            return None

    async def _store_analysis(
        self,
        barcode: str,
        product_name: Optional[str],
        ingredients_text: str,
        analysis: Dict,
    ) -> str:
        """Store analysis in database and return ID."""
        client = get_supabase().client

        data = {
            "barcode": barcode,
            "product_name": product_name,
            "ingredients_text": ingredients_text,
            "overall_score": analysis.get("overall_score", 5),
            "overall_category": analysis.get("overall_category", "neutral"),
            "summary": analysis.get("summary", "Analysis complete."),
            "recommendation": analysis.get("recommendation"),
            "ingredient_analyses": analysis.get("ingredient_analyses", []),
            "inflammatory_ingredients": analysis.get("inflammatory_ingredients", []),
            "anti_inflammatory_ingredients": analysis.get("anti_inflammatory_ingredients", []),
            "additives_found": analysis.get("additives_found", []),
            "analysis_confidence": analysis.get("analysis_confidence"),
            "model_version": "gemini-2.0-flash",
            "expires_at": (datetime.utcnow() + timedelta(days=90)).isoformat(),
        }

        # Upsert to handle race conditions
        result = client.table("food_inflammation_analyses")\
            .upsert(data, on_conflict="barcode")\
            .execute()

        if not result.data:
            raise Exception("Failed to store inflammation analysis")

        return result.data[0]["id"]

    async def _record_user_scan(self, user_id: str, analysis_id: str) -> None:
        """Record that a user scanned this product."""
        try:
            client = get_supabase().client
            client.table("user_inflammation_scans").insert({
                "user_id": user_id,
                "analysis_id": analysis_id,
            }).execute()
        except Exception as e:
            # Don't fail the whole request if scan recording fails
            logger.error(f"Failed to record user scan: {e}")

    async def _log_scan_event(
        self,
        user_id: str,
        barcode: str,
        product_name: Optional[str],
        overall_score: int,
        inflammatory_count: int,
        from_cache: bool,
    ) -> None:
        """Log inflammation scan event for AI context and personalization."""
        try:
            await self.context_service.log_event(
                user_id=user_id,
                event_type=EventType.INFLAMMATION_SCAN_PERFORMED,
                event_data={
                    "barcode": barcode,
                    "product_name": product_name,
                    "overall_score": overall_score,
                    "inflammatory_count": inflammatory_count,
                    "from_cache": from_cache,
                    "is_healthy": overall_score <= 4,
                },
            )
        except Exception as e:
            # Don't fail the whole request if context logging fails
            logger.error(f"Failed to log scan event: {e}")

    def _build_response(self, data: Dict, from_cache: bool) -> InflammationAnalysisResponse:
        """Build response model from database row."""
        ingredient_analyses = []
        for ia in data.get("ingredient_analyses", []):
            try:
                category_str = ia.get("category", "unknown")
                # Map category strings to enum values
                category_map = {
                    "highly_inflammatory": IngredientCategory.HIGHLY_INFLAMMATORY,
                    "inflammatory": IngredientCategory.INFLAMMATORY,
                    "neutral": IngredientCategory.NEUTRAL,
                    "anti_inflammatory": IngredientCategory.ANTI_INFLAMMATORY,
                    "highly_anti_inflammatory": IngredientCategory.HIGHLY_ANTI_INFLAMMATORY,
                    "additive": IngredientCategory.ADDITIVE,
                    "unknown": IngredientCategory.UNKNOWN,
                }
                category = category_map.get(category_str, IngredientCategory.UNKNOWN)

                ingredient_analyses.append(IngredientAnalysis(
                    name=ia.get("name", "Unknown"),
                    category=category,
                    score=ia.get("score", 5),
                    reason=ia.get("reason", ""),
                    is_inflammatory=ia.get("is_inflammatory", False),
                    is_additive=ia.get("is_additive", False),
                    scientific_notes=ia.get("scientific_notes"),
                ))
            except Exception as e:
                logger.warning(f"Failed to parse ingredient analysis: {e}")
                continue

        # Count ingredients by type
        inflammatory_count = len(data.get("inflammatory_ingredients", []))
        anti_inflammatory_count = len(data.get("anti_inflammatory_ingredients", []))
        neutral_count = len(ingredient_analyses) - inflammatory_count - anti_inflammatory_count

        # Parse created_at
        created_at_str = data.get("created_at", datetime.utcnow().isoformat())
        if isinstance(created_at_str, str):
            try:
                created_at = datetime.fromisoformat(created_at_str.replace("Z", "+00:00"))
            except:
                created_at = datetime.utcnow()
        else:
            created_at = created_at_str

        return InflammationAnalysisResponse(
            analysis_id=data["id"],
            barcode=data["barcode"],
            product_name=data.get("product_name"),
            overall_score=data["overall_score"],
            overall_category=InflammationCategory(data["overall_category"]),
            summary=data["summary"],
            recommendation=data.get("recommendation"),
            ingredient_analyses=ingredient_analyses,
            inflammatory_ingredients=data.get("inflammatory_ingredients", []),
            anti_inflammatory_ingredients=data.get("anti_inflammatory_ingredients", []),
            additives_found=data.get("additives_found", []),
            inflammatory_count=inflammatory_count,
            anti_inflammatory_count=anti_inflammatory_count,
            neutral_count=max(0, neutral_count),
            from_cache=from_cache,
            analysis_confidence=data.get("analysis_confidence"),
            created_at=created_at,
        )

    # ========================================
    # History Methods
    # ========================================

    async def get_user_history(
        self,
        user_id: str,
        limit: int = 20,
        offset: int = 0,
        favorited_only: bool = False,
    ) -> List[UserInflammationScan]:
        """Get user's scan history."""
        try:
            client = get_supabase().client

            query = client.table("user_inflammation_history")\
                .select("*")\
                .eq("user_id", user_id)\
                .order("scanned_at", desc=True)\
                .range(offset, offset + limit - 1)

            if favorited_only:
                query = query.eq("is_favorited", True)

            result = query.execute()

            scans = []
            for row in (result.data or []):
                try:
                    scanned_at_str = row.get("scanned_at", datetime.utcnow().isoformat())
                    if isinstance(scanned_at_str, str):
                        scanned_at = datetime.fromisoformat(scanned_at_str.replace("Z", "+00:00"))
                    else:
                        scanned_at = scanned_at_str

                    scans.append(UserInflammationScan(
                        scan_id=row["scan_id"],
                        user_id=row["user_id"],
                        barcode=row["barcode"],
                        product_name=row.get("product_name"),
                        overall_score=row["overall_score"],
                        overall_category=InflammationCategory(row["overall_category"]),
                        summary=row["summary"],
                        scanned_at=scanned_at,
                        notes=row.get("notes"),
                        is_favorited=row.get("is_favorited", False),
                    ))
                except Exception as e:
                    logger.warning(f"Failed to parse scan history entry: {e}")
                    continue

            return scans
        except Exception as e:
            logger.error(f"Error fetching user history: {e}")
            return []

    async def get_user_stats(self, user_id: str) -> UserInflammationStatsResponse:
        """Get aggregated stats for a user."""
        try:
            client = get_supabase().client

            result = client.table("user_inflammation_stats")\
                .select("*")\
                .eq("user_id", user_id)\
                .maybe_single()\
                .execute()

            if not result.data:
                return UserInflammationStatsResponse(user_id=user_id)

            data = result.data
            last_scan_at = None
            if data.get("last_scan_at"):
                try:
                    last_scan_at = datetime.fromisoformat(data["last_scan_at"].replace("Z", "+00:00"))
                except:
                    pass

            return UserInflammationStatsResponse(
                user_id=user_id,
                total_scans=data.get("total_scans", 0),
                avg_inflammation_score=float(data.get("avg_inflammation_score")) if data.get("avg_inflammation_score") else None,
                inflammatory_products_scanned=data.get("inflammatory_products_scanned", 0),
                anti_inflammatory_products_scanned=data.get("anti_inflammatory_products_scanned", 0),
                last_scan_at=last_scan_at,
            )
        except Exception as e:
            logger.error(f"Error fetching user stats: {e}")
            return UserInflammationStatsResponse(user_id=user_id)

    async def update_scan_notes(
        self,
        user_id: str,
        scan_id: str,
        notes: Optional[str],
    ) -> bool:
        """Update notes on a user's scan."""
        try:
            client = get_supabase().client
            result = client.table("user_inflammation_scans")\
                .update({"notes": notes})\
                .eq("id", scan_id)\
                .eq("user_id", user_id)\
                .execute()
            return len(result.data) > 0
        except Exception as e:
            logger.error(f"Error updating scan notes: {e}")
            return False

    async def toggle_favorite(
        self,
        user_id: str,
        scan_id: str,
        is_favorited: bool,
    ) -> bool:
        """Toggle favorite status on a scan."""
        try:
            client = get_supabase().client
            result = client.table("user_inflammation_scans")\
                .update({"is_favorited": is_favorited})\
                .eq("id", scan_id)\
                .eq("user_id", user_id)\
                .execute()
            return len(result.data) > 0
        except Exception as e:
            logger.error(f"Error toggling favorite: {e}")
            return False


# Singleton
_inflammation_service: Optional[InflammationService] = None


def get_inflammation_service() -> InflammationService:
    """Get singleton instance of InflammationService."""
    global _inflammation_service
    if _inflammation_service is None:
        _inflammation_service = InflammationService()
    return _inflammation_service
