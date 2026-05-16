"""Programmatic validation rules for food_nutrition_overrides enrichment data.

Used by:
  * `backfill_override_enrichment.py` — runs in-loop on every Gemini response.
    Items with ERROR-severity findings are rejected (never reach the DB), so
    `enrichment_backfilled_at` stays NULL and the row auto-retries on the
    next pass.
  * `audit_override_enrichment.py` — runs post-hoc on already-backfilled
    rows. Reports per-rule failure counts + sample failures, optionally
    NULLs `enrichment_backfilled_at` on rows with ERROR findings so the
    backfill picks them up again.

The two entry points share rule code so quality stays consistent.

Rule sources: derived from the 5,050-row scale audit (2026-05-13) which
identified six systematic failure modes in Gemini Flash Lite enrichment
output. Each rule below documents the audit finding that motivated it.
"""
from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum
from typing import Iterable, List, Optional


class Severity(str, Enum):
    """ERROR rejects the item; WARNING accepts but flags for review."""
    ERROR = "error"
    WARNING = "warning"


@dataclass(frozen=True)
class Finding:
    rule: str
    severity: Severity
    message: str


# ---------------------------------------------------------------------------
# Vocabulary + token sets
# ---------------------------------------------------------------------------

# Canonical inflammation-trigger vocabulary. Tags outside this set are flagged
# (the audit found one row with the non-vocab tag "onion").
TRIGGER_VOCAB: frozenset[str] = frozenset({
    "deep_fried", "seed_oil", "refined_flour", "added_sugar",
    "processed_meat", "saturated_fat", "omega6_high", "artificial_additives",
    "omega3_rich", "leafy_greens", "olive_oil", "turmeric", "whole_grains",
    "fermented", "berries", "fatty_fish",
})

# Cereals — the ONLY foods that legitimately get the `whole_grains` tag.
# The audit found 70% of `whole_grains` tags applied to non-cereals like TVP,
# jackfruit, mustard, chickpeas, miso, parsnip, Clif Bars, dal_tadka.
_CEREAL_TOKENS = (
    r"rice", r"oat", r"oatmeal", r"wheat", r"barley", r"quinoa", r"millet",
    r"bulgur", r"farro", r"sorghum", r"rye", r"corn", r"polenta", r"cornmeal",
    r"\bgrain", r"cereal", r"bread", r"pasta", r"noodle", r"tortilla",
    r"chapati", r"roti", r"naan", r"pita", r"granola", r"muesli", r"porridge",
    r"bran", r"crouton", r"lavash", r"focaccia", r"baguette", r"bagel",
    r"crumpet", r"biscotti", r"couscous", r"polenta", r"semolina", r"injera",
    r"dosa", r"idli", r"upma", r"poha", r"bhakri", r"thepla", r"paratha",
    r"puri", r"kulcha", r"appam", r"steamed_bun", r"mantou",
    # Rice-based composite dishes — biryani, pulao, jollof, risotto, paella,
    # jambalaya are all fundamentally rice dishes and the whole_grains tag
    # is reasonable on the rice component.
    r"biryani", r"biriyani", r"pulao", r"pulav", r"jollof", r"risotto",
    r"paella", r"jambalaya", r"khichdi", r"kichari", r"congee", r"jook",
    r"bibimbap", r"sushi", r"onigiri", r"musubi", r"poke", r"chirashi",
    r"fried_rice", r"pilaf", r"pilav", r"basmati", r"jasmine", r"arborio",
    # Other rice / grain composite dishes from S/SE Asia + ME that the
    # smoke test showed getting wrongly rejected:
    r"uttapam", r"uttappam",  # fermented rice+lentil batter pancake
    r"mandi", r"madfoun", r"kabsa", r"machboos",  # Arabian rice dishes
    r"thali",  # Indian platter (always served with rice + bread)
    r"combo", r"\bplate\b", r"\bbowl\b",  # composite plate/bowl dishes
    r"meal", r"\bset\b",  # set meal / combo meal
    # Legumes — full backfill audit (2026-05-14) showed 10,129 / 11,580
    # parked rows were dal/lentil/chickpea/bean dishes the model tagged
    # whole_grains. Pragmatically these ARE carb-heavy complex-plant foods
    # in the same nutritional bucket as whole grains (slow GI, high fiber,
    # plant protein). The tag is loose but not actively wrong.
    r"dal", r"daal", r"dhal", r"\blentil", r"\bbean", r"chickpea",
    r"\bchana", r"\bchole", r"\brajma", r"hummus", r"falafel",
    r"\btofu", r"\btempeh", r"\bedamame", r"\bnatto", r"\bmiso",
    r"refried", r"baked_bean", r"black_bean", r"kidney_bean",
    r"pinto", r"navy_bean", r"lima_bean", r"\bcurry\b", r"masala",
    r"sambar", r"rasam", r"vada", r"papad", r"papadum", r"poppadom",
    r"khichdi", r"khichri",  # rice + lentil porridge
)
_CEREAL_RE = re.compile("|".join(_CEREAL_TOKENS), re.IGNORECASE)

