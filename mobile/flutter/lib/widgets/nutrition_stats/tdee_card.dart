import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/widgets/skeleton/skeleton.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../l10n/generated/app_localizations.dart';

/// TDEE & Energy Balance card — total daily energy expenditure with a
/// confidence pill, intake-vs-TDEE delta, weight trend, and a metabolic
/// adaptation warning.
///
/// Extracted verbatim from the /stats Nutrition tab (the original private
/// `_TDEECard`) so it can be reused on the Nutrition tab without any visual
/// change. Constructor signature unchanged.
class TDEECard extends StatelessWidget {
  final AsyncValue<DetailedTDEE?> detailedTDEE;
  final AsyncValue<WeeklySummaryData?> weeklySummary;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final bool isDark;

  const TDEECard({
    super.key,
    required this.detailedTDEE,
    required this.weeklySummary,
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
      child: detailedTDEE.when(
        // Layout-matched skeleton: title + large TDEE figure + 2 detail rows.
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 180, height: 16, radius: 6),
            SizedBox(height: 12),
            SkeletonBox(width: 160, height: 32, radius: 8),
            SizedBox(height: 12),
            SkeletonBox(height: 14, radius: 6),
            SizedBox(height: 8),
            SkeletonBox(height: 14, radius: 6),
          ],
        ),
        error: (_, __) => SizedBox(
          height: 60,
          child: Center(
            child: Text(AppLocalizations.of(context).nutritionTabPartCouldNotLoadTdee,
                style: TextStyle(color: textMuted)),
          ),
        ),
        data: (tdee) {
          if (tdee == null) {
            return SizedBox(
              height: 60,
              child: Center(
                child: Text(AppLocalizations.of(context).nutritionTabPartNotEnoughDataFor,
                    style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            );
          }

          final avgIntake =
              weeklySummary.valueOrNull?.avgCalories ?? 0;
          final confidenceColor = switch (tdee.confidenceLevel) {
            'high' => const Color(0xFF4CAF50),
            'medium' => const Color(0xFFFF9800),
            _ => const Color(0xFFF44336),
          };

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).nutritionTabPartTdeeEnergyBalance,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: confidenceColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tdee.confidenceLevel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: confidenceColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Main TDEE display
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tdee.tdee}',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      'cal/day  ${tdee.uncertaintyDisplay}',
                      style: TextStyle(fontSize: 13, color: textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Intake vs TDEE
              if (avgIntake > 0) ...[
                Row(
                  children: [
                    Icon(Icons.restaurant, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Avg intake: $avgIntake cal',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                    const Spacer(),
                    Text(
                      '${avgIntake - tdee.tdee > 0 ? '+' : ''}${avgIntake - tdee.tdee} cal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: (avgIntake - tdee.tdee).abs() < 100
                            ? const Color(0xFF4CAF50)
                            : (avgIntake > tdee.tdee
                                ? const Color(0xFFFF9800)
                                : const Color(0xFF42A5F5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              // Weight trend
              Row(
                children: [
                  Icon(
                    tdee.weightTrend.direction == 'losing'
                        ? Icons.trending_down
                        : tdee.weightTrend.direction == 'gaining'
                            ? Icons.trending_up
                            : Icons.trending_flat,
                    size: 14,
                    color: textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Weight: ${tdee.weightTrend.formattedWeeklyRate}',
                    style: TextStyle(fontSize: 13, color: textSecondary),
                  ),
                ],
              ),
              // Metabolic adaptation warning
              if (tdee.hasAdaptation) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber,
                          size: 16, color: Color(0xFFFF9800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          tdee.metabolicAdaptation?.actionDescription ??
                              'Metabolic adaptation detected',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
