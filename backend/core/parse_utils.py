"""
Robust numeric parsers for messy AI/Gemini response fields.

Gemini occasionally returns values like "9 boiled eggs" for an amount field
or "2-3" for servings. These helpers extract the first numeric value from
any string, falling back to a default when nothing is extractable.
"""

import re
from typing import Union

_LEADING_NUMBER_RE = re.compile(r"[-+]?\d+(?:\.\d+)?")


def safe_float(val: Union[str, int, float, None], default: float = 0.0) -> float:
    """Extract a float from a possibly messy value.

    Handles: "9 boiled eggs" → 9.0, "150 kcal" → 150.0, "3.5g" → 3.5,
    None → default, already numeric → passthrough.
    """
    if val is None:
        return default
    if isinstance(val, (int, float)):
        return float(val)
    m = _LEADING_NUMBER_RE.search(str(val))
    return float(m.group()) if m else default


def safe_int(val: Union[str, int, float, None], default: int = 0) -> int:
    """Extract an int from a possibly messy value.

    Uses safe_float internally, then truncates to int.
    Handles: "2-3" → 2, "approximately 4" → 4, "30 minutes" → 30.
    """
    return int(safe_float(val, default=float(default)))