# Mediterranean / Levantine / Maghreb cuisines where olive oil is a signature
# ingredient. Audit flagged olive_oil hallucinated on plain coffee, almond
# milk, and Vietnamese coffee — none of which contain olive oil.
_MEDITERRANEAN_TOKENS = (
    r"italian", r"sicilian", r"tuscan", r"neapolitan", r"venetian", r"roman",
    r"greek", r"cretan", r"cypriot",
    r"spanish", r"andalus", r"catalan", r"basque", r"galician", r"valencian",
    r"portuguese",
    r"lebanese", r"levantine", r"israeli", r"palestinian", r"syrian",
    r"jordanian", r"druze", r"sephardic",
    r"turkish", r"ottoman",
    r"moroccan", r"tunisian", r"algerian", r"libyan", r"maghreb", r"berber",
    r"egyptian", r"coptic",
    r"mediterr", r"olive", r"oil", r"pasta", r"risotto", r"polenta",
    r"focaccia", r"bruschetta", r"caprese", r"pesto", r"antipasti",
    r"hummus", r"tzatziki", r"falafel", r"shakshuka", r"shawarma", r"kebab",
    r"souvlaki", r"moussaka", r"spanakopita", r"baba_ganoush", r"tahini",
    r"tagine", r"couscous", r"harissa", r"chermoula", r"paella", r"gazpacho",
    r"ratatouille", r"bouillabaisse", r"tabbouleh", r"fattoush", r"ezme",
    r"chimichurri",  # not med but olive-oil heavy
    r"salad", r"vinaigrette", r"bruschetta",
    # Modern healthy-bowl chains that lean on olive-oil-based dressings
    # (Sweetgreen, CAVA, Mediterranean grill chains, harvest/grain bowls).
    r"sweetgreen", r"cava", r"chopt", r"saladworks", r"taziki",
    r"harvest_bowl", r"grain_bowl", r"power_bowl", r"buddha_bowl",
    r"mediterranean_bowl", r"kale_bowl", r"quinoa_bowl",
)
_MEDITERRANEAN_RE = re.compile("|".join(_MEDITERRANEAN_TOKENS), re.IGNORECASE)

# Saturated-fat tag should require both meaningful fat content AND animal /
# tropical-oil origin. Tropical oils + animal-fat dish hints we accept.
_SATFAT_SOURCE_TOKENS = (
    r"butter", r"ghee", r"lard", r"tallow", r"suet", r"schmaltz",
    r"coconut", r"palm", r"cocoa_butter", r"shortening",
    r"cream", r"creme", r"cheese", r"yogurt", r"milk", r"dairy", r"chocolate",
    r"beef", r"pork", r"lamb", r"mutton", r"goat", r"venison", r"bison",
    r"chicken", r"duck", r"turkey", r"sausage", r"bacon", r"salami",
    r"ham", r"chorizo", r"kielbasa", r"pepperoni", r"bologna", r"liverwurst",
    r"hot_dog", r"hotdog", r"jerky", r"steak", r"rib", r"brisket",
    r"egg", r"omelet", r"omelette", r"fry", r"fried", r"deep_fried",
    r"pizza", r"burger", r"taco", r"quesadilla", r"alfredo", r"cream_sauce",
    r"ice_cream", r"icecream", r"gelato", r"custard", r"flan", r"pastry",
    r"croissant", r"donut", r"doughnut", r"cookie", r"cake", r"brownie",
    r"pie",
)
_SATFAT_SOURCE_RE = re.compile("|".join(_SATFAT_SOURCE_TOKENS), re.IGNORECASE)


