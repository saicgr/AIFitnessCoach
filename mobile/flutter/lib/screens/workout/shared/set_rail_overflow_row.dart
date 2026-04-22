// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Row + set-badge widgets used by `set_rail_overflow_sheet.dart`. Split out
// so the sheet file stays under the 250-line project cap.

import 'package:flutter/material.dart';

import '../../../core/theme/accent_color_provider.dart';
import 'set_rail.dart';

class OverflowRow extends StatelessWidget {
  final RailSetSummary summary;
  final bool isCurrent;
  final VoidCallback onTap;

  const OverflowRow({
    super.key,
    required this.summary,
    required this.isCurrent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final onSurface = isDark ? Colors.white : Colors.black;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            _SetBadge(
              summary: summary,
              isCurrent: isCurrent,
              accent: accent,
              isDark: isDark,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    summary.status == RailSetStatus.warmup
                        ? 'Warm-up'
                        : 'Set ${summary.displayIndex}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _statusText(),
                    style: TextStyle(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _valueText(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText() {
    switch (summary.status) {
      case RailSetStatus.done:
        return 'Completed · tap to edit';
      case RailSetStatus.warmup:
        return 'Warm-up · tap to edit';
      case RailSetStatus.current:
        return 'Current set';
      case RailSetStatus.upcoming:
        return 'Upcoming · tap to edit';
    }
  }

  String _valueText() {
    final w = summary.weightLabel ?? _formatWeight(summary.weight);
    final r = summary.reps;
    if (summary.status == RailSetStatus.upcoming && r == null) return '—';
    return '$w × ${r ?? '-'}';
  }

  String _formatWeight(double? w) {
    if (w == null) return '-';
    if (w == w.roundToDouble()) return w.toStringAsFixed(0);
    return w.toStringAsFixed(1);
  }
}

class _SetBadge extends StatelessWidget {
  final RailSetSummary summary;
  final bool isCurrent;
  final Color accent;
  final bool isDark;

  const _SetBadge({
    required this.summary,
    required this.isCurrent,
    required this.accent,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isCurrent
        ? Colors.transparent
        : accent.withValues(alpha: isDark ? 0.18 : 0.12);
    final border = isCurrent ? accent : accent.withValues(alpha: 0.4);
    final fg = isCurrent ? accent : (isDark ? Colors.white : Colors.black);
    final label = summary.status == RailSetStatus.warmup
        ? 'W'
        : summary.displayIndex.toString();

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: isCurrent ? 1.5 : 1),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: fg,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
