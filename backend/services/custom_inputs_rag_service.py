"""
Custom Inputs RAG Service - Index and retrieve custom focus areas and injuries.

This service:
1. Indexes custom user inputs (focus areas, injuries) from Supabase to ChromaDB
2. Provides semantic search to find similar custom inputs
3. Helps suggest popular custom inputs to users
4. Enables AI to understand user-specific terminology
"""
from typing import List, Dict, Any, Optional
import json
import hashlib

from core.chroma_cloud import get_chroma_cloud_client
from core.supabase_db import get_supabase_db
from core.logger import get_logger
from services.openai_service import OpenAIService

logger = get_logger(__name__)


class CustomInputsRAGService:
    """
    RAG-based service for custom workout inputs (focus areas, injuries).

    Enables:
    - Semantic search for similar custom inputs
    - Aggregation of popular custom inputs across users
    - AI-powered normalization of custom inputs
    """

    def __init__(self, openai_service: OpenAIService):
        self.openai_service = openai_service
        self.db = get_supabase_db()

        # Get Chroma Cloud client
        self.chroma_client = get_chroma_cloud_client()
        self.collection = self.chroma_client.get_custom_inputs_collection()

        logger.info(f"CustomInputsRAG initialized with {self.collection.count()} custom inputs")

    async def index_custom_input(
        self,
        input_type: str,  # 'focus_area' or 'injury'
        input_value: str,
        user_id: Optional[str] = None,
        normalized_value: Optional[str] = None,
    ) -> bool:
        """
        Index a single custom input to ChromaDB.

        Args:
            input_type: Type of input ('focus_area' or 'injury')
            input_value: The custom input text
            user_id: Optional user ID for tracking
            normalized_value: Optional AI-normalized version

        Returns:
            True if indexed successfully
        """
        try:
            # Create unique ID based on type and value
            doc_id = f"{input_type}_{hashlib.md5(input_value.lower().encode()).hexdigest()[:12]}"

            # Build rich text for embedding
            text = self._build_input_text(input_type, input_value, normalized_value)

            # Get embedding
            embedding = await self.openai_service.get_embedding(text)

            # Prepare metadata
            metadata = {
                "input_type": input_type,
                "input_value": input_value,
                "normalized_value": normalized_value or "",
                "user_id": user_id or "",
            }

            # Upsert to collection
            try:
                self.collection.delete(ids=[doc_id])
            except Exception:
                pass

            self.collection.add(
                ids=[doc_id],
                embeddings=[embedding],
                documents=[text],
                metadatas=[metadata],
            )

            logger.info(f"Indexed custom {input_type}: {input_value}")
            return True

        except Exception as e:
            logger.error(f"Failed to index custom input: {e}")
            return False

    async def index_all_custom_inputs(self, batch_size: int = 50) -> int:
        """
        Index all custom inputs from Supabase to ChromaDB.

        Returns:
            Number of inputs indexed
        """
        logger.info("Starting custom inputs indexing from Supabase...")

        try:
            # Fetch all custom inputs from Supabase
            result = self.db.client.table("custom_workout_inputs").select("*").execute()

            if not result.data:
                logger.info("No custom inputs found in database")
                return 0

            inputs = result.data
            logger.info(f"Found {len(inputs)} custom inputs to index")

            indexed_count = 0

            # Process in batches
            for i in range(0, len(inputs), batch_size):
                batch = inputs[i:i + batch_size]

                ids = []
                documents = []
                metadatas = []

                for inp in batch:
                    input_type = inp.get("input_type", "")
                    input_value = inp.get("input_value", "")
                    normalized_value = inp.get("normalized_value", "")
                    user_id = inp.get("user_id", "")

                    if not input_type or not input_value:
                        continue

                    # Create unique ID
                    doc_id = f"{input_type}_{hashlib.md5(input_value.lower().encode()).hexdigest()[:12]}"

                    # Build text for embedding
                    text = self._build_input_text(input_type, input_value, normalized_value)

                    ids.append(doc_id)
                    documents.append(text)
                    metadatas.append({
                        "input_type": input_type,
                        "input_value": input_value,
                        "normalized_value": normalized_value or "",
                        "user_id": user_id or "",
                        "usage_count": str(inp.get("usage_count", 1)),
                    })

                if not documents:
                    continue

                # Get batch embeddings
                try:
                    embeddings = await self.openai_service.get_embeddings_batch(documents)
                except Exception as e:
                    logger.error(f"Failed to get embeddings for batch: {e}")
                    continue

                # Upsert to collection
                try:
                    # Delete existing to avoid duplicates
                    try:
                        self.collection.delete(ids=ids)
                    except Exception:
                        pass

                    self.collection.add(
                        ids=ids,
                        embeddings=embeddings,
                        documents=documents,
                        metadatas=metadatas,
                    )
                    indexed_count += len(ids)
                except Exception as e:
                    logger.error(f"Failed to add batch to Chroma: {e}")

            logger.info(f"Indexed {indexed_count} custom inputs to ChromaDB")
            return indexed_count

        except Exception as e:
            logger.error(f"Failed to index custom inputs: {e}")
            return 0

    def _build_input_text(
        self,
        input_type: str,
        input_value: str,
        normalized_value: Optional[str] = None
    ) -> str:
        """Build text representation for embedding."""
        parts = []

        if input_type == "focus_area":
            parts.append(f"Focus Area: {input_value}")
            parts.append("Type: Custom workout focus area or muscle group target")
            if normalized_value:
                parts.append(f"Also known as: {normalized_value}")
            # Add context for better semantic matching
            parts.append("Related to: workout target, muscle group, body part, exercise focus")
        elif input_type == "injury":
            parts.append(f"Injury/Condition: {input_value}")
            parts.append("Type: Physical limitation or injury to avoid during workouts")
            if normalized_value:
                parts.append(f"Also known as: {normalized_value}")
            # Add context for better semantic matching
            parts.append("Related to: physical limitation, pain area, injury avoidance, safety concern")
        else:
            parts.append(f"Custom Input: {input_value}")
            parts.append(f"Type: {input_type}")

        return "\n".join(parts)

    async def find_similar_inputs(
        self,
        query: str,
        input_type: Optional[str] = None,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Find similar custom inputs using semantic search.

        Args:
            query: Search query text
            input_type: Optional filter by type ('focus_area' or 'injury')
            limit: Maximum results to return

        Returns:
            List of similar custom inputs with metadata
        """
        try:
            # Get embedding for query
            query_embedding = await self.openai_service.get_embedding(query)

            # Build where filter if type specified
            where_filter = None
            if input_type:
                where_filter = {"input_type": input_type}

            # Query collection
            results = self.collection.query(
                query_embeddings=[query_embedding],
                n_results=limit,
                where=where_filter,
                include=["metadatas", "distances"],
            )

            if not results["ids"][0]:
                return []

            # Format results
            similar_inputs = []
            for i, doc_id in enumerate(results["ids"][0]):
                meta = results["metadatas"][0][i]
                distance = results["distances"][0][i]
                similarity = 1 / (1 + distance)

                similar_inputs.append({
                    "input_type": meta.get("input_type", ""),
                    "input_value": meta.get("input_value", ""),
                    "normalized_value": meta.get("normalized_value", ""),
                    "usage_count": int(meta.get("usage_count", "1")),
                    "similarity": similarity,
                })

            return similar_inputs

        except Exception as e:
            logger.error(f"Failed to find similar inputs: {e}")
            return []

    async def normalize_custom_input(
        self,
        input_type: str,
        input_value: str,
    ) -> Optional[str]:
        """
        Use AI to normalize a custom input to a standard form.

        This helps group similar inputs like:
        - "bad knee" -> "knee_injury"
        - "rotator cuff issues" -> "shoulder_injury"
        - "want bigger arms" -> "arm_hypertrophy"

        Args:
            input_type: Type of input ('focus_area' or 'injury')
            input_value: The custom input text

        Returns:
            Normalized string or None if failed
        """
        try:
            if input_type == "focus_area":
                prompt = f"""Normalize this custom workout focus area to a standard form.

Custom input: "{input_value}"

Standard focus area categories:
- upper_body, lower_body, full_body, core
- chest, back, shoulders, arms, biceps, triceps
- legs, quads, hamstrings, glutes, calves
- cardio, flexibility, mobility, balance, power

Return ONLY the normalized category (lowercase, underscores instead of spaces).
If it doesn't fit any category, create a simple 1-3 word normalized form."""
            else:  # injury
                prompt = f"""Normalize this custom injury/condition to a standard form.

Custom input: "{input_value}"

Standard injury categories:
- shoulder_injury, knee_injury, back_injury, wrist_injury
- hip_injury, ankle_injury, neck_injury, elbow_injury
- lower_back_pain, upper_back_pain, joint_pain
- muscle_strain, tendonitis, arthritis

Return ONLY the normalized category (lowercase, underscores instead of spaces).
If it doesn't fit any category, create a simple 1-3 word normalized form."""

            response = await self.openai_service.client.chat.completions.create(
                model="gpt-4-turbo",
                messages=[
                    {
                        "role": "system",
                        "content": "You are a fitness terminology normalizer. Return ONLY the normalized term, nothing else."
                    },
                    {"role": "user", "content": prompt}
                ],
                temperature=0.1,
                max_tokens=50,
            )

            normalized = response.choices[0].message.content.strip().lower()
            # Clean up
            normalized = normalized.replace(" ", "_").replace("-", "_")
            return normalized

        except Exception as e:
            logger.error(f"Failed to normalize custom input: {e}")
            return None

    async def get_popular_suggestions(
        self,
        input_type: str,
        limit: int = 10,
    ) -> List[Dict[str, Any]]:
        """
        Get popular custom inputs for suggestions.

        Fetches from Supabase view and returns most commonly used custom inputs.

        Args:
            input_type: Type of input ('focus_area' or 'injury')
            limit: Maximum suggestions to return

        Returns:
            List of popular custom inputs
        """
        try:
            result = self.db.client.table("popular_custom_inputs").select("*").eq(
                "input_type", input_type
            ).order("total_uses", desc=True).limit(limit).execute()

            return result.data or []

        except Exception as e:
            logger.error(f"Failed to get popular suggestions: {e}")
            return []

    def get_stats(self) -> Dict[str, Any]:
        """Get custom inputs RAG statistics."""
        return {
            "total_indexed": self.collection.count(),
            "storage": "chroma_cloud",
        }


# Singleton instance
_custom_inputs_rag_service: Optional[CustomInputsRAGService] = None


def get_custom_inputs_rag_service() -> CustomInputsRAGService:
    """Get the global CustomInputsRAGService instance."""
    global _custom_inputs_rag_service
    if _custom_inputs_rag_service is None:
        openai_service = OpenAIService()
        _custom_inputs_rag_service = CustomInputsRAGService(openai_service)
    return _custom_inputs_rag_service
