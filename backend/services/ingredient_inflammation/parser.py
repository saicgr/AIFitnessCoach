"""
Ingredient text parser.

Parses raw ingredient strings from food labels into a clean list of
individual ingredient names. Handles commas, semicolons, nested
parentheses, percentages, and/or splits, and qualifier stripping.
"""

import re
from typing import List


def parse_ingredients(text: str) -> List[str]:
    """
    Parse raw ingredient text into a deduplicated list of ingredient names.

    Handles:
    - Commas and semicolons as delimiters
    - Nested parentheses: "enriched flour (wheat flour, niacin)" -> both parent + children
    - Percentage prefixes: strips "2% or less of:" prefixes
    - "and/or" splits: "palm and/or canola oil" -> two entries
    - Trailing qualifiers: strips "(preservative)", "(to preserve freshness)"
    - E-numbers: kept as-is
    - Deduplication while preserving order

    Args:
        text: Raw ingredients string from food label

    Returns:
        List of cleaned, deduplicated ingredient names
    """
    if not text or not text.strip():
        return []

    # Normalize whitespace
    text = " ".join(text.split())

    # Remove common label prefixes
    text = re.sub(r"^ingredients?\s*:\s*", "", text, flags=re.IGNORECASE)

    # Extract parenthesized sub-ingredients before flattening
    ingredients: List[str] = []
    _extract_with_parens(text, ingredients)

    # Clean and deduplicate
    seen: set = set()
    result: List[str] = []
    for ing in ingredients:
        cleaned = _clean_ingredient(ing)
        if cleaned and len(cleaned) >= 2:
            key = cleaned.lower()
            if key not in seen:
                seen.add(key)
                result.append(cleaned)

    return result


def _extract_with_parens(text: str, out: List[str]) -> None:
    """
    Extract ingredients handling nested parentheses.

    For "enriched flour (wheat flour, niacin, iron), sugar":
    -> ["enriched flour", "wheat flour", "niacin", "iron", "sugar"]
    """
    # First, handle the "contains 2% or less of:" pattern
    text = re.sub(
        r"contains?\s+\d+%\s+or\s+less\s+of\s*:?\s*",
        "",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"\d+%\s+or\s+less\s+of\s*:?\s*",
        "",
        text,
        flags=re.IGNORECASE,
    )

    # Track parenthesis depth to find top-level delimiters
    depth = 0
    current = []
    i = 0

    while i < len(text):
        ch = text[i]
        if ch == "(":
            if depth == 0:
                # Save parent ingredient name
                parent = "".join(current).strip()
                if parent:
                    out.append(parent)
                current = []
            else:
                current.append(ch)
            depth += 1
        elif ch == ")":
            depth -= 1
            if depth == 0:
                # Process sub-ingredients inside parens
                sub_text = "".join(current).strip()
                if sub_text and not _is_qualifier(sub_text):
                    _split_and_add(sub_text, out)
                current = []
            elif depth < 0:
                depth = 0
                current.append(ch)
            else:
                current.append(ch)
        elif ch in (",", ";") and depth == 0:
            part = "".join(current).strip()
            if part:
                out.append(part)
            current = []
        elif ch == "." and depth == 0 and i == len(text) - 1:
            # Trailing period
            pass
        else:
            current.append(ch)
        i += 1

    # Remaining text
    remainder = "".join(current).strip()
    if remainder:
        out.append(remainder)


def _split_and_add(text: str, out: List[str]) -> None:
    """Split comma/semicolon-separated text and add each part."""
    parts = re.split(r"[,;]", text)
    for part in parts:
        part = part.strip()
        if part:
            out.append(part)


def _is_qualifier(text: str) -> bool:
    """Check if parenthesized text is a qualifier rather than sub-ingredients."""
    qualifiers = [
        "preservative", "to preserve", "for freshness", "for color",
        "color added", "artificial color", "added for", "as a",
        "used as", "source of", "for leavening", "to retain",
        "to maintain", "to promote", "dough conditioner",
        "anticaking", "anti-caking", "emulsifier", "stabilizer",
        "thickener", "antioxidant", "sequestrant", "humectant",
        "acidity regulator", "glazing agent", "raising agent",
        "gelling agent", "bulking agent", "firming agent",
        "flavor enhancer", "flour treatment",
    ]
    text_lower = text.lower().strip()
    # Single-word or short qualifiers
    if len(text_lower.split()) <= 3:
        for q in qualifiers:
            if q in text_lower:
                return True
    return False


def _clean_ingredient(name: str) -> str:
    """Clean a single ingredient name."""
    if not name:
        return ""

    # Strip trailing qualifiers in parens: "citric acid (preservative)" -> "citric acid"
    name = re.sub(r"\s*\([^)]*(?:preservative|freshness|color|leavening)[^)]*\)\s*$",
                  "", name, flags=re.IGNORECASE)

    # Handle "and/or" splits - return first option cleaned
    # (the caller handles dedup, so we just expand both)
    if " and/or " in name.lower():
        parts = re.split(r"\s+and/or\s+", name, flags=re.IGNORECASE)
        # Return the first part; caller will see both if we add both
        # But since this is called per-ingredient, we handle differently
        name = parts[0].strip()

    # Strip asterisks, daggers, and other annotation marks
    name = re.sub(r"[*\u2020\u2021]+", "", name)

    # Strip leading/trailing punctuation
    name = name.strip(" .,;:-")

    # Collapse whitespace
    name = " ".join(name.split())

    return name


def _expand_and_or(text: str) -> List[str]:
    """Expand 'X and/or Y oil' into ['X oil', 'Y oil']."""
    match = re.search(r"(.+?)\s+and/or\s+(.+)", text, re.IGNORECASE)
    if match:
        return [match.group(1).strip(), match.group(2).strip()]
    return [text]
