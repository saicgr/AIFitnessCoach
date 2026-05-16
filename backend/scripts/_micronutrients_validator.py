"""Per-100g sanity validator for micronutrient backfill (USDA + Gemini).

Strict ranges: anything physiologically impossible per 100g of food is
rejected. Limits derived from highest-known natural foods (e.g. organ meats
for iron + vitamin A; oysters for zinc; egg yolks for cholesterol; salt /
soy sauce for sodium).

Used by `backfill_override_micronutrients.py` in-loop and reusable from
the audit script for post-hoc re-checking.

Severity model mirrors the enrichment validator (Severity.ERROR rejects the
write; Severity.WARNING is logged but accepted).
"""
from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Iterable, List, Optional, Tuple


class Severity(str, Enum):
    ERROR = "error"
    WARNING = "warning"


@dataclass(frozen=True)
class Finding:
    rule: str
    severity: Severity
    message: str


# Per-100g upper bounds. Lower bound for all is 0 (nothing can be negative).
# Sources: USDA FoodData Central highest-known foods + nutrition textbooks.
# Anything above the upper bound is physiologically impossible per 100g.
RANGES = {
    # Macronutrient cross-checks
    "saturated_fat_g":    (0, 100),     # pure butter ~50g; pure coconut oil ~87g
    "trans_fat_g":        (0, 10),      # heavily hydrogenated margarine ~5g
    "cholesterol_mg":     (0, 3500),    # egg yolk ~1085mg, brain meat ~3010mg
    # Minerals
    "sodium_mg":          (0, 40000),   # salt itself = 38758mg/100g; soy sauce ~5500
    "potassium_mg":       (0, 5000),    # cream of tartar ~16500 but dried herbs ~3700
    "calcium_mg":         (0, 2500),    # parmesan ~1200, dried herbs ~2000
    "iron_mg":            (0, 130),     # thyme dried ~123, spirulina ~28
    "magnesium_mg":       (0, 800),     # cocoa powder ~500, sea moss ~700
    "zinc_mg":            (0, 100),     # oysters ~78
    "phosphorus_mg":      (0, 2000),    # parmesan ~700, dried fish ~900
    "selenium_ug":        (0, 2000),    # brazil nuts ~1900
    "copper_mg":          (0, 50),      # beef liver ~9.8, oysters ~4.5
    "manganese_mg":       (0, 50),      # cloves ~30, oats ~3.6
    # Vitamins
    "vitamin_a_ug":       (0, 50000),   # beef liver RAE ~9442, seaweed RE up to ~30000
    "vitamin_c_mg":       (0, 3000),    # acerola cherry ~1677
    "vitamin_d_iu":       (0, 2000),    # cod liver oil ~10000 outlier; food norm <2000
    "vitamin_e_mg":       (0, 200),     # wheat germ oil ~149
    "vitamin_k_ug":       (0, 5000),    # natto ~1100, dried parsley ~1714
    "vitamin_b1_mg":      (0, 50),      # nutritional yeast ~31, thiamin
    "vitamin_b2_mg":      (0, 50),      # liver ~3, fortified yeast ~17, riboflavin
    "vitamin_b3_mg":      (0, 200),     # nutritional yeast ~120, liver ~17, niacin
    "vitamin_b5_mg":      (0, 50),      # liver ~7, sunflower seeds ~7, pantothenic
    "vitamin_b6_mg":      (0, 30),      # nutritional yeast ~20
    "vitamin_b7_ug":      (0, 1000),    # liver ~42, biotin
    "vitamin_b9_ug":      (0, 5000),    # baker's yeast ~3912, liver ~290, folate
    "vitamin_b12_ug":     (0, 200),     # liver ~83, clams ~98
    "choline_mg":         (0, 1000),    # egg yolk ~820
    # Fatty acids
    "omega3_g":           (0, 50),      # salmon ~2.5, flax oil ~53
    "omega6_g":           (0, 80),      # safflower oil ~75
}


def _check_ranges(item: dict, source: dict) -> List[Finding]:
    """Reject any field outside its physiologically plausible per-100g range."""
    findings: List[Finding] = []
    for field, (lo, hi) in RANGES.items():
        v = item.get(field)
        if v is None:
            continue
        try:
            v = float(v)
        except (TypeError, ValueError):
            findings.append(Finding(
                rule="numeric_type",
                severity=Severity.ERROR,
                message=f"{field}={v!r} is not numeric",
            ))
            continue
        if v < lo:
            findings.append(Finding(
                rule="negative_value",
                severity=Severity.ERROR,
                message=f"{field}={v} is negative",
            ))
        elif v > hi:
            findings.append(Finding(
                rule="impossible_per_100g",
                severity=Severity.ERROR,
                message=(
                    f"{field}={v} exceeds upper bound {hi} per 100g "
                    f"({source.get('display_name')!r})"
                ),
            ))
    return findings


def _check_satfat_lte_total_fat(item: dict, source: dict) -> Optional[Finding]:
    """Saturated fat is a SUBSET of total fat. Cannot exceed it (with 0.5g
    rounding tolerance)."""
    sat = item.get("saturated_fat_g")
    total = source.get("fat_per_100g") or 0
    if sat is None:
        return None
    if sat > total + 0.5:
        return Finding(
            rule="satfat_exceeds_total_fat",
            severity=Severity.ERROR,
            message=(
                f"saturated_fat_g={sat} > total fat_per_100g={total} "
                f"({source.get('display_name')!r}) — sat fat must be a "
                f"subset of total fat"
            ),
        )
    return None


