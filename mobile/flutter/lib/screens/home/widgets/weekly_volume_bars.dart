import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/body_analyzer.dart';
import '../../../data/repositories/body_analyzer_repository.dart';

/// Per-muscle weekly-volume bars. Bars extend toward the `cap_sets` value
/// from `muscle_volume_caps`; a red segment appears when the user's weekly
/// sets meet or exceed the cap so overreach is obvious.
class WeeklyVolumeBars extends ConsumerStatefulWidget {
  const WeeklyVolumeBars({super.key});

  @override
  ConsumerState<WeeklyVolumeBars> createState() => _WeeklyVolumeBarsState();
}

class _WeeklyVolumeBarsState extends ConsumerState<WeeklyVolumeBars> {
  List<WeeklyVolumeEntry>? _entries;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(weeklyVolumeRepositoryProvider);
      final list = await repo.perMuscle();
      if (mounted) setState(() => _entries = list);
    } catch (_) {
      // Silent — widget hides if data unavailable.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    final entries = _entries;
    if (entries == null || entries.isEmpty) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 18, color: textMuted),
              const SizedBox(width: 8),
              Text(
                'Weekly volume per muscle',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...entries.map((e) => _row(e, textPrimary, textMuted)),
        ],
      ),
    );
  }

  Widget _row(WeeklyVolumeEntry e, Color primary, Color muted) {
    final cap = e.capSets ?? 20;
    final pct = cap == 0 ? 0.0 : (e.weeklySets / cap).clamp(0.0, 1.2);
    final atCap = pct >= 0.95;
    final color = atCap
        ? const Color(0xFFE74C3C)
        : pct >= 0.75
            ? const Color(0xFFF5A623)
            : const Color(0xFF2ECC71);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              e.muscleGroup,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (_, c) {
              final w = c.maxWidth;
              final barW = (w * pct.clamp(0.0, 1.0));
              return Stack(
                children: [
                  Container(
                    height: 10,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    height: 10,
                    width: barW,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              );
            }),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 56,
            child: Text(
              e.capSets != null ? '${e.weeklySets}/${e.capSets}' : '${e.weeklySets}',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 11, color: muted),
            ),
          ),
        ],
      ),
    );
  }
}
