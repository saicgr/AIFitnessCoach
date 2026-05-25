import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/menu_item.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../widgets/glass_sheet.dart';

/// Reusable bottom sheet that explains what a health-related score means
/// when the user taps it on ANY surface — menu analysis card, food history
/// list, nutrition daily summary, chat meal card, etc. Keeping one widget
/// ensures the explanations stay consistent everywhere and can be updated
/// from a single source of truth.
///
/// Each entrypoint below (rating / inflammation / glycemicLoad / fodmap /
/// ultraProcessed) renders a different body. The shell — glass background,
/// title chip, gradient scale, bullet list — is shared.
enum ScoreKind {
  rating, // green / yellow / red health pill
  inflammation, // 0-10 scale + structured triggers
  glycemicLoad, // 0-40+ scale
  fodmap, // low / medium / high
  ultraProcessed, // bool NOVA Group 4 flag
  addedSugar, // grams per serving, vs WHO 25g/day adult limit
  health, // overall meal health score 1-10 with reason chips
}

class ScoreExplainSheet extends StatelessWidget {
  final ScoreKind kind;

  /// Raw value to highlight on the scale.
  /// - [ScoreKind.rating] expects `'green' | 'yellow' | 'red'`.
  /// - [ScoreKind.inflammation] expects `int 0–10`.
  /// - [ScoreKind.glycemicLoad] expects `int` (GL per serving).
  /// - [ScoreKind.fodmap] expects `'low' | 'medium' | 'high'`.
  /// - [ScoreKind.ultraProcessed] expects `bool`.
  final Object? value;

  /// Short context from the AI (e.g. the `rating_reason`, `fodmap_reason`,
  /// or `coach_tip`) so the user sees WHY this dish earned this score.
  /// Used by FODMAP + rating + ultraProcessed. For inflammation, prefer
  /// the structured [triggers] list — `reason` is ignored when [triggers]
  /// is non-empty because free-text goal-fit copy would mislead the user.
  final String? reason;

  /// Structured inflammation drivers (e.g. ['deep_fried', 'refined_flour']).
  /// When non-null + non-empty, rendered as chip-badges in the "why" box
  /// for [ScoreKind.inflammation]. Ignored for other kinds.
  final List<String>? triggers;

  const ScoreExplainSheet({
    super.key,
    required this.kind,
    this.value,
    this.reason,
    this.triggers,
  });

