"""
Gemini Service Parsers - JSON extraction, weight parsing, USDA lookup.
"""
import json
import re as regex_module
import logging
import asyncio
from typing import List, Dict, Optional

from core.ai_response_parser import parse_ai_json

logger = logging.getLogger("gemini")


# Splits a query like "laughing cow cheese with 4 bacon and 10 ritz crackers"
# into the chunks ["laughing cow cheese", "4 bacon", "10 ritz crackers"].
_QUERY_SPLIT_RE = regex_module.compile(
    r"[,;]|\s+with\s+|\s+and\s+|\s+plus\s+|\s+&\s+",
    regex_module.IGNORECASE,
)

# Strip leading counts, articles, and filler ("4 bacon" → "bacon", "a cup of rice" → "rice").
# Applied repeatedly so "a cup of rice" → "cup of rice" → "of rice" → "rice" in one pass
# (the outer + handles the repetition).
_LEADING_NOISE_RE = regex_module.compile(
    r"^\s*(?:\d+(?:\.\d+)?\s*(?:cups?|cup|oz|g|grams?|ml|tbsp|tsp|lbs?|pounds?|pieces?|pcs?|slices?)?\s+"
    r"|a\s+|an\s+|the\s+|some\s+|of\s+)+",
    regex_module.IGNORECASE,
)

# Tokens too short or too common to count as "substantive overlap" between a
# Gemini item name and the user's query. Includes English + French stopwords
# because the bug is specifically Gemini translating English → French, and
# "la"/"le"/"qui" must NOT count as overlap if the user typed them in English.
_NAME_STOPWORDS = frozenset({
    "a", "an", "the", "of", "with", "and", "or", "for", "in", "on", "at",
    "to", "by", "from", "my", "your", "some", "as", "is", "are", "was",
    "la", "le", "les", "de", "du", "des", "et", "ou", "en", "au", "aux",
    "qui", "que", "un", "une",
})

# Strong signals that a Gemini item name is in a FOREIGN language and
# should be eligible for sanitization. Words on this list are either
# rare in English usage or are specific translation-target vocabulary
# observed in real Gemini failures. Being conservative here matters —
# a common English-used word like "queso" or "guacamole" would cause
# false positives on composite-meal ingredients.
_FOREIGN_INDICATORS = frozenset({
    # French determiners / prepositions when they appear INSIDE a name
    # (stopwords filter them from the overlap check; this set uses them
    # as a positive "this name is French" signal instead).
    "la", "le", "les", "du", "des", "aux", "qui", "que",
    # French foods / nouns
    "fromage", "lait", "pain", "beurre", "poulet", "boeuf", "jambon",
    "oeuf", "oeufs", "pommes", "frites", "crème", "pâté", "pâte",
    "tartiner", "avoine", "amande",
    # French adjectives / brand-translation markers
    "vache", "rit", "taureau", "rouge", "fumé",
    # Spanish generic translations (not commonly used English)
    "leche",
    # Japanese / other Asian translations
    "shoyu",
})


# =============================================================================
# 3-Layer portion validation (added 2026-05-11 after the blueberries 99×148g
# = 8316 kcal incident — Gemini emitted the per-CUP weight as the per-piece
# weight). See models/gemini_schemas.FoodItemSchema for L1; see
# `reconcile_with_db()` for L2; see `apply_tripwires()` for L3.
# =============================================================================

# Realistic kcal/g windows by food_category. Used by L3 as the last-line
# sanity gate — any item outside its category window gets flagged for user
# confirmation rather than silently logged. Bounds are *generous* (real foods
# can sit at the edges) and chosen so a bug like "99 berries × 148g = 12g/g"
# is unmistakably outside the fruit window (0.2–1.0 kcal/g).
KCAL_PER_G_CATEGORY_WINDOWS: Dict[str, tuple] = {
    "fruit":     (0.2, 1.0),  # whole fresh fruit; dried fruit handled separately
    "vegetable": (0.1, 1.0),
    "nut":       (4.0, 7.5),  # 5–6.5 typical, 7+ for macadamias
    "oil":       (7.5, 9.5),  # ~9 kcal/g, with safety margin
    "grain":     (1.0, 4.5),  # cooked-rice low end, granola high end
    "protein":   (1.0, 5.0),  # poached fish low, pepperoni high
    "dairy":     (0.3, 4.5),  # skim milk low, hard aged cheese high
    "dessert":   (1.5, 6.0),  # ice cream low, candy high
    "beverage":  (0.0, 2.0),
}

