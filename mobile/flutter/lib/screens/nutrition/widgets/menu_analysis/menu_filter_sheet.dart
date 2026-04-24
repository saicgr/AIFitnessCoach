import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/menu_item.dart';
import '../../../../widgets/glass_sheet.dart';
import 'diet_heuristics.dart';
import 'menu_filter_state.dart';

/// Goal-oriented filter sheet for Menu Analysis.
///
/// Design principles:
///  • Lead with outcomes the user can name — "high protein", "low carb",
///    "vegan", "gluten-free" — instead of raw macro sliders. The hidden
///    numbers live under an Advanced section so they don't block the
///    casual user.
///  • Diet chips live alongside smart presets as equal peers — most users
///    pick a diet + one goal, e.g. "Vegetarian + High protein".
///  • Pinned header (Filters / Reset) and pinned footer (Show N dishes)
///    so the user never loses context while scrolling.
///  • The Apply label reports *results*, not selection count — "Show 8 of
///    13 dishes" is obvious where "Apply (8)" reads like eight filters.
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
  bool _advancedOpen = false;

  @override
  void initState() {
    super.initState();
    _state = widget.initial;
    // Auto-expand Advanced if the user arrived with any advanced field set —
    // otherwise their active filters would be hidden behind a disclosure
    // triangle, which is confusing.
    _advancedOpen = _state.hasAdvanced;
  }

  int get _previewCount {
    return widget.allItems.where((i) => _state.accepts(i)).length;
  }

  void _togglePreset(String id) {
    final next = {..._state.smartPresets};
    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _state = _state.copyWith(smartPresets: next));
  }

  void _toggleDiet(String id) {
    final next = {..._state.diets};
    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _state = _state.copyWith(diets: next));
  }

  void _toggleHealth(String id) {
    final next = {..._state.healthRatings};
    next.contains(id) ? next.remove(id) : next.add(id);
    setState(() => _state = _state.copyWith(healthRatings: next));
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.allItems.map((i) => i.section).toSet().toList()
      ..sort();
    final total = widget.allItems.length;
    final matches = _previewCount;

    return GlassSheet(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(),
            Flexible(
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: [
                  const SizedBox(height: 4),
                  _quickPresetsSection(),
                  _dietSection(),
                  _healthSection(),
                  _priceSection(),
                  _avoidSection(),
                  const SizedBox(height: 8),
                  _advancedToggle(),
                  if (_advancedOpen) ...[
                    _bloodSugarSection(),
                    _fodmapSection(),
                    _inflammationSection(),
                    _macrosSection(),
                    if (sections.length > 1) _sectionsSection(sections),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
            const SizedBox(height: 8),
            _applyButton(matches: matches, total: total),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── header + footer ───────────────────────────

  Widget _header() {
    return Row(
      children: [
        const Text(
          'Filters',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const Spacer(),
        if (_state.hasAnyFilter)
          TextButton(
            onPressed: () => setState(() => _state = MenuFilterState.empty),
            child: const Text('Reset'),
          ),
      ],
    );
  }

  Widget _applyButton({required int matches, required int total}) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: matches == 0 ? null : () => Navigator.pop(context, _state),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          padding: const EdgeInsets.symmetric(vertical: 14),
          disabledBackgroundColor: AppColors.orange.withValues(alpha: 0.3),
        ),
        child: Text(
          matches == 0
              ? 'No dishes match'
              : matches == total
                  ? 'Show all $total dishes'
                  : 'Show $matches of $total dishes',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  // ──────────────────────────── quick presets ────────────────────────────

  Widget _quickPresetsSection() {
    return _section(
      title: 'What are you in the mood for?',
      caption: 'Tap any that apply — we\'ll only show matching dishes.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final preset in SmartPresets.all)
            _PresetChip(
              emoji: preset.emoji,
              label: preset.label,
              hint: preset.hint,
              selected: _state.smartPresets.contains(preset.id),
              onTap: () => _togglePreset(preset.id),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────── diet ─────────────────────────────

  Widget _dietSection() {
    return _section(
      title: 'Diet',
      caption: 'We\'ll hide dishes that don\'t fit your diet.',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final entry in DietHeuristics.labels.entries)
            _Pill(
              label: entry.value,
              selected: _state.diets.contains(entry.key),
              onTap: () => _toggleDiet(entry.key),
            ),
        ],
      ),
    );
  }

  // ───────────────────────── health rating ─────────────────────────

  Widget _healthSection() {
    return _section(
      title: 'Coach\'s verdict',
      caption: 'How the AI rated each dish for your goals.',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _Pill(
            label: '✅ Good',
            selected: _state.healthRatings.contains('green'),
            onTap: () => _toggleHealth('green'),
          ),
          _Pill(
            label: '👌 Okay',
            selected: _state.healthRatings.contains('yellow'),
            onTap: () => _toggleHealth('yellow'),
          ),
          _Pill(
            label: '⚠️ Skip',
            selected: _state.healthRatings.contains('red'),
            onTap: () => _toggleHealth('red'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────── price ───────────────────────────

  Widget _priceSection() {
    return _section(
      title: 'Per-dish budget',
      caption: 'Applies only to dishes with a listed price.',
      child: _rangeSlider(
        label: 'Max price',
        value: _state.maxPriceUsd,
        min: 0,
        max: 80,
        unit: '\$',
        onChanged: (v) => setState(() => _state = _state.copyWith(
              maxPriceUsd: v,
              clearMaxPriceUsd: v == null,
            )),
      ),
    );
  }

  // ─────────────────────────── avoid ───────────────────────────

  Widget _avoidSection() {
    return _section(
      title: 'Avoid',
      child: Column(
        children: [
          _SwitchRow(
            title: 'Hide dishes with my allergens',
            subtitle: 'Uses your saved allergen profile',
            value: _state.hideAllergenDishes,
            onChanged: (v) =>
                setState(() => _state = _state.copyWith(hideAllergenDishes: v)),
          ),
          _SwitchRow(
            title: 'Hide ultra-processed dishes',
            subtitle: 'Skips NOVA-4 foods (industrial emulsifiers, HFCS, etc.)',
            value: _state.hideUltraProcessed,
            onChanged: (v) =>
                setState(() => _state = _state.copyWith(hideUltraProcessed: v)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────── advanced toggle ───────────────────────

  Widget _advancedToggle() {
    return InkWell(
      onTap: () => setState(() => _advancedOpen = !_advancedOpen),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(Icons.tune, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(
              _advancedOpen ? 'Hide advanced filters' : 'Advanced filters',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Icon(
              _advancedOpen ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────── advanced: blood sugar ────────────────────────

  Widget _bloodSugarSection() {
    return _section(
      title: 'Blood sugar',
      caption: 'Glycemic load per serving — lower = steadier energy.',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _glIdiom('9', 'Very stable', 'Only low-GL (under 10)'),
          _glIdiom('19', 'Steady', 'Low or medium (under 20)'),
          _glIdiom('40', 'Hide spikes only', 'Allow most dishes'),
        ],
      ),
    );
  }

  Widget _glIdiom(String value, String label, String tooltip) {
    final current = _state.maxGlycemicLoad?.round().toString();
    return _Pill(
      label: label,
      tooltip: tooltip,
      selected: current == value,
      onTap: () {
        final parsed = double.tryParse(value);
        final already = _state.maxGlycemicLoad?.round() == parsed?.round();
        setState(() => _state = _state.copyWith(
              maxGlycemicLoad: already ? null : parsed,
              clearMaxGlycemicLoad: already,
            ));
      },
    );
  }

  // ──────────────────────── advanced: FODMAP ────────────────────────

  Widget _fodmapSection() {
    return _section(
      title: 'FODMAP (IBS)',
      caption: 'Onion, garlic, wheat, lactose can trigger IBS symptoms.',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _fodmapPill('low', 'Strict low-FODMAP'),
          _fodmapPill('medium', 'Allow some triggers'),
          _fodmapPill('high', 'No limit'),
        ],
      ),
    );
  }

  Widget _fodmapPill(String value, String label) {
    return _Pill(
      label: label,
      selected: _state.fodmapMax == value,
      onTap: () {
        final already = _state.fodmapMax == value;
        setState(() => _state = _state.copyWith(
              fodmapMax: already ? null : value,
              clearFodmapMax: already,
            ));
      },
    );
  }

  // ──────────────────── advanced: inflammation ────────────────────

  Widget _inflammationSection() {
    return _section(
      title: 'Inflammation',
      caption: 'Based on ingredient profile (omega-3, fiber, added sugar, etc.).',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _inflamPill('anti', 'Anti-inflammatory'),
          _inflamPill('mild', 'Mild'),
          _inflamPill('high', 'Highly inflammatory'),
        ],
      ),
    );
  }

  Widget _inflamPill(String id, String label) {
    return _Pill(
      label: label,
      selected: _state.inflammationBuckets.contains(id),
      onTap: () {
        final next = {..._state.inflammationBuckets};
        next.contains(id) ? next.remove(id) : next.add(id);
        setState(() => _state = _state.copyWith(inflammationBuckets: next));
      },
    );
  }

  // ──────────────────── advanced: macros ────────────────────

  Widget _macrosSection() {
    return _section(
      title: 'Fine-tune macros',
      caption: 'For specific targets. Most people won\'t need this.',
      child: Column(
        children: [
          _rangeSlider(
            label: 'Protein at least',
            value: _state.minProteinG,
            min: 0,
            max: 80,
            unit: 'g',
            onChanged: (v) => setState(() => _state = _state.copyWith(
                  minProteinG: v,
                  clearMinProteinG: v == null,
                )),
          ),
          _rangeSlider(
            label: 'Carbs at most',
            value: _state.maxCarbsG,
            min: 0,
            max: 150,
            unit: 'g',
            onChanged: (v) => setState(() => _state = _state.copyWith(
                  maxCarbsG: v,
                  clearMaxCarbsG: v == null,
                )),
          ),
          _rangeSlider(
            label: 'Fat at most',
            value: _state.maxFatG,
            min: 0,
            max: 80,
            unit: 'g',
            onChanged: (v) => setState(() => _state = _state.copyWith(
                  maxFatG: v,
                  clearMaxFatG: v == null,
                )),
          ),
          _rangeSlider(
            label: 'Calories at most',
            value: _state.maxCalories,
            min: 0,
            max: 1200,
            unit: 'cal',
            onChanged: (v) => setState(() => _state = _state.copyWith(
                  maxCalories: v,
                  clearMaxCalories: v == null,
                )),
          ),
        ],
      ),
    );
  }

  // ──────────────────── advanced: sections ────────────────────

  Widget _sectionsSection(List<String> sections) {
    return _section(
      title: 'Menu sections',
      caption: 'Show only certain parts of the menu.',
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          for (final s in sections)
            _Pill(
              label: displaySectionName(s),
              selected: _state.sections.contains(s),
              onTap: () {
                final next = {..._state.sections};
                next.contains(s) ? next.remove(s) : next.add(s);
                setState(() => _state = _state.copyWith(sections: next));
              },
            ),
        ],
      ),
    );
  }

  // ─────────────────────────── shared builders ───────────────────────────

  Widget _section({
    required String title,
    String? caption,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (caption != null) ...[
            const SizedBox(height: 2),
            Text(
              caption,
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.3),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  /// Range slider — kept in the Advanced drawer because it's the piece
  /// non-nerd users bounce off. When off, track reads grey + the label says
  /// "Off"; when on, track is orange + label shows the numeric value.
  Widget _rangeSlider({
    required String label,
    required double? value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double?> onChanged,
  }) {
    final enabled = value != null;
    final midpoint = ((min + max) / 2).roundToDouble();
    final current = (value ?? midpoint).clamp(min, max).toDouble();
    final offColor = AppColors.textMuted.withValues(alpha: 0.6);
    final activeColor = AppColors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: enabled ? activeColor : offColor,
                    ),
                    children: [
                      TextSpan(text: label),
                      TextSpan(
                        text: enabled ? ' · ${_fmt(current, unit)}' : ' · Off',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: enabled ? activeColor : offColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Switch.adaptive(
                value: enabled,
                activeTrackColor: activeColor,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (v) => onChanged(v ? midpoint : null),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              disabledActiveTrackColor: offColor.withValues(alpha: 0.3),
              disabledInactiveTrackColor: offColor.withValues(alpha: 0.15),
              disabledThumbColor: offColor,
            ),
            child: Slider(
              value: current,
              min: min,
              max: max,
              onChanged: (v) => onChanged(v),
              activeColor: activeColor,
              inactiveColor: enabled ? null : offColor.withValues(alpha: 0.2),
              thumbColor: enabled ? activeColor : offColor,
              label: _fmt(current, unit),
              divisions: max <= 10 ? max.toInt() : null,
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v, String unit) {
    if (unit == '\$') return '\$${v.toStringAsFixed(0)}';
    return '${v.round()} $unit';
  }
}

// ─────────────────────────── reusable pills ───────────────────────────

/// Big preset tile with emoji + primary label + grey hint line.
class _PresetChip extends StatelessWidget {
  final String emoji;
  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({
    required this.emoji,
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.orange.withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.05);
    final border = selected
        ? AppColors.orange
        : Colors.white.withValues(alpha: 0.12);
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.orange : null,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact single-line selector pill. Replaces Flutter's default FilterChip
/// so we get consistent padding + orange accent with the rest of the sheet.
class _Pill extends StatelessWidget {
  final String label;
  final String? tooltip;
  final bool selected;
  final VoidCallback onTap;

  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.orange.withValues(alpha: 0.18)
        : Colors.white.withValues(alpha: 0.06);
    final border = selected
        ? AppColors.orange
        : Colors.white.withValues(alpha: 0.12);
    final chip = Material(
      color: bg,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? AppColors.orange : null,
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return chip;
    return Tooltip(message: tooltip!, child: chip);
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      subtitle!,
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.orange,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