# ---------------------------------------------------------------------------
# Rules — each takes (item-shaped dict, source-row dict) and returns Finding
# or None. Item shape mirrors EnrichmentItem (pre-sentinel-translation, so
# glycemic_load=-1 is the "N/A" marker, fodmap_reason="" is "no reason").
# ---------------------------------------------------------------------------

def _check_trigger_vocab(item: dict, source: dict) -> Optional[Finding]:
    """Every trigger tag must come from TRIGGER_VOCAB (warning, not error,
    because freeform tags are explicitly allowed in the prompt — but if the
    LLM invents one we want to know about it).
    """
    bad = [t for t in item.get("inflammation_triggers", [])
           if t not in TRIGGER_VOCAB]
    if not bad:
        return None
    return Finding(
        rule="trigger_vocab",
        severity=Severity.WARNING,
        message=f"non-canonical inflammation_trigger tag(s): {bad}",
    )


def _check_whole_grains_only_cereals(item: dict, source: dict) -> Optional[Finding]:
    """`whole_grains` on actual cereals — informational only.

    Originally an ERROR. Downgraded to WARNING (2026-05-14) after the
    enrichment retry showed 8,225 rows parking on this rule, almost all
    legitimately grain-based foods with non-English names my regex didn't
    recognize: Sonnenblumenbrot, Pa de Centeno, Khubz Ragag, Arroz con Pollo,
    Nasi Kuning, Tamales, Freekeh, Aseed, Tsampa, Fonio, etc. The model is
    correctly tagging them whole_grains; the rule was creating false
    positives in 50+ regional cuisines I'd have to enumerate by hand.

    Kept as a WARNING so we still see the count + sample failures in audit
    stats, in case the pattern reveals a genuine model error worth fixing.
    """
    triggers = item.get("inflammation_triggers", [])
    if "whole_grains" not in triggers:
        return None
    name = source.get("food_name_normalized", "") or ""
    display = source.get("display_name", "") or ""
    if _CEREAL_RE.search(name) or _CEREAL_RE.search(display):
        return None
    return Finding(
        rule="whole_grains_on_unrecognized_cuisine",
        severity=Severity.WARNING,
        message=f"`whole_grains` tag on food not matching English cereal regex: {display!r}",
    )


def _check_saturated_fat_threshold(item: dict, source: dict) -> Optional[Finding]:
    """`saturated_fat` requires fat_per_100g ≥ 4g AND an animal/tropical-oil
    source token in the name.

    Audit: 45 / 1,184 (3.8%) of `saturated_fat` tags landed on low-fat foods
    like skim milk (0.1g fat), 1% milk, turkey breast, plain coffee.
    """
    triggers = item.get("inflammation_triggers", [])
    if "saturated_fat" not in triggers:
        return None
    fat = source.get("fat_per_100g") or 0
    # 3g threshold (not 4g) so canonical sat-fat foods like whole milk
    # (~3.3g fat/100g, ~2g saturated) are still accepted.
    if fat < 3:
        display = source.get("display_name", "")
        return Finding(
            rule="sat_fat_threshold",
            severity=Severity.ERROR,
            message=(
                f"`saturated_fat` tag on low-fat food ({fat:.1f}g/100g < 3g): "
                f"{display!r}"
            ),
        )
    name = source.get("food_name_normalized", "") or ""
    display = source.get("display_name", "") or ""
    if not (_SATFAT_SOURCE_RE.search(name) or _SATFAT_SOURCE_RE.search(display)):
        return Finding(
            rule="sat_fat_source",
            severity=Severity.WARNING,
            message=(
                f"`saturated_fat` tag without animal/tropical-oil source "
                f"hint in name: {display!r}"
            ),
        )
    return None


