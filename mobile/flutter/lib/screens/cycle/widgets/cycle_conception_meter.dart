/// TTC "chance of conception" meter — shown on the Today tab only when
/// `tracking_mode == ttc`.
///
/// The meter is a deterministic read of [CyclePrediction.conceptionChance]
/// ('high' inside the fertile window, 'low' outside) plus the peak-fertility
/// days. It is explicitly framed as an estimate — never contraceptive advice.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_chat.dart';
import '../cycle_visuals.dart';

class CycleConceptionMeter extends StatelessWidget {
  final CyclePrediction prediction;
  final Color accent;

  const CycleConceptionMeter({
    super.key,
    required this.prediction,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    final chance = prediction.conceptionChance ?? 'low';
    final inPeak = _inPeak();
    final double fill;
    final String label;
    final Color meterColor;
    if (inPeak) {
      fill = 1.0;
      label = 'Peak fertility';
      meterColor = CyclePhaseColors.ovulation;
    } else if (chance == 'high') {
      fill = 0.7;
      label = 'High chance';
      meterColor = CyclePhaseColors.follicular;
    } else {
      fill = 0.22;
      label = 'Lower chance';
      meterColor = CyclePhaseColors.luteal;
    }

    final fertileStart = prediction.fertileWindowStart;
    final fertileEnd = prediction.fertileWindowEnd;
    final subline = (fertileStart != null && fertileEnd != null)
        ? 'Fertile window: ${CycleDates.medium(fertileStart)} – '
            '${CycleDates.medium(fertileEnd)}'
        : 'Log periods to estimate your fertile window';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: meterColor.withValues(alpha: isDark ? 0.12 : 0.09),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meterColor.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_rounded, size: 16, color: meterColor),
              const SizedBox(width: 8),
              Text(
                'Chance of conception',
                style: TextStyle(
                  color: fg,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                label,
                style: TextStyle(
                  color: meterColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fill),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: fg.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(meterColor),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subline,
            style: TextStyle(
              color: fg.withValues(alpha: 0.62),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'An estimate from your logged cycles — not a guarantee '
                  'or a contraceptive method.',
                  style: TextStyle(
                    color: fg.withValues(alpha: 0.45),
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => openCycleChat(
                  context,
                  cycleDatumSeed(
                    'my conception chance today — $label',
                  ),
                ),
                child: Icon(Icons.auto_awesome_rounded,
                    size: 16, color: accent),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }

  bool _inPeak() {
    final start = prediction.peakFertilityStart;
    final end = prediction.peakFertilityEnd;
    if (start == null || end == null) return false;
    final t = CycleDates.dateOnly(prediction.today);
    return !t.isBefore(start) && !t.isAfter(end);
  }
}
