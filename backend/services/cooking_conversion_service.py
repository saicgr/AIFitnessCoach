"""Cooking Conversion Service - Convert between raw and cooked food weights."""

from dataclasses import dataclass
from typing import Optional, Dict, Any, List
from enum import Enum
from core.logger import get_logger

logger = get_logger(__name__)


class FoodCategory(str, Enum):
    GRAINS = "grains"
    LEGUMES = "legumes"
    MEATS = "meats"
    POULTRY = "poultry"
    SEAFOOD = "seafood"
    VEGETABLES = "vegetables"
    EGGS = "eggs"


class CookingMethod(str, Enum):
    BOILING = "boiling"
    STEAMING = "steaming"
    GRILLING = "grilling"
    PAN_FRYING = "pan_frying"
    DEEP_FRYING = "deep_frying"
    BAKING = "baking"
    ROASTING = "roasting"
    POACHING = "poaching"
    SAUTEING = "sauteing"
    RAW = "raw"


@dataclass
class CookingConversionFactor:
    food_name: str
    food_category: FoodCategory
    raw_to_cooked_ratio: float
    cooking_method: CookingMethod
    calories_retention: float = 1.0
    protein_retention: float = 1.0
    carbs_retention: float = 1.0
    fat_change: float = 1.0
    notes: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "food_name": self.food_name,
            "food_category": self.food_category.value,
            "raw_to_cooked_ratio": self.raw_to_cooked_ratio,
            "cooking_method": self.cooking_method.value,
            "calories_retention": self.calories_retention,
            "protein_retention": self.protein_retention,
            "carbs_retention": self.carbs_retention,
            "fat_change": self.fat_change,
            "notes": self.notes,
        }


@dataclass
class WeightConversionResult:
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

    def to_dict(self) -> Dict[str, Any]:
        return {
            "original_weight_g": round(self.original_weight_g, 1),
            "original_state": self.original_state,
            "converted_weight_g": round(self.converted_weight_g, 1),
            "converted_state": self.converted_state,
            "food_name": self.food_name,
            "cooking_method": self.cooking_method,
            "raw_to_cooked_ratio": self.raw_to_cooked_ratio,
            "adjusted_calories_per_100g": round(self.adjusted_calories_per_100g, 1) if self.adjusted_calories_per_100g else None,
            "adjusted_protein_per_100g": round(self.adjusted_protein_per_100g, 1) if self.adjusted_protein_per_100g else None,
            "adjusted_carbs_per_100g": round(self.adjusted_carbs_per_100g, 1) if self.adjusted_carbs_per_100g else None,
            "adjusted_fat_per_100g": round(self.adjusted_fat_per_100g, 1) if self.adjusted_fat_per_100g else None,
            "notes": self.notes,
        }


