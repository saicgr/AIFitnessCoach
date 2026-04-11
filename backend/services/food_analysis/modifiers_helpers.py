"""Helper functions extracted from modifiers.
Food modifier data, metadata, and classification.

Contains the comprehensive _FOOD_MODIFIERS dict (nutritional deltas for food
customizations), _MODIFIER_METADATA (weight/type info), modifier group mappings,
and helper functions for classification and default modifier building.


"""
from typing import Any, Dict, List, NamedTuple, Optional
from enum import Enum
import re


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
    scale_factor: Optional[float] = None  # Multiplicative portion scaling (0.35 = 35% of regular serving weight)


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

    # ── Size / portion (with multiplicative scale_factor) ──
    "mini":             ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Mini", scale_factor=0.5),
    "small":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Small", scale_factor=0.7),
    "make it small":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Small", scale_factor=0.7),
    "half portion":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Half Portion", scale_factor=0.5),
    "large":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Large", scale_factor=1.5),
    "make it large":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Large", scale_factor=1.5),
    "extra large":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Extra Large", scale_factor=2.0),
    "supersize":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Supersize", scale_factor=2.5),

    # ── Side / restaurant portion sizes ──
    "side":             ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),
    "side of":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),
    "side order":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side Order", scale_factor=0.35),
    "side order of":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side Order", scale_factor=0.35),
    "as a side":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),
    "just a side":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),
    "just a side of":   ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),
    "for a side":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Side", scale_factor=0.35),

    # ── Kids / junior / petite ──
    "kids":             ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids", scale_factor=0.5),
    "kid's":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids", scale_factor=0.5),
    "kiddie":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids", scale_factor=0.5),
    "children's":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids", scale_factor=0.5),
    "kids size":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids Size", scale_factor=0.5),
    "kids meal":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Kids Meal", scale_factor=0.5),
    "junior":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Junior", scale_factor=0.6),
    "jr":               ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Junior", scale_factor=0.6),
    "petite":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Petite", scale_factor=0.5),
    "personal":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Personal", scale_factor=0.5),

    # ── Appetizer / starter / tasting ──
    "appetizer portion": ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Appetizer Portion", scale_factor=0.4),
    "appetizer size":   ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Appetizer Size", scale_factor=0.4),
    "starter portion":  ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Starter Portion", scale_factor=0.4),
    "tasting":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Tasting", scale_factor=0.15),
    "tasting portion":  ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Tasting Portion", scale_factor=0.15),
    "sample":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Sample", scale_factor=0.15),
    "taster":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Taster", scale_factor=0.15),

    # ── Shared / split ──
    "shared":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Shared", scale_factor=0.5),
    "split":            ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Split", scale_factor=0.5),
    "split with":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Split", scale_factor=0.5),

    # ── Existing zero-delta entries — now with scale_factor ──
    "bite size":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Bite Size", scale_factor=0.15),
    "bite-size":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Bite Size", scale_factor=0.15),
    "snack size":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Snack Size", scale_factor=0.4),
    "fun size":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Fun Size", scale_factor=0.3),
    "king size":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="King Size", scale_factor=2.0),
    "family size":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Family Size", scale_factor=3.5),
    "sharing size":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Sharing Size", scale_factor=2.5),
    "single":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Single", scale_factor=1.0),
    "double":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Double", scale_factor=2.0),
    "triple":           ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Triple", scale_factor=3.0),

    # ── Informal portion language (scale_factor) ──
    "a bite of":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bite", scale_factor=0.1),
    "just a bite":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bite", scale_factor=0.1),
    "just a bite of":   ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bite", scale_factor=0.1),
    "a few bites of":   ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Few Bites", scale_factor=0.15),
    "a taste of":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Taste", scale_factor=0.1),
    "just a taste":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Taste", scale_factor=0.1),
    "just a taste of":  ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Taste", scale_factor=0.1),
    "a sliver of":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Sliver", scale_factor=0.1),
    "a little":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Little", scale_factor=0.3),
    "a little bit of":  ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Little", scale_factor=0.3),
    "just a little":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Little", scale_factor=0.3),
    "just a little of": ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Little", scale_factor=0.3),
    "a bit of":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bit", scale_factor=0.35),
    "just a bit":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bit", scale_factor=0.35),
    "just a bit of":    ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bit", scale_factor=0.35),
    "nibbled":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Nibbled", scale_factor=0.15),
    "nibbled on":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Nibbled", scale_factor=0.15),
    "picked at":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Picked At", scale_factor=0.2),

    # ── Vague quantity modifiers ──
    "just some":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Just Some", scale_factor=0.5),
    "just some of":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Just Some", scale_factor=0.5),
    "only some":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Only Some", scale_factor=0.5),
    "only some of":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Only Some", scale_factor=0.5),
    "some of the":      ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Some Of", scale_factor=0.5),
    "some of":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Some Of", scale_factor=0.5),
    "a lot of":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Lot", scale_factor=1.5),
    "lots of":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Lots", scale_factor=1.5),
    "plenty of":        ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Plenty", scale_factor=1.5),
    "a bunch of":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Bunch", scale_factor=1.5),
    "a ton of":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="A Ton", scale_factor=2.0),
    "tons of":          ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Tons", scale_factor=2.0),
    "hardly any":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Hardly Any", scale_factor=0.1),
    "barely any":       ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Barely Any", scale_factor=0.1),
    "not much":         ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Not Much", scale_factor=0.4),
    "not a lot of":     ModifierMeta(ModifierType.SIZE_PORTION, group="size", display_label="Not A Lot", scale_factor=0.4),

    # ── Fixed-weight application descriptors (use default_weight_g, NOT scale_factor) ──
    "a pinch of":       ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=1.0, display_label="A Pinch"),
    "a dash of":        ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=1.0, display_label="A Dash"),
    "a smidge of":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=2.0, display_label="A Smidge"),
    "a smidgen of":     ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=2.0, display_label="A Smidgen"),
    "a hint of":        ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=2.0, display_label="A Hint"),
    "a dusting of":     ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=3.0, display_label="A Dusting"),
    "dusted with":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=3.0, display_label="Dusted With"),
    "a sprinkle of":    ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=4.0, display_label="A Sprinkle"),
    "sprinkled with":   ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=4.0, display_label="Sprinkled With"),
    "a touch of":       ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=4.0, display_label="A Touch"),
    "a garnish of":     ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=5.0, display_label="A Garnish"),
    "garnished with":   ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=5.0, display_label="Garnished With"),
    "a smattering of":  ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=4.0, display_label="A Smattering"),
    "a dab of":         ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=5.0, display_label="A Dab"),
    "a squirt of":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=8.0, display_label="A Squirt"),
    "a squeeze of":     ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=8.0, display_label="A Squeeze"),
    "a drizzle of":     ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=8.0, display_label="A Drizzle"),
    "drizzled with":    ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=8.0, display_label="Drizzled With"),
    "a swirl of":       ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=12.0, display_label="A Swirl"),
    "a smear of":       ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=12.0, display_label="A Smear"),
    "a splash of":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=15.0, display_label="A Splash"),
    "a dollop of":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=15.0, display_label="A Dollop"),
    "a spread of":      ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=20.0, display_label="A Spread"),
    "a glob of":        ModifierMeta(ModifierType.SIZE_PORTION, default_weight_g=25.0, display_label="A Glob"),

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
        "mini", "small", "half portion", "side", "side of", "kids", "junior",
        "petite", "personal", "snack size", "fun size", "large", "extra large",
        "supersize", "king size", "family size", "sharing size",
        "single", "double", "triple",
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
    from services.food_analysis.modifiers import _FOOD_MODIFIERS
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
    from services.food_analysis.modifiers import _FOOD_MODIFIERS
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


