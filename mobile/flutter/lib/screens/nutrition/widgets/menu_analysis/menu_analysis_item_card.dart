import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/allergen.dart';
import '../../../../data/models/menu_item.dart';

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
                          if (item.rating != null) _RatingPill(rating: item.rating!),
                        ],
                      ),
                      if (item.weightG != null || item.amount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _subtitle(item),
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ),
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
                        multiplier: item.portionMultiplier,
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

  static String _subtitle(MenuItem item) {
    final parts = <String>[];
    if (item.weightG != null) {
      parts.add('${item.scaledWeightG!.round()} g');
    }
    if (item.amount != null && item.amount!.isNotEmpty) {
      parts.add(item.amount!);
    }
    if (item.inflammationScore != null) {
      final label = item.inflammationScore! <= 3
          ? 'anti-inflammatory'
          : item.inflammationScore! <= 6
              ? 'mildly inflammatory'
              : 'highly inflammatory';
      parts.add('$label (${item.inflammationScore!}/10)');
    }
    return parts.join(' · ');
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
  const _RatingPill({required this.rating});
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
        label = 'Limit';
        break;
      default:
        return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w700, color: color,
        ),
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

class _PortionStepper extends StatelessWidget {
  final double multiplier;
  final ValueChanged<double> onChanged;
  const _PortionStepper({required this.multiplier, required this.onChanged});

  static const _steps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Portion',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textMuted
                : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        _roundBtn(Icons.remove, () {
          final idx = _steps.indexWhere((s) => (s - multiplier).abs() < 0.01);
          if (idx > 0) onChanged(_steps[idx - 1]);
        }),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _formatMultiplier(multiplier),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        _roundBtn(Icons.add, () {
          final idx = _steps.indexWhere((s) => (s - multiplier).abs() < 0.01);
          if (idx >= 0 && idx < _steps.length - 1) onChanged(_steps[idx + 1]);
        }),
      ],
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
