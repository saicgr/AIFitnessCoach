/// Resolvers that turn a [DataBinding] + a live [Shareable] into a concrete
/// value at render time. A bound element stays "live" — a re-rendered card
/// tracks the underlying log; editing an element flips its binding to
/// `literal` so the user's value wins.
library;

import '../shareable_data.dart';
import 'card_doc.dart';

/// Formats grams as a compact string ("13g", "104g").
String _grams(double g) => '${g.round()}g';

/// Resolves a text-producing binding to a string.
///
/// [literalFallback] is the element's own stored value, used when the binding
/// is `literal` (or when bound data is missing).
String resolveText(
  DataBinding binding,
  Shareable data, {
  String literalFallback = '',
}) {
  final n = data.nutrition;
  final items = data.foodItems ?? const <ShareableFood>[];
  final idx = binding.index ?? 0;

  switch (binding.source) {
    case BindingSource.literal:
      return literalFallback;
    case BindingSource.title:
      return data.title;
    case BindingSource.periodLabel:
      return data.periodLabel;
    case BindingSource.mealLabel:
      return data.mealLabel ?? '';
    case BindingSource.logText:
      return data.logText ?? '';
    case BindingSource.caption:
      return data.caption ?? '';
    case BindingSource.userDisplayName:
      return data.userDisplayName ?? '';
    case BindingSource.heroString:
      return shareableHeroString(data);
    case BindingSource.healthScore:
      return data.healthScore?.toString() ?? '';
    case BindingSource.calories:
      return (n?.calories ?? 0).toString();
    case BindingSource.proteinG:
      return _grams(n?.proteinG ?? 0);
    case BindingSource.carbsG:
      return _grams(n?.carbsG ?? 0);
    case BindingSource.fatG:
      return _grams(n?.fatG ?? 0);
    case BindingSource.foodItemName:
      return idx >= 0 && idx < items.length ? items[idx].name : literalFallback;
    case BindingSource.foodItemAmount:
      return idx >= 0 && idx < items.length
          ? (items[idx].amount ?? '')
          : literalFallback;
    case BindingSource.highlightLabel:
      return idx >= 0 && idx < data.highlights.length
          ? data.highlights[idx].label
          : literalFallback;
    case BindingSource.highlightValue:
      return idx >= 0 && idx < data.highlights.length
          ? data.highlights[idx].value
          : literalFallback;
    // Sources that don't resolve to display text.
    case BindingSource.nutrition:
    case BindingSource.foodImageUrl:
    case BindingSource.customPhotoPath:
    case BindingSource.customPhotoPathSecondary:
    case BindingSource.heroImageUrl:
      return literalFallback;
  }
}

/// Resolves a numeric binding (calories / macro grams / score / hero value).
/// Returns null when the binding is not numeric or the data is absent.
num? resolveNumber(DataBinding binding, Shareable data) {
  final n = data.nutrition;
  switch (binding.source) {
    case BindingSource.calories:
      return n?.calories;
    case BindingSource.proteinG:
      return n?.proteinG;
    case BindingSource.carbsG:
      return n?.carbsG;
    case BindingSource.fatG:
      return n?.fatG;
    case BindingSource.healthScore:
      return data.healthScore;
    case BindingSource.heroString:
      return data.heroValue;
    default:
      return null;
  }
}

/// The aggregate macro totals for [data] — never null (an empty
/// [ShareableNutrition] when the share carries none).
ShareableNutrition resolveNutrition(Shareable data) =>
    data.nutrition ?? const ShareableNutrition();

/// Resolves a photo reference to a usable URL / local path, or null.
String? resolvePhotoUrl(CardPhotoRef ref, Shareable data) {
  if (ref.staticPath != null && ref.staticPath!.isNotEmpty) {
    return ref.staticPath;
  }
  final idx = ref.binding.index ?? 0;
  switch (ref.binding.source) {
    case BindingSource.foodImageUrl:
      final urls = data.foodImageUrls;
      if (urls != null && idx >= 0 && idx < urls.length) return urls[idx];
      return null;
    case BindingSource.customPhotoPath:
      return data.customPhotoPath;
    case BindingSource.customPhotoPathSecondary:
      return data.customPhotoPathSecondary;
    case BindingSource.heroImageUrl:
      return data.heroImageUrl;
    default:
      // Fall back to the first food photo so a photo element is never blank
      // when a preset bound it loosely.
      final urls = data.foodImageUrls;
      return (urls != null && urls.isNotEmpty)
          ? urls.first
          : data.customPhotoPath;
  }
}

/// Resolves a list binding (food-item names or amounts) to a string list,
/// capped at [max].
List<String> resolveItemList(
  DataBinding binding,
  Shareable data, {
  int max = 12,
}) {
  final items = data.foodItems ?? const <ShareableFood>[];
  Iterable<String> raw;
  switch (binding.source) {
    case BindingSource.foodItemName:
      raw = items.map((f) => f.name);
    case BindingSource.foodItemAmount:
      raw = items.map((f) => f.amount ?? '');
    default:
      raw = const <String>[];
  }
  return raw.where((s) => s.trim().isNotEmpty).take(max).toList(growable: false);
}

/// The raw food items — used by `repeater` / `table` elements that need
/// per-item macros, not just names.
List<ShareableFood> resolveFoodItems(Shareable data, {int max = 12}) =>
    (data.foodItems ?? const <ShareableFood>[]).take(max).toList(growable: false);
