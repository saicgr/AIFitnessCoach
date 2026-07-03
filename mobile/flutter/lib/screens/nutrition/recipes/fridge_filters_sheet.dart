/// Recipe filter catalog + the full-screen "All filters" sheet for the
/// From-Your-Fridge screen. Selection is keyed by the human label shown on the
/// chip (exactly the string sent to the backend), so the inline card and this
/// sheet share one `Set<String>` of active labels.
library;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/nutrition_preferences.dart';

class FridgeFilterGroup {
  final String key;
  final List<String> labels;
  const FridgeFilterGroup(this.key, this.labels);
}

/// The full catalog shown in the "All filters" sheet.
const List<FridgeFilterGroup> kFridgeFilterCatalog = [
  FridgeFilterGroup('MEAL', [
    'Breakfast', 'Lunch', 'Dinner', 'Snack', 'Dessert', 'Meal prep', 'Post-workout',
  ]),
  FridgeFilterGroup('GOAL', [
    'High protein', 'Low carb', 'Low calorie', 'High fiber',
    'Muscle gain', 'Cutting', 'Heart-healthy', 'Low sugar',
  ]),
  FridgeFilterGroup('TIME & EFFORT', [
    '≤ 15 min', '≤ 30 min', '≤ 45 min', 'One-pan', 'No-cook',
    '5 ingredients or less', 'Air fryer', 'Slow cooker',
  ]),
  FridgeFilterGroup('DIET & MEDICAL', [
    'Vegetarian', 'Vegan', 'Pescatarian', 'Keto', 'Paleo', 'Low-FODMAP',
    'GLP-1 friendly', 'Diabetic-friendly', 'Low-sodium', 'Halal', 'Kosher',
    'Mediterranean diet',
  ]),
  FridgeFilterGroup('ALLERGIES · always applied', [
    'No shellfish', 'Dairy-free', 'Gluten-free', 'Nut-free', 'Egg-free',
    'Soy-free', 'Sesame-free',
  ]),
  FridgeFilterGroup('CUISINE', [
    'Mediterranean', 'Mexican', 'Italian', 'Indian', 'Thai', 'Japanese',
    'Korean', 'Chinese', 'Middle Eastern', 'Greek', 'American', 'Southern',
  ]),
];

/// The popular subset shown inline on the collapsed/expanded filters card.
const List<FridgeFilterGroup> kFridgeInlineFilterGroups = [
  FridgeFilterGroup('MEAL', ['Breakfast', 'Lunch', 'Dinner', 'Snack']),
  FridgeFilterGroup('GOAL', ['High protein', 'Low carb', 'Low calorie', 'High fiber']),
  FridgeFilterGroup('TIME & EFFORT', ['≤ 15 min', '≤ 30 min', 'One-pan', 'No-cook']),
  FridgeFilterGroup('CUISINE', ['Mediterranean', 'Mexican', 'Asian', 'Indian']),
  FridgeFilterGroup(
      'DIET · from your preferences', ['Vegetarian', 'Vegan', 'Dairy-free', 'Gluten-free']),
];

/// Derive the default-active diet/allergy chips from the user's saved
/// nutrition preferences. These start ON and are what Reset restores.
Set<String> deriveDefaultDietFilters(NutritionPreferences? prefs) {
  final out = <String>{};
  if (prefs == null) return out;
  for (final r in prefs.dietaryRestrictions) {
    final label = _dietLabel(r);
    if (label != null) out.add(label);
  }
  for (final a in prefs.allergies) {
    final label = _allergyLabel(a);
    if (label != null) out.add(label);
  }
  return out;
}

String _norm(String s) =>
    s.toLowerCase().trim().replaceAll(RegExp(r'[\s\-]+'), '_');

String? _dietLabel(String raw) {
  final k = _norm(raw);
  if (k.contains('pescatarian')) return 'Pescatarian';
  if (k.contains('vegan')) return 'Vegan';
  if (k.contains('vegetarian')) return 'Vegetarian';
  if (k.contains('keto')) return 'Keto';
  if (k.contains('paleo')) return 'Paleo';
  if (k.contains('fodmap')) return 'Low-FODMAP';
  if (k.contains('glp')) return 'GLP-1 friendly';
  if (k.contains('diabet')) return 'Diabetic-friendly';
  if (k.contains('mediterranean')) return 'Mediterranean diet';
  if (k.contains('halal')) return 'Halal';
  if (k.contains('kosher')) return 'Kosher';
  if (k.contains('low_sodium') || k.contains('sodium')) return 'Low-sodium';
  if (k.contains('gluten')) return 'Gluten-free';
  if (k.contains('dairy') || k.contains('lactose')) return 'Dairy-free';
  return null;
}

String? _allergyLabel(String raw) {
  final k = _norm(raw);
  if (k.contains('shellfish') || k.contains('crustacean')) return 'No shellfish';
  if (k.contains('dairy') || k.contains('milk') || k.contains('lactose')) return 'Dairy-free';
  if (k.contains('gluten') || k.contains('wheat')) return 'Gluten-free';
  if (k.contains('nut') || k.contains('peanut')) return 'Nut-free';
  if (k.contains('egg')) return 'Egg-free';
  if (k.contains('soy')) return 'Soy-free';
  if (k.contains('sesame')) return 'Sesame-free';
  return null;
}

/// A single filter pill.
class FridgePref extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const FridgePref({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final accent = tc.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.14) : tc.surface,
          border: Border.all(
              color: selected ? accent.withValues(alpha: 0.5) : AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? accent : tc.textMuted,
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Full "All filters" sheet: search field that live-filters + every catalog
/// group + Reset / Done. Returns the updated active-label set via Navigator.pop
/// (null if dismissed).
class FridgeFiltersSheet extends StatefulWidget {
  final Set<String> active;
  final Set<String> defaults;
  const FridgeFiltersSheet({super.key, required this.active, required this.defaults});

  @override
  State<FridgeFiltersSheet> createState() => _FridgeFiltersSheetState();
}

class _FridgeFiltersSheetState extends State<FridgeFiltersSheet> {
  late Set<String> _active = {...widget.active};
  String _query = '';

  bool _matches(String label) =>
      _query.isEmpty || label.toLowerCase().contains(_query);

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.elevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ALL FILTERS', style: ZType.disp(20, color: tc.textPrimary)),
                const SizedBox(height: 10),
                TextField(
                  style: TextStyle(color: tc.textPrimary, fontSize: 13),
                  onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Search filters (e.g. FODMAP, keto, thai…)',
                    hintStyle: TextStyle(color: tc.textMuted, fontSize: 13),
                    filled: true,
                    fillColor: tc.surface,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.cardBorder)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: tc.accent)),
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              children: [
                for (final g in kFridgeFilterCatalog)
                  if (g.labels.any(_matches)) _group(g, tc),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _footBtn(
                      label: 'RESET',
                      primary: false,
                      tc: tc,
                      onTap: () => setState(() => _active = {...widget.defaults}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _footBtn(
                      label: 'DONE',
                      primary: true,
                      tc: tc,
                      onTap: () => Navigator.of(context).pop(_active),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _group(FridgeFilterGroup g, ThemeColors tc) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(g.key, style: ZType.lbl(9.5, color: tc.textMuted, letterSpacing: 1.4)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in g.labels)
                if (_matches(label))
                  FridgePref(
                    label: label,
                    selected: _active.contains(label),
                    onTap: () => setState(() {
                      _active.contains(label)
                          ? _active.remove(label)
                          : _active.add(label);
                    }),
                  ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _footBtn({
    required String label,
    required bool primary,
    required ThemeColors tc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? tc.accent : Colors.transparent,
          border: primary ? null : Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: ZType.lbl(14,
              color: primary ? tc.accentContrast : tc.textPrimary, letterSpacing: 2),
        ),
      ),
    );
  }
}
