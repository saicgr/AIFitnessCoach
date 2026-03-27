"""
Food Analysis Caching Service.

Wraps Gemini food analysis with intelligent caching to dramatically
reduce response times for repeated queries.

Cache Strategy:
0a. Saved Foods - User's personal saved meals (instant, user-scoped)
0b. Food Nutrition Overrides - 6,949 curated items (instant)
1. Common Foods DB - Instant lookup (bypasses AI entirely)
1b. Multi-item lookup (overrides + common foods)
1c. Modified override (base item + modifiers like "extra patty", "no cheese")
2. Food Analysis Cache - Cached AI responses (~100ms)
3. Gemini AI - Fresh analysis (30-90s)

Expected Performance:
- Saved food / override hit: < 10ms
- Common food: < 1 second
- Cache hit: < 2 seconds
- Cache miss (first time): 30-60 seconds
"""
import asyncio
import hashlib
import json
import logging
import re
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import Enum
from typing import Optional, Dict, Any, List, Tuple, NamedTuple

from sqlalchemy import text

from core.db.facade import get_supabase_db
from core.db.nutrition_db import NutritionDB
from core.supabase_client import get_supabase
from services.food_database_lookup_service import get_food_db_lookup_service
from services.gemini_service import GeminiService
from core.redis_cache import RedisCache

logger = logging.getLogger(__name__)

_food_analysis_cache = RedisCache(prefix="food_analysis", ttl_seconds=86400, max_size=200)


@dataclass
class ParsedFoodItem:
    """A single parsed food item extracted from a natural-language description."""
    food_name: str          # Cleaned name for DB lookup
    quantity: float = 1.0   # Count (pieces/servings)
    weight_g: float = None  # Explicit weight in grams (e.g., "300g haleem")
    volume_ml: float = None # Explicit volume (converted to weight_g using 1ml~1g)
    unit: str = None        # "plate", "bowl", "glass", "slice", "cup", etc.
    raw_text: str = ""      # Original text before parsing


# ── Parsing constants ─────────────────────────────────────────────

_WORD_NUMBERS = {
    "a": 1, "an": 1, "one": 1, "two": 2, "three": 3, "four": 4,
    "five": 5, "six": 6, "seven": 7, "eight": 8, "nine": 9, "ten": 10,
    "half": 0.5, "quarter": 0.25, "dozen": 12, "couple": 2,
}

# Units that indicate "how many" (not weight/volume)
_COUNT_UNITS = frozenset([
    "plate", "plates", "bowl", "bowls", "glass", "glasses",
    "slice", "slices", "piece", "pieces", "cup", "cups",
    "scoop", "scoops", "spoon", "spoons", "tablespoon", "tablespoons",
    "teaspoon", "teaspoons", "tbsp", "tsp", "serving", "servings",
    "handful", "handfuls", "stick", "sticks", "can", "cans",
    "bottle", "bottles", "packet", "packets", "box", "boxes",
    "bar", "bars", "strip", "strips", "roll", "rolls",
    "portion", "portions",
])

# Weight pattern: number + weight unit (possibly with space)
_WEIGHT_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s*'
    r'(g|gm|gms|gram|grams|kg|kilo|kilogram|kilograms|oz|ounce|ounces)\b'
    r'\s*(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Weight AFTER food: "rice 100g"
_WEIGHT_AFTER_REGEX = re.compile(
    r'^(.+?)\s+(\d+(?:\.\d+)?)\s*'
    r'(g|gm|gms|gram|grams|kg|kilo|kilogram|kilograms|oz|ounce|ounces)$',
    re.IGNORECASE,
)

# Volume pattern: number + volume unit
_VOLUME_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s*'
    r'(ml|milliliter|milliliters|millilitres|l|liter|litre|liters|litres'
    r'|fl\s*oz|fluid\s*oz)\b'
    r'\s*(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Volume AFTER food: "milk 500ml"
_VOLUME_AFTER_REGEX = re.compile(
    r'^(.+?)\s+(\d+(?:\.\d+)?)\s*'
    r'(ml|milliliter|milliliters|millilitres|l|liter|litre|liters|litres'
    r'|fl\s*oz|fluid\s*oz)$',
    re.IGNORECASE,
)

# Filler phrases to strip from the start (mirrors frontend _nlFillerPhrases)
_FILLER_REGEX = re.compile(
    r'^(?:'
    # ── Past tense ──
    # "I had / ate / just had / just ate / drank / consumed / took"
    # NOTE: "finished" is NOT here — handled as "finished off" in phrasal verbs below
    r'i\s+(?:had|ate|just\s+had|just\s+ate|drank|just\s+drank|consumed|took)\s+'
    # Perfect: "I've had / eaten / been eating / already ate"
    r"|i'?ve\s+(?:had|eaten|been\s+eating|been\s+having|already\s+(?:had|ate|eaten))\s+"
    r'|i\s+already\s+(?:had|ate|eaten)\s+'
    # ── Present tense ──
    # "I'm eating / having / drinking / munching / snacking / chewing / finishing / consuming"
    r"|i'?m\s+(?:eating|having|drinking|munching|snacking|chewing|finishing|consuming)\s+"
    r'|(?:currently|right\s+now|just\s+now)\s+(?:eating|having|drinking|munching)\s+'
    # ── Future / intent ──
    # "I'm gonna eat / about to eat / planning to eat / wanna eat / craving"
    r"|i'?m\s+(?:gonna|about\s+to|going\s+to|planning\s+to)\s+(?:eat|have|grab|get|order)\s+"
    r"|i\s+(?:wanna|want\s+to)\s+(?:eat|have|grab|get|order)\s+"
    r'|i\s+feel\s+like\s+(?:eating|having)\s+'
    r'|craving\s+'
    # ── Habitual ──
    r'|i\s+(?:usually|normally|always|often|sometimes|typically)\s+(?:eat|have|drink|get|grab|order)\s+'
    # ── Phrasal verb fillers ──
    # "ended up eating / wound up having / went ahead and ate / decided to eat/have"
    r'|(?:ended\s+up|wound\s+up)\s+(?:eating|having|drinking|getting|ordering)\s+'
    r'|(?:went\s+ahead\s+and|decided\s+to|managed\s+to|had\s+to|could\s+only|couldn\'t\s+help\s+but)\s+(?:eat|ate|have|had|drink|drank|grab|grabbed|get|got|order|ordered)\s+'
    # ── Reward / guilt / indulgence ──
    # "treated myself to / indulged in / splurged on / cheated with / snuck in"
    r'|(?:treated\s+myself\s+to|indulged\s+in|splurged\s+on|cheated\s+with|snuck\s+in|sneaked\s+in|gave\s+in\s+to)\s+'
    r'|(?:guilty\s+pleasure\s+(?:was|is)|cheat\s+meal\s+(?:was|is))\s+'
    # ── Small quantity eating ──
    # "nibbled on / picked at / had a bite of / had a taste of / had a sip of / munched on"
    r'|(?:nibbled\s+on|picked\s+at|munched\s+on|snacked\s+on|grazed\s+on|pecked\s+at)\s+'
    r'|had\s+(?:a\s+)?(?:bite|taste|sip|piece|bit|morsel|sliver|nibble|lick|spoonful)\s+(?:of\s+)?'
    # ── Large quantity eating ──
    # "stuffed myself with / gorged on / pigged out on / feasted on / loaded up on"
    r'|(?:stuffed\s+myself\s+with|gorged\s+on|pigged\s+out\s+on|feasted\s+on|overindulged\s+in|loaded\s+up\s+on|overdid\s+it\s+(?:on|with))\s+'
    # ── Delivery / source compound (MUST come before generic action verbs) ──
    # "ordered from Swiggy / got from DoorDash / delivered from / picked up from"
    r'|(?:ordered|got|picked\s+up|grabbed|delivered)\s+(?:from|via|through|off)\s+(?:swiggy|zomato|doordash|ubereats|uber\s+eats|grubhub|postmates|instacart|seamless|the\s+(?:restaurant|cafeteria|canteen|food\s+court|drive\s+thru|drive-?through))\s+'
    # ── Action verbs ──
    # "grabbed / ordered / cooked / made / demolished / devoured" etc.
    # NOTE: "reheated/heated up/warmed up/microwaved/air fried" are in _FOOD_MODIFIERS, not here
    r'|(?:just\s+)?(?:grabbed|ordered|picked\s+up|got|went\s+with|chose|cooked(?!\s+through)|made|prepared|whipped\s+up|threw\s+together|fixed\s+myself|made\s+myself|cooked\s+myself)\s+'
    r'|(?:just\s+)?(?:demolished|crushed|smashed|scarfed|wolfed\s+down|inhaled|devoured|polished\s+off|downed|chugged|sipped|tasted|tried|sampled|split|shared)\s+'
    # ── Logging intent verbs ──
    # "log / add / track / record / put down / note down / enter / count"
    # Compound: "track my lunch:" / "log my dinner:" / "record breakfast:"
    r'|(?:please\s+)?(?:log|add|track|record|put\s+down|note\s+down|enter|count|save|register)\s+(?:my\s+)?(?:(?:breakfast|lunch|dinner|brunch|snack|meal|food|intake)\s*[:=]\s*)?'
    r'|(?:can\s+you|could\s+you|please|help\s+me)\s+(?:log|add|track|record|enter|count|note)\s+(?:my\s+)?(?:(?:breakfast|lunch|dinner|brunch|snack|meal|food)\s*[:=]\s*)?'
    r'|(?:log(?:ging)?|track(?:ing)?|add(?:ing)?|record(?:ing)?|enter(?:ing)?|count(?:ing)?|not(?:ing)?)\s+(?:my\s+)?(?:food|meal|snack|breakfast|lunch|dinner|intake|macros|calories)\s*:?\s+'
    # ── Meal context ──
    r'|for\s+(?:breakfast|lunch|dinner|brunch|snack|supper|dessert|a\s+snack|my\s+meal|pre-?workout|post-?workout|a\s+quick\s+bite|a\s+cheat\s+meal|a\s+treat|a\s+late\s+night\s+snack|midnight\s+snack|tiffin|tea\s+time|elevenses|my\s+cheat\s+day|second\s+breakfast)\s+'
    # Bare meal labels: "breakfast:", "lunch:", "meal 1:", "3pm snack:"
    r'|(?:breakfast|lunch|dinner|brunch|snack|supper|meal\s*\d*|pre-?\s*workout|post-?\s*workout)\s*[:=]\s*'
    r'|\d{1,2}\s*(?:am|pm)\s+(?:breakfast|lunch|dinner|snack|meal)\s*[:=]?\s+'
    # ── Time context ──
    r'|(?:today|tonight|this\s+morning|this\s+afternoon|this\s+evening|last\s+night|yesterday|earlier\s+today|earlier|just\s+now|moments?\s+ago|a\s+while\s+ago|an\s+hour\s+ago|a\s+few\s+(?:minutes|hours)\s+ago)\s+i\s+(?:had|ate|drank|got|grabbed|consumed|finished)\s+'
    # Possessive time: "today's breakfast / tonight's dinner"
    r"|(?:today'?s|tonight'?s|this\s+morning'?s|yesterday'?s)\s+(?:breakfast|lunch|dinner|snack|meal|food)\s+(?:was|is|included|consisted\s+of)?\s*"
    # Possessive meal: "my breakfast was / my food today"
    r'|my\s+(?:breakfast|lunch|dinner|brunch|snack|meal|food|intake)\s+(?:was|is|today|tonight|this\s+morning|consisted\s+of|included)\s+'
    # ── What I ate / diary style ──
    r'|what\s+i\s+(?:ate|had|eaten|ordered|grabbed)\s+(?:was\s+)?'
    r"|what\s+i'?m\s+(?:eating|having)\s+(?:is\s+)?"
    # ── Conversational ──
    r'|(?:ate|had|having|grabbed|got|ordered|tried|sampled)\s+(?:some|a|an)\s+'
    # ── Limiting ──
    r'|all\s+i\s+(?:had|ate)\s+was\s+'
    r'|(?:only|just)\s+(?:had|ate|eating|having)\s+'
    r"|(?:nothing|all\s+i\s+ate)\s+(?:but|except)\s+"
    # ── Sharing context ──
    r'|we\s+(?:had|ate|ordered|shared|split|grabbed|got|went\s+for|picked\s+up)\s+'
    r'|(?:my\s+(?:friend|partner|wife|husband|bf|gf|kid|son|daughter)\s+and\s+i|me\s+and\s+my\s+\w+)\s+(?:had|ate|shared|split)\s+'
    # ── Query style ──
    r'|how\s+many\s+(?:calories?|carbs?|protein|fat|macros?)\s+(?:in|for|does)\s+'
    r"|(?:what(?:'?s|\s+is|\s+are)?\s+the\s+)?(?:nutrition|calories?|macros?|carbs?|protein|fat)\s+(?:in|of|for|info)\s+"
    r'|(?:nutrition|calorie|macro)\s+(?:info|information|data|breakdown|count)\s+(?:for|of|in)\s+'
    r'|(?:is|does)\s+.{2,30}\s+(?:healthy|good\s+for\s+(?:me|you|weight\s+loss|muscle)|bad\s+for\s+(?:me|you)|fattening|low\s+cal(?:orie)?|high\s+protein)\s*\??'
    # ── Phrasal verb completions (must come AFTER simple past group) ──
    r'|i\s+(?:took|finished\s+off|wolfed|polished\s+off|binged\s+on)\s+'
    # ── Sequential eating ──
    # "followed by / and then had / topped off with / washed it down with"
    r'|(?:followed\s+by|and\s+then\s+(?:had|ate|a)|topped\s+(?:it\s+)?off\s+with|washed\s+(?:it\s+)?down\s+with)\s+'
    # ── Restaurant / source context ──
    # "from McDonald's / at Chipotle / ordered from Swiggy / from the cafeteria / homemade"
    r'|(?:from|at|via|through|off\s+of)\s+(?:the\s+)?(?:restaurant|cafeteria|canteen|food\s+court|drive\s+thru|drive-?through)\s+'
    r'|(?:ordered|got|delivered)\s+(?:from|via|through|off)\s+(?:swiggy|zomato|doordash|ubereats|uber\s+eats|grubhub|postmates|instacart|seamless)\s+'
    r'|(?:home\s*made|home\s*cooked|store\s*bought|takeout|take-?out|take\s*away|dine-?in|delivery)\s+'
    # ── Emphasis / descriptive noise (strip before food name) ──
    r'|(?:the\s+)?(?:best|most\s+amazing|most\s+delicious|incredible|fantastic|amazing|delicious|terrible|disgusting|decent|mediocre|okay|mid)\s+'
    r'|(?:really|very|super|incredibly|extremely|absolutely|totally|so)\s+(?:good|tasty|yummy|delicious|filling|satisfying|healthy|unhealthy)\s+'
    r'|(?:honestly|basically|literally|actually|truly|seriously|lowkey|highkey|ngl|tbh|fr)\s+(?:(?:just|only)\s+)?'
    # ── Mid-sentence noise ──
    # NOTE: "well" must not match before "done" (well done steak)
    r'|(?:um|uh|hmm|well(?!\s+done)|okay|ok|so|yeah)\s+'
    # ── Approximations ──
    r'|(?:about|maybe|around|approximately|roughly|nearly|like|roughly|probably|i\s+think)\s+'
    r')',
    re.IGNORECASE,
)

