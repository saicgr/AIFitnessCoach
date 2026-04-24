import '../../../../data/models/menu_item.dart';

/// Lightweight diet classifier for menu items.
///
/// The backend does not (yet) emit structured diet tags per dish, so we
/// derive a best-effort set of booleans from the dish name, coach tip,
/// rating reason, and macro profile. This is intentionally conservative:
///  • A dish is only flagged vegetarian/vegan when no disqualifying keyword
///    (beef, pork, chicken, fish, egg, milk, cheese, butter, honey…) is
///    found — silence alone is not proof of absence, but on a restaurant
///    menu the noun is almost always spelled out.
///  • Keto / low-carb / high-protein come straight from the macros the
///    backend already reports, so those are exact.
///
/// If / when Gemini starts emitting `diet_tags: ["vegan", "gf"]` per item,
/// swap [matches] to prefer structured tags over string scanning.
class DietHeuristics {
  DietHeuristics._();

  /// Every diet the filter sheet can offer. Keyed by stable id; the label
  /// is UI copy only and can be localized later.
  static const Map<String, String> labels = {
    'vegetarian': 'Vegetarian',
    'vegan': 'Vegan',
    'pescatarian': 'Pescatarian',
    'keto': 'Keto',
    'low_carb': 'Low carb',
    'high_protein': 'High protein',
    'gluten_free': 'Gluten-free',
    'dairy_free': 'Dairy-free',
    'mediterranean': 'Mediterranean',
  };

  // ───────────── keyword vocabularies ─────────────
  static const _meatTerms = {
    'beef', 'steak', 'veal', 'pork', 'ham', 'bacon', 'prosciutto',
    'pancetta', 'sausage', 'salami', 'pepperoni', 'meatball', 'lamb',
    'venison', 'duck', 'goose', 'rabbit', 'liver', 'oxtail', 'brisket',
    'ribs', 'chorizo', 'guanciale', 'mortadella', 'bresaola',
  };
  static const _poultryTerms = {
    'chicken', 'turkey', 'quail', 'poultry',
  };
  static const _seafoodTerms = {
    'fish', 'salmon', 'tuna', 'cod', 'trout', 'halibut', 'sardine',
    'anchovy', 'mackerel', 'bass', 'snapper', 'tilapia', 'branzino',
    'shrimp', 'prawn', 'lobster', 'crab', 'scallop', 'clam', 'mussel',
    'oyster', 'squid', 'octopus', 'calamari', 'seafood',
  };
  static const _dairyTerms = {
    'milk', 'cream', 'butter', 'cheese', 'ricotta', 'mozzarella',
    'parmesan', 'parmigiano', 'pecorino', 'gorgonzola', 'feta',
    'yogurt', 'yoghurt', 'ghee', 'lactose', 'whey',
    'mascarpone', 'burrata', 'gelato', 'ice cream', 'custard',
  };
  static const _eggTerms = {
    'egg', 'eggs', 'frittata', 'omelette', 'omelet', 'carbonara',
    'meringue', 'aioli', 'mayonnaise', 'mayo',
  };
  static const _honeyTerms = {'honey'};
  static const _glutenTerms = {
    'bread', 'toast', 'brioche', 'baguette', 'focaccia', 'pita',
    'wrap', 'bun', 'bagel', 'croissant', 'pastry', 'pie',
    'pizza', 'pasta', 'spaghetti', 'linguine', 'fettuccine',
    'penne', 'rigatoni', 'lasagna', 'ravioli', 'tortellini',
    'gnocchi', 'noodle', 'ramen', 'udon', 'couscous', 'barley',
    'wheat', 'rye', 'farro', 'breadcrumb', 'panko', 'cracker',
    'tiramisu', 'cake', 'cookie', 'biscotti', 'cannoli',
  };

  /// Return true iff the haystack contains any whole-word from [terms].
  static bool _containsAny(String haystack, Set<String> terms) {
    for (final t in terms) {
      // Match as a loose substring — dish text is short and cleanly tokenised
      // on menus, so false positives are rare. Full word-boundary regex
      // would trip on compounds like "cheeseburger" which we DO want to hit.
      if (haystack.contains(t)) return true;
    }
    return false;
  }

  /// Concatenated lowercase text across the fields worth scanning for
  /// ingredient words. Coach tips and rating reasons often mention
  /// ingredients that aren't in the short dish name.
  static String _text(MenuItem item) {
    final buf = StringBuffer(item.name.toLowerCase());
    if (item.coachTip != null) buf.write(' ${item.coachTip!.toLowerCase()}');
    if (item.ratingReason != null) buf.write(' ${item.ratingReason!.toLowerCase()}');
    if (item.fodmapReason != null) buf.write(' ${item.fodmapReason!.toLowerCase()}');
    return buf.toString();
  }

