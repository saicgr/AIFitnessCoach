"""Shared food-name normalization.

Used as the lookup key for `user_food_overrides.food_name_normalized` and
anywhere else that needs a stable, case-/punctuation-insensitive key for
a food description.

Keep this in sync with any SQL that reads/writes `food_name_normalized` —
the read side and the write side MUST agree character-for-character, or
overrides silently fail to apply.
"""

import re


_WHITESPACE_RE = re.compile(r"\s+")
_NON_ALNUM_SPACE_RE = re.compile(r"[^a-z0-9\s]")


def normalize_food_name(name: str | None) -> str:
    """Stable normalized form of a food description.

    Transformations (in order):
      1. Lowercase
      2. Drop anything that isn't [a-z0-9] or whitespace
      3. Collapse runs of whitespace to a single space
      4. Strip leading/trailing whitespace

    Examples:
        "Masala Dosa"          → "masala dosa"
        "  Dosa, Masala "      → "dosa masala"
        "Chicken Biryani (XL)" → "chicken biryani xl"
        ""                     → ""
        None                   → ""
    """
    if not name:
        return ""
    lowered = name.lower()
    alnum = _NON_ALNUM_SPACE_RE.sub(" ", lowered)
    collapsed = _WHITESPACE_RE.sub(" ", alnum)
    return collapsed.strip()
