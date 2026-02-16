"""
Food name normalization for deduplication and search.
"""

from __future__ import annotations

import re
import unicodedata


SOURCE_PRIORITY = {"usda": 1, "usda_branded": 2, "cnf": 3, "indb": 4, "openfoodfacts": 5}


GENERIC_BRANDS = {
    "", "not a branded item", "none", "n/a", "unknown", "generic", "unbranded",
}


def normalize_food_name(name: str, brand: str | None = None) -> str:
    """Normalize for deduplication.

    Steps: NFKD unicode -> lowercase -> remove parenthesised text ->
    remove punctuation -> sort words alphabetically -> collapse spaces.
    If a real brand is provided, prepend it so different brands stay separate.

    "Chicken, breast, cooked, grilled" -> "breast chicken cooked grilled"
    brand="Nestle", name="Chocolate Milk" -> "nestle::chocolate milk"
    """
    if not name:
        return ""
    # Unicode normalize
    name = unicodedata.normalize("NFKD", name)
    name = name.lower()
    # Remove anything inside parentheses (including the parens)
    name = re.sub(r"\([^)]*\)", "", name)
    # Remove punctuation (keep letters, digits, spaces)
    name = re.sub(r"[^a-z0-9\s]", " ", name)
    # Split, sort alphabetically, rejoin
    words = sorted(name.split())
    key = " ".join(words)

    # Prepend brand for branded items so different brands stay separate
    if brand and str(brand).strip():
        brand_norm = unicodedata.normalize("NFKD", str(brand)).lower().strip()
        brand_norm = re.sub(r"[^a-z0-9\s]", " ", brand_norm)
        brand_norm = " ".join(brand_norm.split())
        if brand_norm and brand_norm not in GENERIC_BRANDS:
            key = f"{brand_norm}::{key}"

    return key


def normalize_food_name_display(name: str) -> str:
    """Normalize for display/search.

    Preserves word order: lowercase, strip, collapse whitespace.
    """
    if not name:
        return ""
    name = unicodedata.normalize("NFKD", name)
    name = name.lower().strip()
    name = re.sub(r"\s+", " ", name)
    return name
