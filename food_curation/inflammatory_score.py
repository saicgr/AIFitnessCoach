"""
Simplified Dietary Inflammatory Index (DII) scorer.

Based on published DII methodology (Shivappa et al., 2014). Uses a subset of
21 nutrients with their global mean daily intakes and inflammatory weights.

Score interpretation:
  <= -2.0  highly_anti_inflammatory
  <= -0.5  anti_inflammatory
  <=  0.5  neutral
  <=  2.0  moderately_inflammatory
  >  2.0   highly_inflammatory

Usage:
    from inflammatory_score import calculate_inflammatory_score
    score, category = calculate_inflammatory_score(macros_per_100g, micros_per_100g)
"""


# Global daily mean intakes (reference population) used to center the z-scores.
# Values from Shivappa et al. 2014, Table 1.
GLOBAL_MEANS = {
    "calories":       2056.0,   # kcal/day
    "protein":          79.4,   # g/day
    "fat":              81.4,   # g/day
    "carbs":           272.2,   # g/day
    "fiber":            18.8,   # g/day
    "sugar":            51.5,   # g/day (estimated, not in original DII)
    "cholesterol_mg":  279.4,   # mg/day
    "sodium_mg":      3092.0,   # mg/day
    "iron_mg":          13.3,   # mg/day
    "calcium_mg":     903.0,    # mg/day
    "magnesium_mg":   310.1,    # mg/day
    "zinc_mg":          10.9,   # mg/day
    "phosphorus_mg": 1167.0,    # mg/day
    "potassium_mg":  2745.0,    # mg/day
    "vitamin_a_mcg":  983.9,    # mcg RAE/day
    "vitamin_c_mg":   118.2,    # mg/day
    "vitamin_d_iu":   189.0,    # IU/day
    "vitamin_e_mg":     8.7,    # mg/day
    "vitamin_b6_mg":    1.9,    # mg/day
    "vitamin_b12_mcg":  5.2,    # mcg/day
    "folate_mcg":     279.0,    # mcg/day
}

# DII inflammatory weights (positive = pro-inflammatory, negative = anti-inflammatory).
# From Shivappa et al. 2014, Table 2. Subset of the 45 parameters that we
# can reliably extract from our food data.
INFLAMMATORY_WEIGHTS = {
    # Pro-inflammatory
    "calories":        0.180,
    "protein":         0.021,
    "fat":             0.298,
    "carbs":           0.097,
    "cholesterol_mg":  0.110,
    "sodium_mg":       0.040,  # estimated (not in original 45, mild pro)
    "iron_mg":         0.032,

    # Anti-inflammatory
    "fiber":          -0.663,
    "vitamin_a_mcg":  -0.401,
    "vitamin_c_mg":   -0.424,
    "vitamin_d_iu":   -0.446,
    "vitamin_e_mg":   -0.419,
    "vitamin_b6_mg":  -0.365,
    "vitamin_b12_mcg":-0.106,
    "magnesium_mg":   -0.484,
    "zinc_mg":        -0.313,
    "folate_mcg":     -0.190,
    "calcium_mg":     -0.024,  # mildly anti
    "potassium_mg":   -0.100,  # estimated
}

# Category thresholds
_CATEGORIES = [
    (-2.0, "highly_anti_inflammatory"),
    (-0.5, "anti_inflammatory"),
    ( 0.5, "neutral"),
    ( 2.0, "moderately_inflammatory"),
]


def calculate_inflammatory_score(
    macros_per_100g: dict[str, float],
    micros_per_100g: dict[str, float],
) -> tuple[float, str]:
    """Calculate a simplified DII score from per-100g nutrient data.

    The score is computed per 100 g of food (not per daily intake), so it
    represents the inflammatory *density* of the food. This is appropriate
    for comparing foods against each other.

    Args:
        macros_per_100g: dict with keys like "calories", "protein", "fat", etc.
        micros_per_100g: dict with keys like "sodium_mg", "vitamin_c_mg", etc.

    Returns:
        (score, category) where score is a float and category is a string.
    """
    # Merge macros + micros into one lookup
    all_nutrients = {**macros_per_100g}
    if micros_per_100g:
        all_nutrients.update(micros_per_100g)

    score = 0.0
    n_matched = 0

    for nutrient, weight in INFLAMMATORY_WEIGHTS.items():
        value = all_nutrients.get(nutrient)
        if value is None or value == 0:
            continue

        global_mean = GLOBAL_MEANS.get(nutrient)
        if global_mean is None or global_mean == 0:
            continue

        # Simplified z-score: (value - mean) / mean
        # We skip the standard deviation step for simplicity since we're
        # comparing foods, not absolute daily intakes.
        z = (value - global_mean) / global_mean

        # Clamp z to [-3, 3] to avoid extreme outliers
        z = max(-3.0, min(3.0, z))

        score += z * weight
        n_matched += 1

    # Normalize by number of matched nutrients to avoid penalizing
    # foods with fewer data points
    if n_matched > 0:
        score = score * (len(INFLAMMATORY_WEIGHTS) / n_matched)

    # Round to 3 decimal places
    score = round(score, 3)

    # Categorize
    category = "highly_inflammatory"
    for threshold, cat in _CATEGORIES:
        if score <= threshold:
            category = cat
            break

    return score, category
