"""
Food text parsing utilities.

Contains the ParsedFoodItem dataclass and unit conversion helpers
used to extract structured food data from natural-language descriptions.
"""
from dataclasses import dataclass
from typing import Optional


@dataclass
class ParsedFoodItem:
    """A single parsed food item extracted from a natural-language description."""
    food_name: str          # Cleaned name for DB lookup
    quantity: float = 1.0   # Count (pieces/servings)
    weight_g: float = None  # Explicit weight in grams (e.g., "300g haleem")
    volume_ml: float = None # Explicit volume (converted to weight_g using 1ml~1g)
    unit: str = None        # "plate", "bowl", "glass", "slice", "cup", etc.
    raw_text: str = ""      # Original text before parsing


def _weight_unit_to_grams(value: float, unit: str) -> float:
    """Convert a weight value+unit to grams."""
    u = unit.lower().rstrip('s')
    if u in ('g', 'gm', 'gram'):
        return value
    if u in ('kg', 'kilo', 'kilogram'):
        return value * 1000
    if u in ('oz', 'ounce'):
        return value * 28.35
    return value


def _volume_unit_to_ml(value: float, unit: str) -> float:
    """Convert a volume value+unit to milliliters."""
    u = unit.lower().replace(' ', '')
    if u in ('ml', 'milliliter', 'milliliters', 'millilitres'):
        return value
    if u in ('l', 'liter', 'litre', 'liters', 'litres'):
        return value * 1000
    if u in ('floz', 'fluidoz'):
        return value * 29.57
    return value