# Foods that should NEVER carry portion_basis="by_count". If Gemini ships a
# count for these (e.g. "1 oz cashews" → count=1 weight_per_unit=28), we
# rewrite to by_weight. Maps lower-cased name fragment → typical serving (g).
_NEVER_COUNTABLE_DEFAULT_G: Dict[str, float] = {
    "blueberr": 80,    # ½ cup
    "strawberr": 75,   # ½ cup sliced
    "raspberr": 60,
    "blackberr": 70,
    "grape": 80,
    "cherr": 70,
    "pomegranate": 50,
    "cashew": 28,      # 1 oz
    "almond": 28,
    "walnut": 28,
    "peanut butter": 32,  # 2 tbsp
    "almond butter": 32,
    "hummus": 30,
    "peanut": 28,      # whole peanuts (kept after "peanut butter" check below)
    "pistachio": 28,
    "pecan": 28,
    "macadamia": 28,
    "chia": 12,        # 1 tbsp
    "flax": 7,         # 1 tbsp
    "sunflower seed": 16,
    "pumpkin seed": 16,
    "sesame seed": 9,
    "olive oil": 14,   # 1 tbsp
    "oats": 40,        # ½ cup dry rolled
    "granola": 30,
}


def _match_never_countable(name: str) -> Optional[tuple]:
    """Returns (matched_fragment, default_g) or None.

    Longest-match wins so 'peanut butter' beats bare 'peanut'.
    """
    if not name:
        return None
    nm = name.lower()
    best: Optional[tuple] = None
    for frag, default_g in _NEVER_COUNTABLE_DEFAULT_G.items():
        if frag in nm and (best is None or len(frag) > len(best[0])):
            best = (frag, default_g)
    return best


def reconcile_with_db(items: List[dict], db_rows: Dict[str, dict]) -> List[dict]:
    """L2: Reconcile Gemini items with food-DB override rows.

    Args:
        items: list of food-item dicts from Gemini
        db_rows: lookup of {normalized_food_name: override_row}, where
                 override_row has at minimum:
                   default_weight_per_piece_g (Optional[float])
                   default_serving_g          (Optional[float])

    Three failure modes handled:

    1. **Whole-unit food** (egg, banana, apple, etc.) — DB per_piece /
       serving > 0.5: count is meaningful. Keep count, recompute
       weight_g = count * piece_weight (from DB if Gemini's weight_g is
       absent or wildly off). Set sanity_clamped=True if values change.

    2. **Truly countable small piece** (blueberry, etc.) — DB per_piece /
       serving < 0.5: count is suspect. If Gemini's weight_per_unit_g
       exceeds the DB piece weight by >2x, switch portion_basis to
       "by_weight" and use serving weight instead.

    3. **Oz-as-piece anti-pattern** (cashews, peanut butter) — name matches
       _NEVER_COUNTABLE_DEFAULT_G AND claimed weight_per_unit_g > 50g
       (impossible per-cashew weight): rewrite to by_weight, drop count,
       use serving weight.

    Always sets sanity_clamped=True when any value changes.
    Never silently rewrites without flagging.
    """
    if not items:
        return items

    for item in items:
        if not isinstance(item, dict):
            continue
        name = (item.get("name") or "").strip()
        # DB row lookup (caller-side normalization assumed already done).
        db = None
        if db_rows:
            db = db_rows.get(name) or db_rows.get(name.lower())

        portion_basis = item.get("portion_basis")
        count = item.get("count")
        wpu = item.get("weight_per_unit_g")

        # ---- Failure mode 3: oz-as-piece anti-pattern ----
        # This runs even WITHOUT a DB row, since the rule is name-based.
        nc_match = _match_never_countable(name)
        if nc_match and (portion_basis == "by_count" or count or (wpu and wpu > 50)):
            frag, default_g = nc_match
            new_weight = item.get("weight_g")
            if not new_weight or (wpu and wpu > 50):
                # Use Gemini's weight_g if it looks like a serving weight
                # (small fruits/nuts/spreads ~10–200g); otherwise default.
                if not new_weight or new_weight > 1000 or new_weight < 1:
                    new_weight = default_g
            try:
                logger.warning(
                    f"[L2-Reconcile] '{name}' matched never-countable '{frag}'; "
                    f"forcing by_weight (was count={count}, wpu={wpu}, weight_g={item.get('weight_g')}); "
                    f"new weight_g={new_weight}"
                )
            except Exception:
                pass
            item["portion_basis"] = "by_weight"
            item["count"] = None
            item["weight_per_unit_g"] = None
            item["weight_g"] = new_weight
            item["sanity_clamped"] = True
            continue

        if not db:
            continue
        piece_w = db.get("default_weight_per_piece_g")
        serving_w = db.get("default_serving_g") or db.get("serving_size_g")

        # ---- Failure modes 1 & 2: need both pieces of DB info ----
        if portion_basis != "by_count" or not count or not piece_w or not serving_w:
            continue

        ratio = piece_w / serving_w if serving_w else 0
        if ratio > 0.5:
            # Whole-unit food (egg ≈ 50g, serving = 50g; banana ≈ 120g serving).
            # Keep count; recompute weight_g if Gemini's value disagrees badly.
            expected_weight = count * piece_w
            current_weight = item.get("weight_g") or 0
            if current_weight <= 0 or abs(current_weight - expected_weight) / expected_weight > 0.4:
                try:
                    logger.warning(
                        f"[L2-Reconcile] Whole-unit '{name}' count={count}: "
                        f"weight_g {current_weight}g → {expected_weight}g (DB piece={piece_w}g)"
                    )
                except Exception:
                    pass
                item["weight_g"] = expected_weight
                item["weight_per_unit_g"] = piece_w
                item["sanity_clamped"] = True
        else:
            # Truly countable small piece (berry, nugget). If Gemini's
            # per-unit weight > 2x DB, the count almost certainly came from
            # confusing the cup weight for a piece weight. Switch to by_weight.
            if wpu and piece_w and wpu > piece_w * 2:
                try:
                    logger.warning(
                        f"[L2-Reconcile] Small-piece '{name}': wpu={wpu}g >> DB piece={piece_w}g; "
                        f"switching to by_weight at serving={serving_w}g"
                    )
                except Exception:
                    pass
                item["portion_basis"] = "by_weight"
                item["count"] = None
                item["weight_per_unit_g"] = None
                item["weight_g"] = serving_w
                item["sanity_clamped"] = True

    return items


