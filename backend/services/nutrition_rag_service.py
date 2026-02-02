"""
Nutrition RAG Service - Goal-specific nutrition knowledge retrieval.

This service provides contextual nutrition knowledge based on user's fitness goals.
Used to enhance food scoring with relevant nutrition facts and recommendations.

Uses ChromaDB for vector similarity search.
Includes goal-based caching to avoid repeated embeddings and DB queries.
"""
import logging
from typing import List, Dict, Any, Optional
import uuid

from core.chroma_cloud import get_chroma_cloud_client
from core.db.nutrition_db import NutritionDB
from services.gemini_service import GeminiService

logger = logging.getLogger(__name__)


# Collection name for nutrition knowledge
NUTRITION_COLLECTION_NAME = "nutrition_knowledge"


class NutritionRAGService:
    """
    RAG service for nutrition knowledge retrieval.

    Stores goal-specific nutrition facts and retrieves relevant context
    based on user goals and food items being analyzed.

    Includes goal-based caching to dramatically speed up repeated queries.
    """

    def __init__(
        self,
        gemini_service: Optional[GeminiService] = None,
        nutrition_db: Optional[NutritionDB] = None,
    ):
        self.gemini_service = gemini_service or GeminiService()
        self._nutrition_db = nutrition_db
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_or_create_collection(NUTRITION_COLLECTION_NAME)
        print(f"✅ NutritionRAG initialized with {self.collection.count()} documents")

    @property
    def nutrition_db(self) -> Optional[NutritionDB]:
        """Get NutritionDB instance for caching, creating if needed."""
        if self._nutrition_db is None:
            try:
                from core.db.facade import get_supabase_db
                db = get_supabase_db()
                self._nutrition_db = db.nutrition
            except Exception as e:
                logger.warning(f"Could not initialize NutritionDB for caching: {e}")
                return None
        return self._nutrition_db

    async def add_knowledge(
        self,
        content: str,
        goals: List[str],
        category: str,
        metadata: Optional[Dict[str, Any]] = None,
    ) -> str:
        """
        Add nutrition knowledge to the RAG system.

        Args:
            content: The nutrition fact/knowledge text
            goals: List of fitness goals this applies to (e.g., ["build_muscle", "lose_weight"])
            category: Category of knowledge (e.g., "protein", "carbs", "warnings", "tips")
            metadata: Additional metadata

        Returns:
            Document ID
        """
        doc_id = str(uuid.uuid4())

        # Get embedding from Gemini
        embedding = await self.gemini_service.get_embedding_async(content)

        # Store in ChromaDB
        self.collection.add(
            ids=[doc_id],
            embeddings=[embedding],
            documents=[content],
            metadatas=[{
                "goals": ",".join(goals),  # ChromaDB doesn't support list values
                "category": category,
                **(metadata or {}),
            }],
        )

        print(f"📚 Added nutrition knowledge: {doc_id[:8]}... (total: {self.collection.count()})")
        return doc_id

    async def get_context_for_goals(
        self,
        food_description: str,
        user_goals: List[str],
        n_results: int = 5,
        use_cache: bool = True,
    ) -> str:
        """
        Get relevant nutrition context based on food and user goals.

        Includes goal-based caching for faster repeated queries.
        Goals are cached separately from food descriptions since they change rarely.

        Args:
            food_description: The food being analyzed
            user_goals: User's fitness goals
            n_results: Number of results to retrieve
            use_cache: Whether to use goal-based caching (default True)

        Returns:
            Formatted context string for Gemini prompt
        """
        if not user_goals:
            return ""

        # Create goal hash for caching (goals don't change often)
        goal_key = {"goals": sorted(user_goals), "n_results": n_results}
        goal_hash = NutritionDB.create_goal_hash(goal_key)

        # Try cache first (goals-only cache, independent of food description)
        if use_cache and self.nutrition_db:
            try:
                cached_context = self.nutrition_db.get_cached_rag_context(goal_hash)
                if cached_context:
                    logger.info(f"🎯 RAG cache HIT for goals: {user_goals}")
                    # Return cached context formatted for this food
                    return self._format_cached_context(cached_context, food_description)
            except Exception as e:
                logger.warning(f"RAG cache lookup failed: {e}")

        # Cache miss - do full RAG query
        logger.info(f"🔄 RAG cache MISS - querying ChromaDB for goals: {user_goals}")

        # Create query combining food and goals
        query = f"Food: {food_description}. Goals: {', '.join(user_goals)}"

        # Get embedding for query
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Query ChromaDB
        results = self.collection.query(
            query_embeddings=[query_embedding],
            n_results=n_results * 2,  # Get more to filter
            include=["documents", "metadatas", "distances"]
        )

        if not results or not results.get("documents") or not results["documents"][0]:
            return ""

        # Filter results to match user goals
        relevant_docs = []
        for i, doc in enumerate(results["documents"][0]):
            metadata = results["metadatas"][0][i] if results.get("metadatas") else {}
            doc_goals = metadata.get("goals", "").split(",")

            # Check if any user goal matches document goals
            if any(goal in doc_goals for goal in user_goals) or "general" in doc_goals:
                relevant_docs.append({
                    "content": doc,
                    "category": metadata.get("category", "general"),
                    "distance": results["distances"][0][i] if results.get("distances") else 0
                })

        # Sort by relevance (lower distance = more relevant)
        relevant_docs.sort(key=lambda x: x["distance"])

        # Take top n_results
        relevant_docs = relevant_docs[:n_results]

        if not relevant_docs:
            return ""

        # Cache the goal-specific results (not food-specific)
        if use_cache and self.nutrition_db and relevant_docs:
            try:
                cache_data = {
                    "documents": [doc["content"] for doc in relevant_docs],
                    "categories": [doc["category"] for doc in relevant_docs],
                    "goals": user_goals,
                }
                self.nutrition_db.cache_rag_context(
                    goal_hash=goal_hash,
                    context_result=cache_data,
                    ttl_hours=1,  # 1 hour TTL for goal context
                )
            except Exception as e:
                logger.warning(f"Failed to cache RAG context: {e}")

        # Format as context string
        context_parts = []
        for doc in relevant_docs:
            context_parts.append(f"[{doc['category'].upper()}] {doc['content']}")

        return "\n".join(context_parts)

    def _format_cached_context(
        self,
        cached_data: Dict[str, Any],
        food_description: str
    ) -> str:
        """
        Format cached RAG context into a context string.

        Args:
            cached_data: Cached context data with documents and categories
            food_description: Current food being analyzed (for reference)

        Returns:
            Formatted context string
        """
        documents = cached_data.get("documents", [])
        categories = cached_data.get("categories", [])

        if not documents:
            return ""

        context_parts = []
        for i, doc in enumerate(documents):
            category = categories[i] if i < len(categories) else "general"
            context_parts.append(f"[{category.upper()}] {doc}")

        return "\n".join(context_parts)

    def get_collection_count(self) -> int:
        """Get the number of documents in the nutrition knowledge collection."""
        return self.collection.count()


