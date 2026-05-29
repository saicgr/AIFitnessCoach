import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../l10n/generated/app_localizations.dart';

/// Macro Breakdown card — a weekly-average macro distribution stacked bar plus
/// per-macro detail rows (grams + % of energy).
///
/// Extracted verbatim from the /stats Nutrition tab (the original private
/// `_MacroBreakdownCard` + `_MacroRow`) so it can be reused on the Nutrition
/// tab without any visual change. Constructor signature unchanged. The
/// teal/blue/orange macro colors are preserved exactly so the /stats screen
/// looks identical.
class MacroBreakdownCard extends StatelessWidget {
  final AsyncValue<WeeklyNutritionData?> weeklyNutrition;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const MacroBreakdownCard({
    super.key,
    required this.weeklyNutrition,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: weeklyNutrition.when(
        // Layout-matched skeleton: title + stacked bar + 3 macro rows.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 150, height: 16, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 20, radius: 6),
            SizedBox(height: 16),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionTabPartCouldNotLoadMacros,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (data) {
          if (data == null || data.daysWithData == 0) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text(AppLocalizations.of(context).nutritionTabPartNoMacroDataThis,
                    style: TextStyle(color: textMuted)),
              ),
            );
          }
          final macros = data.averageMacros;
          final totalCals = (macros.protein * 4) +
              (macros.carbs * 4) +
              (macros.fat * 9);
          final proteinPct =
              totalCals > 0 ? (macros.protein * 4 / totalCals * 100) : 0.0;
          final carbsPct =
              totalCals > 0 ? (macros.carbs * 4 / totalCals * 100) : 0.0;
          final fatPct =
              totalCals > 0 ? (macros.fat * 9 / totalCals * 100) : 0.0;

          const proteinColor = Color(0xFF009688);
          const carbsColor = Color(0xFF42A5F5);
          const fatColor = Color(0xFFFF9800);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).nutritionTabPartMacroBreakdown,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppLocalizations.of(context).nutritionTabPartWeeklyAverageDistribution,
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 16),
              // Stacked bar showing macro distribution
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      if (proteinPct > 0)
                        Expanded(
                          flex: proteinPct.round().clamp(1, 100),
                          child: Container(color: proteinColor),
                        ),
                      if (carbsPct > 0)
                        Expanded(
                          flex: carbsPct.round().clamp(1, 100),
                          child: Container(color: carbsColor),
                        ),
                      if (fatPct > 0)
                        Expanded(
                          flex: fatPct.round().clamp(1, 100),
                          child: Container(color: fatColor),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Macro detail rows
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                grams: macros.protein,
                pct: proteinPct,
                color: proteinColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                grams: macros.carbs,
                pct: carbsPct,
                color: carbsColor,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              _MacroRow(
                label: AppLocalizations.of(context).weeklyCheckinSheetFat,
                grams: macros.fat,
                pct: fatPct,
                color: fatColor,
                isDark: isDark,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  final String label;
  final double grams;
  final double pct;
  final Color color;
  final bool isDark;

  const _MacroRow({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondary : AppColorsLight.textSecondary,
            ),
          ),
        ),
        Text(
          '${grams.round()}g',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const Spacer(),
        Text(
          '${pct.round()}%',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
      ],
    );
  }
}
