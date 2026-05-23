/// Session Detail Sheet
///
/// Bottom sheet opened when the user taps a prior-session pill in the
/// ProgressionStrip. Shows the full per-set breakdown for that day —
/// weight × reps × RIR/RPE, with the best working set highlighted.
///
/// Why a separate widget: keeping the strip file focused on rendering
/// the compact pills keeps the hot path lightweight. The sheet loads
/// lazily on tap.
library;

import 'package:flutter/material.dart';

import '../../../core/services/pre_set_insight_engine.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../widgets/glass_sheet.dart';

Future<void> showSessionDetailSheet({
  required BuildContext context,
  required SessionSummary session,
  required bool useKg,
  required bool isBodyweight,
  required bool isTimed,
  String? exerciseName,
}) {
  return showGlassSheet<void>(
    context: context,
    builder: (ctx) => GlassSheet(
      child: _SessionDetailSheet(
        session: session,
        useKg: useKg,
        isBodyweight: isBodyweight,
        isTimed: isTimed,
        exerciseName: exerciseName,
      ),
    ),
  );
}

class _SessionDetailSheet extends StatelessWidget {
  final SessionSummary session;
  final bool useKg;
  final bool isBodyweight;
  final bool isTimed;
  final String? exerciseName;

  const _SessionDetailSheet({
    required this.session,
    required this.useKg,
    required this.isBodyweight,
    required this.isTimed,
    this.exerciseName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final fg = isDark ? Colors.white : const Color(0xFF0A0A0A);

    final sets = session.workingSets;
    final bestScore = sets.isEmpty
        ? 0.0
        : sets
            .map((s) => isTimed || isBodyweight
                ? s.reps.toDouble()
                : s.weightKg * s.reps)
            .reduce((a, b) => a > b ? a : b);

    String dateLabel = '';
    try {
      final d = DateTime.tryParse(session.dateIso);
      if (d != null) {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
        ];
        dateLabel = '${months[d.month - 1]} ${d.day}, ${d.year}';
      }
    } catch (_) {
      dateLabel = session.dateIso;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (exerciseName != null)
            Text(
              exerciseName!,
              style: TextStyle(
                color: fg.withValues(alpha: 0.55),
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          Text(
            dateLabel,
            style: TextStyle(
              color: fg,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // Header row
          Row(
            children: [
              _headerCell('Set', fg, flex: 1),
              _headerCell(isTimed ? 'Time' : isBodyweight ? 'Reps' : 'Weight',
                  fg, flex: 2),
              if (!isTimed && !isBodyweight) _headerCell('Reps', fg, flex: 1),
              _headerCell('RIR', fg, flex: 1),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < sets.length; i++)
            _setRow(context, i + 1, sets[i], fg, accent, bestScore),
          const SizedBox(height: 12),
          Text(
            '${sets.length} set${sets.length == 1 ? '' : 's'} • top set highlighted',
            style: TextStyle(
              color: fg.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, Color fg, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: TextStyle(
          color: fg.withValues(alpha: 0.5),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _setRow(BuildContext context, int setNumber, SetSummary set,
      Color fg, Color accent, double bestScore) {
    final score = isTimed || isBodyweight
        ? set.reps.toDouble()
        : set.weightKg * set.reps;
    final isBest = score == bestScore && bestScore > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isBest
            ? accent.withValues(alpha: 0.1)
            : fg.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: isBest
            ? Border.all(color: accent.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: isBest ? accent : fg,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _valueLabel(set),
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!isTimed && !isBodyweight)
            Expanded(
              flex: 1,
              child: Text(
                '${set.reps}',
                style: TextStyle(
                  color: fg,
                  fontSize: 14,
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Text(
              set.rir != null ? '${set.rir}' : '—',
              style: TextStyle(
                color: fg.withValues(alpha: 0.7),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _valueLabel(SetSummary s) {
    if (isTimed) return '${s.reps}s';
    if (isBodyweight) return '${s.reps} reps';
    return WeightUtils.formatWeightFromKg(s.weightKg, useKg: useKg);
  }
}
