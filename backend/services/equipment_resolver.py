"""
Equipment resolution service - maps raw equipment strings to canonical names
and provides substitution intelligence.
"""

import asyncio
from typing import Dict, List, Optional, Tuple

from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


class EquipmentResolver:
    """
    Central equipment resolution utility.

    Resolves raw equipment strings to canonical names using the equipment_types
    table, and provides substitution intelligence via equipment_substitutions.
    Uses singleton pattern with lazy loading + in-memory caching.
    """

    _instance: Optional["EquipmentResolver"] = None
    _lock = asyncio.Lock()

    def __init__(self):
        self._alias_to_canonical: Dict[str, str] = {}  # alias -> canonical_name
        self._canonical_to_display: Dict[str, str] = {}  # canonical -> display_name
        self._canonical_to_category: Dict[str, str] = {}  # canonical -> category
        self._substitutions: Dict[str, List[Tuple[str, float]]] = {}  # canonical -> [(target, score)]
        self._loaded = False

    @classmethod
    async def get_instance(cls) -> "EquipmentResolver":
        """Get or create the singleton instance."""
        if cls._instance is None or not cls._instance._loaded:
            async with cls._lock:
                if cls._instance is None:
                    cls._instance = cls()
                if not cls._instance._loaded:
                    await cls._instance.load()
        return cls._instance

    async def load(self):
        """Load equipment_types + substitutions from Supabase, cache in memory."""
        try:
            supabase = get_supabase()

            # Load equipment types
            types_result = supabase.table("equipment_types").select(
                "canonical_name, display_name, category, aliases"
            ).execute()

            if types_result.data:
                for row in types_result.data:
                    canonical = row["canonical_name"]
                    display = row["display_name"]
                    aliases = row.get("aliases") or []

                    self._canonical_to_display[canonical] = display
                    self._canonical_to_category[canonical] = row.get("category", "")
                    self._alias_to_canonical[canonical] = canonical
                    self._alias_to_canonical[display.lower()] = canonical

                    for alias in aliases:
                        if alias:
                            self._alias_to_canonical[alias.lower()] = canonical

                logger.info(f"Loaded {len(types_result.data)} equipment types with {len(self._alias_to_canonical)} aliases")

            # Load substitutions
            subs_result = supabase.table("equipment_substitutions").select(
                "source_equipment, target_equipment, compatibility, bidirectional"
            ).execute()

            if subs_result.data:
                for row in subs_result.data:
                    source = row["source_equipment"]
                    target = row["target_equipment"]
                    compat = row["compatibility"]
                    bidirectional = row.get("bidirectional", True)

                    # Add forward direction
                    if source not in self._substitutions:
                        self._substitutions[source] = []
                    self._substitutions[source].append((target, compat))

                    # Add reverse direction if bidirectional
                    if bidirectional:
                        if target not in self._substitutions:
                            self._substitutions[target] = []
                        self._substitutions[target].append((source, compat))

                logger.info(f"Loaded {len(subs_result.data)} equipment substitution rules")

            self._loaded = True

        except Exception as e:
            logger.error(f"Failed to load equipment data: {e}")
            # Still mark as loaded to prevent retry loops - will use empty cache
            self._loaded = True

    def resolve(self, raw_equipment: str) -> Optional[str]:
        """
        Resolve any equipment string to its canonical name.

        Returns canonical_name or None if not found.
        """
        if not raw_equipment:
            return None

        key = raw_equipment.lower().strip()

        # Direct lookup
        if key in self._alias_to_canonical:
            return self._alias_to_canonical[key]

        # Partial match - check if any alias is contained in the raw string
        for alias, canonical in self._alias_to_canonical.items():
            if alias and len(alias) > 2 and alias in key:
                return canonical

        return None

    def get_display_name(self, canonical_name: str) -> str:
        """Get display name for a canonical equipment name."""
        return self._canonical_to_display.get(canonical_name, canonical_name)

    def get_category(self, equipment: str) -> Optional[str]:
        """Get equipment category (e.g., 'machines', 'free_weights') for any equipment string."""
        canonical = self.resolve(equipment)
        if not canonical:
            return None
        return self._canonical_to_category.get(canonical)

    def is_compatible(self, exercise_equipment: str, user_equipment: List[str]) -> bool:
        """
        Check if user can do an exercise based on their equipment.

        Checks direct match first, then substitution matrix.
        """
        if not exercise_equipment:
            return True

        ex_canonical = self.resolve(exercise_equipment)
        if not ex_canonical:
            # Unknown equipment - allow it (don't block on missing data)
            return True

        # Bodyweight is always compatible
        if ex_canonical == "bodyweight":
            return True

        # Check direct match with user's equipment
        user_canonical = set()
        for eq in user_equipment:
            resolved = self.resolve(eq)
            if resolved:
                user_canonical.add(resolved)
            else:
                user_canonical.add(eq.lower().strip())

        # Always include bodyweight
        user_canonical.add("bodyweight")

        if ex_canonical in user_canonical:
            return True

        # Check substitution matrix
        if ex_canonical in self._substitutions:
            for target, compat in self._substitutions[ex_canonical]:
                if target in user_canonical and compat >= 0.5:
                    return True

        return False

    def get_substitutes(self, equipment: str) -> List[Tuple[str, float]]:
        """
        Get substitutable equipment sorted by compatibility score (descending).
        """
        canonical = self.resolve(equipment)
        if not canonical or canonical not in self._substitutions:
            return []

        subs = self._substitutions[canonical]
        return sorted(subs, key=lambda x: x[1], reverse=True)
