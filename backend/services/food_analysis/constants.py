"""
Parsing constants for food text analysis.

Contains regex patterns, word number mappings, unit sets, and
filler phrase patterns used to clean natural-language food descriptions.
"""
import re


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
    # ─��� Phrasal verb fillers ──
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
    # ── Large quantity eating ���─
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
    # ��─ Limiting ──
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
    # ─�� Mid-sentence noise ──
    # NOTE: "well" must not match before "done" (well done steak)
    r'|(?:um|uh|hmm|well(?!\s+done)|okay|ok|so|yeah)\s+'
    # ── Approximations ──
    r'|(?:about|maybe|around|approximately|roughly|nearly|like|roughly|probably|i\s+think)\s+'
    r')',
    re.IGNORECASE,
)