  /// Convenience launcher — every tap target across the app routes here.
  static Future<void> show(
    BuildContext context, {
    required ScoreKind kind,
    Object? value,
    String? reason,
    List<String>? triggers,
  }) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        maxHeightFraction: 0.78,
        child: ScoreExplainSheet(
          kind: kind, value: value, reason: reason, triggers: triggers,
        ),
      ),
    );
  }

  /// Convenience launcher for the meal-level Health Score X/10 explainer.
  /// Wraps [.show] with the right `kind` so callers at every Health pill
  /// site (Today card, logged-meals list, barcode confirm, food browser
  /// review card, etc.) can route taps with a single line.
  ///
  /// [reasons] are the `health_score_reasons` tags emitted by Gemini meal
  /// analysis, OR locally derived from per-meal signals via
  /// `healthReasonsFromSignals` for older logs.
  static Future<void> showHealth(
    BuildContext context, {
    int? score,
    required List<String> reasons,
  }) {
    return show(
      context,
      kind: ScoreKind.health,
      value: score,
      triggers: reasons,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final content = _content(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(content.icon, color: content.accent, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    content.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                if (content.currentLabel != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: content.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: content.accent.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Text(
                      content.currentLabel!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: content.accent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              content.subtitle,
              style: TextStyle(fontSize: 13, color: textSecondary, height: 1.35),
            ),
            // Inflammation has its own "Why" panel: a chip row of the
            // structured triggers Gemini emitted. These are the ingredients /
            // properties of THIS dish that pushed the score — which is the
            // question users are actually asking when they tap the pill.
            if ((kind == ScoreKind.inflammation || kind == ScoreKind.health) &&
                triggers != null &&
                triggers!.isNotEmpty) ...[
              const SizedBox(height: 14),
              _TriggersBox(triggers: triggers!, accent: content.accent),
            ]
            // Other kinds still use the free-text reason box (FODMAP
            // trigger ingredients, rating reason, etc.).
            else if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: content.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: content.accent.withValues(alpha: 0.2), width: 0.8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: content.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason!,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: textPrimary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            ...content.levels.map((lvl) => _LevelRow(
                  level: lvl,
                  active: content.activeIndex == content.levels.indexOf(lvl),
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                )),
            if (content.footer != null) ...[
              const SizedBox(height: 14),
              Text(
                content.footer!,
                style: TextStyle(fontSize: 11, color: textSecondary, fontStyle: FontStyle.italic, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _SheetContent _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (kind) {
      case ScoreKind.rating:
        final r = value as String?;
        final idx = switch (r) {
          'green' => 0,
          'yellow' => 1,
          'red' => 2,
          _ => -1,
        };
        return _SheetContent(
          icon: Icons.verified_rounded,
          title: l10n.scoreExplainHowThisDishRates,
          subtitle: l10n.scoreExplainAiPicksATrafficLight,
          accent: switch (r) {
            'green' => AppColors.success,
            'yellow' => AppColors.orange,
            'red' => AppColors.error,
            _ => AppColors.orange,
          },
          currentLabel: switch (r) {
            'green' => l10n.scoreExplainCurrentLabelGood,
            'yellow' => l10n.scoreExplainCurrentLabelModerate,
            'red' => l10n.scoreExplainCurrentLabelSkip,
            _ => null,
          },
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplainGood,
              body: l10n.scoreExplainHitsYourGoalMacros,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplainModerate,
              body: l10n.scoreExplainReasonableChoiceWithA,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplainSkip,
              body: l10n.scoreExplainHighInflammationUltraProce,
            ),
          ],
          footer: l10n.scoreExplainRatingsArePersonalised,
        );

      case ScoreKind.inflammation:
        final v = (value is int) ? value as int : int.tryParse('$value') ?? -1;
        final idx = v < 0
            ? -1
            : v <= 3
                ? 0
                : v <= 6
                    ? 1
                    : 2;
        return _SheetContent(
          icon: Icons.local_fire_department_rounded,
          title: l10n.scoreExplainInflammationScoreValue(v),
          subtitle: l10n.scoreExplainChronicLowGradeInflammation,
          accent: v >= 7
              ? AppColors.error
              : v >= 4
                  ? AppColors.orange
                  : AppColors.success,
          currentLabel: v < 0
              ? null
              : v <= 3
                  ? l10n.scoreExplainCurrentLabelAntiInfl
                  : v <= 6
                      ? l10n.scoreExplainCurrentLabelMild
                      : l10n.scoreExplainCurrentLabelHigh,
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplain03AntiInflammatory,
              body: l10n.scoreExplainLeafyGreensBerriesWild,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplain46NeutralMild,
              body: l10n.scoreExplainWhiteRicePlainEggs,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplain710HighlyInflammatory,
              body: l10n.scoreExplainFriedFoodsProcessedMeats,
            ),
          ],
          footer: l10n.scoreExplainAimForADailyAverage,
        );

      case ScoreKind.glycemicLoad:
        final v = (value is int) ? value as int : int.tryParse('$value') ?? -1;
        final idx = v < 0
            ? -1
            : v < 10
                ? 0
                : v < 20
                    ? 1
                    : 2;
        return _SheetContent(
          icon: Icons.show_chart_rounded,
          title: l10n.scoreExplainGlycemicLoadValue(v),
          subtitle: l10n.scoreExplainGlycemicLoadCombines,
          accent: v >= 20
              ? AppColors.error
              : v >= 10
                  ? AppColors.orange
                  : AppColors.success,
          currentLabel: v < 0
              ? null
              : v < 10
                  ? l10n.scoreExplainCurrentLabelLow
                  : v < 20
                      ? l10n.scoreExplainCurrentLabelMedium
                      : l10n.scoreExplainCurrentLabelHigh,
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplainLowUnder10,
              body: l10n.scoreExplainMinimalBloodSugarSpike,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplainMedium1019,
              body: l10n.scoreExplainModerateSpikeOatsWhole,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplainHigh20,
              body: l10n.scoreExplainSteepSpikeCrashWhite,
            ),
          ],
          footer: l10n.scoreExplainImportantIfYouHaveDiabetes,
        );

      case ScoreKind.fodmap:
        final r = value as String?;
        final idx = switch (r) {
          'low' => 0,
          'medium' => 1,
          'high' => 2,
          _ => -1,
        };
        return _SheetContent(
          icon: Icons.health_and_safety_rounded,
          title: l10n.scoreExplainFodmapRating,
          subtitle: l10n.scoreExplainFodmapsAreShortChain,
          accent: switch (r) {
            'low' => AppColors.success,
            'medium' => AppColors.orange,
            'high' => AppColors.error,
            _ => AppColors.orange,
          },
          currentLabel: switch (r) {
            'low' => l10n.scoreExplainCurrentLabelLow,
            'medium' => l10n.scoreExplainCurrentLabelMedium,
            'high' => l10n.scoreExplainCurrentLabelHigh,
            _ => null,
          },
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplainLow,
              body: l10n.scoreExplainMeatEggsRiceOats,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplainMedium,
              body: l10n.scoreExplainCertainPortionsOfAvocado,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplainHigh,
              body: l10n.scoreExplainOnionGarlicWheatRye,
            ),
          ],
          footer: l10n.scoreExplainOnlyRelevantIfYouHaveIbs,
        );

      case ScoreKind.ultraProcessed:
        final v = value as bool?;
        return _SheetContent(
          icon: Icons.science_rounded,
          title: v == true ? l10n.scoreExplainUltraProcessed : l10n.scoreExplainWholeMinimallyProcessed,
          subtitle: l10n.scoreExplainWeUseTheNovaClassification,
          accent: v == true ? AppColors.error : AppColors.success,
          currentLabel: v == true ? l10n.scoreExplainCurrentLabelNova4 : l10n.scoreExplainCurrentLabelWhole,
          activeIndex: v == true ? 1 : 0,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplainWholeMinimallyProcessed,
              body: l10n.scoreExplainRawOrBasicCooked,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplainUltraProcessedNova4,
              body: l10n.scoreExplainEngineeredFoodProductsChip,
            ),
          ],
          footer: l10n.scoreExplainLargePopulationStudies,
        );

      case ScoreKind.addedSugar:
        // Added sugar in grams per serving. Anchored to WHO's adult daily
        // limit of 25 g — anything above 15 g in a single dish is "most of
        // your day's budget in one sitting" territory.
        final g = (value is num) ? (value as num).toDouble() : double.tryParse('$value') ?? -1;
        final idx = g < 0
            ? -1
            : g < 5
                ? 0
                : g < 15
                    ? 1
                    : 2;
        final pctDay = g < 0 ? null : ((g / 25.0) * 100).round();
        final footerText = pctDay == null
            ? l10n.scoreExplainWhoRecommendsAdults
            : l10n.scoreExplainThatIsAboutPctDay(pctDay);
        return _SheetContent(
          icon: Icons.icecream_rounded,
          title: g < 0 ? l10n.scoreExplainAddedSugar : l10n.scoreExplainAddedSugarValue(_fmtGrams(g)),
          subtitle: l10n.scoreExplainAddedSugarIsThe,
          accent: g >= 15
              ? AppColors.error
              : g >= 5
                  ? AppColors.orange
                  : AppColors.success,
          currentLabel: g < 0
              ? null
              : g < 5
                  ? l10n.scoreExplainCurrentLabelLow
                  : g < 15
                      ? l10n.scoreExplainCurrentLabelModerate
                      : l10n.scoreExplainCurrentLabelHigh,
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplainLowUnder5G,
              body: l10n.scoreExplainMostSavouryDishesPlain,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplainModerate514G,
              body: l10n.scoreExplainSweetenedYogurtASmall,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplainHigh15G,
              body: l10n.scoreExplainDessertsSugaryDrinksCandy,
            ),
          ],
          footer: footerText,
        );

      case ScoreKind.health:
        // Overall meal health score 1-10. Triggers carry the
        // `health_score_reasons` tags (high_protein, ultra_processed, …)
        // which the shared _TriggersBox renders coloured by polarity.
        final v = (value is int) ? value as int : int.tryParse('$value') ?? -1;
        // 3-tier scheme aligned with the legend bands below:
        // index 0 = 7-10 GOOD, index 1 = 4-6 AVERAGE, index 2 = 1-3 POOR.
        final idx = v < 0
            ? -1
            : v >= 7
                ? 0
                : v >= 4
                    ? 1
                    : 2;
        final hasReasons = triggers != null && triggers!.isNotEmpty;
        final onlyUnavailable =
            hasReasons && triggers!.length == 1 && triggers!.first == 'ai_unavailable';
        return _SheetContent(
          icon: Icons.favorite_rounded,
          title: v < 0 ? l10n.scoreExplainHealthScore : l10n.scoreExplainHealthScoreValue(v),
          subtitle: onlyUnavailable
              ? l10n.scoreExplainScoreDetailUnavailable
              : l10n.scoreExplainEachMealGets,
          // 3-tier scheme matching the legend bands: >=7 GOOD (green),
          // >=4 AVERAGE (orange), else POOR (error). Keeping the badge
          // colour and the highlighted legend band in lock-step.
          accent: v >= 7
              ? AppColors.success
              : v >= 4
                  ? AppColors.orange
                  : AppColors.error,
          currentLabel: v < 0
              ? null
              : v >= 7
                  ? l10n.scoreExplainCurrentLabelGood
                  : v >= 4
                      ? l10n.scoreExplainCurrentLabelAverage
                      : l10n.scoreExplainCurrentLabelPoor,
          activeIndex: idx,
          levels: [
            _Level(
              color: AppColors.success,
              label: l10n.scoreExplain710GoodExcellent,
              body: l10n.scoreExplainHighProteinOrFiber,
            ),
            _Level(
              color: AppColors.orange,
              label: l10n.scoreExplain46Average,
              body: l10n.scoreExplainReasonableChoiceCouldBe,
            ),
            _Level(
              color: AppColors.error,
              label: l10n.scoreExplain13Poor,
              body: l10n.scoreExplainUltraProcessedDeepFried,
            ),
          ],
          footer: l10n.scoreExplainDailyAverageAbove6,
        );
    }
  }
}