def _categorize_for_window(name: str) -> Optional[str]:
    """Best-effort category guess for the kcal/g window check.

    Returns a key from KCAL_PER_G_CATEGORY_WINDOWS or None.
    Conservative — when uncertain, returns None so we don't fire a false
    tripwire. The item's own `category` field (when present) wins.
    """
    if not name:
        return None
    nm = name.lower()
    if any(t in nm for t in ("oil",)):
        return "oil"
    if any(t in nm for t in ("cashew", "almond", "walnut", "peanut", "pistachio", "pecan", "macadamia", "nut")):
        return "nut"
    if any(t in nm for t in ("blueberr", "strawberr", "raspberr", "blackberr", "grape", "cherr", "apple", "banana", "orange", "mango", "fruit")):
        return "fruit"
    if any(t in nm for t in ("broccoli", "spinach", "kale", "lettuce", "vegetable", "carrot", "cucumber", "tomato")):
        return "vegetable"
    if any(t in nm for t in ("rice", "oat", "wheat", "bread", "pasta", "noodle", "quinoa", "granola", "cereal")):
        return "grain"
    if any(t in nm for t in ("chicken", "beef", "pork", "fish", "salmon", "tuna", "egg", "tofu", "lentil", "bean")):
        return "protein"
    if any(t in nm for t in ("milk", "yogurt", "cheese", "butter")):
        return "dairy"
    if any(t in nm for t in ("ice cream", "candy", "chocolate", "cake", "cookie", "donut")):
        return "dessert"
    if any(t in nm for t in ("juice", "soda", "coffee", "tea", "smoothie", "drink", "shake", "water")):
        return "beverage"
    return None


