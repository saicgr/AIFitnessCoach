import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/allergen.dart';
import '../../../../data/models/menu_item.dart';
import '../score_explain_sheet.dart';

/// Single dish row in the Menu Analysis sheet. Shows:
///  • Checkbox + name + portion weight
///  • Macro row (decimal-precise, rounded only when value IS a clean
///    multiple of 5 — otherwise we show one decimal so the numbers
///    don't feel suspiciously round)
///  • Price (if present) on the right of macros
///  • Health rating pill + inflammation chip
///  • Coach tip (Gemini-generated, optional)
///  • Allergen warning banner (only if user's allergen profile hits)
///  • Portion stepper: ±0.5× buttons that scale macros live
///
/// Tapping the card toggles selection. The portion stepper is a
/// separate tap target so the portion can be adjusted without
/// toggling the checkbox.
class MenuAnalysisItemCard extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final UserAllergenProfile? allergenProfile;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<double> onPortionChanged;

  const MenuAnalysisItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.allergenProfile,
    required this.onToggle,
    required this.onPortionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final allergenHits = allergenProfile == null
        ? const <String>[]
        : allergenProfile!
            .matchesForDish(
              dishName: item.name,
              detectedAllergens: item.detectedAllergens,
              dishDescription: item.coachTip,
            )
            .toList();

    return InkWell(
      onTap: () => onToggle(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.orange.withValues(alpha: 0.08)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.orange.withValues(alpha: 0.4)
                : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (item.rating != null)
                            _RatingPill(
                              rating: item.rating!,
                              onTap: () => ScoreExplainSheet.show(
                                context,
                                kind: ScoreKind.rating,
                                value: item.rating,
                                reason: item.ratingReason ?? item.coachTip,
                              ),
                            ),
                        ],
                      ),
                      if (item.weightG != null || item.amount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _subtitlePortion(item),
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ),
                      // Tappable score chips (inflammation / glycemic load /
                      // FODMAP / ultra-processed) — each opens the shared
                      // ScoreExplainSheet with the dish's context. Wrap so
                      // long dish names don't elbow chips off the row.
                      if (_hasAnyScore(item)) ...[
                        const SizedBox(height: 4),
                        _ScoreChipRow(item: item),
                      ],
                      const SizedBox(height: 6),
                      _MacroLine(item: item, color: textSecondary),
                      if (item.coachTip != null && item.coachTip!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: AppColors.orange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.coachTip!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (allergenHits.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _AllergenWarning(matches: allergenHits),
                      ],
                      const SizedBox(height: 6),
                      _PortionStepper(
                        item: item,
                        onChanged: onPortionChanged,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Portion descriptor only — no inflammation copy (that moved to its own
  /// tappable chip on the ScoreChipRow below).
  static String _subtitlePortion(MenuItem item) {
    final parts = <String>[];
    if (item.weightG != null) {
      parts.add('${item.scaledWeightG!.round()} g');
    }
    if (item.amount != null && item.amount!.isNotEmpty) {
      parts.add(item.amount!);
    }
    return parts.join(' · ');
  }

  static bool _hasAnyScore(MenuItem item) =>
      item.inflammationScore != null ||
      item.glycemicLoad != null ||
      item.fodmapRating != null ||
      item.isUltraProcessed == true;
}

/// Inline row of tappable score chips shown beneath each menu item.
///
/// Every chip opens [ScoreExplainSheet] so the user can learn what the
/// score means without leaving the sheet. Chips are compact — we trust
/// the colour + short label and let the explain sheet carry the detail.
class _ScoreChipRow extends StatelessWidget {
  final MenuItem item;
  const _ScoreChipRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: [
        if (item.inflammationScore != null)
          _ScoreChip(
            label: '🔥 ${item.inflammationScore}/10',
            color: item.inflammationScore! >= 7
                ? AppColors.error
                : item.inflammationScore! >= 4
                    ? AppColors.orange
                    : AppColors.success,
            onTap: () => ScoreExplainSheet.show(
              context,
              kind: ScoreKind.inflammation,
              value: item.inflammationScore,
              reason: item.ratingReason,
            ),
          ),
        if (item.glycemicLoad != null)
          _ScoreChip(
            label: 'GL ${item.glycemicLoad}',
            color: item.glycemicLoad! >= 20
                ? AppColors.error
                : item.glycemicLoad! >= 10
                    ? AppColors.orange
                    : AppColors.success,
            onTap: () => ScoreExplainSheet.show(
              context,
              kind: ScoreKind.glycemicLoad,
              value: item.glycemicLoad,
            ),
          ),
        if (item.fodmapRating != null)
          _ScoreChip(
            label: 'FODMAP ${item.fodmapRating!.toUpperCase()}',
            color: item.fodmapRating == 'high'
                ? AppColors.error
                : item.fodmapRating == 'medium'
                    ? AppColors.orange
                    : AppColors.success,
            onTap: () => ScoreExplainSheet.show(
              context,
              kind: ScoreKind.fodmap,
              value: item.fodmapRating,
              reason: item.fodmapReason,
            ),
          ),
        if (item.isUltraProcessed == true)
          _ScoreChip(
            label: 'Ultra-processed',
            color: AppColors.error,
            onTap: () => ScoreExplainSheet.show(
              context,
              kind: ScoreKind.ultraProcessed,
              value: true,
            ),
          ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ScoreChip({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.35), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.info_outline, size: 10, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final MenuItem item;
  final Color color;
  const _MacroLine({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        _macro(item.scaledCalories, 'cal', AppColors.coral),
        _macro(item.scaledProteinG, 'g P', AppColors.macroProtein),
        _macro(item.scaledCarbsG, 'g C', AppColors.macroCarbs),
        _macro(item.scaledFatG, 'g F', AppColors.macroFat),
        if (item.price != null)
          Text(
            _formatPrice(item.price!, item.currency),
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
      ],
    );
  }

  /// Preserve decimal precision when the value isn't a clean multiple of 5
  /// so Gemini's numbers don't read as suspiciously round.
  static Widget _macro(double value, String unit, Color c) {
    final isClean = (value - value.round()).abs() < 0.05 && value.round() % 5 == 0;
    final text = isClean
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: c,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: c.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double price, String? currency) {
    final symbol = switch (currency) {
      'USD' || null => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'INR' => '₹',
      'JPY' => '¥',
      _ => (currency.length <= 3 ? '$currency ' : '\$'),
    };
    return '$symbol${price.toStringAsFixed(2)}';
  }
}

class _RatingPill extends StatelessWidget {
  final String rating;
  final VoidCallback? onTap;
  const _RatingPill({required this.rating, this.onTap});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (rating) {
      case 'green':
        color = AppColors.success;
        label = 'Good';
        break;
      case 'yellow':
        color = AppColors.orange;
        label = 'Moderate';
        break;
      case 'red':
        color = AppColors.error;
        // "Skip" matches the AI recommendation copy ("Skip; contains...")
        // already rendered in the card body. "Limit" was ambiguous — could
        // be read as "eat a small amount" when the intent here is "avoid".
        label = 'Skip';
        break;
      default:
        return const SizedBox.shrink();
    }
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.info_outline, size: 10, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: pill,
      ),
    );
  }
}

class _AllergenWarning extends StatelessWidget {
  final List<String> matches;
  const _AllergenWarning({required this.matches});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Contains ${matches.join(' · ')}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Portion control with two linked affordances:
///   • Discrete multiplier stepper (−/1×/+) — quick half/full/double taps.
///   • Tap-to-edit weight in grams — morphs the "180 g" chip into a TextField
///     so the user can type exactly what they're eating. Saves on ✓.
///
/// Per feedback_inline_editing.md: prefer tap-to-edit over modal sheets when
/// the value is already visible on screen. When the dish has no baseline
/// `weightG`, the grams editor hides and we fall back to multiplier-only.
class _PortionStepper extends StatefulWidget {
  final MenuItem item;
  final ValueChanged<double> onChanged;
  const _PortionStepper({required this.item, required this.onChanged});

  static const _steps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  State<_PortionStepper> createState() => _PortionStepperState();
}

class _PortionStepperState extends State<_PortionStepper> {
  bool _editing = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    final current = widget.item.scaledWeightG?.round();
    _controller.text = current == null ? '' : current.toString();
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _saveEdit() {
    final grams = double.tryParse(_controller.text.trim());
    if (grams != null && grams > 0) {
      final mult = widget.item.multiplierForWeight(grams);
      if (mult != null) widget.onChanged(mult);
    }
    setState(() => _editing = false);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasWeight = item.weightG != null && item.weightG! > 0;
    final steps = _PortionStepper._steps;
    final idx = steps.indexWhere((s) => (s - item.portionMultiplier).abs() < 0.01);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Portion',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        _roundBtn(Icons.remove, () {
          if (idx > 0) widget.onChanged(steps[idx - 1]);
        }),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _formatMultiplier(item.portionMultiplier),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        _roundBtn(Icons.add, () {
          if (idx >= 0 && idx < steps.length - 1) widget.onChanged(steps[idx + 1]);
        }),
        if (hasWeight) ...[
          const SizedBox(width: 10),
          Container(width: 1, height: 14, color: (isDark ? AppColors.cardBorder : Colors.grey.shade300)),
          const SizedBox(width: 10),
          if (_editing)
            _weightEditor(isDark)
          else
            _weightChip(isDark, item.scaledWeightG!.round()),
        ],
      ],
    );
  }

  Widget _weightChip(bool isDark, int grams) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _startEdit,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$grams g',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 11, color: AppColors.orange.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weightEditor(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _saveEdit(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                suffixText: 'g',
                suffixStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange),
              ),
            ),
          ),
          InkWell(
            onTap: _cancelEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.close, size: 14, color: AppColors.orange),
            ),
          ),
          InkWell(
            onTap: _saveEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.check, size: 14, color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMultiplier(double m) {
    if (m == 0.5) return '½×';
    if (m == 0.75) return '¾×';
    if (m == 1.0) return '1×';
    if (m == 1.25) return '1¼×';
    if (m == 1.5) return '1½×';
    if (m == 2.0) return '2×';
    return '${m.toStringAsFixed(2)}×';
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.orange),
      ),
    );
  }
}
