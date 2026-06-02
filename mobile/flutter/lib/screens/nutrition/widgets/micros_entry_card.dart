import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/micronutrients.dart';
import '../../../data/services/haptic_service.dart';

/// F5 — collapsible "Vitamins & minerals" entry point on the Nutrition Daily
/// tab.
///
/// Collapsed: a single tappable row (icon + label + chevron). Expanded: a peek
/// of up to 4 pinned nutrients (mini RDA bars) + a "View all nutrients" button
/// that pushes the full [MicrosDetailScreen] (`/nutrition/micros`).
///
/// Empty/insufficient handling: when no nutrient has any logged value yet, the
/// peek shows an honest "Log a meal to see your vitamins & minerals" line
/// rather than a wall of zero bars (never imply a deficiency from no data).
class MicrosEntryCard extends StatefulWidget {
  final DailyMicronutrientSummary? micronutrients;
  final bool isDark;

  const MicrosEntryCard({
    super.key,
    required this.micronutrients,
    required this.isDark,
  });

  @override
  State<MicrosEntryCard> createState() => _MicrosEntryCardState();
}

class _MicrosEntryCardState extends State<MicrosEntryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final summary = widget.micronutrients;
    // Prefer the backend-pinned nutrients; fall back to the first few across
    // categories so the peek always has something representative.
    final peek = <NutrientProgress>[
      ...?summary?.pinned,
      if (summary != null && (summary.pinned.isEmpty))
        ...summary.allNutrients,
    ].take(4).toList();
    // "Has data" = at least one nutrient with a real current value. Used to
    // avoid showing a wall of zero bars before anything is logged.
    final hasData = peek.any((n) => n.currentValue > 0);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          // Header row — always tappable to expand/collapse.
          Semantics(
            button: true,
            label: 'Vitamins and minerals',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  HapticService.selection();
                  setState(() => _expanded = !_expanded);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.science_outlined,
                            size: 18, color: accent),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vitamins & minerals',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            Text(
                              'Track 30+ nutrients vs your daily targets',
                              style: TextStyle(
                                  fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!hasData)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Log a meal to see your vitamins & minerals.',
                        style: TextStyle(fontSize: 13, color: textSecondary),
                      ),
                    )
                  else
                    ...peek.map((n) => _MiniNutrientBar(
                          nutrient: n,
                          isDark: isDark,
                        )),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        HapticService.light();
                        context.push('/nutrition/micros');
                      },
                      icon: const Icon(Icons.open_in_full_rounded, size: 16),
                      label: const Text('View all nutrients'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: accent,
                        side: BorderSide(color: accent.withValues(alpha: 0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
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

class _MiniNutrientBar extends StatelessWidget {
  final NutrientProgress nutrient;
  final bool isDark;

  const _MiniNutrientBar({required this.nutrient, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final color = _parseHex(nutrient.progressColor) ??
        (isDark ? AppColors.teal : AppColorsLight.teal);
    // Insufficient data → render "—" rather than an implied-deficiency 0 bar.
    final hasValue = nutrient.currentValue > 0;
    final pct = nutrient.targetValue > 0
        ? (nutrient.currentValue / nutrient.targetValue).clamp(0.0, 1.0)
        : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nutrient.displayName,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textPrimary),
                ),
              ),
              Text(
                hasValue
                    ? '${nutrient.formattedCurrent} / ${nutrient.formattedTarget} ${nutrient.unit}'
                    : '— / ${nutrient.formattedTarget} ${nutrient.unit}',
                style: TextStyle(fontSize: 11, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: hasValue ? pct : 0,
              minHeight: 5,
              backgroundColor:
                  (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseHex(String? hex) {
    if (hex == null) return null;
    var h = hex.replaceAll('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }
}