def apply_tripwires(items: List[dict]) -> List[dict]:
    """L3: Sanity tripwires that flag (don't silently rewrite) bad items.

    For each item, checks:
      1. kcal/g sits inside the category window (if category is known/guessable).
      2. weight_g <= 5000 (no realistic single item is 5kg).
      3. count * weight_per_unit_g ≈ weight_g within 20% (internal consistency).

    On ANY tripwire: sets confidence='low', requires_user_confirmation=True,
    and appends a human-readable reason to item['_tripwire_reasons'].
    Never silently rewrites the values — that's L2's job.
    """
    if not items:
        return items

    for item in items:
        if not isinstance(item, dict):
            continue
        reasons: List[str] = list(item.get("_tripwire_reasons") or [])

        weight_g = item.get("weight_g") or 0
        calories = item.get("calories") or 0
        count = item.get("count")
        wpu = item.get("weight_per_unit_g")
        name = (item.get("name") or "").strip()

        # 1. kcal/g window
        category = item.get("category") or _categorize_for_window(name)
        if category in KCAL_PER_G_CATEGORY_WINDOWS and weight_g > 0 and calories > 0:
            lo, hi = KCAL_PER_G_CATEGORY_WINDOWS[category]
            density = calories / weight_g
            if density < lo or density > hi:
                reasons.append(
                    f"{calories} kcal / {weight_g:.0f}g = {density:.2f} kcal/g "
                    f"is outside {category} window {lo}-{hi}"
                )

        # 2. absurd single-item weight
        if weight_g and weight_g > 5000:
            reasons.append(f"weight_g={weight_g:.0f} exceeds 5000g cap (no single item is 5kg)")

        # 3. internal consistency
        if count and wpu and weight_g:
            expected = count * wpu
            if expected > 0 and abs(expected - weight_g) / max(expected, weight_g) > 0.2:
                reasons.append(
                    f"count×weight_per_unit ({count}×{wpu:.1f}={expected:.0f}g) "
                    f"disagrees with weight_g={weight_g:.0f}g by >20%"
                )

        if reasons:
            item["confidence"] = "low"
            item["requires_user_confirmation"] = True
            item["_tripwire_reasons"] = reasons
            try:
                logger.warning(f"[L3-Tripwire] '{name}': {'; '.join(reasons)}")
            except Exception:
                pass

    return items


def finalize_food_items(items: List[dict], db_rows: Optional[Dict[str, dict]] = None) -> List[dict]:
    """Run the L2+L3 portion-validation pipeline.

    Args:
        items: list of food-item dicts (post-Gemini, post-USDA-enhance).
        db_rows: optional {normalized_name: override_row} lookup. When None,
                 only L3 tripwires fire (vision flow doesn't have DB rows).

    Returns the same list (mutated in place + returned for chaining).
    """
    # Always run reconcile_with_db: even with no db_rows, the never-countable
    # name-match path (oz-as-piece anti-pattern) catches cashews / blueberries
    # / peanut butter without any DB dependency.
    items = reconcile_with_db(items, db_rows or {})
    items = apply_tripwires(items)
    return items


def _looks_foreign(name: str) -> bool:
    """True when `name` is either non-ASCII OR contains a token from
    `_FOREIGN_INDICATORS`. Used to gate the sanitizer so composite-meal
    ingredients like "Black Beans" or "Corn Salsa" (English, zero-overlap
    with the user's query text) are NOT rewritten."""
    if not name.isascii():
        return True
    tokens = set(regex_module.findall(r"\w+", name.lower()))
    return bool(tokens & _FOREIGN_INDICATORS)


def _sanitize_foreign_name(name: str, original_query: Optional[str]) -> str:
    """Safety net for when Gemini translates the user's English brand/food
    name to a foreign canonical (e.g. `laughing cow cheese` → `Fromage La
    Vache Qui Rit`) despite the prompt rule.

    Two-stage detection:
    1. `_looks_foreign(name)` — the item name itself must show foreign
       signals (non-ASCII OR French/Spanish/Japanese tokens from the
       indicator list). Items like "Black Beans" or "White Rice" that are
       plain English composite ingredients pass this check → skip.
    2. Zero substantive token overlap with the user's query. If the
       item name shares any meaningful token with the user's wording,
       Gemini's output is aligned → skip.

    When both stages fire, replace the item name with the first usable
    chunk of the user's original query.

    Returns `name` unchanged when:
    - original_query is empty (image flow)
    - name doesn't look foreign
    - there's any substantive token overlap with the query
    - no usable chunk (1-6 tokens) exists in the query after noise-stripping
    """
    if not name or not original_query:
        return name
    if not _looks_foreign(name):
        return name
    name_tokens = {
        t for t in regex_module.findall(r"\w+", name.lower())
        if len(t) >= 3 and t not in _NAME_STOPWORDS
    }
    query_tokens = {
        t for t in regex_module.findall(r"\w+", original_query.lower())
        if len(t) >= 3 and t not in _NAME_STOPWORDS
    }
    if not name_tokens or not query_tokens:
        return name
    if name_tokens & query_tokens:
        return name
    # Zero overlap + foreign-looking: safe to replace with a query chunk.
    for chunk in _QUERY_SPLIT_RE.split(original_query):
        chunk = _LEADING_NOISE_RE.sub("", chunk.strip()).strip()
        if not chunk:
            continue
        token_count = len(chunk.split())
        if 1 <= token_count <= 6:
            sanitized = chunk.title()
            logger.info(
                f"[NameSanitizer] Replaced '{name}' → '{sanitized}' "
                f"(foreign-looking + zero token overlap with query '{original_query[:60]}')"
            )
            return sanitized
    return name