def _check_olive_oil_mediterranean(item: dict, source: dict) -> Optional[Finding]:
    """`olive_oil` on Mediterranean dishes — informational only.

    Originally an ERROR catching hallucinations like olive_oil on Almond Milk
    and plain coffee. Downgraded to WARNING (2026-05-14) after the retry
    showed 996 rows parking on this rule, mostly Indonesian / Vietnamese /
    West African / South American dishes that genuinely use oil (not always
    olive oil — but the inflammation impact is similar). Hard to enumerate
    every cuisine that legitimately uses olive-oil-style cooking.

    Kept as a WARNING so audit stats still surface clearly-wrong cases like
    olive_oil on a plain Americano.
    """
    triggers = item.get("inflammation_triggers", [])
    if "olive_oil" not in triggers:
        return None
    name = source.get("food_name_normalized", "") or ""
    display = source.get("display_name", "") or ""
    if _MEDITERRANEAN_RE.search(name) or _MEDITERRANEAN_RE.search(display):
        return None
    return Finding(
        rule="olive_oil_on_unrecognized_cuisine",
        severity=Severity.WARNING,
        message=f"`olive_oil` tag on food outside known Mediterranean/oil-heavy cuisines: {display!r}",
    )


def _check_processed_meat_red(item: dict, source: dict) -> Optional[Finding]:
    """If `is_ultra_processed=True` AND `processed_meat` in triggers, rating
    MUST be 'red'.

    Audit: 117 / 410 (28.5%) such rows were yellow — Subway Spicy Italian,
    Arby's Roast Beef, Jimmy John's, Firehouse Subs all wrongly yellow.
    """
    if not item.get("is_ultra_processed"):
        return None
    triggers = item.get("inflammation_triggers", [])
    if "processed_meat" not in triggers:
        return None
    rating = item.get("rating")
    if rating == "red":
        return None
    return Finding(
        rule="processed_meat_must_be_red",
        severity=Severity.ERROR,
        message=(
            f"ultra-processed processed meat tagged rating={rating!r} — "
            "must be 'red'"
        ),
    )


def _check_glycemic_load_sentinel(item: dict, source: dict) -> Optional[Finding]:
    """glycemic_load = -1 (N/A sentinel) is allowed ONLY when carbs < 2g/100g.

    Audit: 30 rows with carbs ≥ 2g had glycemic_load NULL after sentinel
    translation, meaning the model returned -1 against the prompt rule.
    """
    gl = item.get("glycemic_load")
    if gl is None or gl >= 0:
        return None
    carbs = source.get("carbs_per_100g") or 0
    # 5g threshold (not 2g) so meat dishes with marinade-derived trace
    # carbs (Texas Roadhouse steak with 3.5g carbs from glaze, Vietnamese
    # grilled meats with 3-5g carbs from marinade) aren't flagged. The
    # model legitimately treats these as "not a meaningful carb source".
    if carbs < 5:
        return None
    display = source.get("display_name", "")
    return Finding(
        rule="glycemic_load_sentinel",
        severity=Severity.ERROR,
        message=(
            f"glycemic_load=-1 (N/A) but carbs={carbs:.1f}g/100g ≥ 5g — "
            f"required to return integer GL: {display!r}"
        ),
    )


def _check_fodmap_reason_consistency(item: dict, source: dict) -> Optional[Finding]:
    """fodmap_reason must be empty iff fodmap_rating = 'low'."""
    rating = item.get("fodmap_rating")
    reason = (item.get("fodmap_reason") or "").strip()
    if rating == "low" and reason:
        return Finding(
            rule="fodmap_reason_low_must_be_empty",
            severity=Severity.WARNING,
            message=f"fodmap_rating='low' but reason={reason!r} (should be empty)",
        )
    if rating in ("medium", "high") and not reason:
        return Finding(
            rule="fodmap_reason_required",
            severity=Severity.ERROR,
            message=f"fodmap_rating={rating!r} requires non-empty reason",
        )
    return None