def _check_omega_lte_total_fat(item: dict, source: dict) -> List[Finding]:
    """omega-3 + omega-6 are subsets of total fat too."""
    findings: List[Finding] = []
    total = source.get("fat_per_100g") or 0
    o3 = item.get("omega3_g") or 0
    o6 = item.get("omega6_g") or 0
    if (o3 + o6) > total + 1.0:
        findings.append(Finding(
            rule="omega_exceeds_total_fat",
            severity=Severity.ERROR,
            message=(
                f"omega3+omega6={o3+o6:.1f}g > total fat_per_100g={total}g "
                f"({source.get('display_name')!r})"
            ),
        ))
    return findings


def _check_zero_carb_zero_fiber(item: dict, source: dict) -> Optional[Finding]:
    """All-zero major minerals on a real food = bad write.

    Per user direction (2026-05-14): NULL is better than wrong data. A real
    food with calories>50 but Na=K=Ca=Fe=0 is usually a sign the model
    honestly returned zeros for a food it doesn't recognize.

    EXCEPTIONS (zeros are legitimate, NOT a bad write):
      * Pure fats / oils (fat ≥ 80g/100g, protein + carbs < 2g): oils, ghee,
        butter, cooking spray have no minerals because they're 100% fat.
        Smoke test (2026-05-14) wrongly cleared 17 oil rows — added this
        carve-out.
      * Pure sugar / syrups (sugar ≥ 80g/100g, protein + fat < 2g): sugar,
        honey, corn syrup have trace minerals at most.
      * Pure water / zero-cal (kcal < 20): water, plain seltzer, herbal tea.

    Treats `None` (USDA-style "not present") and `0` identically — both
    mean "no real data".
    """
    if not (
        (item.get("sodium_mg") or 0) == 0 and
        (item.get("potassium_mg") or 0) == 0 and
        (item.get("calcium_mg") or 0) == 0 and
        (item.get("iron_mg") or 0) == 0
    ):
        return None

    kcal    = source.get("calories_per_100g") or 0
    protein = source.get("protein_per_100g") or 0
    carbs   = source.get("carbs_per_100g")   or 0
    fat     = source.get("fat_per_100g")     or 0
    sugar   = source.get("sugar_per_100g")   or 0

    # Carve-out: pure-fat foods (oils, ghee, butter, cooking spray, animal
    # rendered fats). Two patterns:
    #   (a) absolute: fat ≥ 80g/100g + trace of other macros — classic oils
    #   (b) proportional: calories-from-fat ≥ 95% of total kcal + trace of
    #       other macros — catches oils with anomalously low absolute fat
    #       values (e.g. 'Coconut Oil Pressed' at 14.5g fat / 130 kcal, or
    #       'Mafuta a Mbewu' at 70g fat / 630 kcal — both 100% from fat,
    #       just with non-standard absolute values).
    if (protein + carbs) < 2:
        if fat >= 80:
            return None
        if kcal > 50 and (fat * 9) >= 0.95 * kcal:
            return None
    # Carve-out: pure sugar / syrup / honey
    if sugar >= 80 and (protein + fat) < 2:
        return None
    # Carve-out: zero-cal hydration (water, plain seltzer, herbal tea)
    if kcal < 20:
        return None
    # Carve-out: distilled spirits (whisky / vodka / rum / aquavit / brandy /
    # tequila / gin). Calories come entirely from ethanol (~7 kcal/g ×
    # ~30g/100g = ~210 kcal/100g) with literally zero macros and zero
    # micronutrients. Audit (2026-05-15) confirmed all 204 parked rows
    # were spirits — kcal>50 + P=C=F=0 is the unambiguous ethanol signature.
    if (protein + carbs + fat) < 1 and kcal > 50:
        return None

    if kcal > 50:
        return Finding(
            rule="all_zero_micronutrients",
            severity=Severity.ERROR,
            message=(
                f"all-zero major minerals on a {kcal} kcal/100g food "
                f"(P={protein:.1f} C={carbs:.1f} F={fat:.1f}): "
                f"{source.get('display_name')!r} — refusing to write fake zeros"
            ),
        )
    return None


RULES = (
    _check_satfat_lte_total_fat,
    _check_omega_lte_total_fat,
    _check_zero_carb_zero_fiber,
)


def validate(item: dict, source: dict) -> List[Finding]:
    """Run every rule against one (item, source) pair. Returns all findings.

    `item` is a dict with the 30 micronutrient fields keyed by their column
    name (e.g. "sodium_mg", "vitamin_a_ug"). Missing fields are tolerated.

    `source` is the food_nutrition_overrides input row (provides macros for
    cross-checks).
    """
    findings: List[Finding] = []
    findings.extend(_check_ranges(item, source))
    for rule in RULES:
        result = rule(item, source)
        if isinstance(result, Finding):
            findings.append(result)
        elif isinstance(result, list):
            findings.extend(result)
    return findings


def has_errors(findings: Iterable[Finding]) -> bool:
    return any(f.severity == Severity.ERROR for f in findings)


# Canonical column list — used by both USDA-pass and Gemini-pass code to
# build the JSONB write payload. Keep in sync with mig 324 + the
# RANGES dict above.
MICRONUTRIENT_COLUMNS: Tuple[str, ...] = tuple(RANGES.keys())