DEFAULT_CONVERSION_FACTORS: List[CookingConversionFactor] = [
    # GRAINS - absorb water and increase in weight
    CookingConversionFactor("white_rice", FoodCategory.GRAINS, 2.5, CookingMethod.BOILING, notes="White rice absorbs about 2.5x its weight"),
    CookingConversionFactor("brown_rice", FoodCategory.GRAINS, 2.4, CookingMethod.BOILING, notes="Brown rice absorbs slightly less"),
    CookingConversionFactor("basmati_rice", FoodCategory.GRAINS, 2.8, CookingMethod.BOILING, notes="Basmati elongates and absorbs more"),
    CookingConversionFactor("pasta", FoodCategory.GRAINS, 2.0, CookingMethod.BOILING, notes="Pasta doubles in weight"),
    CookingConversionFactor("spaghetti", FoodCategory.GRAINS, 2.2, CookingMethod.BOILING, notes="Long pasta absorbs more"),
    CookingConversionFactor("penne", FoodCategory.GRAINS, 2.0, CookingMethod.BOILING, notes="Tube pasta standard"),
    CookingConversionFactor("oats", FoodCategory.GRAINS, 2.5, CookingMethod.BOILING, notes="Rolled oats absorb significant water"),
    CookingConversionFactor("steel_cut_oats", FoodCategory.GRAINS, 3.0, CookingMethod.BOILING, notes="Steel cut absorbs more"),
    CookingConversionFactor("quinoa", FoodCategory.GRAINS, 2.6, CookingMethod.BOILING, notes="Quinoa expands significantly"),
    CookingConversionFactor("couscous", FoodCategory.GRAINS, 2.5, CookingMethod.STEAMING, notes="Couscous absorbs water"),
    CookingConversionFactor("bulgur", FoodCategory.GRAINS, 2.8, CookingMethod.BOILING, notes="Bulgur absorbs considerable water"),
    CookingConversionFactor("barley", FoodCategory.GRAINS, 3.0, CookingMethod.BOILING, notes="Barley absorbs 3x weight"),
    CookingConversionFactor("farro", FoodCategory.GRAINS, 2.5, CookingMethod.BOILING, notes="Farro expands moderately"),
    # LEGUMES - absorb significant water
    CookingConversionFactor("lentils", FoodCategory.LEGUMES, 2.5, CookingMethod.BOILING, notes="Lentils absorb 2.5x"),
    CookingConversionFactor("red_lentils", FoodCategory.LEGUMES, 2.3, CookingMethod.BOILING, notes="Red lentils break down more"),
    CookingConversionFactor("chickpeas", FoodCategory.LEGUMES, 2.0, CookingMethod.BOILING, notes="Chickpeas double"),
    CookingConversionFactor("black_beans", FoodCategory.LEGUMES, 2.2, CookingMethod.BOILING, notes="Black beans absorb 2.2x"),
    CookingConversionFactor("kidney_beans", FoodCategory.LEGUMES, 2.2, CookingMethod.BOILING, notes="Kidney beans absorb 2.2x"),
    CookingConversionFactor("pinto_beans", FoodCategory.LEGUMES, 2.3, CookingMethod.BOILING, notes="Pinto beans absorb 2.3x"),
    CookingConversionFactor("split_peas", FoodCategory.LEGUMES, 2.5, CookingMethod.BOILING, notes="Split peas absorb significant water"),
    CookingConversionFactor("mung_beans", FoodCategory.LEGUMES, 2.4, CookingMethod.BOILING, notes="Mung beans expand considerably"),
    # POULTRY - lose moisture when cooked
    CookingConversionFactor("chicken_breast", FoodCategory.POULTRY, 0.75, CookingMethod.GRILLING, protein_retention=1.0, notes="Loses 25 percent when grilled"),
    CookingConversionFactor("chicken_breast", FoodCategory.POULTRY, 0.80, CookingMethod.POACHING, protein_retention=1.0, notes="Poaching retains more moisture"),
    CookingConversionFactor("chicken_breast", FoodCategory.POULTRY, 0.70, CookingMethod.BAKING, protein_retention=1.0, notes="Baking causes more loss"),
    CookingConversionFactor("chicken_thigh", FoodCategory.POULTRY, 0.70, CookingMethod.GRILLING, fat_change=0.9, notes="Thighs lose fat and moisture"),
    CookingConversionFactor("turkey_breast", FoodCategory.POULTRY, 0.72, CookingMethod.ROASTING, protein_retention=1.0, notes="Loses about 28 percent"),
    # MEATS - lose moisture, fat may render
    CookingConversionFactor("beef_steak", FoodCategory.MEATS, 0.75, CookingMethod.GRILLING, fat_change=0.85, notes="Loses 25 percent"),
    CookingConversionFactor("beef_ground", FoodCategory.MEATS, 0.70, CookingMethod.PAN_FRYING, fat_change=0.75, notes="Loses 30 percent"),
    CookingConversionFactor("beef_ground_lean", FoodCategory.MEATS, 0.75, CookingMethod.PAN_FRYING, fat_change=0.85, notes="Lean retains more"),
    CookingConversionFactor("pork_chop", FoodCategory.MEATS, 0.72, CookingMethod.GRILLING, fat_change=0.9, notes="Loses 28 percent"),
    CookingConversionFactor("pork_tenderloin", FoodCategory.MEATS, 0.75, CookingMethod.ROASTING, notes="Lean cut retains more"),
    CookingConversionFactor("lamb_chop", FoodCategory.MEATS, 0.68, CookingMethod.GRILLING, fat_change=0.80, notes="Lamb loses significant fat"),
    CookingConversionFactor("bacon", FoodCategory.MEATS, 0.35, CookingMethod.PAN_FRYING, fat_change=0.50, notes="Loses 65 percent"),
    # SEAFOOD
    CookingConversionFactor("salmon", FoodCategory.SEAFOOD, 0.80, CookingMethod.BAKING, fat_change=0.95, notes="Retains fat"),
    CookingConversionFactor("salmon", FoodCategory.SEAFOOD, 0.85, CookingMethod.POACHING, notes="Poaching preserves moisture"),
    CookingConversionFactor("tilapia", FoodCategory.SEAFOOD, 0.78, CookingMethod.BAKING, notes="Lean fish loses more"),
    CookingConversionFactor("shrimp", FoodCategory.SEAFOOD, 0.75, CookingMethod.BOILING, notes="Shrimp shrink"),
    CookingConversionFactor("tuna", FoodCategory.SEAFOOD, 0.82, CookingMethod.GRILLING, notes="Tuna retains moisture"),
    CookingConversionFactor("cod", FoodCategory.SEAFOOD, 0.75, CookingMethod.BAKING, notes="Cod loses 25 percent"),
    # VEGETABLES - varies widely
    CookingConversionFactor("broccoli", FoodCategory.VEGETABLES, 0.90, CookingMethod.STEAMING, notes="Loses minimal weight"),
    CookingConversionFactor("spinach", FoodCategory.VEGETABLES, 0.10, CookingMethod.SAUTEING, notes="Wilts 90 percent"),
    CookingConversionFactor("mushrooms", FoodCategory.VEGETABLES, 0.50, CookingMethod.SAUTEING, notes="Releases significant moisture"),
    CookingConversionFactor("zucchini", FoodCategory.VEGETABLES, 0.70, CookingMethod.GRILLING, notes="Loses moisture"),
    CookingConversionFactor("carrots", FoodCategory.VEGETABLES, 0.90, CookingMethod.BOILING, notes="Retains most weight"),
    CookingConversionFactor("potatoes", FoodCategory.VEGETABLES, 0.95, CookingMethod.BOILING, notes="Retains well boiled"),
    CookingConversionFactor("potatoes", FoodCategory.VEGETABLES, 0.75, CookingMethod.BAKING, notes="Baked lose more"),
    CookingConversionFactor("sweet_potato", FoodCategory.VEGETABLES, 0.92, CookingMethod.BOILING, notes="Retains well"),
    CookingConversionFactor("asparagus", FoodCategory.VEGETABLES, 0.85, CookingMethod.GRILLING, notes="Loses some moisture"),
    CookingConversionFactor("bell_pepper", FoodCategory.VEGETABLES, 0.75, CookingMethod.ROASTING, notes="Roasted lose moisture"),
    CookingConversionFactor("onion", FoodCategory.VEGETABLES, 0.60, CookingMethod.SAUTEING, notes="Caramelize and lose moisture"),
    CookingConversionFactor("cabbage", FoodCategory.VEGETABLES, 0.70, CookingMethod.BOILING, notes="Wilts and loses volume"),
    CookingConversionFactor("kale", FoodCategory.VEGETABLES, 0.20, CookingMethod.SAUTEING, notes="Wilts dramatically"),
    # EGGS
    CookingConversionFactor("egg_whole", FoodCategory.EGGS, 0.90, CookingMethod.BOILING, notes="Minimal weight loss"),
    CookingConversionFactor("egg_whole", FoodCategory.EGGS, 0.85, CookingMethod.PAN_FRYING, fat_change=1.15, notes="With added oil"),
    CookingConversionFactor("egg_white", FoodCategory.EGGS, 0.88, CookingMethod.BOILING, notes="Slight moisture loss"),
]

