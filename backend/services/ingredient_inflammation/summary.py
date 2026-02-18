"""
Template-based summary and recommendation generation.

Replaces Gemini free-text generation with deterministic templates
that fill in actual ingredient names from the analysis.
"""

from typing import List, Optional


# ── Summary templates (2 per category) ──────────────────────────────────

_SUMMARY_TEMPLATES = {
    "highly_anti_inflammatory": [
        "This product contains several anti-inflammatory ingredients including {top_good}. "
        "Overall, it's an excellent choice for reducing inflammation.",
        "With ingredients like {top_good}, this product has strong anti-inflammatory properties. "
        "It's well-suited for an anti-inflammatory diet.",
    ],
    "anti_inflammatory": [
        "This product features beneficial ingredients such as {top_good}. "
        "It leans toward being anti-inflammatory overall.",
        "Containing ingredients like {top_good}, this product is a generally good choice "
        "for those watching their inflammation levels.",
    ],
    "neutral": [
        "This product has a mix of ingredients. {detail} "
        "Overall, it has a neutral impact on inflammation.",
        "The ingredients in this product are balanced. {detail} "
        "It neither significantly promotes nor reduces inflammation.",
    ],
    "moderately_inflammatory": [
        "This product contains some inflammatory ingredients including {top_bad}. "
        "{mitigation}Consider limiting consumption if you're managing inflammation.",
        "Ingredients like {top_bad} contribute to this product's moderately inflammatory profile. "
        "{mitigation}Occasional consumption should be fine for most people.",
    ],
    "highly_inflammatory": [
        "This product contains several highly inflammatory ingredients including {top_bad}. "
        "Regular consumption may contribute to increased inflammation.",
        "With ingredients like {top_bad}, this product is highly inflammatory. "
        "Consider seeking alternatives with fewer processed ingredients.",
    ],
}

# ── Recommendation templates (2 per category) ──────────────────────────

_RECOMMENDATION_TEMPLATES = {
    "highly_anti_inflammatory": [
        "Great choice! This product supports an anti-inflammatory lifestyle. "
        "Continue including foods like this in your diet.",
        "This is an excellent anti-inflammatory option. Keep it as a regular part of your meals.",
    ],
    "anti_inflammatory": [
        "Good choice overall. The anti-inflammatory ingredients like {top_good} "
        "make this a solid option for your diet.",
        "This product is a reasonable choice. The presence of {top_good} "
        "provides some anti-inflammatory benefits.",
    ],
    "neutral": [
        "This product is fine in moderation. For better anti-inflammatory options, "
        "look for products with more whole food ingredients.",
        "An acceptable choice. To improve your anti-inflammatory intake, "
        "pair this with foods rich in omega-3s, turmeric, or leafy greens.",
    ],
    "moderately_inflammatory": [
        "Try to limit this product. Look for alternatives without {top_bad}. "
        "Whole food versions are usually less inflammatory.",
        "Consider reducing intake. The {top_bad} can be avoided by choosing "
        "products with simpler, whole-food ingredient lists.",
    ],
    "highly_inflammatory": [
        "Strongly consider alternatives. The {top_bad} in this product can promote "
        "chronic inflammation. Look for whole-food or minimally processed options.",
        "This product should be consumed rarely, if at all. The combination of "
        "{top_bad} makes it one of the more inflammatory options available.",
    ],
}


def generate_summary(
    category: str,
    inflammatory_names: List[str],
    anti_inflammatory_names: List[str],
    product_name: Optional[str] = None,
) -> str:
    """
    Generate a template-based summary string.

    Uses deterministic template selection via hash of product name.
    """
    templates = _SUMMARY_TEMPLATES.get(category, _SUMMARY_TEMPLATES["neutral"])
    idx = hash(product_name or "") % len(templates)
    template = templates[idx]

    top_good = _format_list(anti_inflammatory_names[:3]) or "some beneficial compounds"
    top_bad = _format_list(inflammatory_names[:3]) or "some processed ingredients"

    # Build detail/mitigation strings for neutral/moderate categories
    detail = ""
    if inflammatory_names and anti_inflammatory_names:
        detail = (
            f"It contains some inflammatory ingredients ({_format_list(inflammatory_names[:2])}) "
            f"but also beneficial ones ({_format_list(anti_inflammatory_names[:2])})."
        )
    elif inflammatory_names:
        detail = f"It contains some inflammatory ingredients like {_format_list(inflammatory_names[:2])}."
    elif anti_inflammatory_names:
        detail = f"It contains some beneficial ingredients like {_format_list(anti_inflammatory_names[:2])}."

    mitigation = ""
    if anti_inflammatory_names:
        mitigation = (
            f"On the positive side, it does contain {_format_list(anti_inflammatory_names[:2])}. "
        )

    return template.format(
        top_good=top_good,
        top_bad=top_bad,
        detail=detail,
        mitigation=mitigation,
    )


def generate_recommendation(
    category: str,
    inflammatory_names: List[str],
    anti_inflammatory_names: List[str],
    product_name: Optional[str] = None,
) -> str:
    """
    Generate a template-based recommendation string.

    Uses deterministic template selection via hash of product name.
    """
    templates = _RECOMMENDATION_TEMPLATES.get(category, _RECOMMENDATION_TEMPLATES["neutral"])
    idx = hash(product_name or "") % len(templates)
    template = templates[idx]

    top_good = _format_list(anti_inflammatory_names[:3]) or "beneficial ingredients"
    top_bad = _format_list(inflammatory_names[:3]) or "processed additives"

    return template.format(top_good=top_good, top_bad=top_bad)


def _format_list(items: List[str]) -> str:
    """Format a list into natural English: 'a, b, and c'."""
    if not items:
        return ""
    if len(items) == 1:
        return items[0]
    if len(items) == 2:
        return f"{items[0]} and {items[1]}"
    return ", ".join(items[:-1]) + f", and {items[-1]}"