# Singleton instance
_nutrition_rag_service: Optional[NutritionRAGService] = None


def get_nutrition_rag_service() -> NutritionRAGService:
    """Get the global NutritionRAGService instance."""
    global _nutrition_rag_service
    if _nutrition_rag_service is None:
        _nutrition_rag_service = NutritionRAGService()
    return _nutrition_rag_service


# ============================================
# Nutrition Knowledge Data
# ============================================

NUTRITION_KNOWLEDGE_DATA = [
    # ─────────────────────────────────────────
    # MUSCLE BUILDING
    # ─────────────────────────────────────────
    {
        "content": "For muscle building, aim for 1.6-2.2g of protein per kg of body weight daily. Spread protein intake across 4-5 meals for optimal muscle protein synthesis.",
        "goals": ["build_muscle", "gain_muscle"],
        "category": "protein"
    },
    {
        "content": "High-quality protein sources for muscle building: chicken breast (31g/100g), eggs (13g/100g), Greek yogurt (10g/100g), salmon (25g/100g), lean beef (26g/100g).",
        "goals": ["build_muscle", "gain_muscle"],
        "category": "protein"
    },
    {
        "content": "Post-workout meal should contain 20-40g protein within 2 hours of training for optimal muscle recovery and growth.",
        "goals": ["build_muscle", "gain_muscle"],
        "category": "tips"
    },
    {
        "content": "Carbohydrates are important for muscle building as they fuel workouts and help with protein uptake. Aim for 3-5g/kg body weight.",
        "goals": ["build_muscle", "gain_muscle"],
        "category": "carbs"
    },
    {
        "content": "Complete proteins contain all 9 essential amino acids. Animal sources are complete; combine plant sources (rice + beans) for complete protein.",
        "goals": ["build_muscle", "gain_muscle", "general"],
        "category": "protein"
    },

    # ─────────────────────────────────────────
    # WEIGHT LOSS
    # ─────────────────────────────────────────
    {
        "content": "For weight loss, create a moderate calorie deficit of 300-500 calories daily. Larger deficits can lead to muscle loss and metabolic slowdown.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "calories"
    },
    {
        "content": "High fiber foods increase satiety and reduce overall calorie intake. Aim for 25-30g fiber daily from vegetables, fruits, and whole grains.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "fiber"
    },
    {
        "content": "Protein is crucial during weight loss to preserve muscle mass. Aim for 1.2-1.6g/kg body weight when cutting.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "protein"
    },
    {
        "content": "Low calorie-density foods for weight loss: leafy greens, cucumbers, tomatoes, berries, watermelon, broth-based soups.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "tips"
    },
    {
        "content": "Watch out for hidden calories in sauces, dressings, and cooking oils. A tablespoon of oil adds ~120 calories.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "warnings"
    },
    {
        "content": "Eating slowly and mindfully can reduce calorie intake by 10-15%. Take 20 minutes to finish a meal.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "tips"
    },

    # ─────────────────────────────────────────
    # ENDURANCE
    # ─────────────────────────────────────────
    {
        "content": "For endurance athletes, carbohydrates are the primary fuel. Aim for 5-7g/kg body weight on moderate training days, 7-10g/kg on heavy days.",
        "goals": ["improve_endurance", "endurance"],
        "category": "carbs"
    },
    {
        "content": "Complex carbs for sustained energy: oatmeal, brown rice, quinoa, sweet potatoes, whole grain bread. These provide slow-release energy.",
        "goals": ["improve_endurance", "endurance"],
        "category": "carbs"
    },
    {
        "content": "Pre-workout meal (2-3 hours before): focus on carbs with moderate protein, low fat and fiber to avoid GI distress.",
        "goals": ["improve_endurance", "endurance"],
        "category": "tips"
    },
    {
        "content": "Iron is crucial for endurance as it carries oxygen in blood. Good sources: lean red meat, spinach, lentils, fortified cereals.",
        "goals": ["improve_endurance", "endurance"],
        "category": "tips"
    },

    # ─────────────────────────────────────────
    # GENERAL HEALTH
    # ─────────────────────────────────────────
    {
        "content": "Balanced meals should include: 1/2 plate vegetables, 1/4 plate protein, 1/4 plate whole grains/starchy vegetables.",
        "goals": ["general_fitness", "stay_active", "maintain_weight", "general"],
        "category": "tips"
    },
    {
        "content": "Eat a variety of colorful vegetables to get different micronutrients. Each color provides different antioxidants and vitamins.",
        "goals": ["general_fitness", "stay_active", "general"],
        "category": "tips"
    },
    {
        "content": "Omega-3 fatty acids reduce inflammation and support heart health. Sources: fatty fish (salmon, mackerel), walnuts, flaxseeds, chia seeds.",
        "goals": ["general_fitness", "general"],
        "category": "fats"
    },

    # ─────────────────────────────────────────
    # WARNINGS (Apply to all goals)
    # ─────────────────────────────────────────
    {
        "content": "High sodium intake (>2300mg/day) increases blood pressure risk. Watch for: processed meats, canned soups, fast food, soy sauce.",
        "goals": ["general", "lose_weight", "build_muscle", "improve_endurance"],
        "category": "warnings"
    },
    {
        "content": "Added sugars should be limited to <25g/day for women, <36g/day for men. Check labels for: high fructose corn syrup, cane sugar, dextrose.",
        "goals": ["general", "lose_weight"],
        "category": "warnings"
    },
    {
        "content": "Ultra-processed foods are linked to weight gain and poor health outcomes. Minimize: chips, candy, sugary cereals, packaged snacks.",
        "goals": ["general", "lose_weight", "maintain_weight"],
        "category": "warnings"
    },
    {
        "content": "Trans fats should be completely avoided. Found in: fried foods, margarine, some baked goods. Check for 'partially hydrogenated oils'.",
        "goals": ["general", "lose_weight", "build_muscle"],
        "category": "warnings"
    },

    # ─────────────────────────────────────────
    # HEALTHY SWAPS
    # ─────────────────────────────────────────
    {
        "content": "Healthy swap: Replace white rice with cauliflower rice to reduce calories by 75% while adding fiber and vitamins.",
        "goals": ["lose_weight", "fat_loss"],
        "category": "swaps"
    },
    {
        "content": "Healthy swap: Choose Greek yogurt over regular yogurt for 2x the protein and fewer carbs.",
        "goals": ["build_muscle", "lose_weight", "general"],
        "category": "swaps"
    },
    {
        "content": "Healthy swap: Replace sugary sodas with sparkling water or unsweetened tea. A can of soda has ~40g sugar.",
        "goals": ["lose_weight", "general"],
        "category": "swaps"
    },
    {
        "content": "Healthy swap: Use avocado instead of mayo for sandwiches. Similar creaminess with healthy fats instead of processed oils.",
        "goals": ["general", "lose_weight"],
        "category": "swaps"
    },
    {
        "content": "Healthy swap: Choose whole grain bread over white bread for more fiber, B vitamins, and sustained energy.",
        "goals": ["general", "improve_endurance", "lose_weight"],
        "category": "swaps"
    },
]