_CONVERSION_BY_NAME: Dict[str, List[CookingConversionFactor]] = {}
_CONVERSION_BY_CATEGORY: Dict[FoodCategory, List[CookingConversionFactor]] = {}

for factor in DEFAULT_CONVERSION_FACTORS:
    if factor.food_name not in _CONVERSION_BY_NAME:
        _CONVERSION_BY_NAME[factor.food_name] = []
    _CONVERSION_BY_NAME[factor.food_name].append(factor)
    if factor.food_category not in _CONVERSION_BY_CATEGORY:
        _CONVERSION_BY_CATEGORY[factor.food_category] = []
    _CONVERSION_BY_CATEGORY[factor.food_category].append(factor)


class CookingConversionService:
    """Service for converting between raw and cooked food weights."""

    def __init__(self):
        self.conversion_factors = DEFAULT_CONVERSION_FACTORS
        self._by_name = _CONVERSION_BY_NAME.copy()
        self._by_category = _CONVERSION_BY_CATEGORY.copy()

    def get_all_conversions(self) -> List[Dict[str, Any]]:
        """Get all available conversion factors."""
        return [f.to_dict() for f in self.conversion_factors]

    def get_conversions_by_category(self, category: str) -> List[Dict[str, Any]]:
        """Get conversion factors for a specific food category."""
        try:
            cat = FoodCategory(category.lower())
            return [f.to_dict() for f in self._by_category.get(cat, [])]
        except ValueError:
            logger.warning(f"Unknown food category: {category}")
            return []

    def get_conversion_factor(
        self, food_name: str, cooking_method: Optional[str] = None
    ) -> Optional[CookingConversionFactor]:
        """Get the conversion factor for a specific food and cooking method."""
        normalized = food_name.lower().replace(" ", "_").replace("-", "_")
        factors = self._by_name.get(normalized, [])
        if not factors:
            for name in self._by_name:
                if normalized in name or name in normalized:
                    factors = self._by_name[name]
                    break
        if not factors:
            return None
        if cooking_method:
            try:
                method = CookingMethod(cooking_method.lower())
                for f in factors:
                    if f.cooking_method == method:
                        return f
            except ValueError:
                logger.warning(f"Unknown cooking method: {cooking_method}")
        return factors[0]

    def convert_weight(
        self,
        weight_g: float,
        food_name: str,
        from_state: str,
        cooking_method: Optional[str] = None,
        nutrients_per_100g: Optional[Dict[str, float]] = None,
    ) -> Optional[WeightConversionResult]:
        """Convert weight between raw and cooked states."""
        from_state = from_state.lower()
        if from_state not in ("raw", "cooked"):
            logger.error(f"Invalid from_state: {from_state}")
            return None
        factor = self.get_conversion_factor(food_name, cooking_method)
        if not factor:
            logger.warning(f"No conversion factor found for: {food_name}")
            return None
        ratio = factor.raw_to_cooked_ratio
        if from_state == "raw":
            converted_weight = weight_g * ratio
            to_state = "cooked"
        else:
            converted_weight = weight_g / ratio
            to_state = "raw"
        adj_cal = adj_prot = adj_carbs = adj_fat = None
        if nutrients_per_100g:
            cal = nutrients_per_100g.get("calories", 0)
            prot = nutrients_per_100g.get("protein", 0)
            carbs = nutrients_per_100g.get("carbs", 0)
            fat = nutrients_per_100g.get("fat", 0)
            if from_state == "raw":
                adj_cal = (cal * factor.calories_retention) / ratio
                adj_prot = (prot * factor.protein_retention) / ratio
                adj_carbs = (carbs * factor.carbs_retention) / ratio
                adj_fat = (fat * factor.fat_change) / ratio
            else:
                adj_cal = cal * ratio / factor.calories_retention
                adj_prot = prot * ratio / factor.protein_retention
                adj_carbs = carbs * ratio / factor.carbs_retention
                adj_fat = fat * ratio / factor.fat_change
        return WeightConversionResult(
            weight_g,
            from_state,
            converted_weight,
            to_state,
            factor.food_name,
            factor.cooking_method.value,
            ratio,
            adj_cal,
            adj_prot,
            adj_carbs,
            adj_fat,
            factor.notes,
        )

    def get_available_foods(self) -> List[str]:
        """Get list of all foods with conversion factors."""
        return list(self._by_name.keys())

    def get_available_categories(self) -> List[str]:
        """Get list of all food categories."""
        return [cat.value for cat in FoodCategory]

    def get_cooking_methods(self) -> List[str]:
        """Get list of all cooking methods."""
        return [method.value for method in CookingMethod]

    def search_foods(self, query: str) -> List[Dict[str, Any]]:
        """Search for foods matching a query."""
        query = query.lower().replace(" ", "_")
        results = []
        for name, factors in self._by_name.items():
            if query in name or name in query:
                results.extend([f.to_dict() for f in factors])
        return results


_cooking_conversion_service: Optional[CookingConversionService] = None


def get_cooking_conversion_service() -> CookingConversionService:
    """Get the singleton CookingConversionService instance."""
    global _cooking_conversion_service
    if _cooking_conversion_service is None:
        _cooking_conversion_service = CookingConversionService()
    return _cooking_conversion_service
