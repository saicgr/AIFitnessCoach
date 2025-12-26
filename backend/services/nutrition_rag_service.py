"""
Nutrition RAG Service - Goal-specific nutrition knowledge retrieval.

This service provides contextual nutrition knowledge based on user's fitness goals.
Used to enhance food scoring with relevant nutrition facts and recommendations.

Uses ChromaDB for vector similarity search.
"""
from typing import List, Dict, Any, Optional
import uuid
from core.chroma_cloud import get_chroma_cloud_client
from services.gemini_service import GeminiService


# Collection name for nutrition knowledge
NUTRITION_COLLECTION_NAME = "nutrition_knowledge"


class NutritionRAGService:
    """
    RAG service for nutrition knowledge retrieval.

    Stores goal-specific nutrition facts and retrieves relevant context
    based on user goals and food items being analyzed.
    """

    def __init__(self, gemini_service: Optional[GeminiService] = None):
        self.gemini_service = gemini_service or GeminiService()
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_or_create_collection(NUTRITION_COLLECTION_NAME)
        print(f"✅ NutritionRAG initialized with {self.collection.count()} documents")

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
    ) -> str:
        """
        Get relevant nutrition context based on food and user goals.

        Args:
            food_description: The food being analyzed
            user_goals: User's fitness goals
            n_results: Number of results to retrieve

        Returns:
            Formatted context string for Gemini prompt
        """
        if not user_goals:
            return ""

        # Create query combining food and goals
        query = f"Food: {food_description}. Goals: {', '.join(user_goals)}"

        # Get embedding for query
        query_embedding = await self.gemini_service.get_embedding_async(query)

        # Build filter for goals - match any of the user's goals
        # ChromaDB where clause for matching any goal
        where_filter = None
        if user_goals:
            # We'll use $contains for substring matching since goals are stored as comma-separated
            # Actually, ChromaDB doesn't support $contains well, so we'll retrieve more and filter
            pass

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

        # Format as context string
        context_parts = []
        for doc in relevant_docs:
            context_parts.append(f"[{doc['category'].upper()}] {doc['content']}")

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
