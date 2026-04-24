import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
  inflammation, // 0-10 scale
  glycemicLoad, // 0-40+ scale
  fodmap, // low / medium / high
  ultraProcessed, // bool NOVA Group 4 flag
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
  final String? reason;

  const ScoreExplainSheet({
    super.key,
    required this.kind,
    this.value,
    this.reason,
  });

  /// Convenience launcher — every tap target across the app routes here.
  static Future<void> show(
    BuildContext context, {
    required ScoreKind kind,
    Object? value,
    String? reason,
  }) {
    return showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        maxHeightFraction: 0.78,
        child: ScoreExplainSheet(kind: kind, value: value, reason: reason),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    final content = _content();

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
            if (reason != null && reason!.isNotEmpty) ...[
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

  _SheetContent _content() {
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
          title: 'How this dish rates for you',
          subtitle:
              "AI picks a traffic-light rating based on your goals (cutting, bulking, balanced) — then checks macros, "
              "processing level, and inflammation to place each dish on the scale.",
          accent: switch (r) {
            'green' => AppColors.success,
            'yellow' => AppColors.orange,
            'red' => AppColors.error,
            _ => AppColors.orange,
          },
          currentLabel: switch (r) {
            'green' => 'GOOD',
            'yellow' => 'MODERATE',
            'red' => 'SKIP',
            _ => null,
          },
          activeIndex: idx,
          levels: const [
            _Level(
              color: AppColors.success,
              label: 'Good',
              body: 'Hits your goal macros, mostly whole foods, low-to-moderate inflammation. Pick freely.',
            ),
            _Level(
              color: AppColors.orange,
              label: 'Moderate',
              body: "Reasonable choice with a trade-off — watch portion or pair with a cleaner side.",
            ),
            _Level(
              color: AppColors.error,
              label: 'Skip',
              body: 'High inflammation, ultra-processed, or way off your macros. Swap to a Good option if possible.',
            ),
          ],
          footer: 'Ratings are personalised — the same dish can be Good for one goal and Skip for another.',
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
          title: 'Inflammation score: $v / 10',
          subtitle:
              "Chronic low-grade inflammation is linked to joint pain, fatigue, acne, and worse recovery. "
              "We rank every dish on a 0–10 scale using the foods it contains.",
          accent: v >= 7
              ? AppColors.error
              : v >= 4
                  ? AppColors.orange
                  : AppColors.success,
          currentLabel: v < 0
              ? null
              : v <= 3
                  ? 'ANTI-INFL.'
                  : v <= 6
                      ? 'MILD'
                      : 'HIGH',
          activeIndex: idx,
          levels: const [
            _Level(
              color: AppColors.success,
              label: '0 – 3  Anti-inflammatory',
              body: 'Leafy greens, berries, wild salmon, turmeric, extra-virgin olive oil, nuts, legumes.',
            ),
            _Level(
              color: AppColors.orange,
              label: '4 – 6  Neutral / mild',
              body: 'White rice, plain eggs, hard cheese, lean red meat in small portions.',
            ),
            _Level(
              color: AppColors.error,
              label: '7 – 10  Highly inflammatory',
              body: 'Fried foods, processed meats, sugary drinks, refined seed oils, packaged snacks.',
            ),
          ],
          footer: 'Aim for a daily average under 5 if you care about recovery or skin.',
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
          title: 'Glycemic load: $v',
          subtitle:
              "Glycemic Load combines how fast a food raises blood sugar (GI) with how much of it you're actually eating. "
              "More useful than GI alone — it reflects real portions.",
          accent: v >= 20
              ? AppColors.error
              : v >= 10
                  ? AppColors.orange
                  : AppColors.success,
          currentLabel: v < 0
              ? null
              : v < 10
                  ? 'LOW'
                  : v < 20
                      ? 'MEDIUM'
                      : 'HIGH',
          activeIndex: idx,
          levels: const [
            _Level(
              color: AppColors.success,
              label: 'Low  (under 10)',
              body: 'Minimal blood-sugar spike. Non-starchy vegetables, eggs, meat, berries, most dairy.',
            ),
            _Level(
              color: AppColors.orange,
              label: 'Medium  (10 – 19)',
              body: 'Moderate spike. Oats, whole-wheat bread, banana, sweet potato, basmati rice.',
            ),
            _Level(
              color: AppColors.error,
              label: 'High  (20+)',
              body: 'Steep spike + crash. White rice bowls, sugary drinks, pastries, large pasta plates.',
            ),
          ],
          footer:
              'Important if you have diabetes or pre-diabetes, or if you want steady energy. Pairing with protein + fibre blunts the spike.',
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
          title: 'FODMAP rating',
          subtitle:
              "FODMAPs are short-chain carbs that can trigger bloating, gas, and IBS flare-ups. The low-FODMAP approach "
              "(Monash University) groups foods into three tiers.",
          accent: switch (r) {
            'low' => AppColors.success,
            'medium' => AppColors.orange,
            'high' => AppColors.error,
            _ => AppColors.orange,
          },
          currentLabel: switch (r) {
            'low' => 'LOW',
            'medium' => 'MEDIUM',
            'high' => 'HIGH',
            _ => null,
          },
          activeIndex: idx,
          levels: const [
            _Level(
              color: AppColors.success,
              label: 'Low',
              body: 'Meat, eggs, rice, oats, lactose-free dairy, carrots, zucchini, spinach, berries, oranges.',
            ),
            _Level(
              color: AppColors.orange,
              label: 'Medium',
              body: 'Certain portions of avocado, sweet potato, almonds — OK in small servings, rough in large.',
            ),
            _Level(
              color: AppColors.error,
              label: 'High',
              body: 'Onion, garlic, wheat, rye, milk/ice cream, apples, pears, honey, beans, cauliflower.',
            ),
          ],
          footer:
              'Only relevant if you have IBS or known FODMAP sensitivity. If your gut is happy, ignore this rating.',
        );

      case ScoreKind.ultraProcessed:
        final v = value as bool?;
        return _SheetContent(
          icon: Icons.science_rounded,
          title: v == true ? 'Ultra-processed' : 'Whole / minimally processed',
          subtitle:
              "We use the NOVA classification — Group 4 = ultra-processed (industrial recipes with emulsifiers, "
              "hydrogenated oils, artificial sweeteners, HFCS, protein isolates, modified starches).",
          accent: v == true ? AppColors.error : AppColors.success,
          currentLabel: v == true ? 'NOVA 4' : 'WHOLE',
          activeIndex: v == true ? 1 : 0,
          levels: const [
            _Level(
              color: AppColors.success,
              label: 'Whole / minimally processed',
              body: 'Raw or basic-cooked foods: meat, eggs, vegetables, plain yoghurt, cheese, whole grains.',
            ),
            _Level(
              color: AppColors.error,
              label: 'Ultra-processed (NOVA 4)',
              body: 'Engineered food products: chips, sodas, instant noodles, packaged sweets, most fast food.',
            ),
          ],
          footer: 'Large population studies link >30% daily calories from NOVA 4 to worse cardiometabolic health.',
        );
    }
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
