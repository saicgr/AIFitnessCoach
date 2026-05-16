"""100 text-input scenarios for the Phase-2 full-sweep validator.

Categories chosen to stress every code path in `analyze_food` /
`/analyze-text-stream`:
  - single common  → expect canonical hit, <500ms warm
  - single regional → expect canonical hit (regional names backfilled in P1)
  - compound simple → expect compound-decompose path
  - compound complex → multi-component, edge of token budget
  - branded restaurant → may hit canonical or fall to Stage-2
  - quantity edge → tests portion parsing
  - cooking modifier → tests "without skin", "boiled", etc.
  - slang / typos → tests trigram fuzzy
  - allergen / dietary → tests modifier parsing
  - empty / pathological → tests defensive failure modes
"""
from typing import List, Tuple

# Each entry: (category, text)
SCENARIOS: List[Tuple[str, str]] = [
    # --- Single, common cached (20) ---
    ("single_common", "chicken breast 6 oz"),
    ("single_common", "1 cup white rice"),
    ("single_common", "1 banana"),
    ("single_common", "2 large eggs"),
    ("single_common", "1 slice whole wheat bread"),
    ("single_common", "1 cup oatmeal"),
    ("single_common", "1 medium apple"),
    ("single_common", "100g greek yogurt plain"),
    ("single_common", "1 tbsp peanut butter"),
    ("single_common", "1 cup whole milk"),
    ("single_common", "150g salmon fillet baked"),
    ("single_common", "1 cup broccoli steamed"),
    ("single_common", "1 medium baked potato"),
    ("single_common", "1 oz almonds raw"),
    ("single_common", "1 cup cooked quinoa"),
    ("single_common", "1 medium avocado"),
    ("single_common", "1 cup spinach raw"),
    ("single_common", "1 cup blueberries"),
    ("single_common", "100g ground beef 80/20 cooked"),
    ("single_common", "1 oz cheddar cheese"),

    # --- Single, regional (15) ---
    ("single_regional", "hyderabadi chicken biryani 1 plate"),
    ("single_regional", "masala dosa 1"),
    ("single_regional", "thai green curry chicken 1 bowl"),
    ("single_regional", "ethiopian injera with shiro 1 serving"),
    ("single_regional", "vietnamese pho beef 1 large bowl"),
    ("single_regional", "korean bibimbap with beef 1 bowl"),
    ("single_regional", "japanese ramen tonkotsu 1 bowl"),
    ("single_regional", "mexican chicken enchiladas 2"),
    ("single_regional", "italian carbonara pasta 1 plate"),
    ("single_regional", "greek moussaka 1 portion"),
    ("single_regional", "spanish paella mixta 1 cup"),
    ("single_regional", "lebanese hummus 100g"),
    ("single_regional", "turkish kebab plate 1 serving"),
    ("single_regional", "indonesian nasi goreng 1 plate"),
    ("single_regional", "moroccan tagine chicken 1 portion"),

    # --- Compound, simple (15) ---
    ("compound_simple", "2 eggs and toast"),
    ("compound_simple", "burger with fries and coke"),
    ("compound_simple", "chicken caesar salad with croutons"),
    ("compound_simple", "spaghetti and meatballs"),
    ("compound_simple", "rice and beans"),
    ("compound_simple", "yogurt with granola and berries"),
    ("compound_simple", "turkey sandwich with lettuce tomato mayo"),
    ("compound_simple", "grilled chicken with steamed broccoli"),
    ("compound_simple", "bacon and eggs"),
    ("compound_simple", "fish and chips"),
    ("compound_simple", "tacos al pastor 3 pieces"),
    ("compound_simple", "pancakes with syrup and butter"),
    ("compound_simple", "salmon teriyaki with white rice"),
    ("compound_simple", "shrimp stir fry with vegetables"),
    ("compound_simple", "cereal with milk"),

    # --- Compound, complex (10) ---
    ("compound_complex", "thali with dal makhani, basmati rice, sabzi, 2 rotis, raita and papad"),
    ("compound_complex", "sushi assortment 12 pieces (4 nigiri salmon, 4 maki tuna, 4 california rolls)"),
    ("compound_complex", "buddha bowl quinoa kale chickpeas avocado tahini sweet potato"),
    ("compound_complex", "korean bbq spread bulgogi short ribs banchan kimchi rice 1 person"),
    ("compound_complex", "french bistro plate steak frites side salad with vinaigrette glass red wine"),
    ("compound_complex", "indian breakfast plate masala dosa sambar 2 chutneys vada"),
    ("compound_complex", "vietnamese cold noodle bowl bun cha grilled pork spring rolls herbs"),
    ("compound_complex", "english full breakfast 2 eggs 2 sausage 2 bacon beans tomato toast"),
    ("compound_complex", "ethiopian platter injera tibs misir wat shiro gomen"),
    ("compound_complex", "dim sum sampler shrimp dumplings pork buns chicken feet egg tarts"),

    # --- Branded / restaurant (10) ---
    ("branded", "starbucks grande oat milk latte"),
    ("branded", "chipotle chicken burrito bowl with rice beans corn salsa"),
    ("branded", "mcdonalds big mac"),
    ("branded", "subway 6 inch turkey breast on wheat"),
    ("branded", "panera mediterranean veggie sandwich"),
    ("branded", "sweetgreen kale caesar with chicken"),
    ("branded", "in-n-out double double animal style"),
    ("branded", "shake shack shackburger and fries"),
    ("branded", "five guys little hamburger and small fries"),
    ("branded", "domino's medium pepperoni pizza 2 slices"),

    # --- Quantity edge cases (10) ---
    ("quantity", "half cup white rice"),
    ("quantity", "350g chicken thigh boneless"),
    ("quantity", "a handful of mixed nuts"),
    ("quantity", "two slices sourdough"),
    ("quantity", "one and a half cups pasta"),
    ("quantity", "3/4 cup oats"),
    ("quantity", "small bowl of soup"),
    ("quantity", "large slice of pizza"),
    ("quantity", "tbsp olive oil"),
    ("quantity", "an entire rotisserie chicken"),

    # --- Cooking modifier (5) ---
    ("modifier", "grilled chicken breast without skin"),
    ("modifier", "boiled eggs no salt 2"),
    ("modifier", "pasta al dente whole wheat 1 cup"),
    ("modifier", "deep fried chicken wings 6 pieces"),
    ("modifier", "raw vegan kale salad with lemon dressing"),

    # --- Slang / typos (5) ---
    ("slang_typo", "bday cake slice"),
    ("slang_typo", "mac n chez 1 cup"),
    ("slang_typo", "chicn brst 6oz"),
    ("slang_typo", "spag bol"),
    ("slang_typo", "PB&J on white"),

    # --- Allergen / dietary (5) ---
    ("dietary", "gluten-free pasta with marinara sauce 1 cup"),
    ("dietary", "dairy-free smoothie banana almond milk peanut butter"),
    ("dietary", "vegan chickpea curry with brown rice"),
    ("dietary", "keto breakfast 3 eggs bacon avocado"),
    ("dietary", "low-sodium chicken soup 1 cup"),

    # --- Empty / pathological (5) ---
    ("pathological", ""),
    ("pathological", "lunch"),
    ("pathological", "yum"),
    ("pathological", "asdfghjkl"),
    ("pathological", "I had something but I forgot what"),
]


def get_scenarios() -> List[Tuple[str, str]]:
    """Returns the full 100-scenario list."""
    assert len(SCENARIOS) == 100, f"expected 100 scenarios, got {len(SCENARIOS)}"
    return SCENARIOS


if __name__ == "__main__":
    s = get_scenarios()
    from collections import Counter
    cnt = Counter(c for c, _ in s)
    print(f"Total: {len(s)}")
    for cat, n in cnt.most_common():
        print(f"  {cat:<22} {n}")
