import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/services/api_client.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../utils/tz.dart';
import 'tracker_detail_screen.dart';

/// One day's tracker totals (for the detail-screen history chart).
class TrackerDay {
  final String date;
  final double sugarG;
  final double caffeineMg;
  final double alcoholUnits;
  const TrackerDay(this.date, this.sugarG, this.caffeineMg, this.alcoholUnits);

  factory TrackerDay.fromJson(Map<String, dynamic> j) => TrackerDay(
        j['date'] as String? ?? '',
        (j['sugar_g'] as num?)?.toDouble() ?? 0,
        (j['caffeine_mg'] as num?)?.toDouble() ?? 0,
        (j['alcohol_units'] as num?)?.toDouble() ?? 0,
      );
}

/// Gap 7 — today's sugar / caffeine / alcohol totals + per-tracker limits and
/// on/off flags. Plain model (no codegen) parsed from
/// GET /nutrition/optional-trackers/{user_id}.
class OptionalTrackers {
  final bool sugarEnabled;
  final bool caffeineEnabled;
  final bool alcoholEnabled;
  final double sugarG;
  final double caffeineMg;
  final double alcoholUnits;
  final int sugarLimitG;
  final int caffeineLimitMg;
  final int alcoholLimitUnits;
  final List<TrackerDay> series;

  const OptionalTrackers({
    this.sugarEnabled = false,
    this.caffeineEnabled = false,
    this.alcoholEnabled = false,
    this.sugarG = 0,
    this.caffeineMg = 0,
    this.alcoholUnits = 0,
    this.sugarLimitG = 36,
    this.caffeineLimitMg = 400,
    this.alcoholLimitUnits = 2,
    this.series = const [],
  });

  bool get anyEnabled => sugarEnabled || caffeineEnabled || alcoholEnabled;

