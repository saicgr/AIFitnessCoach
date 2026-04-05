"""
Curated ingredient inflammation database (~400 entries).

Each entry maps an ingredient name to its inflammation score (1-10),
category, reason, additive status, and aliases.

Score convention:
  1-2 = highly anti-inflammatory
  3-4 = anti-inflammatory
  5-6 = neutral
  7-8 = moderately inflammatory
  9-10 = highly inflammatory

This module also builds an alias index at import time for O(1) lookups.
"""

from .database_helpers import (  # noqa: F401
    IngredientRecord,
    _build_alias_index,
    get_by_name,
    get_alias_index,
)

from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass
