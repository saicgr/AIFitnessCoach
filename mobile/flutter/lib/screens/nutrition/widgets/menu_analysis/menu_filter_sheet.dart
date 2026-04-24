import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/menu_item.dart';
import '../../../../widgets/glass_sheet.dart';
import 'menu_filter_state.dart';

/// Secondary glass sheet for choosing filter criteria. Renders over the
/// main MenuAnalysisSheet. Returns an updated MenuFilterState via the
/// standard `showGlassSheet<T>` result channel.
class MenuFilterSheet extends StatefulWidget {
  final MenuFilterState initial;
  final int resultCount;
  final List<MenuItem> allItems;

  const MenuFilterSheet({
    super.key,
    required this.initial,
    required this.resultCount,
    required this.allItems,
  });

  static Future<MenuFilterState?> show(
    BuildContext context, {
    required MenuFilterState initial,
    required List<MenuItem> allItems,
    required int resultCount,
  }) {
    return showGlassSheet<MenuFilterState>(
      context: context,
      builder: (_) => MenuFilterSheet(
        initial: initial,
        resultCount: resultCount,
        allItems: allItems,
      ),
    );
  }

  @override
  State<MenuFilterSheet> createState() => _MenuFilterSheetState();
}

class _MenuFilterSheetState extends State<MenuFilterSheet> {
  late MenuFilterState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
  }

  int get _previewCount {
    return widget.allItems.where((i) => _state.accepts(i)).length;
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.allItems.map((i) => i.section).toSet().toList()
      ..sort();

    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _state = MenuFilterState.empty),
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _section(
              'Health',
              child: _chipGroup(
                options: const {'green': 'Good', 'yellow': 'Moderate', 'red': 'Limit'},
                selected: _state.healthRatings,
                onToggle: (v) {
                  final next = {..._state.healthRatings};
                  next.contains(v) ? next.remove(v) : next.add(v);
                  setState(() => _state = _state.copyWith(healthRatings: next));
                },
              ),
            ),
            _section(
              'Inflammation',
              child: _chipGroup(
                options: const {
                  'anti': 'Anti-inflammatory',
                  'mild': 'Mildly inflammatory',
                  'high': 'Highly inflammatory',
                },
                selected: _state.inflammationBuckets,
                onToggle: (v) {
                  final next = {..._state.inflammationBuckets};
                  next.contains(v) ? next.remove(v) : next.add(v);
                  setState(() => _state = _state.copyWith(inflammationBuckets: next));
                },
              ),
            ),
            _section(
              'Macros',
              child: Column(
                children: [
                  _rangeSlider(
                    label: 'Min protein',
                    value: _state.minProteinG,
                    min: 0, max: 80, unit: 'g',
                    onChanged: (v) => setState(() => _state = _state.copyWith(
                      minProteinG: v,
                      clearMinProteinG: v == null,
                    )),
                  ),
                  _rangeSlider(
                    label: 'Max carbs',
                    value: _state.maxCarbsG,
                    min: 0, max: 150, unit: 'g',
                    onChanged: (v) => setState(() => _state = _state.copyWith(
                      maxCarbsG: v, clearMaxCarbsG: v == null,
                    )),
                  ),
                  _rangeSlider(
                    label: 'Max fat',
                    value: _state.maxFatG,
                    min: 0, max: 80, unit: 'g',
                    onChanged: (v) => setState(() => _state = _state.copyWith(
                      maxFatG: v, clearMaxFatG: v == null,
                    )),
                  ),
                  _rangeSlider(
                    label: 'Max calories',
                    value: _state.maxCalories,
                    min: 0, max: 1200, unit: 'cal',
                    onChanged: (v) => setState(() => _state = _state.copyWith(
                      maxCalories: v, clearMaxCalories: v == null,
                    )),
                  ),
                ],
              ),
            ),
            _section(
              'Budget',
              child: _rangeSlider(
                label: 'Max price',
                value: _state.maxPriceUsd,
                min: 0, max: 80, unit: '\$',
                onChanged: (v) => setState(() => _state = _state.copyWith(
                  maxPriceUsd: v, clearMaxPriceUsd: v == null,
                )),
              ),
            ),
            if (sections.length > 1)
              _section(
                'Sections',
                child: _chipGroup(
                  options: {for (final s in sections) s: displaySectionName(s)},
                  selected: _state.sections,
                  onToggle: (v) {
                    final next = {..._state.sections};
                    next.contains(v) ? next.remove(v) : next.add(v);
                    setState(() => _state = _state.copyWith(sections: next));
                  },
                ),
              ),
            _section(
              'Safety',
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hide dishes with my allergens', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Using your saved allergen profile', style: TextStyle(fontSize: 11)),
                value: _state.hideAllergenDishes,
                onChanged: (v) =>
                    setState(() => _state = _state.copyWith(hideAllergenDishes: v)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _state),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text('Apply ($_previewCount)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: const TextStyle(
            fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2,
          )),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _chipGroup({
    required Map<String, String> options,
    required Set<String> selected,
    required ValueChanged<String> onToggle,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: options.entries.map((e) {
        final isSel = selected.contains(e.key);
        return FilterChip(
          label: Text(e.value),
          selected: isSel,
          onSelected: (_) => onToggle(e.key),
          selectedColor: AppColors.orange.withValues(alpha: 0.2),
          checkmarkColor: AppColors.orange,
          labelStyle: TextStyle(
            fontSize: 12,
            color: isSel ? AppColors.orange : null,
            fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
          ),
        );
      }).toList(),
    );
  }

  Widget _rangeSlider({
    required String label,
    required double? value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double?> onChanged,
  }) {
    final current = value ?? max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  value == null ? label : '$label: ${_fmt(current, unit)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
              if (value != null)
                TextButton(
                  onPressed: () => onChanged(null),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('Off', style: TextStyle(fontSize: 11)),
                ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(trackHeight: 3),
            child: Slider(
              value: current.clamp(min, max).toDouble(),
              min: min,
              max: max,
              onChanged: (v) => onChanged(v),
              activeColor: AppColors.orange,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == '\$') return '\$${v.toStringAsFixed(2)}';
    return '${v.round()} $unit';
  }
}