# Lazy-initialized regex patterns (depend on _FOOD_MODIFIERS from parent module)
_MODIFIER_PHRASES_SORTED = None
_MODIFIER_REGEX = None
_NUM_UNIT_REGEX = None
_WORD_NUM_UNIT_REGEX = None
_BULLET_REGEX = None
_BARE_NUM_REGEX = None
_FRACTION_REGEX = None


def _init_modifier_patterns(food_modifiers=None):
    """Initialize regex patterns that depend on _FOOD_MODIFIERS (lazy to avoid circular imports).

    Args:
        food_modifiers: The _FOOD_MODIFIERS dict. If None, imports it (for backward compat).
    """
    global _MODIFIER_PHRASES_SORTED, _MODIFIER_REGEX, _NUM_UNIT_REGEX
    global _WORD_NUM_UNIT_REGEX, _BULLET_REGEX, _BARE_NUM_REGEX, _FRACTION_REGEX

    if _MODIFIER_PHRASES_SORTED is not None:
        return

    if food_modifiers is None:
        from services.food_analysis.modifiers import _FOOD_MODIFIERS
        food_modifiers = _FOOD_MODIFIERS
    from services.food_analysis.constants import _COUNT_UNITS, _WORD_NUMBERS

    # Pre-sorted by phrase length (longest first) to avoid partial matches
    phrases_sorted = sorted(food_modifiers.keys(), key=len, reverse=True)

    # Regex to extract modifier phrases from text
    _MODIFIER_REGEX = re.compile(
        r'\b(' + '|'.join(re.escape(p) for p in phrases_sorted) + r')\b',
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

    # Word number + optional unit
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

    # Set the sentinel LAST so concurrent callers don't see early return
    # before all other globals are initialized
    _MODIFIER_PHRASES_SORTED = phrases_sorted