  factory OptionalTrackers.fromJson(Map<String, dynamic> j) => OptionalTrackers(
        sugarEnabled: j['sugar_tracking_enabled'] as bool? ?? false,
        caffeineEnabled: j['caffeine_tracking_enabled'] as bool? ?? false,
        alcoholEnabled: j['alcohol_tracking_enabled'] as bool? ?? false,
        sugarG: (j['sugar_g'] as num?)?.toDouble() ?? 0,
        caffeineMg: (j['caffeine_mg'] as num?)?.toDouble() ?? 0,
        alcoholUnits: (j['alcohol_units'] as num?)?.toDouble() ?? 0,
        sugarLimitG: (j['sugar_limit_g'] as num?)?.toInt() ?? 36,
        caffeineLimitMg: (j['caffeine_limit_mg'] as num?)?.toInt() ?? 400,
        alcoholLimitUnits: (j['alcohol_limit_units'] as num?)?.toInt() ?? 2,
        series: ((j['series'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => TrackerDay.fromJson(Map<String, dynamic>.from(m)))
            .toList(),
      );
}

/// Fetches today's optional-tracker totals. Keyed by userId; cheap (one row
/// query server-side). autoDispose so it re-fetches when the strip remounts.
final optionalTrackersProvider =
    FutureProvider.autoDispose.family<OptionalTrackers, String>((ref, userId) async {
  if (userId.isEmpty) return const OptionalTrackers();
  // Re-fetch whenever the day's logged-meal count changes (a new food log may
  // add sugar/caffeine/alcohol), so the counters stay live without manual
  // invalidation from the log paths.
  ref.watch(dailyNutritionProvider(todayNutritionKey()).select((s) => s.summary?.meals.length ?? 0));
  final client = ref.watch(apiClientProvider);
  final resp = await client.get(
    '/nutrition/optional-trackers/$userId',
    queryParameters: {'date': Tz.localDate()},
  );
  return OptionalTrackers.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

/// Detail-screen fetch — today's totals + a trailing 7-day `series`. Keyed by
/// userId; re-fetches when the day's meal count changes.
final trackerHistoryProvider =
    FutureProvider.autoDispose.family<OptionalTrackers, String>((ref, userId) async {
  if (userId.isEmpty) return const OptionalTrackers();
  ref.watch(dailyNutritionProvider(todayNutritionKey()).select((s) => s.summary?.meals.length ?? 0));
  final client = ref.watch(apiClientProvider);
  final resp = await client.get(
    '/nutrition/optional-trackers/$userId',
    queryParameters: {'date': Tz.localDate(), 'days': 7},
  );
  return OptionalTrackers.fromJson(Map<String, dynamic>.from(resp.data as Map));
});

/// Identifies which tracker a detail screen / card represents.
enum TrackerKind { sugar, caffeine, alcohol }

/// A horizontal set of opt-in tracker cards (sugar / caffeine / alcohol),
/// rendered only for the trackers the user enabled in Nutrition Settings. Each
/// card shows today's total vs the user's limit and flips to an over-limit
/// state (the inline nudge) when crossed.
class OptionalTrackersStrip extends ConsumerWidget {
  final String userId;
  final bool isDark;

  const OptionalTrackersStrip({
    super.key,
    required this.userId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(optionalTrackersProvider(userId));
    return async.maybeWhen(
      data: (t) {
        if (!t.anyEnabled) return const SizedBox.shrink();
        void openDetail(TrackerKind kind) {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => TrackerDetailScreen(
              userId: userId,
              kind: kind,
              isDark: isDark,
            ),
          ));
        }

        final cards = <Widget>[
          if (t.sugarEnabled)
            _TrackerCard(
              isDark: isDark,
              icon: Icons.cookie_rounded,
              color: AppColors.pink,
              label: 'Added sugar',
              value: t.sugarG,
              limit: t.sugarLimitG.toDouble(),
              unit: 'g',
              onTap: () => openDetail(TrackerKind.sugar),
            ),
          if (t.caffeineEnabled)
            _TrackerCard(
              isDark: isDark,
              icon: Icons.coffee_rounded,
              color: AppColors.orange,
              label: 'Caffeine',
              value: t.caffeineMg,
              limit: t.caffeineLimitMg.toDouble(),
              unit: 'mg',
              onTap: () => openDetail(TrackerKind.caffeine),
            ),
          if (t.alcoholEnabled)
            _TrackerCard(
              isDark: isDark,
              icon: Icons.local_bar_rounded,
              color: AppColors.purple,
              label: 'Alcohol',
              value: t.alcoholUnits,
              limit: t.alcoholLimitUnits.toDouble(),
              unit: t.alcoholUnits == 1 ? 'drink' : 'drinks',
              onTap: () => openDetail(TrackerKind.alcohol),
            ),
        ];
        if (cards.isEmpty) return const SizedBox.shrink();
        // Wrap so 1-3 cards adapt cleanly SE→iPad without overflow.
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Wrap(spacing: 10, runSpacing: 10, children: cards),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _TrackerCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color color;
  final String label;
  final double value;
  final double limit;
  final String unit;
  final VoidCallback? onTap;

  const _TrackerCard({
    required this.isDark,
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.limit,
    required this.unit,
    this.onTap,
  });

  // Gap 7 — varied, human over-limit copy (never robotic; ≥4 variants).
  String _overLimitNudge() {
    final over = (value - limit);
    final overStr = over >= 10 ? over.round().toString() : over.toStringAsFixed(1);
    final variants = <String>[
      'Over by $overStr$unit today',
      "Past your $label limit",
      'A bit over — $overStr$unit above goal',
      'Above your daily cap',
    ];
    // Deterministic pick (no Math.random in hot UI): vary by the integer value.
    return variants[value.round() % variants.length];
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final over = limit > 0 && value > limit;
    final pct = limit > 0 ? (value / limit).clamp(0.0, 1.0) : 0.0;
    final accent = over ? AppColors.coral : color;
    final valueStr =
        value >= 100 ? value.round().toString() : value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: over
              ? AppColors.coral.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 16, color: textMuted),
            ],
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '$valueStr$unit',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                TextSpan(
                  text: '  / ${limit.round()}$unit',
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 5,
              backgroundColor: textMuted.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (over) ...[
            const SizedBox(height: 6),
            Text(
              _overLimitNudge(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.coral,
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
