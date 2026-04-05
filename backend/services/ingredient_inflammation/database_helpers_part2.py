"""Second part of database_helpers.py (auto-split for size)."""
from typing import Dict, Optional


class IngredientRecordPart2:
    """Second half of IngredientRecord methods. Use as mixin."""

def _build_alias_index() -> None:
    """Build reverse index from all aliases to their IngredientRecord."""
    for name, record in INGREDIENT_DATABASE.items():
        key = name.lower().strip()
        _ALIAS_INDEX[key] = record
        for alias in record.aliases:
            alias_key = alias.lower().strip()
            if alias_key not in _ALIAS_INDEX:
                _ALIAS_INDEX[alias_key] = record


_build_alias_index()


def get_by_name(name: str) -> Optional[IngredientRecord]:
    """Look up an ingredient by exact name or alias. O(1)."""
    return _ALIAS_INDEX.get(name.lower().strip())


def get_alias_index() -> Dict[str, IngredientRecord]:
    """Return the alias index for substring/fuzzy matching."""
    return _ALIAS_INDEX
