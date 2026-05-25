import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/repositories/refuel_repository.dart';
import '../../screens/pillar/widgets/ask_coach_button.dart';

import '../../l10n/generated/app_localizations.dart';
/// Card that shows post-cardio refuel guidance (water / carbs / protein
/// targets + a one-line rationale + a "Log meal" CTA + an Ask-Coach button).
///
/// Behaviour:
///   - Backend returns 204 → renders nothing (SizedBox.shrink).
///   - Error / loading → renders nothing (silent).
///   - On success → renders a rounded card matching the pillar-detail card
///     visual (20px radius, elevated surface, 1px border).
///
/// The wiring of this widget into `synced_workout_detail_screen.dart` is
/// owned by a later wave — but any screen can import + drop it in given a
/// cardio log id.
class RefuelWindowCard extends ConsumerWidget {
  final String cardioLogId;
  const RefuelWindowCard({super.key, required this.cardioLogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(refuelPrescriptionProvider(cardioLogId));
    return async.when(
      data: (rx) {
        if (rx == null) return const SizedBox.shrink();
        return _RefuelCard(prescription: rx, cardioLogId: cardioLogId);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _RefuelCard extends StatelessWidget {
  final RefuelPrescription prescription;
  final String cardioLogId;
  const _RefuelCard({required this.prescription, required this.cardioLogId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ----- Header -----
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(context).refuelWindowCardRecoveryWindow,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              AskCoachButton(
                contextLabel: 'Recovery after cardio',
                statSnapshot: {
                  'source': 'refuel',
                  'cardio_log_id': cardioLogId,
                  'water_ml': prescription.waterMl,
                  'carbs_g': prescription.carbsG,
                  'protein_g': prescription.proteinG,
                  'window_minutes': prescription.windowMinutes,
                  'rationale': prescription.rationale,
                },
                semanticLabel: AppLocalizations.of(context).refuelWindowCardAskCoachAboutRecovery,
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ----- Rationale -----
          Text(
            prescription.rationale,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          // ----- Macros grid (3 cells) -----
          Row(
            children: [
              Expanded(
                child: _MacroCell(
                  label: AppLocalizations.of(context).unifiedHomeWidgetsWater,
                  value: '${prescription.waterMl}',
                  unit: 'ml',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCell(
                  label: AppLocalizations.of(context).weeklyCheckinSheetCarbs,
                  value: '${prescription.carbsG}',
                  unit: 'g',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  accent: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MacroCell(
                  label: AppLocalizations.of(context).weeklyCheckinSheetProtein,
                  value: '${prescription.proteinG}',
                  unit: 'g',
                  isDark: isDark,
                  textPrimary: textPrimary,
                  textMuted: textMuted,
                  accent: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // ----- CTA row -----
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                // Deep-link into the food-logging flow. Caller (whichever
                // screen embeds this card) controls onward navigation; if
                // the route doesn't exist for this user's nav stack, the
                // go_router will surface its own 404.
                GoRouter.of(context).push('/nutrition/log');
              },
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: accent,
              ),
              icon: const Icon(Icons.restaurant_outlined, size: 16),
              label: Text(
                AppLocalizations.of(context).refuelWindowCardLogMeal,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final Color accent;

  const _MacroCell({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
