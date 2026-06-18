import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/nutrition.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/design_system/zealova.dart';
import '../../../core/theme/theme_colors.dart';

/// Reusable food-tag chip row for the meal-detail surface.
///
/// Behaviour:
/// - Renders the meal's already-applied [FoodLog.tags] as selected chips.
/// - Auto-derives SUGGESTED tags from the meal's food-item names via simple
///   local keyword heuristics (dairy / gluten / spicy / high-FODMAP / …) and
///   shows the ones not already applied as unselected chips.
/// - A trailing "+ Add tag" affordance opens a free-text dialog (open
///   vocabulary — chips are convenience, not a hard whitelist).
/// - Tapping a chip toggles it; the new tag set is persisted IMMEDIATELY via
///   the EXISTING meal-update path (`PUT /nutrition/food-logs/{id}` with a
///   `tags` array) — the same self-contained pattern the post-meal sheet uses
///   for `/mood`. No new repository method is introduced.
///
/// Signature design: ZealovaChip + ZType, accent via ThemeColors. No emoji —
/// tags are plain UPPERCASE Barlow labels (ZealovaChip uppercases internally).
///
/// EMBED POINT: this is meant to live on the meal-detail / post-log surface
/// (e.g. the meal-detail sheet that shows a single [FoodLog]'s items, notes,
/// mood and health score). Drop in `FoodTagChips(log: foodLog)` under the
/// notes/mood block. It is intentionally self-contained (does its own write +
/// optimistic local state) so it can be embedded anywhere a [FoodLog] is shown
/// without threading a callback. An optional [onTagsChanged] is provided for
/// callers that want to fold the new tag set back into their own view model.
class FoodTagChips extends ConsumerStatefulWidget {
  final FoodLog log;

  /// Called with the new tag list AFTER a successful persist, so an embedding
  /// view can update its local copy of the [FoodLog] (e.g. via
  /// `log.copyWith(tags: ...)`). Optional.
  final ValueChanged<List<String>>? onTagsChanged;

  const FoodTagChips({
    super.key,
    required this.log,
    this.onTagsChanged,
  });

  @override
  ConsumerState<FoodTagChips> createState() => _FoodTagChipsState();
}

