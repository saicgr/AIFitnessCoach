/// A read/edit sheet for a single cycle day, opened from a calendar day tap
/// or a chart scrub callout.
///
/// Shows whatever was logged that day (phase, period flow, BBT, mucus, LH,
/// symptoms), with an "Ask coach about this day" affordance and an "Edit
/// this day" button that opens the full check-in pre-targeted to the date.
library;

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/hormonal_health.dart';
import '../../hormonal_health/widgets/hormone_log_sheet.dart';
import '../cycle_chat.dart';
import '../cycle_visuals.dart';
import 'cycle_calendar.dart';
import '../../../widgets/glass_sheet.dart';

/// Shows the day-detail sheet. [phase] is the predicted phase for [day].
Future<void> showCycleDayDetailSheet(
  BuildContext context, {
  required DateTime day,
  required CycleDayLog? log,
  required CyclePhase? phase,
  required Color accent,
  required bool fahrenheit,
}) {
  return showGlassSheet<void>(
    context: context,
    builder: (_) => GlassSheet(
      child: _CycleDayDetailBody(
        day: day,
        log: log,
        phase: phase,
        accent: accent,
        fahrenheit: fahrenheit,
      ),
    ),
  );
}

class _CycleDayDetailBody extends StatelessWidget {
  final DateTime day;
  final CycleDayLog? log;
  final CyclePhase? phase;
  final Color accent;
  final bool fahrenheit;

  const _CycleDayDetailBody({
    required this.day,
    required this.log,
    required this.phase,
    required this.accent,
    required this.fahrenheit,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final isFuture = day.isAfter(CycleDates.dateOnly(DateTime.now()));

    final rows = <_DetailRow>[];
    if (log != null) {
      if (log!.periodFlow != null) {
        rows.add(_DetailRow(Icons.water_drop_rounded, 'Period flow',
            _cap(log!.periodFlow!), CyclePhaseColors.menstrual));
      }
      if (log!.bbtCelsius != null) {
        rows.add(_DetailRow(
          Icons.thermostat_rounded,
          'Basal temperature',
          CycleTemp.format(log!.bbtCelsius!, fahrenheit: fahrenheit),
          accent,
        ));
      }
      if (log!.mucus != null) {
        rows.add(_DetailRow(Icons.opacity_rounded, 'Cervical mucus',
            _mucus(log!.mucus!), CyclePhaseColors.ovulation));
      }
      if (log!.lhResult != null) {
        rows.add(_DetailRow(Icons.science_rounded, 'LH test',
            _cap(log!.lhResult!), CyclePhaseColors.follicular));
      }
      if (log!.symptoms.isNotEmpty) {
        rows.add(_DetailRow(Icons.healing_rounded, 'Symptoms',
            log!.symptoms.join(', '), CyclePhaseColors.luteal));
      }
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(CyclePhaseColors.emoji(phase),
                    style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        CycleDates.withWeekday(day),
                        style: TextStyle(
                          color: fg,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (phase != null)
                        Text(
                          '${phase!.displayName} phase',
                          style: TextStyle(
                            color: CyclePhaseColors.of(phase),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (rows.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: fg.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    isFuture
                        ? 'This day is in the future.'
                        : 'Nothing logged for this day yet.',
                    style: TextStyle(
                      color: fg.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            else
              ...rows.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(r.icon, size: 16, color: r.color),
                        const SizedBox(width: 10),
                        Text(
                          r.label,
                          style: TextStyle(
                            color: fg.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            r.value,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: fg,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: accent,
                      side: BorderSide(
                          color: accent.withValues(alpha: 0.4)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      openCycleChat(
                        context,
                        cycleDaySeed(day,
                            phase: phase, cycleDay: null),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                    label: const Text('Ask coach'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style:
                        FilledButton.styleFrom(backgroundColor: accent),
                    onPressed: isFuture
                        ? null
                        : () {
                            Navigator.pop(context);
                            showGlassSheet<bool>(
                              context: context,
                              builder: (_) => GlassSheet(
                                child: HormoneLogSheet(logDate: day),
                              ),
                            );
                          },
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Edit this day'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _cap(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  String _mucus(String o) => o == 'egg_white' ? 'Egg-white' : _cap(o);
}

class _DetailRow {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  _DetailRow(this.icon, this.label, this.value, this.color);
}