  /// True if [item] plausibly satisfies the diet identified by [tag].
  /// Unknown tags default to true so an accidental typo doesn't hide
  /// every dish in the menu.
  static bool matches(MenuItem item, String tag) {
    final text = _text(item);
    final hasMeat = _containsAny(text, _meatTerms);
    final hasPoultry = _containsAny(text, _poultryTerms);
    final hasSeafood = _containsAny(text, _seafoodTerms);
    final hasDairy = _containsAny(text, _dairyTerms);
    final hasEgg = _containsAny(text, _eggTerms);
    final hasHoney = _containsAny(text, _honeyTerms);
    final hasGluten = _containsAny(text, _glutenTerms);

    final carbs = item.carbsG;
    final protein = item.proteinG;
    final fat = item.fatG;
    final cal = item.calories;
    final proteinPct = cal > 0 ? (protein * 4.0) / cal : 0.0;
    final fatPct = cal > 0 ? (fat * 9.0) / cal : 0.0;

    switch (tag) {
      case 'vegetarian':
        return !hasMeat && !hasPoultry && !hasSeafood;
      case 'vegan':
        return !hasMeat && !hasPoultry && !hasSeafood &&
            !hasDairy && !hasEgg && !hasHoney;
      case 'pescatarian':
        return !hasMeat && !hasPoultry;
      case 'keto':
        // Strict keto: very low carbs + fat-forward macros per serving.
        return carbs <= 10 && fatPct >= 0.55;
      case 'low_carb':
        return carbs <= 20;
      case 'high_protein':
        return protein >= 25 || proteinPct >= 0.30;
      case 'gluten_free':
        return !hasGluten;
      case 'dairy_free':
        return !hasDairy;
      case 'mediterranean':
        // Rough proxy: seafood or vegetarian, moderate fat, not ultra-processed.
        final isMedSource = hasSeafood || (!hasMeat && !hasPoultry);
        return isMedSource && item.isUltraProcessed != true;
      default:
        return true;
    }
  }
}

/// Smart preset IDs surfaced as big chips at the top of the filter sheet.
/// Each preset compiles down to a predicate over [MenuItem]. Keeping them
/// in a single list (rather than scattering booleans through MenuFilterState)
/// means adding a new preset is one-line: add an entry to [SmartPresets.all].
class SmartPresets {
  SmartPresets._();

  static final List<SmartPreset> all = [
    SmartPreset(
      id: 'high_protein',
      label: 'High protein',
      emoji: '💪',
      hint: '25 g+ per dish',
      matches: (i) => i.proteinG >= 25,
    ),
    SmartPreset(
      id: 'light',
      label: 'Light',
      emoji: '🌿',
      hint: 'Under 450 cal',
      matches: (i) => i.calories <= 450 && i.fatG <= 18,
    ),
    SmartPreset(
      id: 'low_carb',
      label: 'Low carb',
      emoji: '🥩',
      hint: 'Under 20 g carbs',
      matches: (i) => i.carbsG <= 20,
    ),
    SmartPreset(
      id: 'anti_inflammatory',
      label: 'Anti-inflammatory',
      emoji: '🌱',
      hint: 'Score 3 or lower',
      matches: (i) => i.inflammationScore != null && i.inflammationScore! <= 3,
    ),
    SmartPreset(
      id: 'blood_sugar',
      label: 'Blood-sugar friendly',
      emoji: '🩺',
      hint: 'Low glycemic load',
      matches: (i) => i.glycemicLoad == null || i.glycemicLoad! < 10,
    ),
    SmartPreset(
      id: 'gut_friendly',
      label: 'Gut-friendly',
      emoji: '🧡',
      hint: 'Low FODMAP',
      matches: (i) => i.fodmapRating == null || i.fodmapRating == 'low',
    ),
    SmartPreset(
      id: 'clean',
      label: 'Whole foods',
      emoji: '✨',
      hint: 'Not ultra-processed',
      matches: (i) => i.isUltraProcessed != true,
    ),
  ];

  static SmartPreset? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

class SmartPreset {
  final String id;
  final String label;
  final String emoji;
  final String hint;
  final bool Function(MenuItem item) matches;

  const SmartPreset({
    required this.id,
    required this.label,
    required this.emoji,
    required this.hint,
    required this.matches,
  });
}