class ParsersMixin:
    """Mixin providing parsing methods for GeminiService."""

    def _try_recover_truncated_json(self, content: str) -> Optional[Dict]:
        """
        Attempt to recover a truncated JSON response by closing open structures.
        Returns parsed dict if successful, None otherwise.
        """
        if not content:
            return None

        # Count open brackets/braces
        open_braces = content.count('{') - content.count('}')
        open_brackets = content.count('[') - content.count(']')

        # If severely truncated (missing many closers), give up
        if open_braces > 5 or open_brackets > 5:
            logger.warning(f"JSON too severely truncated to recover: {open_braces} braces, {open_brackets} brackets open")
            return None

        recovered = content

        # Try to find a reasonable truncation point (end of a complete field)
        # Look for last complete string or number value
        last_comma = recovered.rfind(',')
        last_colon = recovered.rfind(':')

        if last_comma > last_colon:
            # Truncated after a complete value, remove trailing comma
            recovered = recovered[:last_comma]
        elif last_colon > last_comma:
            # Truncated mid-value, remove incomplete field
            last_good_comma = recovered.rfind(',', 0, last_colon)
            if last_good_comma > 0:
                recovered = recovered[:last_good_comma]

        # Close open structures
        recovered += ']' * open_brackets
        recovered += '}' * open_braces

        try:
            result = json.loads(recovered)
            logger.info("Successfully recovered truncated JSON")
            return result
        except json.JSONDecodeError:
            # Try more aggressive recovery - cut to last complete object
            try:
                # Find the last complete array element or object
                brace_depth = 0
                bracket_depth = 0
                last_complete = -1

                for i, char in enumerate(content):
                    if char == '{':
                        brace_depth += 1
                    elif char == '}':
                        brace_depth -= 1
                        if brace_depth == 0:
                            last_complete = i
                    elif char == '[':
                        bracket_depth += 1
                    elif char == ']':
                        bracket_depth -= 1

                if last_complete > 0:
                    recovered = content[:last_complete + 1]
                    # Close any remaining brackets
                    open_brackets = recovered.count('[') - recovered.count(']')
                    recovered += ']' * open_brackets
                    return json.loads(recovered)
            except json.JSONDecodeError as e:
                logger.debug(f"JSON recovery attempt failed: {e}")

            logger.warning("Failed to recover truncated JSON", exc_info=True)
            return None

    def _fix_trailing_commas(self, json_str: str) -> str:
        """
        Fix trailing commas in JSON which are invalid but commonly returned by LLMs.
        Handles cases like: {"a": 1,} or [1, 2,]
        """
        import re
        # Remove trailing commas before closing braces/brackets
        # Handles: ,} ,] with optional whitespace/newlines between
        fixed = re.sub(r',(\s*[}\]])', r'\1', json_str)
        return fixed

    def _parse_weight_from_amount(self, amount: str) -> tuple[float, str]:
        """
        Parse weight in grams from amount string.
        Returns (weight_g, weight_source) where weight_source is 'exact' or 'estimated'.

        Examples:
            "59 grams" -> (59.0, "exact")
            "150g" -> (150.0, "exact")
            "1 cup" -> (240.0, "estimated")
            "handful" -> (30.0, "estimated")
        """
        if not amount:
            return (100.0, "estimated")  # Default to 100g

        amount_lower = amount.lower().strip()

        # Try to extract explicit gram weight
        gram_patterns = [
            r'(\d+(?:\.\d+)?)\s*(?:g|grams?|gram)\b',  # "59g", "59 grams", "59.5 grams"
            r'(\d+(?:\.\d+)?)\s*(?:gr)\b',  # "59gr"
        ]
        for pattern in gram_patterns:
            match = regex_module.search(pattern, amount_lower)
            if match:
                return (float(match.group(1)), "exact")

        # Convert common measurements to grams (estimates)
        conversion_estimates = {
            # Cups
            'cup': 240.0,
            'cups': 240.0,
            '1/2 cup': 120.0,
            'half cup': 120.0,
            '1/4 cup': 60.0,
            'quarter cup': 60.0,
            # Spoons
            'tablespoon': 15.0,
            'tbsp': 15.0,
            'teaspoon': 5.0,
            'tsp': 5.0,
            # Informal
            'handful': 30.0,
            'small handful': 20.0,
            'large handful': 45.0,
            # Portions
            'small': 100.0,
            'medium': 150.0,
            'large': 200.0,
            'small bowl': 150.0,
            'medium bowl': 250.0,
            'large bowl': 350.0,
            # Slices
            'slice': 30.0,
            'slices': 60.0,
            '1 slice': 30.0,
            '2 slices': 60.0,
            # Pieces
            'piece': 50.0,
            '1 piece': 50.0,
            '2 pieces': 100.0,
        }

        for term, grams in conversion_estimates.items():
            if term in amount_lower:
                return (grams, "estimated")

        # Try to extract oz/ounces and convert
        oz_match = regex_module.search(r'(\d+(?:\.\d+)?)\s*(?:oz|ounce|ounces)\b', amount_lower)
        if oz_match:
            oz = float(oz_match.group(1))
            return (oz * 28.35, "exact")  # 1 oz = 28.35g

        # Try to extract numeric value (assume grams if unit unclear)
        numeric_match = regex_module.search(r'^(\d+(?:\.\d+)?)\s*$', amount_lower)
        if numeric_match:
            return (float(numeric_match.group(1)), "estimated")

        # Default fallback
        return (100.0, "estimated")

    def _is_good_usda_match(self, query: str, usda_description: str) -> bool:
        """
        Check if the USDA result is a good match for the query.
        Avoids using wrong products (e.g., "Cinnabon Pudding" for "Cinnabon Delights").
        """
        query_lower = query.lower().strip()
        desc_lower = usda_description.lower().strip()

        # List of restaurant/fast food brands - USDA doesn't have their menu items
        restaurant_brands = [
            'taco bell', 'mcdonalds', "mcdonald's", 'burger king', 'wendys', "wendy's",
            'chick-fil-a', 'chickfila', 'subway', 'chipotle', 'five guys', 'in-n-out',
            'popeyes', 'kfc', 'pizza hut', 'dominos', "domino's", 'papa johns',
            'starbucks', 'dunkin', 'panda express', 'chilis', "chili's", 'applebees',
            "applebee's", 'olive garden', 'red lobster', 'outback', 'ihop', "denny's",
            'sonic', 'arby', "arby's", 'jack in the box', 'carl', "carl's jr",
            'hardee', "hardee's", 'del taco', 'qdoba', 'panera', 'noodles',
            'wingstop', 'buffalo wild wings', 'hooters', 'zaxbys', "zaxby's",
        ]

        # If query mentions a restaurant brand, USDA probably doesn't have the right item
        for brand in restaurant_brands:
            if brand in query_lower:
                logger.info(f"[USDA] Skipping match - '{query}' is a restaurant item (USDA doesn't have restaurant menus)")
                return False

        # Check if key words from query appear in USDA description
        # Split query into significant words (3+ chars)
        query_words = [w for w in query_lower.split() if len(w) >= 3]

        # Count how many query words appear in the description
        matches = sum(1 for word in query_words if word in desc_lower)
        match_ratio = matches / len(query_words) if query_words else 0

        # Require at least 50% of words to match for a good match
        if match_ratio < 0.5:
            logger.info(f"[USDA] Poor match - query='{query}' vs result='{usda_description}' (match_ratio={match_ratio:.0%})")
            return False

        return True

    async def _lookup_single_usda(self, usda_service, food_name: str) -> Optional[Dict]:
        """Look up a single food in USDA database. Returns usda_data dict or None."""
        if not usda_service or not food_name:
            return None
        try:
            search_result = await usda_service.search_foods(
                query=food_name,
                page_size=1,  # Just need top match
            )
            if search_result.foods:
                top_food = search_result.foods[0]

                # Check if this is actually a good match
                if not self._is_good_usda_match(food_name, top_food.description):
                    logger.warning(f"[USDA] Skipping poor match for '{food_name}' - keeping AI estimate")
                    return None

                nutrients = top_food.nutrients
                logger.info(f"[USDA] Found '{top_food.description}' for '{food_name}' ({nutrients.calories_per_100g} cal/100g)")
                return {
                    'fdc_id': top_food.fdc_id,
                    'calories_per_100g': nutrients.calories_per_100g,
                    'protein_per_100g': nutrients.protein_per_100g,
                    'carbs_per_100g': nutrients.carbs_per_100g,
                    'fat_per_100g': nutrients.fat_per_100g,
                    'fiber_per_100g': nutrients.fiber_per_100g,
                }
        except Exception as e:
            logger.warning(f"USDA lookup failed for '{food_name}': {e}", exc_info=True)
        return None

    async def _enhance_food_items_with_nutrition_db(
        self,
        food_items: List[Dict],
        use_usda: bool = False,
        original_query: Optional[str] = None,
    ) -> List[Dict]:
        """
        Enhance food items with per-100g nutrition data for accurate scaling.

        Primary flow (use_usda=False): Uses local food database (528K foods in Supabase)
        via batch lookup for instant results (~50-100ms for 5 items).

        Retry flow (use_usda=True): Falls back to USDA API for a different data source.

        For each food item:
        1. Look up in nutrition database (batch or parallel)
        2. If found: Add usda_data with per-100g values
        3. If not found: Calculate ai_per_gram from AI's estimate
        4. Post-process: strip non-ASCII foreign canonical names when the user's
           `original_query` carries an English equivalent (see _sanitize_foreign_name).
        """
        # Parse weights first (synchronous, fast)
        # Use Gemini's weight_g if provided, otherwise parse from amount string
        parsed_items = []
        for item in food_items:
            enhanced_item = dict(item)

            # First check if Gemini provided a valid weight_g
            gemini_weight = item.get('weight_g')
            if gemini_weight and gemini_weight > 0:
                enhanced_item['weight_g'] = float(gemini_weight)
                enhanced_item['weight_source'] = 'gemini'
            else:
                # Fall back to parsing the amount string
                amount = item.get('amount', '')
                weight_g, weight_source = self._parse_weight_from_amount(amount)
                enhanced_item['weight_g'] = weight_g
                enhanced_item['weight_source'] = weight_source

            parsed_items.append(enhanced_item)

        food_names = [item.get('name', '') for item in food_items]

        if use_usda:
            # Retry flow: Use USDA API (parallel individual lookups)
            try:
                from services.usda_food_service import get_usda_food_service
                usda_service = get_usda_food_service()
            except Exception as e:
                logger.warning(f"Could not initialize USDA service: {e}", exc_info=True)
                usda_service = None

            logger.info(f"[USDA] Looking up {len(food_names)} items in parallel (retry flow)...")
            lookup_results = await asyncio.gather(
                *[self._lookup_single_usda(usda_service, name) for name in food_names],
                return_exceptions=True
            )
            # Convert gather results to list, replacing exceptions with None
            nutrition_results = []
            for r in lookup_results:
                if isinstance(r, Exception):
                    nutrition_results.append(None)
                else:
                    nutrition_results.append(r)
        else:
            # Primary flow: Use local food database (single batch call)
            try:
                from services.food_database_lookup_service import get_food_db_lookup_service
                food_db_service = get_food_db_lookup_service()
                logger.info(f"[FoodDB] Batch looking up {len(food_names)} items...")
                batch_results = await food_db_service.batch_lookup_foods(food_names)
                # Convert batch dict to ordered list matching food_names
                nutrition_results = [batch_results.get(name) for name in food_names]
            except Exception as e:
                logger.warning(f"Food DB batch lookup failed, falling back to AI estimates: {e}", exc_info=True)
                nutrition_results = [None] * len(food_names)

        # Process results (same logic for both flows)
        enhanced_items = []
        source_label = "USDA" if use_usda else "FoodDB"
        for i, (item, nutrition_data) in enumerate(zip(parsed_items, nutrition_results)):
            weight_g = item['weight_g']
            weight_source = item.get('weight_source', 'estimated')

            if nutrition_data:
                # Check if data has valid calories (non-zero, or legitimately zero-cal)
                calories_per_100g = nutrition_data.get('calories_per_100g', 0)
                protein_per_100g = nutrition_data.get('protein_per_100g', 0)
                carbs_per_100g = nutrition_data.get('carbs_per_100g', 0)
                fat_per_100g = nutrition_data.get('fat_per_100g', 0)
                is_legit_zero_cal = (
                    calories_per_100g == 0
                    and protein_per_100g <= 1
                    and carbs_per_100g <= 1
                    and fat_per_100g <= 1
                )

                if weight_g > 0 and (calories_per_100g > 0 or is_legit_zero_cal):
                    # Apply override weight correction if available
                    # Never override when user gave an exact weight (e.g. "200g of dosa")
                    override_weight = nutrition_data.get('override_weight_per_piece_g')
                    if override_weight and weight_source != 'exact':
                        original_item = food_items[i]
                        count = original_item.get('count')
                        if count and count > 0:
                            # User said "2 dosas" → 2 * 100g = 200g
                            corrected = count * override_weight
                            logger.info(
                                f"[{source_label}] WEIGHT OVERRIDE: '{food_names[i]}' "
                                f"count={count} × {override_weight}g = {corrected}g "
                                f"(was {weight_g}g)"
                            )
                            weight_g = corrected
                            item['weight_g'] = weight_g
                            item['weight_source'] = 'override'
                        elif weight_source in ('estimated', 'gemini'):
                            # No explicit count, assume 1 piece
                            logger.info(
                                f"[{source_label}] WEIGHT OVERRIDE: '{food_names[i]}' "
                                f"1 piece = {override_weight}g (was {weight_g}g)"
                            )
                            weight_g = override_weight
                            item['weight_g'] = weight_g
                            item['weight_source'] = 'override'

                    # Use nutrition DB data
                    item['usda_data'] = nutrition_data
                    item['ai_per_gram'] = None

                    multiplier = weight_g / 100.0
                    item['calories'] = round(calories_per_100g * multiplier)
                    item['protein_g'] = round(nutrition_data['protein_per_100g'] * multiplier, 1)
                    item['carbs_g'] = round(nutrition_data['carbs_per_100g'] * multiplier, 1)
                    item['fat_g'] = round(nutrition_data['fat_per_100g'] * multiplier, 1)
                    item['fiber_g'] = round(nutrition_data['fiber_per_100g'] * multiplier, 1)
                    if is_legit_zero_cal:
                        logger.info(f"[{source_label}] Using ZERO-CAL data for '{food_names[i]}' | confirmed 0 cal + 0 macros from DB")
                    else:
                        logger.info(f"[{source_label}] Using data for '{food_names[i]}' | calories={item['calories']} | cal/100g={calories_per_100g} | weight={weight_g}g")
                else:
                    # Match found but has 0 calories with non-trivial macros - incomplete data, fall back to AI values
                    logger.warning(f"[{source_label}] Found match for '{food_names[i]}' but calories=0 with macros, keeping AI estimate | ai_calories={item.get('calories', 0)}")
                    item['usda_data'] = None
                    # Calculate ai_per_gram so frontend can still scale portions
                    original_item = food_items[i]
                    ai_cal = original_item.get('calories', 0)
                    if weight_g > 0 and ai_cal > 0:
                        item['ai_per_gram'] = {
                            'calories': round(ai_cal / weight_g, 3),
                            'protein': round(original_item.get('protein_g', 0) / weight_g, 4),
                            'carbs': round(original_item.get('carbs_g', 0) / weight_g, 4),
                            'fat': round(original_item.get('fat_g', 0) / weight_g, 4),
                            'fiber': round(original_item.get('fiber_g', 0) / weight_g, 4) if original_item.get('fiber_g') else 0,
                        }
                    else:
                        item['ai_per_gram'] = None
            else:
                # Fallback: Calculate per-gram from AI estimate
                item['usda_data'] = None
                original_item = food_items[i]
                ai_calories = original_item.get('calories', 0)
                ai_protein = original_item.get('protein_g', 0)
                ai_carbs = original_item.get('carbs_g', 0)
                ai_fat = original_item.get('fat_g', 0)
                ai_fiber = original_item.get('fiber_g', 0)

                if weight_g > 0:
                    item['ai_per_gram'] = {
                        'calories': round(ai_calories / weight_g, 3),
                        'protein': round(ai_protein / weight_g, 4),
                        'carbs': round(ai_carbs / weight_g, 4),
                        'fat': round(ai_fat / weight_g, 4),
                        'fiber': round(ai_fiber / weight_g, 4) if ai_fiber else 0,
                    }
                    logger.warning(f"[{source_label}] No match for '{food_names[i]}', using AI per-gram estimate")
                else:
                    item['ai_per_gram'] = None

            # Safety net: if Gemini parroted back a foreign canonical/trademark name
            # despite the prompt rule (e.g. "Fromage La Vache Qui Rit" for a user
            # query of "laughing cow cheese"), rewrite it to the user's wording.
            item['name'] = _sanitize_foreign_name(item.get('name', ''), original_query)

            enhanced_items.append(item)

        # L2 + L3 portion-validation pipeline (replaces the legacy
        # _apply_portion_sanity_caps after the blueberries 99×148g incident).
        # Build a {name: db_row} lookup from the per-item nutrition_data so
        # reconcile_with_db can detect oz-as-piece + small-piece anti-patterns.
        try:
            db_rows: Dict[str, dict] = {}
            for it, nd in zip(enhanced_items, nutrition_results):
                if isinstance(nd, dict):
                    nm = it.get("name") or ""
                    db_rows[nm] = {
                        "default_weight_per_piece_g": nd.get("override_weight_per_piece_g"),
                        "default_serving_g": nd.get("default_serving_g") or nd.get("serving_size_g"),
                    }
            finalize_food_items(enhanced_items, db_rows=db_rows or None)
        except Exception as _fe:
            logger.warning(f"[finalize_food_items] non-fatal failure: {_fe}", exc_info=True)

        return enhanced_items