# ── Modifier parsing for customized food items ───────────────────
# Maps modifier phrases to their nutritional adjustments (per occurrence).
# Values: (cal, protein_g, carbs_g, fat_g, fiber_g, sodium_mg, cholesterol_mg, saturated_fat_g, trans_fat_g)
# Index:   0     1          2        3      4        5           6               7                8
_FOOD_MODIFIERS = {
    # ═══════════════════════════════════════════════════════════════
    # PROTEIN ADD-ONS
    # ═══════════════════════════════════════════════════════════════
    "extra patty":          (250, 20.0, 0.0, 18.0, 0.0, 350, 75, 7.0, 0.5),
    "extra beef patty":     (250, 20.0, 0.0, 18.0, 0.0, 350, 75, 7.0, 0.5),
    "extra chicken patty":  (200, 18.0, 8.0, 10.0, 0.0, 420, 50, 2.5, 0.0),
    "extra fish patty":     (180, 14.0, 12.0, 9.0, 0.0, 380, 30, 2.0, 0.0),
    "extra veggie patty":   (150, 10.0, 15.0, 6.0, 3.0, 350, 0, 1.0, 0.0),
    "double patty":         (250, 20.0, 0.0, 18.0, 0.0, 350, 75, 7.0, 0.5),
    "double meat":          (250, 20.0, 0.0, 18.0, 0.0, 350, 75, 7.0, 0.5),
    "triple patty":         (500, 40.0, 0.0, 36.0, 0.0, 700, 150, 14.0, 1.0),
    "triple meat":          (500, 40.0, 0.0, 36.0, 0.0, 700, 150, 14.0, 1.0),
    "add bacon":            (45, 3.0, 0.0, 3.5, 0.0, 190, 10, 1.2, 0.0),
    "extra bacon":          (90, 6.0, 0.0, 7.0, 0.0, 380, 20, 2.4, 0.0),
    "with bacon":           (45, 3.0, 0.0, 3.5, 0.0, 190, 10, 1.2, 0.0),
    "bacon on top":         (45, 3.0, 0.0, 3.5, 0.0, 190, 10, 1.2, 0.0),
    "add turkey bacon":     (35, 4.0, 0.0, 1.5, 0.0, 180, 15, 0.5, 0.0),
    "add egg":              (90, 6.0, 1.0, 7.0, 0.0, 70, 186, 2.0, 0.0),
    "extra egg":            (90, 6.0, 1.0, 7.0, 0.0, 70, 186, 2.0, 0.0),
    "with egg":             (90, 6.0, 1.0, 7.0, 0.0, 70, 186, 2.0, 0.0),
    "fried egg on top":     (90, 6.0, 1.0, 7.0, 0.0, 70, 186, 2.0, 0.0),
    "add scrambled egg":    (100, 7.0, 1.5, 7.5, 0.0, 170, 190, 2.5, 0.0),
    "add grilled chicken":  (120, 22.0, 0.0, 3.0, 0.0, 350, 65, 0.8, 0.0),
    "add crispy chicken":   (180, 15.0, 10.0, 10.0, 0.0, 480, 45, 2.0, 0.0),
    "add shrimp":           (80, 15.0, 1.0, 1.5, 0.0, 250, 130, 0.3, 0.0),
    "add grilled shrimp":   (80, 15.0, 1.0, 1.5, 0.0, 250, 130, 0.3, 0.0),
    "add fried shrimp":     (120, 12.0, 8.0, 5.0, 0.0, 350, 100, 1.0, 0.0),
    "add steak":            (200, 26.0, 0.0, 10.0, 0.0, 320, 70, 4.0, 0.0),
    "add pulled pork":      (150, 18.0, 2.0, 8.0, 0.0, 400, 55, 3.0, 0.0),
    "add sausage":          (170, 8.0, 1.0, 15.0, 0.0, 400, 35, 5.5, 0.0),
    "add pepperoni":        (70, 3.0, 0.5, 6.0, 0.0, 230, 15, 2.5, 0.0),
    "extra pepperoni":      (140, 6.0, 1.0, 12.0, 0.0, 460, 30, 5.0, 0.0),
    "add ham":              (50, 8.0, 1.0, 1.5, 0.0, 450, 25, 0.5, 0.0),
    "add salami":           (60, 3.5, 0.5, 5.0, 0.0, 280, 15, 2.0, 0.0),
    "add anchovies":        (25, 4.0, 0.0, 1.0, 0.0, 520, 20, 0.3, 0.0),
    "add tuna":             (60, 13.0, 0.0, 0.5, 0.0, 200, 25, 0.1, 0.0),
    "add salmon":           (80, 12.0, 0.0, 3.5, 0.0, 180, 30, 0.6, 0.0),
    "add smoked salmon":    (65, 10.0, 0.0, 2.5, 0.0, 400, 20, 0.5, 0.0),
    "add prosciutto":       (55, 8.0, 0.0, 2.5, 0.0, 580, 20, 0.8, 0.0),
    "add chorizo":          (130, 7.0, 1.0, 11.0, 0.0, 420, 30, 4.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # CHEESE
    # ═══════════════════════════════════════════════════════════════
    "extra cheese":         (60, 4.0, 0.5, 5.0, 0.0, 180, 18, 3.0, 0.0),
    "add cheese":           (60, 4.0, 0.5, 5.0, 0.0, 180, 18, 3.0, 0.0),
    "with cheese":          (60, 4.0, 0.5, 5.0, 0.0, 180, 18, 3.0, 0.0),
    "double cheese":        (120, 8.0, 1.0, 10.0, 0.0, 360, 36, 6.0, 0.0),
    "cheese on top":        (60, 4.0, 0.5, 5.0, 0.0, 180, 18, 3.0, 0.0),
    "add cheddar":          (70, 4.5, 0.5, 5.5, 0.0, 190, 20, 3.5, 0.0),
    "extra cheddar":        (140, 9.0, 1.0, 11.0, 0.0, 380, 40, 7.0, 0.0),
    "add mozzarella":       (55, 4.0, 0.5, 4.0, 0.0, 140, 15, 2.5, 0.0),
    "extra mozzarella":     (110, 8.0, 1.0, 8.0, 0.0, 280, 30, 5.0, 0.0),
    "add pepper jack":      (65, 4.0, 0.5, 5.0, 0.0, 170, 18, 3.2, 0.0),
    "add swiss":            (60, 4.5, 0.5, 4.5, 0.0, 55, 16, 2.8, 0.0),
    "add american cheese":  (60, 3.5, 1.0, 5.0, 0.0, 270, 15, 3.0, 0.1),
    "add provolone":        (55, 4.0, 0.5, 4.0, 0.0, 150, 14, 2.5, 0.0),
    "add parmesan":         (55, 5.0, 0.5, 3.5, 0.0, 230, 10, 2.2, 0.0),
    "extra parmesan":       (110, 10.0, 1.0, 7.0, 0.0, 460, 20, 4.4, 0.0),
    "add feta":             (40, 2.5, 0.5, 3.0, 0.0, 210, 12, 2.0, 0.0),
    "extra feta":           (80, 5.0, 1.0, 6.0, 0.0, 420, 24, 4.0, 0.0),
    "add goat cheese":      (50, 3.5, 0.0, 4.0, 0.0, 100, 10, 2.5, 0.0),
    "add blue cheese":      (60, 3.5, 0.5, 5.0, 0.0, 240, 14, 3.2, 0.0),
    "add brie":             (55, 3.5, 0.0, 4.5, 0.0, 120, 14, 2.8, 0.0),
    "add ricotta":          (40, 3.0, 1.5, 2.5, 0.0, 60, 12, 1.5, 0.0),
    "add cotija":           (50, 3.0, 1.0, 4.0, 0.0, 200, 15, 2.5, 0.0),
    "add queso fresco":     (45, 3.0, 0.5, 3.5, 0.0, 180, 12, 2.0, 0.0),
    "add paneer":           (60, 4.0, 1.0, 4.5, 0.0, 20, 18, 3.0, 0.0),
    "extra paneer":         (120, 8.0, 2.0, 9.0, 0.0, 40, 36, 6.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & CONDIMENTS — American / Western
    # ═══════════════════════════════════════════════════════════════
    "with ranch":           (70, 0.5, 1.0, 7.0, 0.0, 200, 5, 1.1, 0.0),
    "add ranch":            (70, 0.5, 1.0, 7.0, 0.0, 200, 5, 1.1, 0.0),
    "extra ranch":          (140, 1.0, 2.0, 14.0, 0.0, 400, 10, 2.2, 0.0),
    "with mayo":            (50, 0.0, 0.5, 5.5, 0.0, 55, 4, 0.8, 0.0),
    "extra mayo":           (100, 0.0, 1.0, 11.0, 0.0, 110, 8, 1.6, 0.0),
    "add mayo":             (50, 0.0, 0.5, 5.5, 0.0, 55, 4, 0.8, 0.0),
    "with chipotle mayo":   (60, 0.0, 1.0, 6.0, 0.0, 120, 5, 1.0, 0.0),
    "add chipotle mayo":    (60, 0.0, 1.0, 6.0, 0.0, 120, 5, 1.0, 0.0),
    "with aioli":           (55, 0.0, 0.5, 6.0, 0.0, 80, 5, 0.9, 0.0),
    "add aioli":            (55, 0.0, 0.5, 6.0, 0.0, 80, 5, 0.9, 0.0),
    "with ketchup":         (20, 0.0, 5.0, 0.0, 0.0, 160, 0, 0.0, 0.0),
    "extra ketchup":        (40, 0.0, 10.0, 0.0, 0.0, 320, 0, 0.0, 0.0),
    "with mustard":         (5, 0.3, 0.3, 0.2, 0.0, 60, 0, 0.0, 0.0),
    "with dijon mustard":   (10, 0.5, 0.5, 0.5, 0.0, 120, 0, 0.0, 0.0),
    "with bbq sauce":       (30, 0.0, 7.0, 0.0, 0.0, 250, 0, 0.0, 0.0),
    "add bbq sauce":        (30, 0.0, 7.0, 0.0, 0.0, 250, 0, 0.0, 0.0),
    "extra bbq sauce":      (60, 0.0, 14.0, 0.0, 0.0, 500, 0, 0.0, 0.0),
    "with hot sauce":       (5, 0.0, 1.0, 0.0, 0.0, 200, 0, 0.0, 0.0),
    "extra hot sauce":      (10, 0.0, 2.0, 0.0, 0.0, 400, 0, 0.0, 0.0),
    "with buffalo sauce":   (10, 0.0, 1.0, 0.5, 0.0, 460, 0, 0.1, 0.0),
    "add buffalo sauce":    (10, 0.0, 1.0, 0.5, 0.0, 460, 0, 0.1, 0.0),
    "with honey mustard":   (45, 0.0, 6.0, 2.0, 0.0, 130, 5, 0.3, 0.0),
    "add honey mustard":    (45, 0.0, 6.0, 2.0, 0.0, 130, 5, 0.3, 0.0),
    "with thousand island": (55, 0.0, 3.0, 5.0, 0.0, 170, 8, 0.8, 0.0),
    "add thousand island":  (55, 0.0, 3.0, 5.0, 0.0, 170, 8, 0.8, 0.0),
    "with blue cheese dressing": (75, 0.5, 1.0, 8.0, 0.0, 170, 5, 1.5, 0.0),
    "with caesar dressing": (70, 0.5, 1.0, 7.5, 0.0, 160, 5, 1.2, 0.0),
    "with vinaigrette":     (45, 0.0, 2.0, 4.0, 0.0, 120, 0, 0.5, 0.0),
    "with balsamic":        (15, 0.0, 3.0, 0.0, 0.0, 10, 0, 0.0, 0.0),
    "with olive oil":       (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.0, 0.0),
    "drizzle olive oil":    (60, 0.0, 0.0, 7.0, 0.0, 0, 0, 1.0, 0.0),
    "with gravy":           (40, 1.0, 3.0, 2.5, 0.0, 300, 5, 1.0, 0.0),
    "extra gravy":          (80, 2.0, 6.0, 5.0, 0.0, 600, 10, 2.0, 0.0),
    "with tartar sauce":    (70, 0.0, 2.0, 7.0, 0.0, 200, 5, 1.0, 0.0),
    "add tartar sauce":     (70, 0.0, 2.0, 7.0, 0.0, 200, 5, 1.0, 0.0),
    "with horseradish":     (10, 0.3, 2.0, 0.0, 0.5, 50, 0, 0.0, 0.0),
    "with relish":          (20, 0.0, 5.0, 0.0, 0.0, 120, 0, 0.0, 0.0),
    "with worcestershire":  (5, 0.0, 1.0, 0.0, 0.0, 65, 0, 0.0, 0.0),
    "with a1 sauce":        (15, 0.0, 3.0, 0.0, 0.0, 280, 0, 0.0, 0.0),
    "add a1 sauce":         (15, 0.0, 3.0, 0.0, 0.0, 280, 0, 0.0, 0.0),
    "steak sauce":          (15, 0.0, 3.0, 0.0, 0.0, 280, 0, 0.0, 0.0),
    # ── Steak-specific sauces ──
    "with peppercorn sauce": (70, 1.0, 3.0, 6.0, 0.2, 250, 20, 3.5, 0.1),
    "peppercorn sauce":     (70, 1.0, 3.0, 6.0, 0.2, 250, 20, 3.5, 0.1),
    "with bearnaise":       (90, 1.0, 0.5, 9.5, 0.0, 150, 45, 5.5, 0.1),
    "bearnaise sauce":      (90, 1.0, 0.5, 9.5, 0.0, 150, 45, 5.5, 0.1),
    "with au poivre":       (70, 1.0, 3.0, 6.0, 0.2, 250, 20, 3.5, 0.1),
    "with diane sauce":     (60, 0.5, 2.0, 5.0, 0.1, 200, 15, 3.0, 0.1),
    "diane sauce":          (60, 0.5, 2.0, 5.0, 0.1, 200, 15, 3.0, 0.1),
    "with mushroom sauce":  (40, 1.0, 3.0, 2.5, 0.3, 280, 8, 1.5, 0.0),
    "mushroom sauce":       (40, 1.0, 3.0, 2.5, 0.3, 280, 8, 1.5, 0.0),
    "with red wine sauce":  (35, 0.5, 3.0, 1.5, 0.0, 200, 0, 0.5, 0.0),
    "red wine sauce":       (35, 0.5, 3.0, 1.5, 0.0, 200, 0, 0.5, 0.0),
    "with bordelaise":      (35, 0.5, 3.0, 1.5, 0.0, 200, 0, 0.5, 0.0),
    "with blue cheese sauce": (80, 2.5, 1.0, 7.0, 0.0, 300, 15, 4.5, 0.0),
    "blue cheese sauce":    (80, 2.5, 1.0, 7.0, 0.0, 300, 15, 4.5, 0.0),
    "with gravy":           (30, 1.0, 3.0, 1.5, 0.0, 300, 3, 0.5, 0.0),
    "add gravy":            (30, 1.0, 3.0, 1.5, 0.0, 300, 3, 0.5, 0.0),
    "extra gravy":          (60, 2.0, 6.0, 3.0, 0.0, 600, 6, 1.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # FATS & SPREADS
    # ═══════════════════════════════════════════════════════════════
    "with butter":          (100, 0.0, 0.0, 11.0, 0.0, 90, 30, 7.0, 0.3),
    "garlic butter":        (110, 0.2, 1.0, 12.0, 0.0, 95, 30, 7.5, 0.3),
    "with garlic butter":   (110, 0.2, 1.0, 12.0, 0.0, 95, 30, 7.5, 0.3),
    "herb butter":          (105, 0.1, 0.5, 11.5, 0.0, 90, 30, 7.2, 0.3),
    "with herb butter":     (105, 0.1, 0.5, 11.5, 0.0, 90, 30, 7.2, 0.3),
    "compound butter":      (110, 0.2, 0.5, 12.0, 0.0, 95, 30, 7.5, 0.3),
    "truffle butter":       (115, 0.1, 0.5, 12.5, 0.0, 90, 30, 7.5, 0.3),
    "brown butter":         (105, 0.0, 0.0, 11.5, 0.0, 90, 30, 7.2, 0.3),
    "lemon butter":         (100, 0.0, 0.5, 11.0, 0.0, 85, 30, 7.0, 0.3),
    "extra butter":         (200, 0.0, 0.0, 22.0, 0.0, 180, 60, 14.0, 0.6),
    "add butter":           (100, 0.0, 0.0, 11.0, 0.0, 90, 30, 7.0, 0.3),
    "with ghee":            (110, 0.0, 0.0, 12.5, 0.0, 0, 35, 8.0, 0.0),
    "add ghee":             (110, 0.0, 0.0, 12.5, 0.0, 0, 35, 8.0, 0.0),
    "extra ghee":           (220, 0.0, 0.0, 25.0, 0.0, 0, 70, 16.0, 0.0),
    "with cream cheese":    (50, 1.0, 1.0, 5.0, 0.0, 50, 15, 3.0, 0.0),
    "add cream cheese":     (50, 1.0, 1.0, 5.0, 0.0, 50, 15, 3.0, 0.0),
    "extra cream cheese":   (100, 2.0, 2.0, 10.0, 0.0, 100, 30, 6.0, 0.0),
    "with peanut butter":   (95, 4.0, 3.0, 8.0, 1.0, 75, 0, 1.5, 0.0),
    "add peanut butter":    (95, 4.0, 3.0, 8.0, 1.0, 75, 0, 1.5, 0.0),
    "with almond butter":   (100, 3.5, 3.0, 9.0, 1.5, 35, 0, 0.8, 0.0),
    "with nutella":         (100, 1.0, 11.0, 6.0, 0.5, 15, 0, 2.0, 0.0),
    "add nutella":          (100, 1.0, 11.0, 6.0, 0.5, 15, 0, 2.0, 0.0),
    "with jam":             (50, 0.0, 13.0, 0.0, 0.0, 5, 0, 0.0, 0.0),
    "with jelly":           (50, 0.0, 13.0, 0.0, 0.0, 5, 0, 0.0, 0.0),
    "with marmalade":       (50, 0.0, 13.0, 0.0, 0.3, 8, 0, 0.0, 0.0),
    "with honey":           (65, 0.0, 17.0, 0.0, 0.0, 1, 0, 0.0, 0.0),
    "add honey":            (65, 0.0, 17.0, 0.0, 0.0, 1, 0, 0.0, 0.0),
    "drizzle honey":        (30, 0.0, 8.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "with maple syrup":     (60, 0.0, 15.0, 0.0, 0.0, 5, 0, 0.0, 0.0),
    "with syrup":           (60, 0.0, 15.0, 0.0, 0.0, 15, 0, 0.0, 0.0),
    "add syrup":            (60, 0.0, 15.0, 0.0, 0.0, 15, 0, 0.0, 0.0),
    "with whipped cream":   (50, 0.5, 2.0, 5.0, 0.0, 10, 15, 3.0, 0.0),
    "add whipped cream":    (50, 0.5, 2.0, 5.0, 0.0, 10, 15, 3.0, 0.0),
    "extra whipped cream":  (100, 1.0, 4.0, 10.0, 0.0, 20, 30, 6.0, 0.0),
    "with heavy cream":     (50, 0.5, 0.5, 5.5, 0.0, 5, 20, 3.5, 0.0),
    "add heavy cream":      (50, 0.5, 0.5, 5.5, 0.0, 5, 20, 3.5, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # COOKING OILS (per ~1 tbsp / 14g drizzle)
    # ═══════════════════════════════════════════════════════════════
    "with olive oil":       (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.0, 0.0),
    "drizzle olive oil":    (60, 0.0, 0.0, 7.0, 0.0, 0, 0, 1.0, 0.0),
    "extra olive oil":      (180, 0.0, 0.0, 21.0, 0.0, 0, 0, 3.0, 0.0),
    "cooked in olive oil":  (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 1.3, 0.0),
    "with coconut oil":     (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 12.0, 0.0),
    "cooked in coconut oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 8.0, 0.0),
    "with avocado oil":     (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.6, 0.0),
    "cooked in avocado oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 1.1, 0.0),
    "with vegetable oil":   (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.0, 0.0),
    "cooked in vegetable oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 1.3, 0.0),
    "with canola oil":      (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.0, 0.0),
    "cooked in canola oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 0.7, 0.0),
    "with sunflower oil":   (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.4, 0.0),
    "cooked in sunflower oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 0.9, 0.0),
    "with mustard oil":     (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.6, 0.0),
    "cooked in mustard oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 1.1, 0.0),
    "with peanut oil":      (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.3, 0.0),
    "cooked in peanut oil": (80, 0.0, 0.0, 9.0, 0.0, 0, 0, 1.5, 0.0),
    "with sesame oil":      (40, 0.0, 0.0, 4.5, 0.0, 0, 0, 0.6, 0.0),
    "with gingelly oil":    (40, 0.0, 0.0, 4.5, 0.0, 0, 0, 0.6, 0.0),
    "with truffle oil":     (40, 0.0, 0.0, 4.5, 0.0, 0, 0, 0.6, 0.0),
    "drizzle truffle oil":  (20, 0.0, 0.0, 2.3, 0.0, 0, 0, 0.3, 0.0),
    "with grapeseed oil":   (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.3, 0.0),
    "with rice bran oil":   (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.7, 0.0),
    "with corn oil":        (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.8, 0.0),
    "with soybean oil":     (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 2.1, 0.0),
    "with palm oil":        (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 6.7, 0.0),
    "with walnut oil":      (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.2, 0.0),
    "with flaxseed oil":    (120, 0.0, 0.0, 14.0, 0.0, 0, 0, 1.2, 0.0),
    "with mct oil":         (115, 0.0, 0.0, 14.0, 0.0, 0, 0, 12.0, 0.0),
    "cooked in ghee":       (80, 0.0, 0.0, 9.0, 0.0, 0, 25, 5.5, 0.0),
    "fried in oil":         (100, 0.0, 0.0, 11.0, 0.0, 0, 0, 1.5, 0.0),
    "pan fried":            (60, 0.0, 0.0, 7.0, 0.0, 0, 0, 1.0, 0.0),
    "sauteed":              (50, 0.0, 0.0, 5.5, 0.0, 0, 0, 0.8, 0.0),
    "sauteed in butter":    (80, 0.0, 0.0, 9.0, 0.0, 60, 25, 5.5, 0.2),

    # ═══════════════════════════════════════════════════════════════
    # MORE CHEESES
    # ═══════════════════════════════════════════════════════════════
    "add halloumi":         (80, 6.0, 1.0, 6.0, 0.0, 300, 18, 4.0, 0.0),
    "with halloumi":        (80, 6.0, 1.0, 6.0, 0.0, 300, 18, 4.0, 0.0),
    "add burrata":          (70, 4.0, 0.5, 6.0, 0.0, 80, 20, 4.0, 0.0),
    "with burrata":         (70, 4.0, 0.5, 6.0, 0.0, 80, 20, 4.0, 0.0),
    "add mascarpone":       (60, 1.0, 0.5, 6.0, 0.0, 15, 20, 3.5, 0.0),
    "add gruyere":          (65, 5.0, 0.0, 5.0, 0.0, 120, 18, 3.0, 0.0),
    "add fontina":          (60, 4.0, 0.5, 5.0, 0.0, 150, 16, 3.0, 0.0),
    "add havarti":          (60, 4.0, 0.5, 5.0, 0.0, 180, 15, 3.0, 0.0),
    "add manchego":         (65, 5.0, 0.0, 5.0, 0.0, 200, 16, 3.2, 0.0),
    "add asiago":           (55, 4.5, 0.5, 4.0, 0.0, 200, 12, 2.5, 0.0),
    "add gouda":            (60, 4.0, 0.5, 5.0, 0.0, 150, 16, 3.0, 0.0),
    "add smoked gouda":     (60, 4.0, 0.5, 5.0, 0.0, 170, 16, 3.0, 0.0),
    "add queso oaxaca":     (55, 4.0, 1.0, 4.0, 0.0, 140, 14, 2.5, 0.0),
    "add colby jack":       (60, 3.5, 0.5, 5.0, 0.0, 170, 16, 3.0, 0.0),
    "add muenster":         (55, 3.5, 0.5, 4.5, 0.0, 140, 14, 2.8, 0.0),
    "add camembert":        (55, 3.5, 0.0, 4.5, 0.0, 120, 14, 2.8, 0.0),
    "add raclette":         (65, 5.0, 0.0, 5.0, 0.0, 150, 18, 3.5, 0.0),
    "add cheese sauce":     (70, 2.0, 3.0, 5.5, 0.0, 280, 12, 3.0, 0.1),
    "with cheese sauce":    (70, 2.0, 3.0, 5.5, 0.0, 280, 12, 3.0, 0.1),
    "add nacho cheese":     (55, 1.5, 3.0, 4.0, 0.0, 300, 10, 2.5, 0.1),
    "with nacho cheese":    (55, 1.5, 3.0, 4.0, 0.0, 300, 10, 2.5, 0.1),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES — Mexican Cuisine
    # ═══════════════════════════════════════════════════════════════
    "with sour cream":      (30, 0.5, 1.0, 2.5, 0.0, 15, 8, 1.5, 0.0),
    "add sour cream":       (30, 0.5, 1.0, 2.5, 0.0, 15, 8, 1.5, 0.0),
    "extra sour cream":     (60, 1.0, 2.0, 5.0, 0.0, 30, 16, 3.0, 0.0),
    "with guacamole":       (50, 0.5, 3.0, 4.5, 2.0, 120, 0, 0.6, 0.0),
    "add guac":             (50, 0.5, 3.0, 4.5, 2.0, 120, 0, 0.6, 0.0),
    "add guacamole":        (50, 0.5, 3.0, 4.5, 2.0, 120, 0, 0.6, 0.0),
    "extra guacamole":      (100, 1.0, 6.0, 9.0, 4.0, 240, 0, 1.2, 0.0),
    "extra guac":           (100, 1.0, 6.0, 9.0, 4.0, 240, 0, 1.2, 0.0),
    "with salsa":           (10, 0.5, 2.0, 0.0, 0.5, 220, 0, 0.0, 0.0),
    "add salsa":            (10, 0.5, 2.0, 0.0, 0.5, 220, 0, 0.0, 0.0),
    "extra salsa":          (20, 1.0, 4.0, 0.0, 1.0, 440, 0, 0.0, 0.0),
    "with pico de gallo":   (10, 0.5, 2.0, 0.0, 0.5, 130, 0, 0.0, 0.0),
    "add pico de gallo":    (10, 0.5, 2.0, 0.0, 0.5, 130, 0, 0.0, 0.0),
    "with queso":           (55, 2.0, 2.0, 4.0, 0.0, 280, 12, 2.5, 0.0),
    "add queso":            (55, 2.0, 2.0, 4.0, 0.0, 280, 12, 2.5, 0.0),
    "extra queso":          (110, 4.0, 4.0, 8.0, 0.0, 560, 24, 5.0, 0.0),
    "with crema":           (40, 0.5, 1.0, 4.0, 0.0, 10, 12, 2.5, 0.0),
    "add crema":            (40, 0.5, 1.0, 4.0, 0.0, 10, 12, 2.5, 0.0),
    "with chipotle":        (10, 0.3, 2.0, 0.0, 0.5, 150, 0, 0.0, 0.0),
    "add chipotle":         (10, 0.3, 2.0, 0.0, 0.5, 150, 0, 0.0, 0.0),
    "with mole":            (60, 1.5, 5.0, 4.0, 1.0, 200, 0, 1.0, 0.0),
    "with verde sauce":     (15, 0.5, 2.0, 0.5, 0.5, 180, 0, 0.0, 0.0),
    "with enchilada sauce": (20, 0.5, 3.0, 0.5, 0.5, 250, 0, 0.1, 0.0),
    "add beans":            (60, 4.0, 10.0, 0.5, 3.0, 200, 0, 0.1, 0.0),
    "extra beans":          (120, 8.0, 20.0, 1.0, 6.0, 400, 0, 0.2, 0.0),
    "add black beans":      (60, 4.0, 10.0, 0.5, 3.5, 120, 0, 0.1, 0.0),
    "add refried beans":    (70, 4.0, 10.0, 1.5, 3.0, 350, 2, 0.5, 0.0),
    "add rice":             (70, 1.5, 15.0, 0.5, 0.5, 200, 0, 0.1, 0.0),
    "extra rice":           (140, 3.0, 30.0, 1.0, 1.0, 400, 0, 0.2, 0.0),
    "add cilantro lime rice": (80, 1.5, 16.0, 1.5, 0.5, 150, 0, 0.2, 0.0),
    "with corn tortilla":   (50, 1.0, 10.0, 0.5, 1.5, 10, 0, 0.1, 0.0),
    "with flour tortilla":  (90, 2.5, 15.0, 2.5, 1.0, 200, 0, 0.5, 0.0),
    "extra tortilla":       (90, 2.5, 15.0, 2.5, 1.0, 200, 0, 0.5, 0.0),
    "with chips":           (140, 2.0, 18.0, 7.0, 1.0, 120, 0, 1.0, 0.0),
    "add chips":            (140, 2.0, 18.0, 7.0, 1.0, 120, 0, 1.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Indian Cuisine
    # ═══════════════════════════════════════════════════════════════
    "with raita":           (30, 1.5, 2.0, 1.5, 0.0, 80, 5, 1.0, 0.0),
    "add raita":            (30, 1.5, 2.0, 1.5, 0.0, 80, 5, 1.0, 0.0),
    "with chutney":         (25, 0.3, 5.0, 0.5, 0.5, 100, 0, 0.0, 0.0),
    "add chutney":          (25, 0.3, 5.0, 0.5, 0.5, 100, 0, 0.0, 0.0),
    "with mint chutney":    (15, 0.5, 2.0, 0.5, 0.5, 150, 0, 0.0, 0.0),
    "add mint chutney":     (15, 0.5, 2.0, 0.5, 0.5, 150, 0, 0.0, 0.0),
    "with tamarind chutney": (30, 0.2, 7.0, 0.0, 0.5, 80, 0, 0.0, 0.0),
    "with coconut chutney": (40, 1.0, 3.0, 3.0, 1.0, 60, 0, 2.5, 0.0),
    "add coconut chutney":  (40, 1.0, 3.0, 3.0, 1.0, 60, 0, 2.5, 0.0),
    "with pickle":          (10, 0.3, 1.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "add pickle":           (10, 0.3, 1.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "with achar":           (10, 0.3, 1.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "with dal":             (80, 5.0, 12.0, 1.5, 3.0, 250, 0, 0.2, 0.0),
    "add dal":              (80, 5.0, 12.0, 1.5, 3.0, 250, 0, 0.2, 0.0),
    "with naan":            (260, 7.0, 45.0, 5.0, 2.0, 430, 0, 1.0, 0.0),
    "add naan":             (260, 7.0, 45.0, 5.0, 2.0, 430, 0, 1.0, 0.0),
    "extra naan":           (260, 7.0, 45.0, 5.0, 2.0, 430, 0, 1.0, 0.0),
    "with garlic naan":     (300, 8.0, 48.0, 8.0, 2.0, 480, 5, 2.0, 0.0),
    "add garlic naan":      (300, 8.0, 48.0, 8.0, 2.0, 480, 5, 2.0, 0.0),
    "with roti":            (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "add roti":             (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "extra roti":           (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "with paratha":         (180, 4.0, 25.0, 7.0, 2.0, 250, 0, 1.5, 0.0),
    "add paratha":          (180, 4.0, 25.0, 7.0, 2.0, 250, 0, 1.5, 0.0),
    "with papad":           (40, 2.0, 5.0, 1.5, 1.0, 300, 0, 0.2, 0.0),
    "add papad":            (40, 2.0, 5.0, 1.5, 1.0, 300, 0, 0.2, 0.0),
    "with sambar":          (50, 3.0, 8.0, 1.0, 2.0, 400, 0, 0.2, 0.0),
    "add sambar":           (50, 3.0, 8.0, 1.0, 2.0, 400, 0, 0.2, 0.0),
    "with curry sauce":     (60, 1.5, 4.0, 4.5, 0.5, 350, 0, 1.5, 0.0),
    "add curry sauce":      (60, 1.5, 4.0, 4.5, 0.5, 350, 0, 1.5, 0.0),
    "extra curry":          (120, 3.0, 8.0, 9.0, 1.0, 700, 0, 3.0, 0.0),
    "with masala":          (50, 1.0, 3.0, 4.0, 0.5, 300, 0, 1.0, 0.0),
    "extra masala":         (100, 2.0, 6.0, 8.0, 1.0, 600, 0, 2.0, 0.0),
    "with tadka":           (60, 0.5, 1.0, 6.0, 0.0, 100, 0, 1.0, 0.0),
    "add tadka":            (60, 0.5, 1.0, 6.0, 0.0, 100, 0, 1.0, 0.0),
    "with basmati rice":    (130, 3.0, 28.0, 0.5, 0.5, 5, 0, 0.1, 0.0),
    "add basmati rice":     (130, 3.0, 28.0, 0.5, 0.5, 5, 0, 0.1, 0.0),
    "with jeera rice":      (150, 3.0, 28.0, 2.5, 0.5, 200, 0, 0.5, 0.0),
    "add jeera rice":       (150, 3.0, 28.0, 2.5, 0.5, 200, 0, 0.5, 0.0),
    "with biryani rice":    (180, 4.0, 30.0, 5.0, 1.0, 350, 5, 1.5, 0.0),
    # More chutneys
    "with palli chutney":   (45, 2.0, 3.0, 3.0, 0.5, 120, 0, 0.5, 0.0),
    "add palli chutney":    (45, 2.0, 3.0, 3.0, 0.5, 120, 0, 0.5, 0.0),
    "with peanut chutney":  (45, 2.0, 3.0, 3.0, 0.5, 120, 0, 0.5, 0.0),
    "add peanut chutney":   (45, 2.0, 3.0, 3.0, 0.5, 120, 0, 0.5, 0.0),
    "with tomato chutney":  (20, 0.3, 4.0, 0.5, 0.5, 100, 0, 0.0, 0.0),
    "add tomato chutney":   (20, 0.3, 4.0, 0.5, 0.5, 100, 0, 0.0, 0.0),
    "with ginger chutney":  (15, 0.2, 3.0, 0.3, 0.3, 80, 0, 0.0, 0.0),
    "with onion chutney":   (20, 0.3, 4.0, 0.5, 0.5, 90, 0, 0.0, 0.0),
    "add onion chutney":    (20, 0.3, 4.0, 0.5, 0.5, 90, 0, 0.0, 0.0),
    "with garlic chutney":  (20, 0.3, 3.0, 0.5, 0.3, 100, 0, 0.0, 0.0),
    "add garlic chutney":   (20, 0.3, 3.0, 0.5, 0.3, 100, 0, 0.0, 0.0),
    "with red chutney":     (20, 0.3, 3.0, 1.0, 0.5, 120, 0, 0.1, 0.0),
    "with green chutney":   (15, 0.5, 2.0, 0.5, 0.5, 150, 0, 0.0, 0.0),
    "add green chutney":    (15, 0.5, 2.0, 0.5, 0.5, 150, 0, 0.0, 0.0),
    "with coriander chutney": (15, 0.5, 2.0, 0.5, 0.5, 130, 0, 0.0, 0.0),
    # More raita types
    "with boondi raita":    (40, 2.0, 4.0, 2.0, 0.0, 100, 5, 1.0, 0.0),
    "add boondi raita":     (40, 2.0, 4.0, 2.0, 0.0, 100, 5, 1.0, 0.0),
    "with onion raita":     (30, 1.5, 2.5, 1.5, 0.0, 80, 5, 0.8, 0.0),
    "with cucumber raita":  (25, 1.5, 2.0, 1.0, 0.2, 70, 4, 0.6, 0.0),
    "with curd":            (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "add curd":             (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "with dahi":            (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "add dahi":             (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "with yogurt":          (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "add yogurt":           (30, 1.5, 2.0, 1.5, 0.0, 25, 5, 1.0, 0.0),
    "with greek yogurt":    (35, 3.0, 2.0, 1.5, 0.0, 20, 5, 0.8, 0.0),
    "add greek yogurt":     (35, 3.0, 2.0, 1.5, 0.0, 20, 5, 0.8, 0.0),
    # More Indian breads
    "with chapati":         (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "add chapati":          (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "extra chapati":        (120, 3.5, 20.0, 3.5, 2.0, 200, 0, 0.5, 0.0),
    "with kulcha":          (200, 5.0, 32.0, 6.0, 1.5, 350, 0, 1.0, 0.0),
    "add kulcha":           (200, 5.0, 32.0, 6.0, 1.5, 350, 0, 1.0, 0.0),
    "with bhatura":         (250, 5.0, 35.0, 10.0, 1.5, 300, 0, 2.0, 0.0),
    "add bhatura":          (250, 5.0, 35.0, 10.0, 1.5, 300, 0, 2.0, 0.0),
    "with puri":            (120, 2.5, 15.0, 6.0, 1.0, 150, 0, 1.0, 0.0),
    "add puri":             (120, 2.5, 15.0, 6.0, 1.0, 150, 0, 1.0, 0.0),
    "with appam":           (80, 1.5, 15.0, 1.5, 0.5, 80, 0, 0.5, 0.0),
    "with dosa":            (130, 3.5, 20.0, 4.0, 1.0, 200, 0, 1.0, 0.0),
    "add dosa":             (130, 3.5, 20.0, 4.0, 1.0, 200, 0, 1.0, 0.0),
    "with idli":            (60, 2.0, 12.0, 0.5, 0.5, 150, 0, 0.1, 0.0),
    "add idli":             (60, 2.0, 12.0, 0.5, 0.5, 150, 0, 0.1, 0.0),
    # South Indian specific
    "with rasam":           (30, 1.0, 5.0, 0.5, 1.0, 350, 0, 0.1, 0.0),
    "add rasam":            (30, 1.0, 5.0, 0.5, 1.0, 350, 0, 0.1, 0.0),
    "with podi":            (20, 1.0, 2.0, 1.0, 0.5, 200, 0, 0.2, 0.0),
    "with gun powder":      (20, 1.0, 2.0, 1.0, 0.5, 200, 0, 0.2, 0.0),
    "with molaga podi":     (20, 1.0, 2.0, 1.0, 0.5, 200, 0, 0.2, 0.0),
    "with kootu curry":     (60, 3.0, 8.0, 2.0, 2.0, 280, 0, 1.0, 0.0),
    "with avial":           (70, 2.0, 6.0, 4.0, 2.0, 250, 0, 2.5, 0.0),
    "with pachadi":         (25, 1.0, 3.0, 1.0, 0.5, 100, 0, 0.5, 0.0),
    "with thoran":          (40, 1.5, 4.0, 2.0, 1.5, 150, 0, 1.0, 0.0),
    # Indian protein add-ons
    "add chicken tikka":    (140, 22.0, 3.0, 4.5, 0.0, 400, 65, 1.2, 0.0),
    "add tandoori chicken": (130, 22.0, 2.0, 4.0, 0.0, 450, 65, 1.0, 0.0),
    "add paneer tikka":     (100, 7.0, 3.0, 7.0, 0.0, 200, 20, 4.0, 0.0),
    "add seekh kebab":      (120, 10.0, 3.0, 8.0, 0.5, 350, 35, 3.0, 0.0),
    "add lamb keema":       (130, 10.0, 2.0, 9.0, 0.0, 300, 40, 3.5, 0.0),
    "add chicken keema":    (100, 14.0, 2.0, 4.5, 0.0, 280, 45, 1.2, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Chinese / East Asian
    # ═══════════════════════════════════════════════════════════════
    "with soy sauce":       (10, 1.0, 1.0, 0.0, 0.0, 900, 0, 0.0, 0.0),
    "add soy sauce":        (10, 1.0, 1.0, 0.0, 0.0, 900, 0, 0.0, 0.0),
    "extra soy sauce":      (20, 2.0, 2.0, 0.0, 0.0, 1800, 0, 0.0, 0.0),
    "with teriyaki sauce":  (30, 0.5, 6.0, 0.0, 0.0, 610, 0, 0.0, 0.0),
    "add teriyaki sauce":   (30, 0.5, 6.0, 0.0, 0.0, 610, 0, 0.0, 0.0),
    "with sweet and sour sauce": (35, 0.0, 8.0, 0.0, 0.0, 150, 0, 0.0, 0.0),
    "with hoisin sauce":    (35, 0.5, 7.0, 0.5, 0.3, 260, 0, 0.1, 0.0),
    "add hoisin sauce":     (35, 0.5, 7.0, 0.5, 0.3, 260, 0, 0.1, 0.0),
    "with oyster sauce":    (15, 0.5, 3.0, 0.0, 0.0, 490, 0, 0.0, 0.0),
    "add oyster sauce":     (15, 0.5, 3.0, 0.0, 0.0, 490, 0, 0.0, 0.0),
    "with sriracha":        (10, 0.0, 2.0, 0.0, 0.0, 200, 0, 0.0, 0.0),
    "add sriracha":         (10, 0.0, 2.0, 0.0, 0.0, 200, 0, 0.0, 0.0),
    "extra sriracha":       (20, 0.0, 4.0, 0.0, 0.0, 400, 0, 0.0, 0.0),
    "with chili oil":       (45, 0.0, 0.0, 5.0, 0.0, 5, 0, 0.5, 0.0),
    "add chili oil":        (45, 0.0, 0.0, 5.0, 0.0, 5, 0, 0.5, 0.0),
    "with chili garlic sauce": (10, 0.0, 2.0, 0.0, 0.3, 230, 0, 0.0, 0.0),
    "with sambal":          (10, 0.3, 2.0, 0.0, 0.5, 180, 0, 0.0, 0.0),
    "with fish sauce":      (10, 1.5, 0.5, 0.0, 0.0, 1400, 0, 0.0, 0.0),
    "add fish sauce":       (10, 1.5, 0.5, 0.0, 0.0, 1400, 0, 0.0, 0.0),
    "with plum sauce":      (35, 0.0, 8.0, 0.0, 0.0, 100, 0, 0.0, 0.0),
    "with duck sauce":      (40, 0.0, 10.0, 0.0, 0.0, 120, 0, 0.0, 0.0),
    "with szechuan sauce":  (25, 0.5, 4.0, 1.0, 0.0, 350, 0, 0.1, 0.0),
    "with peanut sauce":    (60, 2.0, 4.0, 4.0, 0.5, 250, 0, 0.7, 0.0),
    "add peanut sauce":     (60, 2.0, 4.0, 4.0, 0.5, 250, 0, 0.7, 0.0),
    "with sesame oil":      (40, 0.0, 0.0, 4.5, 0.0, 0, 0, 0.6, 0.0),
    "with fried rice":      (130, 3.0, 20.0, 4.0, 0.5, 450, 25, 0.8, 0.0),
    "add fried rice":       (130, 3.0, 20.0, 4.0, 0.5, 450, 25, 0.8, 0.0),
    "with steamed rice":    (100, 2.0, 22.0, 0.2, 0.3, 5, 0, 0.0, 0.0),
    "add steamed rice":     (100, 2.0, 22.0, 0.2, 0.3, 5, 0, 0.0, 0.0),
    "with lo mein noodles": (120, 3.5, 20.0, 2.5, 1.0, 200, 10, 0.5, 0.0),
    "add noodles":          (110, 3.0, 20.0, 1.5, 1.0, 5, 0, 0.3, 0.0),
    "extra noodles":        (220, 6.0, 40.0, 3.0, 2.0, 10, 0, 0.6, 0.0),
    "with wontons":         (80, 3.0, 10.0, 3.0, 0.5, 200, 15, 0.8, 0.0),
    "add wontons":          (80, 3.0, 10.0, 3.0, 0.5, 200, 15, 0.8, 0.0),
    "with spring roll":     (100, 2.5, 12.0, 5.0, 1.0, 220, 5, 1.0, 0.0),
    "add spring roll":      (100, 2.5, 12.0, 5.0, 1.0, 220, 5, 1.0, 0.0),
    "with egg roll":        (120, 3.5, 14.0, 5.5, 1.0, 280, 15, 1.2, 0.0),
    "add egg roll":         (120, 3.5, 14.0, 5.5, 1.0, 280, 15, 1.2, 0.0),
    "with dim sum":         (70, 3.0, 8.0, 3.0, 0.5, 200, 10, 0.8, 0.0),
    "add tofu":             (40, 4.0, 1.0, 2.5, 0.5, 10, 0, 0.3, 0.0),
    "extra tofu":           (80, 8.0, 2.0, 5.0, 1.0, 20, 0, 0.6, 0.0),
    "with crispy tofu":     (70, 4.0, 4.0, 4.5, 0.5, 120, 0, 0.6, 0.0),
    "add edamame":          (60, 5.0, 4.0, 2.5, 2.0, 5, 0, 0.3, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Japanese
    # ═══════════════════════════════════════════════════════════════
    "with wasabi":          (5, 0.0, 1.0, 0.0, 0.3, 120, 0, 0.0, 0.0),
    "add wasabi":           (5, 0.0, 1.0, 0.0, 0.3, 120, 0, 0.0, 0.0),
    "extra wasabi":         (10, 0.0, 2.0, 0.0, 0.5, 240, 0, 0.0, 0.0),
    "with pickled ginger":  (5, 0.0, 1.0, 0.0, 0.0, 60, 0, 0.0, 0.0),
    "with miso":            (20, 1.5, 2.0, 0.5, 0.5, 420, 0, 0.1, 0.0),
    "add miso":             (20, 1.5, 2.0, 0.5, 0.5, 420, 0, 0.1, 0.0),
    "with ponzu":           (10, 0.5, 2.0, 0.0, 0.0, 400, 0, 0.0, 0.0),
    "with tempura batter":  (80, 1.5, 10.0, 4.0, 0.3, 150, 10, 0.5, 0.0),
    "add tempura":          (80, 1.5, 10.0, 4.0, 0.3, 150, 10, 0.5, 0.0),
    "with furikake":        (10, 0.5, 1.0, 0.5, 0.0, 80, 5, 0.1, 0.0),
    "with tonkatsu sauce":  (20, 0.2, 4.0, 0.0, 0.0, 310, 0, 0.0, 0.0),
    "with seaweed":         (5, 0.5, 0.5, 0.0, 0.5, 120, 0, 0.0, 0.0),
    "add seaweed":          (5, 0.5, 0.5, 0.0, 0.5, 120, 0, 0.0, 0.0),
    "with nori":            (5, 0.5, 0.5, 0.0, 0.5, 50, 0, 0.0, 0.0),
    "with spicy mayo":      (55, 0.0, 1.0, 6.0, 0.0, 100, 5, 0.9, 0.0),
    "add spicy mayo":       (55, 0.0, 1.0, 6.0, 0.0, 100, 5, 0.9, 0.0),
    "with eel sauce":       (30, 0.3, 6.0, 0.0, 0.0, 280, 0, 0.0, 0.0),
    "with yuzu":            (5, 0.0, 1.0, 0.0, 0.0, 2, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Korean
    # ═══════════════════════════════════════════════════════════════
    "with gochujang":       (20, 0.5, 4.0, 0.5, 0.5, 350, 0, 0.1, 0.0),
    "add gochujang":        (20, 0.5, 4.0, 0.5, 0.5, 350, 0, 0.1, 0.0),
    "with kimchi":          (10, 0.5, 2.0, 0.0, 1.0, 350, 0, 0.0, 0.0),
    "add kimchi":           (10, 0.5, 2.0, 0.0, 1.0, 350, 0, 0.0, 0.0),
    "extra kimchi":         (20, 1.0, 4.0, 0.0, 2.0, 700, 0, 0.0, 0.0),
    "with bulgogi sauce":   (35, 0.5, 6.0, 1.0, 0.0, 350, 0, 0.2, 0.0),
    "with ssamjang":        (25, 1.0, 3.0, 1.0, 0.5, 300, 0, 0.2, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Thai / Southeast Asian
    # ═══════════════════════════════════════════════════════════════
    "with coconut milk":    (50, 0.5, 1.0, 5.0, 0.0, 10, 0, 4.5, 0.0),
    "add coconut milk":     (50, 0.5, 1.0, 5.0, 0.0, 10, 0, 4.5, 0.0),
    "extra coconut milk":   (100, 1.0, 2.0, 10.0, 0.0, 20, 0, 9.0, 0.0),
    "with thai basil":      (2, 0.2, 0.3, 0.0, 0.2, 0, 0, 0.0, 0.0),
    "with lemongrass":      (3, 0.1, 0.5, 0.0, 0.2, 2, 0, 0.0, 0.0),
    "with sweet chili sauce": (30, 0.0, 7.0, 0.0, 0.0, 250, 0, 0.0, 0.0),
    "add sweet chili sauce": (30, 0.0, 7.0, 0.0, 0.0, 250, 0, 0.0, 0.0),
    "with nam pla":         (10, 1.5, 0.5, 0.0, 0.0, 1400, 0, 0.0, 0.0),
    "with satay sauce":     (70, 2.5, 5.0, 4.5, 0.5, 280, 0, 0.8, 0.0),
    "with curry paste":     (15, 0.5, 2.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "with green curry":     (60, 1.0, 3.0, 5.0, 0.5, 400, 0, 4.0, 0.0),
    "with red curry":       (55, 1.0, 3.0, 4.5, 0.5, 380, 0, 3.5, 0.0),
    "with pad thai sauce":  (40, 0.5, 8.0, 1.0, 0.0, 500, 0, 0.1, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Mediterranean / Middle Eastern
    # ═══════════════════════════════════════════════════════════════
    "with hummus":          (50, 2.0, 4.0, 3.0, 1.5, 120, 0, 0.4, 0.0),
    "add hummus":           (50, 2.0, 4.0, 3.0, 1.5, 120, 0, 0.4, 0.0),
    "extra hummus":         (100, 4.0, 8.0, 6.0, 3.0, 240, 0, 0.8, 0.0),
    "with tzatziki":        (25, 1.0, 2.0, 1.5, 0.0, 100, 3, 0.8, 0.0),
    "add tzatziki":         (25, 1.0, 2.0, 1.5, 0.0, 100, 3, 0.8, 0.0),
    "with tahini":          (45, 1.5, 1.5, 4.0, 0.5, 20, 0, 0.6, 0.0),
    "add tahini":           (45, 1.5, 1.5, 4.0, 0.5, 20, 0, 0.6, 0.0),
    "extra tahini":         (90, 3.0, 3.0, 8.0, 1.0, 40, 0, 1.2, 0.0),
    "with baba ganoush":    (40, 1.0, 3.0, 3.0, 1.0, 150, 0, 0.4, 0.0),
    "add baba ganoush":     (40, 1.0, 3.0, 3.0, 1.0, 150, 0, 0.4, 0.0),
    "with harissa":         (15, 0.5, 2.0, 0.5, 0.5, 130, 0, 0.1, 0.0),
    "add harissa":          (15, 0.5, 2.0, 0.5, 0.5, 130, 0, 0.1, 0.0),
    "with labneh":          (35, 2.0, 1.5, 2.5, 0.0, 60, 8, 1.5, 0.0),
    "add labneh":           (35, 2.0, 1.5, 2.5, 0.0, 60, 8, 1.5, 0.0),
    "with pita":            (165, 5.5, 33.0, 0.7, 1.3, 320, 0, 0.1, 0.0),
    "add pita":             (165, 5.5, 33.0, 0.7, 1.3, 320, 0, 0.1, 0.0),
    "extra pita":           (165, 5.5, 33.0, 0.7, 1.3, 320, 0, 0.1, 0.0),
    "with tabbouleh":       (40, 1.0, 5.0, 2.0, 1.0, 120, 0, 0.3, 0.0),
    "add tabbouleh":        (40, 1.0, 5.0, 2.0, 1.0, 120, 0, 0.3, 0.0),
    "with fattoush":        (50, 1.0, 6.0, 2.5, 1.0, 150, 0, 0.3, 0.0),
    "with za'atar":         (10, 0.3, 1.0, 0.5, 0.3, 2, 0, 0.1, 0.0),
    "with dukkah":          (30, 1.0, 2.0, 2.5, 0.5, 5, 0, 0.3, 0.0),
    "with sumac":           (5, 0.1, 1.0, 0.0, 0.3, 2, 0, 0.0, 0.0),
    "with falafel":         (60, 2.5, 6.0, 3.0, 1.5, 150, 0, 0.4, 0.0),
    "add falafel":          (60, 2.5, 6.0, 3.0, 1.5, 150, 0, 0.4, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SAUCES & ADD-ONS — Italian
    # ═══════════════════════════════════════════════════════════════
    "with marinara":        (35, 1.0, 5.0, 1.0, 1.0, 300, 0, 0.1, 0.0),
    "add marinara":         (35, 1.0, 5.0, 1.0, 1.0, 300, 0, 0.1, 0.0),
    "extra marinara":       (70, 2.0, 10.0, 2.0, 2.0, 600, 0, 0.2, 0.0),
    "with alfredo sauce":   (100, 2.0, 3.0, 9.0, 0.0, 350, 25, 5.5, 0.0),
    "add alfredo sauce":    (100, 2.0, 3.0, 9.0, 0.0, 350, 25, 5.5, 0.0),
    "extra alfredo":        (200, 4.0, 6.0, 18.0, 0.0, 700, 50, 11.0, 0.0),
    "with pesto":           (80, 2.0, 1.5, 8.0, 0.5, 230, 3, 1.5, 0.0),
    "add pesto":            (80, 2.0, 1.5, 8.0, 0.5, 230, 3, 1.5, 0.0),
    "extra pesto":          (160, 4.0, 3.0, 16.0, 1.0, 460, 6, 3.0, 0.0),
    "with bolognese":       (80, 5.0, 4.0, 5.0, 0.5, 350, 20, 2.0, 0.0),
    "with vodka sauce":     (70, 1.5, 4.0, 5.5, 0.3, 280, 15, 3.0, 0.0),
    "with arrabbiata":      (40, 1.0, 5.0, 1.5, 1.0, 300, 0, 0.2, 0.0),
    "with carbonara":       (100, 4.0, 2.0, 8.0, 0.0, 320, 50, 3.5, 0.0),
    "add meatball":         (80, 6.0, 3.0, 5.0, 0.3, 250, 25, 2.0, 0.1),
    "extra meatball":       (80, 6.0, 3.0, 5.0, 0.3, 250, 25, 2.0, 0.1),
    "add meatballs":        (160, 12.0, 6.0, 10.0, 0.5, 500, 50, 4.0, 0.2),
    "with bruschetta":      (60, 1.5, 7.0, 3.0, 0.5, 150, 0, 0.4, 0.0),
    "add bruschetta":       (60, 1.5, 7.0, 3.0, 0.5, 150, 0, 0.4, 0.0),
    "with garlic bread":    (100, 2.0, 12.0, 5.0, 0.5, 200, 5, 1.5, 0.0),
    "add garlic bread":     (100, 2.0, 12.0, 5.0, 0.5, 200, 5, 1.5, 0.0),
    "with breadsticks":     (140, 4.0, 22.0, 4.0, 1.0, 280, 0, 1.0, 0.0),
    "add breadstick":       (70, 2.0, 11.0, 2.0, 0.5, 140, 0, 0.5, 0.0),
    "with focaccia":        (120, 3.0, 16.0, 5.0, 1.0, 250, 0, 0.8, 0.0),
    "with sun dried tomatoes": (20, 0.5, 3.0, 1.0, 0.5, 80, 0, 0.1, 0.0),
    "add basil":            (2, 0.1, 0.2, 0.0, 0.1, 0, 0, 0.0, 0.0),
    "with capers":          (5, 0.2, 0.5, 0.2, 0.3, 250, 0, 0.0, 0.0),
    "with artichoke":       (15, 1.0, 3.0, 0.0, 1.5, 80, 0, 0.0, 0.0),
    "add italian sausage":  (160, 8.0, 1.0, 14.0, 0.0, 420, 40, 5.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # VEGETABLES & TOPPINGS
    # ═══════════════════════════════════════════════════════════════
    "add avocado":          (80, 1.0, 4.0, 7.0, 3.0, 5, 0, 1.0, 0.0),
    "extra avocado":        (80, 1.0, 4.0, 7.0, 3.0, 5, 0, 1.0, 0.0),
    "with avocado":         (80, 1.0, 4.0, 7.0, 3.0, 5, 0, 1.0, 0.0),
    "add jalapenos":        (5, 0.2, 1.0, 0.0, 0.5, 1, 0, 0.0, 0.0),
    "extra jalapenos":      (10, 0.4, 2.0, 0.0, 1.0, 2, 0, 0.0, 0.0),
    "add onions":           (10, 0.3, 2.5, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "extra onions":         (20, 0.6, 5.0, 0.0, 1.0, 4, 0, 0.0, 0.0),
    "add grilled onions":   (15, 0.3, 3.0, 0.5, 0.5, 5, 0, 0.1, 0.0),
    "add caramelized onions": (25, 0.3, 5.0, 0.5, 0.5, 10, 0, 0.1, 0.0),
    "add pickles":          (5, 0.0, 1.0, 0.0, 0.5, 280, 0, 0.0, 0.0),
    "extra pickles":        (5, 0.0, 1.0, 0.0, 0.5, 280, 0, 0.0, 0.0),
    "add tomato":           (5, 0.2, 1.0, 0.0, 0.3, 2, 0, 0.0, 0.0),
    "extra tomato":         (10, 0.4, 2.0, 0.0, 0.6, 4, 0, 0.0, 0.0),
    "add lettuce":          (3, 0.2, 0.5, 0.0, 0.3, 2, 0, 0.0, 0.0),
    "extra lettuce":        (5, 0.3, 1.0, 0.0, 0.5, 4, 0, 0.0, 0.0),
    "add spinach":          (7, 0.9, 1.0, 0.0, 0.7, 25, 0, 0.0, 0.0),
    "extra spinach":        (14, 1.8, 2.0, 0.0, 1.4, 50, 0, 0.0, 0.0),
    "add arugula":          (5, 0.5, 0.7, 0.0, 0.3, 5, 0, 0.0, 0.0),
    "add kale":             (10, 0.9, 1.5, 0.2, 0.5, 10, 0, 0.0, 0.0),
    "mushrooms":            (10, 1.0, 1.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "add mushrooms":        (10, 1.0, 1.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "with mushrooms":       (10, 1.0, 1.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "sauteed mushrooms":    (25, 1.0, 1.5, 1.5, 0.5, 15, 0, 0.2, 0.0),
    "grilled mushrooms":    (15, 1.0, 1.0, 0.5, 0.5, 5, 0, 0.1, 0.0),
    "extra mushrooms":      (20, 2.0, 2.0, 0.0, 1.0, 4, 0, 0.0, 0.0),
    "add olives":           (15, 0.0, 1.0, 1.5, 0.5, 230, 0, 0.2, 0.0),
    "extra olives":         (30, 0.0, 2.0, 3.0, 1.0, 460, 0, 0.4, 0.0),
    "add bell peppers":     (10, 0.3, 2.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "add green peppers":    (10, 0.3, 2.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "add red peppers":      (10, 0.3, 2.0, 0.0, 0.5, 2, 0, 0.0, 0.0),
    "add roasted peppers":  (15, 0.3, 3.0, 0.5, 0.5, 5, 0, 0.0, 0.0),
    "add banana peppers":   (5, 0.2, 1.0, 0.0, 0.5, 100, 0, 0.0, 0.0),
    "add cucumbers":        (5, 0.2, 1.0, 0.0, 0.3, 2, 0, 0.0, 0.0),
    "add corn":             (30, 1.0, 6.0, 0.5, 0.8, 5, 0, 0.1, 0.0),
    "add pineapple":        (20, 0.2, 5.0, 0.0, 0.5, 1, 0, 0.0, 0.0),
    "add coleslaw":         (60, 0.5, 8.0, 3.0, 1.0, 120, 5, 0.4, 0.0),
    "add sauerkraut":       (10, 0.5, 2.0, 0.0, 1.5, 400, 0, 0.0, 0.0),
    "add sun dried tomato": (20, 0.5, 3.0, 1.0, 0.5, 80, 0, 0.1, 0.0),
    "add roasted garlic":   (15, 0.3, 3.0, 0.0, 0.1, 2, 0, 0.0, 0.0),
    "add fresh garlic":     (5, 0.2, 1.0, 0.0, 0.1, 1, 0, 0.0, 0.0),
    "add cilantro":         (1, 0.1, 0.2, 0.0, 0.1, 2, 0, 0.0, 0.0),
    "add fresh herbs":      (3, 0.2, 0.3, 0.0, 0.2, 2, 0, 0.0, 0.0),
    "add sprouts":          (10, 1.0, 1.5, 0.0, 0.5, 5, 0, 0.0, 0.0),
    "add bean sprouts":     (10, 1.0, 1.5, 0.0, 0.5, 5, 0, 0.0, 0.0),
    "add pickled onions":   (10, 0.2, 2.0, 0.0, 0.3, 250, 0, 0.0, 0.0),
    "add pickled vegetables": (10, 0.3, 2.0, 0.0, 0.5, 300, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # NUTS, SEEDS & CRUNCHY TOPPINGS
    # ═══════════════════════════════════════════════════════════════
    "add walnuts":          (50, 1.5, 1.0, 5.0, 0.5, 0, 0, 0.5, 0.0),
    "add almonds":          (40, 1.5, 1.5, 3.5, 0.5, 0, 0, 0.3, 0.0),
    "add cashews":          (45, 1.5, 2.5, 3.5, 0.3, 5, 0, 0.6, 0.0),
    "add peanuts":          (50, 2.0, 2.0, 4.0, 0.5, 5, 0, 0.5, 0.0),
    "add pine nuts":        (55, 1.5, 1.0, 5.5, 0.3, 0, 0, 0.4, 0.0),
    "add pecans":           (50, 0.7, 1.0, 5.0, 0.5, 0, 0, 0.4, 0.0),
    "add sesame seeds":     (30, 1.0, 1.0, 2.5, 0.5, 5, 0, 0.3, 0.0),
    "add sunflower seeds":  (35, 1.2, 1.5, 3.0, 0.5, 5, 0, 0.3, 0.0),
    "add chia seeds":       (25, 1.0, 2.0, 1.5, 2.0, 5, 0, 0.2, 0.0),
    "add flax seeds":       (30, 1.0, 1.5, 2.0, 1.5, 5, 0, 0.2, 0.0),
    "add hemp seeds":       (35, 2.0, 0.5, 3.0, 0.5, 5, 0, 0.3, 0.0),
    "add croutons":         (45, 1.0, 6.0, 2.0, 0.3, 100, 0, 0.3, 0.0),
    "extra croutons":       (90, 2.0, 12.0, 4.0, 0.6, 200, 0, 0.6, 0.0),
    "add tortilla strips":  (35, 0.5, 4.0, 2.0, 0.3, 50, 0, 0.3, 0.0),
    "add crispy onions":    (40, 0.5, 5.0, 2.0, 0.3, 80, 0, 0.3, 0.0),
    "add fried shallots":   (40, 0.5, 4.0, 2.5, 0.3, 50, 0, 0.4, 0.0),
    "add breadcrumbs":      (30, 1.0, 5.0, 0.5, 0.3, 60, 0, 0.1, 0.0),
    "add panko":            (35, 1.0, 6.0, 0.5, 0.2, 70, 0, 0.1, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # REMOVAL MODIFIERS (subtract)
    # ═══════════════════════════════════════════════════════════════
    "no cheese":            (-60, -4.0, -0.5, -5.0, 0.0, -180, -18, -3.0, 0.0),
    "without cheese":       (-60, -4.0, -0.5, -5.0, 0.0, -180, -18, -3.0, 0.0),
    "no bun":               (-120, -4.0, -22.0, -2.0, -1.0, -250, 0, -0.5, 0.0),
    "without bun":          (-120, -4.0, -22.0, -2.0, -1.0, -250, 0, -0.5, 0.0),
    "bunless":              (-120, -4.0, -22.0, -2.0, -1.0, -250, 0, -0.5, 0.0),
    "lettuce wrap":         (-100, -3.5, -20.0, -1.5, 0.0, -240, 0, -0.4, 0.0),
    "protein style":        (-100, -3.5, -20.0, -1.5, 0.0, -240, 0, -0.4, 0.0),
    "no mayo":              (-50, 0.0, -0.5, -5.5, 0.0, -55, -4, -0.8, 0.0),
    "without mayo":         (-50, 0.0, -0.5, -5.5, 0.0, -55, -4, -0.8, 0.0),
    "no sauce":             (-30, 0.0, -3.0, -2.0, 0.0, -200, 0, -0.3, 0.0),
    "without sauce":        (-30, 0.0, -3.0, -2.0, 0.0, -200, 0, -0.3, 0.0),
    "light sauce":          (-15, 0.0, -1.5, -1.0, 0.0, -100, 0, -0.2, 0.0),
    "no bacon":             (-45, -3.0, 0.0, -3.5, 0.0, -190, -10, -1.2, 0.0),
    "without bacon":        (-45, -3.0, 0.0, -3.5, 0.0, -190, -10, -1.2, 0.0),
    "no lettuce":           (-3, -0.2, -0.5, 0.0, -0.3, -2, 0, 0.0, 0.0),
    "no onions":            (-10, -0.3, -2.5, 0.0, -0.5, -2, 0, 0.0, 0.0),
    "no onion":             (-10, -0.3, -2.5, 0.0, -0.5, -2, 0, 0.0, 0.0),
    "no pickles":           (-5, 0.0, -1.0, 0.0, -0.5, -280, 0, 0.0, 0.0),
    "no tomato":            (-5, -0.2, -1.0, 0.0, -0.3, -2, 0, 0.0, 0.0),
    "no ketchup":           (-20, 0.0, -5.0, 0.0, 0.0, -160, 0, 0.0, 0.0),
    "no mustard":           (-5, -0.3, -0.3, -0.2, 0.0, -60, 0, 0.0, 0.0),
    "no rice":              (-100, -2.0, -22.0, -0.2, -0.3, -5, 0, 0.0, 0.0),
    "without rice":         (-100, -2.0, -22.0, -0.2, -0.3, -5, 0, 0.0, 0.0),
    "no beans":             (-60, -4.0, -10.0, -0.5, -3.0, -200, 0, -0.1, 0.0),
    "without beans":        (-60, -4.0, -10.0, -0.5, -3.0, -200, 0, -0.1, 0.0),
    "no tortilla":          (-90, -2.5, -15.0, -2.5, -1.0, -200, 0, -0.5, 0.0),
    "no bread":             (-80, -3.0, -15.0, -1.0, -1.0, -150, 0, -0.2, 0.0),
    "without bread":        (-80, -3.0, -15.0, -1.0, -1.0, -150, 0, -0.2, 0.0),
    "no croutons":          (-45, -1.0, -6.0, -2.0, -0.3, -100, 0, -0.3, 0.0),
    "no dressing":          (-70, -0.5, -2.0, -7.0, 0.0, -180, -5, -1.0, 0.0),
    "without dressing":     (-70, -0.5, -2.0, -7.0, 0.0, -180, -5, -1.0, 0.0),
    "light dressing":       (-35, -0.3, -1.0, -3.5, 0.0, -90, -3, -0.5, 0.0),
    "dressing on the side": (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "no butter":            (-100, 0.0, 0.0, -11.0, 0.0, -90, -30, -7.0, -0.3),
    "without butter":       (-100, 0.0, 0.0, -11.0, 0.0, -90, -30, -7.0, -0.3),
    "no oil":               (-40, 0.0, 0.0, -4.5, 0.0, 0, 0, -0.5, 0.0),
    "no sugar":             (-15, 0.0, -4.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "sugar free":           (-15, 0.0, -4.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "no cream":             (-50, -0.5, -0.5, -5.5, 0.0, -5, -20, -3.5, 0.0),
    "skinny":               (-40, 0.0, 5.0, -5.0, 0.0, -10, -15, -3.0, 0.0),
    "no sour cream":        (-30, -0.5, -1.0, -2.5, 0.0, -15, -8, -1.5, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # SIZE / PREPARATION MODIFIERS
    # ═══════════════════════════════════════════════════════════════
    "large":                (150, 2.0, 20.0, 6.0, 0.0, 250, 5, 2.0, 0.0),
    "make it large":        (150, 2.0, 20.0, 6.0, 0.0, 250, 5, 2.0, 0.0),
    "supersize":            (250, 3.0, 35.0, 10.0, 0.0, 400, 10, 3.5, 0.0),
    "extra large":          (250, 3.0, 35.0, 10.0, 0.0, 400, 10, 3.5, 0.0),
    "small":                (-80, -1.0, -10.0, -3.0, 0.0, -120, -3, -1.0, 0.0),
    "make it small":        (-80, -1.0, -10.0, -3.0, 0.0, -120, -3, -1.0, 0.0),
    "half portion":         (-150, -5.0, -15.0, -7.0, -1.0, -200, -10, -2.0, 0.0),
    "loaded":               (200, 5.0, 10.0, 15.0, 0.0, 500, 25, 6.0, 0.0),
    "fully loaded":         (250, 6.0, 12.0, 18.0, 0.0, 600, 30, 7.0, 0.0),
    "deep fried":           (100, 0.0, 8.0, 8.0, 0.0, 200, 0, 1.5, 0.2),
    "fried":                (80, 0.0, 5.0, 6.0, 0.0, 150, 0, 1.0, 0.1),
    "grilled":              (0, 0.0, 0.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "crispy":               (60, 0.0, 5.0, 4.0, 0.0, 120, 0, 0.8, 0.0),
    "extra crispy":         (100, 0.0, 8.0, 7.0, 0.0, 200, 0, 1.3, 0.0),
    "smothered":            (120, 3.0, 4.0, 10.0, 0.0, 400, 20, 4.0, 0.0),
    "stuffed":              (100, 4.0, 6.0, 6.0, 0.0, 300, 15, 2.5, 0.0),
    "wrapped in bacon":     (90, 6.0, 0.0, 7.0, 0.0, 380, 20, 2.4, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # DRINKS — Coffee & Beverage Modifiers
    # ═══════════════════════════════════════════════════════════════
    "with milk":            (15, 1.0, 1.5, 0.5, 0.0, 15, 3, 0.3, 0.0),
    "add milk":             (15, 1.0, 1.5, 0.5, 0.0, 15, 3, 0.3, 0.0),
    "with whole milk":      (20, 1.0, 1.5, 1.0, 0.0, 15, 5, 0.6, 0.0),
    "with skim milk":       (10, 1.0, 1.5, 0.0, 0.0, 15, 1, 0.0, 0.0),
    "with oat milk":        (20, 0.5, 3.0, 0.8, 0.3, 15, 0, 0.1, 0.0),
    "with almond milk":     (8, 0.3, 0.5, 0.5, 0.2, 20, 0, 0.0, 0.0),
    "with soy milk":        (15, 1.0, 1.0, 0.7, 0.2, 15, 0, 0.1, 0.0),
    "with coconut milk":    (35, 0.3, 0.5, 3.5, 0.0, 5, 0, 3.0, 0.0),
    "extra shot":           (5, 0.3, 0.0, 0.0, 0.0, 5, 0, 0.0, 0.0),
    "add extra shot":       (5, 0.3, 0.0, 0.0, 0.0, 5, 0, 0.0, 0.0),
    "double shot":          (10, 0.6, 0.0, 0.0, 0.0, 10, 0, 0.0, 0.0),
    "with caramel":         (25, 0.0, 6.0, 0.5, 0.0, 15, 2, 0.3, 0.0),
    "add caramel":          (25, 0.0, 6.0, 0.5, 0.0, 15, 2, 0.3, 0.0),
    "with vanilla":         (20, 0.0, 5.0, 0.0, 0.0, 2, 0, 0.0, 0.0),
    "add vanilla":          (20, 0.0, 5.0, 0.0, 0.0, 2, 0, 0.0, 0.0),
    "with mocha":           (30, 0.5, 6.0, 1.0, 0.3, 10, 2, 0.5, 0.0),
    "with hazelnut":        (20, 0.0, 5.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "add sugar":            (15, 0.0, 4.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "extra sugar":          (30, 0.0, 8.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "add sweetener":        (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "with chocolate drizzle": (30, 0.5, 5.0, 1.5, 0.3, 5, 1, 0.8, 0.0),
    "add protein powder":   (120, 24.0, 3.0, 1.5, 0.5, 150, 30, 0.5, 0.0),
    "add collagen":         (35, 9.0, 0.0, 0.0, 0.0, 25, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # RESTAURANT-SPECIFIC MODIFIERS
    # ═══════════════════════════════════════════════════════════════
    # Chipotle
    "with sofritas":        (150, 8.0, 9.0, 10.0, 2.0, 560, 0, 1.5, 0.0),
    "add sofritas":         (150, 8.0, 9.0, 10.0, 2.0, 560, 0, 1.5, 0.0),
    "with carnitas":        (210, 23.0, 0.0, 12.0, 0.0, 540, 65, 4.5, 0.0),
    "add carnitas":         (210, 23.0, 0.0, 12.0, 0.0, 540, 65, 4.5, 0.0),
    "with barbacoa":        (170, 24.0, 2.0, 7.0, 0.0, 530, 65, 2.5, 0.0),
    "add barbacoa":         (170, 24.0, 2.0, 7.0, 0.0, 530, 65, 2.5, 0.0),
    "with fajita veggies":  (20, 1.0, 4.0, 0.0, 1.0, 170, 0, 0.0, 0.0),
    "add fajita veggies":   (20, 1.0, 4.0, 0.0, 1.0, 170, 0, 0.0, 0.0),
    "with corn salsa":      (80, 3.0, 15.0, 1.5, 2.0, 330, 0, 0.2, 0.0),
    "with tomato salsa":    (25, 1.0, 4.0, 0.0, 1.0, 500, 0, 0.0, 0.0),
    "with tomatillo salsa": (15, 0.5, 3.0, 0.0, 0.5, 360, 0, 0.0, 0.0),
    "with chipotle honey vinaigrette": (110, 0.0, 7.0, 9.0, 0.0, 180, 0, 1.0, 0.0),

    # Subway
    "with provolone":       (50, 4.0, 0.5, 3.5, 0.0, 140, 10, 2.0, 0.0),
    "toasted":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "on wheat":             (0, 1.0, 2.0, 0.0, 1.0, 0, 0, 0.0, 0.0),
    "on white":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "on italian herbs":     (10, 0.5, 2.0, 0.0, 0.5, 30, 0, 0.0, 0.0),
    "on flatbread":         (-30, -1.0, -8.0, 1.0, -0.5, -50, 0, 0.0, 0.0),
    "as a wrap":            (-20, -0.5, -5.0, 0.5, -0.5, -40, 0, 0.0, 0.0),
    "footlong":             (200, 8.0, 36.0, 3.0, 2.0, 500, 0, 0.5, 0.0),

    # Pizza modifiers
    "thin crust":           (-40, -1.5, -8.0, 0.0, -0.5, -80, 0, 0.0, 0.0),
    "thick crust":          (60, 2.0, 12.0, 1.0, 0.5, 120, 0, 0.2, 0.0),
    "stuffed crust":        (90, 4.0, 10.0, 4.0, 0.5, 200, 15, 2.5, 0.0),
    "deep dish":            (80, 2.5, 14.0, 2.0, 0.5, 150, 0, 0.5, 0.0),
    "cauliflower crust":    (-30, 0.5, -6.0, 0.0, 1.0, -40, 0, 0.0, 0.0),
    "gluten free crust":    (10, -0.5, 2.0, 1.0, 0.0, -20, 0, 0.0, 0.0),
    "extra sauce":          (25, 0.5, 4.0, 0.5, 0.5, 200, 0, 0.1, 0.0),
    "white sauce":          (80, 2.0, 3.0, 7.0, 0.0, 250, 15, 4.0, 0.0),

    # Starbucks / Coffee shop
    "iced":                 (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "blended":              (20, 0.0, 5.0, 0.0, 0.0, 10, 0, 0.0, 0.0),
    "decaf":                (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "with foam":            (5, 0.3, 0.5, 0.2, 0.0, 5, 1, 0.1, 0.0),
    "extra foam":           (10, 0.6, 1.0, 0.4, 0.0, 10, 2, 0.2, 0.0),
    "no foam":              (-5, -0.3, -0.5, -0.2, 0.0, -5, -1, -0.1, 0.0),
    "add matcha":           (30, 1.0, 5.0, 0.5, 0.5, 5, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # DIETARY / HEALTH SUBSTITUTIONS
    # ═══════════════════════════════════════════════════════════════
    "gluten free":          (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "keto":                 (-30, 2.0, -15.0, 5.0, 0.0, 0, 0, 1.0, 0.0),
    "low carb":             (-30, 0.0, -12.0, 2.0, 0.0, 0, 0, 0.5, 0.0),
    "vegan cheese":         (-10, -1.0, 1.0, -0.5, 0.0, -50, -18, -2.5, 0.0),
    "plant based patty":    (-30, -2.0, 5.0, -3.0, 2.0, 80, -75, -4.0, 0.0),
    "beyond meat":          (-20, 0.0, 3.0, -2.0, 1.0, 100, -75, -4.0, 0.0),
    "impossible":           (-10, 1.0, 4.0, -1.0, 1.0, 120, -75, -3.0, 0.0),
    "sub cauliflower rice": (-60, -0.5, -16.0, 0.0, 1.0, -5, 0, 0.0, 0.0),
    "sub brown rice":       (10, 0.5, 2.0, 0.0, 1.0, -5, 0, 0.0, 0.0),
    "sub sweet potato fries": (20, 0.5, 5.0, -1.0, 1.5, -50, 0, -0.3, 0.0),
    "sub side salad":       (-100, -1.0, -18.0, -5.0, 2.0, -200, 0, -0.8, 0.0),
    "sub fruit":            (-80, -1.0, -10.0, -5.0, 2.0, -180, 0, -0.8, 0.0),
    "sub zucchini noodles": (-80, -2.0, -18.0, 0.5, 1.5, -5, 0, 0.0, 0.0),
    "sub quinoa":           (10, 2.0, 0.0, 1.0, 1.5, -5, 0, 0.1, 0.0),
    "sub whole wheat":      (0, 1.0, 0.0, 0.0, 2.0, 0, 0, 0.0, 0.0),
    "sub multigrain":       (0, 1.0, 0.0, 0.0, 2.0, 0, 0, 0.0, 0.0),
    "sub sourdough":        (10, 0.5, 2.0, 0.0, 0.5, 30, 0, 0.0, 0.0),
    "dairy free":           (-20, -1.0, 1.0, -2.0, 0.0, -50, -15, -2.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # BREAKFAST ADD-ONS
    # ═══════════════════════════════════════════════════════════════
    "add hash brown":       (140, 1.5, 15.0, 8.0, 1.5, 280, 0, 1.5, 0.0),
    "add hash browns":      (140, 1.5, 15.0, 8.0, 1.5, 280, 0, 1.5, 0.0),
    "extra hash brown":     (140, 1.5, 15.0, 8.0, 1.5, 280, 0, 1.5, 0.0),
    "add sausage patty":    (200, 8.0, 1.0, 18.0, 0.0, 450, 40, 6.5, 0.0),
    "add sausage link":     (100, 4.0, 0.5, 9.0, 0.0, 220, 20, 3.0, 0.0),
    "add pancake":          (90, 2.0, 15.0, 2.5, 0.5, 200, 15, 0.8, 0.0),
    "add waffle":           (110, 2.5, 16.0, 4.0, 0.5, 250, 20, 1.5, 0.0),
    "add toast":            (80, 2.5, 14.0, 1.0, 0.8, 150, 0, 0.2, 0.0),
    "add english muffin":   (130, 5.0, 25.0, 1.0, 1.5, 260, 0, 0.2, 0.0),
    "add croissant":        (230, 4.5, 26.0, 12.0, 1.0, 320, 40, 6.5, 0.3),
    "add bagel":            (250, 9.0, 48.0, 1.5, 2.0, 430, 0, 0.3, 0.0),
    "with cream cheese on bagel": (100, 2.0, 2.0, 10.0, 0.0, 100, 30, 6.0, 0.0),
    "add biscuit":          (180, 3.0, 22.0, 9.0, 0.5, 520, 5, 3.0, 0.5),
    "add home fries":       (120, 2.0, 18.0, 4.5, 2.0, 250, 0, 0.5, 0.0),
    "add fruit cup":        (60, 0.5, 15.0, 0.0, 2.0, 5, 0, 0.0, 0.0),
    "add granola":          (60, 2.0, 10.0, 2.0, 1.0, 30, 0, 0.3, 0.0),
    "with oatmeal":         (100, 3.5, 18.0, 2.0, 3.0, 5, 0, 0.3, 0.0),
    "add cottage cheese":   (55, 6.0, 2.0, 2.5, 0.0, 200, 10, 1.5, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # FAST FOOD / RESTAURANT SIDES
    # ═══════════════════════════════════════════════════════════════
    "add fries":            (230, 3.0, 30.0, 11.0, 3.0, 160, 0, 1.5, 0.0),
    "add small fries":      (230, 3.0, 30.0, 11.0, 3.0, 160, 0, 1.5, 0.0),
    "add medium fries":     (320, 4.0, 42.0, 15.0, 4.0, 230, 0, 2.0, 0.0),
    "add large fries":      (400, 5.0, 52.0, 19.0, 5.0, 290, 0, 2.5, 0.0),
    "add curly fries":      (280, 3.5, 34.0, 15.0, 3.0, 550, 0, 2.5, 0.0),
    "add sweet potato fries": (260, 3.0, 36.0, 12.0, 4.0, 200, 0, 1.5, 0.0),
    "add onion rings":      (280, 4.0, 32.0, 15.0, 1.5, 420, 0, 3.0, 0.2),
    "add mozzarella sticks": (300, 12.0, 28.0, 16.0, 1.0, 680, 25, 6.5, 0.3),
    "add cheese fries":     (350, 7.0, 35.0, 20.0, 3.0, 450, 15, 5.0, 0.1),
    "add chili cheese fries": (420, 12.0, 38.0, 24.0, 4.0, 650, 30, 7.0, 0.2),
    "add loaded fries":     (400, 8.0, 35.0, 25.0, 3.0, 550, 25, 7.5, 0.2),
    "add truffle fries":    (280, 3.0, 32.0, 16.0, 3.0, 200, 0, 2.0, 0.0),
    "add tater tots":       (200, 2.0, 24.0, 11.0, 2.0, 350, 0, 1.5, 0.0),
    "add mac and cheese":   (200, 8.0, 22.0, 10.0, 1.0, 450, 20, 5.0, 0.1),
    "add cornbread":        (120, 2.0, 18.0, 4.5, 1.0, 250, 15, 1.0, 0.0),
    "add baked beans":      (100, 5.0, 18.0, 0.5, 4.0, 450, 0, 0.1, 0.0),
    "add hush puppies":     (130, 2.0, 16.0, 7.0, 0.5, 280, 10, 1.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # AFRICAN / CARIBBEAN / LATIN
    # ═══════════════════════════════════════════════════════════════
    "with plantains":       (90, 1.0, 22.0, 0.5, 1.5, 5, 0, 0.1, 0.0),
    "add plantains":        (90, 1.0, 22.0, 0.5, 1.5, 5, 0, 0.1, 0.0),
    "add fried plantains":  (120, 1.0, 22.0, 4.0, 1.5, 10, 0, 1.0, 0.0),
    "with jerk sauce":      (20, 0.3, 4.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "add jerk sauce":       (20, 0.3, 4.0, 0.5, 0.3, 350, 0, 0.1, 0.0),
    "with scotch bonnet":   (5, 0.2, 1.0, 0.0, 0.5, 5, 0, 0.0, 0.0),
    "with chimichurri":     (50, 0.3, 1.0, 5.0, 0.3, 200, 0, 0.7, 0.0),
    "add chimichurri":      (50, 0.3, 1.0, 5.0, 0.3, 200, 0, 0.7, 0.0),
    "with sofrito":         (30, 0.5, 3.0, 2.0, 0.5, 200, 0, 0.3, 0.0),
    "with aji sauce":       (15, 0.3, 2.0, 0.5, 0.3, 100, 0, 0.1, 0.0),
    "with romesco":         (50, 1.0, 3.0, 4.0, 0.5, 120, 0, 0.5, 0.0),
    "add romesco":          (50, 1.0, 3.0, 4.0, 0.5, 120, 0, 0.5, 0.0),
    "with toum":            (80, 0.2, 1.0, 9.0, 0.0, 50, 0, 1.0, 0.0),
    "add toum":             (80, 0.2, 1.0, 9.0, 0.0, 50, 0, 1.0, 0.0),
    "with zhug":            (20, 0.5, 2.0, 1.0, 0.5, 100, 0, 0.1, 0.0),
    "with amba":            (15, 0.3, 3.0, 0.3, 0.5, 150, 0, 0.0, 0.0),
    "with green goddess":   (60, 0.5, 1.0, 6.0, 0.0, 150, 5, 1.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # NYC HALAL / STREET FOOD
    # ═══════════════════════════════════════════════════════════════
    "with white sauce":     (80, 0.5, 2.0, 8.0, 0.0, 200, 10, 1.5, 0.0),
    "add white sauce":      (80, 0.5, 2.0, 8.0, 0.0, 200, 10, 1.5, 0.0),
    "extra white sauce":    (160, 1.0, 4.0, 16.0, 0.0, 400, 20, 3.0, 0.0),
    "with red sauce":       (15, 0.5, 2.0, 0.5, 0.5, 200, 0, 0.1, 0.0),
    "add red sauce":        (15, 0.5, 2.0, 0.5, 0.5, 200, 0, 0.1, 0.0),
    "with tzatziki sauce":  (25, 1.0, 2.0, 1.5, 0.0, 100, 3, 0.8, 0.0),
    "on a bed of rice":     (130, 3.0, 28.0, 0.5, 0.5, 5, 0, 0.1, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # GENERIC INTENSIFIERS & MISC
    # ═══════════════════════════════════════════════════════════════
    "extra spicy":          (5, 0.0, 1.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "mild":                 (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "medium spicy":         (3, 0.0, 0.5, 0.0, 0.0, 25, 0, 0.0, 0.0),
    "spicy":                (5, 0.0, 1.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "extra crispy":         (100, 0.0, 8.0, 7.0, 0.0, 200, 0, 1.3, 0.0),
    # ── Steak / meat doneness ──
    # USDA steak data ≈ medium doneness. Deltas reflect moisture loss & fat rendering.
    # Rare: ~10% shrinkage, retains moisture → lower cal density/100g, more fat retained in meat
    # Well done: ~30% shrinkage, loses moisture → higher cal density/100g, fat renders out
    # Values: (cal, protein_g, carbs_g, fat_g, fiber_g, sodium_mg, cholesterol_mg, sat_fat_g, trans_fat_g)
    "blue rare":            (-10, -0.5, 0.0, 0.8, 0.0, -5, 2, 0.3, 0.0),   # ~120°F, very juicy, max moisture
    "rare":                 (-8, -0.3, 0.0, 0.5, 0.0, -5, 2, 0.2, 0.0),    # ~130°F, cool red center
    "medium rare":          (-3, -0.1, 0.0, 0.2, 0.0, 0, 0, 0.1, 0.0),     # ~135°F, warm red center (closest to USDA ref)
    "medium":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),       # ~145°F, USDA reference baseline
    "medium well":          (8, 0.5, 0.0, -0.5, 0.0, 10, 0, -0.2, 0.0),    # ~155°F, slight pink, more water loss
    "well done":            (15, 1.0, 0.0, -1.0, 0.0, 15, 0, -0.4, 0.0),   # ~165°F+, no pink, significant shrinkage
    # Colloquial doneness terms (mapped to closest standard)
    "bloody":               (-10, -0.5, 0.0, 0.8, 0.0, -5, 2, 0.3, 0.0),   # = blue rare
    "some pink":            (-3, -0.1, 0.0, 0.2, 0.0, 0, 0, 0.1, 0.0),     # = medium rare
    "pink":                 (-3, -0.1, 0.0, 0.2, 0.0, 0, 0, 0.1, 0.0),     # = medium rare
    "no pink":              (15, 1.0, 0.0, -1.0, 0.0, 15, 0, -0.4, 0.0),   # = well done
    "cooked through":       (15, 1.0, 0.0, -1.0, 0.0, 15, 0, -0.4, 0.0),   # = well done
    # Special styles
    "pittsburgh style":     (5, 0.3, 0.0, 0.3, 0.0, 10, 0, 0.1, 0.0),      # charred outside, rare inside
    "chicago style":        (5, 0.3, 0.0, 0.3, 0.0, 10, 0, 0.1, 0.0),      # similar to pittsburgh
    "chargrilled":          (0, 0.0, 0.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "blackened":            (10, 0.2, 1.0, 0.5, 0.3, 200, 0, 0.1, 0.0),
    "smoked":               (0, 0.0, 0.0, 0.0, 0.0, 100, 0, 0.0, 0.0),
    "steamed":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "boiled":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "baked":                (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "roasted":              (10, 0.0, 0.0, 1.0, 0.0, 10, 0, 0.1, 0.0),
    "braised":              (15, 0.0, 1.0, 1.0, 0.0, 100, 0, 0.3, 0.0),
    "poached":              (0, 0.0, 0.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "air fried":            (20, 0.0, 2.0, 1.0, 0.0, 20, 0, 0.2, 0.0),
    "animal style":         (100, 2.0, 8.0, 7.0, 0.5, 250, 10, 2.5, 0.0),
    "supreme":              (40, 1.5, 3.0, 2.5, 0.5, 150, 8, 1.0, 0.0),
    "deluxe":               (60, 1.0, 5.0, 4.0, 0.5, 180, 5, 1.0, 0.0),
    "add potatoes":         (80, 2.0, 17.0, 0.5, 2.0, 10, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # STATE / TEMPERATURE (zero or near-zero cal impact, strip cleanly)
    # ═══════════════════════════════════════════════════════════════
    "leftover":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "reheated":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "cold":                 (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "room temperature":     (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "warm":                 (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "hot":                  (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "frozen":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "thawed":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "fresh":                (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "freshly made":         (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "day old":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "overnight":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "canned":               (5, 0.0, 1.0, 0.0, 0.0, 200, 0, 0.0, 0.0),
    "jarred":               (5, 0.0, 1.0, 0.0, 0.0, 150, 0, 0.0, 0.0),
    "packaged":             (0, 0.0, 0.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "pre-made":             (0, 0.0, 0.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "pre-packaged":         (0, 0.0, 0.0, 0.0, 0.0, 80, 0, 0.0, 0.0),
    "instant":              (5, 0.0, 1.0, 0.0, 0.0, 100, 0, 0.0, 0.0),
    "microwaved":           (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "al dente":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # QUALITY / DIETARY LABELS (minimal cal impact, recognized & stripped)
    # ═══════════════════════════════════════════════════════════════
    "organic":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "grass fed":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "grass-fed":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "free range":           (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "free-range":           (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "pasture raised":       (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "cage free":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "wild caught":          (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "farm raised":          (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "all natural":          (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "natural":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "non-gmo":              (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "sugar free":           (-30, 0.0, -8.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "sugar-free":           (-30, 0.0, -8.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "zero sugar":           (-30, 0.0, -8.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "no sugar added":       (-15, 0.0, -4.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "low fat":              (-30, 0.0, 2.0, -5.0, 0.0, 50, 0, -2.0, 0.0),
    "fat free":             (-50, 0.0, 3.0, -8.0, 0.0, 80, 0, -3.0, 0.0),
    "reduced fat":          (-20, 0.0, 1.0, -3.0, 0.0, 30, 0, -1.5, 0.0),
    "light":                (-20, 0.0, 0.0, -3.0, 0.0, 20, 0, -1.0, 0.0),
    "lite":                 (-20, 0.0, 0.0, -3.0, 0.0, 20, 0, -1.0, 0.0),
    "diet":                 (-40, 0.0, -10.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "zero calorie":         (-50, 0.0, -12.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "low carb":             (-30, 2.0, -10.0, 1.0, 0.0, 0, 0, 0.0, 0.0),
    "high protein":         (10, 5.0, -2.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "whole grain":          (0, 1.0, 0.0, 0.0, 2.0, 0, 0, 0.0, 0.0),
    "whole wheat":          (0, 1.0, 0.0, 0.0, 2.0, 0, 0, 0.0, 0.0),
    "multigrain":           (0, 1.0, 0.0, 0.0, 2.0, 0, 0, 0.0, 0.0),
    "fortified":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "enriched":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "unsweetened":          (-20, 0.0, -5.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "sweetened":            (20, 0.0, 5.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "salted":               (0, 0.0, 0.0, 0.0, 0.0, 200, 0, 0.0, 0.0),
    "unsalted":             (0, 0.0, 0.0, 0.0, 0.0, -200, 0, 0.0, 0.0),
    "lightly salted":       (0, 0.0, 0.0, 0.0, 0.0, 100, 0, 0.0, 0.0),
    "low sodium":           (0, 0.0, 0.0, 0.0, 0.0, -150, 0, 0.0, 0.0),
    "no salt":              (0, 0.0, 0.0, 0.0, 0.0, -200, 0, 0.0, 0.0),
    "raw":                  (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "uncooked":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "blanched":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "seared":               (15, 0.0, 0.0, 1.5, 0.0, 20, 0, 0.3, 0.0),
    "pan seared":           (20, 0.0, 0.0, 2.0, 0.0, 30, 0, 0.4, 0.0),
    "stir fried":           (30, 0.0, 1.0, 3.0, 0.0, 150, 0, 0.5, 0.0),
    "stir-fried":           (30, 0.0, 1.0, 3.0, 0.0, 150, 0, 0.5, 0.0),
    "sauteed":              (30, 0.0, 0.0, 3.0, 0.0, 50, 0, 0.5, 0.0),
    "sautéed":              (30, 0.0, 0.0, 3.0, 0.0, 50, 0, 0.5, 0.0),
    "char-grilled":         (0, 0.0, 0.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "flame grilled":        (0, 0.0, 0.0, 0.0, 0.0, 30, 0, 0.0, 0.0),
    "slow cooked":          (0, 0.0, 0.0, 0.0, 0.0, 50, 0, 0.0, 0.0),
    "pressure cooked":      (0, 0.0, 0.0, 0.0, 0.0, 20, 0, 0.0, 0.0),
    "oven baked":           (5, 0.0, 0.0, 0.5, 0.0, 10, 0, 0.1, 0.0),
    "tandoori":             (15, 0.0, 1.0, 1.0, 0.0, 200, 0, 0.3, 0.0),
    "marinated":            (15, 0.0, 2.0, 0.5, 0.0, 200, 0, 0.1, 0.0),
    "seasoned":             (5, 0.0, 0.5, 0.0, 0.0, 150, 0, 0.0, 0.0),
    "breaded":              (60, 1.0, 10.0, 3.0, 0.5, 200, 5, 0.5, 0.1),
    "battered":             (80, 1.5, 12.0, 4.0, 0.3, 250, 10, 0.8, 0.2),
    "tempura style":        (80, 1.0, 10.0, 5.0, 0.3, 200, 5, 0.8, 0.1),
    "fried":                (80, 0.0, 5.0, 7.0, 0.0, 150, 0, 1.5, 0.3),
    "deep fried":           (120, 0.0, 8.0, 10.0, 0.0, 200, 0, 2.0, 0.5),
    "shallow fried":        (50, 0.0, 2.0, 5.0, 0.0, 80, 0, 1.0, 0.1),
    "pan fried":            (40, 0.0, 1.0, 4.0, 0.0, 50, 0, 0.8, 0.0),
    "double fried":         (150, 0.0, 10.0, 12.0, 0.0, 250, 0, 2.5, 0.5),
    "twice cooked":         (40, 0.0, 2.0, 3.0, 0.0, 100, 0, 0.5, 0.0),
    "caramelized":          (20, 0.0, 5.0, 0.0, 0.0, 10, 0, 0.0, 0.0),
    "glazed":               (30, 0.0, 7.0, 0.5, 0.0, 30, 0, 0.1, 0.0),
    "honey glazed":         (40, 0.0, 10.0, 0.0, 0.0, 20, 0, 0.0, 0.0),
    "teriyaki glazed":      (35, 0.5, 8.0, 0.0, 0.0, 350, 0, 0.0, 0.0),
    "bbq glazed":           (30, 0.0, 7.0, 0.0, 0.0, 200, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # PORTION / SERVING DESCRIPTORS (no direct cal, recognized for parsing)
    # ═══════════════════════════════════════════════════════════════
    "single":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "double":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "triple":               (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "mini":                 (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "bite size":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "bite-size":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "king size":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "family size":          (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "snack size":           (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "fun size":             (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "sharing size":         (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # BUTTER PATS
    # ═══════════════════════════════════════════════════════════════
    "butter pat":           (36, 0.0, 0.0, 4.1, 0.0, 1, 11, 2.5, 0.0),
    "with butter pat":      (36, 0.0, 0.0, 4.1, 0.0, 1, 11, 2.5, 0.0),
    "butter pats":          (36, 0.0, 0.0, 4.1, 0.0, 1, 11, 2.5, 0.0),

    # ═══════════════════════════════════════════════════════════════
    # WAFFLE HOUSE HASHBROWN MODIFIERS
    # ═══════════════════════════════════════════════════════════════
    "scattered":            (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0),
    "smothered":            (40, 1.0, 3.0, 2.5, 0.5, 50, 0, 0.5, 0.0),
    "covered":              (60, 4.0, 0.5, 5.0, 0.0, 180, 18, 3.0, 0.0),
    "chunked":              (50, 3.0, 0.0, 3.5, 0.0, 200, 10, 1.2, 0.0),
    "diced":                (20, 1.5, 1.0, 1.0, 0.3, 30, 0, 0.3, 0.0),
    "peppered":             (5, 0.2, 1.0, 0.1, 0.3, 5, 0, 0.0, 0.0),
    "capped":               (30, 2.0, 1.0, 2.0, 0.2, 150, 0, 0.5, 0.0),
    "topped":               (60, 2.0, 0.0, 5.0, 0.0, 100, 8, 1.5, 0.0),
    "country":              (80, 2.0, 5.0, 5.0, 0.0, 200, 5, 1.5, 0.1),
    "all the way":          (265, 13.7, 6.5, 19.1, 1.3, 715, 36, 7.0, 0.1),
}


# ── Modifier type classification & metadata ───────────────────────
class ModifierType(str, Enum):
    ADDON = "addon"
    REMOVAL = "removal"
    COOKING_METHOD = "cooking_method"
    DONENESS = "doneness"
    SIZE_PORTION = "size_portion"
    QUALITY_LABEL = "quality_label"
    STATE_TEMP = "state_temp"


class ModifierMeta(NamedTuple):
    type: ModifierType
    default_weight_g: Optional[float] = None
    weight_per_unit_g: Optional[float] = None
    unit_name: Optional[str] = None
    group: Optional[str] = None
    display_label: Optional[str] = None


# Parallel metadata dict — only entries that need explicit metadata.
# Unmapped modifiers are auto-classified by _classify_modifier().
_MODIFIER_METADATA: Dict[str, ModifierMeta] = {
    # ── Doneness (steak_doneness group) ──
    "blue rare":        ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Blue Rare"),
    "rare":             ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Rare"),
    "medium rare":      ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Medium Rare"),
    "medium":           ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Medium"),
    "medium well":      ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Medium Well"),
    "well done":        ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Well Done"),
    "bloody":           ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Bloody (Blue Rare)"),
    "some pink":        ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Some Pink (Med-Rare)"),
    "pink":             ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Pink (Med-Rare)"),
    "no pink":          ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="No Pink (Well Done)"),
    "cooked through":   ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Cooked Through"),
    "pittsburgh style": ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Pittsburgh Style"),
    "chicago style":    ModifierMeta(ModifierType.DONENESS, group="steak_doneness", display_label="Chicago Style"),

    # ── Cooking methods — dry heat ──
    "grilled":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Grilled"),
    "baked":            ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Baked"),
    "roasted":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Roasted"),
    "broiled":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Broiled"),
    "chargrilled":      ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Chargrilled"),
    "char-grilled":     ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Char-Grilled"),
    "flame grilled":    ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Flame Grilled"),
    "oven baked":       ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Oven Baked"),
    "blackened":        ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Blackened"),
    "smoked":           ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Smoked"),
    "tandoori":         ModifierMeta(ModifierType.COOKING_METHOD, group="cook_dry_heat", display_label="Tandoori"),

    # ── Cooking methods — fry ──
    "pan fried":        ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Pan Fried"),
    "shallow fried":    ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Shallow Fried"),
    "fried":            ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Fried"),
    "deep fried":       ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Deep Fried"),
    "air fried":        ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Air Fried"),
    "double fried":     ModifierMeta(ModifierType.COOKING_METHOD, group="cook_fry", display_label="Double Fried"),

    # ── Cooking methods — wet heat ──
    "steamed":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Steamed"),
    "boiled":           ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Boiled"),
    "poached":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Poached"),
    "braised":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Braised"),
    "slow cooked":      ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Slow Cooked"),
    "pressure cooked":  ModifierMeta(ModifierType.COOKING_METHOD, group="cook_wet_heat", display_label="Pressure Cooked"),

    # ── Cooking methods — saute ──
    "sauteed":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Sauteed"),
    "sautéed":          ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Sautéed"),
    "stir fried":       ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Stir Fried"),
    "stir-fried":       ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Stir-Fried"),
    "seared":           ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Seared"),
    "pan seared":       ModifierMeta(ModifierType.COOKING_METHOD, group="cook_saute", display_label="Pan Seared"),

    # ── Size / portion ──
    "mini":             ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Mini"),
    "small":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Small"),
    "make it small":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Small"),
    "half portion":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Half Portion"),
    "large":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Large"),
    "make it large":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Large"),
    "extra large":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Extra Large"),
    "supersize":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Supersize"),

    # ── State / temperature (zero cal, recognized for parsing) ──
    "leftover":         ModifierMeta(ModifierType.STATE_TEMP),
    "reheated":         ModifierMeta(ModifierType.STATE_TEMP),
    "cold":             ModifierMeta(ModifierType.STATE_TEMP),
    "room temperature": ModifierMeta(ModifierType.STATE_TEMP),
    "warm":             ModifierMeta(ModifierType.STATE_TEMP),
    "hot":              ModifierMeta(ModifierType.STATE_TEMP),
    "frozen":           ModifierMeta(ModifierType.STATE_TEMP),
    "thawed":           ModifierMeta(ModifierType.STATE_TEMP),
    "fresh":            ModifierMeta(ModifierType.STATE_TEMP),
    "freshly made":     ModifierMeta(ModifierType.STATE_TEMP),
    "day old":          ModifierMeta(ModifierType.STATE_TEMP),
    "overnight":        ModifierMeta(ModifierType.STATE_TEMP),

    # ── Quality labels ──
    "organic":          ModifierMeta(ModifierType.QUALITY_LABEL),
    "grass fed":        ModifierMeta(ModifierType.QUALITY_LABEL),
    "grass-fed":        ModifierMeta(ModifierType.QUALITY_LABEL),
    "free range":       ModifierMeta(ModifierType.QUALITY_LABEL),
    "free-range":       ModifierMeta(ModifierType.QUALITY_LABEL),
    "pasture raised":   ModifierMeta(ModifierType.QUALITY_LABEL),
    "cage free":        ModifierMeta(ModifierType.QUALITY_LABEL),
    "wild caught":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "farm raised":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "all natural":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "natural":          ModifierMeta(ModifierType.QUALITY_LABEL),
    "non-gmo":          ModifierMeta(ModifierType.QUALITY_LABEL),
    "gluten free":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "whole grain":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "whole wheat":      ModifierMeta(ModifierType.QUALITY_LABEL),
    "multigrain":       ModifierMeta(ModifierType.QUALITY_LABEL),
    "fortified":        ModifierMeta(ModifierType.QUALITY_LABEL),
    "enriched":         ModifierMeta(ModifierType.QUALITY_LABEL),

    # ── Key addons with weight metadata ─────────────────────────
    # Protein add-ons
    "extra patty":          ModifierMeta(ModifierType.ADDON, default_weight_g=113, unit_name="patty"),
    "extra beef patty":     ModifierMeta(ModifierType.ADDON, default_weight_g=113, unit_name="patty"),
    "extra chicken patty":  ModifierMeta(ModifierType.ADDON, default_weight_g=100, unit_name="patty"),
    "extra fish patty":     ModifierMeta(ModifierType.ADDON, default_weight_g=100, unit_name="patty"),
    "extra veggie patty":   ModifierMeta(ModifierType.ADDON, default_weight_g=85, unit_name="patty"),
    "double patty":         ModifierMeta(ModifierType.ADDON, default_weight_g=113, unit_name="patty"),
    "double meat":          ModifierMeta(ModifierType.ADDON, default_weight_g=113, unit_name="patty"),
    "triple patty":         ModifierMeta(ModifierType.ADDON, default_weight_g=226, unit_name="patty"),
    "triple meat":          ModifierMeta(ModifierType.ADDON, default_weight_g=226, unit_name="patty"),
    "add bacon":            ModifierMeta(ModifierType.ADDON, default_weight_g=8, weight_per_unit_g=8, unit_name="strip"),
    "extra bacon":          ModifierMeta(ModifierType.ADDON, default_weight_g=16, weight_per_unit_g=8, unit_name="strip"),
    "with bacon":           ModifierMeta(ModifierType.ADDON, default_weight_g=8, weight_per_unit_g=8, unit_name="strip"),
    "bacon on top":         ModifierMeta(ModifierType.ADDON, default_weight_g=8, weight_per_unit_g=8, unit_name="strip"),
    "add turkey bacon":     ModifierMeta(ModifierType.ADDON, default_weight_g=8, weight_per_unit_g=8, unit_name="strip"),
    "add egg":              ModifierMeta(ModifierType.ADDON, default_weight_g=50, weight_per_unit_g=50, unit_name="egg"),
    "extra egg":            ModifierMeta(ModifierType.ADDON, default_weight_g=50, weight_per_unit_g=50, unit_name="egg"),
    "with egg":             ModifierMeta(ModifierType.ADDON, default_weight_g=50, weight_per_unit_g=50, unit_name="egg"),
    "fried egg on top":     ModifierMeta(ModifierType.ADDON, default_weight_g=50, weight_per_unit_g=50, unit_name="egg"),
    "add scrambled egg":    ModifierMeta(ModifierType.ADDON, default_weight_g=61, weight_per_unit_g=61, unit_name="egg"),
    "add grilled chicken":  ModifierMeta(ModifierType.ADDON, default_weight_g=85, unit_name="breast"),
    "add crispy chicken":   ModifierMeta(ModifierType.ADDON, default_weight_g=85, unit_name="breast"),
    "add shrimp":           ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add grilled shrimp":   ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add fried shrimp":     ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add steak":            ModifierMeta(ModifierType.ADDON, default_weight_g=85, unit_name="serving"),
    "add pulled pork":      ModifierMeta(ModifierType.ADDON, default_weight_g=85, unit_name="serving"),
    "add sausage":          ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="link"),
    "add pepperoni":        ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="serving"),
    "extra pepperoni":      ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="serving"),
    "add ham":              ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="slice"),
    "add salami":           ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="slice"),
    "add anchovies":        ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="serving"),
    "add tuna":             ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add salmon":           ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add smoked salmon":    ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="serving"),
    "add prosciutto":       ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="slice"),
    "add chorizo":          ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="link"),

    # Cheese
    "extra cheese":         ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add cheese":           ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "with cheese":          ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "double cheese":        ModifierMeta(ModifierType.ADDON, default_weight_g=42, unit_name="slice"),
    "cheese on top":        ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add cheddar":          ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "extra cheddar":        ModifierMeta(ModifierType.ADDON, default_weight_g=42, unit_name="slice"),
    "add mozzarella":       ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "extra mozzarella":     ModifierMeta(ModifierType.ADDON, default_weight_g=42, unit_name="slice"),
    "add pepper jack":      ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add swiss":            ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add american cheese":  ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add provolone":        ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "add parmesan":         ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "extra parmesan":       ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="tbsp"),
    "add feta":             ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "extra feta":           ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="tbsp"),
    "add goat cheese":      ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "add blue cheese":      ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "add paneer":           ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="piece"),
    "extra paneer":         ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="piece"),

    # Sauces & condiments
    "with ranch":           ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add ranch":            ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "extra ranch":          ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="tbsp"),
    "with mayo":            ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "extra mayo":           ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add mayo":             ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "with ketchup":         ModifierMeta(ModifierType.ADDON, default_weight_g=17, unit_name="tbsp"),
    "extra ketchup":        ModifierMeta(ModifierType.ADDON, default_weight_g=34, unit_name="tbsp"),
    "with mustard":         ModifierMeta(ModifierType.ADDON, default_weight_g=5, unit_name="tsp"),
    "with bbq sauce":       ModifierMeta(ModifierType.ADDON, default_weight_g=17, unit_name="tbsp"),
    "add bbq sauce":        ModifierMeta(ModifierType.ADDON, default_weight_g=17, unit_name="tbsp"),
    "extra bbq sauce":      ModifierMeta(ModifierType.ADDON, default_weight_g=34, unit_name="tbsp"),
    "with hot sauce":       ModifierMeta(ModifierType.ADDON, default_weight_g=5, unit_name="tsp"),
    "with buffalo sauce":   ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "add buffalo sauce":    ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "with honey mustard":   ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add honey mustard":    ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "with sour cream":      ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add sour cream":       ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "extra sour cream":     ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="tbsp"),
    "with guacamole":       ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add guac":             ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add guacamole":        ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "extra guacamole":      ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="tbsp"),
    "extra guac":           ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="tbsp"),
    "with salsa":           ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add salsa":            ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "with pico de gallo":   ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),

    # Fats & spreads
    "garlic butter":        ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "with garlic butter":   ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "herb butter":          ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "with herb butter":     ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "compound butter":      ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "truffle butter":       ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "brown butter":         ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "lemon butter":         ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "with butter":          ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "add butter":           ModifierMeta(ModifierType.ADDON, default_weight_g=14, unit_name="tbsp"),
    "extra butter":         ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="tbsp"),
    "with cream cheese":    ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="tbsp"),
    "add cream cheese":     ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="tbsp"),
    "extra cream cheese":   ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="tbsp"),
    "with peanut butter":   ModifierMeta(ModifierType.ADDON, default_weight_g=16, unit_name="tbsp"),
    "add peanut butter":    ModifierMeta(ModifierType.ADDON, default_weight_g=16, unit_name="tbsp"),

    # Vegetables
    "add avocado":          ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="slice"),
    "extra avocado":        ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="slice"),
    "with avocado":         ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="slice"),
    "sauteed mushrooms":    ModifierMeta(ModifierType.ADDON, default_weight_g=30, weight_per_unit_g=15, unit_name="mushroom"),
    "grilled mushrooms":    ModifierMeta(ModifierType.ADDON, default_weight_g=30, weight_per_unit_g=15, unit_name="mushroom"),

    # Breakfast
    "add sausage patty":    ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="patty"),
    "add sausage link":     ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="link"),
    "add pancake":          ModifierMeta(ModifierType.ADDON, default_weight_g=38, unit_name="pancake"),
    "add waffle":           ModifierMeta(ModifierType.ADDON, default_weight_g=35, unit_name="waffle"),
    "add hash brown":       ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="piece"),
    "add hash browns":      ModifierMeta(ModifierType.ADDON, default_weight_g=56, unit_name="piece"),

    # Butter pats
    "butter pat":           ModifierMeta(ModifierType.ADDON, default_weight_g=5.0, weight_per_unit_g=5.0, unit_name="pat"),
    "with butter pat":      ModifierMeta(ModifierType.ADDON, default_weight_g=5.0, weight_per_unit_g=5.0, unit_name="pat"),
    "butter pats":          ModifierMeta(ModifierType.ADDON, default_weight_g=5.0, weight_per_unit_g=5.0, unit_name="pat"),

    # Waffle House hashbrown modifiers (non-zero cal ones)
    "smothered":            ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="serving"),
    "covered":              ModifierMeta(ModifierType.ADDON, default_weight_g=21, unit_name="slice"),
    "chunked":              ModifierMeta(ModifierType.ADDON, default_weight_g=28, unit_name="serving"),
    "diced":                ModifierMeta(ModifierType.ADDON, default_weight_g=20, unit_name="serving"),
    "peppered":             ModifierMeta(ModifierType.ADDON, default_weight_g=10, unit_name="serving"),
    "capped":               ModifierMeta(ModifierType.ADDON, default_weight_g=20, unit_name="serving"),
    "topped":               ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="serving"),
    "country":              ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="serving"),
    "all the way":          ModifierMeta(ModifierType.ADDON, default_weight_g=130, unit_name="serving"),

    # Mediterranean / Middle Eastern
    "with hummus":          ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "add hummus":           ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="tbsp"),
    "extra hummus":         ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="tbsp"),
    "with tahini":          ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "add tahini":           ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "with pita":            ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="pita"),
    "add pita":             ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="pita"),
    "add falafel":          ModifierMeta(ModifierType.ADDON, default_weight_g=17, weight_per_unit_g=17, unit_name="piece"),
    "with falafel":         ModifierMeta(ModifierType.ADDON, default_weight_g=17, weight_per_unit_g=17, unit_name="piece"),

    # Indian breads / sides
    "with naan":            ModifierMeta(ModifierType.ADDON, default_weight_g=90, unit_name="piece"),
    "add naan":             ModifierMeta(ModifierType.ADDON, default_weight_g=90, unit_name="piece"),
    "extra naan":           ModifierMeta(ModifierType.ADDON, default_weight_g=90, unit_name="piece"),
    "with garlic naan":     ModifierMeta(ModifierType.ADDON, default_weight_g=100, unit_name="piece"),
    "add garlic naan":      ModifierMeta(ModifierType.ADDON, default_weight_g=100, unit_name="piece"),
    "with roti":            ModifierMeta(ModifierType.ADDON, default_weight_g=40, unit_name="piece"),
    "add roti":             ModifierMeta(ModifierType.ADDON, default_weight_g=40, unit_name="piece"),
    "with paratha":         ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="piece"),
    "add paratha":          ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="piece"),

    # Italian
    "add meatball":         ModifierMeta(ModifierType.ADDON, default_weight_g=40, weight_per_unit_g=40, unit_name="meatball"),
    "extra meatball":       ModifierMeta(ModifierType.ADDON, default_weight_g=40, weight_per_unit_g=40, unit_name="meatball"),
    "add meatballs":        ModifierMeta(ModifierType.ADDON, default_weight_g=80, weight_per_unit_g=40, unit_name="meatball"),
    "with pesto":           ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "add pesto":            ModifierMeta(ModifierType.ADDON, default_weight_g=15, unit_name="tbsp"),
    "with alfredo sauce":   ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="serving"),
    "add alfredo sauce":    ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="serving"),

    # Coffee modifiers
    "extra shot":           ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="shot"),
    "add extra shot":       ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="shot"),
    "double shot":          ModifierMeta(ModifierType.ADDON, default_weight_g=60, unit_name="shot"),
    "add protein powder":   ModifierMeta(ModifierType.ADDON, default_weight_g=30, unit_name="scoop"),
}

# Ordered group lists for UI display
_MODIFIER_GROUPS: Dict[str, List[str]] = {
    "steak_doneness": [
        "blue rare", "rare", "medium rare", "medium",
        "medium well", "well done",
    ],
    "cook_dry_heat": [
        "grilled", "baked", "roasted", "broiled", "chargrilled",
        "blackened", "smoked", "tandoori",
    ],
    "cook_fry": [
        "pan fried", "shallow fried", "fried", "deep fried", "air fried",
    ],
    "cook_wet_heat": [
        "steamed", "boiled", "poached", "braised", "slow cooked",
        "pressure cooked",
    ],
    "cook_saute": [
        "sauteed", "stir fried", "seared", "pan seared",
    ],
    "size": [
        "mini", "small", "half portion", "large", "extra large", "supersize",
    ],
    "cooking_method": [
        "grilled", "baked", "pan fried", "deep fried",
        "steamed", "boiled", "air fried", "roasted",
    ],
}


# Foods that should show modifier group toggles by default (even without explicit modifier text).
# Maps food_name_normalized → list of (group_name, default_phrase, modifier_type).
_FOOD_DEFAULT_MODIFIER_GROUPS: Dict[str, List[tuple]] = {
    "steak": [("steak_doneness", "medium", ModifierType.DONENESS)],
    # Proteins with cooking method modifiers
    "chicken":    [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "fish":       [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "salmon":     [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "tilapia":    [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "cod":        [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "shrimp":     [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "paneer":     [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "tofu":       [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "turkey":     [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "pork":       [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "lamb":       [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "egg":        [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    # Vegetables with cooking method modifiers
    "vegetables": [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "broccoli":   [("cooking_method", "steamed", ModifierType.COOKING_METHOD)],
    "mushroom":   [("cooking_method", "grilled", ModifierType.COOKING_METHOD)],
    "cauliflower":[("cooking_method", "steamed", ModifierType.COOKING_METHOD)],
    "potato":     [("cooking_method", "baked", ModifierType.COOKING_METHOD)],
}
# Also map variant names so "beef steak", "grilled steak" etc. get the toggle
for _vn in ("beef steak", "grilled steak", "steak dinner", "cooked steak",
            "steak piece", "plain steak", "1 steak",
            "sirloin", "ribeye", "filet mignon", "ny strip", "new york strip",
            "t-bone", "tenderloin", "flank steak", "skirt steak",
            "strip steak", "porterhouse"):
    _FOOD_DEFAULT_MODIFIER_GROUPS[_vn] = _FOOD_DEFAULT_MODIFIER_GROUPS["steak"]


def _build_default_modifiers(food_name: str) -> List[Dict[str, Any]]:
    """Build default modifier details for foods with applicable modifier groups."""
    food_key = food_name.lower().strip()
    groups = _FOOD_DEFAULT_MODIFIER_GROUPS.get(food_key)
    if not groups:
        return []

    modifier_details = []
    for group_name, default_phrase, mod_type in groups:
        adj = _FOOD_MODIFIERS.get(default_phrase, (0, 0.0, 0.0, 0.0, 0.0, 0, 0, 0.0, 0.0))
        meta = _MODIFIER_METADATA.get(default_phrase)
        detail: Dict[str, Any] = {
            "phrase": default_phrase,
            "type": mod_type.value,
            "delta": {
                "calories": adj[0],
                "protein_g": adj[1],
                "carbs_g": adj[2],
                "fat_g": adj[3],
                "fiber_g": adj[4],
            },
        }
        if meta and meta.display_label:
            detail["display_label"] = meta.display_label
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
        modifier_details.append(detail)
    return modifier_details


def _classify_modifier(phrase: str) -> ModifierType:
    """Heuristic classification for modifiers not in _MODIFIER_METADATA."""
    if phrase in _MODIFIER_METADATA:
        return _MODIFIER_METADATA[phrase].type
    if phrase.startswith(("no ", "without ", "skip ")):
        return ModifierType.REMOVAL
    delta = _FOOD_MODIFIERS.get(phrase)
    if delta and all(v == 0 for v in delta):
        return ModifierType.QUALITY_LABEL
    if delta and delta[0] < 0 and phrase.startswith(("light ", "skinny", "half ")):
        return ModifierType.SIZE_PORTION
    return ModifierType.ADDON


# Pre-sorted by phrase length (longest first) to avoid partial matches
_MODIFIER_PHRASES_SORTED = sorted(_FOOD_MODIFIERS.keys(), key=len, reverse=True)

# Regex to extract modifier phrases from text
_MODIFIER_REGEX = re.compile(
    r'\b(' + '|'.join(re.escape(p) for p in _MODIFIER_PHRASES_SORTED) + r')\b',
    re.IGNORECASE,
)

# Bullet / prefix patterns
_BULLET_REGEX = re.compile(
    r'^(?:[-•*]\s+|\d+[.)]\s+|(?:breakfast|lunch|dinner|snack|brunch|supper)\s*:\s*)',
    re.IGNORECASE,
)

# Numeric + count-unit: "6 slices pizza"
_NUM_UNIT_REGEX = re.compile(
    r'^(\d+(?:\.\d+)?)\s+(' + '|'.join(_COUNT_UNITS) + r')\s+(?:of\s+)?(.+)$',
    re.IGNORECASE,
)

# Word number + optional unit: "one plate biryani", "half a pizza", "a bowl of soup"
_WORD_NUM_PATTERN = '|'.join(re.escape(w) for w in _WORD_NUMBERS)
_WORD_NUM_UNIT_REGEX = re.compile(
    r'^(' + _WORD_NUM_PATTERN + r')\s+'
    r'(?:a\s+)?'
    r'(?:(' + '|'.join(_COUNT_UNITS) + r')\s+(?:of\s+)?)?'
    r'(.+)$',
    re.IGNORECASE,
)

# Bare number prefix: "2 dosa", "100 rice"
_BARE_NUM_REGEX = re.compile(r'^(\d+(?:\.\d+)?)\s+(.+)$')

# Fraction prefix: "1/2 pizza"
_FRACTION_REGEX = re.compile(r'^(\d+)/(\d+)\s+(.+)$')


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


class FoodAnalysisCacheService:
    """
    Caching layer for food analysis to speed up repeated queries.

    Usage:
        cache_service = FoodAnalysisCacheService()
        result = await cache_service.analyze_food(
            description="lamb biryani",
            user_goals=["build_muscle"],
            nutrition_targets={"daily_calorie_target": 2500},
            rag_context="...",
        )
    """

    def __init__(
        self,
        nutrition_db: Optional[NutritionDB] = None,
        gemini_service: Optional[GeminiService] = None,
    ):
        """
        Initialize the cache service.

        Args:
            nutrition_db: Optional NutritionDB instance (uses global if not provided)
            gemini_service: Optional GeminiService instance (creates new if not provided)
        """
        self._nutrition_db = nutrition_db
        self._gemini_service = gemini_service

    @property
    def nutrition_db(self) -> NutritionDB:
        """Get NutritionDB instance, creating if needed."""
        if self._nutrition_db is None:
            db = get_supabase_db()
            self._nutrition_db = db.nutrition
        return self._nutrition_db

    @property
    def gemini_service(self) -> GeminiService:
        """Get GeminiService instance, creating if needed."""
        if self._gemini_service is None:
            self._gemini_service = GeminiService()
        return self._gemini_service

    async def enrich_with_tips(
        self,
        food_items: list,
        meal_type: Optional[str] = None,
        mood_before: Optional[str] = None,
        user_id: Optional[str] = None,
        coach_name: Optional[str] = None,
        coaching_style: Optional[str] = None,
        communication_tone: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Generate contextual coach tips for food items using full user context.

        Fetches calorie budget (consumed today vs target), computes health score,
        then calls Gemini generate_food_review() with all context for score-stratified,
        mood-aware, calorie-budget-aware tips.

        Args:
            food_items: List of food item dicts with nutritional data
            meal_type: Meal type (breakfast, lunch, dinner, snack)
            mood_before: User's current mood/state
            user_id: User ID for fetching goals, targets, and daily summary

        Returns:
            Dict with encouragements, warnings, ai_suggestion, recommended_swap, health_score
        """
        # Compute aggregate food name and macros from items
        food_names = [item.get("name", "food") for item in food_items]
        food_name = ", ".join(food_names[:3])
        if len(food_names) > 3:
            food_name += f" (+{len(food_names) - 3} more)"

        total_cal = sum(item.get("calories", 0) for item in food_items)
        total_protein = sum(float(item.get("protein_g", 0)) for item in food_items)
        total_carbs = sum(float(item.get("carbs_g", 0)) for item in food_items)
        total_fat = sum(float(item.get("fat_g", 0)) for item in food_items)
        total_fiber = sum(float(item.get("fiber_g", 0)) for item in food_items)

        macros = {
            "calories": total_cal,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
        }

        # Compute health score from items (average goal_score if available, else rule-based)
        item_scores = [item.get("goal_score") or item.get("health_score") for item in food_items]
        item_scores = [s for s in item_scores if s is not None]
        if item_scores:
            health_score = round(sum(item_scores) / len(item_scores))
        else:
            health_score = self._compute_health_score(total_cal, total_protein, total_fiber)

        # Fetch user context (goals, targets, daily summary)
        user_goals = []
        nutrition_targets = {}
        calories_consumed_today = None
        calories_remaining = None

        daily_target = None
        if user_id:
            try:
                supabase = get_supabase()
                async with supabase.get_session() as session:
                    # Get user goals
                    user_result = await session.execute(
                        text("SELECT goals, daily_calorie_target FROM users WHERE id = :uid LIMIT 1"),
                        {"uid": user_id},
                    )
                    user_row = user_result.fetchone()
                    if user_row:
                        goals_val = user_row._mapping.get("goals")
                        if isinstance(goals_val, list):
                            user_goals = goals_val
                        elif isinstance(goals_val, str):
                            try:
                                user_goals = json.loads(goals_val)
                            except (json.JSONDecodeError, TypeError):
                                user_goals = [goals_val] if goals_val else []

                        daily_target = user_row._mapping.get("daily_calorie_target")

                    # Get nutrition targets from preferences
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

                    # Get coach persona from AI settings (if not already passed)
                    if not coach_name:
                        try:
                            coach_result = await session.execute(
                                text(
                                    "SELECT coach_name, coaching_style, communication_tone "
                                    "FROM user_ai_settings WHERE user_id = :uid LIMIT 1"
                                ),
                                {"uid": user_id},
                            )
                            coach_row = coach_result.fetchone()
                            if coach_row:
                                coach_name = coach_row._mapping.get("coach_name")
                                coaching_style = coach_row._mapping.get("coaching_style")
                                communication_tone = coach_row._mapping.get("communication_tone")
                        except Exception as e:
                            logger.warning(f"[EnrichTips] Failed to fetch coach persona: {e}")

                # Get daily nutrition summary for calorie budget
                try:
                    from datetime import date as date_type
                    today_str = date_type.today().isoformat()
                    nutrition_db = NutritionDB()
                    daily_summary = nutrition_db.get_daily_nutrition_summary(user_id, today_str)
                    calories_consumed_today = daily_summary.get("total_calories", 0)

                    # Use target from preferences first, then user table
                    target_cal = nutrition_targets.get("calories") or (daily_target if user_row else None)
                    if target_cal:
                        calories_remaining = max(0, int(target_cal) - calories_consumed_today)
                except Exception as e:
                    logger.warning(f"[EnrichTips] Failed to get daily summary: {e}")

            except Exception as e:
                logger.warning(f"[EnrichTips] Failed to fetch user data: {e}")

        # Call Gemini for contextual tips
        try:
            review = await self.gemini_service.generate_food_review(
                food_name=food_name,
                macros=macros,
                user_goals=user_goals,
                nutrition_targets=nutrition_targets,
                meal_type=meal_type,
                mood_before=mood_before,
                calories_consumed_today=calories_consumed_today,
                calories_remaining=calories_remaining,
                health_score=health_score,
                coach_name=coach_name,
                coaching_style=coaching_style,
                communication_tone=communication_tone,
            )
            if review:
                # Use the Gemini-returned health_score if we didn't have one from items
                if not item_scores and review.get("health_score"):
                    health_score = review["health_score"]
                return {
                    "encouragements": review.get("encouragements", []),
                    "warnings": review.get("warnings", []),
                    "ai_suggestion": review.get("ai_suggestion", ""),
                    "recommended_swap": review.get("recommended_swap", ""),
                    "health_score": health_score,
                }
        except Exception as e:
            logger.error(f"[EnrichTips] Gemini call failed: {e}")

        # Fallback: return just the computed health_score with no tips
        return {
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": "",
            "recommended_swap": "",
            "health_score": health_score,
        }

    async def analyze_food(
        self,
        description: str,
        user_goals: Optional[List[str]] = None,
        nutrition_targets: Optional[Dict] = None,
        rag_context: Optional[str] = None,
        use_cache: bool = True,
        user_id: Optional[str] = None,
        mood_before: Optional[str] = None,
        meal_type: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyze food with intelligent caching.

        Order of operations:
        0a. Check user's saved foods (instant, user-scoped)
        0b. Check food nutrition overrides - 6,949 curated items (instant)
        1. Check common foods database (instant, bypasses AI)
        1b. Try multi-item lookup (overrides + common foods)
        1c. Try modified override (base item + modifiers like "extra patty")
        2. Check food analysis cache (cached AI response)
        3. Fall back to fresh Gemini analysis (cache result)

        For cache hits, enriches with contextual coach tips via enrich_with_tips().

        Args:
            description: Food description text
            user_goals: List of user fitness goals
            nutrition_targets: Dict with calorie/macro targets
            rag_context: RAG context from nutrition knowledge base
            use_cache: Whether to use caching (default True)
            user_id: Optional user ID for saved foods lookup
            mood_before: User's current mood/state
            meal_type: Meal type (breakfast, lunch, dinner, snack)

        Returns:
            Dict with food_items, totals, AI suggestions, and cache_hit indicator
        """
        result = {
            "cache_hit": False,
            "cache_source": None,
        }

        # Step 0a: Try user's saved foods (instant, user-scoped)
        if use_cache and user_id:
            saved = await self._try_saved_food(description, user_id)
            if saved:
                logger.info(f"🎯 Saved food HIT: {description}")
                result.update(saved)
                result["cache_hit"] = True
                result["cache_source"] = "saved_food"
                # Enrich cache hit with contextual tips
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 0b: Try food nutrition overrides (3,785 curated items)
        if use_cache:
            override = await self._try_override(description)
            if override:
                logger.info(f"🎯 Override HIT: {description}")
                result.update(override)
                result["cache_hit"] = True
                result["cache_source"] = "override"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1: Try common foods database (instant lookup)
        if use_cache:
            common_food = await self._try_common_food(description)
            if common_food:
                logger.info(f"🎯 Common food HIT: {description}")
                result.update(common_food)
                result["cache_hit"] = True
                result["cache_source"] = "common_foods"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1b: Try multi-item lookup (overrides + common foods)
        if use_cache:
            multi_result = await self._try_multi_item_lookup(description, user_id)
            if multi_result:
                logger.info(f"🎯 Multi-item lookup HIT: {description}")
                result.update(multi_result)
                result["cache_hit"] = True
                result["cache_source"] = "multi_lookup"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 1c: Try modified override (base item + modifiers like "extra patty", "no cheese")
        if use_cache:
            modified = await self._try_modified_override(description)
            if modified:
                logger.info(f"🎯 Modified override HIT: {description}")
                result.update(modified)
                result["cache_hit"] = True
                result["cache_source"] = "modified_override"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 2: Try food analysis cache (cached AI response)
        if use_cache:
            cached = await self._try_cache(description)
            if cached:
                logger.info(f"🎯 Cache HIT for: {description[:50]}...")
                result.update(cached)
                result["cache_hit"] = True
                result["cache_source"] = "analysis_cache"
                await self._enrich_cache_hit_with_tips(result, meal_type, mood_before, user_id)
                return result

        # Step 3: Fresh Gemini analysis
        logger.info(f"🔄 Cache MISS - calling Gemini for: {description[:50]}...")

        analysis = await self.gemini_service.parse_food_description(
            description=description,
            user_goals=user_goals,
            nutrition_targets=nutrition_targets,
            rag_context=rag_context,
            mood_before=mood_before,
            meal_type=meal_type,
        )

        if analysis and analysis.get('food_items'):
            # Cache the successful result
            if use_cache:
                await self._cache_result(description, analysis)

            # Auto-learn food items for future common food lookups
            asyncio.create_task(self._auto_learn_food_items(analysis))

            result.update(analysis)
            result["cache_hit"] = False
            result["cache_source"] = "gemini_fresh"
            return result

        # Analysis failed
        logger.warning(f"❌ Gemini analysis failed for: {description[:50]}...")
        return None

    async def _enrich_cache_hit_with_tips(
        self,
        result: Dict[str, Any],
        meal_type: Optional[str],
        mood_before: Optional[str],
        user_id: Optional[str],
    ) -> None:
        """
        Enrich a cache-hit result with contextual coach tips if missing.

        Modifies result dict in-place by adding tip fields from enrich_with_tips().
        Only calls Gemini if tips are empty/missing in the cached data.
        """
        # Check if tips are already present and non-empty
        has_tips = (
            result.get("ai_suggestion")
            or result.get("encouragements")
            or result.get("warnings")
        )
        if has_tips:
            return

        food_items = result.get("food_items", [])
        if not food_items:
            return

        try:
            tips = await self.enrich_with_tips(
                food_items=food_items,
                meal_type=meal_type,
                mood_before=mood_before,
                user_id=user_id,
            )
            if tips:
                result["encouragements"] = tips.get("encouragements", [])
                result["warnings"] = tips.get("warnings", [])
                result["ai_suggestion"] = tips.get("ai_suggestion", "")
                result["recommended_swap"] = tips.get("recommended_swap", "")
                if tips.get("health_score") and not result.get("health_score"):
                    result["health_score"] = tips["health_score"]
                logger.info(f"[EnrichTips] Enriched cache hit with tips for {len(food_items)} items")
        except Exception as e:
            logger.warning(f"[EnrichTips] Failed to enrich cache hit: {e}")

    async def _try_common_food(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find food in common foods database.

        Args:
            description: Food description

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            # Simple single-item lookup first
            common = self.nutrition_db.get_common_food(description)

            if common:
                # Convert common food to analysis format
                return self._common_food_to_analysis(common)

            return None

        except Exception as e:
            logger.warning(f"Common food lookup failed: {e}")
            return None

    async def _try_saved_food(
        self, description: str, user_id: str
    ) -> Optional[Dict[str, Any]]:
        """
        Try to find food in user's saved foods.

        Args:
            description: Food description
            user_id: User ID for scoping

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            supabase = get_supabase()
            normalized = description.strip().lower()
            async with supabase.get_session() as session:
                result = await session.execute(
                    text(
                        "SELECT * FROM saved_foods "
                        "WHERE user_id = :uid AND LOWER(name) = :name "
                        "AND deleted_at IS NULL LIMIT 1"
                    ),
                    {"uid": user_id, "name": normalized},
                )
                row = result.fetchone()

            if not row:
                return None

            saved = dict(row._mapping)
            return self._saved_food_to_analysis(saved)

        except Exception as e:
            logger.warning(f"Saved food lookup failed: {e}")
            return None

    def _saved_food_to_analysis(self, saved: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert saved food record to standard analysis format.

        Saved foods store per-meal totals + food_items JSONB array.

        Args:
            saved: Record from saved_foods table

        Returns:
            Dict in same format as Gemini analysis
        """
        total_calories = int(saved.get("total_calories") or 0)
        protein_g = float(saved.get("total_protein_g") or 0)
        carbs_g = float(saved.get("total_carbs_g") or 0)
        fat_g = float(saved.get("total_fat_g") or 0)
        fiber_g = float(saved.get("total_fiber_g") or 0)

        # Map food_items JSONB array directly
        raw_items = saved.get("food_items") or []
        food_items = []
        for item in raw_items:
            fi = {
                "name": item.get("name", saved.get("name")),
                "amount": item.get("amount", "1 serving"),
                "calories": int(item.get("calories") or 0),
                "protein_g": float(item.get("protein_g") or 0),
                "carbs_g": float(item.get("carbs_g") or 0),
                "fat_g": float(item.get("fat_g") or 0),
                "fiber_g": float(item.get("fiber_g") or 0),
                "weight_g": float(item.get("weight_g")) if item.get("weight_g") else None,
                "weight_source": "exact",
                "unit": "g",
            }
            # Add per-gram scaling if weight available
            w = fi["weight_g"]
            if w and w > 0:
                fi["ai_per_gram"] = {
                    "calories": round(fi["calories"] / w, 3),
                    "protein": round(fi["protein_g"] / w, 4),
                    "carbs": round(fi["carbs_g"] / w, 4),
                    "fat": round(fi["fat_g"] / w, 4),
                    "fiber": round(fi["fiber_g"] / w, 4),
                }
            food_items.append(fi)

        # Fallback: if no food_items array, create one from totals
        if not food_items:
            food_items = [{
                "name": saved.get("name"),
                "amount": "1 serving",
                "calories": total_calories,
                "protein_g": protein_g,
                "carbs_g": carbs_g,
                "fat_g": fat_g,
                "fiber_g": fiber_g,
                "weight_source": "exact",
                "unit": "g",
            }]

        score = self._compute_health_score(total_calories, protein_g, fiber_g)

        return {
            "food_items": food_items,
            "total_calories": total_calories,
            "protein_g": protein_g,
            "carbs_g": carbs_g,
            "fat_g": fat_g,
            "fiber_g": fiber_g,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": saved.get("overall_meal_score") or score,
            "health_score": score,
            "data_source": "saved_food",
        }

    async def _try_override(self, description: str) -> Optional[Dict[str, Any]]:
        """
        Try to find food in the curated food_nutrition_overrides (3,785 items).

        Parses quantity/weight from the description, looks up the cleaned food name,
        then scales the result accordingly.

        Examples:
            "2 dosa"     → food="dosa", qty=2 → scale by 2
            "300g rice"  → food="rice", weight_g=300 → scale per-100g
            "biryani"    → food="biryani", qty=1 → default serving

        Args:
            description: Food description

        Returns:
            Formatted analysis result if found, None otherwise
        """
        try:
            lookup_service = get_food_db_lookup_service()
            await lookup_service._load_overrides()

            # First try exact match on full description (handles "chicken 65", etc.)
            override = lookup_service._check_override(description)
            food_key = description  # Track which key matched for default modifiers
            if override:
                result = self._override_to_analysis(override)
                self._inject_default_modifiers(result, food_key, override)
                return result

            # Parse to extract quantity/weight, then look up cleaned food name
            parsed = self._parse_single_item(description)
            if not parsed:
                return None

            override = lookup_service._check_override(parsed.food_name)
            food_key = parsed.food_name
            if not override:
                return None

            # Scale based on what was parsed
            if parsed.weight_g:
                result = self._override_to_analysis_by_weight(override, parsed.weight_g)
            elif parsed.quantity != 1.0:
                result = self._override_to_analysis_scaled(override, parsed.quantity)
            else:
                result = self._override_to_analysis(override)

            self._inject_default_modifiers(result, food_key, override)
            return result

        except Exception as e:
            logger.warning(f"Override lookup failed: {e}")
            return None

    def _override_to_analysis(self, override: Dict[str, Any]) -> Dict[str, Any]:
        """
        Convert per-100g override to per-serving analysis format.

        Serving size priority: override_serving_g > override_weight_per_piece_g > 100g

        Args:
            override: Override dict from FoodDatabaseLookupService

        Returns:
            Dict in same format as Gemini analysis
        """
        # Determine serving size
        serving_g = (
            override.get("override_serving_g")
            or override.get("override_weight_per_piece_g")
            or 100.0
        )
        scale = serving_g / 100.0
        default_count = override.get("default_count", 1) or 1

        calories_per_serving = round(override["calories_per_100g"] * scale)
        protein_per_serving = round(override["protein_per_100g"] * scale, 1)
        carbs_per_serving = round(override["carbs_per_100g"] * scale, 1)
        fat_per_serving = round(override["fat_per_100g"] * scale, 1)
        fiber_per_serving = round(override.get("fiber_per_100g", 0) * scale, 1)

        total_calories = calories_per_serving * default_count
        total_protein = round(protein_per_serving * default_count, 1)
        total_carbs = round(carbs_per_serving * default_count, 1)
        total_fat = round(fat_per_serving * default_count, 1)
        total_fiber = round(fiber_per_serving * default_count, 1)

        # Build serving description
        if default_count > 1:
            amount = f"{default_count} x {serving_g:.0f}g"
        elif override.get("override_serving_g"):
            amount = f"{serving_g:.0f}g serving"
        elif override.get("override_weight_per_piece_g"):
            amount = f"1 piece ({serving_g:.0f}g)"
        else:
            amount = "100g"

        # Scale micronutrients by serving size and count (same as macros)
        micro_keys = (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        )
        scaled_micros = {}
        per_gram_micros = {}
        for key in micro_keys:
            val = override.get(key)
            if val is not None:
                scaled_micros[key] = round(val * scale * default_count, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(serving_g * default_count, 1),
            "weight_source": "exact",
            "unit": "g",
            # Per-gram scaling for frontend weight adjustment slider
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        # Add weight_per_unit_g for count-based adjustment
        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]
            food_item["count"] = default_count

        score = self._compute_health_score(total_calories, total_protein, total_fiber)

        result = {
            "food_items": [food_item],
            "total_calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            "data_source": "override",
            "restaurant_name": override.get("restaurant_name"),
            "food_category": override.get("food_category"),
        }
        # Add scaled micronutrients to top-level response
        result.update(scaled_micros)
        return result

    @staticmethod
    def _inject_default_modifiers(
        result: Dict[str, Any], food_key: str, override: Dict[str, Any]
    ) -> None:
        """Inject default modifier groups (e.g. steak doneness) into analysis result."""
        # Check both the lookup key and the override's food_name_normalized
        override_name = override.get("food_name_normalized", "")
        default_mods = _build_default_modifiers(food_key)
        if not default_mods:
            default_mods = _build_default_modifiers(override_name)
        if not default_mods:
            return

        food_items = result.get("food_items", [])
        if not food_items:
            return
        fi = food_items[0]
        existing_mods = fi.get("modifiers", [])
        # Don't inject if a modifier of the same group already exists
        existing_groups = {m.get("group") for m in existing_mods if m.get("group")}
        for mod in default_mods:
            if mod.get("group") not in existing_groups:
                existing_mods.append(mod)
        fi["modifiers"] = existing_mods

    def _override_to_analysis_by_weight(
        self, override: Dict[str, Any], weight_g: float
    ) -> Dict[str, Any]:
        """
        Convert override to analysis using explicit weight in grams.
        Scales per-100g data by weight_g/100.

        Args:
            override: Override dict from FoodDatabaseLookupService
            weight_g: Explicit weight in grams

        Returns:
            Dict in same format as Gemini analysis
        """
        scale = weight_g / 100.0

        total_calories = round(override["calories_per_100g"] * scale)
        total_protein = round(override["protein_per_100g"] * scale, 1)
        total_carbs = round(override["carbs_per_100g"] * scale, 1)
        total_fat = round(override["fat_per_100g"] * scale, 1)
        total_fiber = round(override.get("fiber_per_100g", 0) * scale, 1)

        amount = f"{weight_g:.0f}g"

        micro_keys = (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        )
        scaled_micros = {}
        per_gram_micros = {}
        for key in micro_keys:
            val = override.get(key)
            if val is not None:
                scaled_micros[key] = round(val * scale, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(weight_g, 1),
            "weight_source": "exact",
            "unit": "g",
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]

        score = self._compute_health_score(total_calories, total_protein, total_fiber)

        result = {
            "food_items": [food_item],
            "total_calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            "data_source": "override",
            "restaurant_name": override.get("restaurant_name"),
            "food_category": override.get("food_category"),
        }
        result.update(scaled_micros)
        return result

    def _override_to_analysis_scaled(
        self, override: Dict[str, Any], count: float
    ) -> Dict[str, Any]:
        """
        Convert override to analysis scaled by a given count.
        Uses serving size (override_serving_g or override_weight_per_piece_g or 100g)
        as the base, then multiplies by count.

        Args:
            override: Override dict from FoodDatabaseLookupService
            count: Number of servings/pieces

        Returns:
            Dict in same format as Gemini analysis
        """
        serving_g = (
            override.get("override_serving_g")
            or override.get("override_weight_per_piece_g")
            or 100.0
        )
        scale = serving_g / 100.0

        calories_per_serving = round(override["calories_per_100g"] * scale)
        protein_per_serving = round(override["protein_per_100g"] * scale, 1)
        carbs_per_serving = round(override["carbs_per_100g"] * scale, 1)
        fat_per_serving = round(override["fat_per_100g"] * scale, 1)
        fiber_per_serving = round(override.get("fiber_per_100g", 0) * scale, 1)

        total_calories = round(calories_per_serving * count)
        total_protein = round(protein_per_serving * count, 1)
        total_carbs = round(carbs_per_serving * count, 1)
        total_fat = round(fat_per_serving * count, 1)
        total_fiber = round(fiber_per_serving * count, 1)

        # Build serving description
        count_display = int(count) if count == int(count) else count
        if override.get("override_weight_per_piece_g"):
            amount = f"{count_display} piece{'s' if count != 1 else ''} ({round(serving_g * count):.0f}g)"
        else:
            amount = f"{count_display} x {serving_g:.0f}g"

        micro_keys = (
            "sodium_mg", "cholesterol_mg", "saturated_fat_g", "trans_fat_g",
            "potassium_mg", "calcium_mg", "iron_mg", "vitamin_a_ug",
            "vitamin_c_mg", "vitamin_d_iu", "magnesium_mg", "zinc_mg",
            "phosphorus_mg", "selenium_ug", "omega3_g",
        )
        scaled_micros = {}
        per_gram_micros = {}
        for key in micro_keys:
            val = override.get(key)
            if val is not None:
                scaled_micros[key] = round(val * scale * count, 2)
                per_gram_micros[key] = round(val / 100, 4)

        food_item = {
            "name": override["display_name"],
            "amount": amount,
            "calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "weight_g": round(serving_g * count, 1),
            "weight_source": "exact",
            "unit": "g",
            "ai_per_gram": {
                "calories": round(override["calories_per_100g"] / 100, 3),
                "protein": round(override["protein_per_100g"] / 100, 4),
                "carbs": round(override["carbs_per_100g"] / 100, 4),
                "fat": round(override["fat_per_100g"] / 100, 4),
                "fiber": round(override.get("fiber_per_100g", 0) / 100, 4),
                **per_gram_micros,
            },
        }

        if override.get("override_weight_per_piece_g"):
            food_item["weight_per_unit_g"] = override["override_weight_per_piece_g"]
            food_item["count"] = count_display

        score = self._compute_health_score(total_calories, total_protein, total_fiber)

        result = {
            "food_items": [food_item],
            "total_calories": total_calories,
            "protein_g": total_protein,
            "carbs_g": total_carbs,
            "fat_g": total_fat,
            "fiber_g": total_fiber,
            "encouragements": [],
            "warnings": [],
            "ai_suggestion": None,
            "recommended_swap": None,
            "overall_meal_score": score,
            "health_score": score,
            "data_source": "override",
            "restaurant_name": override.get("restaurant_name"),
            "food_category": override.get("food_category"),
        }
        result.update(scaled_micros)
        return result

    async def _auto_learn_food_items(self, analysis_result: Dict[str, Any]) -> None:
        """
        Auto-learn individual food items from a Gemini analysis result
        into the common_foods table for faster future lookups.

        Args:
            analysis_result: Successful Gemini food analysis result
        """
        food_items = analysis_result.get("food_items", [])
        if not food_items:
            return

        for item in food_items:
            try:
                name = item.get("name")
                if not name:
                    continue

                # Build micronutrients dict from item or top-level result
                micro_keys = [
                    "sugar_g", "sodium_mg", "cholesterol_mg",
                    "vitamin_a_ug", "vitamin_c_mg", "vitamin_d_iu",
                    "calcium_mg", "iron_mg", "potassium_mg",
                ]
                micronutrients = {}
                for key in micro_keys:
                    val = item.get(key) or analysis_result.get(key)
                    if val is not None:
                        micronutrients[key] = val

                # Infer category from food name
                category = self._infer_food_category(name)

                self.nutrition_db.upsert_learned_food(
                    name=name,
                    serving_size=item.get("amount", "1 serving"),
                    serving_weight_g=float(item.get("weight_g") or 0),
                    calories=int(item.get("calories") or 0),
                    protein_g=float(item.get("protein_g") or 0),
                    carbs_g=float(item.get("carbs_g") or 0),
                    fat_g=float(item.get("fat_g") or 0),
                    fiber_g=float(item.get("fiber_g") or 0),
                    micronutrients=micronutrients,
                    category=category,
                    source="ai_learned",
                )
                logger.info(f"✅ Auto-learned food: {name}")
            except Exception as e:
                logger.error(f"❌ Failed to auto-learn food '{item.get('name')}': {e}")

    @staticmethod
    def _infer_food_category(name: str) -> str:
        """Infer a food category from the food name using keyword heuristics."""
        lower = name.lower()
        protein_keywords = ["chicken", "beef", "fish", "salmon", "tuna", "egg",
                            "shrimp", "pork", "lamb", "turkey", "tofu", "paneer"]
        grain_keywords = ["rice", "bread", "pasta", "noodle", "roti", "naan",
                          "oat", "cereal", "wheat", "chapati"]
        fruit_keywords = ["apple", "banana", "mango", "orange", "grape",
                          "berry", "melon", "pear", "peach", "plum"]
        veg_keywords = ["broccoli", "spinach", "carrot", "tomato", "onion",
                        "potato", "lettuce", "cucumber", "pepper", "cabbage"]
        dairy_keywords = ["milk", "cheese", "yogurt", "curd", "butter", "cream"]

        for kw in protein_keywords:
            if kw in lower:
                return "protein"
        for kw in grain_keywords:
            if kw in lower:
                return "grains"
        for kw in fruit_keywords:
            if kw in lower:
                return "fruit"
        for kw in veg_keywords:
            if kw in lower:
                return "vegetable"
        for kw in dairy_keywords:
            if kw in lower:
                return "dairy"
        return "general"

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

    def _split_text_into_parts(self, text: str) -> List[str]:
        """Split text into individual food strings using newlines, commas, and conjunctions."""
        # Step 1: Split on newlines
        lines = [l.strip() for l in text.split('\n') if l.strip()]
        parts: List[str] = []
        for line in lines:
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
        # Split on " with " ONLY when the right side starts with a quantity/unit.
        # "5 dosas with 200ml lassi" → split (right side: "200ml lassi")
        # "dosa with chutney"        → keep  (right side: "chutney", no qty)
        # "coffee with milk"         → keep  (right side: "milk", no qty)
        with_parts = re.split(r'\s+with\s+', text, flags=re.IGNORECASE)
        if len(with_parts) > 1:
            smart_merged: List[str] = [with_parts[0]]
            for wp in with_parts[1:]:
                if self._RIGHT_SIDE_QTY_RE.match(wp):
                    # Right side has a quantity → treat as separate item
                    smart_merged.append(wp)
                else:
                    # Right side has no quantity → rejoin with " with "
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

            override = lookup_service._check_override(food_name)

            # Fuzzy fallback
            if not override:
                fuzzy_matches = lookup_service._find_matching_overrides_for_search(food_name)
                if fuzzy_matches:
                    # Use the best match (highest similarity)
                    best = fuzzy_matches[0]
                    best_name = best.get("name", "")
                    override = lookup_service._check_override(best_name)

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
