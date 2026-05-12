"""Shared food-name normalization.

Used as the lookup key for `*_normalized` columns across user_food_overrides,
user_recipes, recipe_ingredients, saved_foods, and grocery_list_items, and
anywhere else that needs a stable, case-/punctuation-/diacritic-insensitive
key for a food description.

This Python implementation MUST stay in lockstep with the SQL functions
`normalize_food_name_sql()` and `lemmatize_food_word()` defined in migration
2056. The columns in those tables are GENERATED STORED from the SQL side, so
the Python normalizer is what callers use for the pre-insert dedupe SELECT —
if the two ever drift, the SELECT misses an existing row and you get a
silent duplicate (or a unique-index error if the SQL form already conflicts).

`backend/tests/test_food_naming_parity.py` runs every fixture string through
both implementations and fails the build if they disagree.
"""
from __future__ import annotations

import re
import unicodedata
from typing import Optional

# ─── Word-level lemmatization ────────────────────────────────────
# Mirrors `lemmatize_food_word(TEXT)` in migration 2056. Order matters:
# irregular overrides first, then generic suffix rules. Extend the override
# map (here AND in the SQL function) when a new common cuisine plural slips
# through the suffix rules.

_IRREGULAR: dict[str, str] = {
    "idlis":    "idli",
    "samosas":  "samosa",
    "parathas": "paratha",
    "chutneys": "chutney",
    "rotis":    "roti",
    "curries":  "curry",
    "tomatoes": "tomato",
    "potatoes": "potato",
    "cookies":  "cookie",
    "brownies": "brownie",
    "berries":  "berry",
    "cherries": "cherry",
    "leaves":   "leaf",
    "loaves":   "loaf",
    "knives":   "knife",
}

_IES_SUFFIX = re.compile(r"ies$")
_ES_SUFFIX_AFTER_SIBILANT = re.compile(r"(ses|xes|zes|ches|shes)$")
_S_SUFFIX = re.compile(r"s$")
_BARE_S_EXCLUSIONS = re.compile(r"(ss|us|is)$")


def _lemmatize_word(w: str) -> str:
    if not w:
        return w
    if w in _IRREGULAR:
        return _IRREGULAR[w]
    # -ies → -y (puppies → puppy), only on words longer than 4 chars.
    if _IES_SUFFIX.search(w) and len(w) > 4:
        return _IES_SUFFIX.sub("y", w)
    # -ses/-xes/-zes/-ches/-shes → drop -es (boxes → box).
    if _ES_SUFFIX_AFTER_SIBILANT.search(w):
        return w[:-2]
    # bare -s, but only when long enough and not after ss/us/is (kiss, bus, basis).
    if (
        _S_SUFFIX.search(w)
        and not _BARE_S_EXCLUSIONS.search(w)
        and len(w) > 3
    ):
        return w[:-1]
    return w


# ─── Diacritic stripping ─────────────────────────────────────────
# Equivalent to Postgres `unaccent()` for the Latin range we care about.
# NFKD splits "é" into "e" + COMBINING ACUTE ACCENT; the combining mark is
# in the Mn (Mark, Nonspacing) category and gets filtered out.

def _strip_diacritics(s: str) -> str:
    nfkd = unicodedata.normalize("NFKD", s)
    return "".join(c for c in nfkd if unicodedata.category(c) != "Mn")


# ─── Main entry point ────────────────────────────────────────────
_NON_ALNUM_SPACE = re.compile(r"[^a-z0-9 ]")
_WHITESPACE = re.compile(r"\s+")


def normalize_food_name(name: Optional[str], *, preserve_diacritics: bool = False) -> str:
    """Stable normalized form of a food description.

    Pipeline (mirrors `normalize_food_name_sql` in migration 2056):
      1. Lowercase
      2. Strip diacritics (unless `preserve_diacritics=True` — used for display
         columns where "Crème Brûlée" should stay readable)
      3. Drop everything outside [a-z 0-9 space]
      4. Split on whitespace, lemmatize each word, rejoin with single space
      5. Trim

    Examples:
        normalize_food_name("Masala Dosa")          → "masala dosa"
        normalize_food_name("  Dosa, Masala ")      → "dosa masala"
        normalize_food_name("Chicken Biryani (XL)") → "chicken biryani xl"
        normalize_food_name("Idlis")                → "idli"
        normalize_food_name("Tomatoes")             → "tomato"
        normalize_food_name("Crème Brûlée")         → "creme brulee"
        normalize_food_name("McDonald's Burger")    → "mcdonald s burger"
        normalize_food_name("")                     → ""
        normalize_food_name(None)                   → ""
    """
    if not name:
        return ""
    s = name.lower()
    if not preserve_diacritics:
        s = _strip_diacritics(s)
    # Drop everything that isn't a-z 0-9 or space (diacritics already gone).
    s = _NON_ALNUM_SPACE.sub(" ", s)
    # Split on whitespace, lemmatize each word, rejoin.
    words = [_lemmatize_word(w) for w in _WHITESPACE.split(s) if w]
    return " ".join(words)