async def seed_nutrition_knowledge():
    """Seed the nutrition knowledge collection with initial data."""
    service = get_nutrition_rag_service()

    # Check if already seeded
    if service.get_collection_count() > 0:
        print(f"⚠️ Nutrition knowledge collection already has {service.get_collection_count()} documents. Skipping seed.")
        return

    print(f"🌱 Seeding nutrition knowledge collection with {len(NUTRITION_KNOWLEDGE_DATA)} documents...")

    for item in NUTRITION_KNOWLEDGE_DATA:
        await service.add_knowledge(
            content=item["content"],
            goals=item["goals"],
            category=item["category"],
        )

    print(f"✅ Seeded nutrition knowledge collection with {service.get_collection_count()} documents")


# ============================================
# User Nutrition Profile Indexing
# ============================================

# Collection name for user nutrition profiles
USER_NUTRITION_PROFILES_COLLECTION = "user_nutrition_profiles"


class UserNutritionProfileService:
    """Service for managing user-specific nutrition metrics in ChromaDB."""

    def __init__(self):
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_or_create_collection(
            USER_NUTRITION_PROFILES_COLLECTION
        )

    def index_user_metrics(self, user_id: str, metrics: Dict[str, Any]) -> None:
        """
        Add or update user's calculated nutrition metrics to ChromaDB.

        Args:
            user_id: User's UUID
            metrics: Dictionary containing all nutrition metrics from calculation
        """
        # Build a natural language description for embedding
        document_text = self._build_nutrition_profile_document(metrics)

        # Metadata for filtering
        from datetime import datetime, timezone
        metadata = {
            "user_id": user_id,
            "type": "nutrition_profile",
            "calories": int(metrics.get('calories', 0)),
            "protein": int(metrics.get('protein', 0)),
            "carbs": int(metrics.get('carbs', 0)),
            "fat": int(metrics.get('fat', 0)),
            "bmr": int(metrics.get('bmr', 0)),
            "tdee": int(metrics.get('tdee', 0)),
            "metabolic_age": int(metrics.get('metabolic_age', 0)),
            "updated_at": datetime.now(timezone.utc).isoformat(),
        }

        doc_id = f"nutrition_profile_{user_id}"

        # Delete existing if present (upsert)
        try:
            self.collection.delete(ids=[doc_id])
        except Exception:
            pass  # Document may not exist

        # Add the updated profile
        self.collection.add(
            documents=[document_text],
            metadatas=[metadata],
            ids=[doc_id],
        )

        print(f"✅ Indexed nutrition profile to RAG for user {user_id}")

    def _build_nutrition_profile_document(self, metrics: Dict[str, Any]) -> str:
        """Build a natural language document for nutrition profile embedding."""
        parts = [
            "User Nutrition Profile:",
            f"- Daily Calorie Target: {metrics.get('calories', 0)} kcal",
            f"- Macros: {metrics.get('protein', 0)}g protein, {metrics.get('carbs', 0)}g carbs, {metrics.get('fat', 0)}g fat",
            f"- BMR: {metrics.get('bmr', 0)} kcal, TDEE: {metrics.get('tdee', 0)} kcal",
            f"- Metabolic Age: {metrics.get('metabolic_age', 0)} years",
            f"- Daily Water Goal: {metrics.get('water_liters', 0)}L",
            f"- Max Safe Deficit: {metrics.get('max_safe_deficit', 0)} kcal",
        ]

        # Body composition
        if metrics.get('lean_mass') and metrics.get('fat_mass'):
            parts.append(
                f"- Body Composition: {metrics['lean_mass']}kg lean, "
                f"{metrics['fat_mass']}kg fat ({metrics.get('body_fat_percent', 0)}% body fat)"
            )

        # Protein per kg
        if metrics.get('protein_per_kg'):
            parts.append(f"- Protein Target: {metrics['protein_per_kg']}g per kg body weight")

        # Ideal weight range
        if metrics.get('ideal_weight_min') and metrics.get('ideal_weight_max'):
            parts.append(
                f"- Ideal Weight Range: {metrics['ideal_weight_min']}-{metrics['ideal_weight_max']}kg"
            )

        # Goal timeline
        if metrics.get('weeks_to_goal'):
            goal_date = metrics.get('goal_date', 'TBD')
            parts.append(f"- Goal Date: {goal_date} (~{metrics['weeks_to_goal']} weeks)")

        return "\n".join(parts)

    def get_user_profile_context(self, user_id: str) -> Optional[str]:
        """
        Get user's nutrition profile from ChromaDB.

        Args:
            user_id: User's UUID

        Returns:
            Natural language nutrition context or None if not found
        """
        try:
            result = self.collection.get(
                ids=[f"nutrition_profile_{user_id}"],
                include=["documents"]
            )

            if result and result.get('documents') and len(result['documents']) > 0:
                return result['documents'][0]

            return None

        except Exception as e:
            print(f"⚠️ Could not retrieve nutrition profile for user {user_id}: {e}")
            return None

    def delete_user_profile(self, user_id: str) -> None:
        """
        Delete user's nutrition profile from ChromaDB.

        Args:
            user_id: User's UUID
        """
        try:
            self.collection.delete(ids=[f"nutrition_profile_{user_id}"])
            print(f"✅ Deleted nutrition profile from RAG for user {user_id}")
        except Exception as e:
            print(f"⚠️ Could not delete nutrition profile for user {user_id}: {e}")


# Singleton instance for user profiles
_user_nutrition_profile_service: Optional[UserNutritionProfileService] = None


def get_user_nutrition_profile_service() -> UserNutritionProfileService:
    """Get the global UserNutritionProfileService instance."""
    global _user_nutrition_profile_service
    if _user_nutrition_profile_service is None:
        _user_nutrition_profile_service = UserNutritionProfileService()
    return _user_nutrition_profile_service


async def index_user_nutrition_metrics(user_id: str, metrics: Dict[str, Any]) -> None:
    """
    Async helper to index user nutrition metrics to ChromaDB.

    This is the function imported and called from the API endpoint.
    """
    service = get_user_nutrition_profile_service()
    service.index_user_metrics(user_id, metrics)