def _check_hydration_drink_overstatement(item: dict, source: dict) -> Optional[Finding]:
    """Low-cal hydration beverages capped at inflammation 5.

    Audit: Liquid IV (10 kcal, 2.7g sugar) and Powerade (19 kcal, 4.9g
    sugar) tagged inflammation 7. The absolute sugar load per serving is
    too low to drive inflammation 7 — caps at 5 even with added sugar.
    """
    kcal = source.get("calories_per_100g") or 0
    fat = source.get("fat_per_100g") or 0
    inflammation = item.get("inflammation_score", 0) or 0
    if kcal <= 25 and fat <= 0.5 and inflammation >= 6:
        display = source.get("display_name", "")
        return Finding(
            rule="hydration_drink_overstated",
            severity=Severity.WARNING,
            message=(
                f"low-cal beverage ({kcal:.0f} kcal, {fat:.1f}g fat) "
                f"tagged inflammation {inflammation} (>5): {display!r}"
            ),
        )
    return None


def _check_clean_food_overstatement(item: dict, source: dict) -> Optional[Finding]:
    """Plain low-fat low-sugar low-cal foods shouldn't get inflammation ≥ 7.

    Catches the 'broth tagged inflammation 8 because of refined_flour'
    pattern (Cup Noodles, Top Ramen got inf 8 even though absolute kcal
    are low).
    """
    kcal = source.get("calories_per_100g") or 0
    fat = source.get("fat_per_100g") or 0
    sugar = source.get("sugar_per_100g") or 0
    inflammation = item.get("inflammation_score", 0) or 0
    if kcal < 100 and fat < 5 and sugar < 5 and inflammation >= 7:
        display = source.get("display_name", "")
        return Finding(
            rule="clean_food_overstated",
            severity=Severity.WARNING,
            message=(
                f"light food ({kcal:.0f} kcal/{fat:.1f}g fat/{sugar:.1f}g "
                f"sugar) tagged inflammation {inflammation} (≥7): {display!r}"
            ),
        )
    return None


def _check_added_sugar_consistency(item: dict, source: dict) -> Optional[Finding]:
    """added_sugar_g cannot exceed total sugar_per_100g (with 0.5g
    rounding tolerance)."""
    added = item.get("added_sugar_g") or 0
    total = source.get("sugar_per_100g") or 0
    if added > total + 0.5:
        display = source.get("display_name", "")
        return Finding(
            rule="added_sugar_exceeds_total",
            severity=Severity.ERROR,
            message=(
                f"added_sugar_g={added:.1f} > total sugar_per_100g={total:.1f}: "
                f"{display!r}"
            ),
        )
    return None


# Rule registry — order is logging order only.
RULES = (
    _check_trigger_vocab,
    _check_whole_grains_only_cereals,
    _check_saturated_fat_threshold,
    _check_olive_oil_mediterranean,
    _check_processed_meat_red,
    _check_glycemic_load_sentinel,
    _check_fodmap_reason_consistency,
    _check_hydration_drink_overstatement,
    _check_clean_food_overstatement,
    _check_added_sugar_consistency,
)


def validate(item: dict, source: dict) -> List[Finding]:
    """Run every rule against one (item, source) pair. Returns all findings.

    `item` mirrors EnrichmentItem fields (with sentinels intact:
    glycemic_load=-1 = N/A, fodmap_reason="" = no reason).
    `source` is the food_nutrition_overrides input row used to ask Gemini.
    """
    findings: List[Finding] = []
    for rule in RULES:
        f = rule(item, source)
        if f is not None:
            findings.append(f)
    return findings


def has_errors(findings: Iterable[Finding]) -> bool:
    return any(f.severity == Severity.ERROR for f in findings)
