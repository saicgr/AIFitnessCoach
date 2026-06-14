import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import 'package:fitwiz/widgets/design_system/zealova.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../widgets/glass_sheet.dart';
import 'optional_trackers_strip.dart';

/// Gap 7 — per-tracker detail screen (sugar / caffeine / alcohol). Shows
/// today's total vs the user's limit, an editable limit, and a 7-day history
/// bar chart. Reached by tapping a tracker card on the Nutrition → Daily tab.
class TrackerDetailScreen extends ConsumerWidget {
  final String userId;
  final TrackerKind kind;
  final bool isDark;

  const TrackerDetailScreen({
    super.key,
    required this.userId,
    required this.kind,
    required this.isDark,
  });

  ({String label, String unit, Color color, IconData icon}) get _meta {
    switch (kind) {
      case TrackerKind.sugar:
        return (label: 'Added sugar', unit: 'g', color: AppColors.pink, icon: Icons.cookie_rounded);
      case TrackerKind.caffeine:
        return (label: 'Caffeine', unit: 'mg', color: AppColors.orange, icon: Icons.coffee_rounded);
      case TrackerKind.alcohol:
        return (label: 'Alcohol', unit: 'drinks', color: AppColors.purple, icon: Icons.local_bar_rounded);
    }
  }

  double _todayValue(OptionalTrackers t) => switch (kind) {
        TrackerKind.sugar => t.sugarG,
        TrackerKind.caffeine => t.caffeineMg,
        TrackerKind.alcohol => t.alcoholUnits,
      };

  int _limit(OptionalTrackers t) => switch (kind) {
        TrackerKind.sugar => t.sugarLimitG,
        TrackerKind.caffeine => t.caffeineLimitMg,
        TrackerKind.alcohol => t.alcoholLimitUnits,
      };

  double _dayValue(TrackerDay d) => switch (kind) {
        TrackerKind.sugar => d.sugarG,
        TrackerKind.caffeine => d.caffeineMg,
        TrackerKind.alcohol => d.alcoholUnits,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final m = _meta;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bg = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final async = ref.watch(trackerHistoryProvider(userId));

    return Scaffold(
      backgroundColor: bg,
      appBar: ZealovaAppBar(
        kicker: 'TRACKER',
        title: m.label,
        titleSize: 24,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(m.icon, color: m.color, size: 22),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Could not load tracker data',
              style: TextStyle(color: textMuted)),
        ),
        data: (t) {
          final value = _todayValue(t);
          final limit = _limit(t).toDouble();
          final over = limit > 0 && value > limit;
          final pct = limit > 0 ? (value / limit).clamp(0.0, 1.0) : 0.0;
          final accent = over ? AppColors.coral : m.color;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Today's hero number + ring.
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 140,
                            child: CircularProgressIndicator(
                              value: pct,
                              strokeWidth: 11,
                              backgroundColor: textMuted.withValues(alpha: 0.15),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1),
                                style: ZType.disp(36, color: accent),
                              ),
                              Text(m.unit.toUpperCase(),
                                  style: ZType.lbl(10,
                                      color: textMuted, letterSpacing: 1.3)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('TODAY',
                        style: ZType.lbl(11,
                            color: textMuted, letterSpacing: 2)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Editable daily limit row.
              _LimitRow(
                isDark: isDark,
                label: 'Daily limit',
                valueText: '${_limit(t)} ${m.unit}',
                accent: m.color,
                onEdit: () => _editLimit(context, ref, t),
              ),
              const SizedBox(height: 12),

              if (over)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.coral),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "You're ${(value - limit) % 1 == 0 ? (value - limit).toInt() : (value - limit).toStringAsFixed(1)} ${m.unit} over your daily limit.",
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.coral),
                        ),
                      ),
                    ],
                  ),
                ),
              if (over) const SizedBox(height: 20),

              // 7-day history.
              const ZealovaSectionKicker('Last 7 days'),
              const SizedBox(height: 16),
              _HistoryChart(
                series: t.series,
                limit: limit,
                color: m.color,
                isDark: isDark,
                valueOf: _dayValue,
              ),
              const SizedBox(height: 24),
              Text(
                'This counter sums what we already read from your food logs — turning it off just hides the card, your meals still log normally.',
                style: TextStyle(fontSize: 12.5, height: 1.4, color: textMuted),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _editLimit(
      BuildContext context, WidgetRef ref, OptionalTrackers t) async {
    final controller = TextEditingController(text: _limit(t).toString());
    final m = _meta;
    final newLimit = await showGlassSheet<int>(
      context: context,
      builder: (ctx) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
              24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Set ${m.label.toLowerCase()} limit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Daily limit',
                  suffixText: m.unit,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: m.color,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final v = int.tryParse(controller.text.trim());
                    if (v != null && v > 0 && v <= 100000) Navigator.pop(ctx, v);
                  },
                  child: const Text('Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (newLimit == null) return;

    final prefs = ref.read(nutritionPreferencesProvider).preferences;
    if (prefs == null) return;
    final updated = switch (kind) {
      TrackerKind.sugar => prefs.copyWith(sugarLimitG: newLimit),
      TrackerKind.caffeine => prefs.copyWith(caffeineLimitMg: newLimit),
      TrackerKind.alcohol => prefs.copyWith(alcoholLimitUnits: newLimit),
    };
    await ref
        .read(nutritionPreferencesProvider.notifier)
        .savePreferences(userId: userId, preferences: updated);
    // Re-fetch so the ring + history reflect the new limit immediately.
    ref.invalidate(trackerHistoryProvider(userId));
    ref.invalidate(optionalTrackersProvider(userId));
  }
}

class _LimitRow extends StatelessWidget {
  final bool isDark;
  final String label;
  final String valueText;
  final Color accent;
  final VoidCallback onEdit;

  const _LimitRow({
    required this.isDark,
    required this.label,
    required this.valueText,
    required this.accent,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(label.toUpperCase(),
                  style: ZType.lbl(13,
                      color: textPrimary, letterSpacing: 1.2)),
            ),
            Text(valueText,
                style: ZType.data(14, color: accent)),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  final List<TrackerDay> series;
  final double limit;
  final Color color;
  final bool isDark;
  final double Function(TrackerDay) valueOf;

  const _HistoryChart({
    required this.series,
    required this.limit,
    required this.color,
    required this.isDark,
    required this.valueOf,
  });

  @override
  Widget build(BuildContext context) {
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    if (series.isEmpty) {
      return Text('No history yet', style: TextStyle(color: textMuted, fontSize: 13));
    }
    final values = series.map(valueOf).toList();
    final maxV = [
      ...values,
      if (limit > 0) limit,
      1.0,
    ].reduce((a, b) => a > b ? a : b);

    const chartHeight = 120.0;
    return SizedBox(
      height: chartHeight + 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < series.length; i++)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: chartHeight,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: (values[i] / maxV * chartHeight).clamp(2.0, chartHeight),
                        decoration: BoxDecoration(
                          color: (limit > 0 && values[i] > limit)
                              ? AppColors.coral
                              : color,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _dow(series[i].date),
                    style: ZType.lbl(9, color: textMuted, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 'YYYY-MM-DD' → single-letter weekday, no intl dependency.
  String _dow(String iso) {
    try {
      final d = DateTime.parse(iso);
      const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
      return labels[(d.weekday - 1) % 7];
    } catch (_) {
      return '';
    }
  }
}