class _FoodTagChipsState extends ConsumerState<FoodTagChips> {
  /// The applied tags (lowercase, de-duped). Mutated optimistically.
  late List<String> _tags;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tags = _normalize(widget.log.tags ?? const []);
  }

  @override
  void didUpdateWidget(covariant FoodTagChips oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync if the embedding view swapped in a fresh log (e.g. after a
    // server refresh) AND we're not mid-edit.
    if (!_saving && oldWidget.log.id != widget.log.id) {
      _tags = _normalize(widget.log.tags ?? const []);
    }
  }

  List<String> _normalize(Iterable<String> raw) {
    final seen = <String>{};
    final out = <String>[];
    for (final t in raw) {
      final v = t.trim().toLowerCase();
      if (v.isNotEmpty && seen.add(v)) out.add(v);
    }
    return out;
  }

  /// Local heuristic suggestions derived from the meal's food names. Keyword
  /// match against item names + the user query — deliberately lightweight (no
  /// network). Mirrors the dietary buckets the backend correlations care about.
  List<String> _suggestedTags() {
    final haystack = StringBuffer();
    for (final item in widget.log.foodItems) {
      haystack.write(' ');
      haystack.write(item.name.toLowerCase());
    }
    if (widget.log.userQuery != null) {
      haystack.write(' ');
      haystack.write(widget.log.userQuery!.toLowerCase());
    }
    final text = haystack.toString();

    bool any(List<String> kws) => kws.any(text.contains);

    final suggestions = <String>[];
    void add(String tag, List<String> kws) {
      if (any(kws)) suggestions.add(tag);
    }

    add('dairy', [
      'milk', 'cheese', 'yogurt', 'yoghurt', 'butter', 'cream', 'latte',
      'ice cream', 'mozzarella', 'cheddar', 'parmesan', 'whey',
    ]);
    add('gluten', [
      'bread', 'pasta', 'wheat', 'flour', 'cracker', 'cereal', 'bagel',
      'noodle', 'pizza', 'tortilla', 'bun', 'roll', 'cookie', 'cake',
      'pancake', 'muffin', 'pretzel',
    ]);
    add('spicy', [
      'spicy', 'chili', 'chilli', 'jalapeno', 'jalapeño', 'sriracha',
      'hot sauce', 'cayenne', 'pepper', 'buffalo', 'kimchi', 'curry',
    ]);
    add('high-fodmap', [
      'onion', 'garlic', 'bean', 'lentil', 'chickpea', 'apple', 'pear',
      'mango', 'honey', 'mushroom', 'cauliflower', 'wheat', 'rye',
    ]);
    add('fried', [
      'fried', 'fries', 'tempura', 'crispy', 'nugget', 'wing', 'chip',
      'doughnut', 'donut',
    ]);
    add('caffeine', [
      'coffee', 'espresso', 'latte', 'cappuccino', 'tea', 'matcha',
      'energy drink', 'cola', 'soda',
    ]);
    add('alcohol', [
      'beer', 'wine', 'vodka', 'whiskey', 'whisky', 'rum', 'tequila',
      'cocktail', 'margarita', 'champagne',
    ]);
    add('sugary', [
      'candy', 'chocolate', 'cake', 'cookie', 'soda', 'donut', 'doughnut',
      'ice cream', 'syrup', 'dessert',
    ]);
    add('high-protein', [
      'chicken', 'beef', 'steak', 'egg', 'protein', 'salmon', 'tuna',
      'tofu', 'turkey', 'shrimp', 'greek yogurt',
    ]);
    add('veggie', [
      'salad', 'broccoli', 'spinach', 'kale', 'vegetable', 'veggie',
      'carrot', 'zucchini', 'pepper', 'cucumber', 'tomato',
    ]);

    // Only surface suggestions not already applied.
    return suggestions.where((s) => !_tags.contains(s)).toList();
  }

  Future<void> _toggle(String rawTag) async {
    final tag = rawTag.trim().toLowerCase();
    if (tag.isEmpty) return;

    final previous = List<String>.from(_tags);
    setState(() {
      if (!_tags.remove(tag)) _tags.add(tag);
      _saving = true;
    });

    final next = List<String>.from(_tags);
    try {
      // EXISTING meal-update path — PUT /nutrition/food-logs/{id} with a `tags`
      // array (the same endpoint the nutrition screen uses to edit a meal).
      final apiClient = ref.read(apiClientProvider);
      await apiClient.put(
        '/nutrition/food-logs/${widget.log.id}',
        data: {'tags': next},
      );
      if (!mounted) return;
      setState(() => _saving = false);
      widget.onTagsChanged?.call(next);
    } catch (e) {
      // Roll back so the chip never shows a tag the server rejected.
      if (!mounted) return;
      setState(() {
        _tags = previous;
        _saving = false;
      });
      debugPrint('🥗 [FoodTagChips] tag write failed, rolled back: $e');
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text('Could not save tag. Please try again.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addCustomTag() async {
    final controller = TextEditingController();
    final tc = ThemeColors.of(context);
    final entered = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: tc.elevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text('ADD TAG', style: ZType.lbl(13, color: tc.textPrimary, letterSpacing: 1.5)),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.none,
            style: TextStyle(color: tc.textPrimary),
            decoration: InputDecoration(
              hintText: 'e.g. probiotic, homemade, takeout',
              hintStyle: TextStyle(color: tc.textMuted),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: tc.cardBorder),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: tc.accent),
              ),
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: tc.textMuted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: Text('Add', style: TextStyle(color: tc.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    controller.dispose();
    final tag = entered?.trim().toLowerCase();
    if (tag != null && tag.isNotEmpty && !_tags.contains(tag)) {
      await _toggle(tag);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final suggestions = _suggestedTags();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TAGS',
          style: ZType.lbl(11, color: tc.textMuted, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            // Applied tags (selected).
            for (final t in _tags)
              ZealovaChip(
                label: t,
                icon: Icons.check,
                selected: true,
                onTap: _saving ? null : () => _toggle(t),
              ),
            // Suggested tags (unselected).
            for (final s in suggestions)
              ZealovaChip(
                label: s,
                selected: false,
                onTap: _saving ? null : () => _toggle(s),
              ),
            // Custom add.
            ZealovaChip(
              label: 'Add tag',
              icon: Icons.add,
              selected: false,
              onTap: _saving ? null : _addCustomTag,
            ),
          ],
        ),
      ],
    );
  }
}
