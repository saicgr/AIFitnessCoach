"""Helper functions extracted from modifiers."""
Food modifier data, metadata, and classification.

Contains the comprehensive _FOOD_MODIFIERS dict (nutritional deltas for food
customizations), _MODIFIER_METADATA (weight/type info), modifier group mappings,
and helper functions for classification and default modifier building.


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

