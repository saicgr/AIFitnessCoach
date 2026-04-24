/// FDA Big 9 major food allergens (as of the 2023 FASTER Act addition
/// of sesame). Canonical enum used by user preferences + menu item
/// warnings. Values match the lowercase snake_case strings the Gemini
/// prompt is instructed to emit in `detected_allergens`.
///
/// Source: fsis.usda.gov/food-safety/safe-food-handling-and-preparation/food-safety-basics/food-allergies-big-9
enum Allergen {
  milk,
  egg,
  fish,
  crustaceanShellfish,
  treeNuts,
  wheat,
  peanuts,
  soybeans,
  sesame;

  /// Canonical backend string (snake_case) used across storage, Gemini
  /// prompt, and API payloads.
  String get code {
    switch (this) {
      case Allergen.milk: return 'milk';
      case Allergen.egg: return 'egg';
      case Allergen.fish: return 'fish';
      case Allergen.crustaceanShellfish: return 'crustacean_shellfish';
      case Allergen.treeNuts: return 'tree_nuts';
      case Allergen.wheat: return 'wheat';
      case Allergen.peanuts: return 'peanuts';
      case Allergen.soybeans: return 'soybeans';
      case Allergen.sesame: return 'sesame';
    }
  }

  /// Human-readable label for the settings UI + warning banners.
  String get displayName {
    switch (this) {
      case Allergen.milk: return 'Milk';
      case Allergen.egg: return 'Egg';
      case Allergen.fish: return 'Fish';
      case Allergen.crustaceanShellfish: return 'Shellfish';
      case Allergen.treeNuts: return 'Tree nuts';
      case Allergen.wheat: return 'Wheat';
      case Allergen.peanuts: return 'Peanuts';
      case Allergen.soybeans: return 'Soy';
      case Allergen.sesame: return 'Sesame';
    }
  }

  /// Emoji glyph for inline pills / chips where an icon helps scanning.
  String get glyph {
    switch (this) {
      case Allergen.milk: return '🥛';
      case Allergen.egg: return '🥚';
      case Allergen.fish: return '🐟';
      case Allergen.crustaceanShellfish: return '🦐';
      case Allergen.treeNuts: return '🥜';
      case Allergen.wheat: return '🌾';
      case Allergen.peanuts: return '🥜';
      case Allergen.soybeans: return '🫘';
      case Allergen.sesame: return '🌱';
    }
  }

  static Allergen? fromCode(String? code) {
    if (code == null) return null;
    final c = code.trim().toLowerCase();
    for (final a in Allergen.values) {
      if (a.code == c) return a;
    }
    // Tolerate common mis-spellings from Gemini.
    switch (c) {
      case 'shellfish': return Allergen.crustaceanShellfish;
      case 'nuts': return Allergen.treeNuts;
      case 'dairy': return Allergen.milk;
      case 'gluten':
      case 'gluten_wheat': return Allergen.wheat;
      case 'soy': return Allergen.soybeans;
    }
    return null;
  }

  /// Parse a backend-provided list (strings) into a typed set. Unknown
  /// codes are dropped silently — we never want to crash on a Gemini
  /// response that invents a new allergen string.
  static Set<Allergen> parseAll(List<dynamic>? raw) {
    if (raw == null) return const {};
    final out = <Allergen>{};
    for (final entry in raw) {
      final a = Allergen.fromCode(entry?.toString());
      if (a != null) out.add(a);
    }
    return out;
  }
}

/// Pair of (builtin Allergen set, free-text "other" list) stored on
/// user preferences — users can flag an allergen outside the Big 9
/// (e.g. "mango", "nightshades", "corn"). Matching against a dish is a
/// two-step check: typed set intersection + case-insensitive substring
/// over dish name.
class UserAllergenProfile {
  final Set<Allergen> allergens;
  final List<String> customAllergens;

  const UserAllergenProfile({
    this.allergens = const {},
    this.customAllergens = const [],
  });

  bool get isEmpty => allergens.isEmpty && customAllergens.isEmpty;

  /// Which of the user's allergens hit on this dish. Empty iterable if
  /// nothing to warn about.
  Iterable<String> matchesForDish({
    required String dishName,
    required Set<Allergen> detectedAllergens,
    String? dishDescription,
  }) sync* {
    for (final a in detectedAllergens.intersection(allergens)) {
      yield a.displayName;
    }
    if (customAllergens.isEmpty) return;
    final haystack = '${dishName.toLowerCase()} ${(dishDescription ?? '').toLowerCase()}';
    for (final custom in customAllergens) {
      final needle = custom.trim().toLowerCase();
      if (needle.isEmpty) continue;
      if (haystack.contains(needle)) yield custom;
    }
  }
}
