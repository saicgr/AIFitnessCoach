/// Private, in-app monthly cycle summary card for the Insights tab.
///
/// Deliberately NOT shareable — period / symptom data is sensitive and is
/// never a viral artifact. There is no share button, no export, no social
/// hook. This is a personal recap the user reads inside the app only.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../data/models/hormonal_health.dart';
import '../cycle_visuals.dart';

import '../../../l10n/generated/app_localizations.dart';
class CycleMonthlySummary extends StatelessWidget {
  final CyclePrediction? prediction;

  /// Symptom display-name → count over the last ~30 days.
  final Map<String, int> symptomCounts;

  /// Count of days with any BBT reading over the window.
  final int bbtDaysLogged;

  /// Count of days with any check-in over the window.
  final int checkInDays;
  final Color accent;

  const CycleMonthlySummary({
    super.key,
    required this.prediction,
    required this.symptomCounts,
    required this.bbtDaysLogged,
    required this.checkInDays,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    final stats = prediction?.stats;
    final topSymptom = symptomCounts.isEmpty
        ? null
        : (symptomCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first;

    final lines = <_SummaryLine>[
      _SummaryLine(
        Icons.event_repeat_rounded,
        'Cycles tracked',
        '${stats?.cyclesTracked ?? 0}',
      ),
      _SummaryLine(
        Icons.straighten_rounded,
        'Average cycle',
        stats?.avgCycleLength == null
            ? 'Not enough data'
            : '${stats!.avgCycleLength!.toStringAsFixed(1)} days',
      ),
      _SummaryLine(
        Icons.check_circle_outline_rounded,
        'Days checked in',
        '$checkInDays this month',
      ),
      _SummaryLine(
        Icons.thermostat_rounded,
        'Temperature logs',
        bbtDaysLogged == 0
            ? 'None yet'
            : '$bbtDaysLogged day${bbtDaysLogged == 1 ? '' : 's'}',
      ),
      if (topSymptom != null)
        _SummaryLine(
          Icons.healing_rounded,
          'Most-logged symptom',
          '${topSymptom.key} (${topSymptom.value}×)',
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: isDark ? 0.16 : 0.11),
            accent.withValues(alpha: isDark ? 0.05 : 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 18, color: accent),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).cycleMonthlySummaryYourMonthInReview,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Icon(Icons.lock_rounded,
                  size: 13, color: fg.withValues(alpha: 0.35)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            CycleDates.monthYear(DateTime.now()),
            style: TextStyle(
              color: fg.withValues(alpha: 0.55),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...lines.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(l.icon,
                        size: 15, color: accent.withValues(alpha: 0.8)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.label,
                        style: TextStyle(
                          color: fg.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      l.value,
                      style: TextStyle(
                        color: fg,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).cycleMonthlySummaryThisRecapStaysPrivate,
            style: TextStyle(
              color: fg.withValues(alpha: 0.4),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 360.ms);
  }
}

class _SummaryLine {
  final IconData icon;
  final String label;
  final String value;
  _SummaryLine(this.icon, this.label, this.value);
}
