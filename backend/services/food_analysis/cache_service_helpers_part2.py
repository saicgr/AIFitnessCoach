"""Second part of cache_service_helpers.py (auto-split for size)."""
from typing import Any, Dict, List, Optional, Tuple
import hashlib
import json
import logging
import re
from sqlalchemy import text
from core.supabase_client import get_supabase
from services.food_analysis.parser import ParsedFoodItem
from services.food_analysis.constants import (
    _WEIGHT_REGEX, _WEIGHT_AFTER_REGEX, _VOLUME_REGEX, _VOLUME_AFTER_REGEX,
)
from services.food_analysis.parser import _weight_unit_to_grams, _volume_unit_to_ml

logger = logging.getLogger(__name__)


class FoodAnalysisCacheServicePart2:
    """Second half of FoodAnalysisCacheService methods. Use as mixin."""

    def _split_food_description(
        self, description: str
    ) -> List[ParsedFoodItem]:
        """
        Split a multi-item food description into individual ParsedFoodItems.

        Splitting order:
        1. Newlines
        2. Commas
        3. " and " / " & " / " + " (with compound food protection)
        4. Does NOT split on " with " (part of food names like "dosa with chutney")

        Per-item parsing extracts quantity, weight_g, volume_ml, unit, and food_name.

        Args:
            description: Food description potentially containing multiple items

        Returns:
            List of ParsedFoodItem
        """
        raw_parts = self._split_text_into_parts(description.strip())
        items: List[ParsedFoodItem] = []
        for part in raw_parts:
            parsed = self._parse_single_item(part)
            if parsed:
                items.append(parsed)
        return items

    # Keywords that signal a composite meal (bowl, burrito, etc.) with its ingredients.
    # These are meal TYPES, not containers — "burrito bowl with X" is composite,
    # but "bowl of ice cream" is not (it's a container).
    _COMPOSITE_MEAL_KEYWORDS = frozenset([
        # Mexican / Tex-Mex
        'bowl', 'burrito', 'taco', 'quesadilla', 'nachos', 'fajitas', 'enchilada',
        # Sandwiches & wraps
        'wrap', 'sandwich', 'sub', 'pita', 'gyro', 'shawarma', 'banh mi',
        # Asian
        'ramen', 'pho', 'bibimbap', 'stir fry', 'stir-fry', 'pad thai',
        'sushi roll', 'bento', 'dosa',
        # Indian
        'thali', 'curry bowl',
        # Western
        'pizza', 'pasta', 'omelette', 'omelet', 'crepe',
        # Bowls (specific named types)
        'poke', 'grain bowl', 'acai bowl', 'buddha bowl', 'power bowl',
        'smoothie bowl', 'burrito bowl', 'rice bowl',
        # Drinks / desserts that are composed
        'shake', 'smoothie', 'parfait', 'sundae',
        # Platters / combos
        'platter', 'plate', 'combo',
        # Modifiers that signal composed items
        'loaded', 'stuffed',
        # Soups & noodles
        'soup', 'noodles', 'noodle soup',
    ])

    # "bowl of X", "plate of X" = container, NOT composite meal
    _CONTAINER_OF_RE = re.compile(
        r'\b(bowl|plate|cup|glass|mug|pot|jar|bag|box|can|bottle|carton)\s+of\s+',
        re.IGNORECASE,
    )

    def _is_composite_meal(self, text: str) -> bool:
        """Detect if text describes a single composite meal with its ingredients.

        Returns True when the text contains a meal keyword (bowl, burrito, etc.)
        early in the sentence followed by ingredient indicators (commas, "with",
        "topped with", "add", etc.). This prevents the splitter from breaking a
        composite meal like "Chipotle bowl with chicken, rice, beans" into 4 parts.

        Returns False for "container of X" patterns like "bowl of ice cream" or
        "plate of cookies" where the keyword is just a vessel.
        """
        text_lower = text.lower().strip()

        # "bowl of ice cream", "plate of cookies" = container, not composite
        if self._CONTAINER_OF_RE.search(text_lower):
            return False

        # Must contain a composite keyword
        keyword_pos = None
        for kw in self._COMPOSITE_MEAL_KEYWORDS:
            pos = text_lower.find(kw)
            if pos != -1 and (keyword_pos is None or pos < keyword_pos):
                keyword_pos = pos

        if keyword_pos is None:
            return False

        # Keyword should be in the first half of the text (before ingredients)
        if keyword_pos > len(text_lower) * 0.5:
            return False

        # If "with" is followed by a quantity, these are separate items, not composite
        # e.g., "5 dosas with 200ml lassi" → 2 separate items
        with_match = re.search(r'\s+with\s+(.+)', text_lower)
        if with_match and self._RIGHT_SIDE_QTY_RE.match(with_match.group(1)):
            return False

        # Check for ingredient indicators after the keyword
        after_keyword = text_lower[keyword_pos:]
        has_ingredients = any(marker in after_keyword for marker in [
            ' with ', ', ', ' topped ', ' add ', '(', ' over ', ' on ',
            ' in ', ' plus ', ' and ', ' extra ', ' no ', ' double ',
        ])
        # Also treat as composite if keyword is followed by 3+ words
        # (e.g., "chicken burrito bowl rice beans cheese")
        words_after = after_keyword.split()
        if len(words_after) >= 3:
            has_ingredients = True

        return has_ingredients

    def _split_text_into_parts(self, text: str) -> List[str]:
        """Split text into individual food strings using newlines, commas, and conjunctions."""
        # Check for composite meal BEFORE splitting — send whole description to Gemini
        if self._is_composite_meal(text):
            return [text]

        # Step 1: Split on newlines
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        parts: List[str] = []
        for line in lines:
            # Check each line for composite meals too
            if self._is_composite_meal(line):
                parts.append(line)
                continue
            # Step 2: Split on commas
            comma_parts = [p.strip() for p in line.split(',') if p.strip()]
            for cp in comma_parts:
                # Step 3: Split on " and " / " & " / " + " with compound food protection
                parts.extend(self._split_on_conjunctions(cp))
        return parts

    # Regex to detect a quantity/unit at the START of a string.
    # Used by smart "with" splitting: "5 dosas with 200ml lassi" → split
    # because right side starts with "200ml".
    _RIGHT_SIDE_QTY_RE = re.compile(
        r'^\s*(?:'
        r'\d+(?:\.\d+)?\s*(?:g|gm|gms|grams?|kg|ml|oz|ounces?|cups?|liters?|litres?|l|lbs?|plates?|bowls?|glasses?|slices?|pieces?|servings?)\b'  # digit+unit
        r'|\d+(?:\.\d+)?\s+\w'  # bare number + food word
        r'|(?:one|two|three|four|five|six|seven|eight|nine|ten|half|quarter|dozen|couple|a|an)\s+\w'  # word number
        r')',
        re.IGNORECASE,
    )

    def _split_on_conjunctions(self, text: str) -> List[str]:
        """Split on ' and ', ' & ', ' + ' and smart ' with ' but protect compound foods."""
        # Check if the full text is a known override → don't split
        lookup_service = get_food_db_lookup_service()
        if lookup_service._overrides.get(text.lower().strip()):
            return [text]

        # ── Smart "with" splitting ──
        # Split on " with " when:
        #   1. The right side starts with a quantity/unit ("5 dosas with 200ml lassi")
        #   2. The right side contains " and " suggesting multiple separate dishes
        #      ("pulihora rice with ground nut pachadi and chicken fry" → 3 items)
        #      BUT only when the text is NOT a composite meal (already checked above)
        # Keep together when it's a simple compound name:
        #   "dosa with chutney"  → keep  (no qty, no "and")
        #   "coffee with milk"   → keep  (no qty, no "and")
        with_parts = re.split(r'\s+with\s+', text, flags=re.IGNORECASE)
        if len(with_parts) > 1:
            smart_merged: List[str] = [with_parts[0]]
            for wp in with_parts[1:]:
                # Split if right side has a quantity
                if self._RIGHT_SIDE_QTY_RE.match(wp):
                    smart_merged.append(wp)
                # Split if right side contains " and " (multiple dishes listed)
                # e.g., "ground nut pachadi and chicken fry" → split on "with"
                elif re.search(r'\s+and\s+', wp, re.IGNORECASE):
                    smart_merged.append(wp)
                else:
                    # Simple compound name → rejoin with " with "
                    smart_merged[-1] = f"{smart_merged[-1]} with {wp}"
            # If we actually split, recurse on each part for " and " splitting
            if len(smart_merged) > 1:
                result: List[str] = []
                for part in smart_merged:
                    result.extend(self._split_on_and_only(part, lookup_service))
                return result
            # No "with" split happened, fall through to " and " splitting
            text = smart_merged[0]

        return self._split_on_and_only(text, lookup_service)

    def _split_on_and_only(self, text: str, lookup_service) -> List[str]:
        """Split on ' and ', ' & ', ' + ' with compound food protection."""
        # Try splitting
        parts = re.split(r'\s+and\s+|\s*&\s*|\s*\+\s*', text, flags=re.IGNORECASE)
        parts = [p.strip() for p in parts if p.strip()]
        if len(parts) <= 1:
            return [text]

        # Check if any adjacent pair forms a compound food
        # e.g., "mac and cheese" → rejoin if "mac and cheese" is in overrides
        merged: List[str] = []
        i = 0
        while i < len(parts):
            if i + 1 < len(parts):
                compound = f"{parts[i]} and {parts[i+1]}"
                if lookup_service._overrides.get(compound.lower().strip()):
                    merged.append(compound)
                    i += 2
                    continue
            merged.append(parts[i])
            i += 1
        return merged

    def _parse_single_item(self, raw: str) -> Optional[ParsedFoodItem]:
        """Parse a single food string into a ParsedFoodItem."""
        text = raw.strip()
        if not text:
            return None

        # Strip fillers: "I had", "I ate", "about", etc.
        text = _FILLER_REGEX.sub('', text).strip()
        # Strip bullets: "- ", "• ", "1. ", "breakfast: "
        text = _BULLET_REGEX.sub('', text).strip()
        # Strip leading "and " / "or "
        text = re.sub(r'^(?:and|or)\s+', '', text, flags=re.IGNORECASE).strip()

        if not text:
            return None

        # Full-text override check: if entire text (including number) is a known override
        # This handles "chicken 65", "5 star chocolate", "7up"
        lookup_service = get_food_db_lookup_service()
        if lookup_service._overrides.get(text.lower().strip()):
            return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)

        # Try weight BEFORE food: "300g haleem", "0.5kg chicken"
        m = _WEIGHT_REGEX.match(text)
        if m:
            val = float(m.group(1))
            wg = _weight_unit_to_grams(val, m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, weight_g=wg, raw_text=raw)

        # Try volume BEFORE food: "500ml milk", "2 liters water"
        m = _VOLUME_REGEX.match(text)
        if m:
            val = float(m.group(1))
            ml = _volume_unit_to_ml(val, m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, weight_g=ml, volume_ml=ml, raw_text=raw)

        # Try weight AFTER food: "rice 100g"
        m = _WEIGHT_AFTER_REGEX.match(text)
        if m:
            food = m.group(1).strip()
            val = float(m.group(2))
            wg = _weight_unit_to_grams(val, m.group(3))
            return ParsedFoodItem(food_name=food, weight_g=wg, raw_text=raw)

        # Try volume AFTER food: "milk 500ml"
        m = _VOLUME_AFTER_REGEX.match(text)
        if m:
            food = m.group(1).strip()
            val = float(m.group(2))
            ml = _volume_unit_to_ml(val, m.group(2))
            return ParsedFoodItem(food_name=food, weight_g=ml, volume_ml=ml, raw_text=raw)

        # Try numeric + count-unit: "6 slices pizza", "2 cups rice"
        m = _NUM_UNIT_REGEX.match(text)
        if m:
            qty = float(m.group(1))
            unit = m.group(2).lower()
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, quantity=qty, unit=unit, raw_text=raw)

        # Try word number + optional unit: "one plate biryani", "half a pizza", "a bowl of soup"
        m = _WORD_NUM_UNIT_REGEX.match(text)
        if m:
            word = m.group(1).lower()
            qty = _WORD_NUMBERS.get(word, 1.0)
            unit = m.group(2).lower() if m.group(2) else None
            food = m.group(3).strip()
            # Strip leading "of " from food if present
            food = re.sub(r'^of\s+', '', food, flags=re.IGNORECASE)
            return ParsedFoodItem(food_name=food, quantity=qty, unit=unit, raw_text=raw)

        # Try fraction: "1/2 pizza"
        m = _FRACTION_REGEX.match(text)
        if m:
            qty = float(m.group(1)) / float(m.group(2))
            food = m.group(3).strip()
            return ParsedFoodItem(food_name=food, quantity=qty, raw_text=raw)

        # Try bare number: "2 dosa", "100 rice"
        m = _BARE_NUM_REGEX.match(text)
        if m:
            qty = float(m.group(1))
            food = m.group(2).strip()
            # Check if full text with number is a known override (e.g., "chicken 65")
            if lookup_service._overrides.get(text.lower().strip()):
                return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)
            return ParsedFoodItem(food_name=food, quantity=qty, raw_text=raw)

        # No quantity detected
        return ParsedFoodItem(food_name=text, quantity=1.0, raw_text=raw)

    async def _try_multi_item_lookup(
        self, description: str, user_id: Optional[str] = None
    ) -> Optional[Dict[str, Any]]:
        """
        Try to resolve food description from overrides + common foods.

        Now handles single items with quantities (e.g., "2 dosa") in addition
        to multi-item descriptions. For each parsed item, checks:
        1. Exact override match
        2. Fuzzy override search (word-index)
        3. Common foods DB

        If ALL items resolve locally, combines and returns the result.
        If any item misses, returns None to let Gemini handle the full description.

        When weight_g is provided on a ParsedFoodItem, scales using per-100g data.
        Applies countability heuristic for bare numbers.

        Args:
            description: Food description
            user_id: Optional user ID

        Returns:
            Combined analysis dict if all items found, None otherwise
        """
        try:
            items = self._split_food_description(description)
            if not items:
                return None

            # Ensure overrides are loaded
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()

            all_food_items = []
            total_cals = 0
            total_protein = 0.0
            total_carbs = 0.0
            total_fat = 0.0
            total_fiber = 0.0

            for item in items:
                analysis = await self._resolve_single_parsed_item(item, lookup_service)

                if not analysis:
                    # Any miss means Gemini handles the full description
                    return None

                for fi in analysis["food_items"]:
                    all_food_items.append(fi)

                total_cals += analysis["total_calories"]
                total_protein += analysis["protein_g"]
                total_carbs += analysis["carbs_g"]
                total_fat += analysis["fat_g"]
                total_fiber += analysis["fiber_g"]

            score = self._compute_health_score(total_cals, total_protein, total_fiber)

            return {
                "food_items": all_food_items,
                "total_calories": total_cals,
                "protein_g": round(total_protein, 1),
                "carbs_g": round(total_carbs, 1),
                "fat_g": round(total_fat, 1),
                "fiber_g": round(total_fiber, 1),
                "encouragements": [],
                "warnings": [],
                "ai_suggestion": None,
                "recommended_swap": None,
                "overall_meal_score": score,
                "health_score": score,
                "data_source": "multi_lookup",
            }

        except Exception as e:
            logger.warning(f"Multi-item lookup failed: {e}")
            return None

    async def _try_modified_override(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to resolve a customized food item using base override + modifier adjustments.

        Handles inputs like:
            "Spicy McChicken with Extra patty and bacon on top"
            "Big Mac no pickles extra cheese"
            "Quarter Pounder add bacon no ketchup"

        Steps:
            1. Strip NL filler phrases
            2. Extract all recognized modifiers from the text
            3. Remove modifiers to get the base food description
            4. Look up base food in overrides (exact → fuzzy)
            5. Apply modifier calorie/macro adjustments
            6. Return combined result

        Returns:
            Analysis dict with modifier adjustments, or None if base food not found.
        """
        try:
            text = description.strip()
            if not text or len(text) < 3:
                return None

            # Step 1: Strip NL filler phrases
            text = _FILLER_REGEX.sub('', text).strip()
            text = _BULLET_REGEX.sub('', text).strip()
            if not text:
                return None

            text_lower = text.lower()

            # Step 2: Find all modifiers in the text
            found_modifiers = []
            remaining = text_lower
            for phrase in _MODIFIER_PHRASES_SORTED:
                # Use word boundary matching
                pattern = re.compile(r'\b' + re.escape(phrase) + r'\b', re.IGNORECASE)
                if pattern.search(remaining):
                    found_modifiers.append(phrase)
                    # Remove the modifier from remaining text
                    remaining = pattern.sub('', remaining, count=1)

            if not found_modifiers:
                return None  # No modifiers found — let other steps handle it

            # Step 3: Clean up remaining text to get base food name
            # Remove conjunctions, prepositions, extra spaces
            base_food = remaining.strip()
            base_food = re.sub(r'\s+', ' ', base_food)
            # Remove stray commas and trailing punctuation
            base_food = re.sub(r'[,;.]+', ' ', base_food).strip()
            # Iteratively strip leading/trailing conjunctions and prepositions
            for _ in range(3):
                base_food = re.sub(
                    r'^(?:and|with|plus|also|on\s+top|on\s+the\s+side)\s+', '', base_food, flags=re.IGNORECASE
                ).strip()
                base_food = re.sub(
                    r'\s+(?:and|with|plus|also|on\s+top|on\s+the\s+side)$', '', base_food, flags=re.IGNORECASE
                ).strip()
                # Also strip standalone trailing "and" / "with" / "plus"
                base_food = re.sub(r'^(?:and|with|plus|also)\b', '', base_food, flags=re.IGNORECASE).strip()
                base_food = re.sub(r'\b(?:and|with|plus|also)$', '', base_food, flags=re.IGNORECASE).strip()
            base_food = re.sub(r'\s+', ' ', base_food).strip()

            if not base_food or len(base_food) < 2:
                return None

            # Step 4: Look up base food in overrides
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()

            # Parse quantity from the base food text
            parsed = self._parse_single_item(base_food)
            food_name = parsed.food_name if parsed else base_food

            override = await lookup_service._check_override_fuzzy_db(food_name)

            # Fuzzy fallback via search
            if not override:
                fuzzy_matches = lookup_service._find_matching_overrides_for_search(food_name)
                if fuzzy_matches:
                    # Use the best match (highest similarity)
                    best = fuzzy_matches[0]
                    best_name = best.get("name", "")
                    override = await lookup_service._check_override_fuzzy_db(best_name)

            if not override:
                return None

            # Step 5: Get base analysis
            if parsed and parsed.weight_g:
                base_analysis = self._override_to_analysis_by_weight(override, parsed.weight_g)
            elif parsed and parsed.quantity != 1.0:
                qty = self._apply_countability_heuristic(override, parsed.quantity) if not parsed.unit else parsed.quantity
                base_analysis = self._override_to_analysis_scaled(override, qty)
            else:
                base_analysis = self._override_to_analysis(override)

            if not base_analysis:
                return None

            # Step 6: Apply modifier adjustments
            # Tuple indices: (cal, protein, carbs, fat, fiber, sodium_mg, cholesterol_mg, sat_fat_g, trans_fat_g)
            mod_cals = 0
            mod_protein = 0.0
            mod_carbs = 0.0
            mod_fat = 0.0
            mod_fiber = 0.0
            mod_sodium = 0.0
            mod_cholesterol = 0.0
            mod_sat_fat = 0.0
            mod_trans_fat = 0.0
            modifier_names = []

            for mod_phrase in found_modifiers:
                adj = _FOOD_MODIFIERS[mod_phrase]
                mod_cals += adj[0]
                mod_protein += adj[1]
                mod_carbs += adj[2]
                mod_fat += adj[3]
                mod_fiber += adj[4]
                mod_sodium += adj[5]
                mod_cholesterol += adj[6]
                mod_sat_fat += adj[7]
                mod_trans_fat += adj[8]
                modifier_names.append(mod_phrase)

            # Build structured modifier_details for the response
            modifier_details = []
            for mod_phrase in found_modifiers:
                adj = _FOOD_MODIFIERS[mod_phrase]
                meta = _MODIFIER_METADATA.get(mod_phrase)
                mod_type = meta.type if meta else _classify_modifier(mod_phrase)

                detail: Dict[str, Any] = {
                    "phrase": mod_phrase,
                    "type": mod_type.value,
                    "delta": {
                        "calories": adj[0],
                        "protein_g": adj[1],
                        "carbs_g": adj[2],
                        "fat_g": adj[3],
                        "fiber_g": adj[4],
                    },
                }

                if mod_type == ModifierType.ADDON and meta and meta.default_weight_g:
                    dw = meta.default_weight_g
                    detail["default_weight_g"] = dw
                    detail["weight_per_unit_g"] = meta.weight_per_unit_g
                    detail["unit_name"] = meta.unit_name
                    detail["per_gram"] = {
                        "calories": round(adj[0] / dw, 4) if dw else 0,
                        "protein_g": round(adj[1] / dw, 4) if dw else 0,
                        "carbs_g": round(adj[2] / dw, 4) if dw else 0,
                        "fat_g": round(adj[3] / dw, 4) if dw else 0,
                        "fiber_g": round(adj[4] / dw, 4) if dw else 0,
                    }

                if mod_type in (ModifierType.DONENESS, ModifierType.COOKING_METHOD, ModifierType.SIZE_PORTION):
                    if meta and meta.group:
                        detail["group"] = meta.group
                        detail["group_options"] = []
                        for m in _MODIFIER_GROUPS.get(meta.group, []):
                            if m in _FOOD_MODIFIERS:
                                m_meta = _MODIFIER_METADATA.get(m)
                                label = m_meta.display_label if m_meta and m_meta.display_label else m.title()
                                detail["group_options"].append({
                                    "phrase": m,
                                    "label": label,
                                    "cal_delta": _FOOD_MODIFIERS[m][0],
                                })

                if meta and meta.display_label:
                    detail["display_label"] = meta.display_label

                modifier_details.append(detail)

            # Apply to totals (ensure nothing goes negative)
            total_cals = max(0, base_analysis["total_calories"] + mod_cals)
            total_protein = max(0.0, base_analysis["protein_g"] + mod_protein)
            total_carbs = max(0.0, base_analysis["carbs_g"] + mod_carbs)
            total_fat = max(0.0, base_analysis["fat_g"] + mod_fat)
            total_fiber = max(0.0, base_analysis["fiber_g"] + mod_fiber)

            # Apply micronutrient adjustments on top of base analysis values
            total_sodium = max(0.0, float(base_analysis.get("sodium_mg") or 0) + mod_sodium)
            total_cholesterol = max(0.0, float(base_analysis.get("cholesterol_mg") or 0) + mod_cholesterol)
            total_sat_fat = max(0.0, float(base_analysis.get("saturated_fat_g") or 0) + mod_sat_fat)
            total_trans_fat = max(0.0, float(base_analysis.get("trans_fat_g") or 0) + mod_trans_fat)

            # Update food_items[0] with adjusted values and structured modifiers
            food_items = base_analysis.get("food_items", [])
            if food_items:
                fi = food_items[0].copy()
                fi["calories"] = total_cals
                fi["protein_g"] = round(total_protein, 1)
                fi["carbs_g"] = round(total_carbs, 1)
                fi["fat_g"] = round(total_fat, 1)
                fi["fiber_g"] = round(total_fiber, 1)
                fi["sodium_mg"] = round(total_sodium, 1)
                fi["cholesterol_mg"] = round(total_cholesterol, 1)
                fi["saturated_fat_g"] = round(total_sat_fat, 1)
                fi["trans_fat_g"] = round(total_trans_fat, 1)
                base_name = fi.get("name", food_name)
                fi["name"] = base_name
                fi["modifiers"] = modifier_details
                food_items = [fi]

            score = self._compute_health_score(total_cals, total_protein, total_fiber)

            logger.info(
                f"🎯 Modified override HIT: '{description}' → base='{food_name}', "
                f"modifiers={modifier_names}, cals={total_cals}"
            )

            return {
                "food_items": food_items,
                "total_calories": total_cals,
                "protein_g": round(total_protein, 1),
                "carbs_g": round(total_carbs, 1),
                "fat_g": round(total_fat, 1),
                "fiber_g": round(total_fiber, 1),
                "sodium_mg": round(total_sodium, 1),
                "cholesterol_mg": round(total_cholesterol, 1),
                "saturated_fat_g": round(total_sat_fat, 1),
                "trans_fat_g": round(total_trans_fat, 1),
                "encouragements": [],
                "warnings": [],
                "ai_suggestion": None,
                "recommended_swap": None,
                "overall_meal_score": score,
                "health_score": score,
                "data_source": "modified_override",
            }

        except Exception as e:
            logger.warning(f"Modified override lookup failed: {e}")
            return None

    async def _resolve_single_parsed_item(
        self, item: ParsedFoodItem, lookup_service
    ) -> Optional[Dict[str, Any]]:
        """
        Resolve a single ParsedFoodItem to a nutrition analysis using overrides + common foods.

        Applies countability heuristic for bare numbers and weight-based scaling.
        Uses DB-backed fuzzy matching (cooking stems, word reordering, variant search)
        to catch near-misses like "avocado mash" → "mashed avocado".

        Args:
            item: ParsedFoodItem from _split_food_description
            lookup_service: FoodDatabaseLookupService instance

        Returns:
            Analysis dict or None if not found
        """
        food_name = item.food_name
        # Fuzzy DB lookup: exact → variant array → stemmed/reordered → trigram
        override = await lookup_service._check_override_fuzzy_db(food_name)

        if override:
            # Weight-based scaling
            if item.weight_g:
                return self._override_to_analysis_by_weight(override, item.weight_g)

            # Apply countability heuristic for bare numbers (no unit specified)
            qty = item.quantity
            if qty != 1.0 and not item.unit:
                qty = self._apply_countability_heuristic(override, qty)

            if qty != 1.0:
                return self._override_to_analysis_scaled(override, qty)
            else:
                return self._override_to_analysis(override)

        # Try common foods DB
        common = self.nutrition_db.get_common_food(food_name)
        if common:
            analysis = self._common_food_to_analysis(common)
            # Scale by quantity if not 1.0
            qty = item.quantity
            if item.weight_g and analysis.get("food_items"):
                # Weight-based scaling for common foods
                fi = analysis["food_items"][0]
                base_weight = float(fi.get("weight_g") or 100)
                if base_weight > 0:
                    scale = item.weight_g / base_weight
                    self._scale_analysis(analysis, scale, f"{item.weight_g:.0f}g")
                return analysis
            elif qty != 1.0:
                self._scale_analysis(analysis, qty)
            return analysis

        return None

    @staticmethod
    def _apply_countability_heuristic(override: Dict, qty: float) -> float:
        """
        Apply countability heuristic for bare numbers (user typed "100 rice" or "2 dosa").

        Rules:
        - Countable food (has weight_per_piece_g) + qty <= 30 → count (pieces)
        - Countable food + qty > 30 → treat qty as grams, convert to piece-count
        - Non-countable (serving_g only) + qty > 10 → treat qty as grams
        - Non-countable + qty <= 10 → treat as servings
        - Unknown + qty > 20 → assume grams (return qty as weight_g later handled upstream)
        - Unknown + qty <= 20 → assume count

        Returns the effective count to pass to _override_to_analysis_scaled,
        or a negative value to signal weight-based scaling (caller checks).
        """
        has_piece_weight = override.get("override_weight_per_piece_g") is not None
        has_serving = override.get("override_serving_g") is not None

        if has_piece_weight:
            # Countable food
            if qty <= 30:
                return qty  # pieces
            else:
                # Treat as grams → convert to piece count
                piece_g = override["override_weight_per_piece_g"]
                return qty / piece_g if piece_g > 0 else qty
        elif has_serving:
            # Non-countable food
            if qty > 10:
                # Treat as grams → convert to serving count
                serv_g = override["override_serving_g"]
                return qty / serv_g if serv_g > 0 else qty
            else:
                return qty  # servings
        else:
            # Unknown structure
            if qty > 20:
                # Treat as grams → scale from 100g base
                return qty / 100.0
            else:
                return qty  # count

    def _scale_analysis(
        self, analysis: Dict[str, Any], scale: float, amount_label: str = None
    ) -> None:
        """Scale an analysis dict's food_items and totals by a multiplier (in-place)."""
        for fi in analysis.get("food_items", []):
            fi["calories"] = round(fi["calories"] * scale)
            fi["protein_g"] = round(fi["protein_g"] * scale, 1)
            fi["carbs_g"] = round(fi["carbs_g"] * scale, 1)
            fi["fat_g"] = round(fi["fat_g"] * scale, 1)
            fi["fiber_g"] = round(fi["fiber_g"] * scale, 1)
            if fi.get("weight_g"):
                fi["weight_g"] = round(fi["weight_g"] * scale, 1)
            if amount_label:
                fi["amount"] = amount_label
            elif scale != 1.0:
                scale_display = int(scale) if scale == int(scale) else round(scale, 1)
                fi["amount"] = f"{scale_display} x {fi['amount']}"

        analysis["total_calories"] = round(analysis["total_calories"] * scale)
        analysis["protein_g"] = round(analysis["protein_g"] * scale, 1)
        analysis["carbs_g"] = round(analysis["carbs_g"] * scale, 1)
        analysis["fat_g"] = round(analysis["fat_g"] * scale, 1)
        analysis["fiber_g"] = round(analysis["fiber_g"] * scale, 1)

    def _common_food_to_analysis(self, common_food: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert common food record to standard analysis format.

        Args:
            common_food: Record from common_foods table

        Returns:
            Dict in same format as Gemini analysis
        """
        weight_g = float(common_food.get("serving_weight_g", 0)) if common_food.get("serving_weight_g") else None
        calories = common_food.get("calories", 0)
        protein_g = float(common_food.get("protein_g", 0))
        carbs_g = float(common_food.get("carbs_g", 0))
        fat_g = float(common_food.get("fat_g", 0))
        fiber_g = float(common_food.get("fiber_g", 0))

        food_item = {
            "name": common_food.get("name"),
            "amount": common_food.get("serving_size", "1 serving"),
            "calories": calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "weight_g": weight_g,
            "weight_source": "exact",
            "unit": "g",
        }

        # Add per-gram scaling data so frontend can adjust portions
        if weight_g and weight_g > 0:
            food_item["ai_per_gram"] = {
                "calories": round(calories / weight_g, 3),
                "protein": round(protein_g / weight_g, 4),
                "carbs": round(carbs_g / weight_g, 4),
                "fat": round(fat_g / weight_g, 4),
                "fiber": round(fiber_g / weight_g, 4),
            }

        # Get micronutrients if available
        micronutrients = common_food.get("micronutrients", {})

        # Compute a simple health score from macros
        score = self._compute_health_score(calories, protein_g, fiber_g)

        return {
            "food_items": [food_item],
            "total_calories": calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            # Micronutrients from JSONB field
            "sugar_g": micronutrients.get("sugar_g"),
            "sodium_mg": micronutrients.get("sodium_mg"),
            "cholesterol_mg": micronutrients.get("cholesterol_mg"),
            "vitamin_a_ug": micronutrients.get("vitamin_a_ug"),
            "vitamin_c_mg": micronutrients.get("vitamin_c_mg"),
            "vitamin_d_iu": micronutrients.get("vitamin_d_iu"),
            "calcium_mg": micronutrients.get("calcium_mg"),
            "iron_mg": micronutrients.get("iron_mg"),
            "potassium_mg": micronutrients.get("potassium_mg"),
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            # Source tracking
            "data_source": common_food.get("source", "common_foods"),
            "category": common_food.get("category"),
        }

    @staticmethod
    def _compute_health_score(calories: int, protein_g: float, fiber_g: float) -> int:
        """Compute a simple health score (1-10) from macros."""
        protein_ratio = (protein_g * 4) / max(calories, 1)
        score = 5  # neutral baseline
        if protein_ratio >= 0.25:
            score += 2
        elif protein_ratio >= 0.15:
            score += 1
        if fiber_g >= 5:
            score += 1
        return min(score, 10)

    async def _try_cache(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find cached analysis for food description.

        Args:
            description: Food description

        Returns:
            Cached analysis result if found, None otherwise
        """
        try:
            # Normalize and hash
            normalized = NutritionDB.normalize_food_query(description)
            query_hash = NutritionDB.hash_query(normalized)

            # Check cache
            cached = await _food_analysis_cache.get(query_hash)

            return cached

        except Exception as e:
            logger.warning(f"Cache lookup failed: {e}")
            return None

    async def _cache_result(
        self,
        description: str,
        analysis: Dict[str, Any],
    ) -> bool:
        """
        Cache a successful analysis result.

        Args:
            description: Original food description
            analysis: Analysis result to cache

        Returns:
            True if cached successfully
        """
        try:
            normalized = NutritionDB.normalize_food_query(description)
            query_hash = NutritionDB.hash_query(normalized)
            await _food_analysis_cache.set(query_hash, analysis)
            return True
        except Exception as e:
            logger.warning(f"Failed to cache analysis: {e}")
            return False

    def get_cache_key(self, description: str) -> str:
        """
        Get the cache key (hash) for a food description.

        Useful for debugging and testing.

        Args:
            description: Food description

        Returns:
            SHA256 hash of normalized description
        """
        normalized = NutritionDB.normalize_food_query(description)
        return NutritionDB.hash_query(normalized)

    async def invalidate_cache(self, description: str) -> bool:
        """
        Invalidate (delete) a cached analysis.

        Args:
            description: Food description to invalidate

        Returns:
            True if invalidated successfully
        """
        try:
            normalized = NutritionDB.normalize_food_query(description)
            query_hash = NutritionDB.hash_query(normalized)

            await _food_analysis_cache.delete(query_hash)

            logger.info(f"🗑️ Invalidated cache for: {description[:50]}...")
            return True

        except Exception as e:
            logger.error(f"Failed to invalidate cache: {e}")
            return False

    async def review_food(self, food_name: str, macros: dict, user_id: str) -> dict:
        """
        AI-powered food review based on user goals and nutrition targets.

        Checks cache first, then calls Gemini for fresh review.
        Falls back to rule-based scoring on any error.

        Args:
            food_name: Name of the food item
            macros: Dict with calories, protein_g, carbs_g, fat_g
            user_id: User ID for fetching goals and targets

        Returns:
            Dict with encouragements, warnings, ai_suggestion, recommended_swap, health_score
        """
        # Fetch user goals and nutrition targets from DB
        user_goals = []
        nutrition_targets = {}
        try:
            supabase = get_supabase()
            async with supabase.get_session() as session:
                # Get user goals
                user_result = await session.execute(
                    text("SELECT goals FROM users WHERE id = :uid LIMIT 1"),
                    {"uid": user_id},
                )
                user_row = user_result.fetchone()
                if user_row and user_row._mapping.get("goals"):
                    goals_val = user_row._mapping["goals"]
                    if isinstance(goals_val, list):
                        user_goals = goals_val
                    elif isinstance(goals_val, str):
                        user_goals = [goals_val]

                # Get nutrition targets
                targets_result = await session.execute(
                    text(
                        "SELECT target_calories AS calories, target_protein_g AS protein_g, "
                        "target_carbs_g AS carbs_g, target_fat_g AS fat_g "
                        "FROM nutrition_preferences WHERE user_id = :uid LIMIT 1"
                    ),
                    {"uid": user_id},
                )
                targets_row = targets_result.fetchone()
                if targets_row:
                    nutrition_targets = dict(targets_row._mapping)
        except Exception as e:
            logger.warning(f"[FoodReview] Failed to fetch user data: {e}")

        # Build cache key: food_review_{normalize(food_name)}_{hash(goals)}
        normalized_name = NutritionDB.normalize_food_query(food_name)
        goals_hash = hashlib.sha256(
            json.dumps(sorted(user_goals)).encode()
        ).hexdigest()[:8]
        cache_key = f"food_review_{normalized_name}_{goals_hash}"
        query_hash = NutritionDB.hash_query(cache_key)

        # Check cache
        try:
            cached = await _food_analysis_cache.get(query_hash)
            if cached:
                logger.info(f"[FoodReview] Cache HIT for: {food_name[:50]}")
                return cached
        except Exception as e:
            logger.warning(f"[FoodReview] Cache lookup failed: {e}")

        # Pre-compute health score for score-stratified guidance
        pre_score = self._compute_health_score(
            macros.get("calories", 0),
            macros.get("protein_g", 0),
            macros.get("fiber_g", 0),
        )

        # Cache miss - call Gemini
        try:
            result = await self.gemini_service.generate_food_review(
                food_name=food_name,
                macros=macros,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                health_score=pre_score,
            )

            if result:
                # Cache for 24h
                try:
                    await _food_analysis_cache.set(query_hash, result)
                    logger.info(f"[FoodReview] Cached result for: {food_name[:50]}")
                except Exception as cache_err:
                    logger.warning(f"[FoodReview] Failed to cache: {cache_err}")

                return result

        except Exception as e:
            logger.error(f"[FoodReview] Gemini call failed: {e}")

        # Fallback: rule-based scoring
        logger.info(f"[FoodReview] Using rule-based fallback for: {food_name[:50]}")
        return {
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": "",
            "recommended_swap": "",
            "health_score": pre_score,
        }


# Singleton instance
_cache_service_instance: Optional[FoodAnalysisCacheService] = None


def get_food_analysis_cache_service() -> FoodAnalysisCacheService:
    """Get or create the singleton cache service instance."""
    global _cache_service_instance
    if _cache_service_instance is None:
        _cache_service_instance = FoodAnalysisCacheService()
    return _cache_service_instance
