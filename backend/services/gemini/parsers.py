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

            logger.warning("Failed to recover truncated JSON")
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
            logger.warning(f"USDA lookup failed for '{food_name}': {e}")
        return None

    async def _enhance_food_items_with_nutrition_db(self, food_items: List[Dict], use_usda: bool = False) -> List[Dict]:
        """
        Enhance food items with per-100g nutrition data for accurate scaling.

        Primary flow (use_usda=False): Uses local food database (528K foods in Supabase)
        via batch lookup for instant results (~50-100ms for 5 items).

        Retry flow (use_usda=True): Falls back to USDA API for a different data source.

        For each food item:
        1. Look up in nutrition database (batch or parallel)
        2. If found: Add usda_data with per-100g values
        3. If not found: Calculate ai_per_gram from AI's estimate
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
                logger.warning(f"Could not initialize USDA service: {e}")
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
                logger.warning(f"Food DB batch lookup failed, falling back to AI estimates: {e}")
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

            enhanced_items.append(item)

        return enhanced_items