String _fmtGrams(double g) {
  // Integer display when the value is effectively a whole number so
  // "24 g" reads cleanly in the chip; preserve one decimal otherwise.
  if ((g - g.roundToDouble()).abs() < 0.05) return '${g.round()} g';
  return '${g.toStringAsFixed(1)} g';
}

/// Compact row of chip-badges used inside the inflammation panel. Each
/// chip shows the human label of one trigger; positive drivers (omega-3,
/// leafy greens, etc.) render green so the user can tell which ingredients
/// are helping vs hurting without reading copy.
class _TriggersBox extends StatelessWidget {
  final List<String> triggers;
  final Color accent;
  const _TriggersBox({required this.triggers, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 14, color: accent),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context).scoreExplainWhyThisScore,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final tag in triggers)
                _TriggerChip(
                  label: InflammationTriggers.label(tag),
                  positive: InflammationTriggers.isPositive(tag),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TriggerChip extends StatelessWidget {
  final String label;
  final bool positive;
  const _TriggerChip({required this.label, required this.positive});

  @override
  Widget build(BuildContext context) {
    // Anti-inflammatory drivers render green; inflammatory drivers render
    // red. User can tell at a glance which ingredients pulled the score up
    // vs pushed it down without reading additional copy.
    final bg = positive
        ? AppColors.success.withValues(alpha: 0.15)
        : AppColors.error.withValues(alpha: 0.12);
    final fg = positive ? AppColors.success : AppColors.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positive ? Icons.arrow_downward : Icons.arrow_upward,
            size: 10,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetContent {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final String? currentLabel;
  final int activeIndex;
  final List<_Level> levels;
  final String? footer;
  const _SheetContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.currentLabel,
    required this.activeIndex,
    required this.levels,
    this.footer,
  });
}

class _Level {
  final Color color;
  final String label;
  final String body;
  const _Level({required this.color, required this.label, required this.body});
}

class _LevelRow extends StatelessWidget {
  final _Level level;
  final bool active;
  final Color textPrimary;
  final Color textSecondary;
  const _LevelRow({
    required this.level,
    required this.active,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? level.color.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? level.color.withValues(alpha: 0.4) : level.color.withValues(alpha: 0.15),
          width: active ? 1.2 : 0.6,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: level.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: active ? level.color : textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  level.body,
                  style: TextStyle(
                    fontSize: 11,
                    color: textSecondary,
                    height: 1.35,
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
